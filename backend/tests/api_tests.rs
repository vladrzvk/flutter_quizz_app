// backend/quiz_core_service/tests/api_quizzes_test.rs
//  Template de Test : Quizzes Endpoints (CRUD)
//
// Ce template montre comment tester des endpoints CRUD complets

mod helpers;

use axum::http::StatusCode;
use helpers::*;
use serde_json::json;

// ========================================
// 🟢 TESTS GET (Read)
// ========================================

///  Test : GET /api/v1/quizzes (liste vide)
#[tokio::test]
async fn test_get_quizzes_empty() {
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    let (status, body) = get(app, "/api/v1/quizzes").await;

    assert_eq!(status, StatusCode::OK);

    let quizzes: Vec<serde_json::Value> = serde_json::from_str(&body)
        .expect("Response should be valid JSON array");

    assert_eq!(quizzes.len(), 0, "La liste devrait être vide");

    cleanup_test_db(&pool).await;
}

///  Test : GET /api/v1/quizzes (avec données)
#[tokio::test]
async fn test_get_quizzes_with_data() {
    let pool = setup_test_db().await;

    // Insérer un quiz de test
    let quiz_id = create_test_quiz(&pool).await;

    let app = create_test_app(pool.clone()).await;
    let (status, body) = get(app, "/api/v1/quizzes").await;

    assert_eq!(status, StatusCode::OK);

    let quizzes: Vec<serde_json::Value> = serde_json::from_str(&body)
        .expect("Response should be valid JSON array");

    assert_eq!(quizzes.len(), 1);
    assert_eq!(quizzes[0]["titre"], "Quiz Test");
    assert_eq!(quizzes[0]["id"], quiz_id.to_string());

    cleanup_test_db(&pool).await;
}

///  Test : GET /api/v1/quizzes/:id (trouvé)
#[tokio::test]
async fn test_get_quiz_by_id_found() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;

    let app = create_test_app(pool.clone()).await;
    let uri = format!("/api/v1/quizzes/{}", quiz_id);
    let (status, body) = get(app, &uri).await;

    assert_eq!(status, StatusCode::OK);

    let quiz: serde_json::Value = serde_json::from_str(&body)
        .expect("Response should be valid JSON");

    assert_eq!(quiz["id"], quiz_id.to_string());
    assert_eq!(quiz["titre"], "Quiz Test");
    assert_eq!(quiz["niveau_difficulte"], "facile");

    cleanup_test_db(&pool).await;
}

///  Test : GET /api/v1/quizzes/:id (non trouvé)
#[tokio::test]
async fn test_get_quiz_by_id_not_found() {
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    // ID qui n'existe pas
    let fake_id = uuid::Uuid::new_v4();
    let uri = format!("/api/v1/quizzes/{}", fake_id);
    let (status, _body) = get(app, &uri).await;

    assert_eq!(status, StatusCode::NOT_FOUND);

    cleanup_test_db(&pool).await;
}

// ========================================
// 🟡 TESTS POST (Create)
// ========================================

///  Test : POST /api/v1/quizzes (création valide)
#[tokio::test]
async fn test_create_quiz_success() {
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    let new_quiz = json!({
        "domain": "geography",
        "titre": "Nouveau Quiz",
        "description": "Description test",
        "niveau_difficulte": "moyen",
        "version_app": "1.0.0",
        "scope": "france",
        "mode": "decouverte",
        "nb_questions": 10,
        "is_active": true
    });

    let (status, body) = post(
        app,
        "/api/v1/quizzes",
        new_quiz.to_string()
    ).await;

    assert_eq!(status, StatusCode::CREATED);

    let created_quiz: serde_json::Value = serde_json::from_str(&body)
        .expect("Response should be valid JSON");

    assert_eq!(created_quiz["titre"], "Nouveau Quiz");
    assert!(created_quiz["id"].is_string());

    cleanup_test_db(&pool).await;
}

///  Test : POST /api/v1/quizzes (données invalides)
#[tokio::test]
async fn test_create_quiz_invalid_data() {
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    // Données incomplètes (manque des champs requis)
    let invalid_quiz = json!({
        "titre": "Quiz Invalide"
        // Manque domain, niveau_difficulte, etc.
    });

    let (status, _body) = post(
        app,
        "/api/v1/quizzes",
        invalid_quiz.to_string()
    ).await;

    assert_eq!(status, StatusCode::BAD_REQUEST);

    cleanup_test_db(&pool).await;
}

// ========================================
//  TESTS PUT (Update)
// ========================================

///  Test : PUT /api/v1/quizzes/:id (mise à jour)
#[tokio::test]
async fn test_update_quiz_success() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;

    let app = create_test_app(pool.clone()).await;

    let updated_data = json!({
        "titre": "Quiz Modifié",
        "description": "Nouvelle description",
        "niveau_difficulte": "difficile"
    });

    let uri = format!("/api/v1/quizzes/{}", quiz_id);
    let (status, body) = put(app, &uri, updated_data.to_string()).await;

    assert_eq!(status, StatusCode::OK);

    let updated_quiz: serde_json::Value = serde_json::from_str(&body)
        .expect("Response should be valid JSON");

    assert_eq!(updated_quiz["titre"], "Quiz Modifié");
    assert_eq!(updated_quiz["niveau_difficulte"], "difficile");

    cleanup_test_db(&pool).await;
}

// ========================================
//  TESTS DELETE (Delete)
// ========================================

///  Test : DELETE /api/v1/quizzes/:id
#[tokio::test]
async fn test_delete_quiz_success() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;

    let app = create_test_app(pool.clone()).await;

    let uri = format!("/api/v1/quizzes/{}", quiz_id);
    let (status, _body) = delete(app, &uri).await;

    assert_eq!(status, StatusCode::NO_CONTENT);

    // Vérifier que le quiz a bien été supprimé
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM quizzes WHERE id = $1")
        .bind(quiz_id)
        .fetch_one(&pool)
        .await
        .unwrap();

    assert_eq!(count, 0, "Le quiz devrait être supprimé");

    cleanup_test_db(&pool).await;
}

// ========================================
//  NOTES : Comment adapter ce template
// ========================================
//
// 1. Copier ce fichier pour un autre endpoint
// 2. Remplacer "quizzes" par ton endpoint (ex: "users", "sessions")
// 3. Adapter les JSON de test selon ton schema
// 4. Ajouter tes règles métier spécifiques
//
// Exemples de tests additionnels à ajouter :
// - Filtrage (query params)
// - Pagination
// - Tri
// - Validation métier spécifique
// - Permissions/Authorization