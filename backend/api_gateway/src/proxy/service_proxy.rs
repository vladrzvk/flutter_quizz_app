use axum::{
    body::Body,
    http::{HeaderMap, Method, StatusCode},
    response::{IntoResponse, Response},
};
use std::time::Duration;

use crate::config::Config;
use crate::middleware::CircuitBreaker;

#[derive(Clone)]
pub struct ServiceProxy {
    client: reqwest::Client,
    config: Config,
    circuit_breaker: CircuitBreaker,
}

impl ServiceProxy {
    pub fn new(config: Config) -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(30)) // Default timeout
            .build()
            .expect("Failed to create HTTP client");

        Self {
            client,
            config,
            circuit_breaker: CircuitBreaker::new(5, 30), // 5 failures, 30s timeout
        }
    }

    pub async fn proxy_request(
        &self,
        service: ServiceType,
        method: Method,
        path: &str,
        headers: HeaderMap,
        body: Body,
    ) -> Result<Response, ProxyError> {
        // Vérifier circuit breaker
        if self.circuit_breaker.is_open().await {
            tracing::error!("Circuit breaker is open for {:?}", service);
            return Err(ProxyError::ServiceUnavailable);
        }

        let target_url = self.get_service_url(service, path);
        let timeout = Duration::from_secs(self.config.get_timeout_for_service(service));

        tracing::debug!("Proxying {} {} to {}", method, path, target_url);

        let body_bytes = axum::body::to_bytes(body, usize::MAX)
            .await
            .map_err(|e| ProxyError::BodyRead(e.to_string()))?;

        let mut request = self
            .client
            .request(method.clone(), &target_url)
            .timeout(timeout)
            .body(body_bytes.to_vec());

        for (key, value) in headers.iter() {
            let key_str = key.as_str();
            if !is_hop_by_hop_header(key_str) {
                if let Ok(value_str) = value.to_str() {
                    request = request.header(key_str, value_str);
                }
            }
        }

        match request.send().await {
            Ok(response) => {
                self.circuit_breaker.record_success().await;

                let status = response.status();
                let response_headers = response.headers().clone();
                let response_body = response
                    .bytes()
                    .await
                    .map_err(|e| ProxyError::ResponseRead(e.to_string()))?;

                let mut builder = Response::builder().status(status);

                for (key, value) in response_headers.iter() {
                    let key_str = key.as_str();
                    if !is_hop_by_hop_header(key_str) {
                        builder = builder.header(key_str, value);
                    }
                }

                let response = builder
                    .body(Body::from(response_body))
                    .map_err(|e| ProxyError::ResponseBuild(e.to_string()))?;

                Ok(response)
            }
            Err(e) => {
                self.circuit_breaker.record_failure().await;
                tracing::error!("Request to {:?} failed: {}", service, e);
                Err(ProxyError::RequestFailed(e.to_string()))
            }
        }
    }

    fn get_service_url(&self, service: ServiceType, path: &str) -> String {
        let base_url = match service {
            ServiceType::Auth => &self.config.auth_service_url,
            ServiceType::Quiz => &self.config.quiz_service_url,
            ServiceType::Subscription => &self.config.subscription_service_url,
            ServiceType::Offline => &self.config.offline_service_url,
            ServiceType::Ads => &self.config.ads_service_url,
        };

        format!("{}{}", base_url, path)
    }
}

#[derive(Debug, Clone, Copy)]
pub enum ServiceType {
    Auth,
    Quiz,
    Subscription,
    Offline,
    Ads,
}

impl ServiceType {
    pub fn from_path(path: &str) -> Option<Self> {
        if path.starts_with("/api/auth") {
            Some(ServiceType::Auth)
        } else if path.starts_with("/api/quiz") {
            Some(ServiceType::Quiz)
        } else if path.starts_with("/api/subscription") {
            Some(ServiceType::Subscription)
        } else if path.starts_with("/api/offline") {
            Some(ServiceType::Offline)
        } else if path.starts_with("/api/ads") {
            Some(ServiceType::Ads)
        } else {
            None
        }
    }
}

fn is_hop_by_hop_header(name: &str) -> bool {
    matches!(
        name.to_lowercase().as_str(),
        "connection"
            | "keep-alive"
            | "proxy-authenticate"
            | "proxy-authorization"
            | "te"
            | "trailers"
            | "transfer-encoding"
            | "upgrade"
    )
}

#[derive(Debug)]
pub enum ProxyError {
    ServiceNotFound,
    ServiceUnavailable,
    BodyRead(String),
    RequestFailed(String),
    ResponseRead(String),
    ResponseBuild(String),
}

impl IntoResponse for ProxyError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            ProxyError::ServiceNotFound => {
                (StatusCode::NOT_FOUND, "Service not found")
            }
            ProxyError::ServiceUnavailable => {
                (StatusCode::SERVICE_UNAVAILABLE, "Service temporarily unavailable")
            }
            ProxyError::BodyRead(_) => {
                (StatusCode::BAD_REQUEST, "Failed to read request body")
            }
            ProxyError::RequestFailed(_) => {
                (StatusCode::BAD_GATEWAY, "Failed to reach upstream service")
            }
            ProxyError::ResponseRead(_) => {
                (StatusCode::BAD_GATEWAY, "Failed to read upstream response")
            }
            ProxyError::ResponseBuild(_) => {
                (StatusCode::INTERNAL_SERVER_ERROR, "Failed to build response")
            }
        };

        tracing::error!("Proxy error: {:?}", self);

        (status, message).into_response()
    }
}