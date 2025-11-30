use axum::middleware as axum_middleware;
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod config;
mod middleware;
mod proxy;
mod routes;

use config::{Config, Environment};
use middleware::{RateLimiter};

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "api_gateway=info,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    let config = Arc::new(Config::from_env()?);

    tracing::info!("Configuration loaded successfully");
    tracing::info!("Environment: {:?}", config.environment);
    tracing::info!("Auth Service: {}", config.auth_service_url);
    tracing::info!("Quiz Service: {}", config.quiz_service_url);
    tracing::info!("Rate limit: {} req/min", config.rate_limit_requests_per_minute);

    let rate_limiter = Arc::new(RateLimiter::new(config.rate_limit_requests_per_minute));

    // CORS configuration
    let cors = if config.environment == Environment::Development {
        CorsLayer::permissive()
    } else {
        let origins: Vec<_> = config
            .cors_origins
            .iter()
            .filter_map(|origin| origin.parse().ok())
            .collect();

        if origins.is_empty() {
            tracing::warn!("No CORS origins configured for production");
            CorsLayer::permissive()
        } else {
            CorsLayer::new()
                .allow_origin(origins)
                .allow_methods(tower_http::cors::Any)
                .allow_headers(tower_http::cors::Any)
        }
    };

    let app = routes::create_router(config.clone())
        .layer(axum_middleware::from_fn(middleware::logging_middleware))
        .layer(axum_middleware::from_fn_with_state(
            (config.clone(), rate_limiter),
            middleware::rate_limit_middleware,
        ))
        .layer(axum_middleware::from_fn_with_state(
            config.clone(),
            middleware::auth_middleware,
        ))
        .layer(cors);

    let addr = SocketAddr::from(([0, 0, 0, 0], config.port));
    tracing::info!("API Gateway listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}