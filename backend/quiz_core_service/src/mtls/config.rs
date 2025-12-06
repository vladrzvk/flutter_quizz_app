use std::env;
use std::path::PathBuf;

#[derive(Debug, Clone)]
pub struct MtlsConfig {
    /// Active ou desactive mTLS
    pub enabled: bool,

    // ========== Configuration SERVEUR (recoit du gateway) ==========
    /// Certificat du serveur (CRT)
    pub server_cert_path: PathBuf,

    /// Cle privee du serveur (KEY)
    pub server_key_path: PathBuf,

    /// CA racine pour valider les clients (CRT)
    pub client_ca_cert_path: PathBuf,

    /// Requiert obligatoirement un certificat client
    pub require_client_cert: bool,

    // ========== Configuration CLIENT (appelle auth-service) ==========
    /// Certificat client pour appeler auth-service (CRT)
    pub client_cert_path: PathBuf,

    /// Cle privee client pour appeler auth-service (KEY)
    pub client_key_path: PathBuf,

    /// CA racine pour valider auth-service (CRT)
    pub server_ca_cert_path: PathBuf,
}

impl MtlsConfig {
    /// Charge la configuration depuis les variables d'environnement
    pub fn from_env() -> anyhow::Result<Self> {
        let enabled = env::var("MTLS_ENABLED")
            .unwrap_or_else(|_| "false".to_string())
            .parse()
            .unwrap_or(false);

        if !enabled {
            tracing::info!("mTLS is disabled");
            return Ok(Self::disabled());
        }

        // Configuration SERVEUR (recoit du gateway)
        let server_cert_path = env::var("MTLS_SERVER_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/server.crt"));

        let server_key_path = env::var("MTLS_SERVER_KEY")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/server.key"));

        let client_ca_cert_path = env::var("MTLS_CLIENT_CA_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/ca.crt"));

        let require_client_cert = env::var("MTLS_REQUIRE_CLIENT_CERT")
            .unwrap_or_else(|_| "true".to_string())
            .parse()
            .unwrap_or(true);

        // Configuration CLIENT (appelle auth-service)
        let client_cert_path = env::var("MTLS_CLIENT_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/client.crt"));

        let client_key_path = env::var("MTLS_CLIENT_KEY")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/client.key"));

        let server_ca_cert_path = env::var("MTLS_SERVER_CA_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/ca.crt"));

        Ok(Self {
            enabled,
            server_cert_path,
            server_key_path,
            client_ca_cert_path,
            require_client_cert,
            client_cert_path,
            client_key_path,
            server_ca_cert_path,
        })
    }

    /// Configuration desactivee par defaut
    fn disabled() -> Self {
        Self {
            enabled: false,
            server_cert_path: PathBuf::new(),
            server_key_path: PathBuf::new(),
            client_ca_cert_path: PathBuf::new(),
            require_client_cert: false,
            client_cert_path: PathBuf::new(),
            client_key_path: PathBuf::new(),
            server_ca_cert_path: PathBuf::new(),
        }
    }

    /// Valide que les fichiers existent
    pub fn validate(&self) -> anyhow::Result<()> {
        if !self.enabled {
            return Ok(());
        }

        // Validation SERVEUR
        if !self.server_cert_path.exists() {
            anyhow::bail!(
                "Server certificate not found: {}",
                self.server_cert_path.display()
            );
        }

        if !self.server_key_path.exists() {
            anyhow::bail!(
                "Server key not found: {}",
                self.server_key_path.display()
            );
        }

        if !self.client_ca_cert_path.exists() {
            anyhow::bail!(
                "Client CA certificate not found: {}",
                self.client_ca_cert_path.display()
            );
        }

        // Validation CLIENT
        if !self.client_cert_path.exists() {
            anyhow::bail!(
                "Client certificate not found: {}",
                self.client_cert_path.display()
            );
        }

        if !self.client_key_path.exists() {
            anyhow::bail!(
                "Client key not found: {}",
                self.client_key_path.display()
            );
        }

        if !self.server_ca_cert_path.exists() {
            anyhow::bail!(
                "Server CA certificate not found: {}",
                self.server_ca_cert_path.display()
            );
        }

        Ok(())
    }
}