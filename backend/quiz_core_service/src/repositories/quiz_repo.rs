use sqlx::PgPool;
use uuid::Uuid;

use crate::models::Quiz;

pub struct QuizRepository;

impl QuizRepository {
    /// Trouver tous les quiz actifs
    pub async fn find_all_active(pool: &PgPool) -> Result<Vec<Quiz>, sqlx::Error> {
        sqlx::query_as::<_, Quiz>(
            "SELECT * FROM quizzes WHERE is_active = true ORDER BY created_at DESC"
        )
            .fetch_all(pool)
            .await
    }

    /// Trouver un quiz par ID
    pub async fn find_by_id(pool: &PgPool, id: Uuid) -> Result<Option<Quiz>, sqlx::Error> {
        sqlx::query_as::<_, Quiz>("SELECT * FROM quizzes WHERE id = $1")
            .bind(id)
            .fetch_optional(pool)
            .await
    }

    /// 🆕 Créer un quiz avec domain
    pub async fn create(
        pool: &PgPool,
        domain: &str,                    // 🆕 NOUVEAU
        titre: &str,
        description: Option<&str>,
        niveau_difficulte: &str,
        version_app: &str,
        scope: &str,                     // 🆕 RENOMMÉ
        mode: &str,
        nb_questions: i32,
    ) -> Result<Quiz, sqlx::Error> {
        sqlx::query_as::<_, Quiz>(
            r#"
            INSERT INTO quizzes (
                domain, titre, description, niveau_difficulte,
                version_app, scope, mode, nb_questions
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *
            "#
        )
            .bind(domain)
            .bind(titre)
            .bind(description)
            .bind(niveau_difficulte)
            .bind(version_app)
            .bind(scope)
            .bind(mode)
            .bind(nb_questions)
            .fetch_one(pool)
            .await
    }

    /// 🆕 Trouver tous les quiz d'un domaine
    pub async fn find_by_domain(
        pool: &PgPool,
        domain: &str,
    ) -> Result<Vec<Quiz>, sqlx::Error> {
        sqlx::query_as::<_, Quiz>(
            "SELECT * FROM quizzes WHERE domain = $1 AND is_active = true ORDER BY created_at DESC"
        )
            .bind(domain)
            .fetch_all(pool)
            .await
    }

    /// 🆕 Compter les quiz par domaine
    pub async fn count_by_domain(
        pool: &PgPool,
        domain: &str,
    ) -> Result<i64, sqlx::Error> {
        sqlx::query_scalar("SELECT COUNT(*) FROM quizzes WHERE domain = $1")
            .bind(domain)
            .fetch_one(pool)
            .await
    }
}