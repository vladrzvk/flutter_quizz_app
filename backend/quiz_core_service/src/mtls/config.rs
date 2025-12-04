use std::env;
use std::path::PathBuf;

#[derive(Debug, Clone)]
pub struct MtlsConfig {
    /// Active ou désactive mTLS
    pub enabled: bool,

    // ========== Configuration SERVEUR ==========
    /// Certificat du serveur API Gateway (PEM)
    pub server_cert_path: PathBuf,

    /// Clé privée du serveur API Gateway (PEM)
    pub server_key_path: PathBuf,

    /// CA racine pour valider les clients (PEM)
    pub client_ca_cert_path: PathBuf,

    /// Requiert obligatoirement un certificat client
    pub require_client_cert: bool,

    // ========== Configuration CLIENT ==========
    /// Certificat client pour appeler les services backend (PEM)
    pub gateway_client_cert_path: PathBuf,

    /// Clé privée client pour appeler les services backend (PEM)
    pub gateway_client_key_path: PathBuf,

    /// CA racine pour valider les certificats des services backend (PEM)
    pub backend_ca_cert_path: PathBuf,
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

        // Configuration SERVEUR (Gateway reçoit des connexions)
        let server_cert_path = env::var("MTLS_SERVER_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/gateway-server-cert.pem"));

        let server_key_path = env::var("MTLS_SERVER_KEY")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/gateway-server-key.pem"));

        let client_ca_cert_path = env::var("MTLS_CLIENT_CA_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/ca-cert.pem"));

        let require_client_cert = env::var("MTLS_REQUIRE_CLIENT_CERT")
            .unwrap_or_else(|_| "false".to_string())  // Généralement false pour gateway public
            .parse()
            .unwrap_or(false);

        // Configuration CLIENT (Gateway appelle les services backend)
        let gateway_client_cert_path = env::var("MTLS_GATEWAY_CLIENT_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/gateway-client-cert.pem"));

        let gateway_client_key_path = env::var("MTLS_GATEWAY_CLIENT_KEY")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/gateway-client-key.pem"));

        let backend_ca_cert_path = env::var("MTLS_BACKEND_CA_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/ca-cert.pem"));

        Ok(Self {
            enabled,
            server_cert_path,
            server_key_path,
            client_ca_cert_path,
            require_client_cert,
            gateway_client_cert_path,
            gateway_client_key_path,
            backend_ca_cert_path,
        })
    }

    /// Configuration désactivée par défaut
    fn disabled() -> Self {
        Self {
            enabled: false,
            server_cert_path: PathBuf::new(),
            server_key_path: PathBuf::new(),
            client_ca_cert_path: PathBuf::new(),
            require_client_cert: false,
            gateway_client_cert_path: PathBuf::new(),
            gateway_client_key_path: PathBuf::new(),
            backend_ca_cert_path: PathBuf::new(),
        }
    }

    /// Valide que les fichiers existent
    pub fn validate(&self) -> anyhow::Result<()> {
        if !self.enabled {
            return Ok(());
        }

        // Validation serveur
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

        if self.require_client_cert && !self.client_ca_cert_path.exists() {
            anyhow::bail!(
                "Client CA certificate not found: {}",
                self.client_ca_cert_path.display()
            );
        }

        // Validation client (pour appeler backend)
        if !self.gateway_client_cert_path.exists() {
            anyhow::bail!(
                "Gateway client certificate not found: {}",
                self.gateway_client_cert_path.display()
            );
        }

        if !self.gateway_client_key_path.exists() {
            anyhow::bail!(
                "Gateway client key not found: {}",
                self.gateway_client_key_path.display()
            );
        }

        if !self.backend_ca_cert_path.exists() {
            anyhow::bail!(
                "Backend CA certificate not found: {}",
                self.backend_ca_cert_path.display()
            );
        }

        Ok(())
    }
}