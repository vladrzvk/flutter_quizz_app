use axum::{
    extract::{Request, State},
    http::{HeaderMap, HeaderValue, StatusCode},
    middleware::Next,
    response::{IntoResponse, Response},
};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

use crate::config::Config;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,              // user_id (UUID)
    pub is_guest: bool,           // true si guest
    pub status: String,           // "free" | "premium"
    pub analytics_consent: bool,  // consentement analytics
    pub exp: i64,                 // expiration timestamp
}

pub async fn auth_middleware(
    State(config): State<Arc<Config>>,
    mut request: Request,
    next: Next,
) -> Response {
    let path = request.uri().path();

    // Routes publiques : bypass auth
    if config.is_public_route(path) {
        return next.run(request).await;
    }

    // Routes protégées : valider JWT
    let headers = request.headers();

    match extract_and_validate_token(headers, &config.jwt_secret) {
        Ok(claims) => {
            // Enrichir headers pour services downstream
            if let Err(e) = enrich_request_headers(&mut request, &claims) {
                tracing::error!("Failed to enrich headers: {:?}", e);
                return (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "Failed to process authentication",
                )
                    .into_response();
            }

            next.run(request).await
        }
        Err(err) => err.into_response(),
    }
}

fn extract_and_validate_token(
    headers: &HeaderMap,
    secret: &str,
) -> Result<Claims, AuthError> {
    let auth_header = headers
        .get("authorization")
        .ok_or(AuthError::MissingToken)?
        .to_str()
        .map_err(|_| AuthError::InvalidToken)?;

    if !auth_header.starts_with("Bearer ") {
        return Err(AuthError::InvalidToken);
    }

    let token = &auth_header[7..];

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
        .map_err(|e| {
            tracing::warn!("JWT validation failed: {}", e);
            AuthError::InvalidToken
        })?;

    Ok(token_data.claims)
}

fn enrich_request_headers(request: &mut Request, claims: &Claims) -> Result<(), AuthError> {
    let headers = request.headers_mut();

    headers.insert(
        "X-User-Id",
        HeaderValue::from_str(&claims.sub)
            .map_err(|_| AuthError::InvalidUserId)?,
    );

    headers.insert(
        "X-Is-Guest",
        HeaderValue::from_str(&claims.is_guest.to_string())
            .map_err(|_| AuthError::HeaderCreation)?,
    );

    headers.insert(
        "X-Status",
        HeaderValue::from_str(&claims.status)
            .map_err(|_| AuthError::HeaderCreation)?,
    );

    headers.insert(
        "X-Analytics-Consent",
        HeaderValue::from_str(&claims.analytics_consent.to_string())
            .map_err(|_| AuthError::HeaderCreation)?,
    );

    Ok(())
}

#[derive(Debug)]
pub enum AuthError {
    MissingToken,
    InvalidToken,
    InvalidUserId,
    HeaderCreation,
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AuthError::MissingToken => {
                (StatusCode::UNAUTHORIZED, "Missing authorization token")
            }
            AuthError::InvalidToken => {
                (StatusCode::UNAUTHORIZED, "Invalid or expired token")
            }
            AuthError::InvalidUserId => {
                (StatusCode::INTERNAL_SERVER_ERROR, "Invalid user ID format")
            }
            AuthError::HeaderCreation => {
                (StatusCode::INTERNAL_SERVER_ERROR, "Failed to create headers")
            }
        };

        (status, message).into_response()
    }
}