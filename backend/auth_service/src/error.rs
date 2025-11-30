use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::fmt;

#[derive(Debug, thiserror::Error)]
pub enum AuthError {
    // ========== Authentication Errors ==========
    #[error("Invalid credentials")]
    InvalidCredentials,

    #[error("Account locked")]
    AccountLocked,

    #[error("CAPTCHA required")]
    CaptchaRequired,

    #[error("Invalid CAPTCHA")]
    InvalidCaptcha,

    #[error("Invalid token")]
    InvalidToken,

    #[error("Token expired")]
    TokenExpired,

    #[error("Token revoked")]
    TokenRevoked,

    // ========== Authorization Errors ==========
    #[error("Permission denied")]
    PermissionDenied,

    #[error("Forbidden field modification")]
    ForbiddenField,

    #[error("Resource not found")]
    NotFound,

    #[error("Ownership required")]
    OwnershipRequired,

    // ========== Quota Errors ==========
    #[error("Quota exceeded")]
    QuotaExceeded,

    #[error("Quota renewal not allowed")]
    RenewNotAllowed,

    #[error("Invalid renewal proof")]
    InvalidRenewProof,

    #[error("Idempotency conflict")]
    IdempotencyConflict,

    // ========== Validation Errors ==========
    #[error("Validation error: {0}")]
    ValidationError(String),

    #[error("Email already exists")]
    EmailAlreadyExists,

    #[error("Invalid input: {0}")]
    InvalidInput(String),

    // ========== Rate Limiting ==========
    #[error("Too many requests")]
    TooManyRequests,

    #[error("Device limit exceeded")]
    DeviceLimitExceeded,

    // ========== Database Errors ==========
    #[error("Database error")]
    DatabaseError(#[from] sqlx::Error),

    // ========== Internal Errors ==========
    #[error("Internal server error")]
    InternalError,

    #[error("Hashing error")]
    HashingError,

    #[error("JWT error")]
    JwtError,
}

// ✅ SÉCURITÉ : Messages d'erreur génériques pour l'utilisateur
// Les détails sont loggés côté serveur uniquement
#[derive(Serialize)]
struct ErrorResponse {
    error: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    code: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    details: Option<String>,
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let (status, error_code, user_message, include_details) = match &self {
            // Authentication - Messages génériques pour sécurité
            AuthError::InvalidCredentials => (
                StatusCode::UNAUTHORIZED,
                "INVALID_CREDENTIALS",
                "Invalid credentials",
                false,
            ),
            AuthError::AccountLocked => (
                StatusCode::FORBIDDEN,
                "ACCOUNT_LOCKED",
                "Account is locked. Please contact support.",
                false,
            ),
            AuthError::CaptchaRequired => (
                StatusCode::FORBIDDEN,
                "CAPTCHA_REQUIRED",
                "CAPTCHA verification required",
                false,
            ),
            AuthError::InvalidCaptcha => (
                StatusCode::BAD_REQUEST,
                "INVALID_CAPTCHA",
                "Invalid CAPTCHA response",
                false,
            ),
            AuthError::InvalidToken => (
                StatusCode::UNAUTHORIZED,
                "INVALID_TOKEN",
                "Invalid authentication token",
                false,
            ),
            AuthError::TokenExpired => (
                StatusCode::UNAUTHORIZED,
                "TOKEN_EXPIRED",
                "Authentication token has expired",
                false,
            ),
            AuthError::TokenRevoked => (
                StatusCode::UNAUTHORIZED,
                "TOKEN_REVOKED",
                "Authentication token has been revoked",
                false,
            ),

            // Authorization
            AuthError::PermissionDenied => (
                StatusCode::FORBIDDEN,
                "PERMISSION_DENIED",
                "You don't have permission to perform this action",
                false,
            ),
            AuthError::ForbiddenField => (
                StatusCode::FORBIDDEN,
                "FORBIDDEN_FIELD",
                "You cannot modify this field",
                false,
            ),
            AuthError::NotFound => (
                StatusCode::NOT_FOUND,
                "NOT_FOUND",
                "Resource not found",
                false,
            ),
            AuthError::OwnershipRequired => (
                StatusCode::FORBIDDEN,
                "OWNERSHIP_REQUIRED",
                "You can only modify your own resources",
                false,
            ),

            // Quotas
            AuthError::QuotaExceeded => (
                StatusCode::FORBIDDEN,
                "QUOTA_EXCEEDED",
                "Quota limit exceeded",
                false,
            ),
            AuthError::RenewNotAllowed => (
                StatusCode::FORBIDDEN,
                "RENEW_NOT_ALLOWED",
                "Quota renewal is not available",
                false,
            ),
            AuthError::InvalidRenewProof => (
                StatusCode::BAD_REQUEST,
                "INVALID_RENEW_PROOF",
                "Invalid renewal proof provided",
                false,
            ),
            AuthError::IdempotencyConflict => (
                StatusCode::CONFLICT,
                "IDEMPOTENCY_CONFLICT",
                "Request already processed",
                false,
            ),

            // Validation - On peut donner plus de détails
            AuthError::ValidationError(_) => (
                StatusCode::BAD_REQUEST,
                "VALIDATION_ERROR",
                "Validation failed",
                true,
            ),
            AuthError::EmailAlreadyExists => (
                StatusCode::CONFLICT,
                "EMAIL_EXISTS",
                "Email already registered",
                false,
            ),
            AuthError::InvalidInput(_) => (
                StatusCode::BAD_REQUEST,
                "INVALID_INPUT",
                "Invalid input provided",
                true,
            ),

            // Rate Limiting
            AuthError::TooManyRequests => (
                StatusCode::TOO_MANY_REQUESTS,
                "TOO_MANY_REQUESTS",
                "Too many requests. Please try again later.",
                false,
            ),
            AuthError::DeviceLimitExceeded => (
                StatusCode::FORBIDDEN,
                "DEVICE_LIMIT_EXCEEDED",
                "Device limit exceeded for guest accounts",
                false,
            ),

            // Database - ✅ SÉCURITÉ : Masquer les détails DB
            AuthError::DatabaseError(_) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "An internal error occurred",
                false,
            ),

            // Internal - ✅ SÉCURITÉ : Messages génériques
            AuthError::InternalError => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "An internal error occurred",
                false,
            ),
            AuthError::HashingError => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "An internal error occurred",
                false,
            ),
            AuthError::JwtError => (
                StatusCode::INTERNAL_SERVER_ERROR,
                "INTERNAL_ERROR",
                "An internal error occurred",
                false,
            ),
        };

        // ✅ SÉCURITÉ : Logger l'erreur complète côté serveur
        tracing::error!(
            error = ?self,
            status = ?status,
            code = error_code,
            "Request error"
        );

        let details = if include_details {
            Some(self.to_string())
        } else {
            None
        };

        let body = Json(ErrorResponse {
            error: user_message.to_string(),
            code: Some(error_code.to_string()),
            details,
        });

        (status, body).into_response()
    }
}

// Conversions utiles
impl From<validator::ValidationErrors> for AuthError {
    fn from(e: validator::ValidationErrors) -> Self {
        AuthError::ValidationError(e.to_string())
    }
}

impl From<jsonwebtoken::errors::Error> for AuthError {
    fn from(_: jsonwebtoken::errors::Error) -> Self {
        // ✅ SÉCURITÉ : Ne pas exposer les détails JWT
        AuthError::InvalidToken
    }
}

impl From<bcrypt::BcryptError> for AuthError {
    fn from(_: bcrypt::BcryptError) -> Self {
        // ✅ SÉCURITÉ : Ne pas exposer les détails de hashing
        AuthError::HashingError
    }
}