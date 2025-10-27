use axum::{
    extract::{Path, State},
    response::Json,
};
use shared::AppError;
// use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    dto::{StartSessionRequest, SubmitAnswerRequest},
    models::{SessionQuiz, ReponseUtilisateur},
    services::SessionService,
    AppState
};

pub async fn start_session_handler(
    State(app_state): State<AppState>,
    Path(quiz_id): Path<Uuid>,
    Json(payload): Json<StartSessionRequest>,
) -> Result<Json<SessionQuiz>, AppError> {
    let session = SessionService::start_session(&app_state.pool, quiz_id, payload).await?;
    Ok(Json(session))
}

pub async fn get_session_handler(
    State(app_state): State<AppState>,
    Path(session_id): Path<Uuid>,
) -> Result<Json<SessionQuiz>, AppError> {
    let session = SessionService::get_session(&app_state.pool, session_id).await?;
    Ok(Json(session))
}

pub async fn submit_answer_handler(
    State(app_state): State<AppState>,
    Path(session_id): Path<Uuid>,
    Json(payload): Json<SubmitAnswerRequest>,
) -> Result<Json<ReponseUtilisateur>, AppError> {
    let reponse = SessionService::submit_answer(&app_state.pool, session_id, payload).await?;
    Ok(Json(reponse))
}

pub async fn finalize_session_handler(
    State(app_state): State<AppState>,
    Path(session_id): Path<Uuid>,
) -> Result<Json<SessionQuiz>, AppError> {
    let session = SessionService::finalize_session(&app_state.pool, session_id).await?;
    Ok(Json(session))
}