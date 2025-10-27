use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct StartSessionRequest {
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct SubmitAnswerRequest {
    pub question_id: Uuid,
    pub reponse_id: Option<Uuid>,
    pub valeur_saisie: Option<String>,
    pub temps_reponse_sec: i32,
}