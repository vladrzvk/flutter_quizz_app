use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Algorithm, Validation};
use uuid::Uuid;

use crate::config::Config;
use crate::domain::{Claims, RefreshClaims};
use crate::error::AuthError;



#[derive(Clone)]
pub struct JwtService {
    access_encoding_key: EncodingKey,
    access_decoding_key: DecodingKey,
    refresh_encoding_key: EncodingKey,
    refresh_decoding_key: DecodingKey,
    access_expiration_minutes: i64,
    refresh_expiration_days: i64,
}

impl JwtService {
    pub fn new(config: &Config) -> Self {
        Self {
            access_encoding_key: EncodingKey::from_secret(config.jwt_secret().as_bytes()),
            access_decoding_key: DecodingKey::from_secret(config.jwt_secret().as_bytes()),
            refresh_encoding_key: EncodingKey::from_secret(
                config.jwt_refresh_secret().as_bytes(),
            ),
            refresh_decoding_key: DecodingKey::from_secret(
                config.jwt_refresh_secret().as_bytes(),
            ),
            access_expiration_minutes: config.jwt_access_expiration_minutes,
            refresh_expiration_days: config.jwt_refresh_expiration_days,
        }
    }

    /// ✅ SÉCURITÉ : Générer un access token JWT (courte durée)
    pub fn generate_access_token(
        &self,
        user_id: Uuid,
        status: &str,
        is_guest: bool,
        permissions: Vec<String>,
        session_id: Uuid,
    ) -> Result<String, AuthError> {
        let now = Utc::now();
        let exp = now + Duration::minutes(self.access_expiration_minutes);

        let claims = Claims {
            sub: user_id.to_string(),
            status: status.to_string(),
            is_guest,
            permissions,
            exp: exp.timestamp(),
            iat: now.timestamp(),
            jti: session_id.to_string(),
        };

        // ✅ SÉCURITÉ : Algorithme HS512 (plus fort que HS256)
        let mut header = Header::new(Algorithm::HS512);
        header.typ = Some("JWT".to_string());

        let token = encode(&header, &claims, &self.access_encoding_key)
            .map_err(|_| AuthError::JwtError)?;

        Ok(token)
    }

    /// ✅ SÉCURITÉ : Générer un refresh token JWT (longue durée)
    pub fn generate_refresh_token(
        &self,
        user_id: Uuid,
        session_id: Uuid,
    ) -> Result<String, AuthError> {
        let now = Utc::now();
        let exp = now + Duration::days(self.refresh_expiration_days);

        let claims = RefreshClaims {
            sub: user_id.to_string(),
            exp: exp.timestamp(),
            iat: now.timestamp(),
            jti: session_id.to_string(),
        };

        let mut header = Header::new(Algorithm::HS512);
        header.typ = Some("JWT".to_string());

        let token = encode(&header, &claims, &self.refresh_encoding_key)
            .map_err(|_| AuthError::JwtError)?;

        Ok(token)
    }

    /// ✅ SÉCURITÉ : Valider un access token
    pub fn validate_access_token(&self, token: &str) -> Result<Claims, AuthError> {
        // ✅ SÉCURITÉ : Validation stricte, leeway = 0
        let mut validation = Validation::new(Algorithm::HS512);
        validation.leeway = 0; // Pas de tolérance sur l'expiration
        validation.validate_exp = true;
        validation.validate_nbf = false;

        let token_data = decode::<Claims>(token, &self.access_decoding_key, &validation)
            .map_err(|e| {
                tracing::debug!("Token validation failed: {}", e);
                match e.kind() {
                    jsonwebtoken::errors::ErrorKind::ExpiredSignature => AuthError::TokenExpired,
                    _ => AuthError::InvalidToken,
                }
            })?;

        Ok(token_data.claims)
    }

    /// ✅ SÉCURITÉ : Valider un refresh token
    pub fn validate_refresh_token(&self, token: &str) -> Result<RefreshClaims, AuthError> {
        let mut validation = Validation::new(Algorithm::HS512);
        validation.leeway = 0;
        validation.validate_exp = true;
        validation.validate_nbf = false;

        let token_data = decode::<RefreshClaims>(token, &self.refresh_decoding_key, &validation)
            .map_err(|e| {
                tracing::debug!("Refresh token validation failed: {}", e);
                match e.kind() {
                    jsonwebtoken::errors::ErrorKind::ExpiredSignature => AuthError::TokenExpired,
                    _ => AuthError::InvalidToken,
                }
            })?;

        Ok(token_data.claims)
    }

    /// Hash un token pour stockage en DB (révocation)
    pub fn hash_token(token: &str) -> String {
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(token.as_bytes());
        format!("{:x}", hasher.finalize())
    }

    /// Obtenir l'expiration en secondes pour l'access token
    pub fn access_expiration_seconds(&self) -> i64 {
        self.access_expiration_minutes * 60
    }
}

// #[cfg(test)]
// mod tests {
//     use super::*;
//
//     fn create_test_config() -> Config {
//         let mut config = Config {
//             server_host: "localhost".to_string(),
//             server_port: 3001,
//             environment: crate::config::Environment::Test,
//             database_url: "".to_string(),
//             jwt_secret: "test_secret_key_with_32_chars_min".to_string(),
//             jwt_refresh_secret: "test_refresh_secret_key_32_chars".to_string(),
//             jwt_access_expiration_minutes: 15,
//             jwt_refresh_expiration_days: 7,
//             bcrypt_cost: 4,
//             rate_limit_requests_per_minute: 60,
//             login_attempts_before_captcha: 3,
//             login_max_attempts_before_block: 10,
//             hcaptcha_secret: None,
//             hcaptcha_enabled: false,
//             device_fingerprint_max_guests: 3,
//             cors_origins: vec![],
//             guest_default_quiz_quota: 5,
//             guest_quota_renewable: true,
//         };
//         config
//     }
//
//     #[test]
//     fn test_generate_and_validate_access_token() {
//         let config = create_test_config();
//         let jwt_service = JwtService::new(&config);
//
//         let user_id = Uuid::new_v4();
//         let session_id = Uuid::new_v4();
//         let permissions = vec!["quiz:play:free".to_string()];
//
//         let token = jwt_service
//             .generate_access_token(user_id, "free", false, permissions.clone(), session_id)
//             .unwrap();
//
//         let claims = jwt_service.validate_access_token(&token).unwrap();
//
//         assert_eq!(claims.sub, user_id.to_string());
//         assert_eq!(claims.status, "free");
//         assert_eq!(claims.is_guest, false);
//         assert_eq!(claims.permissions, permissions);
//         assert_eq!(claims.jti, session_id.to_string());
//     }
//
//     #[test]
//     fn test_generate_and_validate_refresh_token() {
//         let config = create_test_config();
//         let jwt_service = JwtService::new(&config);
//
//         let user_id = Uuid::new_v4();
//         let session_id = Uuid::new_v4();
//
//         let token = jwt_service
//             .generate_refresh_token(user_id, session_id)
//             .unwrap();
//
//         let claims = jwt_service.validate_refresh_token(&token).unwrap();
//
//         assert_eq!(claims.sub, user_id.to_string());
//         assert_eq!(claims.jti, session_id.to_string());
//     }
//
//     #[test]
//     fn test_invalid_token() {
//         let config = create_test_config();
//         let jwt_service = JwtService::new(&config);
//
//         let result = jwt_service.validate_access_token("invalid.token.here");
//         assert!(result.is_err());
//     }
// }