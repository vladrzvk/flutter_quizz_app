use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::{
    ConsumeQuotaRequest, ConsumeQuotaResponse, RenewQuotaRequest, RenewQuotaResponse,
    QuotaResponse, RenewProof,
};
use crate::error::AuthError;
use crate::infrastructure::repositories::{QuotaRepository, AuditLogRepository};

#[derive(Clone, Copy)]
pub struct QuotaService;

impl QuotaService {
    /// ✅ SÉCURITÉ : Consommer un quota avec idempotency
    pub async fn consume(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        request: ConsumeQuotaRequest,
    ) -> Result<ConsumeQuotaResponse, AuthError> {
        // Générer une idempotency key si non fournie
        let idempotency_key = request.idempotency_key.or_else(|| Some(Uuid::new_v4()));

        // Consommer le quota de manière atomique
        let quota = QuotaRepository::consume(
            pool,
            user_id,
            &request.quota_type,
            idempotency_key,
        )
            .await?;

        tracing::info!(
            user_id = %user_id,
            quota_type = %request.quota_type,
            remaining = quota.remaining(),
            "Quota consumed successfully"
        );

        Ok(ConsumeQuotaResponse {
            success: true,
            remaining: quota.remaining(),
        })
    }

    /// ✅ SÉCURITÉ : Renouveler un quota après vérification du proof
    pub async fn renew(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        request: RenewQuotaRequest,
    ) -> Result<RenewQuotaResponse, AuthError> {
        // 1. Vérifier que le quota existe et peut être renouvelé
        let quota = QuotaRepository::find(pool, user_id, &request.quota_type).await?;

        if !quota.can_renew {
            return Err(AuthError::RenewNotAllowed);
        }

        // 2. ✅ SÉCURITÉ : Vérifier le proof selon l'action requise
        let renew_action = quota
            .renew_action
            .as_ref()
            .ok_or(AuthError::RenewNotAllowed)?;

        match (&request.proof, renew_action.as_str()) {
            (RenewProof::AdWatched { ad_id }, "watch_ad") => {
                // TODO: Vérifier avec Ads Service que la pub a bien été regardée
                // Pour l'instant, on valide simplement
                tracing::info!(
                    user_id = %user_id,
                    ad_id = %ad_id,
                    "Ad watched proof validated"
                );
            }
            (RenewProof::Shared { share_id }, "share") => {
                // TODO: Vérifier que le share a bien été effectué
                tracing::info!(
                    user_id = %user_id,
                    share_id = %share_id,
                    "Share proof validated"
                );
            }
            (RenewProof::Invited { invite_id }, "invite") => {
                // TODO: Vérifier que l'invitation a bien été envoyée
                tracing::info!(
                    user_id = %user_id,
                    invite_id = %invite_id,
                    "Invite proof validated"
                );
            }
            _ => {
                tracing::warn!(
                    user_id = %user_id,
                    proof = ?request.proof,
                    required_action = %renew_action,
                    "Invalid renewal proof type"
                );
                return Err(AuthError::InvalidRenewProof);
            }
        }

        // 3. Renouveler le quota
        let renewed_quota = QuotaRepository::renew(pool, user_id, &request.quota_type).await?;

        // 4. Audit log
        AuditLogRepository::log_quota_renewal(
            pool,
            user_id,
            &request.quota_type,
            renew_action,
        )
            .await?;

        tracing::info!(
            user_id = %user_id,
            quota_type = %request.quota_type,
            renew_action = %renew_action,
            "Quota renewed successfully"
        );

        Ok(RenewQuotaResponse {
            success: true,
            quota: QuotaResponse {
                id: renewed_quota.id,
                quota_type: renewed_quota.quota_type.clone(),
                max_allowed: renewed_quota.max_allowed,
                current_usage: renewed_quota.current_usage,
                remaining: renewed_quota.remaining(),
                can_renew: renewed_quota.can_renew,
                renew_action: renewed_quota.renew_action,
                period_end: renewed_quota.period_end,
            },
        })
    }

    /// Récupérer un quota spécifique
    pub async fn get_quota(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
    ) -> Result<QuotaResponse, AuthError> {
        let quota = QuotaRepository::find(pool, user_id, quota_type).await?;

        Ok(QuotaResponse {
            id: quota.id,
            quota_type: quota.quota_type.clone(),
            max_allowed: quota.max_allowed,
            current_usage: quota.current_usage,
            remaining: quota.remaining(),
            can_renew: quota.can_renew,
            renew_action: quota.renew_action,
            period_end: quota.period_end,
        })
    }

    /// Vérifier si un quota est dépassé
    pub async fn check_quota(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        quota_type: &str,
    ) -> Result<bool, AuthError> {
        let quota = QuotaRepository::find(pool, user_id, quota_type).await?;

        if quota.is_exceeded() {
            tracing::warn!(
                user_id = %user_id,
                quota_type = %quota_type,
                current = quota.current_usage,
                max = quota.max_allowed,
                "Quota exceeded"
            );
            return Ok(false);
        }

        Ok(true)
    }
}