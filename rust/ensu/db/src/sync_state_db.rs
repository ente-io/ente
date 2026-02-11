use std::path::Path;

use uuid::Uuid;

use crate::Result;
use crate::backend::{Backend, RowExt, Value};
use crate::sync_state_schema;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SyncEntityState {
    pub remote_id: Option<String>,
    pub server_updated_at: Option<i64>,
}

pub struct SyncStateDb<B: Backend> {
    backend: B,
}

impl<B: Backend> SyncStateDb<B> {
    pub fn new(backend: B) -> Result<Self> {
        backend.execute_batch(sync_state_schema::CREATE_ALL)?;
        Ok(Self { backend })
    }

    pub fn get_session_state(&self, uuid: Uuid) -> Result<Option<SyncEntityState>> {
        self.get_entity_state("sync_sessions", uuid)
    }

    pub fn get_message_state(&self, uuid: Uuid) -> Result<Option<SyncEntityState>> {
        self.get_entity_state("sync_messages", uuid)
    }

    pub fn get_session_remote_id(&self, uuid: Uuid) -> Result<Option<String>> {
        self.get_entity_remote_id("sync_sessions", uuid)
    }

    pub fn get_message_remote_id(&self, uuid: Uuid) -> Result<Option<String>> {
        self.get_entity_remote_id("sync_messages", uuid)
    }

    pub fn get_session_uuid_by_remote_id(&self, remote_id: &str) -> Result<Option<Uuid>> {
        self.get_uuid_by_remote_id("sync_sessions", remote_id)
    }

    pub fn get_message_uuid_by_remote_id(&self, remote_id: &str) -> Result<Option<Uuid>> {
        self.get_uuid_by_remote_id("sync_messages", remote_id)
    }

    pub fn set_session_state(
        &self,
        uuid: Uuid,
        remote_id: Option<&str>,
        server_updated_at: Option<i64>,
    ) -> Result<()> {
        self.set_entity_state("sync_sessions", uuid, remote_id, server_updated_at)
    }

    pub fn set_message_state(
        &self,
        uuid: Uuid,
        remote_id: Option<&str>,
        server_updated_at: Option<i64>,
    ) -> Result<()> {
        self.set_entity_state("sync_messages", uuid, remote_id, server_updated_at)
    }

    pub fn set_session_remote_id(&self, uuid: Uuid, remote_id: Option<&str>) -> Result<()> {
        self.set_entity_remote_id("sync_sessions", uuid, remote_id)
    }

    pub fn set_message_remote_id(&self, uuid: Uuid, remote_id: Option<&str>) -> Result<()> {
        self.set_entity_remote_id("sync_messages", uuid, remote_id)
    }

    pub fn set_session_server_updated_at(&self, uuid: Uuid, updated_at: i64) -> Result<()> {
        self.set_entity_server_updated_at("sync_sessions", uuid, updated_at)
    }

    pub fn set_message_server_updated_at(&self, uuid: Uuid, updated_at: i64) -> Result<()> {
        self.set_entity_server_updated_at("sync_messages", uuid, updated_at)
    }

    pub fn delete_session_state(&self, uuid: Uuid) -> Result<()> {
        self.delete_entity_state("sync_sessions", uuid)
    }

    pub fn delete_message_state(&self, uuid: Uuid) -> Result<()> {
        self.delete_entity_state("sync_messages", uuid)
    }

    pub fn clear_state(&self) -> Result<()> {
        self.backend.execute("DELETE FROM sync_sessions", &[])?;
        self.backend.execute("DELETE FROM sync_messages", &[])?;
        Ok(())
    }

    pub fn get_meta(&self, key: &str) -> Result<Option<Vec<u8>>> {
        let row = self.backend.query_row(
            "SELECT value FROM sync_meta WHERE key = ?",
            &[Value::Text(key.to_string())],
        )?;
        row.map(|row| row.get_blob(0)).transpose()
    }

    pub fn set_meta(&self, key: &str, value: &[u8]) -> Result<()> {
        self.backend.execute(
            "INSERT INTO sync_meta (key, value) VALUES (?, ?) \n             ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            &[Value::Text(key.to_string()), Value::Blob(value.to_vec())],
        )?;
        Ok(())
    }

    pub fn delete_meta(&self, key: &str) -> Result<()> {
        self.backend.execute(
            "DELETE FROM sync_meta WHERE key = ?",
            &[Value::Text(key.to_string())],
        )?;
        Ok(())
    }

    pub fn clear_meta(&self) -> Result<()> {
        self.backend.execute("DELETE FROM sync_meta", &[])?;
        Ok(())
    }

    fn get_entity_state(&self, table: &str, uuid: Uuid) -> Result<Option<SyncEntityState>> {
        let query = format!("SELECT remote_id, server_updated_at FROM {table} WHERE client_id = ?");
        let row = self
            .backend
            .query_row(&query, &[Value::Text(uuid.to_string())])?;
        row.map(|row| {
            Ok(SyncEntityState {
                remote_id: row.get_optional_string(0)?,
                server_updated_at: row.get_optional_i64(1)?,
            })
        })
        .transpose()
    }

    fn get_entity_remote_id(&self, table: &str, uuid: Uuid) -> Result<Option<String>> {
        let query = format!("SELECT remote_id FROM {table} WHERE client_id = ?");
        let row = self
            .backend
            .query_row(&query, &[Value::Text(uuid.to_string())])?;
        match row {
            Some(row) => row.get_optional_string(0),
            None => Ok(None),
        }
    }

    fn get_uuid_by_remote_id(&self, table: &str, remote_id: &str) -> Result<Option<Uuid>> {
        let query = format!("SELECT client_id FROM {table} WHERE remote_id = ?");
        let row = self
            .backend
            .query_row(&query, &[Value::Text(remote_id.to_string())])?;
        match row {
            Some(row) => Ok(Some(Uuid::parse_str(&row.get_string(0)?)?)),
            None => Ok(None),
        }
    }

    fn set_entity_state(
        &self,
        table: &str,
        uuid: Uuid,
        remote_id: Option<&str>,
        server_updated_at: Option<i64>,
    ) -> Result<()> {
        let query = format!(
            "INSERT INTO {table} (client_id, remote_id, server_updated_at) VALUES (?, ?, ?) \n             ON CONFLICT(client_id) DO UPDATE SET \n               remote_id = COALESCE(excluded.remote_id, {table}.remote_id), \n               server_updated_at = COALESCE(excluded.server_updated_at, {table}.server_updated_at)"
        );
        self.backend.execute(
            &query,
            &[
                Value::Text(uuid.to_string()),
                remote_id
                    .map(|value| Value::Text(value.to_string()))
                    .unwrap_or(Value::Null),
                server_updated_at.map(Value::Integer).unwrap_or(Value::Null),
            ],
        )?;
        Ok(())
    }

    fn set_entity_remote_id(&self, table: &str, uuid: Uuid, remote_id: Option<&str>) -> Result<()> {
        let query = format!(
            "INSERT INTO {table} (client_id, remote_id) VALUES (?, ?) \n             ON CONFLICT(client_id) DO UPDATE SET remote_id = excluded.remote_id"
        );
        self.backend.execute(
            &query,
            &[
                Value::Text(uuid.to_string()),
                remote_id
                    .map(|value| Value::Text(value.to_string()))
                    .unwrap_or(Value::Null),
            ],
        )?;
        Ok(())
    }

    fn set_entity_server_updated_at(&self, table: &str, uuid: Uuid, updated_at: i64) -> Result<()> {
        let query = format!(
            "INSERT INTO {table} (client_id, server_updated_at) VALUES (?, ?) \n             ON CONFLICT(client_id) DO UPDATE SET server_updated_at = excluded.server_updated_at"
        );
        self.backend.execute(
            &query,
            &[Value::Text(uuid.to_string()), Value::Integer(updated_at)],
        )?;
        Ok(())
    }

    fn delete_entity_state(&self, table: &str, uuid: Uuid) -> Result<()> {
        let query = format!("DELETE FROM {table} WHERE client_id = ?");
        self.backend
            .execute(&query, &[Value::Text(uuid.to_string())])?;
        Ok(())
    }
}

#[cfg(feature = "sqlite")]
impl SyncStateDb<crate::backend::sqlite::SqliteBackend> {
    pub fn open_sqlite(path: impl AsRef<Path>) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open(path)?;
        Self::new(backend)
    }

    pub fn open_sqlite_with_defaults(path: impl AsRef<Path>) -> Result<Self> {
        Self::open_sqlite(path)
    }
}
