use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
};
use std::time::Instant;

pub async fn logging_middleware(
    request: Request,
    next: Next,
) -> Response {
    let method = request.method().clone();
    let uri = request.uri().clone();
    let start = Instant::now();

    tracing::info!(
        "→ {} {}",
        method,
        uri
    );

    let response = next.run(request).await;

    let duration = start.elapsed();
    let status = response.status();

    tracing::info!(
        "← {} {} {} {:?}",
        method,
        uri,
        status.as_u16(),
        duration
    );

    response
}