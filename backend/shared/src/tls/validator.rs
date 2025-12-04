// backend/shared/src/tls/validator.rs
// Validateur de certificats mTLS - verification CN, dates

use rustls::Certificate;
use thiserror::Error;
use tracing::{info, error};
use x509_parser::prelude::*;

#[derive(Debug, Error)]
pub enum ValidationError {
    #[error("Certificat expire ou pas encore valide")]
    CertificateExpired,

    #[error("Common Name (CN) non autorise: {0}")]
    UnauthorizedCommonName(String),

    #[error("Common Name (CN) introuvable dans le certificat")]
    CommonNameNotFound,

    #[error("Erreur parsing certificat X.509: {0}")]
    X509ParseError(String),
}

pub struct CertificateValidator {
    allowed_common_names: Vec<String>,
    strict_mode: bool,
}

impl CertificateValidator {
    pub fn new(allowed_common_names: Vec<String>, strict_mode: bool) -> Self {
        info!("Validateur mTLS cree - CNs autorises: {:?}", allowed_common_names);

        Self {
            allowed_common_names,
            strict_mode,
        }
    }

    pub fn validate_client_certificate(&self, cert: &Certificate) -> Result<String, ValidationError> {
        info!("Validation certificat client...");

        let (_, x509_cert) = parse_x509_certificate(&cert.0)
            .map_err(|e| ValidationError::X509ParseError(e.to_string()))?;

        self.validate_time_validity(&x509_cert)?;

        let common_name = self.extract_common_name(&x509_cert)?;
        self.validate_common_name(&common_name)?;

        info!("Certificat valide avec succes - CN: {}", common_name);
        Ok(common_name)
    }

    fn validate_time_validity(&self, cert: &X509Certificate) -> Result<(), ValidationError> {
        let validity = cert.validity();
        let now = std::time::SystemTime::now();

        let not_before = validity.not_before.timestamp();
        let not_after = validity.not_after.timestamp();

        let now_secs = now
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        if now_secs < not_before {
            error!("Certificat pas encore valide (not_before: {})", not_before);
            return Err(ValidationError::CertificateExpired);
        }

        if now_secs > not_after {
            error!("Certificat expire (not_after: {})", not_after);
            return Err(ValidationError::CertificateExpired);
        }

        info!("Dates de validite OK");
        Ok(())
    }

    fn extract_common_name(&self, cert: &X509Certificate) -> Result<String, ValidationError> {
        let subject = cert.subject();

        for rdn in subject.iter() {
            for attr in rdn.iter() {
                if attr.attr_type() == &oid_registry::OID_X509_COMMON_NAME {
                    if let Ok(cn) = attr.attr_value().as_str() {
                        info!("Common Name extrait: {}", cn);
                        return Ok(cn.to_string());
                    }
                }
            }
        }

        error!("Common Name introuvable dans le certificat");
        Err(ValidationError::CommonNameNotFound)
    }

    fn validate_common_name(&self, cn: &str) -> Result<(), ValidationError> {
        if self.allowed_common_names.contains(&cn.to_string()) {
            info!("Common Name autorise: {}", cn);
            Ok(())
        } else {
            error!("Common Name NON autorise: {} (autorises: {:?})", cn, self.allowed_common_names);
            Err(ValidationError::UnauthorizedCommonName(cn.to_string()))
        }
    }
}