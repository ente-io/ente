mod audio;
mod model;
mod text;
mod transcriber;

pub use model::{ModelEvent, download_model, is_model_downloaded, model_path, model_size_mb};
pub use transcriber::{transcribe_pcm16, unload_model};

#[derive(Debug, thiserror::Error)]
pub enum TranscriptionError {
    #[error("{0}")]
    Message(String),
}

impl From<std::io::Error> for TranscriptionError {
    fn from(value: std::io::Error) -> Self {
        Self::Message(value.to_string())
    }
}

impl From<reqwest::Error> for TranscriptionError {
    fn from(value: reqwest::Error) -> Self {
        Self::Message(value.to_string())
    }
}

impl From<transcribe_rs::TranscribeError> for TranscriptionError {
    fn from(value: transcribe_rs::TranscribeError) -> Self {
        Self::Message(value.to_string())
    }
}

impl From<rubato::ResamplerConstructionError> for TranscriptionError {
    fn from(value: rubato::ResamplerConstructionError) -> Self {
        Self::Message(value.to_string())
    }
}

pub type Result<T> = std::result::Result<T, TranscriptionError>;

pub(crate) fn error(message: impl Into<String>) -> TranscriptionError {
    TranscriptionError::Message(message.into())
}
