mod config;
mod dto;
mod handlers;
mod json_utf8;
mod middleware; // 🔐 Pour mTLS validation
mod models;
mod plugins;
mod repositories;
mod routes;
mod services;

use axum::http::header;
use config::Config;
use hyper::body::Incoming;
use hyper::Request;
use hyper_util::rt::TokioIo;
use plugins::{GeographyPlugin, PluginRegistry};
use shared::tls::{create_mtls_acceptor, MtlsAcceptor}; // 🔐 Import module shared
use sqlx::PgPool;
use std::sync::Arc;
use tokio::net::TcpListener;
use tower::ServiceExt; // Pour oneshot()
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

    // 🔐 Vérifier si mTLS activé
    let mtls_enabled = std::env::var("MTLS_ENABLED")
        .unwrap_or_else(|_| "false".to_string())
        .parse::<bool>()
        .unwrap_or(false);

    // Créer le router
    let app = routes::create_router(app_state)
        .layer(CorsLayer::permissive())
        .layer(SetResponseHeaderLayer::if_not_present(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json; charset=utf-8"),
        ));

    // Adresse serveur
    let addr = format!("{}:{}", config.server_host, config.server_port);

    if mtls_enabled {
        tracing::info!("🔐 Mode mTLS ACTIVÉ");
        tracing::info!("🚀 Quiz Core Service listening on {} (HTTPS/mTLS)", addr);

        // Créer acceptor mTLS
        let mtls_acceptor = match create_mtls_acceptor() {
            Ok(acceptor) => {
                tracing::info!("✅ Acceptor mTLS créé avec succès");
                Arc::new(acceptor)
            }
            Err(e) => {
                tracing::error!("❌ Erreur création acceptor mTLS: {}", e);
                tracing::error!("💥 Impossible de démarrer sans mTLS en mode strict");
                return Err(e.into());
            }
        };

        // Démarrer serveur mTLS
        start_mtls_server(&addr, app, mtls_acceptor).await?;
    } else {
        tracing::info!("ℹ️  Mode HTTP standard (mTLS désactivé)");
        tracing::info!("🚀 Quiz Core Service listening on {} (HTTP)", addr);
        tracing::info!(
            "🔓 API: http://{}:{}/api/v1",
            config.server_host, config.server_port
        );
        tracing::info!(
            "🔓 Health: http://{}:{}/health",
            config.server_host, config.server_port
        );

        // Démarrer serveur HTTP standard
        start_http_server(&addr, app).await?;
    }

    Ok(())
}

/// Démarre serveur avec mTLS (validation client obligatoire)
async fn start_mtls_server(
    addr: &str,
    app: axum::Router,
    mtls_acceptor: Arc<MtlsAcceptor>,
) -> anyhow::Result<()> {
    use hyper_util::server::conn::auto::Builder;

    tracing::info!("🔐 Écoute mTLS sur: {}", addr);
    tracing::info!("🔐 Validation client certificat: OBLIGATOIRE");

    let listener = TcpListener::bind(addr).await?;
    let tls_acceptor = mtls_acceptor.acceptor().clone();

    loop {
        // Accepter connexion TCP
        let (tcp_stream, remote_addr) = match listener.accept().await {
            Ok(conn) => conn,
            Err(e) => {
                tracing::error!("❌ Erreur accept TCP: {}", e);
                continue;
            }
        };

        tracing::debug!("🔌 Nouvelle connexion depuis: {}", remote_addr);

        let tls_acceptor = tls_acceptor.clone();
        let mtls_acceptor = Arc::clone(&mtls_acceptor);
        let tower_service = app.clone();

        // Spawner task pour chaque connexion
        tokio::spawn(async move {
            // 1. Handshake TLS
            let tls_stream = match tls_acceptor.accept(tcp_stream).await {
                Ok(stream) => {
                    tracing::info!("✅ Handshake TLS réussi avec: {}", remote_addr);
                    stream
                }
                Err(e) => {
                    tracing::error!("❌ Erreur handshake TLS depuis {}: {}", remote_addr, e);
                    return;
                }
            };

            // 2. Extraire certificat client
            let (_, server_connection) = tls_stream.get_ref();

            if let Some(peer_certs) = server_connection.peer_certificates() {
                if let Some(client_cert) = peer_certs.first() {
                    // 3. Valider certificat client
                    match mtls_acceptor.validate_client_cert(client_cert) {
                        Ok(cn) => {
                            tracing::info!(
                                "✅ Certificat client validé - CN: {} (depuis {})",
                                cn,
                                remote_addr
                            );
                            // TODO: Injecter CN dans request headers pour middleware
                        }
                        Err(e) => {
                            tracing::error!(
                                "❌ Certificat client invalide depuis {}: {}",
                                remote_addr, e
                            );
                            // En mode strict, on rejette
                            return;
                        }
                    }
                } else {
                    tracing::error!("❌ Aucun certificat client fourni par: {}", remote_addr);
                    return;
                }
            } else {
                tracing::error!("❌ Pas de certificats peer depuis: {}", remote_addr);
                return;
            }

            // 4. Servir requête HTTP via hyper_util
            let io = TokioIo::new(tls_stream);

            // Créer un service Hyper à partir du Router Axum
            let hyper_service = hyper::service::service_fn(move |request: Request<Incoming>| {
                // Clone le service pour chaque requête
                tower_service.clone().oneshot(request)
            });

            if let Err(e) = Builder::new(hyper_util::rt::TokioExecutor::new())
                .serve_connection(io, hyper_service)
                .await
            {
                tracing::error!("❌ Erreur traitement requête HTTP: {}", e);
            }
        });
    }
}

/// Démarre serveur HTTP standard (sans mTLS)
async fn start_http_server(addr: &str, app: axum::Router) -> anyhow::Result<()> {
    tracing::info!("📡 Écoute HTTP sur: {}", addr);

    let listener = TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
