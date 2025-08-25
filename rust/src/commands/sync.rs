use crate::Result;
use crate::api::client::ApiClient;
use crate::models::account::Account;
use crate::storage::Storage;
use crate::sync::{SyncEngine, SyncStats};
use base64::Engine;

pub async fn run_sync(
    account_email: Option<String>,
    metadata_only: bool,
    full_sync: bool,
) -> Result<()> {
    // Initialize crypto
    crate::crypto::init()?;

    // Open database
    let config_dir = crate::utils::get_cli_config_dir()?;
    let db_path = config_dir.join("ente.db");
    let storage = Storage::new(&db_path)?;

    // Get accounts to sync
    let accounts = if let Some(email) = account_email {
        // Sync specific account
        let all_accounts = storage.accounts().list()?;
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
        // Sync all accounts
        storage.accounts().list()?
    };

    if accounts.is_empty() {
        println!("No accounts configured. Use 'ente-rs account add' first.");
        return Ok(());
    }

    // Sync each account
    for account in accounts {
        println!("\n=== Syncing account: {} ===", account.email);

        if let Err(e) = sync_account(&storage, &account, metadata_only, full_sync).await {
            log::error!("Failed to sync account {}: {}", account.email, e);
            println!("❌ Sync failed: {e}");
        } else {
            println!("✅ Sync completed successfully!");
        }
    }

    Ok(())
}

async fn sync_account(
    storage: &Storage,
    account: &Account,
    metadata_only: bool,
    full_sync: bool,
) -> Result<()> {
    // Get stored secrets
    let secrets = storage
        .accounts()
        .get_secrets(account.id)?
        .ok_or_else(|| crate::Error::NotFound("Account secrets not found".into()))?;

    // Create API client with account's endpoint
    let api_client = ApiClient::new(Some(account.endpoint.clone()))?;

    // Store token for this account
    let token = base64::engine::general_purpose::URL_SAFE.encode(&secrets.token);
    api_client.add_token(&account.email, &token);

    // Clear sync state if full sync requested
    if full_sync {
        println!("Performing full sync (clearing existing sync state)...");
        storage.sync().clear_sync_state(account.id)?;
    }

    // Create sync engine (need to create new storage instance for ownership)
    let db_path = storage
        .db_path()
        .ok_or_else(|| crate::Error::Generic("Database path not available".into()))?;
    let sync_storage = Storage::new(db_path)?;
    let sync_engine = SyncEngine::new(api_client, sync_storage, account.clone());

    // Run sync
    println!("Fetching collections and files...");
    let stats = sync_engine.sync().await?;

    // Display sync statistics
    display_sync_stats(&stats);

    // Download files if not metadata-only
    if !metadata_only {
        println!("\n📥 Downloading files would happen here (not yet implemented)");
        // TODO: Implement file download using DownloadManager
        // let pending_files = sync_engine.get_pending_downloads().await?;
        // if !pending_files.is_empty() {
        //     println!("Found {} files to download", pending_files.len());
        //     let download_manager = DownloadManager::new(api_client, storage.clone())?;
        //     // Set collection keys...
        //     // Download files...
        // }
    } else {
        println!("\n📋 Metadata-only sync completed (skipping file downloads)");
    }

    Ok(())
}

fn display_sync_stats(stats: &SyncStats) {
    println!("\n📊 Sync Statistics:");
    println!("┌─────────────────────────────────────┐");
    println!("│ Collections:                        │");
    println!(
        "│   Total: {:5}                      │",
        stats.collections.total
    );
    println!(
        "│   New:   {:5}                      │",
        stats.collections.new
    );
    println!(
        "│   Updated: {:5}                    │",
        stats.collections.updated
    );
    println!("├─────────────────────────────────────┤");
    println!("│ Files:                              │");
    println!("│   Total: {:5}                      │", stats.files.total);
    println!("│   New:   {:5}                      │", stats.files.new);
    println!(
        "│   Updated: {:5}                    │",
        stats.files.updated
    );
    println!("└─────────────────────────────────────┘");
}
