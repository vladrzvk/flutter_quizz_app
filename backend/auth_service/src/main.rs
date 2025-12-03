// backend/auth_service/src/main.rs
mod application;
mod config;
mod domain;
mod error;
mod infrastrcture; // Note: typo dans ton dossier (infrastructure au lieu de infrastructure)
mod presentation;

use axum::Router;
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
                .unwrap_or_else(|_| "auth_service=debug,tower_http=debug,sqlx=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("Starting Auth Service...");

    // Database
    tracing::info!("Connecting to database...");
    let pool = PgPool::connect(&config.database_url).await?;
    tracing::info!("Connected to database");

    // Run migrations
    tracing::info!("Running database migrations...");
    sqlx::migrate!("./migrations").run(&pool).await?;
    tracing::info!("Migrations completed");

    // Router (à adapter selon ta structure)
    let app = Router::new()
        .layer(CorsLayer::permissive());
    // TODO: Ajouter tes routes depuis presentation/routes/

    // Server
    let addr: SocketAddr = format!("{}:{}", config.host, config.port).parse()?;
    tracing::info!("Auth Service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}