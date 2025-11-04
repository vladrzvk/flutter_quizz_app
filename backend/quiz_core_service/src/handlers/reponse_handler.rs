use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::Json,
};
use shared::AppError;
use uuid::Uuid;

use crate::{
    AppState, // ✅ IMPORTANT
    dto::reponse_dto::{CreateBulkReponsesRequest, CreateReponseRequest, UpdateReponseRequest},
    models::Reponse,
    services::reponse_service::ReponseService,
};

pub async fn get_question_reponses_handler(
    State(app_state): State<AppState>, // ✅ VÉRIFIER
    Path(question_id): Path<Uuid>,
) -> Result<Json<Vec<Reponse>>, AppError> {
    let reponses = ReponseService::get_by_question_id(&app_state.pool, question_id).await?;
    Ok(Json(reponses))
}

pub async fn get_reponse_by_id_handler(
    State(app_state): State<AppState>, // ✅ VÉRIFIER
    Path(id): Path<Uuid>,
) -> Result<Json<Reponse>, AppError> {
    let reponse = ReponseService::get_by_id(&app_state.pool, id).await?;
    Ok(Json(reponse))
}

pub async fn create_reponse_handler(
    State(app_state): State<AppState>, // ✅ VÉRIFIER
    Json(payload): Json<CreateReponseRequest>,
) -> Result<Json<Reponse>, AppError> {
    let reponse = ReponseService::create(&app_state.pool, payload).await?;
    Ok(Json(reponse))
}

pub async fn create_bulk_reponses_handler(
    State(app_state): State<AppState>, // ✅ VÉRIFIER
    Path(question_id): Path<Uuid>,
    Json(payload): Json<CreateBulkReponsesRequest>,
) -> Result<Json<Vec<Reponse>>, AppError> {
    let reponses = ReponseService::create_bulk(&app_state.pool, question_id, payload).await?;
    Ok(Json(reponses))
}

pub async fn update_reponse_handler(
    State(app_state): State<AppState>, // ✅ VÉRIFIER
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateReponseRequest>,
) -> Result<Json<Reponse>, AppError> {
    let reponse = ReponseService::update(&app_state.pool, id, payload).await?;
    Ok(Json(reponse))
}

pub async fn delete_reponse_handler(
    State(app_state): State<AppState>, // ✅ VÉRIFIER
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    ReponseService::delete(&app_state.pool, id).await?;
    Ok(StatusCode::NO_CONTENT)
}
