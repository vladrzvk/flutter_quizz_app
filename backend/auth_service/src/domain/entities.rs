use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ============================================
// USER ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: Option<String>,

    // ✅ SÉCURITÉ : password_hash JAMAIS exposé dans les DTOs
    #[serde(skip_serializing)]
    pub password_hash: Option<String>,

    pub status: UserStatus,
    pub is_guest: bool,

    pub display_name: Option<String>,
    pub avatar_url: Option<String>,

    pub analytics_consent: bool,
    pub marketing_consent: bool,
    pub locale: String,

    pub metadata: serde_json::Value,

    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub last_login_at: Option<DateTime<Utc>>,
    pub deleted_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq, sqlx::Type)]
#[sqlx(type_name = "VARCHAR", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum UserStatus {
    Free,
    Premium,
    Trial,
    Suspended,
}

impl std::fmt::Display for UserStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            UserStatus::Free => write!(f, "free"),
            UserStatus::Premium => write!(f, "premium"),
            UserStatus::Trial => write!(f, "trial"),
            UserStatus::Suspended => write!(f, "suspended"),
        }
    }
}

// ============================================
// ROLE ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Role {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub priority: i32,
    pub is_system: bool,
    pub metadata: serde_json::Value,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

// ============================================
// PERMISSION ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Permission {
    pub id: Uuid,
    pub service: String,
    pub action: String,
    pub resource: String,
    pub name: String,
    pub description: Option<String>,
    pub metadata: serde_json::Value,
    pub created_at: DateTime<Utc>,
}

impl Permission {
    /// Format: "service:action:resource"
    pub fn full_name(&self) -> String {
        format!("{}:{}:{}", self.service, self.action, self.resource)
    }

    /// Parse permission depuis format "service:action:resource"
    pub fn parse(permission_str: &str) -> Option<(String, String, String)> {
        let parts: Vec<&str> = permission_str.split(':').collect();
        if parts.len() != 3 {
            return None;
        }
        Some((
            parts[0].to_string(),
            parts[1].to_string(),
            parts[2].to_string(),
        ))
    }
}

// ============================================
// USER_ROLE ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct UserRole {
    pub user_id: Uuid,
    pub role_id: Uuid,
    pub granted_at: DateTime<Utc>,
    pub granted_by: Option<Uuid>,
    pub expires_at: Option<DateTime<Utc>>,
    pub metadata: serde_json::Value,
}

// ============================================
// USER_QUOTA ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct UserQuota {
    pub id: Uuid,
    pub user_id: Uuid,
    pub quota_type: String,

    pub max_allowed: i32,
    pub current_usage: i32,

    pub period_type: Option<String>,
    pub period_start: Option<DateTime<Utc>>,
    pub period_end: Option<DateTime<Utc>>,

    pub can_renew: bool,
    pub renew_action: Option<String>,

    pub metadata: serde_json::Value,

    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl UserQuota {
    pub fn is_exceeded(&self) -> bool {
        self.current_usage >= self.max_allowed
    }

    pub fn is_expired(&self) -> bool {
        if let Some(end) = self.period_end {
            Utc::now() > end
        } else {
            false
        }
    }

    pub fn remaining(&self) -> i32 {
        (self.max_allowed - self.current_usage).max(0)
    }
}

// ============================================
// JWT_SESSION ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct JwtSession {
    pub id: Uuid,
    pub user_id: Uuid,

    #[serde(skip_serializing)]
    pub access_token_hash: String,

    #[serde(skip_serializing)]
    pub refresh_token_hash: String,

    pub issued_at: DateTime<Utc>,
    pub expires_at: DateTime<Utc>,
    pub last_used_at: DateTime<Utc>,

    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub device_fingerprint: Option<String>,

    pub revoked_at: Option<DateTime<Utc>>,
    pub revoke_reason: Option<String>,

    pub metadata: serde_json::Value,
}

impl JwtSession {
    pub fn is_active(&self) -> bool {
        self.revoked_at.is_none() && Utc::now() < self.expires_at
    }

    pub fn is_revoked(&self) -> bool {
        self.revoked_at.is_some()
    }
}

// ============================================
// LOGIN_ATTEMPT ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct LoginAttempt {
    pub id: Uuid,
    pub email: Option<String>,
    pub ip_address: String,
    pub success: bool,
    pub failure_reason: Option<String>,
    pub user_agent: Option<String>,
    pub device_fingerprint: Option<String>,
    pub attempted_at: DateTime<Utc>,
}

// ============================================
// DEVICE_FINGERPRINT ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct DeviceFingerprint {
    pub id: Uuid,
    pub user_id: Uuid,
    pub fingerprint: String,
    pub first_seen_at: DateTime<Utc>,
    pub last_seen_at: DateTime<Utc>,
    pub metadata: serde_json::Value,
}

// ============================================
// AUDIT_LOG ENTITY
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct AuditLog {
    pub id: Uuid,
    pub user_id: Option<Uuid>,
    pub action: String,
    pub resource_type: Option<String>,
    pub resource_id: Option<Uuid>,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub old_value: Option<serde_json::Value>,
    pub new_value: Option<serde_json::Value>,
    pub metadata: serde_json::Value,
    pub created_at: DateTime<Utc>,
}

// ============================================
// QUOTA_CONSUMPTION ENTITY (Idempotency)
// ============================================

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct QuotaConsumption {
    pub id: Uuid,
    pub idempotency_key: Uuid,
    pub user_id: Uuid,
    pub quota_type: String,
    pub consumed_at: DateTime<Utc>,
}