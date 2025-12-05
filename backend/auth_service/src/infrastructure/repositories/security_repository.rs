use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc, Duration};

use crate::domain::{LoginAttempt, DeviceFingerprint, AuditLog};
use crate::error::AuthError;

// ============================================
// LOGIN ATTEMPTS
// ============================================

pub struct LoginAttemptRepository;

impl LoginAttemptRepository {
    /// Enregistrer une tentative de login
    pub async fn record(
        pool: &PgPool,
        email: Option<&str>,
        ip_address: &str,
        success: bool,
        failure_reason: Option<&str>,
        user_agent: Option<&str>,
        device_fingerprint: Option<&str>,
    ) -> Result<LoginAttempt, AuthError> {
        let attempt = sqlx::query_as::<_, LoginAttempt>(
            r#"
            INSERT INTO login_attempts (
                email, ip_address, success, failure_reason,
                user_agent, device_fingerprint
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
            "#,
        )
            .bind(email)
            .bind(ip_address)
            .bind(success)
            .bind(failure_reason)
            .bind(user_agent)
            .bind(device_fingerprint)
            .fetch_one(pool)
            .await?;

        Ok(attempt)
    }

    /// Compter les échecs récents par IP
    pub async fn count_recent_failures_by_ip(
        pool: &PgPool,
        ip_address: &str,
        minutes: i64,
    ) -> Result<i64, AuthError> {
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE ip_address = $1
              AND success = false
              AND attempted_at > NOW() - INTERVAL '1 minute' * $2
            "#,
        )
            .bind(ip_address)
            .bind(minutes)
            .fetch_one(pool)
            .await?;

        Ok(count)
    }

    /// Compter les échecs récents par email
    pub async fn count_recent_failures_by_email(
        pool: &PgPool,
        email: &str,
        minutes: i64,
    ) -> Result<i64, AuthError> {
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM login_attempts
            WHERE email = $1
              AND success = false
              AND attempted_at > NOW() - INTERVAL '1 minute' * $2
            "#,
        )
            .bind(email)
            .bind(minutes)
            .fetch_one(pool)
            .await?;

        Ok(count)
    }

    /// Vérifier si un compte est bloqué
    pub async fn is_account_locked(
        pool: &PgPool,
        email: &str,
        max_attempts: i64,
        lockout_minutes: i64,
    ) -> Result<bool, AuthError> {
        let failures = Self::count_recent_failures_by_email(pool, email, lockout_minutes).await?;
        Ok(failures >= max_attempts)
    }

    /// Nettoyer les anciennes tentatives (maintenance)
    pub async fn cleanup_old(pool: &PgPool, older_than_days: i32) -> Result<i64, AuthError> {
        let result = sqlx::query(
            r#"
            DELETE FROM login_attempts
            WHERE attempted_at < NOW() - INTERVAL '1 day' * $1
            "#,
        )
            .bind(older_than_days)
            .execute(pool)
            .await?;

        Ok(result.rows_affected() as i64)
    }
}

// ============================================
// DEVICE FINGERPRINTS
// ============================================

pub struct DeviceFingerprintRepository;

impl DeviceFingerprintRepository {
    /// Enregistrer ou mettre à jour un device fingerprint
    pub async fn upsert(
        pool: &PgPool,
        user_id: Uuid,
        fingerprint: &str,
    ) -> Result<DeviceFingerprint, AuthError> {
        let device = sqlx::query_as::<_, DeviceFingerprint>(
            r#"
            INSERT INTO device_fingerprints (user_id, fingerprint)
            VALUES ($1, $2)
            ON CONFLICT (user_id, fingerprint)
            DO UPDATE SET last_seen_at = NOW()
            RETURNING *
            "#,
        )
            .bind(user_id)
            .bind(fingerprint)
            .fetch_one(pool)
            .await?;

        Ok(device)
    }

    /// Compter le nombre de guests pour un fingerprint
    pub async fn count_guests_for_fingerprint(
        pool: &PgPool,
        fingerprint: &str,
    ) -> Result<i64, AuthError> {
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(DISTINCT df.user_id)
            FROM device_fingerprints df
            INNER JOIN users u ON df.user_id = u.id
            WHERE df.fingerprint = $1
              AND u.is_guest = true
              AND u.deleted_at IS NULL
            "#,
        )
            .bind(fingerprint)
            .fetch_one(pool)
            .await?;

        Ok(count)
    }

    /// Lister les devices d'un utilisateur
    pub async fn list_user_devices(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<DeviceFingerprint>, AuthError> {
        let devices = sqlx::query_as::<_, DeviceFingerprint>(
            r#"
            SELECT * FROM device_fingerprints
            WHERE user_id = $1
            ORDER BY last_seen_at DESC
            "#,
        )
            .bind(user_id)
            .fetch_all(pool)
            .await?;

        Ok(devices)
    }
}

// ============================================
// AUDIT LOGS
// ============================================

pub struct AuditLogRepository;

impl AuditLogRepository {
    /// Logger une action simple
    pub async fn log_action(
        pool: &PgPool,
        user_id: Option<Uuid>,
        action: &str,
        ip_address: Option<&str>,
    ) -> Result<AuditLog, AuthError> {
        Self::log(
            pool,
            user_id,
            action,
            None,
            None,
            ip_address,
            None,
            None,
            None,
            None,
        )
            .await
    }

    /// Logger une action complète
    pub async fn log(
        pool: &PgPool,
        user_id: Option<Uuid>,
        action: &str,
        resource_type: Option<&str>,
        resource_id: Option<Uuid>,
        ip_address: Option<&str>,
        user_agent: Option<&str>,
        old_value: Option<serde_json::Value>,
        new_value: Option<serde_json::Value>,
        metadata: Option<serde_json::Value>,
    ) -> Result<AuditLog, AuthError> {
        let log = sqlx::query_as::<_, AuditLog>(
            r#"
            INSERT INTO audit_logs (
                user_id, action, resource_type, resource_id,
                ip_address, user_agent, old_value, new_value, metadata
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
            "#,
        )
            .bind(user_id)
            .bind(action)
            .bind(resource_type)
            .bind(resource_id)
            .bind(ip_address)
            .bind(user_agent)
            .bind(old_value)
            .bind(new_value)
            .bind(metadata.unwrap_or(serde_json::json!({})))
            .fetch_one(pool)
            .await?;

        Ok(log)
    }

    /// Logger un renouvellement de quota
    pub async fn log_quota_renewal(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
        renew_action: &str,
    ) -> Result<AuditLog, AuthError> {
        Self::log(
            pool,
            Some(user_id),
            "quota_renewed",
            Some("user_quota"),
            None,
            None,
            None,
            None,
            None,
            Some(serde_json::json!({
                "quota_type": quota_type,
                "renew_action": renew_action,
            })),
        )
            .await
    }

    /// Lister les logs d'un utilisateur
    pub async fn list_user_logs(
        pool: &PgPool,
        user_id: Uuid,
        limit: i64,
    ) -> Result<Vec<AuditLog>, AuthError> {
        let logs = sqlx::query_as::<_, AuditLog>(
            r#"
            SELECT * FROM audit_logs
            WHERE user_id = $1
            ORDER BY created_at DESC
            LIMIT $2
            "#,
        )
            .bind(user_id)
            .bind(limit)
            .fetch_all(pool)
            .await?;

        Ok(logs)
    }

    /// Nettoyer les anciens logs (maintenance)
    pub async fn cleanup_old(pool: &PgPool, older_than_days: i32) -> Result<i64, AuthError> {
        let result = sqlx::query(
            r#"
            DELETE FROM audit_logs
            WHERE created_at < NOW() - INTERVAL '1 day' * $1
            "#,
        )
            .bind(older_than_days)
            .execute(pool)
            .await?;

        Ok(result.rows_affected() as i64)
    }
}