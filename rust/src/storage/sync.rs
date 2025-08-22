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
    pub fn upsert_collection(&self, account_id: i64, collection: &Collection) -> Result<()> {
        let metadata = serde_json::to_string(&collection)?;

        self.conn.execute(
            "INSERT OR REPLACE INTO collections 
             (account_id, collection_id, name, type, owner, is_deleted, metadata, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                account_id,
                collection.id,
                collection.name,
                format!("{:?}", collection.collection_type).to_lowercase(),
                collection.owner,
                collection.is_deleted as i32,
                metadata,
                collection.updated_at
            ],
        )?;

        Ok(())
    }

    /// Get all collections for an account
    pub fn get_collections(&self, account_id: i64) -> Result<Vec<Collection>> {
        let mut stmt = self.conn.prepare(
            "SELECT metadata FROM collections 
             WHERE account_id = ?1 AND is_deleted = 0
             ORDER BY collection_id",
        )?;

        let collections = stmt
            .query_map(params![account_id], |row| {
                let metadata: String = row.get(0)?;
                Ok(serde_json::from_str::<Collection>(&metadata).unwrap())
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(collections)
    }

    /// Store a file
    pub fn upsert_file(&self, account_id: i64, file: &RemoteFile) -> Result<()> {
        let file_info = serde_json::to_string(&file.file)?;
        let metadata = serde_json::to_string(&file.metadata)?;

        self.conn.execute(
            "INSERT OR REPLACE INTO files 
             (account_id, file_id, collection_id, encrypted_key, key_decryption_nonce, 
              file_info, metadata, is_deleted, updated_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
            params![
                account_id,
                file.id,
                file.collection_id,
                file.encrypted_key,
                file.key_decryption_nonce,
                file_info,
                metadata,
                file.is_deleted as i32,
                file.updated_at
            ],
        )?;

        Ok(())
    }

    /// Get files for a collection
    pub fn get_files_by_collection(
        &self,
        account_id: i64,
        collection_id: i64,
    ) -> Result<Vec<RemoteFile>> {
        let mut stmt = self.conn.prepare(
            "SELECT file_id, collection_id, encrypted_key, key_decryption_nonce, 
                    file_info, metadata, is_deleted, updated_at
             FROM files 
             WHERE account_id = ?1 AND collection_id = ?2 AND is_deleted = 0
             ORDER BY file_id",
        )?;

        let files = stmt
            .query_map(params![account_id, collection_id], |row| {
                let file_info: String = row.get(4)?;
                let metadata: String = row.get(5)?;

                Ok(RemoteFile {
                    id: row.get(0)?,
                    collection_id: row.get(1)?,
                    owner_id: 0, // Will need to fetch from account
                    encrypted_key: row.get(2)?,
                    key_decryption_nonce: row.get(3)?,
                    file: serde_json::from_str(&file_info).unwrap(),
                    thumbnail: serde_json::from_str("{}").unwrap(), // Placeholder
                    metadata: serde_json::from_str(&metadata).unwrap(),
                    is_deleted: row.get::<_, i32>(6)? != 0,
                    updated_at: row.get(7)?,
                })
            })?
            .collect::<std::result::Result<Vec<_>, _>>()?;

        Ok(files)
    }

    /// Update sync state
    pub fn update_sync_state(
        &self,
        account_id: i64,
        sync_type: &str,
        timestamp: i64,
    ) -> Result<()> {
        let column = match sync_type {
            "files" => "last_file_sync",
            "collections" => "last_collection_sync",
            "albums" => "last_album_sync",
            _ => return Err(crate::Error::InvalidInput("Invalid sync type".into())),
        };

        let query = format!(
            "INSERT OR REPLACE INTO sync_state (account_id, {}) VALUES (?1, ?2)
             ON CONFLICT(account_id) DO UPDATE SET {} = ?2",
            column, column
        );

        self.conn.execute(&query, params![account_id, timestamp])?;

        Ok(())
    }

    /// Get last sync timestamp
    pub fn get_last_sync(&self, account_id: i64, sync_type: &str) -> Result<Option<i64>> {
        let column = match sync_type {
            "files" => "last_file_sync",
            "collections" => "last_collection_sync",
            "albums" => "last_album_sync",
            _ => return Err(crate::Error::InvalidInput("Invalid sync type".into())),
        };

        let query = format!("SELECT {} FROM sync_state WHERE account_id = ?1", column);
        let mut stmt = self.conn.prepare(&query)?;

        let timestamp = stmt
            .query_row(params![account_id], |row| row.get::<_, Option<i64>>(0))
            .optional()?
            .flatten();

        Ok(timestamp)
    }

    /// Mark album file as synced
    pub fn mark_album_file_synced(
        &self,
        account_id: i64,
        album_id: i64,
        file_id: i64,
    ) -> Result<()> {
        self.conn.execute(
            "UPDATE album_files SET synced_locally = 1 
             WHERE account_id = ?1 AND album_id = ?2 AND file_id = ?3",
            params![account_id, album_id, file_id],
        )?;

        Ok(())
    }
}
