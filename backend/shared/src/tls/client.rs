// backend/shared/src/tls/client.rs
// Client mTLS pour appels HTTP sortants avec authentification mutuelle

use crate::tls::config::{TlsConfig, TlsConfigError};
use reqwest::{Client, ClientBuilder};
use rustls::{ClientConfig, RootCertStore};
use std::sync::Arc;
use thiserror::Error;
use tracing::{info, error};

#[derive(Debug, Error)]
pub enum MtlsClientError {
    #[error("Erreur configuration TLS: {0}")]
    TlsConfigError(#[from] TlsConfigError),

    #[error("Erreur construction client HTTP: {0}")]
    HttpClientError(#[from] reqwest::Error),

    #[error("Certificat CA invalide")]
    InvalidCaCertificate,

    #[error("Erreur rustls: {0}")]
    RustlsError(String),
}

/// Client HTTP avec support mTLS
pub struct MtlsClient {
    client: Client,
}

impl MtlsClient {
    /// Crée un client HTTP avec mTLS depuis la configuration
    pub fn from_config(config: &TlsConfig) -> Result<Self, MtlsClientError> {
        info!("🔧 Construction client mTLS");

        // 1. Créer RootCertStore avec le CA
        let mut root_store = RootCertStore::empty();

        for ca_cert in &config.ca_certificate {
            root_store
                .add(&rustls::Certificate(ca_cert.0.clone()))
                .map_err(|e| {
                    error!("❌ Erreur ajout CA au root store: {:?}", e);
                    MtlsClientError::InvalidCaCertificate
                })?;
        }

        info!("✅ CA ajouté au root store");

        // 2. Créer configuration rustls client
        let tls_config = ClientConfig::builder()
            .with_safe_defaults()
            .with_root_certificates(root_store)
            .with_client_auth_cert(
                config.certificate.clone(),
                config.private_key.clone(),
            )
            .map_err(|e| {
                error!("❌ Erreur configuration certificat client: {:?}", e);
                MtlsClientError::RustlsError(e.to_string())
            })?;

        info!("✅ Configuration TLS client créée");

        // 3. Créer client HTTP reqwest avec rustls
        let client = ClientBuilder::new()
            .use_preconfigured_tls(tls_config)
            .build()?;

        info!("✅ Client mTLS prêt");

        Ok(Self { client })
    }

    /// Récupère le client HTTP interne
    pub fn client(&self) -> &Client {
        &self.client
    }

    /// Effectue une requête GET avec mTLS
    pub async fn get(&self, url: &str) -> Result<reqwest::Response, reqwest::Error> {
        info!("🔐 GET mTLS: {}", url);
        self.client.get(url).send().await
    }

    /// Effectue une requête POST avec mTLS
    pub async fn post<T: serde::Serialize>(
        &self,
        url: &str,
        json: &T,
    ) -> Result<reqwest::Response, reqwest::Error> {
        info!("🔐 POST mTLS: {}", url);
        self.client.post(url).json(json).send().await
    }

    /// Effectue une requête PUT avec mTLS
    pub async fn put<T: serde::Serialize>(
        &self,
        url: &str,
        json: &T,
    ) -> Result<reqwest::Response, reqwest::Error> {
        info!("🔐 PUT mTLS: {}", url);
        self.client.put(url).json(json).send().await
    }

    /// Effectue une requête DELETE avec mTLS
    pub async fn delete(&self, url: &str) -> Result<reqwest::Response, reqwest::Error> {
        info!("🔐 DELETE mTLS: {}", url);
        self.client.delete(url).send().await
    }
}

/// Helper pour créer un client mTLS depuis l'environnement
pub fn create_mtls_client() -> Result<MtlsClient, MtlsClientError> {
    let config = TlsConfig::from_env()?;
    MtlsClient::from_config(&config)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_client_creation_fails_without_config() {
        // Sans configuration mTLS, doit échouer
        std::env::remove_var("MTLS_ENABLED");
        let result = create_mtls_client();
        assert!(result.is_err());
    }
}