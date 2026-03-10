use thiserror::Error;

pub type MlResult<T> = Result<T, MlError>;

#[derive(Debug, Error)]
pub enum MlError {
    #[error("invalid request: {0}")]
    InvalidRequest(String),
    #[error("decode error: {0}")]
    Decode(String),
    #[error("preprocess error: {0}")]
    Preprocess(String),
    #[error("onnx runtime error: {0}")]
    Ort(String),
    #[error("postprocess error: {0}")]
    Postprocess(String),
    #[error("runtime error: {0}")]
    Runtime(String),
}

impl From<ort::Error> for MlError {
    fn from(value: ort::Error) -> Self {
        MlError::Ort(value.to_string())
    }
}

impl From<image::ImageError> for MlError {
    fn from(value: image::ImageError) -> Self {
        MlError::Decode(value.to_string())
    }
}
