use thiserror::Error;

use ensu_transcription as core;

#[derive(Debug, Error, uniffi::Error)]
pub enum TranscriptionError {
    #[error("{0}")]
    Message(String),
}

impl From<core::TranscriptionError> for TranscriptionError {
    fn from(value: core::TranscriptionError) -> Self {
        Self::Message(value.to_string())
    }
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum TranscriptionModelEvent {
    DownloadProgress {
        downloaded: u64,
        total: u64,
        percentage: f64,
    },
    ExtractionStarted,
    ExtractionCompleted,
    DownloadComplete,
    DownloadError {
        message: String,
    },
}

impl From<core::ModelEvent> for TranscriptionModelEvent {
    fn from(value: core::ModelEvent) -> Self {
        match value {
            core::ModelEvent::DownloadProgress {
                downloaded,
                total,
                percentage,
            } => Self::DownloadProgress {
                downloaded,
                total,
                percentage,
            },
            core::ModelEvent::ExtractionStarted => Self::ExtractionStarted,
            core::ModelEvent::ExtractionCompleted => Self::ExtractionCompleted,
            core::ModelEvent::DownloadComplete => Self::DownloadComplete,
            core::ModelEvent::DownloadError { message } => Self::DownloadError { message },
        }
    }
}

#[uniffi::export(callback_interface)]
pub trait TranscriptionModelEventCallback: Send + Sync {
    fn on_event(&self, event: TranscriptionModelEvent);
}

#[uniffi::export]
pub fn is_transcription_model_downloaded(models_dir: String) -> bool {
    core::is_model_downloaded(models_dir)
}

#[uniffi::export]
pub fn transcription_model_path(models_dir: String) -> String {
    core::model_path(models_dir).to_string_lossy().into_owned()
}

#[uniffi::export]
pub fn transcription_model_size_mb() -> u64 {
    core::model_size_mb()
}

#[uniffi::export]
pub fn download_transcription_model(
    models_dir: String,
    callback: Box<dyn TranscriptionModelEventCallback>,
) -> Result<String, TranscriptionError> {
    core::download_model(models_dir, |event| callback.on_event(event.into()))
        .map(|path| path.to_string_lossy().into_owned())
        .map_err(Into::into)
}

#[uniffi::export]
pub fn transcribe_pcm16(
    models_dir: String,
    vad_cache_dir: String,
    input_sample_rate: u32,
    pcm_le: Vec<u8>,
) -> Result<String, TranscriptionError> {
    core::transcribe_pcm16(models_dir, vad_cache_dir, input_sample_rate, pcm_le).map_err(Into::into)
}

#[uniffi::export]
pub fn unload_transcription_model() -> Result<(), TranscriptionError> {
    core::unload_model().map_err(Into::into)
}
