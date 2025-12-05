use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};

use crate::domain::JwtSession;
use crate::error::AuthError;

pub struct SessionRepository;

impl SessionRepository {
    /// ✅ SÉCURITÉ : Créer une nouvelle session JWT
    pub async fn create(
        pool: &PgPool,
        user_id: Uuid,
        access_token_hash: &str,
        refresh_token_hash: &str,
        expires_at: DateTime<Utc>,
        ip_address: Option<&str>,
        user_agent: Option<&str>,
        device_fingerprint: Option<&str>,
    ) -> Result<JwtSession, AuthError> {
        let session = sqlx::query_as::<_, JwtSession>(
            r#"
            INSERT INTO jwt_sessions (
                user_id, access_token_hash, refresh_token_hash,
                expires_at, ip_address, user_agent, device_fingerprint
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
            .bind(user_id)
            .bind(access_token_hash)
            .bind(refresh_token_hash)
            .bind(expires_at)
            .bind(ip_address)
            .bind(user_agent)
            .bind(device_fingerprint)
            .fetch_one(pool)
            .await?;

        Ok(session)
    }

    /// ✅ SÉCURITÉ : Trouver une session active par access token hash
    pub async fn find_by_access_token(
        pool: &PgPool,
        access_token_hash: &str,
    ) -> Result<JwtSession, AuthError> {
        let session = sqlx::query_as::<_, JwtSession>(
            r#"
            SELECT * FROM jwt_sessions
            WHERE access_token_hash = $1
              AND revoked_at IS NULL
              AND expires_at > NOW()
            "#,
        )
            .bind(access_token_hash)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::InvalidToken)?;

        Ok(session)
    }

    /// ✅ SÉCURITÉ : Trouver et consommer un refresh token (usage unique)
    pub async fn consume_refresh_token(
        pool: &PgPool,
        refresh_token_hash: &str,
    ) -> Result<JwtSession, AuthError> {
        let mut tx = pool.begin().await?;

        // 1. Trouver la session
        let session = sqlx::query_as::<_, JwtSession>(
            r#"
            SELECT * FROM jwt_sessions
            WHERE refresh_token_hash = $1
              AND revoked_at IS NULL
              AND expires_at > NOW()
            FOR UPDATE
            "#,
        )
            .bind(refresh_token_hash)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or(AuthError::InvalidToken)?;

        // 2. Révoquer immédiatement (refresh token à usage unique)
        sqlx::query(
            r#"
            UPDATE jwt_sessions
            SET revoked_at = NOW(), revoke_reason = 'refresh_consumed'
            WHERE id = $1
            "#,
        )
            .bind(session.id)
            .execute(&mut *tx)
            .await?;

        tx.commit().await?;

        Ok(session)
    }

    /// ✅ SÉCURITÉ : Mettre à jour last_used_at
    pub async fn update_last_used(pool: &PgPool, session_id: Uuid) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            UPDATE jwt_sessions
            SET last_used_at = NOW()
            WHERE id = $1
            "#,
        )
            .bind(session_id)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// ✅ SÉCURITÉ : Révoquer une session spécifique
    pub async fn revoke(
        pool: &PgPool,
        session_id: Uuid,
        reason: &str,
    ) -> Result<(), AuthError> {
        sqlx::query(
            r#"
            UPDATE jwt_sessions
            SET revoked_at = NOW(), revoke_reason = $1
            WHERE id = $2 AND revoked_at IS NULL
            "#,
        )
            .bind(reason)
            .bind(session_id)
            .execute(pool)
            .await?;

        Ok(())
    }

    /// ✅ SÉCURITÉ : Révoquer toutes les sessions d'un utilisateur
    pub async fn revoke_all_user_sessions(
        pool: &PgPool,
        user_id: Uuid,
        reason: &str,
    ) -> Result<i64, AuthError> {
        let result = sqlx::query(
            r#"
            UPDATE jwt_sessions
            SET revoked_at = NOW(), revoke_reason = $1
            WHERE user_id = $2 AND revoked_at IS NULL
            "#,
        )
            .bind(reason)
            .bind(user_id)
            .execute(pool)
            .await?;

        Ok(result.rows_affected() as i64)
    }

    /// Lister les sessions actives d'un utilisateur
    pub async fn list_user_sessions(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<JwtSession>, AuthError> {
        let sessions = sqlx::query_as::<_, JwtSession>(
            r#"
            SELECT * FROM jwt_sessions
            WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW()
            ORDER BY last_used_at DESC
            "#,
        )
            .bind(user_id)
            .fetch_all(pool)
            .await?;

        Ok(sessions)
    }

    /// ✅ SÉCURITÉ : Détecter les anomalies de session (nouveau device/IP)
    pub async fn detect_anomaly(
        pool: &PgPool,
        user_id: Uuid,
        ip_address: Option<&str>,
        device_fingerprint: Option<&str>,
    ) -> Result<bool, AuthError> {
        // Vérifier si cet IP/device a déjà été utilisé par cet utilisateur
        let known = sqlx::query_scalar::<_, bool>(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM jwt_sessions
                WHERE user_id = $1
                  AND (
                      (ip_address = $2 AND $2 IS NOT NULL) OR
                      (device_fingerprint = $3 AND $3 IS NOT NULL)
                  )
            )
            "#,
        )
            .bind(user_id)
            .bind(ip_address)
            .bind(device_fingerprint)
            .fetch_one(pool)
            .await?;

        // Anomalie = nouveau device/IP jamais vu
        Ok(!known)
    }

    /// Nettoyer les sessions expirées (maintenance)
    pub async fn cleanup_expired(pool: &PgPool, older_than_days: i32) -> Result<i64, AuthError> {
        let result = sqlx::query(
            r#"
            DELETE FROM jwt_sessions
            WHERE expires_at < NOW() - INTERVAL '1 day' * $1
            "#,
        )
            .bind(older_than_days)
            .execute(pool)
            .await?;

        Ok(result.rows_affected() as i64)
    }

    /// Compter les sessions actives d'un utilisateur
    pub async fn count_active_sessions(pool: &PgPool, user_id: Uuid) -> Result<i64, AuthError> {
        let count = sqlx::query_scalar::<_, i64>(
            r#"
            SELECT COUNT(*) FROM jwt_sessions
            WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW()
            "#,
        )
            .bind(user_id)
            .fetch_one(pool)
            .await?;

        Ok(count)
    }
}