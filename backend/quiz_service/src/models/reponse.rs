use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Reponse {
    pub id: Uuid,
    pub question_id: Uuid,
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: i32,
    pub tolerance_meters: Option<i32>,
    pub metadata: serde_json::Value,
    pub created_at: DateTime<Utc>,
}