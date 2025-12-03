use axum::{
    middleware,
    routing::{get, post},
    Router,
};

use crate::{
    handlers::{question_handler::*, quiz_handler::*, reponse_handler::*, session_handler::*},
    middleware::mtls_validation::{log_mtls_connection, validate_mtls_middleware},
    AppState,
};

pub fn create_router(app_state: AppState) -> Router {
    // Créer le router avec toutes les routes
    let router = Router::new()
        .route("/health", get(health_handler))
        // Quiz routes
        .route(
            "/api/v1/quizzes",
            get(get_quizzes_handler).post(create_quiz_handler),
        )
        .route("/api/v1/quizzes/:id", get(get_quiz_by_id_handler))
        // Question routes
        .route(
            "/api/v1/quizzes/:quiz_id/questions",
            get(get_questions_by_quiz_handler),
        )
        .route("/api/v1/questions", post(create_question_handler))
        .route(
            "/api/v1/questions/:id",
            get(get_question_by_id_handler)
                .put(update_question_handler)
                .delete(delete_question_handler),
        )
        // Reponse routes
        .route(
            "/api/v1/questions/:question_id/reponses",
            get(get_question_reponses_handler),
        )
        .route(
            "/api/v1/questions/:question_id/reponses/bulk",
            post(create_bulk_reponses_handler),
        )
        .route("/api/v1/reponses", post(create_reponse_handler))
        .route(
            "/api/v1/reponses/:id",
            get(get_reponse_by_id_handler)
                .put(update_reponse_handler)
                .delete(delete_reponse_handler),
        )
        // Session routes
        .route(
            "/api/v1/quizzes/:quiz_id/sessions",
            post(start_session_handler),
        )
        .route("/api/v1/sessions/:session_id", get(get_session_handler))
        .route(
            "/api/v1/sessions/:session_id/answers",
            post(submit_answer_handler),
        )
        .route(
            "/api/v1/sessions/:session_id/finalize",
            post(finalize_session_handler),
        );

    // 🔐 Ajouter middleware mTLS si activé
    let mtls_enabled = std::env::var("MTLS_ENABLED")
        .unwrap_or_else(|_| "false".to_string())
        .parse::<bool>()
        .unwrap_or(false);

    let router = if mtls_enabled {
        tracing::info!("🔐 Middleware mTLS activé sur toutes les routes API");
        router
            .layer(middleware::from_fn(log_mtls_connection))
            .layer(middleware::from_fn(validate_mtls_middleware))
    } else {
        tracing::debug!("ℹ️  Middleware mTLS désactivé");
        router
    };

    router.with_state(app_state)
}

// Health handler simple
async fn health_handler() -> &'static str {
    "OK"
}