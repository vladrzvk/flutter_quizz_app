use serde::Deserialize;
use std::env;
use std::path::PathBuf;

#[derive(Debug, Clone)]
pub struct Config {
    // Server
    pub server_host: String,
    pub server_port: u16,
    pub environment: Environment,

    // Database
    pub database_url: String,

    // JWT - SECRETS (jamais loggés)
    jwt_secret: String,
    jwt_refresh_secret: String,

    // JWT Configuration
    pub jwt_access_expiration_minutes: i64,
    pub jwt_refresh_expiration_days: i64,

    // Security - Password
    pub bcrypt_cost: u32,

    // Security - Rate Limiting
    pub rate_limit_requests_per_minute: u32,
    pub login_attempts_before_captcha: u32,
    pub login_max_attempts_before_block: u32,

    // Security - CAPTCHA
    pub hcaptcha_secret: Option<String>,
    pub hcaptcha_enabled: bool,

    // Security - Device Fingerprinting
    pub device_fingerprint_max_guests: u32,

    // CORS
    pub cors_origins: Vec<String>,

    // Quotas - Default values
    pub guest_default_quiz_quota: i32,
    pub guest_quota_renewable: bool,

    // mTLS
    pub mtls_enabled: bool,
}

#[derive(Debug, Clone, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Environment {
    Development,
    Production,
    Test,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        dotenvy::dotenv().ok();

        let environment = match env::var("ENVIRONMENT")
            .unwrap_or_else(|_| "development".to_string())
            .to_lowercase()
            .as_str()
        {
            "production" | "prod" => Environment::Production,
            "test" => Environment::Test,
            _ => Environment::Development,
        };

        let cors_origins = if environment == Environment::Development {
            vec!["*".to_string()]
        } else {
            env::var("CORS_ORIGINS")
                .unwrap_or_else(|_| "".to_string())
                .split(',')
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect()
        };

        Ok(Self {
            server_host: env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string()),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "3001".to_string())
                .parse()?,
            environment,

            database_url: env::var("DATABASE_URL")
                .expect("DATABASE_URL must be set"),

            // JWT Secrets - OBLIGATOIRES en production
            jwt_secret: env::var("JWT_SECRET")
                .expect("JWT_SECRET must be set"),
            jwt_refresh_secret: env::var("JWT_REFRESH_SECRET")
                .unwrap_or_else(|_| env::var("JWT_SECRET").expect("JWT_REFRESH_SECRET or JWT_SECRET must be set")),

            jwt_access_expiration_minutes: env::var("JWT_ACCESS_EXPIRATION_MINUTES")
                .unwrap_or_else(|_| "15".to_string())
                .parse()?,
            jwt_refresh_expiration_days: env::var("JWT_REFRESH_EXPIRATION_DAYS")
                .unwrap_or_else(|_| "7".to_string())
                .parse()?,

            bcrypt_cost: env::var("BCRYPT_COST")
                .unwrap_or_else(|_| "12".to_string())
                .parse()?,

            rate_limit_requests_per_minute: env::var("RATE_LIMIT_RPM")
                .unwrap_or_else(|_| "60".to_string())
                .parse()?,
            login_attempts_before_captcha: env::var("LOGIN_ATTEMPTS_BEFORE_CAPTCHA")
                .unwrap_or_else(|_| "3".to_string())
                .parse()?,
            login_max_attempts_before_block: env::var("LOGIN_MAX_ATTEMPTS_BEFORE_BLOCK")
                .unwrap_or_else(|_| "10".to_string())
                .parse()?,

            hcaptcha_secret: env::var("HCAPTCHA_SECRET").ok(),
            hcaptcha_enabled: env::var("HCAPTCHA_ENABLED")
                .unwrap_or_else(|_| "false".to_string())
                .parse()
                .unwrap_or(false),

            device_fingerprint_max_guests: env::var("DEVICE_FINGERPRINT_MAX_GUESTS")
                .unwrap_or_else(|_| "3".to_string())
                .parse()?,

            cors_origins,

            guest_default_quiz_quota: env::var("GUEST_DEFAULT_QUIZ_QUOTA")
                .unwrap_or_else(|_| "5".to_string())
                .parse()?,
            guest_quota_renewable: env::var("GUEST_QUOTA_RENEWABLE")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true),

            mtls_enabled: env::var("MTLS_ENABLED")
                .unwrap_or_else(|_| "false".to_string())
                .parse()
                .unwrap_or(false),
        })
    }

    pub fn jwt_secret(&self) -> &str {
        &self.jwt_secret
    }

    pub fn jwt_refresh_secret(&self) -> &str {
        &self.jwt_refresh_secret
    }

    pub fn is_production(&self) -> bool {
        self.environment == Environment::Production
    }

    pub fn captcha_required(&self, failed_attempts: u32) -> bool {
        self.hcaptcha_enabled && failed_attempts >= self.login_attempts_before_captcha
    }

    #[cfg(test)]
    pub fn test_config() -> Self {
        Self {
            server_host: "localhost".to_string(),
            server_port: 3001,
            environment: Environment::Test,
            database_url: "".to_string(),
            jwt_secret: "test".to_string(),
            jwt_refresh_secret: "test".to_string(),
            jwt_access_expiration_minutes: 15,
            jwt_refresh_expiration_days: 7,
            bcrypt_cost: 4,
            rate_limit_requests_per_minute: 60,
            login_attempts_before_captcha: 3,
            login_max_attempts_before_block: 10,
            hcaptcha_secret: None,
            hcaptcha_enabled: false,
            device_fingerprint_max_guests: 3,
            cors_origins: vec![],
            guest_default_quiz_quota: 5,
            guest_quota_renewable: true,
            mtls_enabled: false,
        }
    }
}


// ============================================
// MTLS Configuration
// ============================================

#[derive(Debug, Clone)]
pub struct MtlsConfig {
    /// Active ou désactive mTLS
    pub enabled: bool,

    /// Certificat du serveur (PEM)
    pub server_cert_path: PathBuf,

    /// Clé privée du serveur (PEM)
    pub server_key_path: PathBuf,

    /// CA racine pour valider les clients (PEM)
    pub client_ca_cert_path: PathBuf,

    /// Requiert obligatoirement un certificat client
    pub require_client_cert: bool,
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

        let server_cert_path = env::var("MTLS_SERVER_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/server-cert.pem"));

        let server_key_path = env::var("MTLS_SERVER_KEY")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/server-key.pem"));

        let client_ca_cert_path = env::var("MTLS_CLIENT_CA_CERT")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("/etc/mtls/certs/ca-cert.pem"));

        let require_client_cert = env::var("MTLS_REQUIRE_CLIENT_CERT")
            .unwrap_or_else(|_| "true".to_string())
            .parse()
            .unwrap_or(true);

        Ok(Self {
            enabled,
            server_cert_path,
            server_key_path,
            client_ca_cert_path,
            require_client_cert,
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
        }
    }

    /// Valide que les fichiers existent
    pub fn validate(&self) -> anyhow::Result<()> {
        if !self.enabled {
            return Ok(());
        }

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

        Ok(())
    }
}