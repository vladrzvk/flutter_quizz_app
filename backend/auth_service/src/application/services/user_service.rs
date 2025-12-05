use sqlx::PgPool;
use uuid::Uuid;

use crate::domain::{
    User, UserResponse, UpdateUserRequest, ChangePasswordRequest,
    UserStatus, UpdateUserStatusRequest, QuotaResponse,
};
use crate::error::AuthError;
use crate::infrastructure::repositories::{
    UserRepository, SessionRepository, QuotaRepository, PermissionRepository,
    AuditLogRepository,
};
use super::{PasswordService, SecurityService};


#[derive(Clone)]
pub struct UserService {
    password_service: PasswordService,
    security_service: SecurityService,
}

impl UserService {
    pub fn new(bcrypt_cost: u32) -> Self {
        let password_service = PasswordService::new(bcrypt_cost);
        let security_service = SecurityService::new(
            crate::config::Config::from_env().unwrap()
        );

        Self {
            password_service,
            security_service,
        }
    }

    // ============================================
    // PROFILE MANAGEMENT
    // ============================================

    /// Récupérer le profil utilisateur
    pub async fn get_profile(
        &self,
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<UserResponse, AuthError> {
        let user = UserRepository::find_by_id(pool, user_id).await?;
        Ok(UserResponse::from(user))
    }

    /// ✅ SÉCURITÉ : Mise à jour du profil avec validation stricte
    pub async fn update_profile(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        request: UpdateUserRequest,
        ip_address: Option<&str>,
    ) -> Result<UserResponse, AuthError> {
        // 1. Sanitize display_name si fourni
        let display_name = request
            .display_name
            .as_ref()
            .map(|name| SecurityService::sanitize_display_name(name))
            .transpose()?;

        // 2. Mettre à jour le profil
        let user = UserRepository::update_profile(
            pool,
            user_id,
            display_name.as_deref(),
            request.avatar_url.as_deref(),
            request.locale.as_deref(),
            request.analytics_consent,
            request.marketing_consent,
        )
            .await?;

        // 3. Audit log
        AuditLogRepository::log(
            pool,
            Some(user_id),
            "profile_updated",
            Some("user"),
            Some(user_id),
            ip_address,
            None,
            None,
            Some(serde_json::to_value(&request).unwrap()),
            None,
        )
            .await?;

        tracing::info!(user_id = %user_id, "Profile updated successfully");

        Ok(UserResponse::from(user))
    }

    /// ✅ SÉCURITÉ : Changement de mot de passe avec vérification
    pub async fn change_password(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        request: ChangePasswordRequest,
        ip_address: Option<&str>,
    ) -> Result<(), AuthError> {
        // 1. Récupérer l'utilisateur
        let user = UserRepository::find_by_id(pool, user_id).await?;

        // Vérifier que ce n'est pas un guest
        if user.is_guest {
            return Err(AuthError::PermissionDenied);
        }

        let current_hash = user
            .password_hash
            .ok_or(AuthError::InternalError)?;

        // 2. Vérifier le mot de passe actuel
        let is_valid = self
            .password_service
            .verify_password(request.current_password, current_hash)
            .await?;

        if !is_valid {
            tracing::warn!(user_id = %user_id, "Password change failed: invalid current password");
            return Err(AuthError::InvalidCredentials);
        }

        // 3. Valider le nouveau mot de passe
        PasswordService::validate_password_strength(&request.new_password)?;

        // 4. Hash le nouveau mot de passe
        let new_hash = self
            .password_service
            .hash_password(request.new_password)
            .await?;

        // 5. ✅ SÉCURITÉ : Mettre à jour + Révoquer toutes les sessions
        UserRepository::update_password(pool, user_id, &new_hash).await?;

        // 6. Audit log
        AuditLogRepository::log_action(pool, Some(user_id), "password_changed", ip_address)
            .await?;

        tracing::info!(user_id = %user_id, "Password changed successfully");

        Ok(())
    }

    /// Supprimer son compte (soft delete)
    pub async fn delete_account(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        ip_address: Option<&str>,
    ) -> Result<(), AuthError> {
        UserRepository::soft_delete(pool, user_id).await?;

        AuditLogRepository::log_action(pool, Some(user_id), "account_deleted", ip_address)
            .await?;

        tracing::info!(user_id = %user_id, "Account deleted successfully");

        Ok(())
    }

    // ============================================
    // SESSIONS MANAGEMENT
    // ============================================

    /// Lister les sessions actives de l'utilisateur
    pub async fn list_sessions(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        current_session_id: Option<Uuid>,
    ) -> Result<Vec<crate::domain::SessionResponse>, AuthError> {
        let sessions = SessionRepository::list_user_sessions(pool, user_id).await?;

        let responses = sessions
            .into_iter()
            .map(|s| crate::domain::SessionResponse {
                id: s.id,
                issued_at: s.issued_at,
                expires_at: s.expires_at,
                last_used_at: s.last_used_at,
                ip_address: s.ip_address,
                user_agent: s.user_agent,
                is_current: current_session_id == Some(s.id),
            })
            .collect();

        Ok(responses)
    }

    /// ✅ SÉCURITÉ : Révoquer une session spécifique
    pub async fn revoke_session(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        session_id: Uuid,
        ip_address: Option<&str>,
    ) -> Result<(), AuthError> {
        // Vérifier que la session appartient bien à l'utilisateur
        let session = SessionRepository::list_user_sessions(pool, user_id)
            .await?
            .into_iter()
            .find(|s| s.id == session_id)
            .ok_or(AuthError::NotFound)?;

        SessionRepository::revoke(pool, session_id, "user_revoked").await?;

        AuditLogRepository::log_action(pool, Some(user_id), "session_revoked", ip_address)
            .await?;

        tracing::info!(
            user_id = %user_id,
            session_id = %session_id,
            "Session revoked successfully"
        );

        Ok(())
    }

    // ============================================
    // QUOTAS
    // ============================================

    /// Récupérer les quotas d'un utilisateur
    pub async fn get_quotas(
        &self,
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<QuotaResponse>, AuthError> {
        let quotas = QuotaRepository::list_user_quotas(pool, user_id).await?;

        let responses = quotas
            .into_iter()
            .map(|q| QuotaResponse {
                id: q.id,
                quota_type: q.quota_type.clone(),
                max_allowed: q.max_allowed,
                current_usage: q.current_usage,
                remaining: q.remaining(),
                can_renew: q.can_renew,
                renew_action: q.renew_action,
                period_end: q.period_end,
            })
            .collect();

        Ok(responses)
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

    // ============================================
    // PERMISSIONS
    // ============================================

    /// Récupérer les permissions d'un utilisateur
    pub async fn get_permissions(
        &self,
        pool: &PgPool,
        user_id: Uuid,
    ) -> Result<Vec<String>, AuthError> {
        let permissions = PermissionRepository::get_user_permissions(pool, user_id).await?;
        Ok(permissions)
    }

    /// Vérifier si un utilisateur a une permission
    pub async fn has_permission(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        permission: &str,
    ) -> Result<bool, AuthError> {
        let has_permission =
            PermissionRepository::user_has_permission(pool, user_id, permission).await?;
        Ok(has_permission)
    }

    // ============================================
    // ADMIN OPERATIONS
    // ============================================

    /// ✅ SÉCURITÉ : Admin uniquement - Changer le statut d'un utilisateur
    pub async fn update_user_status(
        &self,
        pool: &PgPool,
        admin_user_id: Uuid,
        target_user_id: Uuid,
        request: UpdateUserStatusRequest,
        ip_address: Option<&str>,
    ) -> Result<UserResponse, AuthError> {
        // Vérifier que l'admin a la permission
        let has_permission = PermissionRepository::user_has_permission(
            pool,
            admin_user_id,
            "user:update:status",
        )
            .await?;

        if !has_permission {
            return Err(AuthError::PermissionDenied);
        }

        // Mettre à jour le statut
        let user = UserRepository::update_status(pool, target_user_id, request.status).await?;

        // Audit log
        AuditLogRepository::log(
            pool,
            Some(admin_user_id),
            "user_status_updated",
            Some("user"),
            Some(target_user_id),
            ip_address,
            None,
            None,
            Some(serde_json::json!({
                "new_status": request.status,
                "reason": request.reason,
            })),
            None,
        )
            .await?;

        tracing::info!(
            admin_user_id = %admin_user_id,
            target_user_id = %target_user_id,
            new_status = ?request.status,
            "User status updated by admin"
        );

        Ok(UserResponse::from(user))
    }

    /// Admin - Lister les utilisateurs avec pagination
    pub async fn list_users(
        &self,
        pool: &PgPool,
        admin_user_id: Uuid,
        page: u32,
        per_page: u32,
        status: Option<UserStatus>,
        is_guest: Option<bool>,
        search: Option<String>,
    ) -> Result<crate::domain::PaginatedResponse<UserResponse>, AuthError> {
        // Vérifier que l'admin a la permission
        let has_permission = PermissionRepository::user_has_permission(
            pool,
            admin_user_id,
            "user:list:all",
        )
            .await?;

        if !has_permission {
            return Err(AuthError::PermissionDenied);
        }

        let offset = ((page - 1) * per_page) as i64;
        let limit = per_page as i64;

        let users = UserRepository::list(
            pool,
            offset,
            limit,
            status,
            is_guest,
            search.as_deref(),
        )
            .await?;

        let total = UserRepository::count(pool, status, is_guest, search.as_deref()).await?;

        let data: Vec<UserResponse> = users.into_iter().map(UserResponse::from).collect();

        let total_pages = ((total as f64) / (per_page as f64)).ceil() as u32;

        Ok(crate::domain::PaginatedResponse {
            data,
            page,
            per_page,
            total,
            total_pages,
        })
    }
}