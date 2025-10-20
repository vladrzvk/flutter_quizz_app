use sqlx::PgPool;
use uuid::Uuid;
use shared::AppError;
use crate::{
    dto::CreateQuestionRequest,
    models::Question,
    repositories::{QuestionRepository, QuizRepository},
};

pub struct QuestionService;

impl QuestionService {
    pub async fn get_by_quiz_id(pool: &PgPool, quiz_id: Uuid) -> Result<Vec<Question>, AppError> {
        // Vérifier que le quiz existe
        QuizRepository::find_by_id(pool, quiz_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", quiz_id)))?;

        let questions = QuestionRepository::find_by_quiz_id(pool, quiz_id).await?;
        Ok(questions)
    }

    pub async fn get_by_id(pool: &PgPool, id: Uuid) -> Result<Question, AppError> {
        QuestionRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", id)))
    }

    pub async fn create(pool: &PgPool, request: CreateQuestionRequest) -> Result<Question, AppError> {
        // Vérifier que le quiz existe
        QuizRepository::find_by_id(pool, request.quiz_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", request.quiz_id)))?;

        // Validation métier
        if request.points <= 0 {
            return Err(AppError::BadRequest("Les points doivent être supérieurs à 0".to_string()));
        }

        let question = QuestionRepository::create(
            pool,
            request.quiz_id,
            request.ordre,
            &request.type_question,
            &request.question_data,
            request.region_cible_id,
            request.points,
            request.temps_limite_sec,
            request.hint.as_deref(),
            request.explanation.as_deref(),
        )
            .await?;

        Ok(question)
    }

    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        request: CreateQuestionRequest,
    ) -> Result<Question, AppError> {
        let question = QuestionRepository::update(
            pool,
            id,
            request.ordre,
            &request.type_question,
            &request.question_data,
            request.region_cible_id,
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
        let rows_affected = QuestionRepository::delete(pool, id).await?;
        if rows_affected == 0 {
            return Err(AppError::NotFound(format!("Question with id {} not found", id)));
        }
        Ok(())
    }
}