use axum::{
    extract::{Path, State},
    response::Json,
};
use shared::AppError;
use uuid::Uuid;

use crate::{dto::CreateQuestionRequest, models::Question, services::QuestionService, AppState};
use crate::dto::{QuestionWithReponses, UpdateQuestionRequest};

pub async fn get_questions_by_quiz_handler(
    State(app_state): State<AppState>,
    Path(quiz_id): Path<Uuid>,
) -> Result<Json<Vec<QuestionWithReponses>>, AppError> {  // ✅ MODIFIER le type
    let questions = QuestionService::get_by_quiz_id(&app_state.pool, quiz_id).await?;
    Ok(Json(questions))
}

pub async fn get_question_by_id_handler(
    State(app_state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<Question>, AppError> {
    let question = QuestionService::get_by_id(&app_state.pool, id).await?;
    Ok(Json(question))
}

pub async fn create_question_handler(
    State(app_state): State<AppState>,
    Json(payload): Json<CreateQuestionRequest>,
) -> Result<Json<Question>, AppError> {
    let question = QuestionService::create(&app_state.pool, payload).await?;
    Ok(Json(question))
}

pub async fn update_question_handler(
    State(app_state): State<AppState>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateQuestionRequest>,
) -> Result<Json<Question>, AppError> {
    let question = QuestionService::update(&app_state.pool, id, payload).await?;
    Ok(Json(question))
}

pub async fn delete_question_handler(
    State(app_state): State<AppState>,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    QuestionService::delete(&app_state.pool, id).await?;
    Ok(Json(serde_json::json!({
        "message": "Question deleted successfully",
        "id": id
    })))
}