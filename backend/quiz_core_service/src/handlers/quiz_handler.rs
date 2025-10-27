use axum::{
    extract::{Path, State},
    response::Json,
};
use shared::AppError;
use uuid::Uuid;

use crate::{
    dto::quiz_dto::CreateQuizRequest,
    models::Quiz,
    services::quiz_service::QuizService,
    AppState,  // ✅ IMPORTANT
};

pub async fn health_handler() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "status": "healthy",
        "service": "quiz_core_service",
        "version": env!("CARGO_PKG_VERSION")
    }))
}

pub async fn get_quizzes_handler(
    State(app_state): State<AppState>,  // ✅ VÉRIFIER ICI
) -> Result<Json<Vec<Quiz>>, AppError> {
    let quizzes = QuizService::get_all_active(&app_state.pool).await?;
    Ok(Json(quizzes))
}

pub async fn get_quiz_by_id_handler(
    State(app_state): State<AppState>,  // ✅ VÉRIFIER ICI
    Path(id): Path<Uuid>,
) -> Result<Json<Quiz>, AppError> {
    let quiz = QuizService::get_by_id(&app_state.pool, id).await?;
    Ok(Json(quiz))
}

pub async fn create_quiz_handler(
    State(app_state): State<AppState>,  // ✅ VÉRIFIER ICI
    Json(payload): Json<CreateQuizRequest>,
) -> Result<Json<Quiz>, AppError> {
    let quiz = QuizService::create(&app_state.pool, payload).await?;
    Ok(Json(quiz))
}