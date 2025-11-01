mod config;
mod dto;
mod handlers;
mod models;
mod plugins;        // 🆕 Plugin system
mod repositories;
mod routes;
mod services;
mod json_utf8;


use config::Config;
use plugins::{PluginRegistry, GeographyPlugin}; // 🆕
use sqlx::PgPool;
use std::net::SocketAddr;
use std::sync::Arc;
use axum::http::header;
use tower_http::{
    cors::CorsLayer,
    set_header::SetResponseHeaderLayer,
};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

/// 🆕 App State avec Plugin Registry
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub plugin_registry: Arc<PluginRegistry>,
}

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
    tracing::info!("🔌 Connecting to database...");
    let pool = PgPool::connect(&config.database_url).await?;
    tracing::info!("✅ Connected to database");

    // 🆕 Plugin Registry
    tracing::info!("🔌 Initializing plugin registry...");
    let mut plugin_registry = PluginRegistry::new();
    // 🆕 Enregistrer Geography Plugin
    plugin_registry.register(Arc::new(GeographyPlugin));
    
    tracing::info!(
        "✅ Plugin registry initialized with {} plugins",
        plugin_registry.count()
    );

    // App State
    let app_state = AppState {
        pool,
        plugin_registry: Arc::new(plugin_registry),
    };

    // Routes avec CORS
    let app = routes::create_router(app_state).layer(CorsLayer::permissive()).layer(SetResponseHeaderLayer::if_not_present(
        header::CONTENT_TYPE,
        header::HeaderValue::from_static("application/json; charset=utf-8"),
    ));

    // Server
    let addr = SocketAddr::from(([127, 0, 0, 1], config.server_port));
    tracing::info!("🚀 Quiz Core Service listening on {}", addr);
    tracing::info!("📍 API: http://localhost:{}/api/v1", config.server_port);
    tracing::info!("📍 Health: http://localhost:{}/health", config.server_port);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}