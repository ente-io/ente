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

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Enum)]
pub enum GenerateEvent {
    Text {
        job_id: i64,
        text: String,
        token_id: Option<i32>,
    },
    Done { summary: GenerateSummary },
    Error { job_id: i64, message: String },
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
    let context = core::create_context(model.handle.clone(), params.into()).map_err(InferenceError::from)?;
    Ok(Arc::new(ContextHandle { handle: context }))
}

#[uniffi::export]
pub fn tokenize(
    model: Arc<ModelHandle>,
    text: String,
    add_bos: bool,
    special: bool,
) -> Result<Vec<i32>, InferenceError> {
    core::tokenize(model.handle.as_ref(), text, add_bos, special)
        .map_err(InferenceError::from)
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
pub fn apply_chat_template(
    model: Arc<ModelHandle>,
    messages: Vec<ChatMessage>,
    template_override: Option<String>,
    add_assistant: bool,
) -> Result<String, InferenceError> {
    let messages = messages.into_iter().map(Into::into).collect();
    core::apply_chat_template(model.handle.as_ref(), messages, template_override, add_assistant)
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
