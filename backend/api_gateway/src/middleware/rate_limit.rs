use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::Mutex;

use crate::config::Config;

#[derive(Clone)]
pub struct RateLimiter {
    requests: Arc<Mutex<HashMap<String, Vec<Instant>>>>,
    limit: u32,
    window: Duration,
}

impl RateLimiter {
    pub fn new(requests_per_minute: u32) -> Self {
        Self {
            requests: Arc::new(Mutex::new(HashMap::new())),
            limit: requests_per_minute,
            window: Duration::from_secs(60),
        }
    }

    async fn check(&self, user_id: &str) -> bool {
        let mut requests = self.requests.lock().await;
        let now = Instant::now();

        let user_requests = requests.entry(user_id.to_string()).or_insert_with(Vec::new);

        // Nettoyer anciennes requêtes
        user_requests.retain(|&time| now.duration_since(time) < self.window);

        if user_requests.len() >= self.limit as usize {
            false
        } else {
            user_requests.push(now);
            true
        }
    }
}

pub async fn rate_limit_middleware(
    State((config, limiter)): State<(Arc<Config>, Arc<RateLimiter>)>,
    request: Request,
    next: Next,
) -> Response {
    // Routes publiques : pas de rate limiting
    if config.is_public_route(request.uri().path()) {
        return next.run(request).await;
    }

    // Extraire user_id du header (mis par auth_middleware)
    let user_id = request
        .headers()
        .get("X-User-Id")
        .and_then(|v| v.to_str().ok())
        .unwrap_or("anonymous");

    if limiter.check(user_id).await {
        next.run(request).await
    } else {
        tracing::warn!("Rate limit exceeded for user: {}", user_id);
        (
            StatusCode::TOO_MANY_REQUESTS,
            "Rate limit exceeded. Please try again later.",
        )
            .into_response()
    }
}