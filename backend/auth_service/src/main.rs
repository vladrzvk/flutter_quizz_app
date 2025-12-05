mod config;
mod error;
mod domain;
mod application;
mod infrastructure;
mod presentation;
mod mtls;

use axum::{http::header, Router};
use config::Config;
use hyper_util::service::TowerToHyperService;
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::{set_header::SetResponseHeaderLayer, cors::CorsLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use application::{AuthService, UserService, QuotaService, JwtService};
use presentation::{
    routes::{health_routes, auth_routes, user_routes, admin_routes},
    middleware::{auth_middleware, optional_auth_middleware, IpRateLimiter, AppRateLimiter},
};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Configuration
    let config = Config::from_env()?;

    // Tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "auth_service=debug,tower_http=debug,sqlx=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    tracing::info!("🚀 Starting Auth Service...");
    tracing::info!("Environment: {:?}", config.environment);
    tracing::info!("mTLS: {}", if config.mtls_enabled { "ENABLED" } else { "DISABLED" });

    // Database connection
    tracing::info!("🔌 Connecting to database...");
    let pool = sqlx::PgPool::connect(&config.database_url).await?;
    tracing::info!("✅ Connected to database");

    // Services
    let auth_service = AuthService::new(config.clone());
    let user_service = UserService::new(config.bcrypt_cost);
    let quota_service = QuotaService;
    let jwt_service = JwtService::new(&config);

    // Rate limiters
    let app_rate_limiter = AppRateLimiter::new(config.rate_limit_requests_per_minute);
    let ip_rate_limiter = IpRateLimiter::new(60); // 60 req/min par IP

    // CORS
    let cors = if config.cors_origins.contains(&"*".to_string()) {
        CorsLayer::permissive()
    } else {
        let mut cors = CorsLayer::new();
        for origin in &config.cors_origins {
            cors = cors.allow_origin(origin.parse::<axum::http::HeaderValue>().unwrap());
        }
        cors.allow_methods([
            axum::http::Method::GET,
            axum::http::Method::POST,
            axum::http::Method::PUT,
            axum::http::Method::DELETE,
        ])
            .allow_headers([
                axum::http::header::CONTENT_TYPE,
                axum::http::header::AUTHORIZATION,
            ])
    };

    // Routes
    let app = Router::new()
        // Health routes (public)
        .merge(health_routes())

        // Auth routes (public)
        .nest("/api/v1/auth", auth_routes(pool.clone(), auth_service))

        // User routes (protected)
        .nest(
            "/api/v1/users",
            user_routes(pool.clone(), user_service.clone(), quota_service)
                .layer(axum::middleware::from_fn_with_state(
                    (pool.clone(), jwt_service.clone()),
                    auth_middleware,
                )),
        )

        // Admin routes (protected + admin permission)
        .nest(
            "/api/v1/admin",
            admin_routes(pool.clone(), user_service)
                .layer(axum::middleware::from_fn_with_state(
                    (pool.clone(), jwt_service.clone()),
                    auth_middleware,
                )),
        )

        // Global middleware
        .layer(cors)
        .layer(SetResponseHeaderLayer::if_not_present(
            header::CONTENT_TYPE,
            header::HeaderValue::from_static("application/json; charset=utf-8"),
        ));

    let addr: SocketAddr = format!("{}:{}", config.server_host, config.server_port).parse()?;

    // Démarrage conditionnel avec ou sans mTLS
    if config.mtls_enabled {
        tracing::info!("🔐 mTLS mode enabled");

        let mtls_config = mtls::MtlsConfig::from_env()?;
        mtls_config.validate()?;

        let tls_acceptor = mtls::create_mtls_acceptor(&mtls_config)?;

        tracing::info!("🚀 Auth Service (mTLS) listening on https://{}", addr);

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
        tracing::info!("🚀 Auth Service listening on http://{}", addr);

        let listener = tokio::net::TcpListener::bind(&addr).await?;
        axum::serve(listener, app).await?;
    }

    Ok(())
}