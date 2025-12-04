use sqlx::PgPool;
use uuid::Uuid;

use crate::config::Config;
use crate::error::AuthError;
use crate::infrastructure::repositories::{
    LoginAttemptRepository, DeviceFingerprintRepository,
};

pub struct SecurityService {
    config: Config,
}

impl SecurityService {
    pub fn new(config: Config) -> Self {
        Self { config }
    }

    // ============================================
    // RATE LIMITING & BRUTE FORCE PROTECTION
    // ============================================

    /// ✅ SÉCURITÉ : Vérifier le rate limiting pour login par IP
    pub async fn check_login_rate_limit(
        &self,
        pool: &PgPool,
        ip_address: &str,
    ) -> Result<(), AuthError> {
        let failures = LoginAttemptRepository::count_recent_failures_by_ip(
            pool,
            ip_address,
            15, // 15 minutes
        )
            .await?;

        // 5 tentatives max en 15 minutes par IP
        if failures >= 5 {
            tracing::warn!(
                ip_address = ip_address,
                failures = failures,
                "Rate limit exceeded for IP"
            );
            return Err(AuthError::TooManyRequests);
        }

        Ok(())
    }

    /// ✅ SÉCURITÉ : Vérifier si un compte est bloqué
    pub async fn check_account_lock(
        &self,
        pool: &PgPool,
        email: &str,
    ) -> Result<(), AuthError> {
        let is_locked = LoginAttemptRepository::is_account_locked(
            pool,
            email,
            self.config.login_max_attempts_before_block as i64,
            60, // 60 minutes de lockout
        )
            .await?;

        if is_locked {
            tracing::warn!(email = email, "Account is locked");
            return Err(AuthError::AccountLocked);
        }

        Ok(())
    }

    /// ✅ SÉCURITÉ : Vérifier si CAPTCHA est requis
    pub async fn check_captcha_required(
        &self,
        pool: &PgPool,
        email: &str,
    ) -> Result<bool, AuthError> {
        let failures = LoginAttemptRepository::count_recent_failures_by_email(
            pool,
            email,
            15, // 15 minutes
        )
            .await?;

        Ok(failures >= self.config.login_attempts_before_captcha as i64)
    }

    /// ✅ SÉCURITÉ : Valider un CAPTCHA hCaptcha
    pub async fn verify_captcha(&self, captcha_response: &str) -> Result<bool, AuthError> {
        if !self.config.hcaptcha_enabled {
            return Ok(true); // CAPTCHA désactivé en dev
        }

        let secret = self
            .config
            .hcaptcha_secret
            .as_ref()
            .ok_or(AuthError::InternalError)?;

        // Appel API hCaptcha
        let client = reqwest::Client::new();
        let response = client
            .post("https://hcaptcha.com/siteverify")
            .form(&[
                ("secret", secret.as_str()),
                ("response", captcha_response),
            ])
            .send()
            .await
            .map_err(|e| {
                tracing::error!("hCaptcha API call failed: {}", e);
                AuthError::InternalError
            })?;

        #[derive(serde::Deserialize)]
        struct HCaptchaResponse {
            success: bool,
        }

        let result: HCaptchaResponse = response.json().await.map_err(|e| {
            tracing::error!("hCaptcha response parsing failed: {}", e);
            AuthError::InternalError
        })?;

        if !result.success {
            tracing::warn!("CAPTCHA verification failed");
            return Err(AuthError::InvalidCaptcha);
        }

        Ok(true)
    }

    /// ✅ SÉCURITÉ : Enregistrer une tentative de login
    pub async fn record_login_attempt(
        &self,
        pool: &PgPool,
        email: Option<&str>,
        ip_address: &str,
        success: bool,
        failure_reason: Option<&str>,
        user_agent: Option<&str>,
        device_fingerprint: Option<&str>,
    ) -> Result<(), AuthError> {
        LoginAttemptRepository::record(
            pool,
            email,
            ip_address,
            success,
            failure_reason,
            user_agent,
            device_fingerprint,
        )
            .await?;

        Ok(())
    }

    // ============================================
    // DEVICE FINGERPRINTING (GUEST LIMITATION)
    // ============================================

    /// ✅ SÉCURITÉ : Vérifier la limite de guests par device
    pub async fn check_guest_device_limit(
        &self,
        pool: &PgPool,
        device_fingerprint: &str,
    ) -> Result<(), AuthError> {
        let count = DeviceFingerprintRepository::count_guests_for_fingerprint(
            pool,
            device_fingerprint,
        )
            .await?;

        if count >= self.config.device_fingerprint_max_guests as i64 {
            tracing::warn!(
                device_fingerprint = device_fingerprint,
                count = count,
                "Device guest limit exceeded"
            );
            return Err(AuthError::DeviceLimitExceeded);
        }

        Ok(())
    }

    /// Enregistrer un device pour un utilisateur
    pub async fn register_device(
        &self,
        pool: &PgPool,
        user_id: Uuid,
        device_fingerprint: &str,
    ) -> Result<(), AuthError> {
        DeviceFingerprintRepository::upsert(pool, user_id, device_fingerprint).await?;
        Ok(())
    }

    // ============================================
    // INPUT SANITIZATION
    // ============================================

    /// ✅ SÉCURITÉ : Sanitize HTML depuis input utilisateur
    pub fn sanitize_html(input: &str) -> String {
        ammonia::clean(input)
    }

    /// Valider et sanitize un display_name
    pub fn sanitize_display_name(name: &str) -> Result<String, AuthError> {
        // Nettoyer les tags HTML
        let cleaned = Self::sanitize_html(name);

        // Vérifier la longueur
        if cleaned.is_empty() {
            return Err(AuthError::ValidationError(
                "Display name cannot be empty".to_string(),
            ));
        }

        if cleaned.len() > 100 {
            return Err(AuthError::ValidationError(
                "Display name too long".to_string(),
            ));
        }

        Ok(cleaned)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_html() {
        let input = "<scripts>alert('xss')</scripts>Hello";
        let sanitized = SecurityService::sanitize_html(input);
        assert!(!sanitized.contains("<scripts>"));
        assert!(sanitized.contains("Hello"));
    }

    #[test]
    fn test_sanitize_display_name() {
        let config = Config {
            server_host: "localhost".to_string(),
            server_port: 3001,
            environment: crate::config::Environment::Test,
            database_url: "".to_string(),
            jwt_secret: "test".to_string(),
            jwt_refresh_secret: "test".to_string(),
            jwt_access_expiration_minutes: 15,
            jwt_refresh_expiration_days: 7,
            bcrypt_cost: 4,
            rate_limit_requests_per_minute: 60,
            login_attempts_before_captcha: 3,
            login_max_attempts_before_block: 10,
            hcaptcha_secret: None,
            hcaptcha_enabled: false,
            device_fingerprint_max_guests: 3,
            cors_origins: vec![],
            guest_default_quiz_quota: 5,
            guest_quota_renewable: true,
        };

        let service = SecurityService::new(config);

        let result = service.sanitize_display_name("<b>John</b>");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "<b>John</b>"); // <b> est autorisé par ammonia

        let result = service.sanitize_display_name("<scripts>alert('xss')</scripts>");
        assert!(result.is_ok());
        let sanitized = result.unwrap();
        assert!(!sanitized.contains("<scripts>"));
    }
}