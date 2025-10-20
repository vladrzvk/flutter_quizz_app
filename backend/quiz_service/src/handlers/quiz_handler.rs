use axum::{
    extract::{Path, State},
    response::Json,
};
use shared::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{dto::CreateQuizRequest, models::Quiz, services::QuizService};

pub async fn health_handler() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "quiz_service"
    }))
}

pub async fn get_quizzes_handler(
    State(pool): State<PgPool>,
) -> Result<Json<Vec<Quiz>>, AppError> {
    let quizzes = QuizService::get_all_active(&pool).await?;
    Ok(Json(quizzes))
}

pub async fn get_quiz_by_id_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Quiz>, AppError> {
    let quiz = QuizService::get_by_id(&pool, id).await?;
    Ok(Json(quiz))
}

pub async fn create_quiz_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<CreateQuizRequest>,
) -> Result<Json<Quiz>, AppError> {
    let quiz = QuizService::create(&pool, payload).await?;
    Ok(Json(quiz))
}