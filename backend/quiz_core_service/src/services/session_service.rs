use sqlx::PgPool;
use uuid::Uuid;
use shared::AppError;
use crate::{
    dto::{StartSessionRequest, SubmitAnswerRequest},
    models::{SessionQuiz, ReponseUtilisateur},
    repositories::{SessionRepository, QuizRepository, QuestionRepository, ReponseRepository},
};

pub struct SessionService;

impl SessionService {
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

    pub async fn get_session(pool: &PgPool, session_id: Uuid) -> Result<SessionQuiz, AppError> {
        SessionRepository::find_by_id(pool, session_id)
            .await?
            .ok_or_else(|| AppError::NotFound(format!("Session with id {} not found", session_id)))
    }

    pub async fn submit_answer(
        pool: &PgPool,
        session_id: Uuid,
        request: SubmitAnswerRequest,
    ) -> Result<ReponseUtilisateur, AppError> {
        // Vérifier que la session existe et est en cours
        let session = SessionRepository::find_active_by_id(pool, session_id)
            .await?
            .ok_or_else(|| AppError::BadRequest("Session not found or already completed".to_string()))?;

        // Récupérer la question
        let question = QuestionRepository::find_by_id(pool, request.question_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Question not found".to_string()))?;

        // Vérifier que la question appartient au quiz de la session
        if question.quiz_id != session.quiz_id {
            return Err(AppError::BadRequest("Question does not belong to this quiz".to_string()));
        }

        // Déterminer si la réponse est correcte
        let is_correct = if let Some(reponse_id) = request.reponse_id {
            ReponseRepository::is_correct(pool, reponse_id).await?
        } else if let Some(ref valeur) = request.valeur_saisie {
            ReponseRepository::check_answer_by_value(pool, request.question_id, valeur).await?
        } else {
            false
        };

        let points_obtenus = if is_correct { question.points } else { 0 };

        // Enregistrer la réponse utilisateur
        let reponse_user = SessionRepository::create_user_answer(
            pool,
            session_id,
            request.question_id,
            request.reponse_id,
            request.valeur_saisie.as_deref(),
            is_correct,
            points_obtenus,
            request.temps_reponse_sec,
        )
            .await?;

        // Mettre à jour le score de la session
        SessionRepository::update_score(pool, session_id, points_obtenus).await?;

        Ok(reponse_user)
    }

    pub async fn finalize_session(pool: &PgPool, session_id: Uuid) -> Result<SessionQuiz, AppError> {
        SessionRepository::finalize(pool, session_id)
            .await?
            .ok_or_else(|| AppError::NotFound("Session not found or already finalized".to_string()))
    }
}