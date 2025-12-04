// backend/shared/src/tls/server.rs
// Serveur mTLS pour accepter connexions avec validation client obligatoire

use crate::tls::config::{TlsConfig, TlsConfigError};
use crate::tls::validator::CertificateValidator;
use rustls::{Certificate, ServerConfig, RootCertStore};
use rustls::server::AllowAnyAuthenticatedClient;
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

pub struct MtlsAcceptor {
    acceptor: TlsAcceptor,
    validator: Arc<CertificateValidator>,
}

impl MtlsAcceptor {
    pub fn from_config(config: &TlsConfig) -> Result<Self, MtlsServerError> {
        info!("Construction serveur mTLS");

        let mut client_cert_verifier = RootCertStore::empty();

        for ca_cert in &config.ca_certificate {
            client_cert_verifier
                .add(&rustls::Certificate(ca_cert.0.clone()))
                .map_err(|e| {
                    error!("Erreur ajout CA au verifier: {:?}", e);
                    MtlsServerError::InvalidCaCertificate
                })?;
        }

        info!("CA ajoute au client verifier");

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
                error!("Erreur configuration serveur TLS: {:?}", e);
                MtlsServerError::RustlsError(e.to_string())
            })?;

        info!("Configuration TLS serveur creee avec validation client obligatoire");

        let acceptor = TlsAcceptor::from(Arc::new(server_config));

        let validator = Arc::new(CertificateValidator::new(
            config.allowed_common_names.clone(),
            config.strict_mode,
        ));

        info!("Serveur mTLS pret");

        Ok(Self { acceptor, validator })
    }

    pub fn acceptor(&self) -> &TlsAcceptor {
        &self.acceptor
    }

    pub fn validator(&self) -> &Arc<CertificateValidator> {
        &self.validator
    }

    pub fn validate_client_cert(
        &self,
        cert: &Certificate,
    ) -> Result<String, crate::tls::validator::ValidationError> {
        self.validator.validate_client_certificate(cert)
    }
}

pub fn create_mtls_acceptor() -> Result<MtlsAcceptor, MtlsServerError> {
    let config = TlsConfig::from_env()?;
    MtlsAcceptor::from_config(&config)
}