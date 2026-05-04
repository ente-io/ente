use std::fs;
use std::fs::File;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

use flate2::read::GzDecoder;
use reqwest::blocking::Client;
use reqwest::header::RANGE;
use tar::Archive;

use crate::{Result, error};

const MODEL_URL: &str = "https://models.ente.io/parakeet-v3-int8.tar.gz";
const MODEL_DIR_NAME: &str = "parakeet-tdt-0.6b-v3-int8";
const MODEL_SIZE_MB: u64 = 478;

#[derive(Debug, Clone)]
pub enum ModelEvent {
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

pub fn is_model_downloaded(models_dir: impl AsRef<Path>) -> bool {
    model_path(models_dir).is_dir()
}

pub fn model_path(models_dir: impl AsRef<Path>) -> PathBuf {
    models_dir.as_ref().join(MODEL_DIR_NAME)
}

pub fn model_size_mb() -> u64 {
    MODEL_SIZE_MB
}

pub fn download_model(
    models_dir: impl AsRef<Path>,
    mut on_event: impl FnMut(ModelEvent),
) -> Result<PathBuf> {
    let models_dir = models_dir.as_ref();
    fs::create_dir_all(models_dir)?;

    let final_model_dir = model_path(models_dir);
    let partial_path = models_dir.join(format!("{MODEL_DIR_NAME}.partial"));
    let extracting_path = models_dir.join(format!("{MODEL_DIR_NAME}.extracting"));

    if final_model_dir.is_dir() {
        let _ = fs::remove_file(&partial_path);
        on_event(ModelEvent::DownloadComplete);
        return Ok(final_model_dir);
    }

    if extracting_path.exists() {
        let _ = fs::remove_dir_all(&extracting_path);
    }

    let client = Client::builder().build()?;
    let mut resume_from = partial_path.metadata().map(|m| m.len()).unwrap_or(0);
    let mut response = request_model(&client, resume_from)?;

    if resume_from > 0 && response.status() == reqwest::StatusCode::OK {
        let _ = fs::remove_file(&partial_path);
        resume_from = 0;
        response = request_model(&client, 0)?;
    }

    if !response.status().is_success() && response.status() != reqwest::StatusCode::PARTIAL_CONTENT
    {
        let message = format!(
            "Failed to download transcription model: HTTP {}",
            response.status()
        );
        on_event(ModelEvent::DownloadError {
            message: message.clone(),
        });
        return Err(error(message));
    }

    let total = response
        .content_length()
        .map(|len| len + resume_from)
        .unwrap_or(0);
    let mut downloaded = resume_from;
    let mut file = if resume_from > 0 {
        fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&partial_path)?
    } else {
        File::create(&partial_path)?
    };

    on_event(ModelEvent::DownloadProgress {
        downloaded,
        total,
        percentage: percentage(downloaded, total),
    });

    let mut last_update = Instant::now();
    let mut buffer = [0u8; 128 * 1024];
    loop {
        let read = response.read(&mut buffer)?;
        if read == 0 {
            break;
        }
        file.write_all(&buffer[..read])?;
        downloaded += read as u64;

        if last_update.elapsed() >= Duration::from_millis(250) {
            on_event(ModelEvent::DownloadProgress {
                downloaded,
                total,
                percentage: percentage(downloaded, total),
            });
            last_update = Instant::now();
        }
    }
    file.flush()?;
    drop(file);

    if total > 0 {
        let actual = partial_path.metadata()?.len();
        if actual != total {
            let _ = fs::remove_file(&partial_path);
            let message = format!("Download incomplete: expected {total} bytes, got {actual}");
            on_event(ModelEvent::DownloadError {
                message: message.clone(),
            });
            return Err(error(message));
        }
    }

    on_event(ModelEvent::ExtractionStarted);
    extract_archive(&partial_path, &extracting_path, &final_model_dir).map_err(|err| {
        let _ = fs::remove_dir_all(&extracting_path);
        let message = err.to_string();
        on_event(ModelEvent::DownloadError {
            message: message.clone(),
        });
        error(message)
    })?;

    let _ = fs::remove_file(&partial_path);
    on_event(ModelEvent::ExtractionCompleted);
    on_event(ModelEvent::DownloadComplete);

    Ok(final_model_dir)
}

fn request_model(
    client: &Client,
    resume_from: u64,
) -> reqwest::Result<reqwest::blocking::Response> {
    let mut request = client.get(MODEL_URL);
    if resume_from > 0 {
        request = request.header(RANGE, format!("bytes={resume_from}-"));
    }
    request.send()
}

fn extract_archive(
    archive_path: &Path,
    extracting_path: &Path,
    final_model_dir: &Path,
) -> Result<()> {
    if extracting_path.exists() {
        fs::remove_dir_all(extracting_path)?;
    }
    fs::create_dir_all(extracting_path)?;

    let tar_gz = File::open(archive_path)?;
    let tar = GzDecoder::new(tar_gz);
    let mut archive = Archive::new(tar);
    archive.unpack(extracting_path)?;

    let extracted_dirs = fs::read_dir(extracting_path)?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            entry
                .file_type()
                .map(|file_type| file_type.is_dir())
                .unwrap_or(false)
        })
        .collect::<Vec<_>>();

    if final_model_dir.exists() {
        fs::remove_dir_all(final_model_dir)?;
    }

    if extracted_dirs.len() == 1 {
        fs::rename(extracted_dirs[0].path(), final_model_dir)?;
        let _ = fs::remove_dir_all(extracting_path);
    } else {
        fs::rename(extracting_path, final_model_dir)?;
    }

    Ok(())
}

fn percentage(downloaded: u64, total: u64) -> f64 {
    if total == 0 {
        0.0
    } else {
        (downloaded as f64 / total as f64) * 100.0
    }
}
