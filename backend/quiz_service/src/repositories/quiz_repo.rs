use sqlx::PgPool;
use uuid::Uuid;
use crate::models::Quiz;

pub struct QuizRepository;

impl QuizRepository {
    pub async fn find_all(pool: &PgPool) -> Result<Vec<Quiz>, sqlx::Error> {
        sqlx::query_as::<_, Quiz>(
            "SELECT * FROM quizzes WHERE is_active = true ORDER BY created_at DESC"
        )
            .fetch_all(pool)
            .await
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Quiz>, sqlx::Error> {
        sqlx::query_as::<_, Quiz>("SELECT * FROM quizzes WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await
    }

    pub async fn create(
        pool: &PgPool,
        titre: &str,
        description: Option<&str>,
        niveau_difficulte: &str,
        version_app: &str,
        region_scope: &str,
        mode: &str,
        nb_questions: i32,
    ) -> Result<Quiz, sqlx::Error> {
        sqlx::query_as::<_, Quiz>(
            r#"
            INSERT INTO quizzes (titre, description, niveau_difficulte, version_app, region_scope, mode, nb_questions)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#
        )
            .bind(titre)
            .bind(description)
            .bind(niveau_difficulte)
            .bind(version_app)
            .bind(region_scope)
            .bind(mode)
            .bind(nb_questions)
            .fetch_one(pool)
            .await
    }

    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        titre: &str,
        description: Option<&str>,
        niveau_difficulte: &str,
    ) -> Result<Quiz, sqlx::Error> {
        sqlx::query_as::<_, Quiz>(
            r#"
            UPDATE quizzes
            SET titre = $2, description = $3, niveau_difficulte = $4, updated_at = NOW()
            WHERE id = $1
            RETURNING *
            "#
        )
            .bind(id)
            .bind(titre)
            .bind(description)
            .bind(niveau_difficulte)
            .fetch_one(pool)
            .await
    }

    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<u64, sqlx::Error> {
        let result = sqlx::query("DELETE FROM quizzes WHERE id = $1")
            .bind(id)
            .execute(pool)
            .await?;
        Ok(result.rows_affected())
    }
}