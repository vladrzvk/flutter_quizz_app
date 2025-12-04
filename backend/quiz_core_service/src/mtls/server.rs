use rustls::{ServerConfig, RootCertStore};
use rustls_pemfile::{certs, rsa_private_keys};
use std::fs::File;
use std::io::{self, BufReader};
use std::sync::Arc;
use thiserror::Error;
use tokio_rustls::TlsAcceptor;

use super::MtlsConfig;

#[derive(Debug, Error)]
pub enum MtlsServerError {
    #[error("Failed to read certificate file: {0}")]
    CertRead(#[from] io::Error),

    #[error("Failed to parse certificates: {0}")]
    CertParse(String),

    #[error("Failed to configure TLS: {0}")]
    TlsConfig(String),

    #[error("No private key found")]
    NoPrivateKey,
}

/// Crée un TlsAcceptor configuré pour mTLS
pub fn create_mtls_acceptor(
    mtls_config: &MtlsConfig,
) -> Result<TlsAcceptor, MtlsServerError> {
    tracing::info!("🔐 Configuring mTLS server...");

    // Lire le certificat serveur
    let cert_file = File::open(&mtls_config.server_cert_path)?;
    let mut cert_reader = BufReader::new(cert_file);
    let cert_chain: Vec<_> = certs(&mut cert_reader)
        .collect::<Result<_, _>>()
        .map_err(|e| MtlsServerError::CertParse(e.to_string()))?;

    if cert_chain.is_empty() {
        return Err(MtlsServerError::CertParse(
            "No certificates found in server cert file".to_string(),
        ));
    }

    tracing::debug!(
        "Loaded {} certificate(s) from: {}",
        cert_chain.len(),
        mtls_config.server_cert_path.display()
    );

    // Lire la clé privée serveur
    let key_file = File::open(&mtls_config.server_key_path)?;
    let mut key_reader = BufReader::new(key_file);

    let private_key = rsa_private_keys(&mut key_reader)
        .next()
        .ok_or(MtlsServerError::NoPrivateKey)?
        .map_err(|e| MtlsServerError::CertParse(e.to_string()))?;

    tracing::debug!(
        "Loaded server key from: {}",
        mtls_config.server_key_path.display()
    );

    // Configuration TLS de base
    let mut config = ServerConfig::builder()
        .with_no_client_auth()  // On commencera sans validation client
        .with_single_cert(cert_chain, private_key.into())
        .map_err(|e| MtlsServerError::TlsConfig(e.to_string()))?;

    // Si la validation du certificat client est requise
    if mtls_config.require_client_cert {
        tracing::info!("Client certificate validation: REQUIRED");

        // Charger le CA pour valider les clients
        let ca_file = File::open(&mtls_config.client_ca_cert_path)?;
        let mut ca_reader = BufReader::new(ca_file);

        let mut root_store = RootCertStore::empty();
        for cert in certs(&mut ca_reader) {
            let cert = cert.map_err(|e| MtlsServerError::CertParse(e.to_string()))?;
            root_store.add(cert)
                .map_err(|e| MtlsServerError::CertParse(e.to_string()))?;
        }

        tracing::debug!(
            "Loaded client CA certificate from: {}",
            mtls_config.client_ca_cert_path.display()
        );

        // Reconfigurer avec validation client
        config = ServerConfig::builder()
            .with_client_cert_verifier(
                rustls::server::WebPkiClientVerifier::builder(Arc::new(root_store))
                    .build()
                    .map_err(|e| MtlsServerError::TlsConfig(e.to_string()))?
            )
            .with_single_cert(
                cert_chain,
                rustls::pki_types::PrivateKeyDer::Pkcs1(private_key)
            )
            .map_err(|e| MtlsServerError::TlsConfig(e.to_string()))?;
    } else {
        tracing::info!("Client certificate validation: OPTIONAL");
    }

    config.alpn_protocols = vec![b"h2".to_vec(), b"http/1.1".to_vec()];

    let acceptor = TlsAcceptor::from(Arc::new(config));

    tracing::info!("✅ mTLS server configured successfully");

    Ok(acceptor)
}