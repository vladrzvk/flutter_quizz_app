use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Quiz {
    pub id: Uuid,
    pub titre: String,
    pub description: Option<String>,
    pub niveau_difficulte: String,
    pub version_app: String,
    pub region_scope: String,
    pub mode: String,
    pub collection_id: Option<Uuid>,
    pub nb_questions: i32,
    pub temps_limite_sec: Option<i32>,
    pub score_minimum_success: i32,
    pub is_active: bool,
    pub is_public: bool,
    pub metadata: serde_json::Value,
    pub total_attempts: i32,
    pub average_score: Option<f64>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Option<Uuid>,
}