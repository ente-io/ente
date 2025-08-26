#![allow(dead_code)]

use crate::{
    Result,
    models::{collection::Collection, file::RemoteFile},
};
use rusqlite::{Connection, OptionalExtension, params};
use serde_json;

pub struct SyncStore<'a> {
    conn: &'a Connection,
}

impl<'a> SyncStore<'a> {
    pub fn new(conn: &'a Connection) -> Self {
        Self { conn }
    }

    /// Store a collection
    pub fn upsert_collection(&self, collection: &Collection) -> Result<()> {
        let metadata = serde_json::to_string(&collection)?;

        self.conn.execute(
            "INSERT OR REPLACE INTO collections 
             (collection_id, owner, name, type, is_deleted, metadata, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
            params![
                collection.id,
                collection.owner,
                collection.name,
                format!("{:?}", collection.collection_type).to_lowercase(),
                collection.is_deleted as i32,
                metadata,
                collection.updated_at
            ],
        )?;

        Ok(())
    }

    /// Get all collections for a user
    pub fn get_collections(&self, user_id: i64) -> Result<Vec<Collection>> {
        let mut stmt = self.conn.prepare(
            "SELECT metadata FROM collections 
             WHERE owner = ?1 AND is_deleted = 0
             ORDER BY collection_id",
        )?;

        let collections = stmt
            .query_map(params![user_id], |row| {
                let metadata: String = row.get(0)?;
                Ok(serde_json::from_str::<Collection>(&metadata).unwrap())
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(collections)
    }

    /// Store a file
    pub fn upsert_file(&self, file: &RemoteFile) -> Result<()> {
        let file_info = serde_json::to_string(&file.file)?;
        let metadata = serde_json::to_string(&file.metadata)?;

        // First check if file exists and preserve is_synced_locally flag
        let existing_sync_status: Option<i32> = self
            .conn
            .query_row(
                "SELECT is_synced_locally FROM files WHERE file_id = ?1",
                params![file.id],
                |row| row.get(0),
            )
            .optional()?;

        let is_synced = existing_sync_status.unwrap_or(0);

        self.conn.execute(
            "INSERT OR REPLACE INTO files 
             (file_id, owner_id, collection_id, encrypted_key, key_decryption_nonce, 
              file_info, metadata, is_deleted, is_synced_locally, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10)",
            params![
                file.id,
                file.owner_id,
                file.collection_id,
                file.encrypted_key,
                file.key_decryption_nonce,
                file_info,
                metadata,
                file.is_deleted as i32,
                is_synced,
                file.updated_at
            ],
        )?;

        Ok(())
    }

    /// Get files for a collection
    pub fn get_files_by_collection(
        &self,
        user_id: i64,
        collection_id: i64,
    ) -> Result<Vec<RemoteFile>> {
        let mut stmt = self.conn.prepare(
            "SELECT file_id, collection_id, encrypted_key, key_decryption_nonce, 
                    file_info, metadata, is_deleted, updated_at, owner_id
             FROM files 
             WHERE owner_id = ?1 AND collection_id = ?2 AND is_deleted = 0
             ORDER BY file_id",
        )?;

        let files = stmt
            .query_map(params![user_id, collection_id], |row| {
                let file_info: String = row.get(4)?;
                let metadata: String = row.get(5)?;

                // Deserialize stored data - thumbnail might not be stored properly
                let file_obj: crate::models::file::FileInfo = serde_json::from_str(&file_info)
                    .map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?;

                let metadata_obj: crate::models::file::MetadataInfo =
                    serde_json::from_str(&metadata)
                        .map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?;

                // Create a default thumbnail info if not available
                let thumbnail = crate::models::file::FileInfo {
                    encrypted_data: None,
                    decryption_header: String::new(),
                    object_key: None,
                    size: None,
                };

                Ok(RemoteFile {
                    id: row.get(0)?,
                    collection_id: row.get(1)?,
                    owner_id: row.get(8)?,
                    encrypted_key: row.get(2)?,
                    key_decryption_nonce: row.get(3)?,
                    file: file_obj,
                    thumbnail,
                    metadata: metadata_obj,
                    is_deleted: row.get::<_, i32>(6)? != 0,
                    updated_at: row.get(7)?,
                })
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(files)
    }

    /// Update sync state
    pub fn update_sync_state(&self, user_id: i64, sync_type: &str, timestamp: i64) -> Result<()> {
        // For per-collection sync, store as generic key-value
        if sync_type.starts_with("collection_") {
            // Use a more generic approach for per-collection sync
            // Note: We're assuming photos app for now - might need app parameter in future
            self.conn.execute(
                "INSERT OR REPLACE INTO sync_state (user_id, app, last_file_sync) VALUES (?1, 'photos', ?2)
                 ON CONFLICT(user_id, app) DO UPDATE SET last_file_sync = MAX(last_file_sync, ?2)",
                params![user_id, timestamp],
            )?;
            return Ok(());
        }

        let column = match sync_type {
            "files" => "last_file_sync",
            "collections" => "last_collection_sync",
            "albums" => "last_album_sync",
            _ => return Err(crate::Error::InvalidInput("Invalid sync type".into())),
        };

        let query = format!(
            "INSERT OR REPLACE INTO sync_state (user_id, app, {column}) VALUES (?1, 'photos', ?2)
             ON CONFLICT(user_id, app) DO UPDATE SET {column} = ?2"
        );

        self.conn.execute(&query, params![user_id, timestamp])?;

        Ok(())
    }

    /// Get last sync timestamp
    pub fn get_last_sync(&self, user_id: i64, sync_type: &str) -> Result<Option<i64>> {
        // For per-collection sync, just return 0 for now
        if sync_type.starts_with("collection_") {
            return Ok(Some(0));
        }

        let column = match sync_type {
            "files" => "last_file_sync",
            "collections" => "last_collection_sync",
            "albums" => "last_album_sync",
            _ => return Err(crate::Error::InvalidInput("Invalid sync type".into())),
        };

        let query =
            format!("SELECT {column} FROM sync_state WHERE user_id = ?1 AND app = 'photos'");
        let mut stmt = self.conn.prepare(&query)?;

        let timestamp = stmt
            .query_row(params![user_id], |row| row.get::<_, Option<i64>>(0))
            .optional()?
            .flatten();

        Ok(timestamp)
    }

    /// Mark album file as synced
    pub fn mark_album_file_synced(&self, album_id: i64, file_id: i64) -> Result<()> {
        self.conn.execute(
            "UPDATE album_files SET synced_locally = 1 
             WHERE album_id = ?1 AND file_id = ?2",
            params![album_id, file_id],
        )?;

        Ok(())
    }

    /// Clear sync state for an account (for full sync)
    pub fn clear_sync_state(&self, user_id: i64) -> Result<()> {
        self.conn.execute(
            "DELETE FROM sync_state WHERE user_id = ?1 AND app = 'photos'",
            params![user_id],
        )?;
        Ok(())
    }

    /// Get files that need downloading (not synced locally)
    pub fn get_pending_downloads(&self, user_id: i64) -> Result<Vec<RemoteFile>> {
        // First check how many files are already synced
        let synced_count: i64 = self.conn.query_row(
            "SELECT COUNT(*) FROM files WHERE owner_id = ?1 AND is_synced_locally = 1",
            params![user_id],
            |row| row.get(0),
        )?;
        log::debug!("Files already synced locally: {synced_count}");

        let mut stmt = self.conn.prepare(
            "SELECT file_id, collection_id, encrypted_key, key_decryption_nonce, 
                    file_info, metadata, is_deleted, updated_at, owner_id
             FROM files 
             WHERE owner_id = ?1 AND is_deleted = 0 AND is_synced_locally = 0
             ORDER BY file_id",
        )?;

        let files = stmt
            .query_map(params![user_id], |row| {
                let file_info: String = row.get(4)?;
                let metadata: String = row.get(5)?;

                // Deserialize stored data - thumbnail might not be stored properly
                let file_obj: crate::models::file::FileInfo = serde_json::from_str(&file_info)
                    .map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?;

                let metadata_obj: crate::models::file::MetadataInfo =
                    serde_json::from_str(&metadata)
                        .map_err(|e| rusqlite::Error::ToSqlConversionFailure(Box::new(e)))?;

                // Create a default thumbnail info if not available
                let thumbnail = crate::models::file::FileInfo {
                    encrypted_data: None,
                    decryption_header: String::new(),
                    object_key: None,
                    size: None,
                };

                Ok(RemoteFile {
                    id: row.get(0)?,
                    collection_id: row.get(1)?,
                    owner_id: row.get(8)?,
                    encrypted_key: row.get(2)?,
                    key_decryption_nonce: row.get(3)?,
                    file: file_obj,
                    thumbnail,
                    metadata: metadata_obj,
                    is_deleted: row.get::<_, i32>(6)? != 0,
                    updated_at: row.get(7)?,
                })
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(files)
    }

    /// Mark file as synced locally after successful download
    pub fn mark_file_synced(&self, file_id: i64, local_path: Option<&str>) -> Result<()> {
        let rows_updated = if let Some(path) = local_path {
            self.conn.execute(
                "UPDATE files SET is_synced_locally = 1, local_path = ?2 
                 WHERE file_id = ?1",
                params![file_id, path],
            )?
        } else {
            self.conn.execute(
                "UPDATE files SET is_synced_locally = 1 
                 WHERE file_id = ?1",
                params![file_id],
            )?
        };

        log::debug!("Marked file {file_id} as synced locally, rows affected: {rows_updated}");

        Ok(())
    }
}
