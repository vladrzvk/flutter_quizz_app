use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateQuestionRequest {
    pub quiz_id: Uuid,
    pub ordre: i32,
    pub type_question: String,
    pub question_data: serde_json::Value,
    pub region_cible_id: Option<Uuid>,
    pub points: i32,
    pub temps_limite_sec: Option<i32>,
    pub hint: Option<String>,
    pub explanation: Option<String>,
}