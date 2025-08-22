use crate::crypto::{decrypt_chacha, secret_box_open};
use crate::models::{file::RemoteFile, collection::Collection};
use crate::Result;
use base64::{Engine, engine::general_purpose::STANDARD as BASE64};
use chrono::{Utc, TimeZone};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::PathBuf;

/// Processes files for export, handling decryption and path generation
pub struct FileProcessor {
    export_dir: PathBuf,
    collection_keys: HashMap<i64, Vec<u8>>,
}

impl FileProcessor {
    /// Create a new file processor
    pub fn new(export_dir: PathBuf) -> Self {
        Self {
            export_dir,
            collection_keys: HashMap::new(),
        }
    }

    /// Set collection keys for decryption
    pub fn set_collection_keys(&mut self, collections: &[Collection], master_key: &[u8]) -> Result<()> {
        for collection in collections {
            if let Some(encrypted_key) = &collection.encrypted_key {
                // Decrypt collection key using master key
                let key_bytes = BASE64.decode(encrypted_key)?;
                let nonce = BASE64.decode(collection.key_decryption_nonce.as_ref().unwrap_or(&String::new()))?;
                let collection_key = decrypt_chacha(&key_bytes, master_key, &nonce)?;
                self.collection_keys.insert(collection.id, collection_key);
            }
        }
        Ok(())
    }

    /// Process a file and determine its export path
    pub fn process_file(&self, file: &RemoteFile, collection: Option<&Collection>) -> Result<ProcessedFile> {
        log::trace!("Processing file {}", file.id);
        
        // Decrypt file metadata if available
        let metadata = if file.metadata.encrypted_data.is_some() {
            self.decrypt_file_metadata(file)?
        } else {
            FileMetadata::default()
        };
        
        // Determine file name
        let file_name = self.get_file_name(file, &metadata)?;
        
        // Build export path based on date and collection
        let export_path = self.build_export_path(file, &metadata, collection, &file_name)?;
        
        Ok(ProcessedFile {
            file_id: file.id,
            file_name,
            export_path,
            metadata,
            needs_download: !export_path.exists(),
        })
    }

    /// Decrypt file metadata
    fn decrypt_file_metadata(&self, file: &RemoteFile) -> Result<FileMetadata> {
        // Get collection key
        let collection_key = self.collection_keys.get(&file.collection_id)
            .ok_or_else(|| crate::Error::Crypto("Missing collection key".into()))?;
        
        // Get encrypted metadata
        let encrypted_data = file.metadata.encrypted_data.as_ref()
            .ok_or_else(|| crate::Error::Crypto("Missing encrypted metadata".into()))?;
        
        // Decode encrypted metadata
        let encrypted_bytes = BASE64.decode(encrypted_data)?;
        
        // Decrypt using collection key
        let decrypted = if let Some(ref header) = file.metadata.header {
            let nonce_bytes = BASE64.decode(header)?;
            decrypt_chacha(&encrypted_bytes, collection_key, &nonce_bytes)?
        } else if let Some(ref nonce) = file.key_decryption_nonce {
            // Legacy: use secret_box_open for older files
            let nonce_bytes = BASE64.decode(nonce)?;
            secret_box_open(&encrypted_bytes, &nonce_bytes, collection_key)?
        } else {
            return Err(crate::Error::Crypto("Missing decryption header".into()));
        };
        
        // Parse JSON metadata
        let metadata: FileMetadata = serde_json::from_slice(&decrypted)?;
        Ok(metadata)
    }

    /// Get file name from metadata or generate one
    fn get_file_name(&self, file: &RemoteFile, metadata: &FileMetadata) -> Result<String> {
        if let Some(ref title) = metadata.title {
            return Ok(title.clone());
        }
        
        // Fallback to ID-based name with extension
        let extension = self.get_extension(metadata.file_type.unwrap_or(0));
        Ok(format!("file_{}.{}", file.id, extension))
    }

    /// Get file extension based on file type
    fn get_extension(&self, file_type: i32) -> &str {
        match file_type {
            0 => "jpg",  // Image
            1 => "mp4",  // Video
            _ => "bin",  // Other/unknown
        }
    }

    /// Build the export path for a file
    fn build_export_path(
        &self,
        file: &RemoteFile,
        metadata: &FileMetadata,
        collection: Option<&Collection>,
        file_name: &str,
    ) -> Result<PathBuf> {
        // Start with export directory
        let mut path = self.export_dir.clone();
        
        // Add date-based directory structure (YYYY/MM-MonthName)
        let creation_time = metadata.creation_time
            .or(metadata.modification_time)
            .unwrap_or(file.updated_at);
        
        let datetime = Utc.timestamp_micros(creation_time).single()
            .ok_or_else(|| crate::Error::Generic("Invalid timestamp".into()))?;
        
        let year = datetime.format("%Y").to_string();
        let month = datetime.format("%m-%B").to_string(); // e.g., "01-January"
        
        path.push(year);
        path.push(month);
        
        // Add collection name if available and not default
        if let Some(col) = collection {
            if !col.name.is_empty() && col.name != "Uncategorized" {
                // Sanitize collection name for filesystem
                let safe_name = sanitize_filename(&col.name);
                path.push(safe_name);
            }
        }
        
        // Add file name
        path.push(file_name);
        
        Ok(path)
    }
}

/// Processed file information
#[derive(Debug)]
pub struct ProcessedFile {
    pub file_id: i64,
    pub file_name: String,
    pub export_path: PathBuf,
    pub metadata: FileMetadata,
    pub needs_download: bool,
}

/// Decrypted file metadata
#[derive(Debug, Default, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct FileMetadata {
    pub title: Option<String>,
    pub description: Option<String>,
    pub creation_time: Option<i64>,
    pub modification_time: Option<i64>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub file_type: Option<i32>,
    pub device_folder: Option<String>,
}

/// Sanitize a filename for safe filesystem usage
fn sanitize_filename(name: &str) -> String {
    name.chars()
        .map(|c| match c {
            '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
            c if c.is_control() => '_',
            c => c,
        })
        .collect::<String>()
        .trim()
        .to_string()
}