use std::cell::RefCell;
use std::fs::{self, File, OpenOptions};
use std::io::{Error, ErrorKind, Read, Write};
use std::path::{Path, PathBuf};
use std::rc::Rc;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use futures_util::future::try_join_all;
use reqwest::header::{ACCEPT_RANGES, CONTENT_RANGE, ETAG, IF_RANGE, LAST_MODIFIED, RANGE};
use reqwest::{Client, Response, StatusCode};
use serde::{Deserialize, Serialize};
use tokio::runtime::Builder;
use tokio::time::timeout;

const MIN_GGUF_BYTES: u64 = 1024 * 1024;
const MAX_ATTEMPTS: usize = 3;
const RANGE_DOWNLOAD_CONCURRENCY: usize = 4;
const PROGRESS_INTERVAL: Duration = Duration::from_millis(250);
const CONNECT_TIMEOUT: Duration = Duration::from_secs(30);
const RESPONSE_START_TIMEOUT: Duration = Duration::from_secs(30);
const READ_STALL_TIMEOUT: Duration = Duration::from_secs(30);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmModelDownloadTarget {
    pub label: String,
    pub url: String,
    pub destination_path: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LlmModelDownloadProgress {
    pub label: String,
    pub downloaded_bytes: u64,
    pub total_bytes: Option<u64>,
    pub file_downloaded_bytes: u64,
    pub file_total_bytes: Option<u64>,
    pub percentage: f64,
    pub elapsed_ms: u64,
    pub bytes_per_second: f64,
    pub file_elapsed_ms: u64,
    pub file_bytes_per_second: f64,
    pub retry_count: u32,
    pub file_retry_count: u32,
    pub file_complete: bool,
    pub complete: bool,
}

#[derive(Debug, Clone, Copy, Default)]
struct DownloadProgressMetrics {
    elapsed_ms: u64,
    bytes_per_second: f64,
    file_elapsed_ms: u64,
    file_bytes_per_second: f64,
    retry_count: u32,
    file_retry_count: u32,
    file_complete: bool,
    complete: bool,
}

#[derive(Debug, Clone, Copy)]
struct FileDownloadProgress {
    downloaded_bytes: u64,
    total_bytes: Option<u64>,
    network_downloaded_bytes: u64,
    elapsed: Duration,
    retry_count: u32,
}

#[derive(Debug, Clone, Copy)]
struct FileDownloadReport {
    final_size: u64,
    network_downloaded_bytes: u64,
    elapsed: Duration,
    retry_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct DownloadMetadata {
    url: String,
    label: String,
    size_bytes: u64,
    etag: Option<String>,
    last_modified: Option<String>,
    downloaded_at_ms: u64,
}

#[derive(Debug, Clone)]
struct ResponseMetadata {
    etag: Option<String>,
    last_modified: Option<String>,
}

#[derive(Debug, Clone, Default)]
struct DownloadProbe {
    content_length: Option<u64>,
    supports_ranges: bool,
    response_metadata: Option<ResponseMetadata>,
}

#[derive(Debug, Clone, Copy)]
struct FileDownloadState {
    downloaded_bytes: u64,
    total_bytes: Option<u64>,
    network_downloaded_bytes: u64,
    elapsed: Duration,
    retry_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RangeDownloadMetadata {
    url: String,
    size_bytes: u64,
    etag: Option<String>,
    last_modified: Option<String>,
    ranges: Vec<RangeDownloadPartMetadata>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
struct RangeDownloadPartMetadata {
    start: u64,
    end: u64,
    complete: bool,
}

#[derive(Debug, Clone, Copy)]
struct RangePartState {
    downloaded_bytes: u64,
    network_downloaded_bytes: u64,
    retry_count: u32,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
struct ContentRange {
    start: u64,
    end: u64,
    total: Option<u64>,
}

pub fn download_llm_model_files(
    targets: Vec<LlmModelDownloadTarget>,
    on_progress: impl FnMut(LlmModelDownloadProgress),
    is_cancelled: impl Fn() -> bool,
) -> Result<(), String> {
    let runtime = Builder::new_current_thread()
        .enable_io()
        .enable_time()
        .build()
        .map_err(|err| err.to_string())?;
    runtime.block_on(download_llm_model_files_async(
        targets,
        on_progress,
        is_cancelled,
    ))
}

async fn download_llm_model_files_async(
    targets: Vec<LlmModelDownloadTarget>,
    on_progress: impl FnMut(LlmModelDownloadProgress),
    is_cancelled: impl Fn() -> bool,
) -> Result<(), String> {
    if targets.is_empty() {
        return Ok(());
    }

    let client = Client::builder()
        .connect_timeout(CONNECT_TIMEOUT)
        .build()
        .map_err(|err| err.to_string())?;
    let download_started_at = Instant::now();
    let mut download_probes = Vec::with_capacity(targets.len());

    for target in &targets {
        let destination = Path::new(&target.destination_path);
        if prepare_cached_download(target, destination) {
            download_probes.push(DownloadProbe {
                content_length: file_size(destination),
                supports_ranges: false,
                response_metadata: read_download_metadata(destination).map(|metadata| {
                    ResponseMetadata {
                        etag: metadata.etag,
                        last_modified: metadata.last_modified,
                    }
                }),
            });
        } else {
            download_probes.push(fetch_download_probe(&client, &target.url).await);
        }
    }

    let total_bytes = if download_probes
        .iter()
        .all(|probe| probe.content_length.is_some())
    {
        let total = download_probes
            .iter()
            .filter_map(|probe| probe.content_length)
            .sum::<u64>();
        (total > 0).then_some(total)
    } else {
        None
    };

    let file_states = targets
        .iter()
        .zip(&download_probes)
        .map(|(target, probe)| {
            let existing =
                existing_download_bytes(target, Path::new(&target.destination_path), probe);
            FileDownloadState {
                downloaded_bytes: probe
                    .content_length
                    .map_or(existing, |value| existing.min(value)),
                total_bytes: probe.content_length,
                network_downloaded_bytes: 0,
                elapsed: Duration::ZERO,
                retry_count: 0,
            }
        })
        .collect::<Vec<_>>();
    let file_states = Rc::new(RefCell::new(file_states));
    let on_progress = Rc::new(RefCell::new(on_progress));

    emit_progress_from_states(
        "Preparing downloads",
        total_bytes,
        DownloadProgressMetrics::default(),
        None,
        &file_states,
        &on_progress,
    );

    let mut downloads = Vec::new();

    for (index, target) in targets.iter().enumerate() {
        let destination = PathBuf::from(&target.destination_path);
        if destination.exists() && is_valid_gguf_download(&destination) {
            continue;
        }

        let download_probe = download_probes
            .get(index)
            .cloned()
            .unwrap_or_else(DownloadProbe::default);
        let expected_file_total = download_probe.content_length;
        let progress_states = Rc::clone(&file_states);
        let progress_callback = Rc::clone(&on_progress);
        let target_label = target.label.clone();
        let download_started_at = download_started_at;
        let client = &client;
        let is_cancelled = &is_cancelled;

        downloads.push(async move {
            if is_cancelled() {
                return Err("Download cancelled".to_string());
            }

            let file_report = download_llm_model_file(
                client,
                target,
                &destination,
                &download_probe,
                |file_progress| {
                    {
                        let mut states = progress_states.borrow_mut();
                        if let Some(state) = states.get_mut(index) {
                            state.downloaded_bytes = file_progress.downloaded_bytes;
                            state.total_bytes = file_progress.total_bytes;
                            state.network_downloaded_bytes = file_progress.network_downloaded_bytes;
                            state.elapsed = file_progress.elapsed;
                            state.retry_count = file_progress.retry_count;
                        }
                    }

                    let metrics = aggregate_progress_metrics(
                        download_started_at.elapsed(),
                        &progress_states,
                        index,
                        false,
                        false,
                    );
                    emit_progress_from_states(
                        &target_label,
                        total_bytes,
                        metrics,
                        Some(index),
                        &progress_states,
                        &progress_callback,
                    );
                },
                is_cancelled,
            )
            .await?;

            {
                let mut states = progress_states.borrow_mut();
                if let Some(state) = states.get_mut(index) {
                    state.downloaded_bytes = file_report.final_size;
                    state.total_bytes = expected_file_total.or(Some(file_report.final_size));
                    state.network_downloaded_bytes = file_report.network_downloaded_bytes;
                    state.elapsed = file_report.elapsed;
                    state.retry_count = file_report.retry_count;
                }
            }

            let metrics = aggregate_progress_metrics(
                download_started_at.elapsed(),
                &progress_states,
                index,
                true,
                false,
            );
            emit_progress_from_states(
                &target_label,
                total_bytes,
                metrics,
                Some(index),
                &progress_states,
                &progress_callback,
            );

            Ok(file_report)
        });
    }

    let _reports = try_join_all(downloads).await?;
    let complete_metrics = aggregate_complete_metrics(download_started_at.elapsed(), &file_states);

    emit_progress_from_states(
        "Complete",
        total_bytes.or_else(|| Some(downloaded_bytes_from_states(&file_states))),
        complete_metrics,
        None,
        &file_states,
        &on_progress,
    );

    Ok(())
}

async fn download_llm_model_file(
    client: &Client,
    target: &LlmModelDownloadTarget,
    destination: &Path,
    download_probe: &DownloadProbe,
    mut on_progress: impl FnMut(FileDownloadProgress),
    is_cancelled: &impl Fn() -> bool,
) -> Result<FileDownloadReport, String> {
    let parent = destination
        .parent()
        .ok_or_else(|| format!("Invalid destination path: {}", destination.display()))?;
    fs::create_dir_all(parent).map_err(|err| err.to_string())?;

    let mut range_error = None;
    if let Some(total) = download_probe.content_length {
        if should_use_range_download(destination, total, download_probe) {
            match download_llm_model_file_ranged(
                client,
                target,
                destination,
                total,
                download_probe.response_metadata.clone(),
                &mut on_progress,
                is_cancelled,
            )
            .await
            {
                Ok(report) => return Ok(report),
                Err(err) if is_download_cancelled_error(&err) => return Err(err),
                Err(err) => {
                    range_error = Some(err);
                    cleanup_range_download(destination);
                }
            }
        } else if range_metadata_path_for(destination).exists() {
            cleanup_range_download(destination);
        }
    } else if range_metadata_path_for(destination).exists() {
        cleanup_range_download(destination);
    }

    let single_result = download_llm_model_file_single(
        client,
        target,
        destination,
        download_probe.content_length,
        &mut on_progress,
        is_cancelled,
    )
    .await;

    match (single_result, range_error) {
        (Ok(report), _) => Ok(report),
        (Err(single_error), Some(range_error)) => Err(format!(
            "{single_error}; range download fallback was used after: {range_error}"
        )),
        (Err(single_error), None) => Err(single_error),
    }
}

async fn download_llm_model_file_single(
    client: &Client,
    target: &LlmModelDownloadTarget,
    destination: &Path,
    expected_file_total: Option<u64>,
    on_progress: &mut dyn FnMut(FileDownloadProgress),
    is_cancelled: &impl Fn() -> bool,
) -> Result<FileDownloadReport, String> {
    let tmp_path = tmp_path_for(destination);
    let file_started_at = Instant::now();
    let mut network_downloaded_bytes = 0u64;
    let mut retry_count = 0u32;

    for attempt in 1..=MAX_ATTEMPTS {
        if is_cancelled() {
            return Err("Download cancelled".to_string());
        }

        let mut resume_from = valid_resume_bytes(&tmp_path)?;
        let mut response = match request_model(client, &target.url, resume_from).await {
            Ok(response) => response,
            Err(err) => {
                if attempt == MAX_ATTEMPTS {
                    return Err(format!("Failed to download {}: {}", target.label, err));
                }
                retry_count = retry_count.saturating_add(1);
                continue;
            }
        };

        if resume_from > 0 && response.status() == reqwest::StatusCode::OK {
            let _ = fs::remove_file(&tmp_path);
            resume_from = 0;
            response = match request_model(client, &target.url, 0).await {
                Ok(response) => response,
                Err(err) => {
                    if attempt == MAX_ATTEMPTS {
                        return Err(format!("Failed to download {}: {}", target.label, err));
                    }
                    retry_count = retry_count.saturating_add(1);
                    continue;
                }
            };
        }

        if !response.status().is_success() {
            if attempt == MAX_ATTEMPTS {
                return Err(format!(
                    "Failed to download {}: HTTP {}",
                    target.label,
                    response.status()
                ));
            }
            retry_count = retry_count.saturating_add(1);
            continue;
        }

        let response_metadata = response_metadata(&response);
        let file_total = content_total(&response, resume_from).or(expected_file_total);
        if let Some(total) = file_total {
            if total <= resume_from {
                let _ = fs::remove_file(&tmp_path);
                retry_count = retry_count.saturating_add(1);
                continue;
            }
        }

        let append = resume_from > 0 && response.status() == reqwest::StatusCode::PARTIAL_CONTENT;
        let mut file = OpenOptions::new()
            .create(true)
            .write(true)
            .append(append)
            .truncate(!append)
            .open(&tmp_path)
            .map_err(|err| err.to_string())?;

        let mut downloaded = resume_from;
        let mut first_bytes = if resume_from == 0 {
            Vec::with_capacity(4)
        } else {
            Vec::new()
        };
        let mut last_progress = Instant::now();
        let mut retry_attempt = false;

        on_progress(FileDownloadProgress {
            downloaded_bytes: downloaded,
            total_bytes: file_total,
            network_downloaded_bytes,
            elapsed: file_started_at.elapsed(),
            retry_count,
        });

        loop {
            if is_cancelled() {
                file.flush().ok();
                return Err("Download cancelled".to_string());
            }

            let chunk = match timeout(READ_STALL_TIMEOUT, response.chunk()).await {
                Ok(Ok(chunk)) => chunk,
                Ok(Err(err)) => {
                    file.flush().ok();
                    if attempt == MAX_ATTEMPTS {
                        return Err(format!("Failed to download {}: {}", target.label, err));
                    }
                    retry_count = retry_count.saturating_add(1);
                    retry_attempt = true;
                    break;
                }
                Err(_) => {
                    file.flush().ok();
                    if attempt == MAX_ATTEMPTS {
                        return Err(format!(
                            "Failed to download {}: stalled for {} seconds",
                            target.label,
                            READ_STALL_TIMEOUT.as_secs()
                        ));
                    }
                    retry_count = retry_count.saturating_add(1);
                    retry_attempt = true;
                    break;
                }
            };
            let Some(chunk) = chunk else {
                break;
            };

            if downloaded < 4 {
                let needed = 4usize.saturating_sub(first_bytes.len());
                first_bytes.extend_from_slice(&chunk[..chunk.len().min(needed)]);
                if first_bytes.len() == 4 && !is_gguf_header(&first_bytes) {
                    let _ = fs::remove_file(&tmp_path);
                    return Err("Downloaded file is not GGUF".to_string());
                }
            }

            file.write_all(&chunk).map_err(|err| err.to_string())?;
            downloaded = downloaded.saturating_add(chunk.len() as u64);
            network_downloaded_bytes = network_downloaded_bytes.saturating_add(chunk.len() as u64);

            if last_progress.elapsed() >= PROGRESS_INTERVAL {
                on_progress(FileDownloadProgress {
                    downloaded_bytes: downloaded,
                    total_bytes: file_total,
                    network_downloaded_bytes,
                    elapsed: file_started_at.elapsed(),
                    retry_count,
                });
                last_progress = Instant::now();
            }
        }

        if retry_attempt {
            drop(file);
            continue;
        }

        file.flush().map_err(|err| err.to_string())?;
        drop(file);

        on_progress(FileDownloadProgress {
            downloaded_bytes: downloaded,
            total_bytes: file_total,
            network_downloaded_bytes,
            elapsed: file_started_at.elapsed(),
            retry_count,
        });

        if let Some(total) = file_total {
            if downloaded < total {
                if attempt == MAX_ATTEMPTS {
                    return Err(format!(
                        "Download incomplete: expected {total} bytes, got {downloaded}"
                    ));
                }
                retry_count = retry_count.saturating_add(1);
                continue;
            }
        }

        if downloaded < MIN_GGUF_BYTES {
            let _ = fs::remove_file(&tmp_path);
            return Err("Downloaded file too small".to_string());
        }

        if !looks_like_gguf(&tmp_path) {
            let _ = fs::remove_file(&tmp_path);
            return Err("Downloaded file is not GGUF".to_string());
        }

        if destination.exists() {
            fs::remove_file(destination).map_err(|err| err.to_string())?;
        }
        fs::rename(&tmp_path, destination).map_err(|err| err.to_string())?;
        let _ = fs::remove_file(range_metadata_path_for(destination));

        let final_size = file_size(destination).unwrap_or(downloaded);
        if final_size != downloaded {
            let _ = fs::remove_file(destination);
            return Err(format!(
                "Downloaded file size mismatch ({final_size} != {downloaded})"
            ));
        }

        let _ = write_download_metadata(destination, target, final_size, Some(response_metadata));

        return Ok(FileDownloadReport {
            final_size,
            network_downloaded_bytes,
            elapsed: file_started_at.elapsed(),
            retry_count,
        });
    }

    Err("Failed to download model".to_string())
}

async fn download_llm_model_file_ranged(
    client: &Client,
    target: &LlmModelDownloadTarget,
    destination: &Path,
    total: u64,
    response_metadata: Option<ResponseMetadata>,
    on_progress: &mut dyn FnMut(FileDownloadProgress),
    is_cancelled: &impl Fn() -> bool,
) -> Result<FileDownloadReport, String> {
    let tmp_path = tmp_path_for(destination);
    let range_metadata_path = range_metadata_path_for(destination);
    let file_started_at = Instant::now();
    let range_metadata =
        prepare_range_download_metadata(target, destination, total, response_metadata.clone())?;

    let file = OpenOptions::new()
        .create(true)
        .read(true)
        .write(true)
        .open(&tmp_path)
        .map_err(|err| err.to_string())?;
    file.set_len(total).map_err(|err| err.to_string())?;
    let file = Rc::new(file);

    let range_states = range_metadata
        .ranges
        .iter()
        .map(|range| RangePartState {
            downloaded_bytes: if range.complete {
                range_download_len(*range)
            } else {
                0
            },
            network_downloaded_bytes: 0,
            retry_count: 0,
        })
        .collect::<Vec<_>>();
    let range_states = Rc::new(RefCell::new(range_states));
    let range_metadata = Rc::new(RefCell::new(range_metadata));
    let on_progress = Rc::new(RefCell::new(on_progress));

    emit_range_file_progress(total, file_started_at, &range_states, &on_progress);

    let mut downloads = Vec::new();
    {
        let metadata = range_metadata.borrow();
        for (part_index, range) in metadata.ranges.iter().copied().enumerate() {
            if range.complete {
                continue;
            }

            let file = Rc::clone(&file);
            let range_states = Rc::clone(&range_states);
            let range_metadata = Rc::clone(&range_metadata);
            let range_metadata_path = range_metadata_path.clone();
            let response_metadata = response_metadata.clone();
            let on_progress = Rc::clone(&on_progress);

            downloads.push(async move {
                download_range_part(
                    client,
                    target,
                    file,
                    part_index,
                    range,
                    total,
                    response_metadata,
                    range_states,
                    range_metadata,
                    range_metadata_path,
                    file_started_at,
                    on_progress,
                    is_cancelled,
                )
                .await
            });
        }
    }

    try_join_all(downloads).await?;
    drop(file);

    emit_range_file_progress(total, file_started_at, &range_states, &on_progress);

    if total < MIN_GGUF_BYTES {
        let _ = fs::remove_file(&tmp_path);
        let _ = fs::remove_file(&range_metadata_path);
        return Err("Downloaded file too small".to_string());
    }

    if !looks_like_gguf(&tmp_path) {
        let _ = fs::remove_file(&tmp_path);
        let _ = fs::remove_file(&range_metadata_path);
        return Err("Downloaded file is not GGUF".to_string());
    }

    if destination.exists() {
        fs::remove_file(destination).map_err(|err| err.to_string())?;
    }
    fs::rename(&tmp_path, destination).map_err(|err| err.to_string())?;
    let _ = fs::remove_file(&range_metadata_path);

    let final_size = file_size(destination).unwrap_or(total);
    if final_size != total {
        let _ = fs::remove_file(destination);
        return Err(format!(
            "Downloaded file size mismatch ({final_size} != {total})"
        ));
    }

    let network_downloaded_bytes = range_states
        .borrow()
        .iter()
        .map(|state| state.network_downloaded_bytes)
        .sum::<u64>();
    let retry_count = range_states
        .borrow()
        .iter()
        .map(|state| state.retry_count)
        .fold(0u32, u32::saturating_add);
    let elapsed = file_started_at.elapsed();
    let _ = write_download_metadata(destination, target, final_size, response_metadata);

    Ok(FileDownloadReport {
        final_size,
        network_downloaded_bytes,
        elapsed,
        retry_count,
    })
}

#[allow(clippy::too_many_arguments)]
async fn download_range_part(
    client: &Client,
    target: &LlmModelDownloadTarget,
    file: Rc<File>,
    part_index: usize,
    range: RangeDownloadPartMetadata,
    total: u64,
    response_metadata: Option<ResponseMetadata>,
    range_states: Rc<RefCell<Vec<RangePartState>>>,
    range_metadata: Rc<RefCell<RangeDownloadMetadata>>,
    range_metadata_path: PathBuf,
    file_started_at: Instant,
    on_progress: Rc<RefCell<&mut dyn FnMut(FileDownloadProgress)>>,
    is_cancelled: &impl Fn() -> bool,
) -> Result<(), String> {
    let range_len = range_download_len(range);

    for attempt in 1..=MAX_ATTEMPTS {
        if is_cancelled() {
            return Err("Download cancelled".to_string());
        }

        {
            let mut states = range_states.borrow_mut();
            if let Some(state) = states.get_mut(part_index) {
                state.downloaded_bytes = 0;
            }
        }
        emit_range_file_progress(total, file_started_at, &range_states, &on_progress);

        let mut response =
            match request_model_range(client, &target.url, range, response_metadata.as_ref()).await
            {
                Ok(response) => response,
                Err(err) => {
                    if attempt == MAX_ATTEMPTS {
                        return Err(format!(
                            "Failed to download {} range: {}",
                            target.label, err
                        ));
                    }
                    increment_range_retry(&range_states, part_index);
                    emit_range_file_progress(total, file_started_at, &range_states, &on_progress);
                    continue;
                }
            };

        if response.status() != StatusCode::PARTIAL_CONTENT {
            if response.status() == StatusCode::OK
                || response.status() == StatusCode::RANGE_NOT_SATISFIABLE
            {
                return Err(format!(
                    "Failed to download {} range: HTTP {}",
                    target.label,
                    response.status()
                ));
            }
            if attempt == MAX_ATTEMPTS {
                return Err(format!(
                    "Failed to download {} range: HTTP {}",
                    target.label,
                    response.status()
                ));
            }
            increment_range_retry(&range_states, part_index);
            emit_range_file_progress(total, file_started_at, &range_states, &on_progress);
            continue;
        }

        validate_range_response(&response, range, total)?;

        let mut downloaded_in_range = 0u64;
        let mut first_bytes = if range.start == 0 {
            Vec::with_capacity(4)
        } else {
            Vec::new()
        };
        let mut last_progress = Instant::now();
        let mut retry_attempt = false;

        loop {
            if is_cancelled() {
                return Err("Download cancelled".to_string());
            }

            let chunk = match timeout(READ_STALL_TIMEOUT, response.chunk()).await {
                Ok(Ok(chunk)) => chunk,
                Ok(Err(err)) => {
                    if attempt == MAX_ATTEMPTS {
                        return Err(format!(
                            "Failed to download {} range: {}",
                            target.label, err
                        ));
                    }
                    increment_range_retry(&range_states, part_index);
                    retry_attempt = true;
                    break;
                }
                Err(_) => {
                    if attempt == MAX_ATTEMPTS {
                        return Err(format!(
                            "Failed to download {} range: stalled for {} seconds",
                            target.label,
                            READ_STALL_TIMEOUT.as_secs()
                        ));
                    }
                    increment_range_retry(&range_states, part_index);
                    retry_attempt = true;
                    break;
                }
            };
            let Some(chunk) = chunk else {
                break;
            };

            let chunk_len = chunk.len() as u64;
            if downloaded_in_range.saturating_add(chunk_len) > range_len {
                return Err(format!(
                    "Failed to download {} range: received more bytes than requested",
                    target.label
                ));
            }

            if range.start == 0 && downloaded_in_range < 4 {
                let needed = 4usize.saturating_sub(first_bytes.len());
                first_bytes.extend_from_slice(&chunk[..chunk.len().min(needed)]);
                if first_bytes.len() == 4 && !is_gguf_header(&first_bytes) {
                    return Err("Downloaded file is not GGUF".to_string());
                }
            }

            write_all_at(
                file.as_ref(),
                chunk.as_ref(),
                range.start + downloaded_in_range,
            )
            .map_err(|err| err.to_string())?;
            downloaded_in_range = downloaded_in_range.saturating_add(chunk_len);

            {
                let mut states = range_states.borrow_mut();
                if let Some(state) = states.get_mut(part_index) {
                    state.downloaded_bytes = downloaded_in_range;
                    state.network_downloaded_bytes =
                        state.network_downloaded_bytes.saturating_add(chunk_len);
                }
            }

            if last_progress.elapsed() >= PROGRESS_INTERVAL {
                emit_range_file_progress(total, file_started_at, &range_states, &on_progress);
                last_progress = Instant::now();
            }
        }

        if retry_attempt {
            emit_range_file_progress(total, file_started_at, &range_states, &on_progress);
            continue;
        }

        if downloaded_in_range != range_len {
            if attempt == MAX_ATTEMPTS {
                return Err(format!(
                    "Download incomplete: expected {range_len} bytes, got {downloaded_in_range}"
                ));
            }
            increment_range_retry(&range_states, part_index);
            emit_range_file_progress(total, file_started_at, &range_states, &on_progress);
            continue;
        }

        {
            let mut states = range_states.borrow_mut();
            if let Some(state) = states.get_mut(part_index) {
                state.downloaded_bytes = range_len;
            }
        }
        mark_range_complete(&range_metadata, &range_metadata_path, part_index)?;
        emit_range_file_progress(total, file_started_at, &range_states, &on_progress);
        return Ok(());
    }

    Err("Failed to download model range".to_string())
}

async fn request_model(client: &Client, url: &str, resume_from: u64) -> Result<Response, String> {
    let mut request = client.get(url);
    if resume_from > 0 {
        request = request.header(RANGE, format!("bytes={resume_from}-"));
    }
    timeout(RESPONSE_START_TIMEOUT, request.send())
        .await
        .map_err(|_| {
            format!(
                "request did not receive a response within {} seconds",
                RESPONSE_START_TIMEOUT.as_secs()
            )
        })?
        .map_err(|err| err.to_string())
}

async fn request_model_range(
    client: &Client,
    url: &str,
    range: RangeDownloadPartMetadata,
    response_metadata: Option<&ResponseMetadata>,
) -> Result<Response, String> {
    let mut request = client
        .get(url)
        .header(RANGE, format!("bytes={}-{}", range.start, range.end));
    if let Some(if_range) = if_range_header_value(response_metadata) {
        request = request.header(IF_RANGE, if_range);
    }
    timeout(RESPONSE_START_TIMEOUT, request.send())
        .await
        .map_err(|_| {
            format!(
                "request did not receive a response within {} seconds",
                RESPONSE_START_TIMEOUT.as_secs()
            )
        })?
        .map_err(|err| err.to_string())
}

async fn fetch_download_probe(client: &Client, url: &str) -> DownloadProbe {
    let response = timeout(RESPONSE_START_TIMEOUT, client.head(url).send())
        .await
        .ok()
        .and_then(Result::ok);
    let Some(response) = response else {
        return DownloadProbe::default();
    };
    if !response.status().is_success() {
        return DownloadProbe::default();
    }
    let content_length = response
        .content_length()
        .filter(|value| *value > 0)
        .or_else(|| {
            // HEAD responses have no body, so reqwest can report a semantic length of 0.
            response
                .headers()
                .get("Content-Length")
                .and_then(|value| value.to_str().ok())
                .and_then(|value| value.parse().ok())
                .filter(|value| *value > 0)
        });
    let supports_ranges = response
        .headers()
        .get(ACCEPT_RANGES)
        .and_then(|value| value.to_str().ok())
        .is_some_and(|value| value.eq_ignore_ascii_case("bytes"));

    DownloadProbe {
        content_length,
        supports_ranges,
        response_metadata: Some(response_metadata(&response)),
    }
}

fn should_use_range_download(destination: &Path, total: u64, probe: &DownloadProbe) -> bool {
    if total < MIN_GGUF_BYTES || !probe.supports_ranges {
        return false;
    }
    if range_metadata_path_for(destination).exists() {
        return true;
    }

    let tmp_path = tmp_path_for(destination);
    if tmp_path.exists() && valid_resume_bytes(&tmp_path).unwrap_or(0) > 0 {
        return false;
    }

    true
}

fn is_download_cancelled_error(err: &str) -> bool {
    err == "Download cancelled"
}

fn prepare_range_download_metadata(
    target: &LlmModelDownloadTarget,
    destination: &Path,
    total: u64,
    response_metadata: Option<ResponseMetadata>,
) -> Result<RangeDownloadMetadata, String> {
    let tmp_path = tmp_path_for(destination);
    let ranges = range_download_parts(total, RANGE_DOWNLOAD_CONCURRENCY);

    if tmp_path.exists() {
        if let Some(metadata) = read_range_download_metadata(destination) {
            if file_size(&tmp_path) == Some(total)
                && range_download_metadata_matches(
                    &metadata,
                    target,
                    total,
                    response_metadata.as_ref(),
                    &ranges,
                )
            {
                return Ok(metadata);
            }
        }
    }

    cleanup_range_download(destination);
    let metadata = RangeDownloadMetadata {
        url: target.url.clone(),
        size_bytes: total,
        etag: response_metadata
            .as_ref()
            .and_then(|metadata| metadata.etag.clone()),
        last_modified: response_metadata
            .as_ref()
            .and_then(|metadata| metadata.last_modified.clone()),
        ranges,
    };
    write_range_download_metadata(&range_metadata_path_for(destination), &metadata)?;
    Ok(metadata)
}

fn range_download_parts(total: u64, concurrency: usize) -> Vec<RangeDownloadPartMetadata> {
    if total == 0 || concurrency == 0 {
        return Vec::new();
    }

    let max_parts = usize::try_from(total).unwrap_or(concurrency);
    let part_count = concurrency.min(max_parts).max(1);
    let part_count_u64 = part_count as u64;
    let base_len = total / part_count_u64;
    let remainder = total % part_count_u64;
    let mut start = 0u64;
    let mut ranges = Vec::with_capacity(part_count);

    for index in 0..part_count {
        let len = base_len + if (index as u64) < remainder { 1 } else { 0 };
        let end = start + len - 1;
        ranges.push(RangeDownloadPartMetadata {
            start,
            end,
            complete: false,
        });
        start = end + 1;
    }

    ranges
}

fn range_download_metadata_matches(
    metadata: &RangeDownloadMetadata,
    target: &LlmModelDownloadTarget,
    total: u64,
    response_metadata: Option<&ResponseMetadata>,
    ranges: &[RangeDownloadPartMetadata],
) -> bool {
    metadata.url == target.url
        && metadata.size_bytes == total
        && range_download_validators_match(metadata, response_metadata)
        && metadata.ranges.len() == ranges.len()
        && metadata
            .ranges
            .iter()
            .zip(ranges)
            .all(|(left, right)| left.start == right.start && left.end == right.end)
}

fn range_download_validators_match(
    metadata: &RangeDownloadMetadata,
    response_metadata: Option<&ResponseMetadata>,
) -> bool {
    let Some(response_metadata) = response_metadata else {
        return metadata.etag.is_none() && metadata.last_modified.is_none();
    };

    if let Some(expected_etag) = response_metadata.etag.as_deref() {
        return metadata.etag.as_deref() == Some(expected_etag);
    }
    if let Some(expected_last_modified) = response_metadata.last_modified.as_deref() {
        return metadata.last_modified.as_deref() == Some(expected_last_modified);
    }

    metadata.etag.is_none() && metadata.last_modified.is_none()
}

fn range_download_len(range: RangeDownloadPartMetadata) -> u64 {
    range.end.saturating_sub(range.start).saturating_add(1)
}

fn emit_range_file_progress(
    total_bytes: u64,
    file_started_at: Instant,
    range_states: &Rc<RefCell<Vec<RangePartState>>>,
    on_progress: &Rc<RefCell<&mut dyn FnMut(FileDownloadProgress)>>,
) {
    let states = range_states.borrow();
    let downloaded_bytes = states
        .iter()
        .map(|state| state.downloaded_bytes)
        .sum::<u64>()
        .min(total_bytes);
    let network_downloaded_bytes = states
        .iter()
        .map(|state| state.network_downloaded_bytes)
        .sum::<u64>();
    let retry_count = states
        .iter()
        .map(|state| state.retry_count)
        .fold(0u32, u32::saturating_add);
    drop(states);

    let mut callback = on_progress.borrow_mut();
    (&mut **callback)(FileDownloadProgress {
        downloaded_bytes,
        total_bytes: Some(total_bytes),
        network_downloaded_bytes,
        elapsed: file_started_at.elapsed(),
        retry_count,
    });
}

fn increment_range_retry(range_states: &Rc<RefCell<Vec<RangePartState>>>, part_index: usize) {
    let mut states = range_states.borrow_mut();
    if let Some(state) = states.get_mut(part_index) {
        state.retry_count = state.retry_count.saturating_add(1);
    }
}

fn mark_range_complete(
    range_metadata: &Rc<RefCell<RangeDownloadMetadata>>,
    range_metadata_path: &Path,
    part_index: usize,
) -> Result<(), String> {
    let mut metadata = range_metadata.borrow_mut();
    if let Some(range) = metadata.ranges.get_mut(part_index) {
        range.complete = true;
    }
    write_range_download_metadata(range_metadata_path, &metadata)
}

fn validate_range_response(
    response: &Response,
    range: RangeDownloadPartMetadata,
    total: u64,
) -> Result<(), String> {
    let content_range = response
        .headers()
        .get(CONTENT_RANGE)
        .and_then(|value| value.to_str().ok())
        .and_then(parse_content_range)
        .ok_or_else(|| "Range response did not include a valid Content-Range".to_string())?;

    if content_range.start != range.start || content_range.end != range.end {
        return Err(format!(
            "Range response mismatch: expected {}-{}, got {}-{}",
            range.start, range.end, content_range.start, content_range.end
        ));
    }

    if let Some(content_total) = content_range.total {
        if content_total != total {
            return Err(format!(
                "Range response total mismatch: expected {total}, got {content_total}"
            ));
        }
    }

    if let Some(content_length) = response.content_length() {
        let expected_length = range_download_len(range);
        if content_length != expected_length {
            return Err(format!(
                "Range response length mismatch: expected {expected_length}, got {content_length}"
            ));
        }
    }

    Ok(())
}

fn if_range_header_value(response_metadata: Option<&ResponseMetadata>) -> Option<String> {
    response_metadata.and_then(|metadata| {
        metadata
            .etag
            .clone()
            .or_else(|| metadata.last_modified.clone())
    })
}

fn content_total(response: &Response, resume_from: u64) -> Option<u64> {
    let content_range_total = response
        .headers()
        .get(CONTENT_RANGE)
        .and_then(|value| value.to_str().ok())
        .and_then(parse_content_range_total);
    let content_length = response.content_length().filter(|value| *value > 0);

    content_range_total.or_else(|| {
        if resume_from > 0 && response.status() == reqwest::StatusCode::PARTIAL_CONTENT {
            content_length.map(|value| value.saturating_add(resume_from))
        } else {
            content_length
        }
    })
}

fn parse_content_range_total(value: &str) -> Option<u64> {
    parse_content_range(value)?.total
}

fn parse_content_range(value: &str) -> Option<ContentRange> {
    let value = value.trim();
    let value = value.strip_prefix("bytes ")?;
    let (range, total) = value.split_once('/')?;
    let (start, end) = range.split_once('-')?;
    let start = start.parse().ok()?;
    let end = end.parse().ok()?;
    if end < start {
        return None;
    }
    let total = if total == "*" {
        None
    } else {
        Some(total.parse().ok()?)
    };

    Some(ContentRange { start, end, total })
}

fn emit_progress_from_states<F: FnMut(LlmModelDownloadProgress)>(
    label: &str,
    total_bytes: Option<u64>,
    metrics: DownloadProgressMetrics,
    file_index: Option<usize>,
    file_states: &Rc<RefCell<Vec<FileDownloadState>>>,
    on_progress: &Rc<RefCell<F>>,
) {
    let states = file_states.borrow();
    let downloaded_bytes = states
        .iter()
        .map(|state| state.downloaded_bytes)
        .sum::<u64>();
    let resolved_total_bytes = total_bytes.or_else(|| partial_total_from_states(&states));
    let (file_downloaded_bytes, file_total_bytes) = file_index
        .and_then(|index| states.get(index))
        .map(|state| (state.downloaded_bytes, state.total_bytes))
        .unwrap_or((0, None));
    drop(states);

    emit_combined_progress(
        label,
        downloaded_bytes,
        resolved_total_bytes,
        file_downloaded_bytes,
        file_total_bytes,
        metrics,
        &mut *on_progress.borrow_mut(),
    );
}

fn aggregate_progress_metrics(
    elapsed: Duration,
    file_states: &Rc<RefCell<Vec<FileDownloadState>>>,
    file_index: usize,
    file_complete: bool,
    complete: bool,
) -> DownloadProgressMetrics {
    let states = file_states.borrow();
    let network_downloaded_bytes = states
        .iter()
        .map(|state| state.network_downloaded_bytes)
        .sum::<u64>();
    let retry_count = states
        .iter()
        .map(|state| state.retry_count)
        .fold(0u32, u32::saturating_add);
    let file_state = states
        .get(file_index)
        .copied()
        .unwrap_or(FileDownloadState {
            downloaded_bytes: 0,
            total_bytes: None,
            network_downloaded_bytes: 0,
            elapsed: Duration::ZERO,
            retry_count: 0,
        });
    drop(states);

    progress_metrics(
        elapsed,
        network_downloaded_bytes,
        file_state.elapsed,
        file_state.network_downloaded_bytes,
        retry_count,
        file_state.retry_count,
        file_complete,
        complete,
    )
}

fn aggregate_complete_metrics(
    elapsed: Duration,
    file_states: &Rc<RefCell<Vec<FileDownloadState>>>,
) -> DownloadProgressMetrics {
    let states = file_states.borrow();
    let network_downloaded_bytes = states
        .iter()
        .map(|state| state.network_downloaded_bytes)
        .sum::<u64>();
    let retry_count = states
        .iter()
        .map(|state| state.retry_count)
        .fold(0u32, u32::saturating_add);
    drop(states);

    progress_metrics(
        elapsed,
        network_downloaded_bytes,
        Duration::ZERO,
        0,
        retry_count,
        0,
        false,
        true,
    )
}

fn downloaded_bytes_from_states(file_states: &Rc<RefCell<Vec<FileDownloadState>>>) -> u64 {
    file_states
        .borrow()
        .iter()
        .map(|state| state.downloaded_bytes)
        .sum()
}

fn partial_total_from_states(states: &[FileDownloadState]) -> Option<u64> {
    let total = states
        .iter()
        .filter_map(|state| state.total_bytes)
        .sum::<u64>();
    (total > 0).then_some(total)
}

fn emit_combined_progress(
    label: &str,
    downloaded_bytes: u64,
    total_bytes: Option<u64>,
    file_downloaded_bytes: u64,
    file_total_bytes: Option<u64>,
    metrics: DownloadProgressMetrics,
    on_progress: &mut impl FnMut(LlmModelDownloadProgress),
) {
    let percentage = total_bytes
        .filter(|value| *value > 0)
        .map(|total| ((downloaded_bytes as f64 / total as f64) * 100.0).clamp(0.0, 100.0))
        .unwrap_or(0.0);

    on_progress(LlmModelDownloadProgress {
        label: label.to_string(),
        downloaded_bytes,
        total_bytes,
        file_downloaded_bytes,
        file_total_bytes,
        percentage,
        elapsed_ms: metrics.elapsed_ms,
        bytes_per_second: metrics.bytes_per_second,
        file_elapsed_ms: metrics.file_elapsed_ms,
        file_bytes_per_second: metrics.file_bytes_per_second,
        retry_count: metrics.retry_count,
        file_retry_count: metrics.file_retry_count,
        file_complete: metrics.file_complete,
        complete: metrics.complete,
    });
}

fn progress_metrics(
    elapsed: Duration,
    downloaded_bytes: u64,
    file_elapsed: Duration,
    file_downloaded_bytes: u64,
    retry_count: u32,
    file_retry_count: u32,
    file_complete: bool,
    complete: bool,
) -> DownloadProgressMetrics {
    DownloadProgressMetrics {
        elapsed_ms: duration_ms(elapsed),
        bytes_per_second: bytes_per_second(downloaded_bytes, elapsed),
        file_elapsed_ms: duration_ms(file_elapsed),
        file_bytes_per_second: bytes_per_second(file_downloaded_bytes, file_elapsed),
        retry_count,
        file_retry_count,
        file_complete,
        complete,
    }
}

fn duration_ms(duration: Duration) -> u64 {
    u64::try_from(duration.as_millis()).unwrap_or(u64::MAX)
}

fn bytes_per_second(bytes: u64, elapsed: Duration) -> f64 {
    let seconds = elapsed.as_secs_f64();
    if seconds > 0.0 {
        bytes as f64 / seconds
    } else {
        0.0
    }
}

fn prepare_cached_download(target: &LlmModelDownloadTarget, destination: &Path) -> bool {
    if is_valid_gguf_download(destination) {
        if !download_metadata_matches(destination, &target.url) {
            let size = file_size(destination).unwrap_or(0);
            let _ = write_download_metadata(destination, target, size, None);
        }
        return true;
    }

    if let Some(source) = find_reusable_cached_download(destination, &target.url) {
        if copy_cached_download(&source, destination).is_ok() && is_valid_gguf_download(destination)
        {
            let size = file_size(destination).unwrap_or(0);
            let source_metadata =
                read_download_metadata(&source).map(|metadata| ResponseMetadata {
                    etag: metadata.etag,
                    last_modified: metadata.last_modified,
                });
            let _ = write_download_metadata(destination, target, size, source_metadata);
            return true;
        }
        let _ = fs::remove_file(destination);
        let _ = fs::remove_file(metadata_path_for(destination));
        let _ = fs::remove_file(range_metadata_path_for(destination));
    }

    false
}

fn find_reusable_cached_download(destination: &Path, url: &str) -> Option<PathBuf> {
    for root in cache_search_roots(destination) {
        let entries = match fs::read_dir(root) {
            Ok(entries) => entries,
            Err(_) => continue,
        };

        for entry in entries.flatten() {
            let path = entry.path();
            if path == destination || !path.is_file() || is_sidecar_download_file(&path) {
                continue;
            }
            if !is_valid_gguf_download(&path) {
                continue;
            }
            if download_metadata_matches(&path, url) {
                return Some(path);
            }
        }
    }

    None
}

fn cache_search_roots(destination: &Path) -> Vec<PathBuf> {
    let Some(parent) = destination.parent() else {
        return Vec::new();
    };

    let mut roots = vec![parent.to_path_buf()];
    if parent.file_name().and_then(|name| name.to_str()) == Some("custom") {
        if let Some(models_dir) = parent.parent() {
            roots.push(models_dir.to_path_buf());
        }
    } else {
        roots.push(parent.join("custom"));
    }
    roots
}

fn copy_cached_download(source: &Path, destination: &Path) -> Result<(), String> {
    let parent = destination
        .parent()
        .ok_or_else(|| format!("Invalid destination path: {}", destination.display()))?;
    fs::create_dir_all(parent).map_err(|err| err.to_string())?;

    let tmp_path = tmp_path_for(destination);
    let _ = fs::remove_file(&tmp_path);
    let _ = fs::remove_file(range_metadata_path_for(destination));
    fs::copy(source, &tmp_path).map_err(|err| err.to_string())?;
    if !is_valid_gguf_download(&tmp_path) {
        let _ = fs::remove_file(&tmp_path);
        return Err("Cached model copy is invalid".to_string());
    }
    if destination.exists() {
        fs::remove_file(destination).map_err(|err| err.to_string())?;
    }
    fs::rename(&tmp_path, destination).map_err(|err| err.to_string())
}

fn read_download_metadata(path: &Path) -> Option<DownloadMetadata> {
    let text = fs::read_to_string(metadata_path_for(path)).ok()?;
    serde_json::from_str(&text).ok()
}

fn download_metadata_matches(path: &Path, url: &str) -> bool {
    let Some(metadata) = read_download_metadata(path) else {
        return false;
    };
    let Some(size) = file_size(path) else {
        return false;
    };
    metadata.url == url && metadata.size_bytes == size && size >= MIN_GGUF_BYTES
}

fn write_download_metadata(
    path: &Path,
    target: &LlmModelDownloadTarget,
    size_bytes: u64,
    response_metadata: Option<ResponseMetadata>,
) -> Result<(), String> {
    let (etag, last_modified) = response_metadata
        .map(|metadata| (metadata.etag, metadata.last_modified))
        .unwrap_or((None, None));
    let metadata = DownloadMetadata {
        url: target.url.clone(),
        label: target.label.clone(),
        size_bytes,
        etag,
        last_modified,
        downloaded_at_ms: now_ms(),
    };
    let text = serde_json::to_string_pretty(&metadata).map_err(|err| err.to_string())?;
    fs::write(metadata_path_for(path), text).map_err(|err| err.to_string())
}

fn response_metadata(response: &Response) -> ResponseMetadata {
    ResponseMetadata {
        etag: response
            .headers()
            .get(ETAG)
            .and_then(|value| value.to_str().ok())
            .map(ToString::to_string),
        last_modified: response
            .headers()
            .get(LAST_MODIFIED)
            .and_then(|value| value.to_str().ok())
            .map(ToString::to_string),
    }
}

fn read_range_download_metadata(path: &Path) -> Option<RangeDownloadMetadata> {
    let text = fs::read_to_string(range_metadata_path_for(path)).ok()?;
    serde_json::from_str(&text).ok()
}

fn write_range_download_metadata(
    path: &Path,
    metadata: &RangeDownloadMetadata,
) -> Result<(), String> {
    let text = serde_json::to_string_pretty(metadata).map_err(|err| err.to_string())?;
    fs::write(path, text).map_err(|err| err.to_string())
}

fn metadata_path_for(path: &Path) -> PathBuf {
    PathBuf::from(format!("{}.metadata.json", path.display()))
}

fn range_metadata_path_for(path: &Path) -> PathBuf {
    PathBuf::from(format!("{}.tmp.ranges.json", path.display()))
}

fn cleanup_range_download(destination: &Path) {
    let _ = fs::remove_file(tmp_path_for(destination));
    let _ = fs::remove_file(range_metadata_path_for(destination));
}

fn is_sidecar_download_file(path: &Path) -> bool {
    let Some(name) = path.file_name().and_then(|name| name.to_str()) else {
        return false;
    };
    name.ends_with(".tmp") || name.ends_with(".metadata.json") || name.ends_with(".tmp.ranges.json")
}

fn now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| u64::try_from(duration.as_millis()).unwrap_or(u64::MAX))
        .unwrap_or(0)
}

fn existing_download_bytes(
    target: &LlmModelDownloadTarget,
    destination: &Path,
    probe: &DownloadProbe,
) -> u64 {
    if destination.exists() {
        return if is_valid_gguf_download(destination) {
            file_size(destination).unwrap_or(0)
        } else {
            0
        };
    }

    if range_metadata_path_for(destination).exists() {
        if let Some(total) = probe.content_length {
            let ranges = range_download_parts(total, RANGE_DOWNLOAD_CONCURRENCY);
            if let Some(metadata) = read_range_download_metadata(destination) {
                if file_size(&tmp_path_for(destination)) == Some(total)
                    && range_download_metadata_matches(
                        &metadata,
                        target,
                        total,
                        probe.response_metadata.as_ref(),
                        &ranges,
                    )
                {
                    return metadata
                        .ranges
                        .iter()
                        .filter(|range| range.complete)
                        .map(|range| range_download_len(*range))
                        .sum();
                }
            }
        }
        return 0;
    }

    let tmp_path = tmp_path_for(destination);
    valid_resume_bytes(&tmp_path).unwrap_or(0)
}

fn valid_resume_bytes(tmp_path: &Path) -> Result<u64, String> {
    if !tmp_path.exists() {
        return Ok(0);
    }

    let size = file_size(tmp_path).unwrap_or(0);
    if size == 0 {
        let _ = fs::remove_file(tmp_path);
        return Ok(0);
    }

    if size < 4 || !looks_like_gguf(tmp_path) {
        let _ = fs::remove_file(tmp_path);
        return Ok(0);
    }

    Ok(size)
}

fn file_size(path: &Path) -> Option<u64> {
    fs::metadata(path).ok().map(|metadata| metadata.len())
}

fn tmp_path_for(destination: &Path) -> PathBuf {
    PathBuf::from(format!("{}.tmp", destination.display()))
}

fn looks_like_gguf(path: &Path) -> bool {
    let mut file = match File::open(path) {
        Ok(file) => file,
        Err(_) => return false,
    };
    let mut header = [0u8; 4];
    file.read_exact(&mut header).is_ok() && is_gguf_header(&header)
}

fn is_gguf_header(bytes: &[u8]) -> bool {
    bytes == b"GGUF"
}

fn is_valid_gguf_download(path: &Path) -> bool {
    file_size(path).is_some_and(|size| size >= MIN_GGUF_BYTES) && looks_like_gguf(path)
}

#[cfg(unix)]
fn write_all_at(file: &File, mut bytes: &[u8], mut offset: u64) -> std::io::Result<()> {
    use std::os::unix::fs::FileExt;

    while !bytes.is_empty() {
        let written = file.write_at(bytes, offset)?;
        if written == 0 {
            return Err(Error::new(
                ErrorKind::WriteZero,
                "failed to write range bytes",
            ));
        }
        offset = offset.saturating_add(written as u64);
        bytes = &bytes[written..];
    }

    Ok(())
}

#[cfg(windows)]
fn write_all_at(file: &File, mut bytes: &[u8], mut offset: u64) -> std::io::Result<()> {
    use std::os::windows::fs::FileExt;

    while !bytes.is_empty() {
        let written = file.seek_write(bytes, offset)?;
        if written == 0 {
            return Err(Error::new(
                ErrorKind::WriteZero,
                "failed to write range bytes",
            ));
        }
        offset = offset.saturating_add(written as u64);
        bytes = &bytes[written..];
    }

    Ok(())
}

#[cfg(not(any(unix, windows)))]
fn write_all_at(file: &File, bytes: &[u8], offset: u64) -> std::io::Result<()> {
    use std::io::{Seek, SeekFrom};

    let mut file = file.try_clone()?;
    file.seek(SeekFrom::Start(offset))?;
    file.write_all(bytes)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{BufRead, BufReader};
    use std::net::{TcpListener, TcpStream};
    use std::sync::Arc;
    use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
    use std::thread;

    #[test]
    fn range_download_parts_split_file_into_four_ranges() {
        let ranges = range_download_parts(10, 4);

        assert_eq!(
            ranges,
            vec![
                RangeDownloadPartMetadata {
                    start: 0,
                    end: 2,
                    complete: false,
                },
                RangeDownloadPartMetadata {
                    start: 3,
                    end: 5,
                    complete: false,
                },
                RangeDownloadPartMetadata {
                    start: 6,
                    end: 7,
                    complete: false,
                },
                RangeDownloadPartMetadata {
                    start: 8,
                    end: 9,
                    complete: false,
                },
            ]
        );
        assert_eq!(
            ranges
                .iter()
                .map(|range| range_download_len(*range))
                .sum::<u64>(),
            10
        );
    }

    #[test]
    fn range_download_parts_do_not_create_empty_ranges() {
        let ranges = range_download_parts(3, 4);

        assert_eq!(ranges.len(), 3);
        assert!(ranges.iter().all(|range| range_download_len(*range) == 1));
    }

    #[test]
    fn parse_content_range_accepts_known_and_unknown_totals() {
        assert_eq!(
            parse_content_range("bytes 10-19/100"),
            Some(ContentRange {
                start: 10,
                end: 19,
                total: Some(100),
            })
        );
        assert_eq!(
            parse_content_range("bytes 10-19/*"),
            Some(ContentRange {
                start: 10,
                end: 19,
                total: None,
            })
        );
    }

    #[test]
    fn parse_content_range_rejects_invalid_ranges() {
        assert_eq!(parse_content_range("bytes 20-10/100"), None);
        assert_eq!(parse_content_range("items 10-19/100"), None);
        assert_eq!(parse_content_range("bytes 10-19/not-a-number"), None);
    }

    #[test]
    fn download_uses_four_ranges_when_server_supports_ranges() {
        let mut bytes = vec![0u8; MIN_GGUF_BYTES as usize + 123];
        bytes[..4].copy_from_slice(b"GGUF");
        for (index, byte) in bytes.iter_mut().enumerate().skip(4) {
            *byte = (index % 251) as u8;
        }
        let bytes = Arc::new(bytes);
        let head_count = Arc::new(AtomicUsize::new(0));
        let range_get_count = Arc::new(AtomicUsize::new(0));
        let full_get_count = Arc::new(AtomicUsize::new(0));
        let running = Arc::new(AtomicBool::new(true));

        let listener = TcpListener::bind("127.0.0.1:0").expect("bind test server");
        listener
            .set_nonblocking(true)
            .expect("configure test server");
        let address = listener.local_addr().expect("test server address");
        let server = {
            let bytes = Arc::clone(&bytes);
            let head_count = Arc::clone(&head_count);
            let range_get_count = Arc::clone(&range_get_count);
            let full_get_count = Arc::clone(&full_get_count);
            let running = Arc::clone(&running);
            thread::spawn(move || {
                while running.load(Ordering::SeqCst) {
                    match listener.accept() {
                        Ok((stream, _)) => {
                            stream.set_nonblocking(false).ok();
                            let bytes = Arc::clone(&bytes);
                            let head_count = Arc::clone(&head_count);
                            let range_get_count = Arc::clone(&range_get_count);
                            let full_get_count = Arc::clone(&full_get_count);
                            thread::spawn(move || {
                                handle_range_test_request(
                                    stream,
                                    bytes,
                                    head_count,
                                    range_get_count,
                                    full_get_count,
                                );
                            });
                        }
                        Err(err) if err.kind() == std::io::ErrorKind::WouldBlock => {
                            thread::sleep(Duration::from_millis(5));
                        }
                        Err(_) => break,
                    }
                }
            })
        };

        let test_dir = std::env::temp_dir().join(format!("ensu-range-download-test-{}", now_ms()));
        fs::create_dir_all(&test_dir).expect("create test dir");
        let destination = test_dir.join("model.gguf");
        let url = format!("http://{address}/model.gguf");

        let probe_client = Client::builder().build().expect("build probe client");
        let probe_runtime = Builder::new_current_thread()
            .enable_io()
            .enable_time()
            .build()
            .expect("build probe runtime");
        let probe = probe_runtime.block_on(fetch_download_probe(&probe_client, &url));
        assert_eq!(probe.content_length, Some(bytes.len() as u64));
        assert!(probe.supports_ranges);

        let result = download_llm_model_files(
            vec![LlmModelDownloadTarget {
                label: "Model".to_string(),
                url,
                destination_path: destination.display().to_string(),
            }],
            |_| {},
            || false,
        );

        running.store(false, Ordering::SeqCst);
        let _ = TcpStream::connect(address);
        server.join().expect("join test server");

        result.expect("range download succeeds");
        assert_eq!(
            fs::read(&destination).expect("read downloaded file"),
            *bytes
        );
        assert_eq!(head_count.load(Ordering::SeqCst), 2);
        assert_eq!(
            range_get_count.load(Ordering::SeqCst),
            RANGE_DOWNLOAD_CONCURRENCY,
            "full GET count: {}",
            full_get_count.load(Ordering::SeqCst)
        );
        assert_eq!(full_get_count.load(Ordering::SeqCst), 0);
        assert!(!range_metadata_path_for(&destination).exists());

        let _ = fs::remove_dir_all(test_dir);
    }

    fn handle_range_test_request(
        mut stream: TcpStream,
        bytes: Arc<Vec<u8>>,
        head_count: Arc<AtomicUsize>,
        range_get_count: Arc<AtomicUsize>,
        full_get_count: Arc<AtomicUsize>,
    ) {
        let mut reader = BufReader::new(stream.try_clone().expect("clone test stream"));
        let mut request_line = String::new();
        if reader.read_line(&mut request_line).is_err() {
            return;
        }

        let mut range_header = None;
        loop {
            let mut line = String::new();
            if reader.read_line(&mut line).is_err() || line == "\r\n" || line.is_empty() {
                break;
            }
            if let Some((name, value)) = line.split_once(':') {
                if name.eq_ignore_ascii_case("range") {
                    range_header = Some(value.trim().to_string());
                }
            }
        }

        if request_line.starts_with("HEAD ") {
            head_count.fetch_add(1, Ordering::SeqCst);
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nAccept-Ranges: bytes\r\nETag: \"test-etag\"\r\nConnection: close\r\n\r\n",
                bytes.len()
            );
            let _ = stream.write_all(response.as_bytes());
            return;
        }

        if let Some(range_header) = range_header {
            let Some((start, end)) = parse_test_range_header(&range_header, bytes.len() as u64)
            else {
                let _ = stream
                    .write_all(b"HTTP/1.1 416 Range Not Satisfiable\r\nConnection: close\r\n\r\n");
                return;
            };
            range_get_count.fetch_add(1, Ordering::SeqCst);
            let body = &bytes[start as usize..=end as usize];
            let response = format!(
                "HTTP/1.1 206 Partial Content\r\nContent-Length: {}\r\nContent-Range: bytes {}-{}/{}\r\nAccept-Ranges: bytes\r\nETag: \"test-etag\"\r\nConnection: close\r\n\r\n",
                body.len(),
                start,
                end,
                bytes.len()
            );
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.write_all(body);
        } else {
            full_get_count.fetch_add(1, Ordering::SeqCst);
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Length: {}\r\nAccept-Ranges: bytes\r\nETag: \"test-etag\"\r\nConnection: close\r\n\r\n",
                bytes.len()
            );
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.write_all(bytes.as_slice());
        }
    }

    fn parse_test_range_header(value: &str, total: u64) -> Option<(u64, u64)> {
        let value = value.strip_prefix("bytes=")?;
        let (start, end) = value.split_once('-')?;
        let start = start.parse().ok()?;
        let end = if end.is_empty() {
            total.checked_sub(1)?
        } else {
            end.parse().ok()?
        };
        if start > end || end >= total {
            return None;
        }
        Some((start, end))
    }
}
