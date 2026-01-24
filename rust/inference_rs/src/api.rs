use llama_cpp_2::context::LlamaContext;
use llama_cpp_2::context::params::LlamaContextParams;
use llama_cpp_2::llama_backend::LlamaBackend;
use llama_cpp_2::llama_batch::LlamaBatch;
use llama_cpp_2::model::{AddBos, LlamaChatMessage, LlamaChatTemplate, LlamaModel, Special};
use llama_cpp_2::mtmd::{
    MtmdBitmap, MtmdContext, MtmdContextParams, MtmdInputText, mtmd_default_marker,
};
use llama_cpp_2::sampling::LlamaSampler;
use llama_cpp_2::token::LlamaToken;
use llama_cpp_sys_2::{
    GGML_LOG_LEVEL_ERROR, GGML_LOG_LEVEL_WARN, ggml_log_level, mtmd_helper_log_set,
};
use parking_lot::Mutex;
use self_cell::self_cell;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::ffi::{CStr, CString};
use std::num::NonZeroU32;
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicI64, Ordering};
use std::sync::{Arc, OnceLock};
use std::time::Instant;

pub type JobId = i64;

pub trait EventSink {
    fn add(&mut self, event: GenerateEvent);
}

impl<F> EventSink for F
where
    F: FnMut(GenerateEvent),
{
    fn add(&mut self, event: GenerateEvent) {
        (self)(event);
    }
}

static BACKEND: OnceLock<Result<LlamaBackend, String>> = OnceLock::new();
static JOB_COUNTER: AtomicI64 = AtomicI64::new(1);
static CANCEL_FLAGS: OnceLock<Mutex<HashMap<JobId, Arc<AtomicBool>>>> = OnceLock::new();
static MTMD_LOG_BUFFER: OnceLock<Mutex<String>> = OnceLock::new();
static MTMD_LOG_HOOK: OnceLock<()> = OnceLock::new();

fn backend() -> Result<&'static LlamaBackend, String> {
    match BACKEND.get_or_init(|| LlamaBackend::init().map_err(|err| err.to_string())) {
        Ok(backend) => Ok(backend),
        Err(err) => Err(format!("Failed to initialize backend: {err}")),
    }
}

fn cancel_flags() -> &'static Mutex<HashMap<JobId, Arc<AtomicBool>>> {
    CANCEL_FLAGS.get_or_init(|| Mutex::new(HashMap::new()))
}

fn mtmd_log_buffer() -> &'static Mutex<String> {
    MTMD_LOG_BUFFER.get_or_init(|| Mutex::new(String::new()))
}

unsafe extern "C" fn mtmd_log_callback(
    level: ggml_log_level,
    text: *const ::std::os::raw::c_char,
    _user_data: *mut ::std::os::raw::c_void,
) {
    if text.is_null() {
        return;
    }
    if level != GGML_LOG_LEVEL_WARN && level != GGML_LOG_LEVEL_ERROR {
        return;
    }
    let cstr = unsafe { CStr::from_ptr(text) };
    if let Ok(message) = cstr.to_str() {
        let mut guard = mtmd_log_buffer().lock();
        guard.push_str(message);
        const MAX_LEN: usize = 8192;
        if guard.len() > MAX_LEN {
            let drain = guard.len() - MAX_LEN;
            guard.drain(..drain);
        }
    }
}

fn init_mtmd_logging() {
    MTMD_LOG_HOOK.get_or_init(|| unsafe {
        mtmd_helper_log_set(Some(mtmd_log_callback), std::ptr::null_mut());
    });
}

fn take_mtmd_logs() -> String {
    let mut guard = mtmd_log_buffer().lock();
    let logs = guard.clone();
    guard.clear();
    logs
}

fn register_job() -> (JobId, Arc<AtomicBool>) {
    let job_id = JOB_COUNTER.fetch_add(1, Ordering::Relaxed);
    let flag = Arc::new(AtomicBool::new(false));
    cancel_flags().lock().insert(job_id, flag.clone());
    (job_id, flag)
}


struct JobGuard(JobId);

impl Drop for JobGuard {
    fn drop(&mut self) {
        cancel_flags().lock().remove(&self.0);
    }
}

fn format_error(context: &str, err: impl std::fmt::Display) -> String {
    format!("{context}: {err}")
}

fn build_chat_prompt(
    model: &LlamaModel,
    messages: Vec<ChatMessage>,
    template_override: Option<String>,
    add_assistant: bool,
) -> Result<String, String> {
    let template = match template_override {
        Some(template) => LlamaChatTemplate::new(&template)
            .map_err(|err| format_error("Invalid chat template", err))?,
        None => model
            .chat_template(None)
            .or_else(|_| LlamaChatTemplate::new("chatml"))
            .map_err(|err| format_error("Failed to load chat template", err))?,
    };

    let chat_messages = messages
        .into_iter()
        .map(|message| {
            LlamaChatMessage::new(message.role, message.content)
                .map_err(|err| format_error("Invalid chat message", err))
        })
        .collect::<Result<Vec<_>, String>>()?;

    model
        .apply_chat_template(&template, &chat_messages, add_assistant)
        .map_err(|err| format_error("Failed to apply chat template", err))
}

fn should_add_bos(model: &LlamaModel, prompt: &str) -> AddBos {
    if let Ok(bos) = model.token_to_str(model.token_bos(), Special::Tokenize)
        && !bos.is_empty()
        && prompt.starts_with(&bos)
    {
        return AddBos::Never;
    }
    AddBos::Always
}

fn find_stop_index(text: &str, stop_sequences: &[String], start: usize) -> Option<usize> {
    let mut found: Option<usize> = None;
    let search = &text[start.min(text.len())..];

    for stop in stop_sequences {
        if stop.is_empty() {
            continue;
        }
        if let Some(idx) = search.find(stop) {
            let idx = start + idx;
            found = match found {
                Some(existing) if existing <= idx => Some(existing),
                _ => Some(idx),
            };
        }
    }

    found
}

fn drain_utf8(pending: &mut Vec<u8>) -> String {
    let mut output = String::new();
    loop {
        match std::str::from_utf8(pending) {
            Ok(text) => {
                output.push_str(text);
                pending.clear();
                break;
            }
            Err(err) => {
                let valid_up_to = err.valid_up_to();
                if valid_up_to > 0 {
                    let valid = std::str::from_utf8(&pending[..valid_up_to])
                        .expect("valid UTF-8 prefix");
                    output.push_str(valid);
                    pending.drain(..valid_up_to);
                }

                match err.error_len() {
                    None => break,
                    Some(len) => {
                        let len = len.min(pending.len());
                        let lossy = String::from_utf8_lossy(&pending[..len]);
                        output.push_str(&lossy);
                        pending.drain(..len);
                    }
                }
            }
        }
    }
    output
}

struct DecodeStep {
    text: Option<String>,
    stop: bool,
}

/// Incremental UTF-8 streaming decoder with stop-sequence handling.
struct StreamDecoder {
    generated_text: String,
    pending_bytes: Vec<u8>,
    stop_sequences: Vec<String>,
    max_stop_len: usize,
}

impl StreamDecoder {
    fn new(stop_sequences: &[String]) -> Self {
        let max_stop_len = stop_sequences.iter().map(|s| s.len()).max().unwrap_or(0);
        Self {
            generated_text: String::new(),
            pending_bytes: Vec::new(),
            stop_sequences: stop_sequences.to_vec(),
            max_stop_len,
        }
    }

    fn push_bytes(&mut self, bytes: &[u8]) -> DecodeStep {
        if !bytes.is_empty() {
            self.pending_bytes.extend_from_slice(bytes);
        }
        let piece = drain_utf8(&mut self.pending_bytes);
        self.push_text(piece)
    }

    fn flush(&mut self) -> DecodeStep {
        if self.pending_bytes.is_empty() {
            return DecodeStep { text: None, stop: false };
        }
        let piece = String::from_utf8_lossy(&self.pending_bytes).to_string();
        self.pending_bytes.clear();
        self.push_text(piece)
    }

    fn push_text(&mut self, piece: String) -> DecodeStep {
        if piece.is_empty() {
            return DecodeStep { text: None, stop: false };
        }

        let prev_len = self.generated_text.len();
        self.generated_text.push_str(&piece);

        if self.max_stop_len > 0 {
            let search_start = prev_len.saturating_sub(self.max_stop_len);
            if let Some(stop_index) =
                find_stop_index(&self.generated_text, &self.stop_sequences, search_start)
            {
                let new_piece = self.generated_text[prev_len..stop_index].to_string();
                self.generated_text.truncate(stop_index);
                return DecodeStep {
                    text: if new_piece.is_empty() { None } else { Some(new_piece) },
                    stop: true,
                };
            }
        }

        DecodeStep {
            text: Some(piece),
            stop: false,
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn run_generation_loop(
    ctx: &mut LlamaContext,
    sampler: &mut LlamaSampler,
    cancel_flag: &AtomicBool,
    sink: &mut dyn EventSink,
    job_id: JobId,
    max_tokens: usize,
    stop_sequences: &[String],
    generated_tokens_count: &mut i32,
    mut pos: i32,
    mut logits_index: i32,
) -> Result<(), String> {
    let mut decoder = StreamDecoder::new(stop_sequences);
    let mut stop_triggered = false;
    let n_ctx = ctx.n_ctx();

    for _ in 0..max_tokens {
        if cancel_flag.load(Ordering::Relaxed) {
            return Err("Generation cancelled".to_string());
        }
        if pos >= n_ctx as i32 {
            break;
        }

        let token = sampler.sample(ctx, logits_index);
        sampler.accept(token);
        *generated_tokens_count = generated_tokens_count.saturating_add(1);

        if ctx.model.is_eog_token(token) {
            break;
        }

        let bytes = ctx
            .model
            .token_to_bytes(token, Special::Tokenize)
            .map_err(|err| format_error("Detokenize failed", err))?;
        let step = decoder.push_bytes(&bytes);

        if let Some(text) = step.text {
            sink.add(GenerateEvent::Text {
                job_id,
                text,
                token_id: Some(token.0),
            });
        }

        if step.stop {
            stop_triggered = true;
            break;
        }

        let mut step_batch = LlamaBatch::new(1, 1);
        step_batch
            .add(token, pos, &[0], true)
            .map_err(|err| format_error("Failed to add token", err))?;
        ctx.decode(&mut step_batch)
            .map_err(|err| format_error("Decode failed", err))?;

        logits_index = 0;
        pos += 1;
    }

    if !stop_triggered {
        let step = decoder.flush();
        if let Some(text) = step.text {
            sink.add(GenerateEvent::Text {
                job_id,
                text,
                token_id: None,
            });
        }
    }

    Ok(())
}

fn build_sampler(model: &LlamaModel, request: &GenerateRequest) -> Result<LlamaSampler, String> {
    let mut samplers = Vec::new();

    let mut repeat_penalty = request.repeat_penalty.unwrap_or(1.0);
    if repeat_penalty <= 0.0 {
        repeat_penalty = 1.0;
    }
    let mut frequency_penalty = request.frequency_penalty.unwrap_or(0.0);
    if frequency_penalty < 0.0 {
        frequency_penalty = 0.0;
    }
    let mut presence_penalty = request.presence_penalty.unwrap_or(0.0);
    if presence_penalty < 0.0 {
        presence_penalty = 0.0;
    }

    if (repeat_penalty - 1.0).abs() > f32::EPSILON
        || frequency_penalty != 0.0
        || presence_penalty != 0.0
    {
        samplers.push(LlamaSampler::penalties(
            -1,
            repeat_penalty,
            frequency_penalty,
            presence_penalty,
        ));
    }

    if let Some(grammar) = request.grammar.as_deref() {
        samplers.push(
            LlamaSampler::grammar(model, grammar, "root")
                .map_err(|err| format_error("Invalid grammar", err))?,
        );
    }

    if let Some(top_k) = request.top_k
        && top_k > 0
    {
        samplers.push(LlamaSampler::top_k(top_k));
    }

    if let Some(top_p) = request.top_p
        && top_p > 0.0
        && top_p < 1.0
    {
        samplers.push(LlamaSampler::top_p(top_p, 1));
    }

    let temperature = request.temperature.unwrap_or(1.0);
    if temperature > 0.0 {
        samplers.push(LlamaSampler::temp(temperature));
        let seed = request.seed.unwrap_or(0);
        let seed = u32::try_from(seed).unwrap_or(0);
        samplers.push(LlamaSampler::dist(seed));
    } else {
        samplers.push(LlamaSampler::greedy());
    }

    Ok(LlamaSampler::chain_simple(samplers))
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelLoadParams {
    pub model_path: String,
    pub n_gpu_layers: Option<i32>,
    pub use_mmap: Option<bool>,
    pub use_mlock: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextParams {
    pub context_size: Option<i32>,
    pub n_threads: Option<i32>,
    pub n_batch: Option<i32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelInfo {
    pub bos_token_id: Option<i32>,
    pub eos_token_id: Option<i32>,
    pub bos_token: Option<String>,
    pub eos_token: Option<String>,
    pub chat_template: Option<String>,
    pub metadata_json: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatMessage {
    pub role: String,
    pub content: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GenerateSummary {
    pub job_id: JobId,
    pub prompt_tokens: Option<i32>,
    pub generated_tokens: Option<i32>,
    pub total_time_ms: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum GenerateEvent {
    Text {
        job_id: JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: GenerateSummary,
    },
    Error {
        job_id: JobId,
        message: String,
    },
}

pub struct ModelHandle {
    model: LlamaModel,
}

pub type ModelHandleRef = Arc<ModelHandle>;

impl ModelHandle {
    fn model(&self) -> &LlamaModel {
        &self.model
    }
}

self_cell!(
    struct ContextHandleCell {
        owner: ModelHandleRef,

        #[covariant]
        dependent: LlamaContext,
    }
);

pub struct ContextHandle(Mutex<ContextHandleCell>);

pub type ContextHandleRef = Arc<ContextHandle>;

unsafe impl Send for ContextHandle {}
unsafe impl Sync for ContextHandle {}

impl ContextHandle {
    fn try_new(
        owner: ModelHandleRef,
        builder: impl for<'a> FnOnce(&'a ModelHandleRef) -> Result<LlamaContext<'a>, String>,
    ) -> Result<Self, String> {
        ContextHandleCell::try_new(owner, builder).map(|cell| ContextHandle(Mutex::new(cell)))
    }

    fn with_context_mut<R>(
        &self,
        func: impl for<'a, 'b> FnOnce(&'b mut LlamaContext<'a>) -> R,
    ) -> R {
        let mut guard = self.0.lock();
        guard.with_dependent_mut(|_owner, context| func(context))
    }
}

pub fn init_backend() -> Result<(), String> {
    backend().map(|_| ())
}

pub fn load_model(params: ModelLoadParams) -> Result<ModelHandleRef, String> {
    let backend = backend()?;
    let mut model_params = llama_cpp_2::model::params::LlamaModelParams::default();

    if let Some(n_gpu_layers) = params.n_gpu_layers {
        let layers =
            u32::try_from(n_gpu_layers).map_err(|_| "n_gpu_layers must be >= 0".to_string())?;
        model_params = model_params.with_n_gpu_layers(layers);
    }

    if let Some(use_mlock) = params.use_mlock {
        model_params = model_params.with_use_mlock(use_mlock);
    }

    let model = LlamaModel::load_from_file(backend, Path::new(&params.model_path), &model_params)
        .map_err(|err| format_error("Failed to load model", err))?;

    Ok(Arc::new(ModelHandle { model }))
}

pub fn create_context(
    model: ModelHandleRef,
    params: ContextParams,
) -> Result<ContextHandleRef, String> {
    let mut context_params = LlamaContextParams::default();

    if let Some(context_size) = params.context_size {
        let context_size =
            u32::try_from(context_size).map_err(|_| "context_size must be > 0".to_string())?;
        let context_size =
            NonZeroU32::new(context_size).ok_or_else(|| "context_size must be > 0".to_string())?;
        context_params = context_params.with_n_ctx(Some(context_size));
    }

    if let Some(n_threads) = params.n_threads {
        if n_threads <= 0 {
            return Err("n_threads must be > 0".to_string());
        }
        context_params = context_params
            .with_n_threads(n_threads)
            .with_n_threads_batch(n_threads);
    }

    if let Some(n_batch) = params.n_batch {
        let n_batch = u32::try_from(n_batch).map_err(|_| "n_batch must be > 0".to_string())?;
        context_params = context_params.with_n_batch(n_batch);
    }

    let context = ContextHandle::try_new(model, |model| {
        let backend = backend()?;
        model
            .model()
            .new_context(backend, context_params)
            .map_err(|err| format_error("Failed to create context", err))
    })?;

    Ok(Arc::new(context))
}

pub fn tokenize(
    model: &ModelHandle,
    text: String,
    add_bos: bool,
    special: bool,
) -> Result<Vec<i32>, String> {
    let add_bos = if add_bos {
        AddBos::Always
    } else {
        AddBos::Never
    };
    let _ = special;

    let tokens = model
        .model()
        .str_to_token(&text, add_bos)
        .map_err(|err| format_error("Tokenize failed", err))?;

    Ok(tokens.into_iter().map(|token| token.0).collect())
}

pub fn detokenize(model: &ModelHandle, tokens: Vec<i32>) -> Result<String, String> {
    let tokens = tokens.into_iter().map(LlamaToken::new).collect::<Vec<_>>();
    model
        .model()
        .tokens_to_str(&tokens, Special::Tokenize)
        .map_err(|err| format_error("Detokenize failed", err))
}

pub fn get_model_info(model: &ModelHandle) -> Result<ModelInfo, String> {
    let model_ref = model.model();
    let bos_token = model_ref.token_bos();
    let eos_token = model_ref.token_eos();

    let bos_token_str = model_ref
        .token_to_str(bos_token, Special::Tokenize)
        .ok()
        .filter(|value| !value.is_empty());
    let eos_token_str = model_ref
        .token_to_str(eos_token, Special::Tokenize)
        .ok()
        .filter(|value| !value.is_empty());

    let chat_template = model_ref
        .chat_template(None)
        .ok()
        .and_then(|tmpl| tmpl.to_string().ok());

    let meta_count = model_ref.meta_count();
    let mut metadata_json = None;

    if meta_count > 0 {
        let mut map = serde_json::Map::new();
        for index in 0..meta_count {
            let key = model_ref
                .meta_key_by_index(index)
                .map_err(|err| format_error("Failed to read metadata key", err))?;
            let value = model_ref
                .meta_val_str_by_index(index)
                .map_err(|err| format_error("Failed to read metadata value", err))?;
            map.insert(key, serde_json::Value::String(value));
        }
        if !map.is_empty() {
            metadata_json = Some(serde_json::Value::Object(map).to_string());
        }
    }

    Ok(ModelInfo {
        bos_token_id: Some(bos_token.0),
        eos_token_id: Some(eos_token.0),
        bos_token: bos_token_str,
        eos_token: eos_token_str,
        chat_template,
        metadata_json,
    })
}

pub fn apply_chat_template(
    model: &ModelHandle,
    messages: Vec<ChatMessage>,
    template_override: Option<String>,
    add_assistant: bool,
) -> Result<String, String> {
    build_chat_prompt(model.model(), messages, template_override, add_assistant)
}

pub fn generate_chat_stream(
    context: &ContextHandle,
    request: GenerateChatRequest,
    sink: &mut dyn EventSink,
) -> Result<GenerateSummary, String> {
    let GenerateChatRequest {
        messages,
        template_override,
        add_assistant,
        image_paths,
        mmproj_path,
        media_marker,
        max_tokens,
        temperature,
        top_p,
        top_k,
        repeat_penalty,
        frequency_penalty,
        presence_penalty,
        seed,
        stop_sequences,
        grammar,
    } = request;

    let (job_id, cancel_flag) = register_job();
    let _job_guard = JobGuard(job_id);
    let start = Instant::now();

    sink.add(GenerateEvent::Text {
        job_id,
        text: String::new(),
        token_id: None,
    });

    let max_tokens = max_tokens.unwrap_or(128);
    let max_tokens = usize::try_from(max_tokens.max(0)).unwrap_or(0);
    let stop_sequences = stop_sequences.unwrap_or_default();

    let mut prompt_tokens_count: i32 = 0;
    let mut generated_tokens_count: i32 = 0;
    let mut error_message: Option<String> = None;

    let result = match catch_unwind(AssertUnwindSafe(|| {
        context.with_context_mut(|ctx| -> Result<(), String> {
            let add_assistant = add_assistant.unwrap_or(true);
            let mut messages = messages;
            let image_paths = image_paths.unwrap_or_default();
            let marker = media_marker
                .clone()
                .unwrap_or_else(|| mtmd_default_marker().to_string());

            if !image_paths.is_empty() {
                let mut marker_count = messages
                    .iter()
                    .map(|message| message.content.matches(&marker).count())
                    .sum::<usize>();
                if marker_count == 0 {
                    let target_index = messages
                        .iter()
                        .rposition(|message| message.role == "user")
                        .or_else(|| messages.len().checked_sub(1))
                        .ok_or_else(|| "No chat messages provided".to_string())?;
                    if !messages[target_index].content.ends_with('\n') {
                        messages[target_index].content.push('\n');
                    }
                    messages[target_index].content.push_str(&marker);
                    marker_count = messages
                        .iter()
                        .map(|message| message.content.matches(&marker).count())
                        .sum();
                }
                if marker_count != image_paths.len() {
                    return Err(format!(
                        "Found {marker_count} media markers but {} images were provided",
                        image_paths.len()
                    ));
                }
            }

            let prompt = build_chat_prompt(ctx.model, messages, template_override, add_assistant)?;

            let sampler_request = GenerateRequest {
                prompt: prompt.clone(),
                max_tokens: None,
                temperature,
                top_p,
                top_k,
                repeat_penalty,
                frequency_penalty,
                presence_penalty,
                seed,
                stop_sequences: Some(stop_sequences.clone()),
                grammar: grammar.clone(),
            };

            if image_paths.is_empty() {
                let add_bos = should_add_bos(ctx.model, &prompt);
                let prompt_tokens = ctx
                    .model
                    .str_to_token(&prompt, add_bos)
                    .map_err(|err| format_error("Tokenize failed", err))?;

                if prompt_tokens.is_empty() {
                    return Err("Prompt produced no tokens".to_string());
                }

                prompt_tokens_count = i32::try_from(prompt_tokens.len())
                    .map_err(|_| "Prompt is too long".to_string())?;

                let n_ctx = ctx.n_ctx();
                if prompt_tokens.len() as u32 > n_ctx {
                    return Err(format!(
                        "Prompt length {} exceeds context size {}",
                        prompt_tokens.len(),
                        n_ctx
                    ));
                }

                let n_batch = ctx.n_batch() as usize;
                if n_batch == 0 {
                    return Err("Context batch size is 0".to_string());
                }

                ctx.clear_kv_cache();

                let mut token_offset = 0usize;
                let mut logits_index: i32 = 0;
                while token_offset < prompt_tokens.len() {
                    let end = (token_offset + n_batch).min(prompt_tokens.len());
                    let chunk = &prompt_tokens[token_offset..end];
                    let mut batch = LlamaBatch::new(chunk.len(), 1);
                    for (idx, token) in chunk.iter().enumerate() {
                        let pos = (token_offset + idx) as i32;
                        let logits = token_offset + idx + 1 == prompt_tokens.len();
                        batch
                            .add(*token, pos, &[0], logits)
                            .map_err(|err| format_error("Failed to add prompt token", err))?;
                    }
                    ctx.decode(&mut batch)
                        .map_err(|err| format_error("Prompt decode failed", err))?;
                    if end == prompt_tokens.len() {
                        logits_index = (chunk.len() - 1) as i32;
                    }
                    token_offset = end;
                }

                let mut sampler = build_sampler(ctx.model, &sampler_request)?;
                sampler.accept_many(prompt_tokens.iter());

                let pos = prompt_tokens.len() as i32;
                run_generation_loop(
                    ctx,
                    &mut sampler,
                    &cancel_flag,
                    sink,
                    job_id,
                    max_tokens,
                    &stop_sequences,
                    &mut generated_tokens_count,
                    pos,
                    logits_index,
                )?;

                return Ok(());
            }

            let mmproj_path = mmproj_path.ok_or_else(|| {
                "mmproj_path is required when image_paths are provided".to_string()
            })?;
            if !Path::new(&mmproj_path).exists() {
                return Err(format!("mmproj file not found at {mmproj_path}"));
            }

            init_mtmd_logging();
            take_mtmd_logs();

            let media_marker = CString::new(marker.clone())
                .map_err(|err| format_error("Invalid media marker", err))?;
            let mtmd_params = MtmdContextParams {
                use_gpu: false,
                print_timings: false,
                media_marker,
                ..Default::default()
            };

            let mtmd_ctx = MtmdContext::init_from_file(&mmproj_path, ctx.model, &mtmd_params)
                .map_err(|err| {
                    let logs = take_mtmd_logs();
                    if logs.trim().is_empty() {
                        format_error("Failed to initialize mmproj", err)
                    } else {
                        format!("Failed to initialize mmproj: {err}. Logs: {logs}")
                    }
                })?;

            if !mtmd_ctx.support_vision() {
                return Err("Model does not support vision input".to_string());
            }

            let mut bitmaps = Vec::with_capacity(image_paths.len());
            for image_path in &image_paths {
                if !Path::new(image_path).exists() {
                    return Err(format!("Image file not found at {image_path}"));
                }
                let bitmap = MtmdBitmap::from_file(&mtmd_ctx, image_path)
                    .map_err(|err| format_error("Failed to load image", err))?;
                if bitmap.is_audio() {
                    return Err("Audio inputs are not supported".to_string());
                }
                bitmaps.push(bitmap);
            }
            let bitmap_refs = bitmaps.iter().collect::<Vec<_>>();

            let add_special = matches!(should_add_bos(ctx.model, &prompt), AddBos::Always);
            let input_text = MtmdInputText {
                text: prompt,
                add_special,
                parse_special: true,
            };

            let chunks = mtmd_ctx
                .tokenize(input_text, &bitmap_refs)
                .map_err(|err| format_error("Failed to tokenize multimodal input", err))?;

            if chunks.is_empty() {
                return Err("Prompt produced no tokens".to_string());
            }

            prompt_tokens_count = i32::try_from(chunks.total_tokens())
                .map_err(|_| "Prompt is too long".to_string())?;

            let n_ctx = ctx.n_ctx();
            let total_positions = chunks.total_positions();
            if total_positions as u32 > n_ctx {
                return Err(format!(
                    "Prompt length {} exceeds context size {}",
                    total_positions, n_ctx
                ));
            }

            let n_batch = ctx.n_batch() as i32;
            if n_batch <= 0 {
                return Err("Context batch size is 0".to_string());
            }

            ctx.clear_kv_cache();

            let n_past = chunks
                .eval_chunks(&mtmd_ctx, ctx, 0, 0, n_batch, true)
                .map_err(|err| format_error("Failed to evaluate multimodal prompt", err))?;

            let mut sampler = build_sampler(ctx.model, &sampler_request)?;
            let mut prompt_tokens = Vec::new();
            for index in 0..chunks.len() {
                if let Some(chunk) = chunks.get(index)
                    && let Some(tokens) = chunk.text_tokens()
                {
                    prompt_tokens.extend_from_slice(tokens);
                }
            }
            sampler.accept_many(prompt_tokens.iter());

            run_generation_loop(
                ctx,
                &mut sampler,
                &cancel_flag,
                sink,
                job_id,
                max_tokens,
                &stop_sequences,
                &mut generated_tokens_count,
                n_past,
                -1,
            )?;

            Ok(())
        })
    })) {
        Ok(inner) => inner,
        Err(_) => Err("Generation panicked".to_string()),
    };

    if let Err(err) = result {
        error_message = Some(err);
    }

    let summary = GenerateSummary {
        job_id,
        prompt_tokens: Some(prompt_tokens_count),
        generated_tokens: Some(generated_tokens_count),
        total_time_ms: Some(start.elapsed().as_millis() as i64),
    };

    if let Some(message) = error_message {
        sink.add(GenerateEvent::Error { job_id, message });
    }

    sink.add(GenerateEvent::Done {
        summary: summary.clone(),
    });

    Ok(summary)
}

pub fn generate_stream(
    context: &ContextHandle,
    request: GenerateRequest,
    sink: &mut dyn EventSink,
) -> Result<GenerateSummary, String> {
    let (job_id, cancel_flag) = register_job();
    let _job_guard = JobGuard(job_id);
    let start = Instant::now();

    sink.add(GenerateEvent::Text {
        job_id,
        text: String::new(),
        token_id: None,
    });

    let max_tokens = request.max_tokens.unwrap_or(128);
    let max_tokens = usize::try_from(max_tokens.max(0)).unwrap_or(0);
    let stop_sequences = request.stop_sequences.clone().unwrap_or_default();

    let mut prompt_tokens_count: i32 = 0;
    let mut generated_tokens_count: i32 = 0;
    let mut error_message: Option<String> = None;

    let result = match catch_unwind(AssertUnwindSafe(|| {
        context.with_context_mut(|ctx| -> Result<(), String> {
            let add_bos = should_add_bos(ctx.model, &request.prompt);
            let prompt_tokens = ctx
                .model
                .str_to_token(&request.prompt, add_bos)
                .map_err(|err| format_error("Tokenize failed", err))?;

            if prompt_tokens.is_empty() {
                return Err("Prompt produced no tokens".to_string());
            }

            prompt_tokens_count =
                i32::try_from(prompt_tokens.len()).map_err(|_| "Prompt is too long".to_string())?;

            let n_ctx = ctx.n_ctx();
            if prompt_tokens.len() as u32 > n_ctx {
                return Err(format!(
                    "Prompt length {} exceeds context size {}",
                    prompt_tokens.len(),
                    n_ctx
                ));
            }

            let n_batch = ctx.n_batch() as usize;
            if n_batch == 0 {
                return Err("Context batch size is 0".to_string());
            }

            ctx.clear_kv_cache();

            let mut token_offset = 0usize;
            let mut logits_index: i32 = 0;
            while token_offset < prompt_tokens.len() {
                let end = (token_offset + n_batch).min(prompt_tokens.len());
                let chunk = &prompt_tokens[token_offset..end];
                let mut batch = LlamaBatch::new(chunk.len(), 1);
                for (idx, token) in chunk.iter().enumerate() {
                    let pos = (token_offset + idx) as i32;
                    let logits = token_offset + idx + 1 == prompt_tokens.len();
                    batch
                        .add(*token, pos, &[0], logits)
                        .map_err(|err| format_error("Failed to add prompt token", err))?;
                }
                ctx.decode(&mut batch)
                    .map_err(|err| format_error("Prompt decode failed", err))?;
                if end == prompt_tokens.len() {
                    logits_index = (chunk.len() - 1) as i32;
                }
                token_offset = end;
            }

            let mut sampler = build_sampler(ctx.model, &request)?;
            sampler.accept_many(prompt_tokens.iter());

            let pos = prompt_tokens.len() as i32;
            run_generation_loop(
                ctx,
                &mut sampler,
                &cancel_flag,
                sink,
                job_id,
                max_tokens,
                &stop_sequences,
                &mut generated_tokens_count,
                pos,
                logits_index,
            )?;

            Ok(())
        })
    })) {
        Ok(inner) => inner,
        Err(_) => Err("Generation panicked".to_string()),
    };

    if let Err(err) = result {
        error_message = Some(err);
    }

    let summary = GenerateSummary {
        job_id,
        prompt_tokens: Some(prompt_tokens_count),
        generated_tokens: Some(generated_tokens_count),
        total_time_ms: Some(start.elapsed().as_millis() as i64),
    };

    if let Some(message) = error_message {
        sink.add(GenerateEvent::Error { job_id, message });
    }

    sink.add(GenerateEvent::Done {
        summary: summary.clone(),
    });

    Ok(summary)
}

pub fn cancel(job_id: JobId) -> Result<(), String> {
    if let Some(flag) = cancel_flags().lock().get(&job_id) {
        flag.store(true, Ordering::Relaxed);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::StreamDecoder;

    #[test]
    fn stream_decoder_emits_complete_utf8() {
        let mut decoder = StreamDecoder::new(&[]);
        let step = decoder.push_bytes(&[0xF0, 0x9F]);
        assert!(step.text.is_none());
        assert!(!step.stop);

        let step = decoder.push_bytes(&[0x99, 0x82]);
        assert_eq!(step.text.as_deref(), Some("🙂"));
        assert!(!step.stop);
    }
}
