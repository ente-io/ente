use std::fs;
use std::io::Read;

use tauri::async_runtime;

use crate::commands::common::ApiError;

fn fs_thread_error() -> ApiError {
    ApiError::new("io_thread", "FS task failed")
}

#[tauri::command]
pub async fn fs_file_size(path: String) -> Result<Option<u64>, ApiError> {
    async_runtime::spawn_blocking(move || match fs::metadata(&path) {
        Ok(metadata) => Ok(Some(metadata.len())),
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(err) => Err(ApiError::new("io", err.to_string())),
    })
    .await
    .map_err(|_| fs_thread_error())?
}

#[tauri::command]
pub async fn fs_read_head(path: String, length: usize) -> Result<Vec<u8>, ApiError> {
    async_runtime::spawn_blocking(move || {
        if length == 0 {
            return Ok(Vec::new());
        }
        let mut file = fs::File::open(&path).map_err(|err| ApiError::new("io", err.to_string()))?;
        let mut buffer = vec![0u8; length];
        let bytes_read = file
            .read(&mut buffer)
            .map_err(|err| ApiError::new("io", err.to_string()))?;
        buffer.truncate(bytes_read);
        Ok(buffer)
    })
    .await
    .map_err(|_| fs_thread_error())?
}
