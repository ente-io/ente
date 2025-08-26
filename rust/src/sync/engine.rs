use crate::Result;
use crate::api::client::ApiClient;
use crate::api::methods::ApiMethods;
use crate::models::{account::Account, file::RemoteFile};
use crate::storage::Storage;

/// Core sync engine responsible for fetching and tracking remote changes
pub struct SyncEngine {
    api_client: ApiClient,
    storage: Storage,
    account: Account,
}

impl SyncEngine {
    /// Create a new sync engine for an account
    pub fn new(api_client: ApiClient, storage: Storage, account: Account) -> Self {
        Self {
            api_client,
            storage,
            account,
        }
    }

    /// Run a full sync for the account
    pub async fn sync(&self) -> Result<SyncStats> {
        log::info!("Starting sync for account: {}", self.account.email);

        let mut stats = SyncStats::default();

        // Get account ID for auth - use email as account identifier
        let account_id = &self.account.email;

        // Sync collections first
        stats.collections = self.sync_collections(account_id).await?;

        // Then sync files
        stats.files = self.sync_files(account_id).await?;

        log::info!("Sync completed: {stats:?}");
        Ok(stats)
    }

    /// Sync collections (albums)
    async fn sync_collections(&self, account_id: &str) -> Result<SyncResult> {
        log::debug!("Syncing collections...");

        let sync_store = self.storage.sync();

        // Get last sync time for collections
        let last_sync = sync_store
            .get_last_sync(self.account.id, "collections")?
            .unwrap_or(0);

        let api = ApiMethods::new(&self.api_client);
        let collections = api.get_collections(account_id, last_sync).await?;

        let mut result = SyncResult {
            total: collections.len(),
            new: 0,
            updated: 0,
            deleted: 0,
        };

        // Process each collection
        for collection in &collections {
            log::debug!(
                "Processing collection: {:?} ({})",
                collection.name,
                collection.id
            );

            // Convert API collection to storage collection
            let storage_collection = crate::models::collection::Collection {
                id: collection.id,
                owner: collection.owner.id,
                key: collection.encrypted_key.clone(),
                name: collection.name.clone().unwrap_or_default(),
                collection_type: match collection.collection_type.as_str() {
                    "folder" => crate::models::collection::CollectionType::Folder,
                    "favorites" => crate::models::collection::CollectionType::Favorites,
                    _ => crate::models::collection::CollectionType::Album,
                },
                attributes: None,
                sharees: None,
                public_urls: None,
                updated_at: collection.updation_time,
                is_deleted: collection.is_deleted,
            };

            // Upsert collection (insert or update)
            sync_store.upsert_collection(&storage_collection)?;

            // Count as new or updated based on updation time
            if collection.updation_time > last_sync {
                // We don't have creation_time in API response, so count as updated
                if collection.updation_time > last_sync {
                    result.new += 1;
                } else {
                    result.updated += 1;
                }
            }
        }

        // Update sync timestamp
        let now = chrono::Utc::now().timestamp_micros();
        sync_store.update_sync_state(self.account.user_id, "collections", now)?;

        log::info!(
            "Collections synced: {} new, {} updated",
            result.new,
            result.updated
        );
        Ok(result)
    }

    /// Sync files incrementally
    async fn sync_files(&self, account_id: &str) -> Result<SyncResult> {
        log::debug!("Syncing files...");

        let sync_store = self.storage.sync();
        let api = ApiMethods::new(&self.api_client);
        let mut result = SyncResult::default();

        // Get all collections for this account
        let collections = sync_store.get_collections(self.account.id)?;

        // Sync files for each collection
        for collection in collections {
            if collection.is_deleted {
                continue;
            }

            log::debug!(
                "Syncing files for collection: {} ({})",
                collection.name,
                collection.id
            );

            // Get last sync time for this collection's files
            let mut last_sync = sync_store
                .get_last_sync(
                    self.account.id,
                    &format!("collection_{}_files", collection.id),
                )?
                .unwrap_or(0);

            let mut has_more = true;
            while has_more {
                log::debug!(
                    "Fetching files for collection {}, since_time: {}",
                    collection.id,
                    last_sync
                );

                let (files, more) = api
                    .get_collection_files(account_id, collection.id, last_sync)
                    .await?;
                has_more = more;

                if files.is_empty() {
                    break;
                }

                result.total += files.len();

                // Convert API files to RemoteFile and process
                for file in files {
                    log::trace!("Processing file: {}", file.id);

                    // Create RemoteFile from API response
                    let remote_file = RemoteFile {
                        id: file.id,
                        collection_id: file.collection_id,
                        owner_id: file.owner_id,
                        encrypted_key: file.encrypted_key.clone(),
                        key_decryption_nonce: file.key_decryption_nonce.clone(),
                        file: crate::models::file::FileInfo {
                            encrypted_data: file.file.encrypted_data.clone(),
                            decryption_header: file.file.decryption_header.clone(),
                            object_key: None, // Not in API response
                            size: file.file.size,
                        },
                        thumbnail: crate::models::file::FileInfo {
                            encrypted_data: file.thumbnail.encrypted_data.clone(),
                            decryption_header: file.thumbnail.decryption_header.clone(),
                            object_key: None, // Not in API response
                            size: file.thumbnail.size,
                        },
                        metadata: crate::models::file::MetadataInfo {
                            encrypted_data: file
                                .metadata
                                .encrypted_data
                                .clone()
                                .unwrap_or_default(),
                            decryption_header: file.metadata.decryption_header.clone(),
                        },
                        is_deleted: file.is_deleted,
                        updated_at: file.updation_time,
                    };

                    // Upsert file (insert or update)
                    sync_store.upsert_file(&remote_file)?;

                    // Count as new or updated
                    if file.updation_time > last_sync {
                        // We don't have creation_time in API response, count as updated
                        result.updated += 1;
                    }

                    // Track the latest updation time for next sync
                    if file.updation_time > last_sync {
                        last_sync = file.updation_time;
                    }
                }

                // Update sync state after each batch for this collection
                sync_store.update_sync_state(
                    self.account.id,
                    &format!("collection_{}_files", collection.id),
                    last_sync,
                )?;
            }
        }

        log::info!(
            "Files synced: {} new, {} updated",
            result.new,
            result.updated
        );
        Ok(result)
    }

    /// Get list of files that need to be downloaded
    pub async fn get_pending_downloads(&self) -> Result<Vec<RemoteFile>> {
        let sync_store = self.storage.sync();

        // Get all non-deleted files for this account
        // Note: We'll need to check all collections for this account
        let collections = sync_store.get_collections(self.account.id)?;

        let mut all_files = Vec::new();
        for collection in collections {
            let files = sync_store.get_files_by_collection(self.account.id, collection.id)?;
            all_files.extend(files);
        }

        // Filter out deleted files
        let pending: Vec<RemoteFile> = all_files.into_iter().filter(|f| !f.is_deleted).collect();

        log::info!("Found {} files pending download", pending.len());
        Ok(pending)
    }

    /// Get collections for decryption keys
    pub async fn get_collections(&self) -> Result<Vec<crate::models::collection::Collection>> {
        let sync_store = self.storage.sync();
        sync_store.get_collections(self.account.id)
    }
}

/// Statistics from a sync operation
#[derive(Debug, Default)]
pub struct SyncStats {
    pub collections: SyncResult,
    pub files: SyncResult,
}

/// Result of syncing a specific type of data
#[derive(Debug, Default)]
pub struct SyncResult {
    pub total: usize,
    pub new: usize,
    pub updated: usize,
    pub deleted: usize,
}
