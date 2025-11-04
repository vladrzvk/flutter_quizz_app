use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use uuid::Uuid;

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
