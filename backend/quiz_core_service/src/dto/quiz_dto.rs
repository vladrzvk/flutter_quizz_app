use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct CreateQuizRequest {
    pub domain: String,              // 🆕 "geography", "code_route"
    pub titre: String,
    pub description: Option<String>,
    pub niveau_difficulte: String,
    pub version_app: String,
    pub scope: String,               // 🆕 "europe", "france"
    pub mode: String,
    pub nb_questions: i32,
}