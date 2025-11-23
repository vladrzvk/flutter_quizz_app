use axum::{
    http::{StatusCode, header},
    response::{IntoResponse, Response},
};
use serde::Serialize;

/// Wrapper pour forcer UTF-8 dans les réponses JSON
pub struct JsonUtf8<T>(pub T);

impl<T> IntoResponse for JsonUtf8<T>
where
    T: Serialize,
{
    fn into_response(self) -> Response {
        match serde_json::to_vec(&self.0) {
            Ok(bytes) => (
                StatusCode::OK,
                [(header::CONTENT_TYPE, "application/json; charset=utf-8")],
                bytes,
            )
                .into_response(),
            Err(err) => (
                StatusCode::INTERNAL_SERVER_ERROR,
                format!("Failed to serialize: {}", err),
            )
                .into_response(),
        }
    }
}
