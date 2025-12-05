use axum::{
    body::Body,
    extract::{Request, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::{any, get},
    Router,
};
use std::sync::Arc;

use crate::proxy::{ServiceProxy, ServiceType};

pub fn create_router(proxy: Arc<ServiceProxy>) -> Router {
    Router::new()
        // Health check
        .route("/health", get(health_check))

        // Proxy all other routes
        .fallback(proxy_handler)
        .with_state(proxy)
}

async fn health_check() -> impl IntoResponse {
    (StatusCode::OK, "API Gateway is healthy")
}

async fn proxy_handler(
    State(proxy): State<Arc<ServiceProxy>>,
    request: Request,
) -> Response {
    let method = request.method().clone();
    let uri = request.uri().clone();
    let path = uri.path();
    let headers = request.headers().clone();
    let body = request.into_body();

    // Déterminer le service cible
    let service = match ServiceType::from_path(path) {
        Some(s) => s,
        None => {
            return (
                StatusCode::NOT_FOUND,
                "No service found for this path",
            )
                .into_response();
        }
    };

    // Proxyer la requête
    match proxy
        .proxy_request(service, method, path, headers, body)
        .await
    {
        Ok(response) => response,
        Err(e) => e.into_response(),
    }
}