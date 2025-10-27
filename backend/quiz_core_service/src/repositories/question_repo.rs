use sqlx::PgPool;
use uuid::Uuid;

use crate::models::Question;

pub struct QuestionRepository;

impl QuestionRepository {
    /// Trouver toutes les questions d'un quiz
    pub async fn find_by_quiz_id(pool: &PgPool, quiz_id: Uuid) -> Result<Vec<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            "SELECT * FROM questions WHERE quiz_id = $1 ORDER BY ordre ASC"
        )
            .bind(quiz_id)
            .fetch_all(pool)
            .await
    }

    /// Trouver une question par ID
    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>("SELECT * FROM questions WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await
    }

    /// ✅ Créer une question (UNE SEULE VERSION - avec media_url et target_id)
    pub async fn create(
        pool: &PgPool,
        quiz_id: Uuid,
        ordre: i32,
        type_question: &str,
        question_data: &serde_json::Value,
        media_url: Option<&str>,        // ✅ NOUVEAU
        target_id: Option<Uuid>,        // ✅ NOUVEAU
        points: i32,
        temps_limite_sec: Option<i32>,
        hint: Option<&str>,
        explanation: Option<&str>,
    ) -> Result<Question, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            r#"
            INSERT INTO questions (
                quiz_id, ordre, type_question, question_data,
                media_url, target_id, points, temps_limite_sec, hint, explanation
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *
            "#
        )
            .bind(quiz_id)
            .bind(ordre)
            .bind(type_question)
            .bind(question_data)
            .bind(media_url)
            .bind(target_id)
            .bind(points)
            .bind(temps_limite_sec)
            .bind(hint)
            .bind(explanation)
            .fetch_one(pool)
            .await
    }

    /// Mettre à jour une question
    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        type_question: &str,
        question_data: &serde_json::Value,
        media_url: Option<&str>,        // ✅ NOUVEAU
        target_id: Option<Uuid>,        // ✅ NOUVEAU
        points: i32,
        temps_limite_sec: Option<i32>,
        hint: Option<&str>,
        explanation: Option<&str>,
    ) -> Result<Option<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            r#"
            UPDATE questions
            SET type_question = $2,
                question_data = $3,
                media_url = $4,
                target_id = $5,
                points = $6,
                temps_limite_sec = $7,
                hint = $8,
                explanation = $9,
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
            "#
        )
            .bind(id)
            .bind(type_question)
            .bind(question_data)
            .bind(media_url)
            .bind(target_id)
            .bind(points)
            .bind(temps_limite_sec)
            .bind(hint)
            .bind(explanation)
            .fetch_optional(pool)
            .await
    }

    /// Supprimer une question
    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<(), sqlx::Error> {
        sqlx::query("DELETE FROM questions WHERE id = $1")
            .bind(id)
            .execute(pool)
            .await?;
        Ok(())
    }
}