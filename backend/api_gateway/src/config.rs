use serde::Deserialize;
use std::env;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub port: u16,
    pub jwt_secret: String,
    pub environment: Environment,

    // Service URLs
    pub auth_service_url: String,
    pub quiz_service_url: String,
    pub subscription_service_url: String,
    pub offline_service_url: String,
    pub ads_service_url: String,

    // Timeouts par service (en secondes)
    pub auth_timeout: u64,
    pub quiz_timeout: u64,
    pub subscription_timeout: u64,
    pub offline_timeout: u64,
    pub ads_timeout: u64,

    // CORS
    pub cors_origins: Vec<String>,

    // Rate limiting
    pub rate_limit_requests_per_minute: u32,

    // Routes publiques
    pub public_routes: Vec<String>,
}

#[derive(Debug, Clone, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum Environment {
    Development,
    Production,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        let environment = match env::var("ENVIRONMENT")
            .unwrap_or_else(|_| "development".to_string())
            .to_lowercase()
            .as_str()
        {
            "production" | "prod" => Environment::Production,
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
            port: env::var("PORT")
                .unwrap_or_else(|_| "8000".to_string())
                .parse()?,
            jwt_secret: env::var("JWT_SECRET")
                .unwrap_or_else(|_| "dev_secret_change_in_prod".to_string()),
            environment,

            auth_service_url: env::var("AUTH_SERVICE_URL")
                .unwrap_or_else(|_| "http://auth-service:3001".to_string()),
            quiz_service_url: env::var("QUIZ_SERVICE_URL")
                .unwrap_or_else(|_| "http://quiz-core-service:8080".to_string()),
            subscription_service_url: env::var("SUBSCRIPTION_SERVICE_URL")
                .unwrap_or_else(|_| "http://subscription-service:3002".to_string()),
            offline_service_url: env::var("OFFLINE_SERVICE_URL")
                .unwrap_or_else(|_| "http://offline-service:3003".to_string()),
            ads_service_url: env::var("ADS_SERVICE_URL")
                .unwrap_or_else(|_| "http://ads-service:3004".to_string()),

            auth_timeout: env::var("AUTH_TIMEOUT")
                .unwrap_or_else(|_| "2".to_string())
                .parse()?,
            quiz_timeout: env::var("QUIZ_TIMEOUT")
                .unwrap_or_else(|_| "5".to_string())
                .parse()?,
            subscription_timeout: env::var("SUBSCRIPTION_TIMEOUT")
                .unwrap_or_else(|_| "3".to_string())
                .parse()?,
            offline_timeout: env::var("OFFLINE_TIMEOUT")
                .unwrap_or_else(|_| "5".to_string())
                .parse()?,
            ads_timeout: env::var("ADS_TIMEOUT")
                .unwrap_or_else(|_| "2".to_string())
                .parse()?,

            cors_origins,

            rate_limit_requests_per_minute: env::var("RATE_LIMIT_REQUESTS_PER_MINUTE")
                .unwrap_or_else(|_| "100".to_string())
                .parse()?,

            public_routes: vec![
                "/health".to_string(),
                "/api/auth/register".to_string(),
                "/api/auth/login".to_string(),
                "/api/auth/refresh".to_string(),
                "/api/quiz/list".to_string(),
            ],
        })
    }

    pub fn is_public_route(&self, path: &str) -> bool {
        self.public_routes.iter().any(|route| path.starts_with(route))
    }

    pub fn get_timeout_for_service(&self, service_type: crate::proxy::ServiceType) -> u64 {
        match service_type {
            crate::proxy::ServiceType::Auth => self.auth_timeout,
            crate::proxy::ServiceType::Quiz => self.quiz_timeout,
            crate::proxy::ServiceType::Subscription => self.subscription_timeout,
            crate::proxy::ServiceType::Offline => self.offline_timeout,
            crate::proxy::ServiceType::Ads => self.ads_timeout,
        }
    }
}