mod config;
mod middleware;
mod mtls;
mod proxy;
mod routes;

use axum::http::header;
use config::Config;
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::{cors::CorsLayer, set_header::SetResponseHeaderLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "api_gateway=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Configuration
    let config = Config::from_env()?;

    tracing::info!("🚀 Starting API Gateway...");
    tracing::info!("Environment: {:?}", config.environment);
    tracing::info!("mTLS: {}", if config.mtls_enabled { "ENABLED" } else { "DISABLED" });

    // ✅ NOUVEAU: Créer client HTTP avec ou sans mTLS
    let http_client = if config.mtls_enabled {
        tracing::info!("🔐 Initializing mTLS client for backend services...");

        // Charger et valider configuration mTLS
        let mtls_config = mtls::MtlsConfig::from_env()?;
        mtls_config.validate()?;

        // Créer client avec mTLS (pour appeler les services backend)
        let max_timeout = config.auth_timeout
            .max(config.quiz_timeout)
            .max(config.subscription_timeout)
            .max(config.offline_timeout)
            .max(config.ads_timeout);

        mtls::create_mtls_client(&mtls_config, max_timeout)?
    } else {
        tracing::info!("Creating standard HTTP client (no mTLS)");

        let max_timeout = config.auth_timeout
            .max(config.quiz_timeout)
            .max(config.subscription_timeout)
            .max(config.offline_timeout)
            .max(config.ads_timeout);

        mtls::create_standard_client(max_timeout)?
    };

    // Créer ServiceProxy avec le client configuré
    let proxy = proxy::ServiceProxy::new(config.clone(), http_client);

    // Routes avec CORS et middleware
    let app = routes::create_router(Arc::new(config.clone()))
        .layer(CorsLayer::permissive())
        .layer(SetResponseHeaderLayer::if_not_present(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json; charset=utf-8"),
        ))
        .with_state(Arc::new(proxy));

    let addr = format!("0.0.0.0:{}", config.port);

    // ✅ NOUVEAU: Démarrage conditionnel avec ou sans mTLS (serveur)
    if config.mtls_enabled {
        tracing::info!("🔐 mTLS server mode enabled");

        // Charger configuration mTLS serveur
        let mtls_config = mtls::MtlsConfig::from_env()?;
        mtls_config.validate()?;

        // Créer configuration TLS serveur
        let tls_config = mtls::create_mtls_server_config(&mtls_config).await?;

        tracing::info!("🚀 API Gateway (mTLS) listening on https://{}", addr);
        tracing::info!("📍 Health: https://{}/health", addr);

        // Serveur avec TLS
        axum_server::bind_rustls(addr.parse()?, tls_config)
            .serve(app.into_make_service())
            .await?;
    } else {
        tracing::info!("🔓 Running without mTLS (HTTP mode)");
        tracing::info!("🚀 API Gateway listening on http://{}", addr);
        tracing::info!("📍 Health: http://{}/health", addr);

        // Serveur sans TLS (mode actuel)
        let listener = tokio::net::TcpListener::bind(&addr).await?;
        axum::serve(
            listener,
            app.into_make_service_with_connect_info::<SocketAddr>(),
        )
            .await?;
    }

    Ok(())
}