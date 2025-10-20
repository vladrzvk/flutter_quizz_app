use axum::{
    routing::{delete, get, post, put},
    Router,
};
use sqlx::PgPool;

use crate::handlers::*;

pub fn create_router(pool: PgPool) -> Router {
    Router::new()
        .route("/health", get(health_handler))

        // ============= QUIZ ROUTES =============
        .route("/api/v1/quizzes",
               get(get_quizzes_handler)
                   .post(create_quiz_handler)
        )
        .route("/api/v1/quizzes/:id", get(get_quiz_by_id_handler))

        // ============= QUESTION ROUTES =============
        .route("/api/v1/quizzes/:quiz_id/questions", get(get_quiz_questions_handler))
        .route("/api/v1/questions", post(create_question_handler))
        .route("/api/v1/questions/:id",
               get(get_question_by_id_handler)
                   .put(update_question_handler)
                   .delete(delete_question_handler)
        )

        // ============= REPONSE ROUTES =============
        .route("/api/v1/questions/:question_id/reponses", get(get_question_reponses_handler))
        .route("/api/v1/questions/:question_id/reponses/bulk", post(create_bulk_reponses_handler))
        .route("/api/v1/reponses", post(create_reponse_handler))
        .route("/api/v1/reponses/:id",
               get(get_reponse_by_id_handler)
                   .put(update_reponse_handler)
                   .delete(delete_reponse_handler)
        )

        // ============= SESSION ROUTES =============
        .route("/api/v1/quizzes/:quiz_id/sessions", post(start_session_handler))
        .route("/api/v1/sessions/:session_id", get(get_session_handler))
        .route("/api/v1/sessions/:session_id/answers", post(submit_answer_handler))
        .route("/api/v1/sessions/:session_id/finalize", post(finalize_session_handler))

        .with_state(pool)
}