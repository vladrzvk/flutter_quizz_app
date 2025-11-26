use serde::Deserialize;
use std::env;

#[derive(Debug, Clone, Deserialize)]
pub struct Config {
    pub port: u16,
    pub jwt_secret: String,

    // Service URLs
    pub auth_service_url: String,
    pub quiz_service_url: String,
    pub subscription_service_url: String,
    pub offline_service_url: String,
    pub ads_service_url: String,

    // Timeouts
    pub request_timeout_seconds: u64,
}

impl Config {
    pub fn from_env() -> anyhow::Result<Self> {
        Ok(Self {
            port: env::var("PORT")
                .unwrap_or_else(|_| "8000".to_string())
                .parse()?,
            jwt_secret: env::var("JWT_SECRET")?,

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

            request_timeout_seconds: env::var("REQUEST_TIMEOUT_SECONDS")
                .unwrap_or_else(|_| "30".to_string())
                .parse()?,
        })
    }
}