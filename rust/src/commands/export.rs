use crate::api::client::ApiClient;
use crate::api::methods::ApiMethods;
use crate::crypto::init as crypto_init;
use crate::models::account::Account;
use crate::storage::Storage;
use crate::Result;
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
        for acc in &all_accounts {
            log::debug!("Account: email='{}', id={}", acc.email, acc.id);
        }
        let matching: Vec<Account> = all_accounts.into_iter()
            .filter(|a| {
                let matches = a.email == email;
                log::debug!("Comparing '{}' == '{}': {}", a.email, email, matches);
                matches
            })
            .collect();
        
        if matching.is_empty() {
            return Err(crate::Error::NotFound(format!("Account not found: {email}")));
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
            println!("❌ Export failed: {}", e);
        } else {
            println!("✅ Export completed successfully!");
        }
    }
    
    Ok(())
}

async fn export_account(storage: &Storage, account: &Account) -> Result<()> {
    // Get export directory
    let export_dir = account.export_dir.as_ref()
        .ok_or_else(|| crate::Error::InvalidInput("No export directory configured".into()))?;
    let export_path = Path::new(export_dir);
    
    println!("Export directory: {}", export_dir);
    
    // Create export directory if needed
    fs::create_dir_all(export_path).await?;
    
    // Get stored secrets
    let secrets = storage.accounts().get_secrets(account.id)?
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
    let _master_key = &secrets.master_key;
    
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
        
        let mut has_more = true;
        let mut since_time = 0i64;
        
        while has_more {
            let (files, more) = api.get_collection_files(&account.email, collection.id, since_time).await?;
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
                
                // Generate export path
                let file_path = generate_export_path(
                    export_path,
                    &file,
                    Some(collection),
                )?;
                
                // Skip if file already exists
                if file_path.exists() {
                    log::debug!("File already exists: {:?}", file_path);
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
                
                // Decrypt file (simplified - would need proper key management)
                // For now, just save the encrypted file
                let mut file_handle = fs::File::create(&file_path).await?;
                file_handle.write_all(&encrypted_data).await?;
                file_handle.sync_all().await?;
                
                exported_files += 1;
                
                // Progress indicator
                if exported_files % 10 == 0 {
                    println!("Exported {} files...", exported_files);
                }
            }
        }
    }
    
    println!("\nExport summary:");
    println!("  Total files: {}", total_files);
    println!("  Exported: {}", exported_files);
    println!("  Skipped (already exists or deleted): {}", total_files - exported_files);
    
    Ok(())
}

fn generate_export_path(
    export_dir: &Path,
    file: &crate::api::models::File,
    collection: Option<&crate::api::models::Collection>,
) -> Result<PathBuf> {
    use chrono::{Utc, TimeZone};
    
    // Start with export directory
    let mut path = export_dir.to_path_buf();
    
    // Add date-based directory structure (YYYY/MM-MonthName)
    // Use updation_time as creation time proxy
    let datetime = Utc.timestamp_micros(file.updation_time).single()
        .ok_or_else(|| crate::Error::Generic("Invalid timestamp".into()))?;
    
    let year = datetime.format("%Y").to_string();
    let month = datetime.format("%m-%B").to_string(); // e.g., "01-January"
    
    path.push(year);
    path.push(month);
    
    // Add collection name if available
    if let Some(col) = collection {
        if let Some(ref name) = col.name {
            if !name.is_empty() && name != "Uncategorized" {
                // Sanitize collection name for filesystem
                let safe_name: String = name.chars()
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
        }
    }
    
    // Generate filename - just use ID with a generic extension for now
    let filename = format!("file_{}.dat", file.id);
    path.push(filename);
    
    Ok(path)
}