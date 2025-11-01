use async_trait::async_trait;
use shared::AppError;
use sqlx::PgPool;

use crate::{
    dto::session_dto::SubmitAnswerRequest,
    models::Question,
    plugins::{QuizPlugin, ValidationResult},
};

/// Plugin pour le domaine Géographie
pub struct GeographyPlugin;

#[async_trait]
impl QuizPlugin for GeographyPlugin {
    fn domain_name(&self) -> &str {
        "geography"
    }

    fn display_name(&self) -> &str {
        "Géographie"
    }

    fn description(&self) -> &str {
        "Quiz sur la géographie : fleuves, reliefs, pays, régions, capitales"
    }

    /// Validation des réponses géographiques
    async fn validate_answer(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        // La validation ne dépend PAS de la catégorie
        // On utilise juste le type de question
        match question.type_question.as_str() {
            "qcm" => self.validate_qcm(pool, question, answer).await,
            "vrai_faux" => self.validate_vrai_faux(pool, question, answer).await,
            "saisie_texte" => self.validate_saisie_texte_geo(pool, question, answer).await,

            // V1 : Carte cliquable (pas encore implémenté)
            "carte_cliquable" => {
                Err(AppError::BadRequest(
                    "Type 'carte_cliquable' pas encore implémenté (prévu V1)".to_string()
                ))
            }

            _ => {
                Err(AppError::BadRequest(
                    format!("Type de question '{}' non supporté pour la géographie", question.type_question)
                ))
            }
        }
    }

    /// Calcul du score avec bonus géographiques
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

        // Score partiel (pour questions complexes futures)
        if let Some(partial) = validation.partial_score {
            points *= partial;
        }

        // Bonus vitesse
        if let Some(limit) = time_limit {
            let ratio = time_spent as f32 / limit as f32;
            if ratio < 0.3 {
                points *= 1.5; // +50% si très rapide (< 30% du temps)
            } else if ratio < 0.5 {
                points *= 1.25; // +25% si rapide (< 50% du temps)
            } else if ratio > 0.9 {
                points *= 0.75; // -25% si trop lent (> 90% du temps)
            }
        }

        // Bonus streak (série de bonnes réponses)
        if streak_count >= 3 {
            let streak_bonus = ((streak_count - 2) * 10).min(50) as f32 / 100.0;
            points += base_points as f32 * streak_bonus;
        }

        points.round() as i32
    }

    /// Badge de vitesse personnalisé pour la géo
    fn speed_badge(&self, time_spent: i32, time_limit: Option<i32>) -> Option<String> {
        time_limit.and_then(|limit| {
            let ratio = time_spent as f32 / limit as f32;
            if ratio < 0.3 {
                Some("🌍 Expert géographe !".to_string())
            } else if ratio < 0.5 {
                Some("🗺️ Bon navigateur !".to_string())
            } else if ratio > 0.9 {
                Some("🐌 Prends ton temps pour explorer".to_string())
            } else {
                None
            }
        })
    }

    /// Seed des données géographiques (on le fera plus tard)
    async fn seed_data(&self, _pool: &PgPool) -> Result<(), AppError> {
        tracing::info!("🌍 Geography plugin: seed data will be done via SQL script");
        Ok(())
    }
}

// Méthodes privées spécifiques à la géographie
impl GeographyPlugin {
    /// Validation saisie texte avec variations acceptées et normalisation
    /// Ex: "Paris", "paris", "PARIS" sont toutes acceptées
    async fn validate_saisie_texte_geo(
        &self,
        pool: &PgPool,
        question: &Question,
        answer: &SubmitAnswerRequest,
    ) -> Result<ValidationResult, AppError> {
        let valeur_saisie = answer
            .valeur_saisie
            .as_ref()
            .ok_or_else(|| AppError::BadRequest("valeur_saisie requise".to_string()))?;

        // Normaliser la saisie : lowercase + trim
        let normalized = valeur_saisie.trim().to_lowercase();

        // Chercher toutes les réponses correctes (peut y avoir des variantes)
        let correct_answers: Vec<String> = sqlx::query_scalar(
            r#"
            SELECT LOWER(valeur)
            FROM reponses
            WHERE question_id = $1
            AND is_correct = true
            AND valeur IS NOT NULL
            "#,
        )
            .bind(question.id)
            .fetch_all(pool)
            .await?;

        // Vérifier si la réponse normalisée correspond à l'une des variantes
        let is_correct = correct_answers.iter().any(|answer| answer == &normalized);

        if is_correct {
            Ok(ValidationResult::correct("Bonne réponse !")
                .with_explanation(
                    question.explanation.clone().unwrap_or_default()
                ))
        } else {
            // Récupérer la bonne réponse pour l'afficher
            let correct = correct_answers.first().cloned().unwrap_or_default();
            Ok(ValidationResult::incorrect(
                format!("Mauvaise réponse. La bonne réponse était : {}", correct)
            )
                .with_explanation(
                    question.explanation.clone().unwrap_or_default()
                ))
        }
    }
}