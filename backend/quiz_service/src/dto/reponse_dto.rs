use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Request pour créer une réponse
#[derive(Debug, Deserialize)]
pub struct CreateReponseRequest {
    pub question_id: Uuid,
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: i32,
    pub tolerance_meters: Option<i32>,
}

/// Request pour mettre à jour une réponse
#[derive(Debug, Deserialize)]
pub struct UpdateReponseRequest {
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: i32,
    pub tolerance_meters: Option<i32>,
}

/// Response pour une réponse (utilisé pour les listes)
#[derive(Debug, Serialize)]
pub struct ReponseResponse {
    pub id: Uuid,
    pub question_id: Uuid,
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: i32,
    pub tolerance_meters: Option<i32>,
}

/// Response pour une réponse (sans révéler si elle est correcte - pour les quiz)
#[derive(Debug, Serialize)]
pub struct ReponsePublicResponse {
    pub id: Uuid,
    pub valeur: Option<String>,
    pub ordre: i32,
}