use async_trait::async_trait;
use shared::AppError;
use sqlx::PgPool;

use crate::{
    dto::session_dto::SubmitAnswerRequest,
    models::{Question},
};

/// Résultat de validation d'une réponse
#[derive(Debug, Clone)]
pub struct ValidationResult {
    pub is_correct: bool,
    pub feedback_message: String,
    pub explanation: Option<String>,
    pub partial_score: Option<f32>, // Pour ordre/association (0.0 à 1.0)
}

impl ValidationResult {
    pub fn correct(message: impl Into<String>) -> Self {
        Self {
            is_correct: true,
            feedback_message: message.into(),
            explanation: None,
            partial_score: None,
        }
    }

    pub fn incorrect(message: impl Into<String>) -> Self {
        Self {
            is_correct: false,
            feedback_message: message.into(),
            explanation: None,
            partial_score: None,
        }
    }

    pub fn partial(score: f32, message: impl Into<String>) -> Self {
        Self {
            is_correct: score > 0.5,
            feedback_message: message.into(),
            explanation: None,
            partial_score: Some(score),
        }
    }

    pub fn with_explanation(mut self, explanation: impl Into<String>) -> Self {
        self.explanation = Some(explanation.into());
        self
    }
}

/// Trait que chaque plugin de domaine doit implémenter
#[async_trait]
pub trait QuizPlugin: Send + Sync {
    /// Nom du domaine (ex: "geography", "code_route")
    fn domain_name(&self) -> &str;

    /// Nom d'affichage (ex: "Géographie", "Code de la Route")
    fn display_name(&self) -> &str {
        self.domain_name()
    }

    /// Description du domaine
    fn description(&self) -> &str {
        ""
    }

    /// Valider une réponse selon les règles du domaine
    /// Cette méthode est appelée pour chaque type de question
    async fn validate_answer(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError>;

    /// Calculer le score final avec bonifications/pénalités
    /// Implémentation par défaut fournie, peut être override
    fn calculate_score(
        &self,
        base_points: i32,
        validation: &ValidationResult,
        time_spent: i32,
        time_limit: Option<i32>,
        streak_count: i32,
    ) -> i32 {
        if !validation.is_correct && validation.partial_score.is_none() {
            return 0;
        }

        let mut points = base_points as f32;

        // Score partiel (pour ordre/association)
        if let Some(partial) = validation.partial_score {
            points *= partial;
        }

        // Bonus vitesse
        if let Some(limit) = time_limit {
            let ratio = time_spent as f32 / limit as f32;
            if ratio < 0.3 {
                points *= 1.5; // +50% si très rapide
            } else if ratio < 0.5 {
                points *= 1.25; // +25% si rapide
            } else if ratio > 0.9 {
                points *= 0.75; // -25% si trop lent
            }
        }

        // Bonus streak
        if streak_count >= 3 {
            let streak_bonus = ((streak_count - 2) * 10).min(50) as f32 / 100.0;
            points += base_points as f32 * streak_bonus;
        }

        points.round() as i32
    }

    /// Badge de vitesse (optionnel, override si logique spécifique)
    fn speed_badge(&self, time_spent: i32, time_limit: Option<i32>) -> Option<String> {
        time_limit.and_then(|limit| {
            let ratio = time_spent as f32 / limit as f32;
            if ratio < 0.3 {
                Some("⚡ Éclair !".to_string())
            } else if ratio < 0.5 {
                Some("🚀 Rapide !".to_string())
            } else if ratio > 0.9 {
                Some("🐢 Prends ton temps".to_string())
            } else {
                None
            }
        })
    }

    /// Seed initial des données du domaine
    /// Cette méthode est appelée lors du seeding de la DB
    async fn seed_data(&self, _pool: &PgPool) -> Result<(), AppError> {
        tracing::warn!(
            "No seed data implementation for domain: {}",
            self.domain_name()
        );
        Ok(())
    }

    /// Validation spécifique pour le type "qcm" (implémentation par défaut)
    async fn validate_qcm(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        // Validation par défaut : vérifier dans la table reponses
        let reponse_id = answer
            .reponse_id
            .ok_or_else(|| AppError::BadRequest("reponse_id requis pour QCM".to_string()))?;

        let is_correct: bool = sqlx::query_scalar(
            "SELECT is_correct FROM reponses WHERE id = $1 AND question_id = $2",
        )
            .bind(reponse_id)
            .bind(question.id)
            .fetch_optional(pool)
            .await?
            .ok_or_else(|| AppError::NotFound("Réponse non trouvée".to_string()))?;

        if is_correct {
            Ok(ValidationResult::correct("Bonne réponse !")
                .with_explanation(question.explanation.clone().unwrap_or_default()))
        } else {
            Ok(ValidationResult::incorrect("Mauvaise réponse")
                .with_explanation(question.explanation.clone().unwrap_or_default()))
        }
    }

    /// Validation spécifique pour le type "vrai_faux"
    async fn validate_vrai_faux(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        // Réutiliser la validation QCM (même logique)
        self.validate_qcm(pool, question, answer).await
    }

    /// Validation spécifique pour le type "saisie_texte"
    async fn validate_saisie_texte(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        let valeur_saisie = answer
            .valeur_saisie
            .as_ref()
            .ok_or_else(|| AppError::BadRequest("valeur_saisie requise".to_string()))?;

        // Vérifier si la valeur saisie correspond à une réponse correcte
        let is_correct: bool = sqlx::query_scalar(
            r#"
            SELECT EXISTS(
                SELECT 1 FROM reponses
                WHERE question_id = $1
                AND LOWER(valeur) = LOWER($2)
                AND is_correct = true
            )
            "#,
        )
            .bind(question.id)
            .bind(valeur_saisie)
            .fetch_one(pool)
            .await?;

        if is_correct {
            Ok(ValidationResult::correct("Bonne réponse !"))
        } else {
            Ok(ValidationResult::incorrect("Mauvaise réponse"))
        }
    }
}