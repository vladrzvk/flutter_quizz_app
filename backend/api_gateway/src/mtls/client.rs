use rustls::{ClientConfig, RootCertStore};
use rustls_pemfile::certs;
use std::fs::File;
use std::io::{self, BufReader};
use std::sync::Arc;
use std::time::Duration;
use thiserror::Error;

use super::MtlsConfig;

#[derive(Debug, Error)]
pub enum MtlsClientError {
    #[error("Failed to read certificate file: {0}")]
    CertRead(#[from] io::Error),

    #[error("Failed to parse certificates: {0}")]
    CertParse(String),

    #[error("Failed to configure TLS: {0}")]
    TlsConfig(String),

    #[error("Failed to build HTTP client: {0}")]
    ClientBuild(#[from] reqwest::Error),
}

/// Crée un client HTTP standard (sans mTLS)
pub fn create_standard_client(timeout_secs: u64) -> Result<reqwest::Client, MtlsClientError> {
    tracing::info!("🔓 Creating standard HTTP client (no mTLS)");

    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(timeout_secs))
        .build()?;

    tracing::info!("✅ Standard HTTP client created");

    Ok(client)
}

/// Crée un client HTTP avec mTLS
pub fn create_mtls_client(
    mtls_config: &MtlsConfig,
    timeout_secs: u64,
) -> Result<reqwest::Client, MtlsClientError> {
    tracing::info!("🔐 Creating mTLS HTTP client...");

    // Charger le certificat CA pour valider les serveurs
    let ca_file = File::open(&mtls_config.client_ca_cert_path)?;
    let mut ca_reader = BufReader::new(ca_file);

    let mut root_store = RootCertStore::empty();
    for cert in certs(&mut ca_reader) {
        let cert = cert.map_err(|e| MtlsClientError::CertParse(e.to_string()))?;
        root_store.add(cert)
            .map_err(|e| MtlsClientError::CertParse(e.to_string()))?;
    }

    tracing::debug!(
        "Loaded CA certificate from: {}",
        mtls_config.client_ca_cert_path.display()
    );

    // Charger le certificat client
    let cert_file = File::open(&mtls_config.server_cert_path)?;
    let mut cert_reader = BufReader::new(cert_file);
    let certs: Vec<_> = certs(&mut cert_reader)
        .collect::<Result<_, _>>()
        .map_err(|e| MtlsClientError::CertParse(e.to_string()))?;

    // Charger la clé privée client
    let key_file = File::open(&mtls_config.server_key_path)?;
    let mut key_reader = BufReader::new(key_file);
    let key = rustls_pemfile::rsa_private_keys(&mut key_reader)
        .next()
        .ok_or_else(|| MtlsClientError::CertParse("No private key found".to_string()))?
        .map_err(|e| MtlsClientError::CertParse(e.to_string()))?;

    let key_der = rustls::pki_types::PrivateKeyDer::Pkcs1(key);

    // Configuration TLS client
    let tls_config = ClientConfig::builder()
        .with_root_certificates(root_store)
        .with_client_auth_cert(certs, key_der)
        .map_err(|e| MtlsClientError::TlsConfig(e.to_string()))?;

    // Client reqwest avec TLS
    let client = reqwest::Client::builder()
        .use_preconfigured_tls(tls_config)
        .timeout(Duration::from_secs(timeout_secs))
        .build()?;

    tracing::info!("✅ mTLS HTTP client created");

    Ok(client)
}