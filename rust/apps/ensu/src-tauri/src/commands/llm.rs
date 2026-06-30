use std::panic::{AssertUnwindSafe, catch_unwind};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use ente_ensu::llm;
use serde::{Deserialize, Serialize};
use tauri::async_runtime;
use tauri::{AppHandle, Emitter, Manager, State as TauriState, WebviewWindow};

use crate::commands::common::{ApiError, log_command_panic, panic_message};
use crate::logging;

#[derive(Default)]
pub struct State {
    model: Mutex<Option<llm::ModelHandleRef>>,
    context: Mutex<Option<llm::ContextHandleRef>>,
}

pub struct ModelDownloadState {
    cancel_requested: Arc<AtomicBool>,
}

impl Default for ModelDownloadState {
    fn default() -> Self {
        Self {
            cancel_requested: Arc::new(AtomicBool::new(false)),
        }
    }
}

const PANIC_JOB_ID: i64 = 0;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DownloadRequest {
    label: String,
    url: String,
    path: String,
}

#[derive(Debug, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct DownloadProgress {
    label: String,
    percent: i32,
    status: String,
    bytes_downloaded: u64,
    total_bytes: Option<u64>,
    file_bytes_downloaded: u64,
    file_total_bytes: Option<u64>,
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

pub(crate) fn replace_state(
    state: &State,
    model: Option<llm::ModelHandleRef>,
    context: Option<llm::ContextHandleRef>,
) -> Result<(), ApiError> {
    let mut model_guard = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?;
    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;

    *model_guard = model;
    *context_guard = context;
    Ok(())
}

fn default_threads() -> i32 {
    let available = std::thread::available_parallelism()
        .map(|count| count.get())
        .unwrap_or(2);
    let half = available / 2;
    let threads = if half == 0 { 1 } else { half };
    i32::try_from(threads).unwrap_or(1)
}

#[derive(Serialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
enum Event {
    Text {
        job_id: llm::JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: llm::GenerationSummary,
    },
    Error {
        job_id: llm::JobId,
        message: String,
    },
}

impl From<llm::GenerationEvent> for Event {
    fn from(value: llm::GenerationEvent) -> Self {
        match value {
            llm::GenerationEvent::Text {
                job_id,
                text,
                token_id,
            } => Self::Text {
                job_id,
                text,
                token_id,
            },
            llm::GenerationEvent::Done { summary } => Self::Done { summary },
            llm::GenerationEvent::Error { job_id, message } => Self::Error { job_id, message },
        }
    }
}

const EVENT_BATCH_MS: u64 = 80;
const EVENT_BATCH_BYTES: usize = 2048;

struct EventSink {
    window: WebviewWindow,
    buffered_text: String,
    buffered_job_id: Option<llm::JobId>,
    buffered_token_id: Option<i32>,
    last_emit: Instant,
}

impl EventSink {
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
            let payload = Event::Text {
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

impl llm::EventSink for EventSink {
    fn add(&mut self, event: llm::GenerationEvent) {
        match event {
            llm::GenerationEvent::Text {
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
                if self.buffered_text.len() >= EVENT_BATCH_BYTES
                    || elapsed >= Duration::from_millis(EVENT_BATCH_MS)
                {
                    self.flush_text();
                }
            }
            llm::GenerationEvent::Done { summary } => {
                self.flush_text();
                let _ = self.window.emit("llm-event", Event::Done { summary });
            }
            llm::GenerationEvent::Error { job_id, message } => {
                self.flush_text();
                let _ = self
                    .window
                    .emit("llm-event", Event::Error { job_id, message });
            }
        }
    }
}

#[tauri::command]
pub async fn llm_download_model_files(
    window: WebviewWindow,
    state: TauriState<'_, ModelDownloadState>,
    downloads: Vec<DownloadRequest>,
) -> Result<(), ApiError> {
    let cancel_requested = Arc::clone(&state.cancel_requested);
    cancel_requested.store(false, Ordering::SeqCst);
    let targets = downloads
        .into_iter()
        .map(|download| llm::ModelDownloadTarget {
            label: download.label,
            url: download.url,
            destination_path: download.path,
        })
        .collect::<Vec<_>>();

    async_runtime::spawn_blocking(move || {
        let progress_window = window.clone();
        llm::download_model_files(
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
pub fn llm_cancel_model_download(state: TauriState<'_, ModelDownloadState>) {
    state.cancel_requested.store(true, Ordering::SeqCst);
}

fn tauri_download_progress(progress: llm::ModelDownloadProgress) -> DownloadProgress {
    let percent = if progress.total_bytes.is_some() {
        progress.percentage.round().clamp(0.0, 100.0) as i32
    } else {
        0
    };
    let status = download_progress_status(&progress);

    DownloadProgress {
        label: progress.label,
        percent,
        status,
        bytes_downloaded: progress.downloaded_bytes,
        total_bytes: progress.total_bytes,
        file_bytes_downloaded: progress.file_downloaded_bytes,
        file_total_bytes: progress.file_total_bytes,
    }
}

fn download_progress_status(progress: &llm::ModelDownloadProgress) -> String {
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

fn log_download_metrics(progress: &llm::ModelDownloadProgress) {
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
    async_runtime::spawn_blocking(|| match catch_unwind(AssertUnwindSafe(llm::init_backend)) {
        Ok(result) => result.map_err(llm_error),
        Err(payload) => {
            let message = panic_message(payload);
            log_command_panic("llm_init_backend", &message);
            Err(ApiError::new(
                "llm_panic",
                format!("llm_init_backend panicked: {message}"),
            ))
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
    state: TauriState<'_, State>,
    params: llm::ModelLoadParams,
) -> Result<(), ApiError> {
    logging::log(
        "LLM",
        format!("load model requested model_path={}", params.model_path),
    );
    let model = async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| llm::load_model(params))) {
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
    replace_state(&state, Some(model), None)?;

    logging::log("LLM", "load model succeeded");
    Ok(())
}

#[tauri::command]
pub async fn llm_create_context(
    state: TauriState<'_, State>,
    params: llm::ContextParams,
) -> Result<(), ApiError> {
    let model = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_loaded", "Model not loaded"))?;

    let mut params = params;
    if params.n_threads.is_none() {
        params.n_threads = Some(default_threads());
    }
    logging::log(
        "LLM",
        format!(
            "create context requested context_size={:?} n_threads={:?} n_batch={:?}",
            params.context_size, params.n_threads, params.n_batch
        ),
    );

    let context = async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| llm::create_context(model, params))) {
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
pub fn llm_free_context(state: TauriState<State>) -> Result<(), ApiError> {
    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    *context_guard = None;
    Ok(())
}

#[tauri::command]
pub fn llm_free_model(state: TauriState<State>) -> Result<(), ApiError> {
    replace_state(&state, None, None)
}

#[tauri::command]
pub async fn llm_prewarm_multimodal_context(
    state: TauriState<'_, State>,
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
            llm::prewarm_multimodal_context(context.as_ref(), mmproj_path, media_marker)
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
    state: TauriState<State>,
    window: WebviewWindow,
    request: llm::ChatRequest,
) -> Result<(), ApiError> {
    let context = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_ready", "Model context not loaded"))?;

    async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| {
            let mut sink = EventSink::new(window.clone());
            let _ = llm::generate_chat_stream(context.as_ref(), request, &mut sink);
        })) {
            Ok(()) => {}
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_generate_chat_stream", &message);
                let _ = window.emit(
                    "llm-event",
                    Event::Error {
                        job_id: PANIC_JOB_ID,
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
    llm::cancel(job_id).map_err(llm_error)
}

pub(crate) fn clear_for_exit(app: &AppHandle) {
    if let Some(state) = app.try_state::<State>() {
        match replace_state(&state, None, None) {
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
