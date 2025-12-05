mod config;
mod middleware;
mod mtls;
mod proxy;
mod routes;

use axum::http::header;
use config::Config;
use hyper_util::service::TowerToHyperService;
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

    // Créer client HTTP avec ou sans mTLS
    let http_client = if config.mtls_enabled {
        tracing::info!("🔐 Initializing mTLS client for backend services...");

        let mtls_config = mtls::MtlsConfig::from_env()?;
        mtls_config.validate()?;

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

    // Routes avec CORS
    let app = routes::create_router(Arc::new(proxy))
        .layer(CorsLayer::permissive())
        .layer(SetResponseHeaderLayer::if_not_present(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json; charset=utf-8"),
        ));

    let addr: SocketAddr = format!("0.0.0.0:{}", config.port).parse()?;

    // Démarrage conditionnel avec ou sans mTLS
    if config.mtls_enabled {
        tracing::info!("🔐 mTLS mode enabled for API Gateway");

        let mtls_config = mtls::MtlsConfig::from_env()?;
        mtls_config.validate()?;

        let tls_acceptor = mtls::create_mtls_acceptor(&mtls_config)?;

        tracing::info!("🚀 API Gateway (mTLS) listening on https://{}", addr);

        let listener = tokio::net::TcpListener::bind(addr).await?;

        loop {
            let (tcp_stream, remote_addr) = listener.accept().await?;
            let tls_acceptor = tls_acceptor.clone();
            let app = app.clone();

            tokio::spawn(async move {
                match tls_acceptor.accept(tcp_stream).await {
                    Ok(tls_stream) => {
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
        tracing::info!("🚀 API Gateway listening on http://{}", addr);

        let listener = tokio::net::TcpListener::bind(&addr).await?;
        axum::serve(listener, app).await?;
    }

    Ok(())
}