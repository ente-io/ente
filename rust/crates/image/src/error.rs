use thiserror::Error;

pub type ImageResult<T> = Result<T, ImageError>;

#[derive(Debug, Error)]
pub enum ImageError {
    #[error("decode error: {0}")]
    Decode(String),
    #[error("postprocess error: {0}")]
    Postprocess(String),
}

impl From<image::ImageError> for ImageError {
    fn from(value: image::ImageError) -> Self {
        ImageError::Decode(value.to_string())
    }
}
