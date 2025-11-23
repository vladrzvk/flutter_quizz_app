// backend/quiz_core_service/tests/api_health_test.rs
//  Template de Test : Health Check Endpoint
//
// Ce test est le plus SIMPLE possible, idéal pour démarrer
// Il vérifie que l'API répond correctement sur /health

mod helpers;

use axum::http::StatusCode;
use helpers::*;

///  Test basique : GET /health
///
/// Ce qu'on teste :
/// - Le serveur répond
/// - Code HTTP 200 OK
/// - Body contient "OK"
#[tokio::test]
async fn test_health_endpoint_returns_ok() {
    // 1. Setup : Préparer la DB et l'app
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    // 2. Action : Faire la requête
    let (status, body) = get(app, "/health").await;

    // 3. Assertions : Vérifier les résultats
    assert_eq!(status, StatusCode::OK, "Le status devrait être 200 OK");
    assert_eq!(body, "OK", "Le body devrait contenir 'OK'");

    // 4. Cleanup : Nettoyer la DB
    cleanup_test_db(&pool).await;
}

/// Test : Vérifier les headers
#[tokio::test]
async fn test_health_endpoint_headers() {
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    // Faire une requête complète pour vérifier les headers
    use axum::body::Body;
    use axum::http::Request;
    use tower::ServiceExt;

    let request = Request::builder()
        .uri("/health")
        .method("GET")
        .body(Body::empty())
        .unwrap();

    let response = app.oneshot(request).await.unwrap();

    // Vérifier status
    assert_eq!(response.status(), StatusCode::OK);

    // Vérifier content-type (optionnel)
    // let content_type = response.headers().get("content-type");
    // assert!(content_type.is_some());

    cleanup_test_db(&pool).await;
}

/// Test : Health avec DB connection
///
/// Vérifie que le endpoint health peut accéder à la DB
#[tokio::test]
async fn test_health_with_database_connection() {
    let pool = setup_test_db().await;

    // Vérifier que la DB est accessible
    let result = sqlx::query("SELECT 1 as check")
        .fetch_one(&pool)
        .await;

    assert!(result.is_ok(), "La DB devrait être accessible");

    // Maintenant tester le endpoint
    let app = create_test_app(pool.clone()).await;
    let (status, _body) = get(app, "/health").await;

    assert_eq!(status, StatusCode::OK);

    cleanup_test_db(&pool).await;
}

// ========================================
//  NOTES POUR ÉCRIRE TES PROPRES TESTS
// ========================================
//
// Structure d'un test :
// 1. Setup    : Préparer DB, données, app
// 2. Action   : Exécuter la requête à tester
// 3. Assert   : Vérifier les résultats
// 4. Cleanup  : Nettoyer la DB
//
// Commandes utiles :
// - cargo test                     : Lance tous les tests
// - cargo test health              : Lance seulement les tests avec "health"
// - cargo test -- --nocapture      : Affiche les println!()
// - cargo test -- --test-threads=1 : Tests séquentiels (évite conflits DB)
//
// Pour débugger :
// - Ajouter println!() dans le test
// - Utiliser dbg!(variable)
// - Lancer avec --nocapture