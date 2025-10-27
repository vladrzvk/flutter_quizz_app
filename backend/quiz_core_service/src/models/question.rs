use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Question {
    pub id: Uuid,
    pub quiz_id: Uuid,
    pub ordre: i32,
    pub type_question: String,
    pub question_data: serde_json::Value,
    pub media_url: Option<String>,   // 🆕 URL générique (map://, https://)
    pub target_id: Option<Uuid>,     // 🆕 Renommé (générique)
    pub points: i32,
    pub temps_limite_sec: Option<i32>,
    pub hint: Option<String>,
    pub explanation: Option<String>,
    pub metadata: serde_json::Value,
    pub total_attempts: i32,
    pub correct_attempts: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}