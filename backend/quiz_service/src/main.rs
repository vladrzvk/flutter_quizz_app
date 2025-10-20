mod dto;
mod handlers;
mod models;
mod routes;
mod config;
mod repositories;
mod services;

use config::Config;
use sqlx::PgPool;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Configuration
    let config = Config::from_env();

    // Tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "quiz_service=debug,tower_http=debug,sqlx=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Database
    tracing::info!("Connecting to database...");
    let pool = PgPool::connect(&config.database_url).await?;
    tracing::info!("✅ Connected to database");

    // Routes with CORS
    let app = routes::create_router(pool).layer(CorsLayer::permissive());

    // Server
    let addr = SocketAddr::from(([127, 0, 0, 1], config.server_port));
    tracing::info!("🚀 Quiz Service listening on {}", addr);
    tracing::info!("📍 API: http://localhost:{}/api/v1", config.server_port);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}