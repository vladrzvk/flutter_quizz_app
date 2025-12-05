use axum::{
    extract::{Path, Query, State, Extension},
    http::HeaderMap,
    Json, Router,
    routing::{get, post, put, delete},
};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;

use crate::application::UserService;
use crate::domain::{
    UpdateUserStatusRequest, ListUsersQuery, CreatePermissionRequest,
    CreateRoleRequest, AssignRoleRequest,
};
use crate::error::AuthError;
use crate::infrastructure::repositories::{PermissionRepository, RoleRepository};
use crate::presentation::middleware::AuthContext;

pub fn admin_routes(pool: PgPool, user_service: UserService) -> Router {
    Router::new()
        // Users management
        .route("/users", get(list_users))
        .route("/users/:user_id", get(get_user))
        .route("/users/:user_id/status", put(update_user_status))
        .route("/users/:user_id", delete(delete_user))

        // Roles management
        .route("/roles", get(list_roles))
        .route("/roles", post(create_role))
        .route("/roles/:role_id", get(get_role))
        .route("/roles/:role_id", delete(delete_role))
        .route("/roles/:role_id/permissions", get(list_role_permissions))
        .route("/roles/:role_id/permissions/:permission_id", post(assign_permission_to_role))
        .route("/roles/:role_id/permissions/:permission_id", delete(remove_permission_from_role))

        // User roles
        .route("/users/:user_id/roles", get(list_user_roles))
        .route("/users/:user_id/roles", post(assign_role_to_user))
        .route("/users/:user_id/roles/:role_id", delete(remove_role_from_user))

        // Permissions management
        .route("/permissions", get(list_permissions))
        .route("/permissions", post(create_permission))

        .with_state((pool, user_service))
}

// ============================================
// USERS MANAGEMENT
// ============================================

/// GET /admin/users
async fn list_users(
    State((pool, user_service)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Query(query): Query<ListUsersQuery>,
) -> Result<Json<crate::domain::PaginatedResponse<crate::domain::UserResponse>>, AuthError> {
    let page = query.page.unwrap_or(1).max(1);
    let per_page = query.per_page.unwrap_or(20).clamp(1, 100);

    let result = user_service
        .list_users(
            &pool,
            auth_context.0.user_id,
            page,
            per_page,
            query.status,
            query.is_guest,
            query.search,
        )
        .await?;

    Ok(Json(result))
}

/// GET /admin/users/:user_id
async fn get_user(
    State((pool, user_service)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<crate::domain::UserResponse>, AuthError> {
    // Vérifier permission admin
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let user = user_service.get_profile(&pool, user_id).await?;

    Ok(Json(user))
}

/// PUT /admin/users/:user_id/status
async fn update_user_status(
    State((pool, user_service)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    headers: HeaderMap,
    Path(user_id): Path<Uuid>,
    Json(payload): Json<UpdateUserStatusRequest>,
) -> Result<Json<crate::domain::UserResponse>, AuthError> {
    let ip_address = extract_ip_from_headers(&headers);

    let user = user_service
        .update_user_status(
            &pool,
            auth_context.0.user_id,
            user_id,
            payload,
            ip_address.as_deref(),
        )
        .await?;

    Ok(Json(user))
}

/// DELETE /admin/users/:user_id
async fn delete_user(
    State((pool, user_service)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    headers: HeaderMap,
    Path(user_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let ip_address = extract_ip_from_headers(&headers);

    user_service
        .delete_account(&pool, user_id, ip_address.as_deref())
        .await?;

    Ok(Json(json!({
        "message": "User deleted successfully"
    })))
}

// ============================================
// ROLES MANAGEMENT
// ============================================

/// GET /admin/roles
async fn list_roles(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
) -> Result<Json<Vec<crate::domain::RoleResponse>>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let roles = RoleRepository::list_all(&pool).await?;

    let responses: Vec<_> = roles
        .into_iter()
        .map(|r| crate::domain::RoleResponse {
            id: r.id,
            name: r.name,
            description: r.description,
            priority: r.priority,
            is_system: r.is_system,
        })
        .collect();

    Ok(Json(responses))
}

/// POST /admin/roles
async fn create_role(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Json(payload): Json<CreateRoleRequest>,
) -> Result<Json<crate::domain::RoleResponse>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    payload.validate()?;

    let role = RoleRepository::create(
        &pool,
        &payload.name,
        payload.description.as_deref(),
        payload.priority.unwrap_or(0),
    )
        .await?;

    Ok(Json(crate::domain::RoleResponse {
        id: role.id,
        name: role.name,
        description: role.description,
        priority: role.priority,
        is_system: role.is_system,
    }))
}

/// GET /admin/roles/:role_id
async fn get_role(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(role_id): Path<Uuid>,
) -> Result<Json<crate::domain::RoleResponse>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let role = RoleRepository::find_by_id(&pool, role_id).await?;

    Ok(Json(crate::domain::RoleResponse {
        id: role.id,
        name: role.name,
        description: role.description,
        priority: role.priority,
        is_system: role.is_system,
    }))
}

/// DELETE /admin/roles/:role_id
async fn delete_role(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(role_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    RoleRepository::delete(&pool, role_id).await?;

    Ok(Json(json!({
        "message": "Role deleted successfully"
    })))
}

// ============================================
// ROLE PERMISSIONS
// ============================================

/// GET /admin/roles/:role_id/permissions
async fn list_role_permissions(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(role_id): Path<Uuid>,
) -> Result<Json<Vec<crate::domain::PermissionResponse>>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let permissions = PermissionRepository::list_role_permissions(&pool, role_id).await?;

    let responses: Vec<_> = permissions
        .into_iter()
        .map(|p| crate::domain::PermissionResponse {
            id: p.id,
            name: p.name,
            service: p.service,
            action: p.action,
            resource: p.resource,
            description: p.description,
        })
        .collect();

    Ok(Json(responses))
}

/// POST /admin/roles/:role_id/permissions/:permission_id
async fn assign_permission_to_role(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path((role_id, permission_id)): Path<(Uuid, Uuid)>,
) -> Result<Json<serde_json::Value>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    PermissionRepository::assign_to_role(&pool, role_id, permission_id).await?;

    Ok(Json(json!({
        "message": "Permission assigned to role successfully"
    })))
}

/// DELETE /admin/roles/:role_id/permissions/:permission_id
async fn remove_permission_from_role(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path((role_id, permission_id)): Path<(Uuid, Uuid)>,
) -> Result<Json<serde_json::Value>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    PermissionRepository::remove_from_role(&pool, role_id, permission_id).await?;

    Ok(Json(json!({
        "message": "Permission removed from role successfully"
    })))
}

// ============================================
// USER ROLES
// ============================================

/// GET /admin/users/:user_id/roles
async fn list_user_roles(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(user_id): Path<Uuid>,
) -> Result<Json<Vec<crate::domain::RoleResponse>>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let roles = RoleRepository::list_user_roles(&pool, user_id).await?;

    let responses: Vec<_> = roles
        .into_iter()
        .map(|r| crate::domain::RoleResponse {
            id: r.id,
            name: r.name,
            description: r.description,
            priority: r.priority,
            is_system: r.is_system,
        })
        .collect();

    Ok(Json(responses))
}

/// POST /admin/users/:user_id/roles
async fn assign_role_to_user(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path(user_id): Path<Uuid>,
    Json(payload): Json<AssignRoleRequest>,
) -> Result<Json<serde_json::Value>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    RoleRepository::assign_to_user(
        &pool,
        user_id,
        payload.role_id,
        Some(auth_context.0.user_id),
        payload.expires_at,
    )
        .await?;

    Ok(Json(json!({
        "message": "Role assigned to user successfully"
    })))
}

/// DELETE /admin/users/:user_id/roles/:role_id
async fn remove_role_from_user(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Path((user_id, role_id)): Path<(Uuid, Uuid)>,
) -> Result<Json<serde_json::Value>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    RoleRepository::remove_from_user(&pool, user_id, role_id).await?;

    Ok(Json(json!({
        "message": "Role removed from user successfully"
    })))
}

// ============================================
// PERMISSIONS MANAGEMENT
// ============================================

/// GET /admin/permissions
async fn list_permissions(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
) -> Result<Json<Vec<crate::domain::PermissionResponse>>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    let permissions = PermissionRepository::list_all(&pool).await?;

    let responses: Vec<_> = permissions
        .into_iter()
        .map(|p| crate::domain::PermissionResponse {
            id: p.id,
            name: p.name,
            service: p.service,
            action: p.action,
            resource: p.resource,
            description: p.description,
        })
        .collect();

    Ok(Json(responses))
}

/// POST /admin/permissions
async fn create_permission(
    State((pool, _)): State<(PgPool, UserService)>,
    Extension(auth_context): Extension<AuthContext>,
    Json(payload): Json<CreatePermissionRequest>,
) -> Result<Json<crate::domain::PermissionResponse>, AuthError> {
    check_admin_permission(&pool, auth_context.0.user_id).await?;

    payload.validate()?;

    let permission = PermissionRepository::create(
        &pool,
        &payload.service,
        &payload.action,
        &payload.resource,
        &payload.name,
        payload.description.as_deref(),
    )
        .await?;

    Ok(Json(crate::domain::PermissionResponse {
        id: permission.id,
        name: permission.name,
        service: permission.service,
        action: permission.action,
        resource: permission.resource,
        description: permission.description,
    }))
}

// ============================================
// HELPERS
// ============================================

async fn check_admin_permission(pool: &PgPool, user_id: Uuid) -> Result<(), AuthError> {
    let has_permission = PermissionRepository::user_has_permission(
        pool,
        user_id,
        "admin:manage:all",
    )
        .await?;

    if !has_permission {
        return Err(AuthError::PermissionDenied);
    }

    Ok(())
}

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