use crate::models::{ReponseUtilisateur, SessionQuiz};
use sqlx::PgPool;
use uuid::Uuid;

pub struct SessionRepository;

impl SessionRepository {
    pub async fn create(
        pool: &PgPool,
        user_id: Uuid,
        quiz_id: Uuid,
        score_max: i32,
    ) -> Result<SessionQuiz, sqlx::Error> {
        sqlx::query_as::<_, SessionQuiz>(
            r#"
            INSERT INTO sessions_quiz (user_id, quiz_id, score_max, date_debut)
            VALUES ($1, $2, $3, NOW())
            RETURNING *
            "#,
        )
        .bind(user_id)
        .bind(quiz_id)
        .bind(score_max)
        .fetch_one(pool)
        .await
    }

    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<SessionQuiz>, sqlx::Error> {
        sqlx::query_as::<_, SessionQuiz>("SELECT * FROM sessions_quiz WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await
    }

    pub async fn find_active_by_id(
        pool: &PgPool,
        id: Uuid,
    ) -> Result<Option<SessionQuiz>, sqlx::Error> {
        sqlx::query_as::<_, SessionQuiz>(
            "SELECT * FROM sessions_quiz WHERE id = $1 AND status = 'en_cours'",
        )
        .bind(id)
        .fetch_optional(pool)
        .await
    }

    pub async fn update_score(
        pool: &PgPool,
        session_id: Uuid,
        points: i32,
    ) -> Result<(), sqlx::Error> {
        sqlx::query("UPDATE sessions_quiz SET score = score + $1 WHERE id = $2")
            .bind(points)
            .bind(session_id)
            .execute(pool)
            .await?;
        Ok(())
    }

    pub async fn finalize(
        pool: &PgPool,
        session_id: Uuid,
    ) -> Result<Option<SessionQuiz>, sqlx::Error> {
        sqlx::query_as::<_, SessionQuiz>(
            r#"
            UPDATE sessions_quiz
            SET status = 'termine',
                date_fin = NOW(),
                temps_total_sec = EXTRACT(EPOCH FROM (NOW() - date_debut))::INTEGER
            WHERE id = $1 AND status = 'en_cours'
            RETURNING *
            "#,
        )
        .bind(session_id)
        .fetch_optional(pool)
        .await
    }

    pub async fn create_user_answer(
        pool: &PgPool,
        session_id: Uuid,
        question_id: Uuid,
        reponse_id: Option<Uuid>,
        valeur_saisie: Option<&str>,
        is_correct: bool,
        points_obtenus: i32,
        temps_reponse_sec: i32,
    ) -> Result<ReponseUtilisateur, sqlx::Error> {
        sqlx::query_as::<_, ReponseUtilisateur>(
            r#"
            INSERT INTO reponses_utilisateur (
                session_id, question_id, reponse_id, valeur_saisie,
                is_correct, points_obtenus, temps_reponse_sec
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *
            "#,
        )
        .bind(session_id)
        .bind(question_id)
        .bind(reponse_id)
        .bind(valeur_saisie)
        .bind(is_correct)
        .bind(points_obtenus)
        .bind(temps_reponse_sec)
        .fetch_one(pool)
        .await
    }

    pub async fn calculate_max_score(pool: &PgPool, quiz_id: Uuid) -> Result<i32, sqlx::Error> {
        let score_max_i64: i64 = sqlx::query_scalar(
            "SELECT COALESCE(SUM(points)::BIGINT, 0) FROM questions WHERE quiz_id = $1",
        )
        .bind(quiz_id)
        .fetch_one(pool)
        .await?;
        Ok(score_max_i64 as i32)
    }

    /// ✅ AJOUTER : Récupérer toutes les réponses d'une session (ordre chronologique)
    pub async fn find_reponses_by_session(
        pool: &PgPool,
        session_id: Uuid,
    ) -> Result<Vec<ReponseUtilisateur>, sqlx::Error> {
        sqlx::query_as::<_, ReponseUtilisateur>(
            "SELECT * FROM reponses_utilisateur WHERE session_id = $1 ORDER BY created_at ASC",
        )
        .bind(session_id)
        .fetch_all(pool)
        .await
    }
}
