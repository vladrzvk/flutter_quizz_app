use sqlx::PgPool;
use uuid::Uuid;
use crate::models::Question;

pub struct QuestionRepository;

impl QuestionRepository {
    pub async fn find_by_quiz_id(pool: &PgPool, quiz_id: Uuid) -> Result<Vec<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            "SELECT * FROM questions WHERE quiz_id = $1 ORDER BY ordre ASC"
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

    pub async fn create(
        pool: &PgPool,
        quiz_id: Uuid,
        ordre: i32,
        type_question: &str,
        question_data: &serde_json::Value,
        region_cible_id: Option<Uuid>,
        points: i32,
        temps_limite_sec: Option<i32>,
        hint: Option<&str>,
        explanation: Option<&str>,
    ) -> Result<Question, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            r#"
            INSERT INTO questions (
                quiz_id, ordre, type_question, question_data,
                region_cible_id, points, temps_limite_sec, hint, explanation
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            RETURNING *
            "#
        )
            .bind(quiz_id)
            .bind(ordre)
            .bind(type_question)
            .bind(question_data)
            .bind(region_cible_id)
            .bind(points)
            .bind(temps_limite_sec)
            .bind(hint)
            .bind(explanation)
            .fetch_one(pool)
            .await
    }

    pub async fn update(
        pool: &PgPool,
        id: Uuid,
        ordre: i32,
        type_question: &str,
        question_data: &serde_json::Value,
        region_cible_id: Option<Uuid>,
        points: i32,
        temps_limite_sec: Option<i32>,
        hint: Option<&str>,
        explanation: Option<&str>,
    ) -> Result<Option<Question>, sqlx::Error> {
        sqlx::query_as::<_, Question>(
            r#"
            UPDATE questions
            SET ordre = $2, type_question = $3, question_data = $4,
                region_cible_id = $5, points = $6, temps_limite_sec = $7,
                hint = $8, explanation = $9, updated_at = NOW()
            WHERE id = $1
            RETURNING *
            "#
        )
            .bind(id)
            .bind(ordre)
            .bind(type_question)
            .bind(question_data)
            .bind(region_cible_id)
            .bind(points)
            .bind(temps_limite_sec)
            .bind(hint)
            .bind(explanation)
            .fetch_optional(pool)
            .await
    }

    pub async fn delete(pool: &PgPool, id: Uuid) -> Result<u64, sqlx::Error> {
        let result = sqlx::query("DELETE FROM questions WHERE id = $1")
            .bind(id)
            .execute(pool)
            .await?;
        Ok(result.rows_affected())
    }
}