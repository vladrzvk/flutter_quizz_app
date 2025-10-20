use axum::{
    extract::{Path, State},
    response::Json,
};
use shared::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    dto::{CreateReponseRequest, UpdateReponseRequest},
    models::Reponse,
    services::ReponseService,
};

/// GET /api/v1/questions/:question_id/reponses
/// Récupérer toutes les réponses d'une question
pub async fn get_question_reponses_handler(
    State(pool): State<PgPool>,
    Path(question_id): Path<Uuid>,
) -> Result<Json<Vec<Reponse>>, AppError> {
    let reponses = ReponseService::get_by_question_id(&pool, question_id).await?;
    Ok(Json(reponses))
}

/// GET /api/v1/reponses/:id
/// Récupérer une réponse par ID
pub async fn get_reponse_by_id_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Reponse>, AppError> {
    let reponse = ReponseService::get_by_id(&pool, id).await?;
    Ok(Json(reponse))
}

/// POST /api/v1/reponses
/// Créer une nouvelle réponse
pub async fn create_reponse_handler(
    State(pool): State<PgPool>,
    Json(payload): Json<CreateReponseRequest>,
) -> Result<Json<Reponse>, AppError> {
    let reponse = ReponseService::create(&pool, payload).await?;
    Ok(Json(reponse))
}

/// POST /api/v1/questions/:question_id/reponses/bulk
/// Créer plusieurs réponses en une fois
pub async fn create_bulk_reponses_handler(
    State(pool): State<PgPool>,
    Path(question_id): Path<Uuid>,
    Json(payload): Json<Vec<CreateReponseRequest>>,
) -> Result<Json<Vec<Reponse>>, AppError> {
    let reponses = ReponseService::create_bulk(&pool, question_id, payload).await?;
    Ok(Json(reponses))
}

/// PUT /api/v1/reponses/:id
/// Mettre à jour une réponse
pub async fn update_reponse_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateReponseRequest>,
) -> Result<Json<Reponse>, AppError> {
    let reponse = ReponseService::update(&pool, id, payload).await?;
    Ok(Json(reponse))
}

/// DELETE /api/v1/reponses/:id
/// Supprimer une réponse
pub async fn delete_reponse_handler(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, AppError> {
    ReponseService::delete(&pool, id).await?;
    Ok(Json(serde_json::json!({
        "message": "Reponse deleted successfully",
        "id": id
    })))
}