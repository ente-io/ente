use crate::Result;
use crate::api::client::ApiClient;
use crate::api::methods::ApiMethods;
use crate::crypto::decrypt_chacha;
use crate::models::file::RemoteFile;
use crate::storage::Storage;
use base64::{Engine, engine::general_purpose::STANDARD as BASE64};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tokio::fs;
use tokio::io::AsyncWriteExt;

/// Manages file downloads with parallel processing and error recovery
pub struct DownloadManager {
    api_client: ApiClient,
    storage: Storage,
    temp_dir: PathBuf,
    collection_keys: HashMap<i64, Vec<u8>>,
    concurrent_downloads: usize,
}

impl DownloadManager {
    /// Create a new download manager
    pub fn new(api_client: ApiClient, storage: Storage) -> Result<Self> {
        let temp_dir = std::env::temp_dir().join("ente-downloads");
        std::fs::create_dir_all(&temp_dir)?;

        Ok(Self {
            api_client,
            storage,
            temp_dir,
            collection_keys: HashMap::new(),
            concurrent_downloads: 4, // Default concurrent downloads
        })
    }

    /// Set collection keys for file decryption
    pub fn set_collection_keys(&mut self, keys: HashMap<i64, Vec<u8>>) {
        self.collection_keys = keys;
    }

    /// Set number of concurrent downloads
    pub fn set_concurrent_downloads(&mut self, count: usize) {
        self.concurrent_downloads = count.max(1).min(10); // Limit between 1-10
    }

    /// Download a single file
    pub async fn download_file(
        &self,
        account_id: &str,
        file: &RemoteFile,
        destination: &Path,
    ) -> Result<()> {
        log::debug!("Downloading file {} to {:?}", file.id, destination);

        // Ensure destination directory exists
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent).await?;
        }

        // Check if file already exists
        if destination.exists() {
            log::debug!("File already exists at {:?}, skipping", destination);
            return Ok(());
        }

        // Download to temp file first
        let temp_path = self.temp_dir.join(format!("{}.tmp", file.id));

        // Get file data
        let api = ApiMethods::new(&self.api_client);
        let encrypted_data = api.download_file(account_id, file.id).await?;

        // Decrypt file
        let decrypted_data = self.decrypt_file_data(file, &encrypted_data)?;

        // Write to temp file
        let mut temp_file = fs::File::create(&temp_path).await?;
        temp_file.write_all(&decrypted_data).await?;
        temp_file.sync_all().await?;
        drop(temp_file);

        // Move to final destination
        fs::rename(&temp_path, destination).await?;

        // TODO: Update storage with local path
        // self.storage.sync().update_file_local_path(file.id, destination.to_str().unwrap())?;

        log::info!("Downloaded file {} to {:?}", file.id, destination);
        Ok(())
    }

    /// Download multiple files with concurrency control
    pub async fn download_files(
        &self,
        account_id: &str,
        files: Vec<(RemoteFile, PathBuf)>,
    ) -> Result<DownloadStats> {
        use futures::stream::{self, StreamExt};

        let total = files.len();
        log::info!("Starting download of {} files", total);

        let mut stats = DownloadStats {
            total,
            ..Default::default()
        };

        // Process files in parallel with concurrency limit
        let results: Vec<_> = stream::iter(files)
            .map(|(file, path)| {
                let account_id = account_id.to_string();
                async move {
                    let result = self.download_file(&account_id, &file, &path).await;
                    (file.id, result)
                }
            })
            .buffer_unordered(self.concurrent_downloads)
            .collect()
            .await;

        // Count results
        for (_file_id, result) in results {
            match result {
                Ok(_) => stats.successful += 1,
                Err(e) => {
                    log::error!("Download failed: {}", e);
                    stats.failed += 1;
                }
            }
        }

        log::info!(
            "Download completed: {} successful, {} failed",
            stats.successful,
            stats.failed
        );
        Ok(stats)
    }

    /// Download thumbnail for a file
    pub async fn download_thumbnail(
        &self,
        account_id: &str,
        file: &RemoteFile,
        destination: &Path,
    ) -> Result<()> {
        log::debug!(
            "Downloading thumbnail for file {} to {:?}",
            file.id,
            destination
        );

        // Ensure destination directory exists
        if let Some(parent) = destination.parent() {
            fs::create_dir_all(parent).await?;
        }

        // Get thumbnail data
        let api = ApiMethods::new(&self.api_client);
        let encrypted_data = api.download_thumbnail(account_id, file.id).await?;

        // Decrypt thumbnail
        let decrypted_data = self.decrypt_file_data(file, &encrypted_data)?;

        // Write to file
        let mut file_handle = fs::File::create(destination).await?;
        file_handle.write_all(&decrypted_data).await?;
        file_handle.sync_all().await?;

        log::debug!("Thumbnail downloaded for file {}", file.id);
        Ok(())
    }

    /// Decrypt file data using file key and collection key
    fn decrypt_file_data(&self, file: &RemoteFile, encrypted_data: &[u8]) -> Result<Vec<u8>> {
        // Get collection key
        let collection_key = self
            .collection_keys
            .get(&file.collection_id)
            .ok_or_else(|| {
                crate::Error::Crypto("Missing collection key for file decryption".into())
            })?;

        // Decrypt file key using collection key
        let file_key = {
            let key_bytes = BASE64.decode(&file.encrypted_key)?;
            let nonce = BASE64.decode(&file.key_decryption_nonce)?;
            decrypt_chacha(&key_bytes, collection_key, &nonce)?
        };

        // Decrypt file data using file key
        let file_nonce = BASE64.decode(&file.file.decryption_header)?;
        let decrypted = decrypt_chacha(encrypted_data, &file_key, &file_nonce)?;

        Ok(decrypted)
    }

    /// Resume a partial download (for future implementation)
    pub async fn resume_download(
        &self,
        _account_id: &str,
        _file: &RemoteFile,
        _destination: &Path,
        _offset: u64,
    ) -> Result<()> {
        // TODO: Implement resume functionality using Range headers
        todo!("Resume download not yet implemented")
    }

    /// Clean up temporary files
    pub async fn cleanup(&self) -> Result<()> {
        log::debug!("Cleaning up temporary download files");

        let mut entries = fs::read_dir(&self.temp_dir).await?;
        let mut count = 0;

        while let Some(entry) = entries.next_entry().await? {
            if entry.path().extension().and_then(|s| s.to_str()) == Some("tmp") {
                if let Err(e) = fs::remove_file(entry.path()).await {
                    log::warn!("Failed to remove temp file {:?}: {}", entry.path(), e);
                } else {
                    count += 1;
                }
            }
        }

        log::debug!("Cleaned up {} temporary files", count);
        Ok(())
    }
}

/// Statistics from download operations
#[derive(Debug, Default)]
pub struct DownloadStats {
    pub total: usize,
    pub successful: usize,
    pub failed: usize,
    pub skipped: usize,
}

impl DownloadStats {
    /// Check if all downloads were successful
    pub fn all_successful(&self) -> bool {
        self.failed == 0 && self.successful == self.total
    }

    /// Get success rate as percentage
    pub fn success_rate(&self) -> f64 {
        if self.total == 0 {
            100.0
        } else {
            (self.successful as f64 / self.total as f64) * 100.0
        }
    }
}
