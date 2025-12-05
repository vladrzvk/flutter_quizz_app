mod config;
mod dto;
mod handlers;
mod json_utf8;
mod models;
mod mtls;
mod plugins;
mod repositories;
mod routes;
mod services;

use axum::http::header;
use config::Config;
use hyper_util::service::TowerToHyperService;
use plugins::{GeographyPlugin, PluginRegistry};
use sqlx::PgPool;
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::{cors::CorsLayer, set_header::SetResponseHeaderLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

/// App State avec Plugin Registry
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

    // Plugin Registry
    tracing::info!("🔌 Initializing plugin registry...");
    let mut plugin_registry = PluginRegistry::new();
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
    let app = routes::create_router(app_state)
        .layer(CorsLayer::permissive())
        .layer(SetResponseHeaderLayer::if_not_present(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json; charset=utf-8"),
        ));

    let addr: SocketAddr = format!("{}:{}", config.server_host, config.server_port)
        .parse()?;

    // Démarrage conditionnel avec ou sans mTLS
    if config.mtls_enabled {
        tracing::info!("🔐 mTLS mode enabled");

        // Charger et valider configuration mTLS
        let mtls_config = mtls::MtlsConfig::from_env()?;
        mtls_config.validate()?;

        // Créer TLS acceptor
        let tls_acceptor = mtls::create_mtls_acceptor(&mtls_config)?;

        tracing::info!("🚀 Quiz Core Service (mTLS) listening on https://{}", addr);
        tracing::info!("📍 API: https://{}:{}/api/v1", config.server_host, config.server_port);
        tracing::info!("📍 Health: https://{}:{}/health", config.server_host, config.server_port);

        // Créer listener TCP
        let listener = tokio::net::TcpListener::bind(addr).await?;

        // Serveur avec TLS
        loop {
            let (tcp_stream, remote_addr) = listener.accept().await?;
            let tls_acceptor = tls_acceptor.clone();
            let app = app.clone();

            tokio::spawn(async move {
                match tls_acceptor.accept(tcp_stream).await {
                    Ok(tls_stream) => {
                        // Convertir Router en service hyper compatible
                        let hyper_service = TowerToHyperService::new(app);

                        if let Err(e) = hyper_util::server::conn::auto::Builder::new(
                            hyper_util::rt::TokioExecutor::new()
                        )
                            .serve_connection(
                                hyper_util::rt::TokioIo::new(tls_stream),
                                hyper_service
                            )
                            .await
                        {
                            tracing::error!("Error serving connection from {}: {}", remote_addr, e);
                        }
                    }
                    Err(e) => {
                        tracing::error!("TLS handshake failed from {}: {}", remote_addr, e);
                    }
                }
            });
        }
    } else {
        tracing::info!("🔓 Running without mTLS (HTTP mode)");
        tracing::info!("🚀 Quiz Core Service listening on http://{}", addr);
        tracing::info!("📍 API: http://{}:{}/api/v1", config.server_host, config.server_port);
        tracing::info!("📍 Health: http://{}:{}/health", config.server_host, config.server_port);

        // Serveur sans TLS (mode actuel)
        let listener = tokio::net::TcpListener::bind(&addr).await?;
        axum::serve(listener, app).await?;
    }

    Ok(())
}