// backend/quiz_core_service/src/dto/reponse_dto.rs

use serde::Deserialize;
use uuid::Uuid;

#[derive(Debug, Deserialize)]
pub struct CreateReponseRequest {
    pub question_id: Uuid,
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: Option<i32>,
    pub tolerance_meters: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateReponseRequest {
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: Option<i32>,
    pub tolerance_meters: Option<i32>,
}

// 🆕 DTO pour création en masse
#[derive(Debug, Deserialize)]
pub struct CreateBulkReponsesRequest {
    pub reponses: Vec<BulkReponseItem>,
}

#[derive(Debug, Deserialize)]
pub struct BulkReponseItem {
    pub valeur: Option<String>,
    pub region_id: Option<Uuid>,
    pub is_correct: bool,
    pub ordre: Option<i32>,
    pub tolerance_meters: Option<i32>,
}