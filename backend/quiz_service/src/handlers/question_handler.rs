use axum::{
    extract::{Path, State},
    response::Json,
};
use shared::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{dto::CreateQuestionRequest, models::Question, services::QuestionService};

pub async fn get_quiz_questions_handler(
    State(pool): State<PgPool>,
    Path(quiz_id): Path<Uuid>,
) -> Result<Json<Vec<Question>>, AppError> {
    let questions = QuestionService::get_by_quiz_id(&pool, quiz_id).await?;
    Ok(Json(questions))
}

pub async fn get_question_by_id_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Question>, AppError> {
    let question = QuestionService::get_by_id(&pool, id).await?;
    Ok(Json(question))
}

pub async fn create_question_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<CreateQuestionRequest>,
) -> Result<Json<Question>, AppError> {
    let question = QuestionService::create(&pool, payload).await?;
    Ok(Json(question))
}

pub async fn update_question_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
    Json(payload): Json<CreateQuestionRequest>,
) -> Result<Json<Question>, AppError> {
    let question = QuestionService::update(&pool, id, payload).await?;
    Ok(Json(question))
}

pub async fn delete_question_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    QuestionService::delete(&pool, id).await?;
    Ok(Json(serde_json::json!({
        "message": "Question deleted successfully",
        "id": id
    })))
}