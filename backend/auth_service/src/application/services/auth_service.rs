use sqlx::PgPool;
use uuid::Uuid;
use chrono::Utc;

use crate::config::Config;
use crate::domain::{
    AuthResponse, LoginRequest, RegisterRequest, RefreshTokenRequest,
    CreateGuestRequest, UserResponse, User,
};
use crate::error::AuthError;
use crate::infrastructure::repositories::{
    UserRepository, SessionRepository, QuotaRepository, PermissionRepository,
    AuditLogRepository,
};
use super::{JwtService, PasswordService, SecurityService};

pub struct AuthService {
    jwt_service: JwtService,
    password_service: PasswordService,
    security_service: SecurityService,
    config: Config,
}

impl AuthService {
    pub fn new(config: Config) -> Self {
        let jwt_service = JwtService::new(&config);
        let password_service = PasswordService::new(config.bcrypt_cost);
        let security_service = SecurityService::new(config.clone());

        Self {
            jwt_service,
            password_service,
            security_service,
            config,
        }
    }

    // ============================================
    // REGISTER
    // ============================================

    /// ✅ SÉCURITÉ : Enregistrer un nouvel utilisateur permanent
    pub async fn register(
        &self,
        pool: &PgPool,
        request: RegisterRequest,
        ip_address: Option<&str>,
    ) -> Result<AuthResponse, AuthError> {
        // 1. Valider la force du mot de passe
        PasswordService::validate_password_strength(&request.password)?;

        // 2. Vérifier si l'email existe déjà
        if UserRepository::email_exists(pool, &request.email).await? {
            return Err(AuthError::EmailAlreadyExists);
        }

        // 3. Hash du mot de passe (async pour ne pas bloquer)
        let password_hash = self
            .password_service
            .hash_password(request.password)
            .await?;

        // 4. Sanitize display_name
        let display_name = request
            .display_name
            .as_ref()
            .map(|name| self.security_service.sanitize_display_name(name))
            .transpose()?;

        // 5. Créer l'utilisateur
        let user = UserRepository::create(
            pool,
            &request.email,
            &password_hash,
            display_name.as_deref(),
            request.locale.as_deref(),
            request.analytics_consent.unwrap_or(false),
            request.marketing_consent.unwrap_or(false),
        )
            .await?;

        // 6. Assigner le rôle "user" par défaut
        if let Some(user_role) = PermissionRepository::find_by_name(pool, "user").await? {
            // Note: Implémenter RoleRepository::assign_to_user
        }

        // 7. Créer les quotas par défaut (si applicable)
        // Ex: quota quiz pour free users
        // QuotaRepository::create(...).await?;

        // 8. Audit log
        AuditLogRepository::log_action(pool, Some(user.id), "user_registered", ip_address)
            .await?;

        // 9. Générer les tokens JWT
        let auth_response = self.generate_tokens(pool, &user, ip_address, None, None).await?;

        tracing::info!(
            user_id = %user.id,
            email = %user.email.as_ref().unwrap(),
            "User registered successfully"
        );

        Ok(auth_response)
    }

    // ============================================
    // LOGIN
    // ============================================

    /// ✅ SÉCURITÉ : Login avec toutes les protections
    pub async fn login(
        &self,
        pool: &PgPool,
        request: LoginRequest,
        ip_address: Option<&str>,
        user_agent: Option<&str>,
    ) -> Result<AuthResponse, AuthError> {
        let ip = ip_address.unwrap_or("unknown");

        // 1. ✅ SÉCURITÉ : Rate limiting par IP
        self.security_service
            .check_login_rate_limit(pool, ip)
            .await?;

        // 2. ✅ SÉCURITÉ : Vérifier si le compte est bloqué
        self.security_service
            .check_account_lock(pool, &request.email)
            .await?;

        // 3. ✅ SÉCURITÉ : Vérifier si CAPTCHA est requis
        let captcha_required = self
            .security_service
            .check_captcha_required(pool, &request.email)
            .await?;

        if captcha_required {
            if let Some(captcha_response) = &request.captcha_response {
                // Valider le CAPTCHA
                self.security_service
                    .verify_captcha(captcha_response)
                    .await?;
            } else {
                // CAPTCHA requis mais non fourni
                self.security_service
                    .record_login_attempt(
                        pool,
                        Some(&request.email),
                        ip,
                        false,
                        Some("captcha_required"),
                        user_agent,
                        request.device_fingerprint.as_deref(),
                    )
                    .await?;
                return Err(AuthError::CaptchaRequired);
            }
        }

        // 4. Trouver l'utilisateur par email
        let user = UserRepository::find_by_email(pool, &request.email)
            .await?
            .ok_or_else(|| {
                // ✅ SÉCURITÉ : Message générique pour ne pas révéler si l'email existe
                AuthError::InvalidCredentials
            })?;

        // 5. Vérifier le mot de passe
        let password_hash = user.password_hash.clone().ok_or_else(|| {
            // Guest account sans password
            AuthError::InvalidCredentials
        })?;

        let is_valid = self
            .password_service
            .verify_password(request.password.clone(), password_hash)
            .await?;

        if !is_valid {
            // ✅ SÉCURITÉ : Enregistrer l'échec
            self.security_service
                .record_login_attempt(
                    pool,
                    Some(&request.email),
                    ip,
                    false,
                    Some("invalid_password"),
                    user_agent,
                    request.device_fingerprint.as_deref(),
                )
                .await?;

            tracing::warn!(
                email = %request.email,
                ip = ip,
                "Login failed: invalid password"
            );

            // ✅ SÉCURITÉ : Message générique
            return Err(AuthError::InvalidCredentials);
        }

        // 6. Vérifier si l'utilisateur est suspendu
        if user.status == crate::domain::UserStatus::Suspended {
            self.security_service
                .record_login_attempt(
                    pool,
                    Some(&request.email),
                    ip,
                    false,
                    Some("account_suspended"),
                    user_agent,
                    request.device_fingerprint.as_deref(),
                )
                .await?;
            return Err(AuthError::PermissionDenied);
        }

        // 7. ✅ SÉCURITÉ : Enregistrer le succès
        self.security_service
            .record_login_attempt(
                pool,
                Some(&request.email),
                ip,
                true,
                None,
                user_agent,
                request.device_fingerprint.as_deref(),
            )
            .await?;

        // 8. Mettre à jour last_login_at
        UserRepository::update_last_login(pool, user.id).await?;

        // 9. Enregistrer le device si fourni
        if let Some(fingerprint) = &request.device_fingerprint {
            self.security_service
                .register_device(pool, user.id, fingerprint)
                .await?;
        }

        // 10. Audit log
        AuditLogRepository::log_action(pool, Some(user.id), "user_login", Some(ip)).await?;

        // 11. Générer les tokens JWT
        let auth_response = self
            .generate_tokens(
                pool,
                &user,
                Some(ip),
                user_agent,
                request.device_fingerprint.as_deref(),
            )
            .await?;

        tracing::info!(
            user_id = %user.id,
            email = %user.email.as_ref().unwrap(),
            ip = ip,
            "User logged in successfully"
        );

        Ok(auth_response)
    }

    // ============================================
    // REFRESH TOKEN
    // ============================================

    /// ✅ SÉCURITÉ : Refresh avec rotation de tokens (usage unique)
    pub async fn refresh_token(
        &self,
        pool: &PgPool,
        refresh_token: &str,
        ip_address: Option<&str>,
        user_agent: Option<&str>,
    ) -> Result<AuthResponse, AuthError> {
        // 1. Valider le refresh token JWT
        let refresh_claims = self.jwt_service.validate_refresh_token(refresh_token)?;

        let user_id = Uuid::parse_str(&refresh_claims.sub).map_err(|_| AuthError::InvalidToken)?;

        // 2. ✅ SÉCURITÉ : Consommer le refresh token (usage unique)
        let refresh_token_hash = JwtService::hash_token(refresh_token);
        let old_session = SessionRepository::consume_refresh_token(pool, &refresh_token_hash)
            .await
            .map_err(|_| AuthError::InvalidToken)?;

        // Vérifier que le session user_id correspond au token
        if old_session.user_id != user_id {
            tracing::error!(
                "Session user_id mismatch: session={}, token={}",
                old_session.user_id,
                user_id
            );
            return Err(AuthError::InvalidToken);
        }

        // 3. Récupérer l'utilisateur
        let user = UserRepository::find_by_id(pool, user_id).await?;

        // 4. ✅ SÉCURITÉ : Détecter les anomalies (nouveau device/IP)
        let is_anomaly = SessionRepository::detect_anomaly(
            pool,
            user_id,
            ip_address,
            old_session.device_fingerprint.as_deref(),
        )
            .await?;

        if is_anomaly {
            tracing::warn!(
                user_id = %user_id,
                ip = ?ip_address,
                "Anomaly detected during token refresh"
            );
            // On pourrait envoyer un email d'alerte ici
        }

        // 5. Générer de nouveaux tokens (rotation complète)
        let auth_response = self
            .generate_tokens(
                pool,
                &user,
                ip_address,
                user_agent,
                old_session.device_fingerprint.as_deref(),
            )
            .await?;

        tracing::info!(
            user_id = %user_id,
            "Token refreshed successfully"
        );

        Ok(auth_response)
    }

    // ============================================
    // GUEST CREATION
    // ============================================

    /// ✅ SÉCURITÉ : Créer un compte guest avec limitations
    pub async fn create_guest(
        &self,
        pool: &PgPool,
        request: CreateGuestRequest,
        ip_address: Option<&str>,
    ) -> Result<AuthResponse, AuthError> {
        // 1. ✅ SÉCURITÉ : Vérifier la limite de guests par device
        if let Some(fingerprint) = &request.device_fingerprint {
            self.security_service
                .check_guest_device_limit(pool, fingerprint)
                .await?;
        }

        // 2. Créer l'utilisateur guest
        let user = UserRepository::create_guest(pool, request.locale.as_deref()).await?;

        // 3. Créer les quotas par défaut pour guests
        QuotaRepository::create(
            pool,
            user.id,
            "quiz_plays",
            self.config.guest_default_quiz_quota,
            self.config.guest_quota_renewable,
            Some("watch_ad"), // Action pour renouveler
            Some("daily"),
            Some(Utc::now()),
            Some(Utc::now() + chrono::Duration::days(1)),
        )
            .await?;

        // 4. Enregistrer le device si fourni
        if let Some(fingerprint) = &request.device_fingerprint {
            self.security_service
                .register_device(pool, user.id, fingerprint)
                .await?;
        }

        // 5. Audit log
        AuditLogRepository::log_action(pool, Some(user.id), "guest_created", ip_address).await?;

        // 6. Générer les tokens JWT
        let auth_response = self
            .generate_tokens(
                pool,
                &user,
                ip_address,
                None,
                request.device_fingerprint.as_deref(),
            )
            .await?;

        tracing::info!(
            user_id = %user.id,
            "Guest user created successfully"
        );

        Ok(auth_response)
    }

    // ============================================
    // LOGOUT
    // ============================================

    /// ✅ SÉCURITÉ : Logout (révocation de session)
    pub async fn logout(
        &self,
        pool: &PgPool,
        access_token: &str,
        ip_address: Option<&str>,
    ) -> Result<(), AuthError> {
        // 1. Valider le token pour obtenir le session_id
        let claims = self.jwt_service.validate_access_token(access_token)?;
        let session_id = Uuid::parse_str(&claims.jti).map_err(|_| AuthError::InvalidToken)?;
        let user_id = Uuid::parse_str(&claims.sub).map_err(|_| AuthError::InvalidToken)?;

        // 2. ✅ SÉCURITÉ : Révoquer la session
        SessionRepository::revoke(pool, session_id, "user_logout").await?;

        // 3. Audit log
        AuditLogRepository::log_action(pool, Some(user_id), "user_logout", ip_address).await?;

        tracing::info!(
            user_id = %user_id,
            session_id = %session_id,
            "User logged out successfully"
        );

        Ok(())
    }

    /// ✅ SÉCURITÉ : Logout de toutes les sessions d'un utilisateur
    pub async fn logout_all(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        ip_address: Option<&str>,
    ) -> Result<i64, AuthError> {
        let count = SessionRepository::revoke_all_user_sessions(pool, user_id, "user_logout_all")
            .await?;

        AuditLogRepository::log_action(pool, Some(user_id), "user_logout_all", ip_address)
            .await?;

        tracing::info!(
            user_id = %user_id,
            sessions_revoked = count,
            "All user sessions logged out"
        );

        Ok(count)
    }

    // ============================================
    // HELPER METHODS
    // ============================================

    /// Générer les tokens JWT et créer la session
    async fn generate_tokens(
        &self,
        pool: &PgPool,
        user: &User,
        ip_address: Option<&str>,
        user_agent: Option<&str>,
        device_fingerprint: Option<&str>,
    ) -> Result<AuthResponse, AuthError> {
        // 1. Récupérer les permissions de l'utilisateur
        let permissions = PermissionRepository::get_user_permissions(pool, user.id).await?;

        // 2. Créer un nouveau session_id
        let session_id = Uuid::new_v4();

        // 3. Générer les tokens
        let access_token = self.jwt_service.generate_access_token(
            user.id,
            &user.status.to_string(),
            user.is_guest,
            permissions.clone(),
            session_id,
        )?;

        let refresh_token = self
            .jwt_service
            .generate_refresh_token(user.id, session_id)?;

        // 4. Hash les tokens pour stockage
        let access_token_hash = JwtService::hash_token(&access_token);
        let refresh_token_hash = JwtService::hash_token(&refresh_token);

        // 5. Calculer l'expiration du refresh token
        let refresh_expires_at =
            Utc::now() + chrono::Duration::days(self.config.jwt_refresh_expiration_days);

        // 6. Créer la session en DB
        SessionRepository::create(
            pool,
            user.id,
            &access_token_hash,
            &refresh_token_hash,
            refresh_expires_at,
            ip_address,
            user_agent,
            device_fingerprint,
        )
            .await?;

        Ok(AuthResponse {
            access_token,
            refresh_token,
            token_type: "Bearer".to_string(),
            expires_in: self.jwt_service.access_expiration_seconds(),
            user: UserResponse::from(user.clone()),
        })
    }
}