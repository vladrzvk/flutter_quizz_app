use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use super::entities::{User, UserStatus};

// ============================================
// AUTHENTICATION DTOs
// ============================================

#[derive(Debug, Deserialize, Validate)]
pub struct RegisterRequest {
    #[validate(email, length(max = 255))]
    pub email: String,

    #[validate(length(min = 8, max = 128))]
    pub password: String,

    #[validate(length(min = 1, max = 100))]
    pub display_name: Option<String>,

    #[validate(length(max = 10))]
    pub locale: Option<String>,

    pub analytics_consent: Option<bool>,
    pub marketing_consent: Option<bool>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct LoginRequest {
    #[validate(email)]
    pub email: String,

    #[validate(length(min = 1))]
    pub password: String,

    pub captcha_response: Option<String>,

    pub device_fingerprint: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RefreshTokenRequest {
    pub device_fingerprint: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
    pub user: UserResponse,
}

#[derive(Debug, Deserialize)]
pub struct CreateGuestRequest {
    pub device_fingerprint: Option<String>,
    pub locale: Option<String>,
}

// ============================================
// USER DTOs
// ============================================

/// ✅ SÉCURITÉ : DTO sans champs sensibles
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub email: Option<String>,
    pub status: UserStatus,
    pub is_guest: bool,
    pub display_name: Option<String>,
    pub avatar_url: Option<String>,
    pub locale: String,
    pub created_at: DateTime<Utc>,
    pub last_login_at: Option<DateTime<Utc>>,
}

impl From<User> for UserResponse {
    fn from(user: User) -> Self {
        Self {
            id: user.id,
            email: user.email,
            status: user.status,
            is_guest: user.is_guest,
            display_name: user.display_name,
            avatar_url: user.avatar_url,
            locale: user.locale,
            created_at: user.created_at,
            last_login_at: user.last_login_at,
        }
    }
}

#[derive(Debug, Deserialize, Serialize, Validate)]
pub struct UpdateUserRequest {
    #[validate(length(min = 1, max = 100), custom(function = "validate_no_html"))]
    pub display_name: Option<String>,

    #[validate(url, length(max = 500))]
    pub avatar_url: Option<String>,

    #[validate(length(max = 10))]
    pub locale: Option<String>,

    pub analytics_consent: Option<bool>,
    pub marketing_consent: Option<bool>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct ChangePasswordRequest {
    #[validate(length(min = 1))]
    pub current_password: String,

    #[validate(length(min = 8, max = 128))]
    pub new_password: String,
}

// ============================================
// PERMISSION DTOs
// ============================================

#[derive(Debug, Serialize, Deserialize)]
pub struct PermissionResponse {
    pub id: Uuid,
    pub name: String,
    pub service: String,
    pub action: String,
    pub resource: String,
    pub description: Option<String>,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreatePermissionRequest {
    #[validate(length(min = 1, max = 50))]
    pub service: String,

    #[validate(length(min = 1, max = 50))]
    pub action: String,

    #[validate(length(min = 1, max = 100))]
    pub resource: String,

    #[validate(length(min = 1, max = 100))]
    pub name: String,

    pub description: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CheckPermissionRequest {
    pub user_id: Uuid,
    pub permission: String,  // Format: "service:action:resource"
}

#[derive(Debug, Serialize)]
pub struct CheckPermissionResponse {
    pub allowed: bool,
    pub user_id: Uuid,
    pub permission: String,
}

// ============================================
// ROLE DTOs
// ============================================

#[derive(Debug, Serialize)]
pub struct RoleResponse {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub priority: i32,
    pub is_system: bool,
}

#[derive(Debug, Deserialize, Validate)]
pub struct CreateRoleRequest {
    #[validate(length(min = 1, max = 50))]
    pub name: String,

    pub description: Option<String>,
    pub priority: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct AssignRoleRequest {
    pub user_id: Uuid,
    pub role_id: Uuid,
    pub expires_at: Option<DateTime<Utc>>,
}

// ============================================
// QUOTA DTOs
// ============================================

#[derive(Debug, Serialize)]
pub struct QuotaResponse {
    pub id: Uuid,
    pub quota_type: String,
    pub max_allowed: i32,
    pub current_usage: i32,
    pub remaining: i32,
    pub can_renew: bool,
    pub renew_action: Option<String>,
    pub period_end: Option<DateTime<Utc>>,
}

#[derive(Debug, Deserialize)]
pub struct ConsumeQuotaRequest {
    pub quota_type: String,
    pub idempotency_key: Option<Uuid>,
}

#[derive(Debug, Serialize)]
pub struct ConsumeQuotaResponse {
    pub success: bool,
    pub remaining: i32,
}

#[derive(Debug, Deserialize, Validate)]
pub struct RenewQuotaRequest {
    pub quota_type: String,
    pub proof: RenewProof,
}

#[derive(Debug, Deserialize, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum RenewProof {
    AdWatched { ad_id: String },
    Shared { share_id: String },
    Invited { invite_id: String },
}

#[derive(Debug, Serialize)]
pub struct RenewQuotaResponse {
    pub success: bool,
    pub quota: QuotaResponse,
}

// ============================================
// SESSION DTOs
// ============================================

#[derive(Debug, Serialize)]
pub struct SessionResponse {
    pub id: Uuid,
    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub last_used_at: DateTime<Utc>,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub is_current: bool,
}

#[derive(Debug, Deserialize)]
pub struct RevokeSessionRequest {
    pub session_id: Uuid,
    pub reason: Option<String>,
}

// ============================================
// ADMIN DTOs
// ============================================

#[derive(Debug, Deserialize, Validate)]
pub struct UpdateUserStatusRequest {
    pub status: UserStatus,
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct ListUsersQuery {
    pub page: Option<u32>,
    pub per_page: Option<u32>,
    pub status: Option<UserStatus>,
    pub is_guest: Option<bool>,
    pub search: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct PaginatedResponse<T> {
    pub data: Vec<T>,
    pub page: u32,
    pub per_page: u32,
    pub total: i64,
    pub total_pages: u32,
}

// ============================================
// VALIDATION HELPERS
// ============================================

/// Validation personnalisée : pas de HTML
fn validate_no_html(value: &str) -> Result<(), validator::ValidationError> {
    if value.contains('<') || value.contains('>') {
        return Err(validator::ValidationError::new("html_not_allowed"));
    }
    Ok(())
}

// ============================================
// CONTEXT DTOs (pour middleware)
// ============================================

#[derive(Debug, Clone)]
pub struct RequestContext {
    pub user_id: Uuid,
    pub status: UserStatus,
    pub is_guest: bool,
    pub permissions: Vec<String>,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub device_fingerprint: Option<String>,
}

// ============================================
// JWT Claims
// ============================================

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,           // user_id
    pub status: String,        // UserStatus
    pub is_guest: bool,
    pub permissions: Vec<String>,
    pub exp: i64,              // Expiration timestamp
    pub iat: i64,              // Issued at timestamp
    pub jti: String,           // JWT ID (session_id)
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RefreshClaims {
    pub sub: String,           // user_id
    pub exp: i64,
    pub iat: i64,
    pub jti: String,           // session_id
}