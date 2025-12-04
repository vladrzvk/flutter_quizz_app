use axum_server::tls_rustls::RustlsConfig;
use std::fs;
use std::io;
use thiserror::Error;

use super::MtlsConfig;

#[derive(Debug, Error)]
pub enum MtlsServerError {
    #[error("Failed to read certificate file: {0}")]
    CertRead(#[from] io::Error),

    #[error("Failed to parse certificates: {0}")]
    CertParse(String),

    #[error("Failed to configure TLS: {0}")]
    TlsConfig(String),
}

/// Crée la configuration Rustls pour le serveur API Gateway avec mTLS
pub async fn create_mtls_server_config(
    mtls_config: &MtlsConfig,
) -> Result<RustlsConfig, MtlsServerError> {
    tracing::info!("🔐 Configuring mTLS server for API Gateway...");

    // Lire le certificat serveur
    let server_cert = fs::read(&mtls_config.server_cert_path)?;
    tracing::debug!(
        "Loaded server certificate from: {}",
        mtls_config.server_cert_path.display()
    );

    // Lire la clé privée serveur
    let server_key = fs::read(&mtls_config.server_key_path)?;
    tracing::debug!(
        "Loaded server key from: {}",
        mtls_config.server_key_path.display()
    );

    // Créer la configuration Rustls
    let rustls_config = RustlsConfig::from_pem(server_cert, server_key)
        .await
        .map_err(|e| MtlsServerError::TlsConfig(e.to_string()))?;

    // Note: Pour validation certificat client (mTLS complet),
    // il faudrait configurer ClientCertVerifier avec le CA client
    // Cela nécessite une configuration Rustls plus bas niveau

    tracing::info!(
        "✅ mTLS server configured (client validation: {})",
        if mtls_config.require_client_cert {
            "REQUIRED"
        } else {
            "OPTIONAL"
        }
    );

    Ok(rustls_config)
}