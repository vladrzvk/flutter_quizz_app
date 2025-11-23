use crate::models::Reponse;
use sqlx::PgPool;
use uuid::Uuid;

pub struct ReponseRepository;

impl ReponseRepository {
    /// Récupérer toutes les réponses d'une question
    pub async fn find_by_question_id(
        pool: &PgPool,
        question_id: Uuid,
    ) -> Result<Vec<Reponse>, sqlx::Error> {
        sqlx::query_as::<_, Reponse>(
            "SELECT * FROM reponses WHERE question_id = $1 ORDER BY ordre ASC",
        )
        .bind(question_id)
        .fetch_all(pool)
        .await
    }

    /// Récupérer une réponse par ID
    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Reponse>, sqlx::Error> {
        sqlx::query_as::<_, Reponse>("SELECT * FROM reponses WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await
    }

    /// Vérifier si une réponse est correcte par ID
    pub async fn is_correct(pool: &PgPool, id: Uuid) -> Result<bool, sqlx::Error> {
        let is_correct: bool = sqlx::query_scalar("SELECT is_correct FROM reponses WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await?
            .unwrap_or(false);
        Ok(is_correct)
    }

    /// Vérifier si une valeur textuelle est correcte pour une question
    pub async fn check_answer_by_value(
        pool: &PgPool,
        question_id: Uuid,
        valeur: &str,
    ) -> Result<bool, sqlx::Error> {
        sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM reponses WHERE question_id = $1 AND valeur = $2 AND is_correct = true)"
        )
            .bind(question_id)
            .bind(valeur)
            .fetch_one(pool)
            .await
    }

    /// Créer une nouvelle réponse
    pub async fn create(
        pool: &PgPool,
        question_id: Uuid,
        valeur: Option<&str>,
        region_id: Option<Uuid>,
        is_correct: bool,
        ordre: Option<i32>,
        tolerance_meters: Option<i32>,
    ) -> Result<Reponse, sqlx::Error> {
        sqlx::query_as::<_, Reponse>(
            r#"
            INSERT INTO reponses (question_id, valeur, region_id, is_correct, ordre, tolerance_meters)
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
            "#
        )
            .bind(question_id)
            .bind(valeur)
            .bind(region_id)
            .bind(is_correct)
            .bind(ordre)
            .bind(tolerance_meters)
            .fetch_one(pool)
            .await
    }

    /// Mettre à jour une réponse
    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        valeur: Option<&str>,
        region_id: Option<Uuid>,
        is_correct: bool,
        ordre: Option<i32>,
        tolerance_meters: Option<i32>,
    ) -> Result<Option<Reponse>, sqlx::Error> {
        sqlx::query_as::<_, Reponse>(
            r#"
            UPDATE reponses
            SET valeur = $2, region_id = $3, is_correct = $4, ordre = $5, tolerance_meters = $6
            WHERE id = $1
            RETURNING *
            "#,
        )
        .bind(id)
        .bind(valeur)
        .bind(region_id)
        .bind(is_correct)
        .bind(ordre)
        .bind(tolerance_meters)
        .fetch_optional(pool)
        .await
    }

    /// Supprimer une réponse
    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<u64, sqlx::Error> {
        let result = sqlx::query("DELETE FROM reponses WHERE id = $1")
            .bind(id)
            .execute(pool)
            .await?;
        Ok(result.rows_affected())
    }

    /// Compter le nombre de réponses pour une question
    pub async fn count_by_question(pool: &PgPool, question_id: Uuid) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar("SELECT COUNT(*) FROM reponses WHERE question_id = $1")
            .bind(question_id)
            .fetch_one(pool)
            .await
    }
}
