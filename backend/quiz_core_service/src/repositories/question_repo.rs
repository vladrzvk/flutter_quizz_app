use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{Question, Reponse};

pub struct QuestionRepository;

impl QuestionRepository {
    pub async fn find_by_quiz_id(
        pool: &PgPool,
        quiz_id: Uuid,
    ) -> Result<Vec<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            "SELECT * FROM questions WHERE quiz_id = $1 ORDER BY ordre ASC",
        )
        .bind(quiz_id)
        .fetch_all(pool)
        .await
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>("SELECT * FROM questions WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await
    }

    /// ✅ Créer une question (AVEC category et subcategory)
    pub async fn create(
        pool: &PgPool,
        quiz_id: Uuid,
        ordre: i32,
        type_question: &str,
        question_data: &serde_json::Value,
        media_url: Option<&str>,
        target_id: Option<Uuid>,
        category: Option<&str>,    // ✅ NOUVEAU
        subcategory: Option<&str>, // ✅ NOUVEAU
        points: i32,
        temps_limite_sec: Option<i32>,
        hint: Option<&str>,
        explanation: Option<&str>,
    ) -> Result<Question, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            r#"
            INSERT INTO questions (
                quiz_id, ordre, type_question, question_data,
                media_url, target_id, category, subcategory,
                points, temps_limite_sec, hint, explanation
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
            RETURNING *
            "#,
        )
        .bind(quiz_id)
        .bind(ordre)
        .bind(type_question)
        .bind(question_data)
        .bind(media_url)
        .bind(target_id)
        .bind(category) // ✅ NOUVEAU
        .bind(subcategory) // ✅ NOUVEAU
        .bind(points)
        .bind(temps_limite_sec)
        .bind(hint)
        .bind(explanation)
        .fetch_one(pool)
        .await
    }

    /// ✅ Mettre à jour une question
    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        type_question: &str,
        question_data: &serde_json::Value,
        media_url: Option<&str>,
        target_id: Option<Uuid>,
        category: Option<&str>,    // ✅ NOUVEAU
        subcategory: Option<&str>, // ✅ NOUVEAU
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
                category = $6,
                subcategory = $7,
                points = $8,
                temps_limite_sec = $9,
                hint = $10,
                explanation = $11,
                updated_at = NOW()
            WHERE id = $1
            RETURNING *
            "#,
        )
        .bind(id)
        .bind(type_question)
        .bind(question_data)
        .bind(media_url)
        .bind(target_id)
        .bind(category) // ✅ NOUVEAU
        .bind(subcategory) // ✅ NOUVEAU
        .bind(points)
        .bind(temps_limite_sec)
        .bind(hint)
        .bind(explanation)
        .fetch_optional(pool)
        .await
    }

    /// ✅ Filtrer questions par catégorie (NOUVEAU)
    pub async fn find_by_category(
        pool: &PgPool,
        quiz_id: Uuid,
        category: &str,
    ) -> Result<Vec<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            "SELECT * FROM questions WHERE quiz_id = $1 AND category = $2 ORDER BY ordre ASC",
        )
        .bind(quiz_id)
        .bind(category)
        .fetch_all(pool)
        .await
    }

    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<(), sqlx::Error> {
        sqlx::query("DELETE FROM questions WHERE id = $1")
            .bind(id)
            .execute(pool)
            .await?;
        Ok(())
    }

    /// ✅ NOUVEAU : Récupérer questions avec leurs réponses
    pub async fn find_by_quiz_id_with_reponses(
        pool: &PgPool,
        quiz_id: Uuid,
    ) -> Result<Vec<(Question, Vec<Reponse>)>, sqlx::Error> {
        // 1. Récupérer toutes les questions
        let questions = Self::find_by_quiz_id(pool, quiz_id).await?;

        // 2. Pour chaque question, récupérer ses réponses
        let mut result = Vec::new();
        for question in questions {
            let reponses = sqlx::query_as::<_, Reponse>(
                "SELECT * FROM reponses WHERE question_id = $1 ORDER BY ordre ASC",
            )
            .bind(question.id)
            .fetch_all(pool)
            .await?;

            result.push((question, reponses));
        }

        Ok(result)
    }
}
