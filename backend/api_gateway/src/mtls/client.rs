use reqwest::Certificate;
use reqwest::Identity;
use std::fs;
use std::io;
use std::time::Duration;
use thiserror::Error;

use super::MtlsConfig;

#[derive(Debug, Error)]
pub enum MtlsClientError {
    #[error("Failed to read certificate file: {0}")]
    CertRead(#[from] io::Error),

    #[error("Failed to parse certificate: {0}")]
    CertParse(String),

    #[error("Failed to create reqwest client: {0}")]
    ClientBuild(#[from] reqwest::Error),
}

/// Crée un client reqwest configuré avec mTLS pour appeler les services backend
pub fn create_mtls_client(
    mtls_config: &MtlsConfig,
    timeout_secs: u64,
) -> Result<reqwest::Client, MtlsClientError> {
    tracing::info!("🔐 Creating mTLS client for backend services...");

    // Lire le certificat client du Gateway
    let gateway_cert_pem = fs::read(&mtls_config.gateway_client_cert_path)?;
    let gateway_key_pem = fs::read(&mtls_config.gateway_client_key_path)?;

    // Combiner cert + key en PEM
    let mut identity_pem = Vec::new();
    identity_pem.extend_from_slice(&gateway_cert_pem);
    identity_pem.extend_from_slice(&gateway_key_pem);

    // Créer l'identité client (certificat + clé privée)
    let identity = Identity::from_pem(&identity_pem)
        .map_err(|e| MtlsClientError::CertParse(e.to_string()))?;

    tracing::debug!(
        "Loaded gateway client certificate from: {}",
        mtls_config.gateway_client_cert_path.display()
    );
    tracing::debug!(
        "Loaded gateway client key from: {}",
        mtls_config.gateway_client_key_path.display()
    );

    // Lire le certificat CA pour valider les services backend
    let backend_ca_cert_pem = fs::read(&mtls_config.backend_ca_cert_path)?;
    let backend_ca_cert = Certificate::from_pem(&backend_ca_cert_pem)
        .map_err(|e| MtlsClientError::CertParse(e.to_string()))?;

    tracing::debug!(
        "Loaded backend CA certificate from: {}",
        mtls_config.backend_ca_cert_path.display()
    );

    // Construire le client reqwest avec mTLS
    let client = reqwest::Client::builder()
        .identity(identity)                     // Certificat client du Gateway
        .add_root_certificate(backend_ca_cert)  // CA pour valider les backends
        .timeout(Duration::from_secs(timeout_secs))
        .danger_accept_invalid_certs(false)     // Toujours valider les certificats
        .use_rustls_tls()                       // Utiliser rustls comme backend TLS
        .build()?;

    tracing::info!("✅ mTLS client configured successfully");

    Ok(client)
}

/// Créer un client HTTP standard (sans mTLS) pour le mode non-sécurisé
pub fn create_standard_client(timeout_secs: u64) -> Result<reqwest::Client, MtlsClientError> {
    tracing::info!("Creating standard HTTP client (no mTLS)");

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(timeout_secs))
        .build()?;

    Ok(client)
}