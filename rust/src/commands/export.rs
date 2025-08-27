use crate::Result;
use crate::api::client::ApiClient;
use crate::api::methods::ApiMethods;
use crate::crypto::{decrypt_file_data, decrypt_stream, init as crypto_init, secret_box_open};
use crate::models::{account::Account, filter::ExportFilter, metadata::FileMetadata};
use crate::storage::Storage;
use crate::sync::SyncEngine;
use base64::Engine;
use std::collections::HashMap;
use std::io::Cursor;
use std::path::{Path, PathBuf};
use tokio::fs;
use tokio::io::AsyncWriteExt;

pub async fn run_export(account_email: Option<String>, filter: ExportFilter) -> Result<()> {
    // Initialize crypto
    crypto_init()?;

    // Open database
    let config_dir = crate::utils::get_cli_config_dir()?;
    let db_path = config_dir.join("ente.db");
    let storage = Storage::new(&db_path)?;

    // Get accounts to export
    let accounts = if let Some(email) = account_email {
        // Export specific account - try to find it with any app
        let all_accounts = storage.accounts().list()?;
        log::debug!("Found {} total accounts", all_accounts.len());
        let matching: Vec<Account> = all_accounts
            .into_iter()
            .filter(|a| a.email == email)
            .collect();

        if matching.is_empty() {
            return Err(crate::Error::NotFound(format!(
                "Account not found: {email}"
            )));
        }
        matching
    } else {
        // Export all accounts
        storage.accounts().list()?
    };

    if accounts.is_empty() {
        println!("No accounts configured. Use 'ente-rs account add' first.");
        return Ok(());
    }

    // Export each account
    for account in accounts {
        println!("\n=== Exporting account: {} ===", account.email);

        // First sync the account (like Go implementation does)
        println!("Syncing account data...");
        if let Err(e) = sync_account_before_export(&storage, &account).await {
            log::error!("Failed to sync account {}: {}", account.email, e);
            println!("❌ Sync failed: {e}");
            continue;
        }
        println!("✅ Sync completed!");

        if let Err(e) = export_account(&storage, &account, &filter).await {
            log::error!("Failed to export account {}: {}", account.email, e);
            println!("❌ Export failed: {e}");
        } else {
            println!("✅ Export completed successfully!");
        }
    }

    Ok(())
}

async fn sync_account_before_export(storage: &Storage, account: &Account) -> Result<()> {
    // Get stored secrets
    let secrets = storage
        .accounts()
        .get_secrets(account.user_id, account.app)?
        .ok_or_else(|| crate::Error::NotFound("Account secrets not found".into()))?;

    // Create API client with account's endpoint
    let api_client = ApiClient::new(Some(account.endpoint.clone()))?;

    // Store token for this account
    let token = base64::engine::general_purpose::URL_SAFE.encode(&secrets.token);
    api_client.add_token(&account.email, &token);

    // Get the database path to create a new Storage instance
    let db_path = storage
        .db_path()
        .ok_or_else(|| crate::Error::Generic("Database path not available".into()))?;

    // Create new Storage instance for sync engine (needed for ownership)
    let sync_storage = Storage::new(db_path)?;

    // Create sync engine
    let sync_engine = SyncEngine::new(api_client, sync_storage, account.clone());

    // Run sync for this account
    let stats = sync_engine.sync().await?;

    log::info!(
        "Sync completed: {} new collections, {} new files",
        stats.collections.new,
        stats.files.new
    );

    Ok(())
}

async fn export_account(storage: &Storage, account: &Account, filter: &ExportFilter) -> Result<()> {
    // Get export directory
    let export_dir = account
        .export_dir
        .as_ref()
        .ok_or_else(|| crate::Error::InvalidInput("No export directory configured".into()))?;
    let export_path = Path::new(export_dir);

    println!("Export directory: {export_dir}");

    // Create export directory if needed
    fs::create_dir_all(export_path).await?;

    // Track exported hashes for deduplication within this export session
    let mut exported_hashes: HashMap<String, PathBuf> = HashMap::new();

    // Get stored secrets
    let secrets = storage
        .accounts()
        .get_secrets(account.user_id, account.app)?
        .ok_or_else(|| crate::Error::NotFound("Account secrets not found".into()))?;

    // Create API client with account's endpoint
    let api_client = ApiClient::new(Some(account.endpoint.clone()))?;

    // Store token for this account
    // Token is stored as raw bytes from sealed_box_open
    // The Go CLI encodes it as base64 URL-encoded string WITH padding for the API
    let token = base64::engine::general_purpose::URL_SAFE.encode(&secrets.token);
    api_client.add_token(&account.email, &token);

    let api = ApiMethods::new(&api_client);

    // Fetch collections
    println!("\nFetching collections...");
    let collections = api.get_collections(&account.email, 0).await?;
    println!("Found {} collections", collections.len());

    // Master key is already raw bytes, no need to decode
    let master_key = &secrets.master_key;

    // We'll also need the secret key for decrypting collection keys
    let secret_key = &secrets.secret_key;

    // Fetch and export files for each collection
    println!("\nFetching files...");
    let mut total_files = 0;
    let mut exported_files = 0;
    let mut skipped_files = 0;
    let mut deleted_files = 0;

    for collection in &collections {
        // Skip deleted collections
        if collection.is_deleted {
            continue;
        }

        // Decrypt collection name to check filters
        let collection_name = if let Some(ref _encrypted_name) = collection.encrypted_name {
            // Decrypt collection name if needed for filtering
            // For now, we'll use the collection ID as a fallback
            // TODO: Implement proper name decryption
            format!("Collection {}", collection.id)
        } else {
            format!("Collection {}", collection.id)
        };

        // Apply collection filters
        // TODO: Determine if collection is shared or hidden from metadata
        let is_shared = false; // Need to check collection metadata
        let is_hidden = false; // Need to check collection metadata

        if !filter.should_include_collection(&collection_name, is_shared, is_hidden) {
            log::debug!("Skipping filtered collection: {}", collection_name);
            continue;
        }

        println!("Processing collection: {}", collection_name);

        // Decrypt collection key
        let collection_key = match decrypt_collection_key(
            &collection.encrypted_key,
            &collection.key_decryption_nonce,
            master_key,
            secret_key,
        ) {
            Ok(key) => key,
            Err(e) => {
                log::error!("Failed to decrypt collection key: {e}");
                continue;
            }
        };

        let mut has_more = true;
        let mut since_time = 0i64;

        while has_more {
            let (files, more) = api
                .get_collection_files(&account.email, collection.id, since_time)
                .await?;
            has_more = more;

            if files.is_empty() {
                break;
            }

            for file in files {
                // Skip deleted files
                if file.is_deleted {
                    deleted_files += 1;
                    continue;
                }

                // Count non-deleted files
                total_files += 1;

                // Update since_time for next batch
                if file.updation_time > since_time {
                    since_time = file.updation_time;
                }

                // Decrypt the file key using the collection key
                let file_key = match decrypt_file_key(
                    &file.encrypted_key,
                    &file.key_decryption_nonce,
                    &collection_key,
                ) {
                    Ok(key) => key,
                    Err(e) => {
                        log::error!("Failed to decrypt key for file {}: {}", file.id, e);
                        continue;
                    }
                };

                // Decrypt metadata to get original filename and hash
                let metadata = match decrypt_file_metadata(&file, &file_key) {
                    Ok(meta) => meta,
                    Err(e) => {
                        log::warn!("Failed to decrypt metadata for file {}: {}", file.id, e);
                        None
                    }
                };

                // Decrypt public magic metadata to check for edited name
                let pub_magic_metadata = if file.pub_magic_metadata.is_some() {
                    match decrypt_magic_metadata(
                        file.pub_magic_metadata.as_ref().unwrap(),
                        &file_key,
                    ) {
                        Ok(meta) => meta,
                        Err(e) => {
                            log::debug!(
                                "Failed to decrypt public magic metadata for file {}: {}",
                                file.id,
                                e
                            );
                            None
                        }
                    }
                } else {
                    None
                };

                // Check for deduplication by hash
                let content_hash = if let Some(ref meta) = metadata {
                    let hash = match meta.get_file_type() {
                        crate::models::metadata::FileType::Image => {
                            meta.image_hash.as_ref().or(meta.hash.as_ref())
                        }
                        crate::models::metadata::FileType::Video => {
                            meta.video_hash.as_ref().or(meta.hash.as_ref())
                        }
                        _ => meta.hash.as_ref(),
                    };
                    if let Some(h) = hash {
                        log::debug!("File {} has hash: {}", file.id, h);
                    } else {
                        log::debug!("File {} has no hash in metadata", file.id);
                    }
                    hash
                } else {
                    log::debug!("File {} has no metadata", file.id);
                    None
                };

                // Check if we've already exported a file with this hash
                if let Some(hash) = content_hash
                    && let Some(existing_path) = exported_hashes.get(hash)
                {
                    log::info!(
                        "Skipping duplicate file {} (same hash as {})",
                        file.id,
                        existing_path.display()
                    );
                    skipped_files += 1;
                    continue;
                }

                // Generate export path with original filename from metadata
                let file_path = generate_export_path(
                    export_path,
                    &file,
                    Some(collection),
                    metadata.as_ref(),
                    pub_magic_metadata.as_ref(),
                )?;

                // Skip if file already exists on disk
                if file_path.exists() {
                    log::debug!("File already exists: {file_path:?}");
                    skipped_files += 1;

                    // Add to hash map even for existing files to prevent duplicates
                    if let Some(hash) = content_hash {
                        exported_hashes.insert(hash.clone(), file_path.clone());
                    }
                    continue;
                }

                // Download and save file
                log::debug!("Downloading file {} to {:?}", file.id, file_path);

                // Ensure directory exists
                if let Some(parent) = file_path.parent() {
                    fs::create_dir_all(parent).await?;
                }

                // Download encrypted file
                let encrypted_data = api.download_file(&account.email, file.id).await?;

                // The file nonce/header is stored separately in the API response
                let file_nonce = match base64::engine::general_purpose::STANDARD
                    .decode(&file.file.decryption_header)
                {
                    Ok(nonce) => nonce,
                    Err(e) => {
                        log::error!("Failed to decode file nonce for file {}: {}", file.id, e);
                        continue;
                    }
                };

                // Decrypt the file data using streaming XChaCha20-Poly1305
                // Use chunked decryption for large files
                let decrypted = match decrypt_file_data(&encrypted_data, &file_nonce, &file_key) {
                    Ok(data) => data,
                    Err(e) => {
                        log::error!("Failed to decrypt file {}: {}", file.id, e);
                        log::debug!(
                            "File size: {}, header length: {}",
                            encrypted_data.len(),
                            file_nonce.len()
                        );
                        continue;
                    }
                };

                // Check if this is a live photo that needs extraction
                let is_live_photo = metadata
                    .as_ref()
                    .map(|m| m.is_live_photo())
                    .unwrap_or(false);

                if is_live_photo {
                    // Extract live photo components from ZIP
                    if let Err(e) = extract_live_photo(&decrypted, &file_path).await {
                        log::error!("Failed to extract live photo {}: {}", file.id, e);
                        // Fall back to saving as ZIP
                        let mut file_handle = fs::File::create(&file_path).await?;
                        file_handle.write_all(&decrypted).await?;
                        file_handle.sync_all().await?;
                    }
                } else {
                    // Write regular file
                    let mut file_handle = fs::File::create(&file_path).await?;
                    file_handle.write_all(&decrypted).await?;
                    file_handle.sync_all().await?;
                }

                exported_files += 1;

                // Add hash to deduplication map
                if let Some(hash) = content_hash {
                    exported_hashes.insert(hash.clone(), file_path.clone());
                }

                // Progress indicator - show every file for now since we have few files
                println!(
                    "  [{}] Exported: {}",
                    exported_files,
                    file_path.file_name().unwrap_or_default().to_string_lossy()
                );
            }
        }
    }

    println!("\n{}", "=".repeat(50));
    println!("Export Summary:");
    println!("{}", "=".repeat(50));
    println!("  📁 Total files (non-deleted): {total_files}");
    println!("  ✅ Successfully exported: {exported_files}");

    if skipped_files > 0 {
        println!("  ⏭️  Skipped (already exists): {skipped_files}");
    }

    if deleted_files > 0 {
        println!("  🗑️  Deleted files (skipped): {deleted_files}");
    }

    let failed = total_files - exported_files - skipped_files;
    if failed > 0 {
        println!("  ❌ Failed to export: {failed}");
    }

    if exported_files == total_files {
        println!("\n🎉 All files exported successfully!");
    } else if exported_files > 0 {
        println!("\n✨ Export completed with {exported_files} new files!");
    } else if skipped_files == total_files {
        println!("\n✨ All files already exported!");
    }

    Ok(())
}

fn generate_export_path(
    export_dir: &Path,
    file: &crate::api::models::File,
    collection: Option<&crate::api::models::Collection>,
    metadata: Option<&FileMetadata>,
    pub_magic_metadata: Option<&serde_json::Value>,
) -> Result<PathBuf> {
    use chrono::{TimeZone, Utc};

    // Start with export directory
    let mut path = export_dir.to_path_buf();

    // Add date-based directory structure (YYYY/MM-MonthName)
    // Use updation_time as creation time proxy
    let datetime = Utc
        .timestamp_micros(file.updation_time)
        .single()
        .ok_or_else(|| crate::Error::Generic("Invalid timestamp".into()))?;

    let year = datetime.format("%Y").to_string();
    let month = datetime.format("%m-%B").to_string(); // e.g., "01-January"

    path.push(year);
    path.push(month);

    // Add collection name if available
    if let Some(col) = collection
        && let Some(ref name) = col.name
        && !name.is_empty()
        && name != "Uncategorized"
    {
        // Sanitize collection name for filesystem
        let safe_name: String = name
            .chars()
            .map(|c| match c {
                '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
                c if c.is_control() => '_',
                c => c,
            })
            .collect::<String>()
            .trim()
            .to_string();
        path.push(safe_name);
    }

    // Use filename from public magic metadata (edited name) or regular metadata
    let filename = {
        // First check for edited name in public magic metadata
        if let Some(pub_meta) = pub_magic_metadata
            && let Some(edited_name) = pub_meta.get("editedName")
            && let Some(name_str) = edited_name.as_str()
            && !name_str.is_empty()
        {
            sanitize_filename(name_str)
        } else if let Some(meta) = metadata {
            // Fall back to original title from metadata
            if let Some(title) = meta.get_title() {
                sanitize_filename(title)
            } else {
                generate_fallback_filename(file, metadata)
            }
        } else {
            generate_fallback_filename(file, None)
        }
    };
    path.push(filename);

    Ok(path)
}

/// Decrypt a collection key using the master key
fn decrypt_collection_key(
    encrypted_key: &str,
    nonce: &str,
    master_key: &[u8],
    _secret_key: &[u8],
) -> Result<Vec<u8>> {
    use base64::engine::general_purpose::STANDARD as BASE64;

    let encrypted_bytes = BASE64.decode(encrypted_key)?;
    let nonce_bytes = BASE64.decode(nonce)?;

    // Collection keys are encrypted with secret_box (XSalsa20-Poly1305) using master key
    secret_box_open(&encrypted_bytes, &nonce_bytes, master_key)
}

/// Decrypt a file key using the collection key
fn decrypt_file_key(encrypted_key: &str, nonce: &str, collection_key: &[u8]) -> Result<Vec<u8>> {
    use base64::engine::general_purpose::STANDARD as BASE64;

    let encrypted_bytes = BASE64.decode(encrypted_key)?;
    let nonce_bytes = BASE64.decode(nonce)?;

    // File keys are encrypted with secret_box (XSalsa20-Poly1305) using collection key
    secret_box_open(&encrypted_bytes, &nonce_bytes, collection_key)
}

/// Generate a fallback filename when metadata is not available
fn generate_fallback_filename(
    file: &crate::api::models::File,
    metadata: Option<&FileMetadata>,
) -> String {
    let extension = if let Some(meta) = metadata {
        match meta.get_file_type() {
            crate::models::metadata::FileType::Image => ".jpg",
            crate::models::metadata::FileType::Video => ".mp4",
            crate::models::metadata::FileType::LivePhoto => ".zip",
            crate::models::metadata::FileType::Unknown => ".bin",
        }
    } else if file.thumbnail.size.unwrap_or(0) > 0 {
        ".jpg" // Has thumbnail, likely an image
    } else {
        ".bin"
    };

    format!("file_{}{}", file.id, extension)
}

/// Sanitize a filename for the filesystem
fn sanitize_filename(name: &str) -> String {
    name.chars()
        .map(|c| match c {
            '/' | '\\' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
            '\0' => '_',
            c if c.is_control() => '_',
            c => c,
        })
        .collect::<String>()
        .trim()
        .to_string()
}

/// Decrypt file metadata
fn decrypt_file_metadata(
    file: &crate::api::models::File,
    file_key: &[u8],
) -> Result<Option<FileMetadata>> {
    use base64::engine::general_purpose::STANDARD as BASE64;

    // Check if metadata exists
    if file.metadata.encrypted_data.is_none() || file.metadata.decryption_header.is_empty() {
        return Ok(None);
    }

    let encrypted_data = file.metadata.encrypted_data.as_ref().unwrap();
    let encrypted_bytes = BASE64.decode(encrypted_data)?;
    let header_bytes = BASE64.decode(&file.metadata.decryption_header)?;

    // Decrypt the metadata using streaming XChaCha20-Poly1305
    let decrypted = decrypt_stream(&encrypted_bytes, &header_bytes, file_key)?;

    // Parse JSON metadata
    let metadata: FileMetadata = serde_json::from_slice(&decrypted)?;
    Ok(Some(metadata))
}

/// Decrypt magic metadata (public or private)
fn decrypt_magic_metadata(
    magic_metadata: &crate::api::models::MagicMetadata,
    file_key: &[u8],
) -> Result<Option<serde_json::Value>> {
    use base64::engine::general_purpose::STANDARD as BASE64;

    // Check if data exists
    if magic_metadata.data.is_empty() || magic_metadata.header.is_empty() {
        return Ok(None);
    }

    let encrypted_bytes = BASE64.decode(&magic_metadata.data)?;
    let header_bytes = BASE64.decode(&magic_metadata.header)?;

    // Decrypt the metadata using streaming XChaCha20-Poly1305
    let decrypted = decrypt_stream(&encrypted_bytes, &header_bytes, file_key)?;

    // Parse as generic JSON since magic metadata structure can vary
    let metadata: serde_json::Value = serde_json::from_slice(&decrypted)?;
    Ok(Some(metadata))
}

/// Extract live photo components from a ZIP file
async fn extract_live_photo(zip_data: &[u8], output_path: &Path) -> Result<()> {
    use zip::ZipArchive;

    // Parse the ZIP archive
    let cursor = Cursor::new(zip_data);
    let mut archive = ZipArchive::new(cursor)?;

    // Get the parent directory and base name
    let parent_dir = output_path
        .parent()
        .ok_or_else(|| crate::Error::Generic("Invalid output path".into()))?;

    let base_name = output_path
        .file_stem()
        .and_then(|s| s.to_str())
        .ok_or_else(|| crate::Error::Generic("Invalid filename".into()))?;

    // Extract each file from the ZIP
    for i in 0..archive.len() {
        let mut file = archive.by_index(i)?;
        let file_name = file.name().to_string();

        // Determine the output filename based on the content
        let output_file_path = if file_name.to_lowercase().ends_with(".heic")
            || file_name.to_lowercase().ends_with(".jpg")
            || file_name.to_lowercase().ends_with(".jpeg")
        {
            // Image component
            parent_dir.join(format!("{}.jpg", base_name))
        } else if file_name.to_lowercase().ends_with(".mov")
            || file_name.to_lowercase().ends_with(".mp4")
        {
            // Video component
            parent_dir.join(format!("{}.mov", base_name))
        } else {
            // Unknown component - use original extension
            let ext = std::path::Path::new(&file_name)
                .extension()
                .and_then(|e| e.to_str())
                .unwrap_or("bin");
            parent_dir.join(format!("{}.{}", base_name, ext))
        };

        // Read the file contents
        let mut contents = Vec::new();
        use std::io::Read;
        file.read_to_end(&mut contents)?;

        // Write to disk
        let mut output_file = fs::File::create(&output_file_path).await?;
        output_file.write_all(&contents).await?;
        output_file.sync_all().await?;

        log::debug!("Extracted live photo component: {:?}", output_file_path);
    }

    Ok(())
}
