use axum::{
    extract::{Request, State},
    http::{header, StatusCode},
    middleware::Next,
    response::Response,
};
use sqlx::PgPool;

use crate::application::JwtService;
use crate::domain::{Claims, RequestContext};
use crate::error::AuthError;
use crate::infrastructure::repositories::SessionRepository;

/// Extension pour le contexte de requête
#[derive(Clone)]
pub struct AuthContext(pub RequestContext);

/// ✅ SÉCURITÉ : Middleware d'authentification JWT
pub async fn auth_middleware(
    State((pool, jwt_service)): State<(PgPool, JwtService)>,
    mut request: Request,
    next: Next,
) -> Result<Response, AuthError> {
    // 1. Extraire le token depuis les cookies (HttpOnly) OU header Authorization
    let token = extract_token(&request)?;

    // 2. Valider le JWT
    let claims = jwt_service.validate_access_token(&token)?;

    // 3. Vérifier que la session n'est pas révoquée
    let token_hash = JwtService::hash_token(&token);
    let session = SessionRepository::find_by_access_token(&pool, &token_hash).await?;

    if !session.is_active() {
        return Err(AuthError::TokenRevoked);
    }

    // 4. Mettre à jour last_used_at de manière asynchrone (fire and forget)
    let pool_clone = pool.clone();
    let session_id = session.id;
    tokio::spawn(async move {
        let _ = SessionRepository::update_last_used(&pool_clone, session_id).await;
    });

    // 5. Extraire les informations de la requête
    let ip_address = extract_ip_address(&request);
    let user_agent = extract_user_agent(&request);
    let device_fingerprint = extract_device_fingerprint(&request);

    // 6. Créer le contexte
    let user_id = uuid::Uuid::parse_str(&claims.sub)
        .map_err(|_| AuthError::InvalidToken)?;

    let status = claims.status.parse::<crate::domain::UserStatus>()
        .map_err(|_| AuthError::InvalidToken)?;

    let context = RequestContext {
        user_id,
        status,
        is_guest: claims.is_guest,
        permissions: claims.permissions,
        ip_address,
        user_agent,
        device_fingerprint,
    };

    // 7. Injecter le contexte dans les extensions
    request.extensions_mut().insert(AuthContext(context));

    // 8. Continuer
    Ok(next.run(request).await)
}

/// ✅ SÉCURITÉ : Middleware optionnel (pour routes publiques)
pub async fn optional_auth_middleware(
    State(pool): State<PgPool>,
    State(jwt_service): State<JwtService>,
    mut request: Request,
    next: Next,
) -> Response {
    // Tenter d'extraire et valider le token
    if let Ok(token) = extract_token(&request) {
        if let Ok(claims) = jwt_service.validate_access_token(&token) {
            let token_hash = JwtService::hash_token(&token);
            if let Ok(session) = SessionRepository::find_by_access_token(&pool, &token_hash).await
            {
                if session.is_active() {
                    if let Ok(user_id) = uuid::Uuid::parse_str(&claims.sub) {
                        if let Ok(status) = claims.status.parse::<crate::domain::UserStatus>() {
                            let context = RequestContext {
                                user_id,
                                status,
                                is_guest: claims.is_guest,
                                permissions: claims.permissions,
                                ip_address: extract_ip_address(&request),
                                user_agent: extract_user_agent(&request),
                                device_fingerprint: extract_device_fingerprint(&request),
                            };

                            request.extensions_mut().insert(AuthContext(context));
                        }
                    }
                }
            }
        }
    }

    next.run(request).await
}

/// ✅ SÉCURITÉ : Middleware de vérification de permission
pub fn require_permission(permission: &'static str) -> impl Fn(Request, Next) -> std::pin::Pin<Box<dyn std::future::Future<Output = Result<Response, AuthError>> + Send>> + Clone {
    move |request: Request, next: Next| {
        Box::pin(async move {
            // Extraire le contexte
            let context = request
                .extensions()
                .get::<AuthContext>()
                .ok_or(AuthError::InvalidToken)?;

            // Vérifier la permission
            if !context.0.permissions.contains(&permission.to_string()) {
                tracing::warn!(
                    user_id = %context.0.user_id,
                    permission = permission,
                    "Permission denied"
                );
                return Err(AuthError::PermissionDenied);
            }

            Ok(next.run(request).await)
        })
    }
}

// ============================================
// HELPER FUNCTIONS
// ============================================

/// Extraire le token JWT depuis cookies ou header
fn extract_token(request: &Request) -> Result<String, AuthError> {
    // 1. Priorité : Cookie HttpOnly (plus sécurisé)
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

    // 2. Fallback : Header Authorization Bearer
    if let Some(auth_header) = request.headers().get(header::AUTHORIZATION) {
        if let Ok(auth_str) = auth_header.to_str() {
            if let Some(token) = auth_str.strip_prefix("Bearer ") {
                return Ok(token.to_string());
            }
        }
    }

    Err(AuthError::InvalidToken)
}

/// Extraire l'adresse IP du client
fn extract_ip_address(request: &Request) -> Option<String> {
    // Vérifier X-Forwarded-For (derrière un proxy)
    if let Some(forwarded) = request.headers().get("X-Forwarded-For") {
        if let Ok(forwarded_str) = forwarded.to_str() {
            return Some(forwarded_str.split(',').next()?.trim().to_string());
        }
    }

    // Fallback sur X-Real-IP
    if let Some(real_ip) = request.headers().get("X-Real-IP") {
        if let Ok(ip_str) = real_ip.to_str() {
            return Some(ip_str.to_string());
        }
    }

    None
}

/// Extraire le User-Agent
fn extract_user_agent(request: &Request) -> Option<String> {
    request
        .headers()
        .get(header::USER_AGENT)
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string())
}

/// Extraire le device fingerprint depuis header custom
fn extract_device_fingerprint(request: &Request) -> Option<String> {
    request
        .headers()
        .get("X-Device-Fingerprint")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string())
}

/// Extractor pour obtenir le contexte depuis une route
pub async fn extract_auth_context(
    request: &Request,
) -> Result<RequestContext, AuthError> {
    request
        .extensions()
        .get::<AuthContext>()
        .map(|ctx| ctx.0.clone())
        .ok_or(AuthError::InvalidToken)
}