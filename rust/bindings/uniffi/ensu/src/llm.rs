use ente_ensu::llm as core;
use std::sync::Arc;
use thiserror::Error;

#[derive(Debug, Error, uniffi::Error)]
pub enum LlmError {
    #[error("{0}")]
    Message(String),
}

impl From<String> for LlmError {
    fn from(value: String) -> Self {
        Self::Message(value)
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmModelLoadParams {
    pub model_path: String,
    pub n_gpu_layers: Option<i32>,
    pub use_mmap: Option<bool>,
    pub use_mlock: Option<bool>,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmContextParams {
    pub context_size: Option<i32>,
    pub n_threads: Option<i32>,
    pub n_batch: Option<i32>,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmChatRequest {
    pub messages: Vec<LlmChatMessage>,
    pub template_override: Option<String>,
    pub add_assistant: Option<bool>,
    pub image_paths: Option<Vec<String>>,
    pub mmproj_path: Option<String>,
    pub media_marker: Option<String>,
    pub max_tokens: Option<i32>,
    pub temperature: Option<f32>,
    pub top_p: Option<f32>,
    pub top_k: Option<i32>,
    pub repeat_penalty: Option<f32>,
    pub frequency_penalty: Option<f32>,
    pub presence_penalty: Option<f32>,
    pub seed: Option<i64>,
    pub stop_sequences: Option<Vec<String>>,
    pub grammar: Option<String>,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmGenerationSummary {
    pub job_id: i64,
    pub prompt_tokens: Option<i32>,
    pub generated_tokens: Option<i32>,
    pub total_time_ms: Option<i64>,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmModelDownloadTarget {
    pub label: String,
    pub url: String,
    pub destination_path: String,
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct LlmModelDownloadProgress {
    pub label: String,
    pub downloaded_bytes: i64,
    pub total_bytes: Option<i64>,
    pub file_downloaded_bytes: i64,
    pub file_total_bytes: Option<i64>,
    pub percentage: f64,
    pub elapsed_ms: i64,
    pub bytes_per_second: f64,
    pub file_elapsed_ms: i64,
    pub file_bytes_per_second: f64,
    pub retry_count: i32,
    pub file_retry_count: i32,
    pub file_complete: bool,
    pub complete: bool,
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum LlmGenerationEvent {
    Text {
        job_id: i64,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: LlmGenerationSummary,
    },
    Error {
        job_id: i64,
        message: String,
    },
}

#[derive(uniffi::Object)]
pub struct LlmModelHandle {
    handle: core::ModelHandleRef,
}

#[derive(uniffi::Object)]
pub struct LlmContextHandle {
    handle: core::ContextHandleRef,
}

#[uniffi::export(callback_interface)]
pub trait LlmGenerationEventCallback: Send + Sync {
    fn on_event(&self, event: LlmGenerationEvent);
}

#[uniffi::export(callback_interface)]
pub trait LlmModelDownloadCallback: Send + Sync {
    fn on_progress(&self, progress: LlmModelDownloadProgress);
    fn is_cancelled(&self) -> bool;
}

impl From<LlmModelLoadParams> for core::ModelLoadParams {
    fn from(value: LlmModelLoadParams) -> Self {
        Self {
            model_path: value.model_path,
            n_gpu_layers: value.n_gpu_layers,
            use_mmap: value.use_mmap,
            use_mlock: value.use_mlock,
        }
    }
}

impl From<LlmContextParams> for core::ContextParams {
    fn from(value: LlmContextParams) -> Self {
        Self {
            context_size: value.context_size,
            n_threads: value.n_threads,
            n_batch: value.n_batch,
        }
    }
}

impl From<LlmChatMessage> for core::ChatMessage {
    fn from(value: LlmChatMessage) -> Self {
        Self {
            role: value.role,
            content: value.content,
        }
    }
}

impl From<LlmChatRequest> for core::ChatRequest {
    fn from(value: LlmChatRequest) -> Self {
        Self {
            messages: value.messages.into_iter().map(Into::into).collect(),
            template_override: value.template_override,
            add_assistant: value.add_assistant,
            image_paths: value.image_paths,
            mmproj_path: value.mmproj_path,
            media_marker: value.media_marker,
            max_tokens: value.max_tokens,
            temperature: value.temperature,
            top_p: value.top_p,
            top_k: value.top_k,
            repeat_penalty: value.repeat_penalty,
            frequency_penalty: value.frequency_penalty,
            presence_penalty: value.presence_penalty,
            seed: value.seed,
            stop_sequences: value.stop_sequences,
            grammar: value.grammar,
        }
    }
}

impl From<LlmModelDownloadTarget> for core::ModelDownloadTarget {
    fn from(value: LlmModelDownloadTarget) -> Self {
        Self {
            label: value.label,
            url: value.url,
            destination_path: value.destination_path,
        }
    }
}

impl From<core::GenerationSummary> for LlmGenerationSummary {
    fn from(value: core::GenerationSummary) -> Self {
        Self {
            job_id: value.job_id,
            prompt_tokens: value.prompt_tokens,
            generated_tokens: value.generated_tokens,
            total_time_ms: value.total_time_ms,
        }
    }
}

impl From<core::ModelDownloadProgress> for LlmModelDownloadProgress {
    fn from(value: core::ModelDownloadProgress) -> Self {
        Self {
            label: value.label,
            downloaded_bytes: u64_to_i64(value.downloaded_bytes),
            total_bytes: value.total_bytes.map(u64_to_i64),
            file_downloaded_bytes: u64_to_i64(value.file_downloaded_bytes),
            file_total_bytes: value.file_total_bytes.map(u64_to_i64),
            percentage: value.percentage,
            elapsed_ms: u64_to_i64(value.elapsed_ms),
            bytes_per_second: value.bytes_per_second,
            file_elapsed_ms: u64_to_i64(value.file_elapsed_ms),
            file_bytes_per_second: value.file_bytes_per_second,
            retry_count: u32_to_i32(value.retry_count),
            file_retry_count: u32_to_i32(value.file_retry_count),
            file_complete: value.file_complete,
            complete: value.complete,
        }
    }
}

impl From<core::GenerationEvent> for LlmGenerationEvent {
    fn from(value: core::GenerationEvent) -> Self {
        match value {
            core::GenerationEvent::Text {
                job_id,
                text,
                token_id,
            } => Self::Text {
                job_id,
                text,
                token_id,
            },
            core::GenerationEvent::Done { summary } => Self::Done {
                summary: summary.into(),
            },
            core::GenerationEvent::Error { job_id, message } => Self::Error { job_id, message },
        }
    }
}

fn u64_to_i64(value: u64) -> i64 {
    i64::try_from(value).unwrap_or(i64::MAX)
}

fn u32_to_i32(value: u32) -> i32 {
    i32::try_from(value).unwrap_or(i32::MAX)
}

struct CallbackSink {
    callback: Box<dyn LlmGenerationEventCallback>,
}

impl core::EventSink for CallbackSink {
    fn add(&mut self, event: core::GenerationEvent) {
        self.callback.on_event(event.into());
    }
}

#[uniffi::export]
pub fn llm_init_backend() -> Result<(), LlmError> {
    core::init_backend().map_err(LlmError::from)
}

#[uniffi::export]
pub fn llm_load_model(params: LlmModelLoadParams) -> Result<Arc<LlmModelHandle>, LlmError> {
    let model = core::load_model(params.into()).map_err(LlmError::from)?;
    Ok(Arc::new(LlmModelHandle { handle: model }))
}

#[uniffi::export]
pub fn llm_create_context(
    model: Arc<LlmModelHandle>,
    params: LlmContextParams,
) -> Result<Arc<LlmContextHandle>, LlmError> {
    let context =
        core::create_context(model.handle.clone(), params.into()).map_err(LlmError::from)?;
    Ok(Arc::new(LlmContextHandle { handle: context }))
}

#[uniffi::export]
pub fn llm_download_model_files(
    targets: Vec<LlmModelDownloadTarget>,
    callback: Box<dyn LlmModelDownloadCallback>,
) -> Result<(), LlmError> {
    let callback: Arc<dyn LlmModelDownloadCallback> = Arc::from(callback);
    let progress_callback = Arc::clone(&callback);
    let cancel_callback = Arc::clone(&callback);
    let targets = targets.into_iter().map(Into::into).collect();
    core::download_model_files(
        targets,
        move |progress| progress_callback.on_progress(progress.into()),
        move || cancel_callback.is_cancelled(),
    )
    .map_err(LlmError::from)
}

#[uniffi::export]
pub fn llm_prewarm_multimodal_context(
    context: Arc<LlmContextHandle>,
    mmproj_path: String,
    media_marker: Option<String>,
) -> Result<(), LlmError> {
    core::prewarm_multimodal_context(context.handle.as_ref(), mmproj_path, media_marker)
        .map_err(LlmError::from)
}

#[uniffi::export]
pub fn llm_generate_chat_stream(
    context: Arc<LlmContextHandle>,
    request: LlmChatRequest,
    callback: Box<dyn LlmGenerationEventCallback>,
) -> Result<LlmGenerationSummary, LlmError> {
    let mut sink = CallbackSink { callback };
    core::generate_chat_stream(context.handle.as_ref(), request.into(), &mut sink)
        .map(Into::into)
        .map_err(LlmError::from)
}

#[uniffi::export]
pub fn llm_cancel(job_id: i64) {
    let _ = core::cancel(job_id);
}
