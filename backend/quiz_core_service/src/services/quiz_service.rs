use shared::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    dto::quiz_dto::CreateQuizRequest,
    models::Quiz,
    repositories::quiz_repo::QuizRepository,
};

pub struct QuizService;

impl QuizService {
    /// Récupérer tous les quiz actifs
    pub async fn get_all_active(pool: &PgPool) -> Result<Vec<Quiz>, AppError> {
        Ok(QuizRepository::find_all_active(pool).await?)
    }

    /// Récupérer un quiz par ID
    pub async fn get_by_id(pool: &PgPool, id: Uuid) -> Result<Quiz, AppError> {
        QuizRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", id)))
    }

    /// Créer un nouveau quiz
    pub async fn create(pool: &PgPool, request: CreateQuizRequest) -> Result<Quiz, AppError> {
        let quiz = QuizRepository::create(
            pool,
            &request.domain,              // ✅ NOUVEAU
            &request.titre,               // ✅
            request.description.as_deref(), // ✅
            &request.niveau_difficulte,   // ✅
            &request.version_app,         // ✅
            &request.scope,               // ✅ CHANGÉ (avant: region_scope)
            &request.mode,                // ✅
            request.nb_questions,         // ✅
        )
            .await?;

        Ok(quiz)
    }
}