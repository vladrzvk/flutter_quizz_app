mod modele;


use axum::{
    extract::{Path, State},
    response::Json,
    routing::{get,post},
    Router,
};
use modele::{Quiz, Question, SessionQuiz, ReponseUtilisateur};
use shared::AppError;
use sqlx::PgPool;
use serde::{Deserialize, Serialize};
use std::net::SocketAddr;

use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use uuid::Uuid;


// #[derive(Serialize, Deserialize)]
// struct HelloResponse {
//     message: String,
//     service: String,
//     version: String,
// }

// async fn hello_handler() -> Json<HelloResponse> {
//     Json(HelloResponse {
//         message: "Hello World from Quiz Service!".to_string(),
//         service: "quiz_service".to_string(),
//         version: "0.1.0".to_string(),
//     })
// }

#[derive(Serialize, Deserialize)]
struct HealthResponse {
    status: String,
    service: String,
}

#[derive(Debug, Deserialize)]
struct CreateQuizRequest {
    titre: String,
    description: Option<String>,
    niveau_difficulte: String,
    version_app: String,
    region_scope: String,
    mode: String,
    nb_questions: i32,
}

#[derive(Debug, Deserialize)]
struct CreateQuestionRequest {
    quiz_id: Uuid,
    ordre: i32,
    type_question: String,
    question_data: serde_json::Value,
    region_cible_id: Option<Uuid>,
    points: i32,
    temps_limite_sec: Option<i32>,
    hint: Option<String>,
    explanation: Option<String>,
}

#[derive(Debug, Deserialize)]
struct StartSessionRequest {
    user_id: Uuid,
}

#[derive(Debug, Deserialize)]
struct SubmitAnswerRequest {
    question_id: Uuid,
    reponse_id: Option<Uuid>,
    valeur_saisie: Option<String>,
    temps_reponse_sec: i32,
}

async fn health_handler() -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "healthy".to_string(),
        service: "quiz_service".to_string(),
    })
}
// ============= HANDLERS POUR QUIZZ =============
// Handler: Get all quizzes
async fn get_quizzes_handler(
    State(pool): State<PgPool>,
) -> Result<Json<Vec<Quiz>>, AppError> {
    let quizzes = sqlx::query_as::<_, Quiz>(
        "SELECT * FROM quizzes WHERE is_active = true ORDER BY created_at DESC"
    )
        .fetch_all(&pool)
        .await?;

    Ok(Json(quizzes))
}

// Handler: Get quiz by ID
async fn get_quiz_by_id_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Quiz>, AppError> {
    let quiz = sqlx::query_as::<_, Quiz>("SELECT * FROM quizzes WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", id)))?;

    Ok(Json(quiz))
}

// Handler: Create quiz
async fn create_quiz_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<CreateQuizRequest>,
) -> Result<Json<Quiz>, AppError> {
    let quiz = sqlx::query_as::<_, Quiz>(
        r#"
        INSERT INTO quizzes (titre, description, niveau_difficulte, version_app, region_scope, mode, nb_questions)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
        "#
    )
        .bind(&payload.titre)
        .bind(&payload.description)
        .bind(&payload.niveau_difficulte)
        .bind(&payload.version_app)
        .bind(&payload.region_scope)
        .bind(&payload.mode)
        .bind(payload.nb_questions)
        .fetch_one(&pool)
        .await?;

    Ok(Json(quiz))
}

// Handler: Get all questions for a quiz
async fn get_quiz_questions_handler(
    State(pool): State<PgPool>,
    Path(quiz_id): Path<Uuid>,
) -> Result<Json<Vec<Question>>, AppError> {
    // Vérifier que le quiz existe
    let _quiz = sqlx::query_as::<_, Quiz>("SELECT * FROM quizzes WHERE id = $1")
        .bind(quiz_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", quiz_id)))?;

    // Récupérer les questions
    let questions = sqlx::query_as::<_, Question>(
        "SELECT * FROM questions WHERE quiz_id = $1 ORDER BY ordre ASC"
    )
        .bind(quiz_id)
        .fetch_all(&pool)
        .await?;

    Ok(Json(questions))
}
// ============= HANDLERS POUR QUESTIONS =============
// Handler: Get a specific question
async fn get_question_by_id_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Question>, AppError> {
    let question = sqlx::query_as::<_, Question>(
        "SELECT * FROM questions WHERE id = $1"
    )
        .bind(id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", id)))?;

    Ok(Json(question))
}

// Handler: Create a question
async fn create_question_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<CreateQuestionRequest>,
) -> Result<Json<Question>, AppError> {
    // Vérifier que le quiz existe
    let _quiz = sqlx::query_as::<_, Quiz>("SELECT * FROM quizzes WHERE id = $1")
        .bind(payload.quiz_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", payload.quiz_id)))?;

    // Créer la question
    let question = sqlx::query_as::<_, Question>(
        r#"
        INSERT INTO questions (
            quiz_id, ordre, type_question, question_data,
            region_cible_id, points, temps_limite_sec, hint, explanation
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING *
        "#
    )
        .bind(payload.quiz_id)
        .bind(payload.ordre)
        .bind(&payload.type_question)
        .bind(&payload.question_data)
        .bind(payload.region_cible_id)
        .bind(payload.points)
        .bind(payload.temps_limite_sec)
        .bind(&payload.hint)
        .bind(&payload.explanation)
        .fetch_one(&pool)
        .await?;

    Ok(Json(question))
}

// Handler: Update a question
async fn update_question_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
    Json(payload): Json<CreateQuestionRequest>,
) -> Result<Json<Question>, AppError> {
    let question = sqlx::query_as::<_, Question>(
        r#"
        UPDATE questions
        SET ordre = $2, type_question = $3, question_data = $4,
            region_cible_id = $5, points = $6, temps_limite_sec = $7,
            hint = $8, explanation = $9, updated_at = NOW()
        WHERE id = $1
        RETURNING *
        "#
    )
        .bind(id)
        .bind(payload.ordre)
        .bind(&payload.type_question)
        .bind(&payload.question_data)
        .bind(payload.region_cible_id)
        .bind(payload.points)
        .bind(payload.temps_limite_sec)
        .bind(&payload.hint)
        .bind(&payload.explanation)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", id)))?;

    Ok(Json(question))
}

// Handler: Delete a question
async fn delete_question_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    let result = sqlx::query("DELETE FROM questions WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await?;

    if result.rows_affected() == 0 {
        return Err(AppError::NotFound(format!("Question with id {} not found", id)));
    }

    Ok(Json(serde_json::json!({
        "message": "Question deleted successfully",
        "id": id
    })))
}

// ============= HANDLERS POUR SESSIONS =============

// Handler: Start a quiz session
async fn start_session_handler(
    State(pool): State<PgPool>,
    Path(quiz_id): Path<Uuid>,
    Json(payload): Json<StartSessionRequest>,
) -> Result<Json<SessionQuiz>, AppError> {
    // Vérifier que le quiz existe
    let _quiz = sqlx::query_as::<_, Quiz>("SELECT * FROM quizzes WHERE id = $1")
        .bind(quiz_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", quiz_id)))?;

    // Calculer le score maximum
    let score_max_i64: i64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(points), 0) FROM questions WHERE quiz_id = $1"
    )
        .bind(quiz_id)
        .fetch_one(&pool)
        .await?;

    // Convertir en i32 pour l'insertion
    let score_max = score_max_i64 as i32;
    
    // Créer la session
    let session = sqlx::query_as::<_, SessionQuiz>(
        r#"
        INSERT INTO sessions_quiz (user_id, quiz_id, score_max, date_debut)
        VALUES ($1, $2, $3, NOW())
        RETURNING *
        "#
    )
        .bind(payload.user_id)
        .bind(quiz_id)
        .bind(score_max)
        .fetch_one(&pool)
        .await?;

    Ok(Json(session))
}

// Handler: Get session by ID
async fn get_session_handler(
    State(pool): State<PgPool>,
    Path(session_id): Path<Uuid>,
) -> Result<Json<SessionQuiz>, AppError> {
    let session = sqlx::query_as::<_, SessionQuiz>(
        "SELECT * FROM sessions_quiz WHERE id = $1"
    )
        .bind(session_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound(format!("Session with id {} not found", session_id)))?;

    Ok(Json(session))
}

// Handler: Submit an answer
async fn submit_answer_handler(
    State(pool): State<PgPool>,
    Path(session_id): Path<Uuid>,
    Json(payload): Json<SubmitAnswerRequest>,
) -> Result<Json<ReponseUtilisateur>, AppError> {
    // Vérifier que la session existe et est en cours
    let session = sqlx::query_as::<_, SessionQuiz>(
        "SELECT * FROM sessions_quiz WHERE id = $1 AND status = 'en_cours'"
    )
        .bind(session_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::BadRequest("Session not found or already completed".to_string()))?;

    // Récupérer la question
    let question = sqlx::query_as::<_, Question>(
        "SELECT * FROM questions WHERE id = $1"
    )
        .bind(payload.question_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

    // Vérifier que la question appartient au quiz de la session
    if question.quiz_id != session.quiz_id {
        return Err(AppError::BadRequest("Question does not belong to this quiz".to_string()));
    }

    // Déterminer si la réponse est correcte (logique simplifiée pour V0)
    let is_correct = if let Some(reponse_id) = payload.reponse_id {
        // Vérifier si cette réponse est marquée comme correcte
        let correct: bool = sqlx::query_scalar(
            "SELECT is_correct FROM reponses WHERE id = $1"
        )
            .bind(reponse_id)
            .fetch_optional(&pool)
            .await?
            .unwrap_or(false);
        correct
    } else if let Some(ref valeur) = payload.valeur_saisie {
        // Vérifier si cette valeur correspond à une réponse correcte
        let correct: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM reponses WHERE question_id = $1 AND valeur = $2 AND is_correct = true)"
        )
            .bind(payload.question_id)
            .bind(valeur)
            .fetch_one(&pool)
            .await?;
        correct
    } else {
        false
    };

    let points_obtenus = if is_correct { question.points } else { 0 };

    // Enregistrer la réponse utilisateur
    let reponse_user = sqlx::query_as::<_, ReponseUtilisateur>(
        r#"
        INSERT INTO reponses_utilisateur (
            session_id, question_id, reponse_id, valeur_saisie,
            is_correct, points_obtenus, temps_reponse_sec
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
        "#
    )
        .bind(session_id)
        .bind(payload.question_id)
        .bind(payload.reponse_id)
        .bind(&payload.valeur_saisie)
        .bind(is_correct)
        .bind(points_obtenus)
        .bind(payload.temps_reponse_sec)
        .fetch_one(&pool)
        .await?;

    // Mettre à jour le score de la session
    sqlx::query(
        "UPDATE sessions_quiz SET score = score + $1 WHERE id = $2"
    )
        .bind(points_obtenus)
        .bind(session_id)
        .execute(&pool)
        .await?;

    Ok(Json(reponse_user))
}

// Handler: Finalize session
async fn finalize_session_handler(
    State(pool): State<PgPool>,
    Path(session_id): Path<Uuid>,
) -> Result<Json<SessionQuiz>, AppError> {
    // Calculer le temps total et finaliser
    let session = sqlx::query_as::<_, SessionQuiz>(
        r#"
        UPDATE sessions_quiz
        SET status = 'termine',
            date_fin = NOW(),
            temps_total_sec = EXTRACT(EPOCH FROM (NOW() - date_debut))::INTEGER
        WHERE id = $1 AND status = 'en_cours'
        RETURNING *
        "#
    )
        .bind(session_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound("Session not found or already finalized".to_string()))?;

    Ok(Json(session))
}

#[tokio::main]
async fn main() {
    // Load .env file
    dotenvy::dotenv().ok();

    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "quiz_service=debug,tower_http=debug,sqlx=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Get DATABASE_URL from environment
    let database_url = std::env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set in .env file");

    // Create database connection pool
    tracing::info!("Connecting to database...");
    let pool = PgPool::connect(&database_url).await.expect("Failed to connect to database");
    tracing::info!("✅ Connected to database");

    let app = Router::new()
        // .route("/hello", get(hello_handler))
        .route("/health", get(health_handler))
        // Routes Quiz
        .route("/api/v1/quizzes", get(get_quizzes_handler))
        .route("/api/v1/quizzes/:id", get(get_quiz_by_id_handler))
        .route("/api/v1/quizzes", post(create_quiz_handler))
        // Routes Questions
        .route("/api/v1/quizzes/:quiz_id/questions", get(get_quiz_questions_handler))
        .route("/api/v1/questions", post(create_question_handler))
        .route("/api/v1/questions/:id",
               get(get_question_by_id_handler)
                   .put(update_question_handler)
                   .delete(delete_question_handler))
        // Routes Sessions
       .route("/api/v1/quizzes/:quiz_id/sessions", post(start_session_handler))
       .route("/api/v1/sessions/:session_id", get(get_session_handler))
       .route("/api/v1/sessions/:session_id/answers", post(submit_answer_handler))
       .route("/api/v1/sessions/:session_id/finalize", post(finalize_session_handler))
        .layer(CorsLayer::permissive()).with_state(pool);

    let addr = SocketAddr::from(([127, 0, 0, 1], 8080));
    tracing::info!("🚀 Quiz Service listening on {}", addr);


    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind to address");

    axum::serve(listener, app)
        .await
        .expect("Server error");
}