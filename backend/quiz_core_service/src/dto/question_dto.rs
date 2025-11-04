use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateQuestionRequest {
    pub quiz_id: Uuid,
    pub ordre: i32,
    pub type_question: String,
    pub question_data: serde_json::Value,
    pub media_url: Option<String>,   // ✅ NOUVEAU
    pub target_id: Option<Uuid>,     // ✅ NOUVEAU (avant: region_cible_id)
    pub category: Option<String>,        // ✅ NOUVEAU
    pub subcategory: Option<String>,     // ✅ NOUVEAU
    pub points: i32,
    pub temps_limite_sec: Option<i32>,
    pub hint: Option<String>,
    pub explanation: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateQuestionRequest {
    pub type_question: String,
    pub question_data: serde_json::Value,
    pub media_url: Option<String>,   // ✅ NOUVEAU
    pub target_id: Option<Uuid>,     // ✅ NOUVEAU
    pub category: Option<String>,        // ✅ NOUVEAU
    pub subcategory: Option<String>,     // ✅ NOUVEAU
    pub points: i32,
    pub temps_limite_sec: Option<i32>,
    pub hint: Option<String>,
    pub explanation: Option<String>,
}

/// DTO pour Question avec ses réponses incluses
#[derive(Debug, Serialize)]
pub struct QuestionWithReponses {
    pub id: Uuid,
    pub quiz_id: Uuid,
    pub ordre: i32,
    pub category: Option<String>,
    pub subcategory: Option<String>,
    pub type_question: String,
    pub question_data: serde_json::Value,
    pub media_url: Option<String>,
    pub target_id: Option<Uuid>,
    pub points: i32,
    pub temps_limite_sec: Option<i32>,
    pub hint: Option<String>,
    pub explanation: Option<String>,
    pub metadata: serde_json::Value,
    pub total_attempts: i32,
    pub correct_attempts: i32,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    pub reponses: Vec<ReponseDto>,  // ✅ AJOUTÉ
}

/// DTO simplifié pour les réponses (sans exposer is_correct pour QCM)
#[derive(Debug, Serialize)]
pub struct ReponseDto {
    pub id: Uuid,
    pub valeur: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub is_correct: Option<bool>,  // Seulement pour debug, pas pour le client
    pub ordre: i32,
}