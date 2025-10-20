use sqlx::PgPool;
use uuid::Uuid;
use shared::AppError;
use crate::{
    dto::CreateQuizRequest,
    models::Quiz,
    repositories::QuizRepository,
};

pub struct QuizService;

impl QuizService {
    pub async fn get_all_active(pool: &PgPool) -> Result<Vec<Quiz>, AppError> {
        let quizzes = QuizRepository::find_all(pool).await?;
        Ok(quizzes)
    }

    pub async fn get_by_id(pool: &PgPool, id: Uuid) -> Result<Quiz, AppError> {
        QuizRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", id)))
    }

    pub async fn create(pool: &PgPool, request: CreateQuizRequest) -> Result<Quiz, AppError> {
        // Validation métier
        if request.titre.trim().is_empty() {
            return Err(AppError::BadRequest("Le titre ne peut pas être vide".to_string()));
        }

        if request.nb_questions <= 0 {
            return Err(AppError::BadRequest("Le nombre de questions doit être supérieur à 0".to_string()));
        }

        let quiz = QuizRepository::create(
            pool,
            &request.titre,
            request.description.as_deref(),
            &request.niveau_difficulte,
            &request.version_app,
            &request.region_scope,
            &request.mode,
            request.nb_questions,
        )
            .await?;

        Ok(quiz)
    }
}