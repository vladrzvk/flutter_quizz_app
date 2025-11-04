use crate::{
    dto::{StartSessionRequest, SubmitAnswerRequest},
    models::{ReponseUtilisateur, SessionQuiz},
    plugins::PluginRegistry, // ✅ AJOUTER
    repositories::{QuestionRepository, QuizRepository, ReponseRepository, SessionRepository},
};
use shared::AppError;
use sqlx::PgPool;
use std::sync::Arc;
use uuid::Uuid;

pub struct SessionService;

impl SessionService {
    // ✅ INCHANGÉ
    pub async fn start_session(
        pool: &PgPool,
        quiz_id: Uuid,
        request: StartSessionRequest,
    ) -> Result<SessionQuiz, AppError> {
        // Vérifier que le quiz existe et est actif
        let quiz = QuizRepository::find_by_id(pool, quiz_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Quiz with id {} not found", quiz_id)))?;

        if !quiz.is_active {
            return Err(AppError::BadRequest("Ce quiz n'est plus actif".to_string()));
        }

        // Calculer le score maximum
        let score_max = SessionRepository::calculate_max_score(pool, quiz_id).await?;

        // Créer la session
        let session = SessionRepository::create(pool, request.user_id, quiz_id, score_max).await?;

        Ok(session)
    }

    // ✅ INCHANGÉ
    pub async fn get_session(pool: &PgPool, session_id: Uuid) -> Result<SessionQuiz, AppError> {
        SessionRepository::find_by_id(pool, session_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Session with id {} not found", session_id)))
    }

    // ✅ MODIFIÉ : Ajouter plugin_registry
    pub async fn submit_answer(
        pool: &PgPool,
        plugin_registry: &PluginRegistry, // ✅ NOUVEAU PARAMÈTRE
        session_id: Uuid,
        request: SubmitAnswerRequest,
    ) -> Result<ReponseUtilisateur, AppError> {
        // Vérifier que la session existe et est en cours
        let session = SessionRepository::find_active_by_id(pool, session_id)
            .await?
            .ok_or_else(|| {
                AppError::BadRequest("Session not found or already completed".to_string())
            })?;

        // Récupérer la question
        let question = QuestionRepository::find_by_id(pool, request.question_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        // Vérifier que la question appartient au quiz de la session
        if question.quiz_id != session.quiz_id {
            return Err(AppError::BadRequest(
                "Question does not belong to this quiz".to_string(),
            ));
        }

        // ✅ NOUVEAU : Récupérer le quiz pour le domaine
        let quiz = QuizRepository::find_by_id(pool, session.quiz_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Quiz not found".to_string()))?;

        // ✅ NOUVEAU : Utiliser le plugin pour valider
        let plugin = plugin_registry.get(&quiz.domain).ok_or_else(|| {
            AppError::NotFound(format!("No plugin found for domain: {}", quiz.domain))
        })?;

        let validation = plugin.validate_answer(pool, &question, &request).await?;

        tracing::debug!(
            question_id = %request.question_id,
            is_correct = validation.is_correct,
            "Answer validated by plugin"
        );

        // ✅ NOUVEAU : Calculer le streak
        let streak_count = Self::calculate_streak(pool, session_id).await?;

        // ✅ NOUVEAU : Calculer le score avec le plugin
        let points_obtenus = if validation.is_correct {
            plugin.calculate_score(
                question.points,
                &validation,
                request.temps_reponse_sec,
                question.temps_limite_sec,
                streak_count,
            )
        } else {
            0
        };

        tracing::debug!(
            base_points = question.points,
            final_points = points_obtenus,
            streak = streak_count,
            "Score calculated"
        );

        // Enregistrer la réponse utilisateur
        let reponse_user = SessionRepository::create_user_answer(
            pool,
            session_id,
            request.question_id,
            request.reponse_id,
            request.valeur_saisie.as_deref(),
            validation.is_correct, // ✅ Utiliser validation du plugin
            points_obtenus,
            request.temps_reponse_sec,
        )
        .await?;

        // Mettre à jour le score de la session
        SessionRepository::update_score(pool, session_id, points_obtenus).await?;

        Ok(reponse_user)
    }

    // ✅ INCHANGÉ
    pub async fn finalize_session(
        pool: &PgPool,
        session_id: Uuid,
    ) -> Result<SessionQuiz, AppError> {
        SessionRepository::finalize(pool, session_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Session not found or already finalized".to_string()))
    }

    // ✅ NOUVEAU : Calculer le streak
    async fn calculate_streak(pool: &PgPool, session_id: Uuid) -> Result<i32, AppError> {
        let reponses = SessionRepository::find_reponses_by_session(pool, session_id).await?;

        // Compter les bonnes réponses consécutives depuis la fin
        let mut streak = 0;
        for reponse in reponses.iter().rev() {
            if reponse.is_correct {
                streak += 1;
            } else {
                break;
            }
        }

        Ok(streak)
    }
}
