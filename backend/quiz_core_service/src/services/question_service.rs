use shared::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    dto::question_dto::{CreateQuestionRequest, UpdateQuestionRequest},
    models::Question,
    repositories::question_repo::QuestionRepository,
};

pub struct QuestionService;

impl QuestionService {
    pub async fn get_by_quiz_id(pool: &PgPool, quiz_id: Uuid) -> Result<Vec<Question>, AppError> {
        Ok(QuestionRepository::find_by_quiz_id(pool, quiz_id).await?)
    }

    pub async fn get_by_id(pool: &PgPool, id: Uuid) -> Result<Question, AppError> {
        QuestionRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", id)))
    }

    /// ✅ Créer question (avec category/subcategory)
    pub async fn create(
        pool: &PgPool,
        request: CreateQuestionRequest,
    ) -> Result<Question, AppError> {
        let question = QuestionRepository::create(
            pool,
            request.quiz_id,
            request.ordre,
            &request.type_question,
            &request.question_data,
            request.media_url.as_deref(),
            request.target_id,
            request.category.as_deref(),        // ✅ NOUVEAU
            request.subcategory.as_deref(),     // ✅ NOUVEAU
            request.points,
            request.temps_limite_sec,
            request.hint.as_deref(),
            request.explanation.as_deref(),
        )
            .await?;

        Ok(question)
    }

    /// ✅ Mettre à jour question
    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        request: UpdateQuestionRequest,
    ) -> Result<Question, AppError> {
        let question = QuestionRepository::update(
            pool,
            id,
            &request.type_question,
            &request.question_data,
            request.media_url.as_deref(),
            request.target_id,
            request.category.as_deref(),        // ✅ NOUVEAU
            request.subcategory.as_deref(),     // ✅ NOUVEAU
            request.points,
            request.temps_limite_sec,
            request.hint.as_deref(),
            request.explanation.as_deref(),
        )
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", id)))?;

        Ok(question)
    }

    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<(), AppError> {
        QuestionRepository::delete(pool, id).await?;
        Ok(())
    }
}
