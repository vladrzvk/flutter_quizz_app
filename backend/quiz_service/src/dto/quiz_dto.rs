use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct CreateQuizRequest {
    pub titre: String,
    pub description: Option<String>,
    pub niveau_difficulte: String,
    pub version_app: String,
    pub region_scope: String,
    pub mode: String,
    pub nb_questions: i32,
}