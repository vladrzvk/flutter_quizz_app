use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct StartSessionRequest {
    pub user_id: Uuid,
}

#[derive(Debug, Deserialize)]
pub struct SubmitAnswerRequest {
    pub question_id: Uuid,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub reponse_id: Option<Uuid>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub valeur_saisie: Option<String>,
    pub temps_reponse_sec: i32,
}
