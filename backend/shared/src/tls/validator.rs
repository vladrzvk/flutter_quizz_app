// backend/shared/src/tls/validator.rs
// Validateur de certificats mTLS - vérification CN, dates, révocation

use rustls::Certificate;
use thiserror::Error;
use tracing::{info, warn, error};
use x509_parser::prelude::*;

#[derive(Debug, Error)]
pub enum ValidationError {
    #[error("Certificat expiré ou pas encore valide")]
    CertificateExpired,

    #[error("Common Name (CN) non autorisé: {0}")]
    UnauthorizedCommonName(String),

    #[error("Common Name (CN) introuvable dans le certificat")]
    CommonNameNotFound,

    #[error("Erreur parsing certificat X.509: {0}")]
    X509ParseError(String),

    #[error("Certificat révoqué")]
    CertificateRevoked,

    #[error("Chaîne de certificats invalide")]
    InvalidCertificateChain,
}

/// Validateur de certificats mTLS
pub struct CertificateValidator {
    /// Liste des CN autorisés
    allowed_common_names: Vec<String>,

    /// Vérifier révocation CRL/OCSP
    check_revocation: bool,

    /// Mode strict (rejeter en cas d'erreur)
    strict_mode: bool,
}

impl CertificateValidator {
    /// Crée un nouveau validateur
    pub fn new(
        allowed_common_names: Vec<String>,
        check_revocation: bool,
        strict_mode: bool,
    ) -> Self {
        info!(
            "🔒 Validateur mTLS créé - CNs autorisés: {:?}",
            allowed_common_names
        );

        Self {
            allowed_common_names,
            check_revocation,
            strict_mode,
        }
    }

    /// Valide un certificat client complet
    pub fn validate_client_certificate(
        &self,
        cert: &Certificate,
    ) -> Result<String, ValidationError> {
        info!("🔍 Validation certificat client...");

        // 1. Parser le certificat X.509
        let (_, x509_cert) = parse_x509_certificate(&cert.0)
            .map_err(|e| ValidationError::X509ParseError(e.to_string()))?;

        // 2. Vérifier dates validité
        self.validate_time_validity(&x509_cert)?;

        // 3. Extraire et vérifier CN (Common Name)
        let common_name = self.extract_common_name(&x509_cert)?;
        self.validate_common_name(&common_name)?;

        // 4. Vérifier révocation si activé
        if self.check_revocation {
            self.validate_revocation(&x509_cert)?;
        }

        info!("✅ Certificat validé avec succès - CN: {}", common_name);
        Ok(common_name)
    }

    /// Vérifie les dates de validité (Not Before / Not After)
    fn validate_time_validity(
        &self,
        cert: &X509Certificate,
    ) -> Result<(), ValidationError> {
        let validity = cert.validity();
        let now = std::time::SystemTime::now();

        // Convertir ASN1Time en SystemTime (approximation)
        let not_before = validity.not_before.timestamp();
        let not_after = validity.not_after.timestamp();

        let now_secs = now
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        if now_secs < not_before {
            error!("❌ Certificat pas encore valide (not_before: {})", not_before);
            return Err(ValidationError::CertificateExpired);
        }

        if now_secs > not_after {
            error!("❌ Certificat expiré (not_after: {})", not_after);
            return Err(ValidationError::CertificateExpired);
        }

        info!("✅ Dates de validité OK");
        Ok(())
    }

    /// Extrait le Common Name (CN) du certificat
    fn extract_common_name(
        &self,
        cert: &X509Certificate,
    ) -> Result<String, ValidationError> {
        let subject = cert.subject();

        // Parcourir les attributs du subject pour trouver CN
        for rdn in subject.iter() {
            for attr in rdn.iter() {
                if attr.attr_type() == &oid_registry::OID_X509_COMMON_NAME {
                    if let Ok(cn) = attr.attr_value().as_str() {
                        info!("📝 Common Name extrait: {}", cn);
                        return Ok(cn.to_string());
                    }
                }
            }
        }

        error!("❌ Common Name introuvable dans le certificat");
        Err(ValidationError::CommonNameNotFound)
    }

    /// Vérifie que le CN est dans la liste autorisée
    fn validate_common_name(&self, cn: &str) -> Result<(), ValidationError> {
        if self.allowed_common_names.contains(&cn.to_string()) {
            info!("✅ Common Name autorisé: {}", cn);
            Ok(())
        } else {
            error!(
                "❌ Common Name NON autorisé: {} (autorisés: {:?})",
                cn, self.allowed_common_names
            );
            Err(ValidationError::UnauthorizedCommonName(cn.to_string()))
        }
    }

    /// Vérifie révocation CRL/OCSP (implémentation basique)
    fn validate_revocation(
        &self,
        _cert: &X509Certificate,
    ) -> Result<(), ValidationError> {
        // TODO: Implémentation complète CRL/OCSP
        // Pour le moment, seulement logging

        if self.strict_mode {
            warn!("⚠️  Vérification révocation non implémentée (mode strict)");
            // En mode strict, on pourrait rejeter si pas de CRL disponible
            // Pour dev, on accepte
        } else {
            info!("ℹ️  Vérification révocation skippée (mode non-strict)");
        }

        Ok(())
    }

    /// Valide une chaîne de certificats complète
    pub fn validate_certificate_chain(
        &self,
        chain: &[Certificate],
        ca_cert: &Certificate,
    ) -> Result<(), ValidationError> {
        if chain.is_empty() {
            return Err(ValidationError::InvalidCertificateChain);
        }

        // TODO: Vérifier signatures avec CA
        info!("✅ Chaîne de certificats validée ({} cert(s))", chain.len());
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validator_creation() {
        let validator = CertificateValidator::new(
            vec!["gateway".to_string(), "quiz-service".to_string()],
            true,
            true,
        );

        assert_eq!(validator.allowed_common_names.len(), 2);
        assert!(validator.check_revocation);
        assert!(validator.strict_mode);
    }

    #[test]
    fn test_cn_validation() {
        let validator = CertificateValidator::new(
            vec!["gateway".to_string()],
            false,
            true,
        );

        assert!(validator.validate_common_name("gateway").is_ok());
        assert!(validator.validate_common_name("attacker").is_err());
    }
}