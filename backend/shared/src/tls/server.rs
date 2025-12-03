// backend/shared/src/tls/server.rs
// Serveur mTLS pour accepter connexions avec validation client obligatoire

use crate::tls::config::{TlsConfig, TlsConfigError};
use crate::tls::validator::CertificateValidator;
use rustls::{Certificate, ServerConfig, RootCertStore};
use rustls::server::{AllowAnyAuthenticatedClient, ClientCertVerifier};
use std::sync::Arc;
use thiserror::Error;
use tokio_rustls::TlsAcceptor;
use tracing::{info, error};

#[derive(Debug, Error)]
pub enum MtlsServerError {
    #[error("Erreur configuration TLS: {0}")]
    TlsConfigError(#[from] TlsConfigError),

    #[error("Certificat CA invalide")]
    InvalidCaCertificate,

    #[error("Erreur rustls: {0}")]
    RustlsError(String),
}

/// Acceptor TLS pour serveur mTLS
pub struct MtlsAcceptor {
    acceptor: TlsAcceptor,
    validator: Arc<CertificateValidator>,
}

impl MtlsAcceptor {
    /// Crée un acceptor mTLS depuis la configuration
    pub fn from_config(config: &TlsConfig) -> Result<Self, MtlsServerError> {
        info!("🔧 Construction serveur mTLS");

        // 1. Créer RootCertStore avec le CA pour vérifier les clients
        let mut client_cert_verifier = RootCertStore::empty();

        for ca_cert in &config.ca_certificate {
            client_cert_verifier
                .add(&rustls::Certificate(ca_cert.0.clone()))
                .map_err(|e| {
                    error!("❌ Erreur ajout CA au verifier: {:?}", e);
                    MtlsServerError::InvalidCaCertificate
                })?;
        }

        info!("✅ CA ajouté au client verifier");

        // 2. Créer configuration rustls server avec vérification client OBLIGATOIRE
        let client_cert_verifier = Arc::new(
            AllowAnyAuthenticatedClient::new(client_cert_verifier)
        );

        let server_config = ServerConfig::builder()
            .with_safe_defaults()
            .with_client_cert_verifier(client_cert_verifier)
            .with_single_cert(
                config.certificate.clone(),
                config.private_key.clone(),
            )
            .map_err(|e| {
                error!("❌ Erreur configuration serveur TLS: {:?}", e);
                MtlsServerError::RustlsError(e.to_string())
            })?;

        info!("✅ Configuration TLS serveur créée avec validation client obligatoire");

        // 3. Créer TlsAcceptor
        let acceptor = TlsAcceptor::from(Arc::new(server_config));

        // 4. Créer validateur de certificats
        let validator = Arc::new(CertificateValidator::new(
            config.allowed_common_names.clone(),
            config.check_revocation,
            config.strict_mode,
        ));

        info!("✅ Serveur mTLS prêt");

        Ok(Self { acceptor, validator })
    }

    /// Récupère l'acceptor TLS interne
    pub fn acceptor(&self) -> &TlsAcceptor {
        &self.acceptor
    }

    /// Récupère le validateur
    pub fn validator(&self) -> &Arc<CertificateValidator> {
        &self.validator
    }

    /// Valide un certificat client après connexion
    pub fn validate_client_cert(
        &self,
        cert: &Certificate,
    ) -> Result<String, crate::tls::validator::ValidationError> {
        self.validator.validate_client_certificate(cert)
    }
}

/// Helper pour créer un acceptor mTLS depuis l'environnement
pub fn create_mtls_acceptor() -> Result<MtlsAcceptor, MtlsServerError> {
    let config = TlsConfig::from_env()?;
    MtlsAcceptor::from_config(&config)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_acceptor_creation_fails_without_config() {
        // Sans configuration mTLS, doit échouer
        std::env::remove_var("MTLS_ENABLED");
        let result = create_mtls_acceptor();
        assert!(result.is_err());
    }
}