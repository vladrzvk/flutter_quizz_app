use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::{IntoResponse, Response},
};
use governor::{
    clock::DefaultClock,
    state::{InMemoryState, NotKeyed},
    Quota, RateLimiter,
};
use std::num::NonZeroU32;
use std::sync::Arc;

use crate::error::AuthError;

/// ✅ SÉCURITÉ : Rate limiter global
pub struct AppRateLimiter {
    limiter: Arc<RateLimiter<NotKeyed, InMemoryState, DefaultClock>>,
}

impl AppRateLimiter {
    pub fn new(requests_per_minute: u32) -> Self {
        let quota = Quota::per_minute(NonZeroU32::new(requests_per_minute).unwrap());
        let limiter = Arc::new(RateLimiter::direct(quota));

        Self { limiter }
    }

    /// Middleware pour rate limiting global
    pub async fn middleware(
        &self,
        request: Request,
        next: Next,
    ) -> Result<Response, AuthError> {
        // Vérifier le rate limit
        if self.limiter.check().is_err() {
            tracing::warn!("Global rate limit exceeded");
            return Err(AuthError::TooManyRequests);
        }

        Ok(next.run(request).await)
    }
}

impl Clone for AppRateLimiter {
    fn clone(&self) -> Self {
        Self {
            limiter: Arc::clone(&self.limiter),
        }
    }
}

/// ✅ SÉCURITÉ : Rate limiter par IP
use dashmap::DashMap;
use std::net::IpAddr;

pub struct IpRateLimiter {
    limiters: Arc<DashMap<IpAddr, RateLimiter<NotKeyed, InMemoryState, DefaultClock>>>,
    quota: Quota,
}

impl IpRateLimiter {
    pub fn new(requests_per_minute: u32) -> Self {
        let quota = Quota::per_minute(NonZeroU32::new(requests_per_minute).unwrap());

        Self {
            limiters: Arc::new(DashMap::new()),
            quota,
        }
    }

    /// Vérifier le rate limit pour une IP
    pub fn check(&self, ip: IpAddr) -> Result<(), AuthError> {
        let limiter = self
            .limiters
            .entry(ip)
            .or_insert_with(|| RateLimiter::direct(self.quota));

        if limiter.check().is_err() {
            tracing::warn!(ip = %ip, "IP rate limit exceeded");
            return Err(AuthError::TooManyRequests);
        }

        Ok(())
    }

    /// Middleware pour rate limiting par IP
    pub async fn middleware(
        &self,
        request: Request,
        next: Next,
    ) -> Result<Response, AuthError> {
        // Extraire l'IP
        let ip = extract_ip(&request)?;

        // Vérifier le rate limit
        self.check(ip)?;

        Ok(next.run(request).await)
    }
}

impl Clone for IpRateLimiter {
    fn clone(&self) -> Self {
        Self {
            limiters: Arc::clone(&self.limiters),
            quota: self.quota,
        }
    }
}

// ============================================
// HELPERS
// ============================================

fn extract_ip(request: &Request) -> Result<IpAddr, AuthError> {
    // X-Forwarded-For
    if let Some(forwarded) = request.headers().get("X-Forwarded-For") {
        if let Ok(forwarded_str) = forwarded.to_str() {
            if let Some(ip_str) = forwarded_str.split(',').next() {
                if let Ok(ip) = ip_str.trim().parse::<IpAddr>() {
                    return Ok(ip);
                }
            }
        }
    }

    // X-Real-IP
    if let Some(real_ip) = request.headers().get("X-Real-IP") {
        if let Ok(ip_str) = real_ip.to_str() {
            if let Ok(ip) = ip_str.parse::<IpAddr>() {
                return Ok(ip);
            }
        }
    }

    // Fallback : localhost
    Ok(IpAddr::from([127, 0, 0, 1]))
}