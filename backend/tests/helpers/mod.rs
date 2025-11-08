// backend/quiz_core_service/tests/helpers/mod.rs
// Helpers et utilitaires pour les tests

use axum::{
    body::Body,
    http::{Request, StatusCode},
    Router,
};
use sqlx::PgPool;
use tower::ServiceExt;

/// Setup de la base de données de test
pub async fn setup_test_db() -> PgPool {
    // Charger .env.test si disponible
    dotenv::from_filename(".env.test").ok();

    // Récupérer l'URL de la DB test
    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| {
            "postgresql://quiz_user:quiz_test@localhost:5433/quiz_db_test".to_string()
        });

    println!("🔌 Connecting to test database...");

    // Connexion à la DB
    let pool = PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to test database. Is it running?");

    println!("Connected to test database");

    // Appliquer les migrations
    println!("Running migrations...");
    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .expect("Failed to run migrations");

    println!("Migrations applied");

    pool
}

/// Cleanup de la base de données après tests
pub async fn cleanup_test_db(pool: &PgPool) {
    println!("🧹 Cleaning up test database...");

    // Désactiver les contraintes FK temporairement
    sqlx::query("SET session_replication_role = replica;")
        .execute(pool)
        .await
        .ok();

    // Truncate toutes les tables dans le bon ordre
    sqlx::query(
        r#"
        TRUNCATE TABLE
            user_answers,
            sessions,
            reponses,
            questions,
            quizzes,
            users
        RESTART IDENTITY CASCADE
        "#
    )
        .execute(pool)
        .await
        .ok();

    // Réactiver les contraintes FK
    sqlx::query("SET session_replication_role = DEFAULT;")
        .execute(pool)
        .await
        .ok();

    println!("Database cleaned");
}

/// Créer l'application de test
pub async fn create_test_app(pool: PgPool) -> Router {
    // Importer depuis votre crate
    // Adapter selon votre structure réelle
    use quiz_core_service::{create_app_state, create_router};

    let state = create_app_state(pool);
    create_router(state)
}

/// Helper pour faire des requêtes HTTP de test
pub async fn test_request(
    app: Router,
    method: &str,
    uri: &str,
    body: Option<String>,
) -> (StatusCode, String) {
    let mut request_builder = Request::builder()
        .uri(uri)
        .method(method);

    let request = if let Some(body_content) = body {
        request_builder
            .header("content-type", "application/json; charset=utf-8")
            .body(Body::from(body_content))
            .unwrap()
    } else {
        request_builder.body(Body::empty()).unwrap()
    };

    let response = app
        .oneshot(request)
        .await
        .expect("Failed to send request");

    let status = response.status();

    let body_bytes = axum::body::to_bytes(response.into_body(), usize::MAX)
        .await
        .expect("Failed to read response body");

    let body_str = String::from_utf8(body_bytes.to_vec())
        .expect("Response body is not valid UTF-8");

    (status, body_str)
}

/// Helper pour faire une requête GET
pub async fn get(app: Router, uri: &str) -> (StatusCode, String) {
    test_request(app, "GET", uri, None).await
}

/// Helper pour faire une requête POST
pub async fn post(app: Router, uri: &str, body: String) -> (StatusCode, String) {
    test_request(app, "POST", uri, Some(body)).await
}

/// Helper pour faire une requête PUT
pub async fn put(app: Router, uri: &str, body: String) -> (StatusCode, String) {
    test_request(app, "PUT", uri, Some(body)).await
}

/// Helper pour faire une requête DELETE
pub async fn delete(app: Router, uri: &str) -> (StatusCode, String) {
    test_request(app, "DELETE", uri, None).await
}

/// Créer un quiz de test
pub async fn create_test_quiz(pool: &PgPool) -> uuid::Uuid {
    let quiz_id = sqlx::query_scalar::<_, uuid::Uuid>(
        r#"
        INSERT INTO quizzes (
            domain, titre, description, niveau_difficulte,
            version_app, scope, mode, nb_questions, is_active
        ) VALUES (
            'geography', 'Quiz Test', 'Quiz pour tests',
            'facile', '1.0.0', 'france', 'decouverte', 5, true
        )
        RETURNING id
        "#
    )
        .fetch_one(pool)
        .await
        .expect("Failed to create test quiz");

    quiz_id
}

/// Créer une question de test
pub async fn create_test_question(pool: &PgPool, quiz_id: uuid::Uuid) -> uuid::Uuid {
    let question_id = sqlx::query_scalar::<_, uuid::Uuid>(
        r#"
        INSERT INTO questions (
            quiz_id, ordre, category, subcategory,
            type_question, question_data, points
        ) VALUES (
            $1, 1, 'geographie', 'capitales',
            'qcm', '{"text": "Capitale de la France ?"}', 10
        )
        RETURNING id
        "#
    )
        .bind(quiz_id)
        .fetch_one(pool)
        .await
        .expect("Failed to create test question");

    question_id
}

/// Créer une session de test
pub async fn create_test_session(pool: &PgPool, quiz_id: uuid::Uuid) -> uuid::Uuid {
    let user_id = uuid::Uuid::new_v4();

    let session_id = sqlx::query_scalar::<_, uuid::Uuid>(
        r#"
        INSERT INTO sessions (
            quiz_id, user_id, status, score
        ) VALUES (
            $1, $2, 'en_cours', 0
        )
        RETURNING id
        "#
    )
        .bind(quiz_id)
        .bind(user_id)
        .fetch_one(pool)
        .await
        .expect("Failed to create test session");

    session_id
}