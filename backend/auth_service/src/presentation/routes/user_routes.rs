use axum::{
    extract::{Path, State, Extension},
    http::HeaderMap,
    Json, Router,
    routing::{get, post, put, delete},
};
use serde_json::json;
use sqlx::PgPool;
use validator::Validate;
use uuid::Uuid;

use crate::application::{UserService, QuotaService};
use crate::domain::{
    UpdateUserRequest, ChangePasswordRequest, ConsumeQuotaRequest,
    RenewQuotaRequest,
};
use crate::error::AuthError;
use crate::presentation::middleware::AuthContext;

pub fn user_routes(pool: PgPool, user_service: UserService, quota_service: QuotaService) -> Router {
    Router::new()
        // Profile
        .route("/me", get(get_profile))
        .route("/me", put(update_profile))
        .route("/me/password", post(change_password))
        .route("/me", delete(delete_account))

        // Sessions
        .route("/me/sessions", get(list_sessions))
        .route("/me/sessions/:session_id", delete(revoke_session))

        // Quotas
        .route("/me/quotas", get(get_quotas))
        .route("/me/quotas/:quota_type", get(get_quota))
        .route("/me/quotas/:quota_type/consume", post(consume_quota))
        .route("/me/quotas/:quota_type/renew", post(renew_quota))

        // Permissions
        .route("/me/permissions", get(get_permissions))
        .route("/me/permissions/check", post(check_permission))

        .with_state((pool, user_service, quota_service))
}

// ============================================
// PROFILE
// ============================================

/// GET /users/me
async fn get_profile(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
) -> Result<Json<crate::domain::UserResponse>, AuthError> {
    let profile = user_service.get_profile(&pool, auth_context.0.user_id).await?;

    Ok(Json(profile))
}

/// PUT /users/me
async fn update_profile(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    headers: HeaderMap,
    Json(payload): Json<UpdateUserRequest>,
) -> Result<Json<crate::domain::UserResponse>, AuthError> {
    // Validation
    payload.validate()?;

    let ip_address = extract_ip_from_headers(&headers);

    let profile = user_service
        .update_profile(&pool, auth_context.0.user_id, payload, ip_address.as_deref())
        .await?;

    Ok(Json(profile))
}

/// POST /users/me/password
async fn change_password(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    headers: HeaderMap,
    Json(payload): Json<ChangePasswordRequest>,
) -> Result<Json<serde_json::Value>, AuthError> {
    // Validation
    payload.validate()?;

    let ip_address = extract_ip_from_headers(&headers);

    user_service
        .change_password(&pool, auth_context.0.user_id, payload, ip_address.as_deref())
        .await?;

    Ok(Json(json!({
        "message": "Password changed successfully. All sessions have been revoked."
    })))
}

/// DELETE /users/me
async fn delete_account(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    headers: HeaderMap,
) -> Result<Json<serde_json::Value>, AuthError> {
    let ip_address = extract_ip_from_headers(&headers);

    user_service
        .delete_account(&pool, auth_context.0.user_id, ip_address.as_deref())
        .await?;

    Ok(Json(json!({
        "message": "Account deleted successfully"
    })))
}

// ============================================
// SESSIONS
// ============================================

/// GET /users/me/sessions
async fn list_sessions(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
) -> Result<Json<Vec<crate::domain::SessionResponse>>, AuthError> {
    // Obtenir current session_id depuis JWT claims
    let current_session_id = None; // TODO: Extraire depuis JWT claims

    let sessions = user_service
        .list_sessions(&pool, auth_context.0.user_id, current_session_id)
        .await?;

    Ok(Json(sessions))
}

/// DELETE /users/me/sessions/:session_id
async fn revoke_session(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    headers: HeaderMap,
    Path(session_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AuthError> {
    let ip_address = extract_ip_from_headers(&headers);

    user_service
        .revoke_session(&pool, auth_context.0.user_id, session_id, ip_address.as_deref())
        .await?;

    Ok(Json(json!({
        "message": "Session revoked successfully"
    })))
}

// ============================================
// QUOTAS
// ============================================

/// GET /users/me/quotas
async fn get_quotas(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
) -> Result<Json<Vec<crate::domain::QuotaResponse>>, AuthError> {
    let quotas = user_service.get_quotas(&pool, auth_context.0.user_id).await?;

    Ok(Json(quotas))
}

/// GET /users/me/quotas/:quota_type
async fn get_quota(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(quota_type): Path<String>,
) -> Result<Json<crate::domain::QuotaResponse>, AuthError> {
    let quota = user_service
        .get_quota(&pool, auth_context.0.user_id, &quota_type)
        .await?;

    Ok(Json(quota))
}

/// POST /users/me/quotas/:quota_type/consume
async fn consume_quota(
    State((pool, _, quota_service)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(quota_type): Path<String>,
    Json(mut payload): Json<ConsumeQuotaRequest>,
) -> Result<Json<crate::domain::ConsumeQuotaResponse>, AuthError> {
    // Override quota_type depuis path
    payload.quota_type = quota_type;

    let response = quota_service
        .consume(&pool, auth_context.0.user_id, payload)
        .await?;

    Ok(Json(response))
}

/// POST /users/me/quotas/:quota_type/renew
async fn renew_quota(
    State((pool, _, quota_service)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(quota_type): Path<String>,
    Json(mut payload): Json<RenewQuotaRequest>,
) -> Result<Json<crate::domain::RenewQuotaResponse>, AuthError> {
    // Override quota_type depuis path
    payload.quota_type = quota_type;

    let response = quota_service
        .renew(&pool, auth_context.0.user_id, payload)
        .await?;

    Ok(Json(response))
}

// ============================================
// PERMISSIONS
// ============================================

/// GET /users/me/permissions
async fn get_permissions(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
) -> Result<Json<Vec<String>>, AuthError> {
    let permissions = user_service
        .get_permissions(&pool, auth_context.0.user_id)
        .await?;

    Ok(Json(permissions))
}

/// POST /users/me/permissions/check
async fn check_permission(
    State((pool, user_service, _)): State<(PgPool, UserService, QuotaService)>,
    Extension(auth_context): Extension<AuthContext>,
    Json(payload): Json<crate::domain::CheckPermissionRequest>,
) -> Result<Json<crate::domain::CheckPermissionResponse>, AuthError> {
    // ✅ SÉCURITÉ : Vérifier ownership - un user ne peut vérifier que ses propres permissions
    if auth_context.0.user_id != payload.user_id {
        return Err(AuthError::OwnershipRequired);
    }

    let has_permission = user_service
        .has_permission(&pool, auth_context.0.user_id, &payload.permission)
        .await?;

    Ok(Json(crate::domain::CheckPermissionResponse {
        allowed: has_permission,
        user_id: auth_context.0.user_id,
        permission: payload.permission,
    }))
}

// ============================================
// HELPERS
// ============================================

fn extract_ip_from_headers(headers: &HeaderMap) -> Option<String> {
    if let Some(forwarded) = headers.get("X-Forwarded-For") {
        if let Ok(forwarded_str) = forwarded.to_str() {
            return Some(forwarded_str.split(',').next()?.trim().to_string());
        }
    }

    if let Some(real_ip) = headers.get("X-Real-IP") {
        if let Ok(ip_str) = real_ip.to_str() {
            return Some(ip_str.to_string());
        }
    }

    None
}