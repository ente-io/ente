use crate::Result;
use crate::api::client::ApiClient;
use crate::api::methods::ApiMethods;
use crate::crypto::{decrypt_file_data, decrypt_stream, init as crypto_init, secret_box_open};
use crate::models::{account::Account, metadata::FileMetadata};
use crate::storage::Storage;
use base64::Engine;
use std::path::{Path, PathBuf};
use tokio::fs;
use tokio::io::AsyncWriteExt;

pub async fn run_export(account_email: Option<String>) -> Result<()> {
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

        if let Err(e) = export_account(&storage, &account).await {
            log::error!("Failed to export account {}: {}", account.email, e);
            println!("❌ Export failed: {e}");
        } else {
            println!("✅ Export completed successfully!");
        }
    }

    Ok(())
}

async fn export_account(storage: &Storage, account: &Account) -> Result<()> {
    // Get export directory
    let export_dir = account
        .export_dir
        .as_ref()
        .ok_or_else(|| crate::Error::InvalidInput("No export directory configured".into()))?;
    let export_path = Path::new(export_dir);

    println!("Export directory: {export_dir}");

    // Create export directory if needed
    fs::create_dir_all(export_path).await?;

    // Get stored secrets
    let secrets = storage
        .accounts()
        .get_secrets(account.id)?
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

    for collection in &collections {
        // Skip deleted collections
        if collection.is_deleted {
            continue;
        }

        println!("Processing collection: {}", collection.id);

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

            total_files += files.len();

            for file in files {
                // Skip deleted files
                if file.is_deleted {
                    continue;
                }

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

                // Decrypt metadata to get original filename
                let metadata = match decrypt_file_metadata(&file, &file_key) {
                    Ok(meta) => meta,
                    Err(e) => {
                        log::warn!("Failed to decrypt metadata for file {}: {}", file.id, e);
                        None
                    }
                };

                // Generate export path with original filename from metadata
                let file_path =
                    generate_export_path(export_path, &file, Some(collection), metadata.as_ref())?;

                // Skip if file already exists
                if file_path.exists() {
                    log::debug!("File already exists: {file_path:?}");
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

                // Write decrypted file
                let mut file_handle = fs::File::create(&file_path).await?;
                file_handle.write_all(&decrypted).await?;
                file_handle.sync_all().await?;

                exported_files += 1;

                // Progress indicator - show every file for now since we have few files
                println!(
                    "  [{}/{}] Exported: {}",
                    exported_files,
                    total_files,
                    file_path.file_name().unwrap_or_default().to_string_lossy()
                );
            }
        }
    }

    println!("\n{}", "=".repeat(50));
    println!("Export Summary:");
    println!("{}", "=".repeat(50));
    println!("  📁 Total files found: {total_files}");
    println!("  ✅ Successfully exported: {exported_files}");

    let skipped = total_files - exported_files;
    if skipped > 0 {
        println!("  ⏭️  Skipped (already exists): {skipped}");
    }

    if exported_files == total_files {
        println!("\n🎉 All files exported successfully!");
    } else if exported_files > 0 {
        println!("\n✨ Export completed with {exported_files} new files!");
    }

    Ok(())
}

fn generate_export_path(
    export_dir: &Path,
    file: &crate::api::models::File,
    collection: Option<&crate::api::models::Collection>,
    metadata: Option<&FileMetadata>,
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

    // Use original filename from metadata if available
    let filename = if let Some(meta) = metadata {
        if let Some(title) = meta.get_title() {
            // Sanitize filename for filesystem
            sanitize_filename(title)
        } else {
            generate_fallback_filename(file, metadata)
        }
    } else {
        generate_fallback_filename(file, None)
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
