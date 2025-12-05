use tokio::task;

use crate::error::AuthError;

#[derive(Clone)]
pub struct PasswordService {
    cost: u32,
}

impl PasswordService {
    pub fn new(cost: u32) -> Self {
        // ✅ SÉCURITÉ : Minimum cost 10, recommandé 12+
        let validated_cost = cost.max(10);
        Self {
            cost: validated_cost,
        }
    }

    /// ✅ SÉCURITÉ : Hash un mot de passe de manière asynchrone
    /// Utilise spawn_blocking pour éviter de bloquer l'async runtime
    pub async fn hash_password(&self, password: String) -> Result<String, AuthError> {
        let cost = self.cost;

        task::spawn_blocking(move || {
            bcrypt::hash(password, cost).map_err(|e| {
                tracing::error!("Password hashing failed: {}", e);
                AuthError::HashingError
            })
        })
            .await
            .map_err(|e| {
                tracing::error!("Task join error: {}", e);
                AuthError::InternalError
            })?
    }

    /// ✅ SÉCURITÉ : Vérifier un mot de passe de manière asynchrone
    pub async fn verify_password(
        &self,
        password: String,
        hash: String,
    ) -> Result<bool, AuthError> {
        task::spawn_blocking(move || {
            bcrypt::verify(password, &hash).map_err(|e| {
                tracing::error!("Password verification failed: {}", e);
                AuthError::HashingError
            })
        })
            .await
            .map_err(|e| {
                tracing::error!("Task join error: {}", e);
                AuthError::InternalError
            })?
    }

    /// Valider la force d'un mot de passe
    pub fn validate_password_strength(password: &str) -> Result<(), AuthError> {
        if password.len() < 8 {
            return Err(AuthError::ValidationError(
                "Password must be at least 8 characters long".to_string(),
            ));
        }

        if password.len() > 128 {
            return Err(AuthError::ValidationError(
                "Password must not exceed 128 characters".to_string(),
            ));
        }

        // Vérifier la présence de différents types de caractères (optionnel)
        let has_lowercase = password.chars().any(|c| c.is_lowercase());
        let has_uppercase = password.chars().any(|c| c.is_uppercase());
        let has_digit = password.chars().any(|c| c.is_numeric());

        if !has_lowercase || !has_uppercase || !has_digit {
            return Err(AuthError::ValidationError(
                "Password must contain lowercase, uppercase, and digit characters".to_string(),
            ));
        }

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_hash_and_verify_password() {
        let service = PasswordService::new(4); // Low cost pour tests

        let password = "SecurePassword123";
        let hash = service
            .hash_password(password.to_string())
            .await
            .unwrap();

        assert!(service
            .verify_password(password.to_string(), hash.clone())
            .await
            .unwrap());

        assert!(!service
            .verify_password("WrongPassword".to_string(), hash)
            .await
            .unwrap());
    }

    #[test]
    fn test_validate_password_strength() {
        assert!(PasswordService::validate_password_strength("Short1").is_err());
        assert!(PasswordService::validate_password_strength("nouppercase1").is_err());
        assert!(PasswordService::validate_password_strength("NOLOWERCASE1").is_err());
        assert!(PasswordService::validate_password_strength("NoDigits").is_err());
        assert!(PasswordService::validate_password_strength("ValidPassword123").is_ok());
    }
}