use inference_rs as core;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use thiserror::Error;

#[derive(Debug, Error, uniffi::Error)]
pub enum InferenceError {
    #[error("{0}")]
    Message(String),
}

impl From<String> for InferenceError {
    fn from(value: String) -> Self {
        Self::Message(value)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct ModelLoadParams {
    pub model_path: String,
    pub n_gpu_layers: Option<i32>,
    pub use_mmap: Option<bool>,
    pub use_mlock: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct ContextParams {
    pub context_size: Option<i32>,
    pub n_threads: Option<i32>,
    pub n_batch: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct ModelInfo {
    pub bos_token_id: Option<i32>,
    pub eos_token_id: Option<i32>,
    pub bos_token: Option<String>,
    pub eos_token: Option<String>,
    pub chat_template: Option<String>,
    pub metadata_json: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct EnsuModelPreset {
    pub id: String,
    pub title: String,
    pub url: String,
    pub mmproj_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct EnsuDefaults {
    pub mobile_system_prompt_body: String,
    pub desktop_system_prompt_body: String,
    pub system_prompt_date_placeholder: String,
    pub session_summary_system_prompt: String,
    pub mobile_default_model: EnsuModelPreset,
    pub mobile_model_presets: Vec<EnsuModelPreset>,
    pub desktop_default_model: EnsuModelPreset,
    pub desktop_model_presets: Vec<EnsuModelPreset>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct GenerateRequest {
    pub prompt: String,
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

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct GenerateChatRequest {
    pub messages: Vec<ChatMessage>,
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

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct GenerateSummary {
    pub job_id: i64,
    pub prompt_tokens: Option<i32>,
    pub generated_tokens: Option<i32>,
    pub total_time_ms: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct LlmModelDownloadTarget {
    pub label: String,
    pub url: String,
    pub destination_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
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

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Enum)]
pub enum GenerateEvent {
    Text {
        job_id: i64,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: GenerateSummary,
    },
    Error {
        job_id: i64,
        message: String,
    },
}

#[derive(uniffi::Object)]
pub struct ModelHandle {
    handle: core::ModelHandleRef,
}

#[derive(uniffi::Object)]
pub struct ContextHandle {
    handle: core::ContextHandleRef,
}

#[uniffi::export(callback_interface)]
pub trait GenerateEventCallback: Send + Sync {
    fn on_event(&self, event: GenerateEvent);
}

#[uniffi::export(callback_interface)]
pub trait LlmModelDownloadCallback: Send + Sync {
    fn on_progress(&self, progress: LlmModelDownloadProgress);
    fn is_cancelled(&self) -> bool;
}

impl From<ModelLoadParams> for core::ModelLoadParams {
    fn from(value: ModelLoadParams) -> Self {
        Self {
            model_path: value.model_path,
            n_gpu_layers: value.n_gpu_layers,
            use_mmap: value.use_mmap,
            use_mlock: value.use_mlock,
        }
    }
}

impl From<ContextParams> for core::ContextParams {
    fn from(value: ContextParams) -> Self {
        Self {
            context_size: value.context_size,
            n_threads: value.n_threads,
            n_batch: value.n_batch,
        }
    }
}

impl From<core::ModelInfo> for ModelInfo {
    fn from(value: core::ModelInfo) -> Self {
        Self {
            bos_token_id: value.bos_token_id,
            eos_token_id: value.eos_token_id,
            bos_token: value.bos_token,
            eos_token: value.eos_token,
            chat_template: value.chat_template,
            metadata_json: value.metadata_json,
        }
    }
}

impl From<core::EnsuModelPreset> for EnsuModelPreset {
    fn from(value: core::EnsuModelPreset) -> Self {
        Self {
            id: value.id,
            title: value.title,
            url: value.url,
            mmproj_url: value.mmproj_url,
        }
    }
}

impl From<core::EnsuDefaults> for EnsuDefaults {
    fn from(value: core::EnsuDefaults) -> Self {
        Self {
            mobile_system_prompt_body: value.mobile_system_prompt_body,
            desktop_system_prompt_body: value.desktop_system_prompt_body,
            system_prompt_date_placeholder: value.system_prompt_date_placeholder,
            session_summary_system_prompt: value.session_summary_system_prompt,
            mobile_default_model: value.mobile_default_model.into(),
            mobile_model_presets: value
                .mobile_model_presets
                .into_iter()
                .map(Into::into)
                .collect(),
            desktop_default_model: value.desktop_default_model.into(),
            desktop_model_presets: value
                .desktop_model_presets
                .into_iter()
                .map(Into::into)
                .collect(),
        }
    }
}

impl From<ChatMessage> for core::ChatMessage {
    fn from(value: ChatMessage) -> Self {
        Self {
            role: value.role,
            content: value.content,
        }
    }
}

impl From<GenerateRequest> for core::GenerateRequest {
    fn from(value: GenerateRequest) -> Self {
        Self {
            prompt: value.prompt,
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

impl From<GenerateChatRequest> for core::GenerateChatRequest {
    fn from(value: GenerateChatRequest) -> Self {
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

impl From<LlmModelDownloadTarget> for core::LlmModelDownloadTarget {
    fn from(value: LlmModelDownloadTarget) -> Self {
        Self {
            label: value.label,
            url: value.url,
            destination_path: value.destination_path,
        }
    }
}

impl From<core::GenerateSummary> for GenerateSummary {
    fn from(value: core::GenerateSummary) -> Self {
        Self {
            job_id: value.job_id,
            prompt_tokens: value.prompt_tokens,
            generated_tokens: value.generated_tokens,
            total_time_ms: value.total_time_ms,
        }
    }
}

impl From<core::LlmModelDownloadProgress> for LlmModelDownloadProgress {
    fn from(value: core::LlmModelDownloadProgress) -> Self {
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

impl From<core::GenerateEvent> for GenerateEvent {
    fn from(value: core::GenerateEvent) -> Self {
        match value {
            core::GenerateEvent::Text {
                job_id,
                text,
                token_id,
            } => Self::Text {
                job_id,
                text,
                token_id,
            },
            core::GenerateEvent::Done { summary } => Self::Done {
                summary: summary.into(),
            },
            core::GenerateEvent::Error { job_id, message } => Self::Error { job_id, message },
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
    callback: Box<dyn GenerateEventCallback>,
}

impl core::EventSink for CallbackSink {
    fn add(&mut self, event: core::GenerateEvent) {
        self.callback.on_event(event.into());
    }
}

#[uniffi::export]
pub fn init_backend() -> Result<(), InferenceError> {
    core::init_backend().map_err(InferenceError::from)
}

#[uniffi::export]
pub fn load_model(params: ModelLoadParams) -> Result<Arc<ModelHandle>, InferenceError> {
    let model = core::load_model(params.into()).map_err(InferenceError::from)?;
    Ok(Arc::new(ModelHandle { handle: model }))
}

#[uniffi::export]
pub fn create_context(
    model: Arc<ModelHandle>,
    params: ContextParams,
) -> Result<Arc<ContextHandle>, InferenceError> {
    let context =
        core::create_context(model.handle.clone(), params.into()).map_err(InferenceError::from)?;
    Ok(Arc::new(ContextHandle { handle: context }))
}

#[uniffi::export]
pub fn tokenize(
    model: Arc<ModelHandle>,
    text: String,
    add_bos: bool,
    special: bool,
) -> Result<Vec<i32>, InferenceError> {
    core::tokenize(model.handle.as_ref(), text, add_bos, special).map_err(InferenceError::from)
}

#[uniffi::export]
pub fn detokenize(model: Arc<ModelHandle>, tokens: Vec<i32>) -> Result<String, InferenceError> {
    core::detokenize(model.handle.as_ref(), tokens).map_err(InferenceError::from)
}

#[uniffi::export]
pub fn get_model_info(model: Arc<ModelHandle>) -> Result<ModelInfo, InferenceError> {
    core::get_model_info(model.handle.as_ref())
        .map(Into::into)
        .map_err(InferenceError::from)
}

#[uniffi::export]
pub fn get_ensu_defaults() -> EnsuDefaults {
    core::ensu_defaults().into()
}

#[uniffi::export]
pub fn download_llm_model_files(
    targets: Vec<LlmModelDownloadTarget>,
    callback: Box<dyn LlmModelDownloadCallback>,
) -> Result<(), InferenceError> {
    let callback: Arc<dyn LlmModelDownloadCallback> = Arc::from(callback);
    let progress_callback = Arc::clone(&callback);
    let cancel_callback = Arc::clone(&callback);
    let targets = targets.into_iter().map(Into::into).collect();
    core::download_llm_model_files(
        targets,
        move |progress| progress_callback.on_progress(progress.into()),
        move || cancel_callback.is_cancelled(),
    )
    .map_err(InferenceError::from)
}

#[uniffi::export]
pub fn apply_chat_template(
    model: Arc<ModelHandle>,
    messages: Vec<ChatMessage>,
    template_override: Option<String>,
    add_assistant: bool,
) -> Result<String, InferenceError> {
    let messages = messages.into_iter().map(Into::into).collect();
    core::apply_chat_template(
        model.handle.as_ref(),
        messages,
        template_override,
        add_assistant,
    )
    .map_err(InferenceError::from)
}

#[uniffi::export]
pub fn prewarm_multimodal_context(
    context: Arc<ContextHandle>,
    mmproj_path: String,
    media_marker: Option<String>,
) -> Result<(), InferenceError> {
    core::prewarm_multimodal_context(context.handle.as_ref(), mmproj_path, media_marker)
        .map_err(InferenceError::from)
}

#[uniffi::export]
pub fn generate_chat_stream(
    context: Arc<ContextHandle>,
    request: GenerateChatRequest,
    callback: Box<dyn GenerateEventCallback>,
) -> Result<GenerateSummary, InferenceError> {
    let mut sink = CallbackSink { callback };
    core::generate_chat_stream(context.handle.as_ref(), request.into(), &mut sink)
        .map(Into::into)
        .map_err(InferenceError::from)
}

#[uniffi::export]
pub fn generate_stream(
    context: Arc<ContextHandle>,
    request: GenerateRequest,
    callback: Box<dyn GenerateEventCallback>,
) -> Result<GenerateSummary, InferenceError> {
    let mut sink = CallbackSink { callback };
    core::generate_stream(context.handle.as_ref(), request.into(), &mut sink)
        .map(Into::into)
        .map_err(InferenceError::from)
}

#[uniffi::export]
pub fn cancel(job_id: i64) {
    let _ = core::cancel(job_id);
}
