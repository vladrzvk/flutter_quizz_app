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

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Question {
    pub id: Uuid,
    pub quiz_id: Uuid,
    pub ordre: i32,
    pub type_question: String,
    pub question_data: serde_json::Value,
    pub region_cible_id: Option<Uuid>,
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

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct SessionQuiz {
    pub id: Uuid,
    pub user_id: Uuid,
    pub quiz_id: Uuid,
    pub score: i32,
    pub score_max: i32,
    pub pourcentage: Option<f64>,
    pub temps_total_sec: Option<i32>,
    pub date_debut: DateTime<Utc>,
    pub date_fin: Option<DateTime<Utc>>,
    pub status: String,
    pub reponses_detaillees: serde_json::Value,
    pub metadata: serde_json::Value,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ReponseUtilisateur {
    pub id: Uuid,
    pub session_id: Uuid,
    pub question_id: Uuid,
    pub reponse_id: Option<Uuid>,
    pub valeur_saisie: Option<String>,
    pub is_correct: bool,
    pub points_obtenus: i32,
    pub temps_reponse_sec: i32,
    pub metadata: serde_json::Value,
    pub created_at: DateTime<Utc>,
}