use axum::{
    response::Json,
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[derive(Serialize, Deserialize)]
struct HelloResponse {
    message: String,
    service: String,
    version: String,
}

#[derive(Serialize, Deserialize)]
struct HealthResponse {
    status: String,
    service: String,
}

// Handler pour la route /hello
async fn hello_handler() -> Json<HelloResponse> {
    Json(HelloResponse {
        message: "Hello World from Map Service!".to_string(),
        service: "map_service".to_string(),
        version: "0.1.0".to_string(),
    })
}

// Handler pour la route /health
async fn health_handler() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy".to_string(),
        service: "map_service".to_string(),
    })
}

#[tokio::main]
async fn main() {
    // Initialiser le logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "map_service=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Créer le routeur
    let app = Router::new()
        .route("/hello", get(hello_handler))
        .route("/health", get(health_handler))
        .layer(CorsLayer::permissive()); // CORS pour développement

    // Définir l'adresse du serveur
    let addr = SocketAddr::from(([127, 0, 0, 1], 8082));

    tracing::info!("🚀 Map Service listening on {}", addr);
    tracing::info!("📍 Try: http://localhost:8082/hello");
    tracing::info!("❤️  Health check: http://localhost:8082/health");

    // Démarrer le serveur
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
