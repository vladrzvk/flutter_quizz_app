use axum::{
    extract::{Request, State},
    http::{header, StatusCode},
    response::{IntoResponse, Response},
    Json, Router,
    routing::post,
};
use serde_json::json;
use sqlx::PgPool;
use validator::Validate;

use crate::application::AuthService;
use crate::domain::{
    AuthResponse, LoginRequest, RegisterRequest, RefreshTokenRequest, CreateGuestRequest,
};
use crate::error::AuthError;
use crate::presentation::middleware::AuthContext;

pub fn auth_routes(pool: PgPool, auth_service: AuthService) -> Router {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/refresh", post(refresh_token))
        .route("/logout", post(logout))
        .route("/logout-all", post(logout_all))
        .route("/guest", post(create_guest))
        .with_state((pool, auth_service))
}

// ============================================
// REGISTER
// ============================================

/// POST /auth/register
async fn register(
    State((pool, auth_service)): State<(PgPool, AuthService)>,
    request: Request,
    Json(payload): Json<RegisterRequest>,
) -> Result<Json<AuthResponse>, AuthError> {
    // Validation
    payload.validate()?;

    // Extraire IP
    let ip_address = extract_ip_address(&request);

    // Register
    let response = auth_service
        .register(&pool, payload, ip_address.as_deref())
        .await?;

    Ok(Json(response))
}

// ============================================
// LOGIN
// ============================================

/// POST /auth/login
async fn login(
    State((pool, auth_service)): State<(PgPool, AuthService)>,
    request: Request,
    Json(payload): Json<LoginRequest>,
) -> Result<impl IntoResponse, AuthError> {
    // Validation
    payload.validate()?;

    // Extraire metadata
    let ip_address = extract_ip_address(&request);
    let user_agent = extract_user_agent(&request);

    // Login
    let response = auth_service
        .login(
            &pool,
            payload,
            ip_address.as_deref(),
            user_agent.as_deref(),
        )
        .await?;

    // ✅ SÉCURITÉ : Définir les tokens dans des cookies HttpOnly
    let access_cookie = create_access_token_cookie(&response.access_token, response.expires_in);
    let refresh_cookie = create_refresh_token_cookie(&response.refresh_token);

    Ok((
        StatusCode::OK,
        [
            (header::SET_COOKIE, access_cookie),
            (header::SET_COOKIE, refresh_cookie),
        ],
        Json(response),
    ))
}

// ============================================
// REFRESH TOKEN
// ============================================

/// POST /auth/refresh
async fn refresh_token(
    State((pool, auth_service)): State<(PgPool, AuthService)>,
    request: Request,
) -> Result<impl IntoResponse, AuthError> {
    // Extraire le refresh token depuis cookie ou body
    let refresh_token = extract_refresh_token(&request)?;

    // Extraire metadata
    let ip_address = extract_ip_address(&request);
    let user_agent = extract_user_agent(&request);

    // Refresh
    let response = auth_service
        .refresh_token(
            &pool,
            &refresh_token,
            ip_address.as_deref(),
            user_agent.as_deref(),
        )
        .await?;

    // ✅ SÉCURITÉ : Mettre à jour les cookies
    let access_cookie = create_access_token_cookie(&response.access_token, response.expires_in);
    let refresh_cookie = create_refresh_token_cookie(&response.refresh_token);

    Ok((
        StatusCode::OK,
        [
            (header::SET_COOKIE, access_cookie),
            (header::SET_COOKIE, refresh_cookie),
        ],
        Json(response),
    ))
}

// ============================================
// LOGOUT
// ============================================

/// POST /auth/logout
async fn logout(
    State((pool, auth_service)): State<(PgPool, AuthService)>,
    request: Request,
) -> Result<impl IntoResponse, AuthError> {
    // Extraire le contexte auth
    let context = request
        .extensions()
        .get::<AuthContext>()
        .ok_or(AuthError::InvalidToken)?;

    // Extraire access token
    let access_token = extract_access_token(&request)?;

    let ip_address = extract_ip_address(&request);

    // Logout
    auth_service
        .logout(&pool, &access_token, ip_address.as_deref())
        .await?;

    // ✅ SÉCURITÉ : Supprimer les cookies
    let clear_access = clear_cookie("access_token");
    let clear_refresh = clear_cookie("refresh_token");

    Ok((
        StatusCode::OK,
        [
            (header::SET_COOKIE, clear_access),
            (header::SET_COOKIE, clear_refresh),
        ],
        Json(json!({ "message": "Logged out successfully" })),
    ))
}

// ============================================
// LOGOUT ALL
// ============================================

/// POST /auth/logout-all
async fn logout_all(
    State((pool, auth_service)): State<(PgPool, AuthService)>,
    request: Request,
) -> Result<impl IntoResponse, AuthError> {
    let context = request
        .extensions()
        .get::<AuthContext>()
        .ok_or(AuthError::InvalidToken)?;

    let ip_address = extract_ip_address(&request);

    let count = auth_service
        .logout_all(&pool, context.0.user_id, ip_address.as_deref())
        .await?;

    let clear_access = clear_cookie("access_token");
    let clear_refresh = clear_cookie("refresh_token");

    Ok((
        StatusCode::OK,
        [
            (header::SET_COOKIE, clear_access),
            (header::SET_COOKIE, clear_refresh),
        ],
        Json(json!({
            "message": "All sessions logged out",
            "sessions_revoked": count
        })),
    ))
}

// ============================================
// CREATE GUEST
// ============================================

/// POST /auth/guest
async fn create_guest(
    State((pool, auth_service)): State<(PgPool, AuthService)>,
    request: Request,
    Json(payload): Json<CreateGuestRequest>,
) -> Result<impl IntoResponse, AuthError> {
    let ip_address = extract_ip_address(&request);

    let response = auth_service
        .create_guest(&pool, payload, ip_address.as_deref())
        .await?;

    // Définir les cookies
    let access_cookie = create_access_token_cookie(&response.access_token, response.expires_in);
    let refresh_cookie = create_refresh_token_cookie(&response.refresh_token);

    Ok((
        StatusCode::CREATED,
        [
            (header::SET_COOKIE, access_cookie),
            (header::SET_COOKIE, refresh_cookie),
        ],
        Json(response),
    ))
}

// ============================================
// HELPERS
// ============================================

fn extract_ip_address(request: &Request) -> Option<String> {
    if let Some(forwarded) = request.headers().get("X-Forwarded-For") {
        if let Ok(forwarded_str) = forwarded.to_str() {
            return Some(forwarded_str.split(',').next()?.trim().to_string());
        }
    }

    if let Some(real_ip) = request.headers().get("X-Real-IP") {
        if let Ok(ip_str) = real_ip.to_str() {
            return Some(ip_str.to_string());
        }
    }

    None
}

fn extract_user_agent(request: &Request) -> Option<String> {
    request
        .headers()
        .get(header::USER_AGENT)
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string())
}

fn extract_access_token(request: &Request) -> Result<String, AuthError> {
    // Cookie priority
    if let Some(cookie_header) = request.headers().get(header::COOKIE) {
        if let Ok(cookie_str) = cookie_header.to_str() {
            for cookie in cookie_str.split(';') {
                let parts: Vec<&str> = cookie.trim().splitn(2, '=').collect();
                if parts.len() == 2 && parts[0] == "access_token" {
                    return Ok(parts[1].to_string());
                }
            }
        }
    }

    // Fallback: Authorization header
    if let Some(auth_header) = request.headers().get(header::AUTHORIZATION) {
        if let Ok(auth_str) = auth_header.to_str() {
            if let Some(token) = auth_str.strip_prefix("Bearer ") {
                return Ok(token.to_string());
            }
        }
    }

    Err(AuthError::InvalidToken)
}

fn extract_refresh_token(request: &Request) -> Result<String, AuthError> {
    // Cookie priority
    if let Some(cookie_header) = request.headers().get(header::COOKIE) {
        if let Ok(cookie_str) = cookie_header.to_str() {
            for cookie in cookie_str.split(';') {
                let parts: Vec<&str> = cookie.trim().splitn(2, '=').collect();
                if parts.len() == 2 && parts[0] == "refresh_token" {
                    return Ok(parts[1].to_string());
                }
            }
        }
    }

    Err(AuthError::InvalidToken)
}

/// ✅ SÉCURITÉ : Créer cookie HttpOnly pour access token
fn create_access_token_cookie(token: &str, expires_in: i64) -> String {
    format!(
        "access_token={}; Path=/; HttpOnly; SameSite=Strict; Secure; Max-Age={}",
        token, expires_in
    )
}

/// ✅ SÉCURITÉ : Créer cookie HttpOnly pour refresh token
fn create_refresh_token_cookie(token: &str) -> String {
    format!(
        "refresh_token={}; Path=/; HttpOnly; SameSite=Strict; Secure; Max-Age={}",
        token,
        7 * 24 * 60 * 60 // 7 jours
    )
}

/// Supprimer un cookie
fn clear_cookie(name: &str) -> String {
    format!(
        "{}=; Path=/; HttpOnly; SameSite=Strict; Secure; Max-Age=0",
        name
    )
}