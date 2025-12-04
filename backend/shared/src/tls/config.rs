// backend/shared/src/tls/config.rs
// Configuration mTLS - chargement certificats depuis /etc/tls

use rustls::{Certificate, PrivateKey};
use rustls_pemfile::{certs, pkcs8_private_keys};
use std::fs::File;
use std::io::{self, BufReader};
use std::path::{Path, PathBuf};
use thiserror::Error;
use tracing::{info, warn};

#[derive(Debug, Error)]
pub enum TlsConfigError {
    #[error("Fichier certificat introuvable: {0}")]
    CertFileNotFound(PathBuf),

    #[error("Fichier cle privee introuvable: {0}")]
    KeyFileNotFound(PathBuf),

    #[error("Erreur lecture fichier: {0}")]
    IoError(#[from] io::Error),

    #[error("Certificat invalide: {0}")]
    InvalidCertificate(String),

    #[error("Cle privee invalide: {0}")]
    InvalidPrivateKey(String),

    #[error("mTLS desactive dans la configuration")]
    MtlsDisabled,
}

#[derive(Debug, Clone)]
pub struct TlsConfig {
    pub certificate: Vec<Certificate>,
    pub private_key: PrivateKey,
    pub ca_certificate: Vec<Certificate>,
    pub allowed_common_names: Vec<String>,
    pub check_revocation: bool,
    pub strict_mode: bool,
}

impl TlsConfig {
    pub fn from_env() -> Result<Self, TlsConfigError> {
        let mtls_enabled = std::env::var("MTLS_ENABLED")
            .unwrap_or_else(|_| "false".to_string())
            .parse::<bool>()
            .unwrap_or(false);

        if !mtls_enabled {
            return Err(TlsConfigError::MtlsDisabled);
        }

        info!("Chargement configuration mTLS");

        let cert_path = std::env::var("MTLS_CERT_PATH")
            .unwrap_or_else(|_| "/etc/tls/tls.crt".to_string());
        let key_path = std::env::var("MTLS_KEY_PATH")
            .unwrap_or_else(|_| "/etc/tls/tls.key".to_string());
        let ca_path = std::env::var("MTLS_CA_PATH")
            .unwrap_or_else(|_| "/etc/tls/ca.crt".to_string());

        let certificate = Self::load_certificates(&cert_path)?;
        let private_key = Self::load_private_key(&key_path)?;
        let ca_certificate = Self::load_certificates(&ca_path)?;

        let allowed_cns = std::env::var("MTLS_ALLOWED_CNS")
            .unwrap_or_else(|_| "gateway,quiz-service,auth-service".to_string());
        let allowed_common_names = allowed_cns
            .split(',')
            .map(|s| s.trim().to_string())
            .collect();

        let check_revocation = std::env::var("MTLS_CHECK_REVOCATION")
            .unwrap_or_else(|_| "false".to_string())
            .parse()
            .unwrap_or(false);

        let strict_mode = std::env::var("MTLS_STRICT_MODE")
            .unwrap_or_else(|_| "true".to_string())
            .parse()
            .unwrap_or(true);

        info!(
            "mTLS configure - CNs autorises: {:?}, strict: {}, revocation: {}",
            allowed_common_names, strict_mode, check_revocation
        );

        Ok(Self {
            certificate,
            private_key,
            ca_certificate,
            allowed_common_names,
            check_revocation,
            strict_mode,
        })
    }

    fn load_certificates(path: &str) -> Result<Vec<Certificate>, TlsConfigError> {
        let path = Path::new(path);

        if !path.exists() {
            return Err(TlsConfigError::CertFileNotFound(path.to_path_buf()));
        }

        let file = File::open(path)?;
        let mut reader = BufReader::new(file);

        let certs = certs(&mut reader)
            .map_err(|_| TlsConfigError::InvalidCertificate(
                "Impossible de parser le fichier PEM".to_string()
            ))?
            .into_iter()
            .map(Certificate)
            .collect::<Vec<_>>();

        if certs.is_empty() {
            return Err(TlsConfigError::InvalidCertificate(
                "Aucun certificat trouve dans le fichier".to_string()
            ));
        }

        info!("{} certificat(s) charge(s) depuis: {}", certs.len(), path.display());
        Ok(certs)
    }

    fn load_private_key(path: &str) -> Result<PrivateKey, TlsConfigError> {
        let path = Path::new(path);

        if !path.exists() {
            return Err(TlsConfigError::KeyFileNotFound(path.to_path_buf()));
        }

        let file = File::open(path)?;
        let mut reader = BufReader::new(file);

        let mut keys = pkcs8_private_keys(&mut reader)
            .map_err(|_| TlsConfigError::InvalidPrivateKey(
                "Impossible de parser la cle privee PKCS8".to_string()
            ))?
            .into_iter()
            .map(PrivateKey)
            .collect::<Vec<_>>();

        if keys.is_empty() {
            return Err(TlsConfigError::InvalidPrivateKey(
                "Aucune cle privee trouvee dans le fichier".to_string()
            ));
        }

        if keys.len() > 1 {
            warn!("Plusieurs cles privees trouvees, utilisation de la premiere");
        }

        info!("Cle privee chargee depuis: {}", path.display());
        Ok(keys.remove(0))
    }
}