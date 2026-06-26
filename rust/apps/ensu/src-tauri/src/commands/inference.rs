use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use ente_ensu::inference;
use serde::{Deserialize, Serialize};
use tauri::async_runtime;
use tauri::{AppHandle, Emitter, Manager, State, WebviewWindow};

use crate::commands::common::{ApiError, log_command_panic, panic_message};
use crate::logging;

#[derive(Default)]
pub struct LlmState {
    model: Mutex<Option<inference::ModelHandleRef>>,
    context: Mutex<Option<inference::ContextHandleRef>>,
}

pub struct LlmModelDownloadState {
    cancel_requested: Arc<AtomicBool>,
}

impl Default for LlmModelDownloadState {
    fn default() -> Self {
        Self {
            cancel_requested: Arc::new(AtomicBool::new(false)),
        }
    }
}

const LLM_PANIC_JOB_ID: i64 = 0;

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TauriEnsuModelPreset {
    id: String,
    title: String,
    url: String,
    mmproj_url: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TauriEnsuDefaults {
    mobile_system_prompt_body: String,
    desktop_system_prompt_body: String,
    system_prompt_date_placeholder: String,
    session_summary_system_prompt: String,
    mobile_default_model: TauriEnsuModelPreset,
    mobile_model_presets: Vec<TauriEnsuModelPreset>,
    desktop_default_model: TauriEnsuModelPreset,
    desktop_model_presets: Vec<TauriEnsuModelPreset>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TauriLlmModelDownloadTarget {
    label: String,
    url: String,
    path: String,
}

#[derive(Debug, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct TauriLlmModelDownloadProgress {
    label: String,
    percent: i32,
    status: String,
    bytes_downloaded: u64,
    total_bytes: Option<u64>,
    file_bytes_downloaded: u64,
    file_total_bytes: Option<u64>,
}

impl From<inference::EnsuModelPreset> for TauriEnsuModelPreset {
    fn from(p: inference::EnsuModelPreset) -> Self {
        Self {
            id: p.id,
            title: p.title,
            url: p.url,
            mmproj_url: p.mmproj_url,
        }
    }
}

impl From<inference::EnsuDefaults> for TauriEnsuDefaults {
    fn from(d: inference::EnsuDefaults) -> Self {
        Self {
            mobile_system_prompt_body: d.mobile_system_prompt_body,
            desktop_system_prompt_body: d.desktop_system_prompt_body,
            system_prompt_date_placeholder: d.system_prompt_date_placeholder,
            session_summary_system_prompt: d.session_summary_system_prompt,
            mobile_default_model: d.mobile_default_model.into(),
            mobile_model_presets: d.mobile_model_presets.into_iter().map(Into::into).collect(),
            desktop_default_model: d.desktop_default_model.into(),
            desktop_model_presets: d
                .desktop_model_presets
                .into_iter()
                .map(Into::into)
                .collect(),
        }
    }
}

fn llm_error(message: impl Into<String>) -> ApiError {
    ApiError::new("llm", message)
}

fn llm_thread_error() -> ApiError {
    ApiError::new("llm", "LLM task failed")
}

fn fs_thread_error() -> ApiError {
    ApiError::new("io_thread", "FS task failed")
}

pub(crate) fn replace_llm_state(
    llm_state: &LlmState,
    model: Option<inference::ModelHandleRef>,
    context: Option<inference::ContextHandleRef>,
) -> Result<(), ApiError> {
    let mut model_guard = llm_state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?;
    let mut context_guard = llm_state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;

    *model_guard = model;
    *context_guard = context;
    Ok(())
}

fn default_llm_threads() -> i32 {
    let available = std::thread::available_parallelism()
        .map(|count| count.get())
        .unwrap_or(2);
    let half = available / 2;
    let threads = if half == 0 { 1 } else { half };
    i32::try_from(threads).unwrap_or(1)
}

#[derive(Serialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
enum LlmEvent {
    Text {
        job_id: inference::JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: inference::GenerateSummary,
    },
    Error {
        job_id: inference::JobId,
        message: String,
    },
}

impl From<inference::GenerateEvent> for LlmEvent {
    fn from(value: inference::GenerateEvent) -> Self {
        match value {
            inference::GenerateEvent::Text {
                job_id,
                text,
                token_id,
            } => Self::Text {
                job_id,
                text,
                token_id,
            },
            inference::GenerateEvent::Done { summary } => Self::Done { summary },
            inference::GenerateEvent::Error { job_id, message } => Self::Error { job_id, message },
        }
    }
}

const LLM_EVENT_BATCH_MS: u64 = 80;
const LLM_EVENT_BATCH_BYTES: usize = 2048;

struct LlmEventSink {
    window: WebviewWindow,
    buffered_text: String,
    buffered_job_id: Option<inference::JobId>,
    buffered_token_id: Option<i32>,
    last_emit: Instant,
}

impl LlmEventSink {
    fn new(window: WebviewWindow) -> Self {
        Self {
            window,
            buffered_text: String::new(),
            buffered_job_id: None,
            buffered_token_id: None,
            last_emit: Instant::now(),
        }
    }

    fn flush_text(&mut self) {
        if self.buffered_text.is_empty() {
            self.buffered_job_id = None;
            self.buffered_token_id = None;
            self.last_emit = Instant::now();
            return;
        }

        if let Some(job_id) = self.buffered_job_id.take() {
            let payload = LlmEvent::Text {
                job_id,
                text: std::mem::take(&mut self.buffered_text),
                token_id: self.buffered_token_id.take(),
            };
            let _ = self.window.emit("llm-event", payload);
        } else {
            self.buffered_text.clear();
            self.buffered_token_id = None;
        }

        self.last_emit = Instant::now();
    }
}

impl inference::EventSink for LlmEventSink {
    fn add(&mut self, event: inference::GenerateEvent) {
        match event {
            inference::GenerateEvent::Text {
                job_id,
                text,
                token_id,
            } => {
                if let Some(current) = self.buffered_job_id
                    && current != job_id
                {
                    self.flush_text();
                }

                if self.buffered_text.is_empty() {
                    self.last_emit = Instant::now();
                }

                self.buffered_job_id = Some(job_id);
                self.buffered_token_id = token_id;
                self.buffered_text.push_str(&text);

                let elapsed = self.last_emit.elapsed();
                if self.buffered_text.len() >= LLM_EVENT_BATCH_BYTES
                    || elapsed >= Duration::from_millis(LLM_EVENT_BATCH_MS)
                {
                    self.flush_text();
                }
            }
            inference::GenerateEvent::Done { summary } => {
                self.flush_text();
                let _ = self.window.emit("llm-event", LlmEvent::Done { summary });
            }
            inference::GenerateEvent::Error { job_id, message } => {
                self.flush_text();
                let _ = self
                    .window
                    .emit("llm-event", LlmEvent::Error { job_id, message });
            }
        }
    }
}

#[tauri::command]
pub fn get_ensu_defaults() -> TauriEnsuDefaults {
    inference::ensu_defaults().into()
}

#[tauri::command]
pub async fn llm_download_model_files(
    window: WebviewWindow,
    state: State<'_, LlmModelDownloadState>,
    downloads: Vec<TauriLlmModelDownloadTarget>,
) -> Result<(), ApiError> {
    let cancel_requested = Arc::clone(&state.cancel_requested);
    cancel_requested.store(false, Ordering::SeqCst);
    let targets = downloads
        .into_iter()
        .map(|download| inference::LlmModelDownloadTarget {
            label: download.label,
            url: download.url,
            destination_path: download.path,
        })
        .collect::<Vec<_>>();

    async_runtime::spawn_blocking(move || {
        let progress_window = window.clone();
        inference::download_llm_model_files(
            targets,
            move |progress| {
                log_download_metrics(&progress);
                let payload = tauri_download_progress(progress);
                let _ = progress_window.emit("llm-download-progress", payload);
            },
            move || cancel_requested.load(Ordering::SeqCst),
        )
        .map_err(llm_error)
    })
    .await
    .map_err(|_| fs_thread_error())?
}

#[tauri::command]
pub fn llm_cancel_model_download(state: State<'_, LlmModelDownloadState>) {
    state.cancel_requested.store(true, Ordering::SeqCst);
}

fn tauri_download_progress(
    progress: inference::LlmModelDownloadProgress,
) -> TauriLlmModelDownloadProgress {
    let percent = if progress.total_bytes.is_some() {
        progress.percentage.round().clamp(0.0, 100.0) as i32
    } else {
        0
    };
    let status = download_progress_status(&progress);

    TauriLlmModelDownloadProgress {
        label: progress.label,
        percent,
        status,
        bytes_downloaded: progress.downloaded_bytes,
        total_bytes: progress.total_bytes,
        file_bytes_downloaded: progress.file_downloaded_bytes,
        file_total_bytes: progress.file_total_bytes,
    }
}

fn download_progress_status(progress: &inference::LlmModelDownloadProgress) -> String {
    if progress.label == "Complete" {
        return "Download complete".to_string();
    }
    if progress.label == "Preparing downloads" {
        return "Preparing downloads...".to_string();
    }

    if let Some(total) = progress.total_bytes {
        format!(
            "Downloading... {} / {}",
            format_bytes(progress.downloaded_bytes),
            format_bytes(total)
        )
    } else if progress.file_downloaded_bytes > 0 {
        format!(
            "Downloading {}... {}",
            progress.label.to_lowercase(),
            format_bytes(progress.file_downloaded_bytes)
        )
    } else {
        format!("Downloading {}...", progress.label.to_lowercase())
    }
}

fn log_download_metrics(progress: &inference::LlmModelDownloadProgress) {
    if progress.file_complete {
        logging::log(
            "LLMDownload",
            format!(
                "file_complete label={} bytes={} elapsed_ms={} rate={} retries={}",
                progress.label,
                progress.file_downloaded_bytes,
                progress.file_elapsed_ms,
                format_rate(progress.file_bytes_per_second),
                progress.file_retry_count
            ),
        );
    }

    if progress.complete {
        logging::log(
            "LLMDownload",
            format!(
                "complete bytes={} elapsed_ms={} rate={} retries={}",
                progress.downloaded_bytes,
                progress.elapsed_ms,
                format_rate(progress.bytes_per_second),
                progress.retry_count
            ),
        );
    }
}

fn format_bytes(bytes: u64) -> String {
    const UNITS: [&str; 5] = ["B", "KB", "MB", "GB", "TB"];
    let mut value = bytes as f64;
    let mut unit = 0usize;
    while value >= 1024.0 && unit < UNITS.len() - 1 {
        value /= 1024.0;
        unit += 1;
    }
    if unit == 0 {
        format!("{} {}", bytes, UNITS[unit])
    } else {
        format!("{value:.1} {}", UNITS[unit])
    }
}

fn format_rate(bytes_per_second: f64) -> String {
    if !bytes_per_second.is_finite() || bytes_per_second <= 0.0 {
        return "0 B/s".to_string();
    }
    format!("{}/s", format_bytes(bytes_per_second.round() as u64))
}

#[tauri::command]
pub async fn llm_init_backend() -> Result<(), ApiError> {
    logging::log("LLM", "init backend requested");
    async_runtime::spawn_blocking(|| {
        match catch_unwind(AssertUnwindSafe(inference::init_backend)) {
            Ok(result) => result.map_err(llm_error),
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_init_backend", &message);
                Err(ApiError::new(
                    "llm_panic",
                    format!("llm_init_backend panicked: {message}"),
                ))
            }
        }
    })
    .await
    .map_err(|err| {
        logging::log("LLM", format!("init backend join failed error={err}"));
        llm_thread_error()
    })??;
    logging::log("LLM", "init backend succeeded");
    Ok(())
}

#[tauri::command]
pub async fn llm_load_model(
    state: State<'_, LlmState>,
    params: inference::ModelLoadParams,
) -> Result<(), ApiError> {
    logging::log(
        "LLM",
        format!("load model requested model_path={}", params.model_path),
    );
    let model = async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| inference::load_model(params))) {
            Ok(result) => result.map_err(llm_error),
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_load_model", &message);
                Err(ApiError::new(
                    "llm_panic",
                    format!("llm_load_model panicked: {message}"),
                ))
            }
        }
    })
    .await
    .map_err(|err| {
        logging::log("LLM", format!("load model join failed error={err}"));
        llm_thread_error()
    })??;
    replace_llm_state(&state, Some(model), None)?;

    logging::log("LLM", "load model succeeded");
    Ok(())
}

#[tauri::command]
pub async fn llm_create_context(
    state: State<'_, LlmState>,
    params: inference::ContextParams,
) -> Result<(), ApiError> {
    let model = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_loaded", "Model not loaded"))?;

    let mut params = params;
    if params.n_threads.is_none() {
        params.n_threads = Some(default_llm_threads());
    }
    logging::log(
        "LLM",
        format!(
            "create context requested context_size={:?} n_threads={:?} n_batch={:?}",
            params.context_size, params.n_threads, params.n_batch
        ),
    );

    let context = async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| {
            inference::create_context(model, params)
        })) {
            Ok(result) => result.map_err(llm_error),
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_create_context", &message);
                Err(ApiError::new(
                    "llm_panic",
                    format!("llm_create_context panicked: {message}"),
                ))
            }
        }
    })
    .await
    .map_err(|err| {
        logging::log("LLM", format!("create context join failed error={err}"));
        llm_thread_error()
    })??;

    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    *context_guard = Some(context);

    logging::log("LLM", "create context succeeded");
    Ok(())
}

#[tauri::command]
pub fn llm_free_context(state: State<LlmState>) -> Result<(), ApiError> {
    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    *context_guard = None;
    Ok(())
}

#[tauri::command]
pub fn llm_free_model(state: State<LlmState>) -> Result<(), ApiError> {
    replace_llm_state(&state, None, None)
}

#[tauri::command]
pub async fn llm_prewarm_multimodal_context(
    state: State<'_, LlmState>,
    mmproj_path: String,
    media_marker: Option<String>,
) -> Result<(), ApiError> {
    let context = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_ready", "Model context not loaded"))?;

    logging::log(
        "LLM",
        format!("prewarm multimodal context requested mmproj_path={mmproj_path}"),
    );
    async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| {
            inference::prewarm_multimodal_context(context.as_ref(), mmproj_path, media_marker)
        })) {
            Ok(result) => result.map_err(llm_error),
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_prewarm_multimodal_context", &message);
                Err(ApiError::new(
                    "llm_panic",
                    format!("llm_prewarm_multimodal_context panicked: {message}"),
                ))
            }
        }
    })
    .await
    .map_err(|err| {
        logging::log("LLM", format!("prewarm multimodal join failed error={err}"));
        llm_thread_error()
    })??;
    logging::log("LLM", "prewarm multimodal context succeeded");
    Ok(())
}

#[tauri::command]
pub fn llm_generate_chat_stream(
    state: State<LlmState>,
    window: WebviewWindow,
    request: inference::GenerateChatRequest,
) -> Result<(), ApiError> {
    let context = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_ready", "Model context not loaded"))?;

    async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| {
            let mut sink = LlmEventSink::new(window.clone());
            let _ = inference::generate_chat_stream(context.as_ref(), request, &mut sink);
        })) {
            Ok(()) => {}
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_generate_chat_stream", &message);
                let _ = window.emit(
                    "llm-event",
                    LlmEvent::Error {
                        job_id: LLM_PANIC_JOB_ID,
                        message: format!("Generation panicked: {message}"),
                    },
                );
            }
        }
    });

    Ok(())
}

#[tauri::command]
pub fn llm_cancel(job_id: i64) -> Result<(), ApiError> {
    inference::cancel(job_id).map_err(llm_error)
}

pub(crate) fn clear_for_exit(app: &AppHandle) {
    if let Some(llm_state) = app.try_state::<LlmState>() {
        match replace_llm_state(&llm_state, None, None) {
            Ok(()) => {
                logging::log("App", "cleared LLM model");
                logging::log("App", "cleared LLM context");
            }
            Err(error) => {
                logging::log(
                    "App",
                    format!(
                        "failed to clear LLM state during exit error={}",
                        error.message
                    ),
                );
            }
        }
    } else {
        logging::log("App", "LLM state unavailable during exit");
    }
}
