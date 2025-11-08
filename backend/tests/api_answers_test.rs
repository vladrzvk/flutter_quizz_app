// backend/quiz_core_service/tests/api_answers_test.rs
// ✍️ Template de Test : Answers Endpoints (Logique Métier)
//
// Ce template montre comment tester la LOGIQUE MÉTIER :
// - Validation des réponses
// - Calcul du score
// - Règles de temps
// - Edge cases

mod helpers;

use axum::http::StatusCode;
use helpers::*;
use serde_json::json;

// ========================================
//  Tests: Réponse correcte
// ========================================

///  Test : Soumettre une réponse correcte
#[tokio::test]
async fn test_submit_correct_answer() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let question_id = create_test_question(&pool, quiz_id).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    // Créer les réponses
    sqlx::query(
        r#"
        INSERT INTO reponses (question_id, valeur, ordre, is_correct)
        VALUES
            ($1, 'Paris', 1, true),
            ($1, 'Lyon', 2, false)
        "#
    )
        .bind(question_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    let payload = json!({
        "question_id": question_id.to_string(),
        "user_answer": "Paris"
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::OK);

    let result: serde_json::Value = serde_json::from_str(&body).unwrap();

    assert_eq!(result["is_correct"], true);
    assert!(result["points_earned"].as_i64().unwrap() > 0);

    cleanup_test_db(&pool).await;
}

///  Test : Soumettre une réponse incorrecte
#[tokio::test]
async fn test_submit_incorrect_answer() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let question_id = create_test_question(&pool, quiz_id).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    // Créer les réponses
    sqlx::query(
        r#"
        INSERT INTO reponses (question_id, valeur, ordre, is_correct)
        VALUES
            ($1, 'Paris', 1, true),
            ($1, 'Lyon', 2, false)
        "#
    )
        .bind(question_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    let payload = json!({
        "question_id": question_id.to_string(),
        "user_answer": "Lyon"  // Mauvaise réponse
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::OK);

    let result: serde_json::Value = serde_json::from_str(&body).unwrap();

    assert_eq!(result["is_correct"], false);
    assert_eq!(result["points_earned"], 0);

    cleanup_test_db(&pool).await;
}

// ========================================
//  Tests: Gestion du temps
// ========================================

///  Test : Réponse avec temps écoulé (timeout)
#[tokio::test]
async fn test_submit_answer_timeout() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let question_id = create_test_question(&pool, quiz_id).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    // Simuler un temps écoulé (modifier started_at dans le passé)
    sqlx::query(
        "UPDATE sessions SET started_at = NOW() - INTERVAL '1 hour' WHERE id = $1"
    )
        .bind(session_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    let payload = json!({
        "question_id": question_id.to_string(),
        "user_answer": "Paris",
        "time_taken": 3700  // 1h + 100s (au-delà du timeout)
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, _body) = post(app, &uri, payload.to_string()).await;

    // Devrait rejeter (timeout)
    assert_eq!(status, StatusCode::REQUEST_TIMEOUT);

    cleanup_test_db(&pool).await;
}

///  Test : Réponse rapide (bonus de points)
#[tokio::test]
async fn test_submit_answer_fast_bonus() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let question_id = create_test_question(&pool, quiz_id).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    sqlx::query(
        r#"
        INSERT INTO reponses (question_id, valeur, ordre, is_correct)
        VALUES ($1, 'Paris', 1, true)
        "#
    )
        .bind(question_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    let payload = json!({
        "question_id": question_id.to_string(),
        "user_answer": "Paris",
        "time_taken": 3  // Très rapide (3 secondes)
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::OK);

    let result: serde_json::Value = serde_json::from_str(&body).unwrap();

    // Devrait avoir un bonus de points pour rapidité
    assert!(result["points_earned"].as_i64().unwrap() >= 10);
    assert_eq!(result["bonus_reason"], "fast_answer");

    cleanup_test_db(&pool).await;
}

// ========================================
//  Tests: Validation et Edge Cases
// ========================================

///  Test : Répondre à une question qui n'existe pas
#[tokio::test]
async fn test_submit_answer_question_not_found() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    let app = create_test_app(pool.clone()).await;

    let fake_question_id = uuid::Uuid::new_v4();
    let payload = json!({
        "question_id": fake_question_id.to_string(),
        "user_answer": "Paris"
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, _body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::NOT_FOUND);

    cleanup_test_db(&pool).await;
}

///  Test : Répondre deux fois à la même question
#[tokio::test]
async fn test_submit_answer_duplicate() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let question_id = create_test_question(&pool, quiz_id).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    sqlx::query(
        r#"
        INSERT INTO reponses (question_id, valeur, ordre, is_correct)
        VALUES ($1, 'Paris', 1, true)
        "#
    )
        .bind(question_id)
        .execute(&pool)
        .await
        .unwrap();

    let app = create_test_app(pool.clone()).await;

    let payload = json!({
        "question_id": question_id.to_string(),
        "user_answer": "Paris"
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);

    // Première réponse : OK
    let (status1, _) = post(app.clone(), &uri, payload.to_string()).await;
    assert_eq!(status1, StatusCode::OK);

    // Deuxième réponse : Devrait être rejetée
    let (status2, _) = post(app, &uri, payload.to_string()).await;
    assert_eq!(status2, StatusCode::CONFLICT);

    cleanup_test_db(&pool).await;
}

///  Test : Réponse vide
#[tokio::test]
async fn test_submit_empty_answer() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let question_id = create_test_question(&pool, quiz_id).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    let app = create_test_app(pool.clone()).await;

    let payload = json!({
        "question_id": question_id.to_string(),
        "user_answer": ""  // Vide
    });

    let uri = format!("/api/v1/sessions/{}/answers", session_id);
    let (status, _body) = post(app, &uri, payload.to_string()).await;

    assert_eq!(status, StatusCode::BAD_REQUEST);

    cleanup_test_db(&pool).await;
}

///  Test : Calcul du score global
#[tokio::test]
async fn test_score_calculation() {
    let pool = setup_test_db().await;
    let quiz_id = create_test_quiz(&pool).await;
    let session_id = create_test_session(&pool, quiz_id).await;

    // Créer 3 questions
    let q1 = create_test_question(&pool, quiz_id).await;
    let q2 = create_test_question(&pool, quiz_id).await;
    let q3 = create_test_question(&pool, quiz_id).await;

    // Créer réponses
    for qid in [q1, q2, q3] {
        sqlx::query(
            r#"
            INSERT INTO reponses (question_id, valeur, ordre, is_correct)
            VALUES ($1, 'Correct', 1, true), ($1, 'Wrong', 2, false)
            "#
        )
            .bind(qid)
            .execute(&pool)
            .await
            .unwrap();
    }

    let app = create_test_app(pool.clone()).await;

    // Répondre : 2 bonnes, 1 mauvaise
    let answers = vec![
        (q1, "Correct", true),
        (q2, "Correct", true),
        (q3, "Wrong", false),
    ];

    for (qid, answer, _expected) in answers {
        let payload = json!({
            "question_id": qid.to_string(),
            "user_answer": answer
        });

        let uri = format!("/api/v1/sessions/{}/answers", session_id);
        post(app.clone(), &uri, payload.to_string()).await;
    }

    // Récupérer le score
    let session_uri = format!("/api/v1/sessions/{}", session_id);
    let (status, body) = get(app, &session_uri).await;

    assert_eq!(status, StatusCode::OK);

    let session: serde_json::Value = serde_json::from_str(&body).unwrap();
    let score = session["score"].as_i64().unwrap();

    // 2 bonnes réponses sur 3 = 66.67%
    assert!(score >= 60 && score <= 70);

    cleanup_test_db(&pool).await;
}

// ========================================
//  NOTES : Tests de Logique Métier
// ========================================
//
// Quand tester la logique métier :
//
// 1. Règles de calcul (score, points, bonus)
// 2. Règles de validation (format, contraintes)
// 3. Règles temporelles (timeout, délais)
// 4. États et transitions
// 5. Edge cases (valeurs limites, cas extrêmes)
//
// Bonnes pratiques :
// - Tester les valeurs limites (0, max, négatif)
// - Tester les cas d'erreur
// - Tester les dépendances (ordre des actions)
// - Documenter les règles métier dans les tests