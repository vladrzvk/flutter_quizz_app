use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};

use crate::domain::{UserQuota, QuotaConsumption};
use crate::error::AuthError;

pub struct QuotaRepository;

impl QuotaRepository {
    /// Créer un quota pour un utilisateur
    pub async fn create(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
        max_allowed: i32,
        can_renew: bool,
        renew_action: Option<&str>,
        period_type: Option<&str>,
        period_start: Option<DateTime<Utc>>,
        period_end: Option<DateTime<Utc>>,
    ) -> Result<UserQuota, AuthError> {
        let quota = sqlx::query_as::<_, UserQuota>(
            r#"
            INSERT INTO user_quotas (
                user_id, quota_type, max_allowed, current_usage,
                can_renew, renew_action,
                period_type, period_start, period_end
            )
            VALUES ($1, $2, $3, 0, $4, $5, $6, $7, $8)
            RETURNING *
            "#,
        )
            .bind(user_id)
            .bind(quota_type)
            .bind(max_allowed)
            .bind(can_renew)
            .bind(renew_action)
            .bind(period_type)
            .bind(period_start)
            .bind(period_end)
            .fetch_one(pool)
            .await?;

        Ok(quota)
    }

    /// Trouver un quota par user_id et type
    pub async fn find(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
    ) -> Result<UserQuota, AuthError> {
        let quota = sqlx::query_as::<_, UserQuota>(
            r#"
            SELECT * FROM user_quotas
            WHERE user_id = $1 AND quota_type = $2
            "#,
        )
            .bind(user_id)
            .bind(quota_type)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(quota)
    }

    /// ✅ SÉCURITÉ : Consommer un quota de manière atomique avec idempotency
    pub async fn consume(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
        idempotency_key: Option<Uuid>,
    ) -> Result<UserQuota, AuthError> {
        let mut tx = pool.begin().await?;

        // 1. Vérifier idempotency si key fournie
        if let Some(key) = idempotency_key {
            let already_consumed = sqlx::query_scalar::<_, bool>(
                r#"
                SELECT EXISTS(
                    SELECT 1 FROM quota_consumptions
                    WHERE idempotency_key = $1
                )
                "#,
            )
                .bind(key)
                .fetch_one(&mut *tx)
                .await?;

            if already_consumed {
                tx.rollback().await?;
                return Err(AuthError::IdempotencyConflict);
            }
        }

        // 2. Verrouiller le quota avec FOR UPDATE
        let quota = sqlx::query_as::<_, UserQuota>(
            r#"
            SELECT * FROM user_quotas
            WHERE user_id = $1 AND quota_type = $2
            FOR UPDATE
            "#,
        )
            .bind(user_id)
            .bind(quota_type)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or(AuthError::NotFound)?;

        // 3. Vérifier si quota dépassé
        if quota.current_usage >= quota.max_allowed {
            tx.rollback().await?;
            return Err(AuthError::QuotaExceeded);
        }

        // 4. Vérifier si période expirée (auto-reset)
        let should_reset = if let Some(end) = quota.period_end {
            Utc::now() > end
        } else {
            false
        };

        let updated_quota = if should_reset {
            // Reset automatique si période expirée
            sqlx::query_as::<_, UserQuota>(
                r#"
                UPDATE user_quotas
                SET current_usage = 1,
                    period_start = NOW(),
                    period_end = CASE
                        WHEN period_type = 'daily' THEN NOW() + INTERVAL '1 day'
                        WHEN period_type = 'weekly' THEN NOW() + INTERVAL '7 days'
                        WHEN period_type = 'monthly' THEN NOW() + INTERVAL '1 month'
                        ELSE period_end
                    END,
                    updated_at = NOW()
                WHERE id = $1
                RETURNING *
                "#,
            )
                .bind(quota.id)
                .fetch_one(&mut *tx)
                .await?
        } else {
            // Incrémenter simplement
            sqlx::query_as::<_, UserQuota>(
                r#"
                UPDATE user_quotas
                SET current_usage = current_usage + 1, updated_at = NOW()
                WHERE id = $1
                RETURNING *
                "#,
            )
                .bind(quota.id)
                .fetch_one(&mut *tx)
                .await?
        };

        // 5. Enregistrer la consommation si idempotency_key fournie
        if let Some(key) = idempotency_key {
            sqlx::query(
                r#"
                INSERT INTO quota_consumptions (idempotency_key, user_id, quota_type)
                VALUES ($1, $2, $3)
                "#,
            )
                .bind(key)
                .bind(user_id)
                .bind(quota_type)
                .execute(&mut *tx)
                .await?;
        }

        tx.commit().await?;

        Ok(updated_quota)
    }

    /// ✅ SÉCURITÉ : Renouveler un quota (après vérification proof)
    pub async fn renew(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
    ) -> Result<UserQuota, AuthError> {
        let mut tx = pool.begin().await?;

        // 1. Verrouiller et vérifier le quota
        let quota = sqlx::query_as::<_, UserQuota>(
            r#"
            SELECT * FROM user_quotas
            WHERE user_id = $1 AND quota_type = $2
            FOR UPDATE
            "#,
        )
            .bind(user_id)
            .bind(quota_type)
            .fetch_optional(&mut *tx)
            .await?
            .ok_or(AuthError::NotFound)?;

        if !quota.can_renew {
            tx.rollback().await?;
            return Err(AuthError::RenewNotAllowed);
        }

        // 2. Reset le quota
        let renewed_quota = sqlx::query_as::<_, UserQuota>(
            r#"
            UPDATE user_quotas
            SET current_usage = 0, updated_at = NOW()
            WHERE id = $1
            RETURNING *
            "#,
        )
            .bind(quota.id)
            .fetch_one(&mut *tx)
            .await?;

        tx.commit().await?;

        Ok(renewed_quota)
    }

    /// Lister tous les quotas d'un utilisateur
    pub async fn list_user_quotas(
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<UserQuota>, AuthError> {
        let quotas = sqlx::query_as::<_, UserQuota>(
            r#"
            SELECT * FROM user_quotas
            WHERE user_id = $1
            ORDER BY quota_type
            "#,
        )
            .bind(user_id)
            .fetch_all(pool)
            .await?;

        Ok(quotas)
    }

    /// Mettre à jour la limite d'un quota (admin)
    pub async fn update_limit(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
        new_max_allowed: i32,
    ) -> Result<UserQuota, AuthError> {
        let quota = sqlx::query_as::<_, UserQuota>(
            r#"
            UPDATE user_quotas
            SET max_allowed = $1, updated_at = NOW()
            WHERE user_id = $2 AND quota_type = $3
            RETURNING *
            "#,
        )
            .bind(new_max_allowed)
            .bind(user_id)
            .bind(quota_type)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(quota)
    }

    /// Reset manuel d'un quota (admin)
    pub async fn reset(
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
    ) -> Result<UserQuota, AuthError> {
        let quota = sqlx::query_as::<_, UserQuota>(
            r#"
            UPDATE user_quotas
            SET current_usage = 0, updated_at = NOW()
            WHERE user_id = $1 AND quota_type = $2
            RETURNING *
            "#,
        )
            .bind(user_id)
            .bind(quota_type)
            .fetch_optional(pool)
            .await?
            .ok_or(AuthError::NotFound)?;

        Ok(quota)
    }

    /// Nettoyer les anciennes consommations (maintenance)
    pub async fn cleanup_old_consumptions(
        pool: &PgPool,
        older_than_days: i32,
    ) -> Result<i64, AuthError> {
        let result = sqlx::query(
            r#"
            DELETE FROM quota_consumptions
            WHERE consumed_at < NOW() - INTERVAL '1 day' * $1
            "#,
        )
            .bind(older_than_days)
            .execute(pool)
            .await?;

        Ok(result.rows_affected() as i64)
    }
}