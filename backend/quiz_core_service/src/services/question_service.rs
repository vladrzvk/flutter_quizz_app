use shared::AppError;
use sqlx::PgPool;
use uuid::Uuid;

use crate::dto::{QuestionWithReponses, ReponseDto};
use crate::{
    dto::question_dto::{CreateQuestionRequest, UpdateQuestionRequest},
    models::Question,
    repositories::question_repo::QuestionRepository,
};

pub struct QuestionService;

impl QuestionService {
    pub async fn get_by_quiz_id(
        pool: &PgPool,
        quiz_id: Uuid,
    ) -> Result<Vec<QuestionWithReponses>, AppError> {
        let questions_with_reponses =
            QuestionRepository::find_by_quiz_id_with_reponses(pool, quiz_id).await?;

        // Convertir en DTO
        let result = questions_with_reponses
            .into_iter()
            .map(|(question, reponses)| {
                QuestionWithReponses {
                    id: question.id,
                    quiz_id: question.quiz_id,
                    ordre: question.ordre,
                    category: question.category,
                    subcategory: question.subcategory,
                    type_question: question.type_question.clone(),
                    question_data: question.question_data.clone(),
                    media_url: question.media_url.clone(),
                    target_id: question.target_id,
                    points: question.points,
                    temps_limite_sec: question.temps_limite_sec,
                    hint: question.hint.clone(),
                    explanation: question.explanation.clone(),
                    metadata: question.metadata.clone(),
                    total_attempts: question.total_attempts,
                    correct_attempts: question.correct_attempts,
                    created_at: question.created_at,
                    updated_at: question.updated_at,
                    reponses: reponses
                        .into_iter()
                        .map(|r| ReponseDto {
                            id: r.id,
                            valeur: r.valeur,
                            is_correct: None, // ❌ NE PAS exposer is_correct au client !
                            ordre: r.ordre,
                        })
                        .collect(),
                }
            })
            .collect();

        Ok(result)
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
            request.category.as_deref(),    // ✅ NOUVEAU
            request.subcategory.as_deref(), // ✅ NOUVEAU
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
            request.category.as_deref(),    // ✅ NOUVEAU
            request.subcategory.as_deref(), // ✅ NOUVEAU
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
