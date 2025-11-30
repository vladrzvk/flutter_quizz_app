pub mod auth_routes;
pub mod user_routes;
pub mod admin_routes;

use axum::{
    http::StatusCode,
    Json, Router,
    routing::get,
};
use serde_json::json;

pub use auth_routes::auth_routes;
pub use user_routes::user_routes;
pub use admin_routes::admin_routes;

/// Route health check
pub fn health_routes() -> Router {
    Router::new()
        .route("/health", get(health_check))
        .route("/ready", get(readiness_check))
}

/// GET /health
async fn health_check() -> Json<serde_json::Value> {
    Json(json!({
        "status": "healthy",
        "service": "auth-service",
        "version": env!("CARGO_PKG_VERSION"),
    }))
}

/// GET /ready
async fn readiness_check() -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Vérifier la connexion DB
    (
        StatusCode::OK,
        Json(json!({
            "status": "ready",
            "service": "auth-service",
        })),
    )
}