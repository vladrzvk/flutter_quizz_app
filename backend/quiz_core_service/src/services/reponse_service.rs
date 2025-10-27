use sqlx::PgPool;
use uuid::Uuid;
use shared::AppError;
use crate::{
    dto::{CreateReponseRequest, UpdateReponseRequest, CreateBulkReponsesRequest,},
    models::Reponse,
    repositories::{ReponseRepository, QuestionRepository},
};

pub struct ReponseService;

impl ReponseService {
    /// Récupérer toutes les réponses d'une question
    pub async fn get_by_question_id(pool: &PgPool, question_id: Uuid) -> Result<Vec<Reponse>, AppError> {
        // Vérifier que la question existe
        QuestionRepository::find_by_id(pool, question_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", question_id)))?;

        let reponses = ReponseRepository::find_by_question_id(pool, question_id).await?;
        Ok(reponses)
    }

    /// Récupérer une réponse par ID
    pub async fn get_by_id(pool: &PgPool, id: Uuid) -> Result<Reponse, AppError> {
        ReponseRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Reponse with id {} not found", id)))
    }

    /// Créer une nouvelle réponse
    pub async fn create(pool: &PgPool, request: CreateReponseRequest) -> Result<Reponse, AppError> {
        // Vérifier que la question existe
        QuestionRepository::find_by_id(pool, request.question_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Question with id {} not found", request.question_id)))?;

        // Validation métier
        if request.ordre < Option::from(0) {
            return Err(AppError::BadRequest("L'ordre doit être positif".to_string()));
        }

        // Vérifier qu'il n'y a pas déjà trop de réponses (max 6 pour un QCM par exemple)
        let count = ReponseRepository::count_by_question(pool, request.question_id).await?;
        if count >= 6 {
            return Err(AppError::BadRequest("Nombre maximum de réponses atteint (6)".to_string()));
        }

        let reponse = ReponseRepository::create(
            pool,
            request.question_id,
            request.valeur.as_deref(),
            request.region_id,
            request.is_correct,
            request.ordre,
            request.tolerance_meters,
        )
            .await?;

        Ok(reponse)
    }

    /// Mettre à jour une réponse
    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        request: UpdateReponseRequest,
    ) -> Result<Reponse, AppError> {
        // Vérifier que la réponse existe
        let _existing = ReponseRepository::find_by_id(pool, id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Reponse with id {} not found", id)))?;

        // Validation métier
        if request.ordre < Option::from(0) {
            return Err(AppError::BadRequest("L'ordre doit être positif".to_string()));
        }

        let reponse = ReponseRepository::update(
            pool,
            id,
            request.valeur.as_deref(),
            request.region_id,
            request.is_correct,
            request.ordre,
            request.tolerance_meters,
        )
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Reponse with id {} not found", id)))?;

        Ok(reponse)
    }

    /// Supprimer une réponse
    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<(), AppError> {
        let rows_affected = ReponseRepository::delete(pool, id).await?;
        if rows_affected == 0 {
            return Err(AppError::NotFound(format!("Reponse with id {} not found", id)));
        }
        Ok(())
    }

    /// Créer plusieurs réponses en une fois (bulk create)
    pub async fn create_bulk(
        pool: &PgPool,
        question_id: Uuid,
        request: CreateBulkReponsesRequest,
    ) -> Result<Vec<Reponse>, AppError> {
        let mut reponses = Vec::new();

        for item in request.reponses {
            let reponse = ReponseRepository::create(
                pool,
                question_id,
                item.valeur.as_deref(),
                item.region_id,
                item.is_correct,
                item.ordre,
                item.tolerance_meters,
            )
                .await?;

            reponses.push(reponse);
        }

        Ok(reponses)
    }


}