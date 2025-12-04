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

pub struct MtlsClient {
    client: Client,
}

impl MtlsClient {
    pub fn from_config(config: &TlsConfig) -> Result<Self, MtlsClientError> {
        info!("Construction client mTLS");

        let mut root_store = RootCertStore::empty();

        for ca_cert in &config.ca_certificate {
            root_store
                .add(&rustls::Certificate(ca_cert.0.clone()))
                .map_err(|e| {
                    error!("Erreur ajout CA au root store: {:?}", e);
                    MtlsClientError::InvalidCaCertificate
                })?;
        }

        info!("CA ajoute au root store");

        let tls_config = ClientConfig::builder()
            .with_safe_defaults()
            .with_root_certificates(root_store)
            .with_client_auth_cert(
                config.certificate.clone(),
                config.private_key.clone(),
            )
            .map_err(|e| {
                error!("Erreur configuration certificat client: {:?}", e);
                MtlsClientError::RustlsError(e.to_string())
            })?;

        info!("Configuration TLS client creee");

        let client = ClientBuilder::new()
            .use_preconfigured_tls(tls_config)
            .build()?;

        info!("Client mTLS pret");

        Ok(Self { client })
    }

    pub fn client(&self) -> &Client {
        &self.client
    }

    pub async fn get(&self, url: &str) -> Result<reqwest::Response, reqwest::Error> {
        info!("GET mTLS: {}", url);
        self.client.get(url).send().await
    }

    pub async fn post<T: serde::Serialize>(
        &self,
        url: &str,
        json: &T,
    ) -> Result<reqwest::Response, reqwest::Error> {
        info!("POST mTLS: {}", url);
        self.client.post(url).json(json).send().await
    }

    pub async fn put<T: serde::Serialize>(
        &self,
        url: &str,
        json: &T,
    ) -> Result<reqwest::Response, reqwest::Error> {
        info!("PUT mTLS: {}", url);
        self.client.put(url).json(json).send().await
    }

    pub async fn delete(&self, url: &str) -> Result<reqwest::Response, reqwest::Error> {
        info!("DELETE mTLS: {}", url);
        self.client.delete(url).send().await
    }
}

pub fn create_mtls_client() -> Result<MtlsClient, MtlsClientError> {
    let config = TlsConfig::from_env()?;
    MtlsClient::from_config(&config)
}