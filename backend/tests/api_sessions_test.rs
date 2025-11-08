// backend/quiz_core_service/tests/api_sessions_test.rs
//  Template de Test : Sessions Endpoints (Workflow)
//
// Ce template montre comment tester un WORKFLOW métier :
// 1. Créer une session
// 2. Répondre aux questions
// 3. Finaliser la session
// 4. Vérifier le score

mod helpers;

use axum::http::StatusCode;
use helpers::*;
use serde_json::json;

// ========================================
//  Test: Créer une session
// ========================================

///  Test : POST /api/v1/quizzes/:quiz_id/sessions
#[tokio::test]
async fn test_start_session_success() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;

    let app = create_test_app(pool.clone()).await;

    let user_id = uuid::Uuid::new_v4();
    let payload = json!({
        "user_id": user_id.to_string()
    });

    let uri = format!("/api/v1/quizzes/{}/sessions", quiz_id);
    let (status, body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::CREATED);

    let session: serde_json::Value = serde_json::from_str(&body)
        .expect("Response should be valid JSON");

    // Vérifier les champs de la session
    assert_eq!(session["quiz_id"], quiz_id.to_string());
    assert_eq!(session["user_id"], user_id.to_string());
    assert_eq!(session["status"], "en_cours");
    assert_eq!(session["score"], 0);
    assert!(session["id"].is_string());
    assert!(session["started_at"].is_string());

    cleanup_test_db(&pool).await;
}

///  Test : Créer session avec quiz inexistant
#[tokio::test]
async fn test_start_session_quiz_not_found() {
    let pool = setup_test_db().await;
    let app = create_test_app(pool.clone()).await;

    let fake_quiz_id = uuid::Uuid::new_v4();
    let user_id = uuid::Uuid::new_v4();

    let payload = json!({
        "user_id": user_id.to_string()
    });

    let uri = format!("/api/v1/quizzes/{}/sessions", fake_quiz_id);
    let (status, _body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::NOT_FOUND);

    cleanup_test_db(&pool).await;
}

// ========================================
//  Test: Récupérer une session
// ========================================

///  Test : GET /api/v1/sessions/:session_id
#[tokio::test]
async fn test_get_session_by_id() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    let app = create_test_app(pool.clone()).await;

    let uri = format!("/api/v1/sessions/{}", session_id);
    let (status, body) = get(app, &uri).await;

    assert_eq!(status, StatusCode::OK);

    let session: serde_json::Value = serde_json::from_str(&body)
        .expect("Response should be valid JSON");

    assert_eq!(session["id"], session_id.to_string());
    assert_eq!(session["status"], "en_cours");

    cleanup_test_db(&pool).await;
}

// ========================================
//  Test: Workflow complet
// ========================================

///  Test : Workflow complet d'une session
///
/// Ce test simule un parcours utilisateur complet :
/// 1. Créer un quiz avec questions
/// 2. Démarrer une session
/// 3. Répondre aux questions
/// 4. Finaliser la session
/// 5. Vérifier le score
#[tokio::test]
async fn test_complete_session_workflow() {
    let pool = setup_test_db().await;

    // === 1. Setup : Créer quiz + questions ===
    let quiz_id = create_test_quiz(&pool).await;
    let question1_id = create_test_question(&pool, quiz_id).await;

    // Créer réponses pour la question
    sqlx::query(
        r#"
        INSERT INTO reponses (question_id, valeur, ordre, is_correct)
        VALUES
            ($1, 'Paris', 1, true),
            ($1, 'Lyon', 2, false),
            ($1, 'Marseille', 3, false)
        "#
    )
        .bind(question1_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    // === 2. Action : Démarrer session ===
    let user_id = uuid::Uuid::new_v4();
    let start_payload = json!({
        "user_id": user_id.to_string()
    });

    let start_uri = format!("/api/v1/quizzes/{}/sessions", quiz_id);
    let (status, body) = post(app.clone(), &start_uri, start_payload.to_string()).await;

    assert_eq!(status, StatusCode::CREATED);

    let session: serde_json::Value = serde_json::from_str(&body).unwrap();
    let session_id = session["id"].as_str().unwrap();

    // === 3. Action : Répondre à la question ===
    let answer_payload = json!({
        "question_id": question1_id.to_string(),
        "user_answer": "Paris"
    });

    let answer_uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, answer_body) = post(app.clone(), &answer_uri, answer_payload.to_string()).await;

    assert_eq!(status, StatusCode::OK);

    let answer_result: serde_json::Value = serde_json::from_str(&answer_body).unwrap();
    assert_eq!(answer_result["is_correct"], true);

    // === 4. Action : Finaliser la session ===
    let finalize_uri = format!("/api/v1/sessions/{}/finalize", session_id);
    let (status, finalize_body) = post(app, &finalize_uri, "{}".to_string()).await;

    assert_eq!(status, StatusCode::OK);

    let final_session: serde_json::Value = serde_json::from_str(&finalize_body).unwrap();

    // === 5. Assertions : Vérifier résultat final ===
    assert_eq!(final_session["status"], "termine");
    assert!(final_session["score"].as_i64().unwrap() > 0);
    assert!(final_session["finished_at"].is_string());

    cleanup_test_db(&pool).await;
}

///  Test : Finaliser une session déjà terminée
#[tokio::test]
async fn test_finalize_already_finished_session() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    // Marquer la session comme terminée
    sqlx::query("UPDATE sessions SET status = 'termine' WHERE id = $1")
        .bind(session_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    let uri = format!("/api/v1/sessions/{}/finalize", session_id);
    let (status, _body) = post(app, &uri, "{}".to_string()).await;

    // Devrait retourner une erreur (400 ou 409)
    assert!(
        status == StatusCode::BAD_REQUEST || status == StatusCode::CONFLICT,
        "Ne devrait pas pouvoir finaliser une session déjà terminée"
    );

    cleanup_test_db(&pool).await;
}

// ========================================
//  NOTES : Tests de Workflow
// ========================================
//
// Pour tester un workflow complexe :
//
// 1. Découper en étapes claires
// 2. Tester chaque étape individuellement
// 3. Tester le workflow complet
// 4. Tester les cas d'erreur (workflow interrompu, état invalide, etc.)
//
// Bonnes pratiques :
// - Utiliser des noms descriptifs
// - Commenter les étapes du workflow
// - Vérifier l'état après chaque étape
// - Tester les transitions d'état invalides