// backend/quiz_core_service/src/middleware/mtls_validation.rs
// Middleware Axum pour validation certificat client mTLS

use axum::{
    extract::Request,
    http::StatusCode,
    middleware::Next,
    response::Response,
};
use tracing::{info, warn, error};

/// Extension contenant le CN (Common Name) du certificat client
#[derive(Debug, Clone)]
pub struct ClientCertInfo {
    pub common_name: String,
}

/// Middleware de validation mTLS
/// Vérifie que le certificat client est présent et valide
pub async fn validate_mtls_middleware(
    mut request: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    // Extraire le CN depuis les headers ajoutés par le proxy TLS
    // En production, le CN serait extrait directement de la connexion TLS
    // Pour simplifier, on utilise un header X-Client-CN

    let client_cn = request
        .headers()
        .get("X-Client-CN")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string());

    match client_cn {
        Some(cn) => {
            info!("✅ Certificat client détecté - CN: {}", cn);

            // Vérifier que le CN est autorisé (gateway uniquement)
            if cn != "gateway" {
                error!("❌ CN non autorisé: {}", cn);
                return Err(StatusCode::FORBIDDEN);
            }

            // Ajouter info client au request
            request.extensions_mut().insert(ClientCertInfo {
                common_name: cn,
            });

            Ok(next.run(request).await)
        }
        None => {
            warn!("⚠️  Aucun certificat client fourni");

            // En mode strict, rejeter
            let strict_mode = std::env::var("MTLS_STRICT_MODE")
                .unwrap_or_else(|_| "true".to_string())
                .parse()
                .unwrap_or(true);

            if strict_mode {
                error!("❌ Mode strict: rejet connexion sans certificat");
                return Err(StatusCode::UNAUTHORIZED);
            }

            warn!("⚠️  Mode non-strict: autorisation sans certificat");
            Ok(next.run(request).await)
        }
    }
}

/// Middleware pour logger les informations de connexion mTLS
pub async fn log_mtls_connection(
    request: Request,
    next: Next,
) -> Response {
    // Extraire info client si présente
    if let Some(client_info) = request.extensions().get::<ClientCertInfo>() {
        info!(
            "🔐 Requête mTLS depuis: {} - {} {}",
            client_info.common_name,
            request.method(),
            request.uri()
        );
    } else {
        info!(
            "📡 Requête standard (pas mTLS) - {} {}",
            request.method(),
            request.uri()
        );
    }

    next.run(request).await
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{
        body::Body,
        http::{Request, Method},
    };

    #[tokio::test]
    async fn test_middleware_rejects_without_cert_in_strict_mode() {
        std::env::set_var("MTLS_STRICT_MODE", "true");

        let request = Request::builder()
            .method(Method::GET)
            .uri("/api/quizzes")
            .body(Body::empty())
            .unwrap();

        let next = |_: Request| async {
            Response::new(Body::empty())
        };

        // Sans header X-Client-CN, doit rejeter en mode strict
        let result = validate_mtls_middleware(request, next).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_middleware_accepts_gateway() {
        std::env::set_var("MTLS_STRICT_MODE", "true");

        let request = Request::builder()
            .method(Method::GET)
            .uri("/api/quizzes")
            .header("X-Client-CN", "gateway")
            .body(Body::empty())
            .unwrap();

        let next = |_: Request| async {
            Response::new(Body::empty())
        };

        let result = validate_mtls_middleware(request, next).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_middleware_rejects_unauthorized_cn() {
        std::env::set_var("MTLS_STRICT_MODE", "true");

        let request = Request::builder()
            .method(Method::GET)
            .uri("/api/quizzes")
            .header("X-Client-CN", "attacker")
            .body(Body::empty())
            .unwrap();

        let next = |_: Request| async {
            Response::new(Body::empty())
        };

        let result = validate_mtls_middleware(request, next).await;
        assert!(result.is_err());
    }
}