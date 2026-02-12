use std::sync::Arc;

use uuid::Uuid;
use zeroize::Zeroizing;

use crate::backend::{Backend, BackendTx, RowExt, Value};
use crate::crypto;
use crate::migrations;
use crate::models::{AttachmentMeta, EntityType, Message, Sender, Session, StoredAttachment};
use crate::traits::{Clock, RandomUuidGen, SystemClock, UuidGen};
use crate::{Error, Result};

const SESSION_NEEDS_SYNC_PREDICATE: &str = "deleted_at IS NULL \
  AND (needs_sync = 1 OR EXISTS (\
    SELECT 1 FROM messages \
    WHERE messages.session_uuid = sessions.session_uuid \
      AND messages.needs_sync = 1 \
      AND messages.deleted_at IS NULL\
  ))";

pub struct ChatDb<B: Backend> {
    backend: B,
    key: Zeroizing<Vec<u8>>,
    clock: Arc<dyn Clock>,
    uuid_gen: Arc<dyn UuidGen>,
}

impl<B: Backend> ChatDb<B> {
    pub fn new(
        backend: B,
        key: Vec<u8>,
        clock: Arc<dyn Clock>,
        uuid_gen: Arc<dyn UuidGen>,
    ) -> Result<Self> {
        let key = validate_key(key)?;
        migrations::migrate(&backend)?;
        Ok(Self {
            backend,
            key,
            clock,
            uuid_gen,
        })
    }

    pub fn new_with_defaults(backend: B, key: Vec<u8>) -> Result<Self> {
        Self::new(backend, key, Arc::new(SystemClock), Arc::new(RandomUuidGen))
    }

    pub fn create_session(&self, title: &str) -> Result<Session> {
        let now = self.clock.now_us();
        let session_uuid = self.uuid_gen.new_uuid();
        let encrypted_title = crypto::encrypt_string(title, &self.key)?;

        let affected = self.backend.execute(
            "INSERT INTO sessions (session_uuid, title, created_at, updated_at, remote_id, needs_sync, deleted_at) \
             VALUES (?, ?, ?, ?, NULL, 1, NULL)",
            &[
                Value::Text(session_uuid.to_string()),
                Value::Blob(encrypted_title),
                Value::Integer(now),
                Value::Integer(now),
            ],
        )?;

        if affected != 1 {
            return Err(Error::NotFound {
                entity: EntityType::Session,
                id: session_uuid,
            });
        }

        Ok(Session {
            uuid: session_uuid,
            title: title.to_string(),
            created_at: now,
            updated_at: now,
            server_updated_at: None,
            remote_id: None,
            needs_sync: true,
            deleted_at: None,
        })
    }

    pub fn get_session(&self, uuid: Uuid) -> Result<Option<Session>> {
        let row = self.backend.query_row(
            "SELECT session_uuid, title, created_at, updated_at, server_updated_at, remote_id, needs_sync, deleted_at \
             FROM sessions WHERE session_uuid = ? AND deleted_at IS NULL",
            &[Value::Text(uuid.to_string())],
        )?;

        row.map(|row| self.session_from_row(&row)).transpose()
    }

    pub fn list_sessions(&self) -> Result<Vec<Session>> {
        let rows = self.backend.query(
            "SELECT session_uuid, title, created_at, updated_at, server_updated_at, remote_id, needs_sync, deleted_at \
             FROM sessions WHERE deleted_at IS NULL ORDER BY updated_at DESC",
            &[],
        )?;
        rows.iter().map(|row| self.session_from_row(row)).collect()
    }

    pub fn update_session_title(&self, uuid: Uuid, title: &str) -> Result<()> {
        let now = self.clock.now_us();
        let encrypted_title = crypto::encrypt_string(title, &self.key)?;
        let affected = self.backend.execute(
            "UPDATE sessions SET title = ?, updated_at = ?, needs_sync = 1, server_updated_at = NULL \
             WHERE session_uuid = ? AND deleted_at IS NULL",
            &[
                Value::Blob(encrypted_title),
                Value::Integer(now),
                Value::Text(uuid.to_string()),
            ],
        )?;
        ensure_row_updated(affected, EntityType::Session, uuid)
    }

    pub fn delete_session(&self, uuid: Uuid) -> Result<()> {
        let now = self.clock.now_us();
        self.backend.transaction(|tx| {
            tx.execute(
                "UPDATE messages SET deleted_at = ?, server_updated_at = NULL WHERE session_uuid = ? AND deleted_at IS NULL",
                &[Value::Integer(now), Value::Text(uuid.to_string())],
            )?;
            let affected = tx.execute(
                "UPDATE sessions SET deleted_at = ?, server_updated_at = NULL WHERE session_uuid = ? AND deleted_at IS NULL",
                &[Value::Integer(now), Value::Text(uuid.to_string())],
            )?;
            ensure_row_updated(affected, EntityType::Session, uuid)
        })
    }

    pub fn upsert_session(
        &self,
        session_uuid: Uuid,
        title: &str,
        created_at: i64,
        updated_at: i64,
        remote_id: Option<String>,
        needs_sync: bool,
        deleted_at: Option<i64>,
    ) -> Result<Session> {
        let encrypted_title = crypto::encrypt_string(title, &self.key)?;
        let needs_sync_value = if needs_sync { 1 } else { 0 };
        let remote_value = remote_id.map(Value::Text).unwrap_or(Value::Null);
        let deleted_value = deleted_at.map(Value::Integer).unwrap_or(Value::Null);

        self.backend.execute(
            "INSERT INTO sessions (session_uuid, title, created_at, updated_at, remote_id, needs_sync, deleted_at) \
             VALUES (?, ?, ?, ?, ?, ?, ?) \
             ON CONFLICT(session_uuid) DO UPDATE SET \
               title = excluded.title, \
               created_at = excluded.created_at, \
               updated_at = excluded.updated_at, \
               remote_id = COALESCE(excluded.remote_id, sessions.remote_id), \
               needs_sync = excluded.needs_sync, \
               deleted_at = excluded.deleted_at",
            &[
                Value::Text(session_uuid.to_string()),
                Value::Blob(encrypted_title),
                Value::Integer(created_at),
                Value::Integer(updated_at),
                remote_value,
                Value::Integer(needs_sync_value),
                deleted_value,
            ],
        )?;

        let row = self.backend.query_row(
            "SELECT session_uuid, title, created_at, updated_at, server_updated_at, remote_id, needs_sync, deleted_at \
             FROM sessions WHERE session_uuid = ?",
            &[Value::Text(session_uuid.to_string())],
        )?;
        let row = row.ok_or(Error::NotFound {
            entity: EntityType::Session,
            id: session_uuid,
        })?;
        self.session_from_row(&row)
    }

    pub fn get_sessions_needing_sync(&self) -> Result<Vec<Session>> {
        let query = format!(
            "SELECT session_uuid, title, created_at, updated_at, server_updated_at, remote_id, needs_sync, deleted_at \
             FROM sessions \
             WHERE {SESSION_NEEDS_SYNC_PREDICATE} \
             ORDER BY updated_at DESC"
        );
        let rows = self.backend.query(&query, &[])?;
        rows.iter().map(|row| self.session_from_row(row)).collect()
    }

    pub fn count_needing_sync(&self) -> Result<i64> {
        let query = format!("SELECT COUNT(*) FROM sessions WHERE {SESSION_NEEDS_SYNC_PREDICATE}");
        let row = self.backend.query_row(&query, &[])?;
        Ok(row.map(|row| row.get_i64(0)).transpose()?.unwrap_or(0))
    }

    pub fn get_sessions_needing_sync_batch(
        &self,
        limit: i64,
        order_desc: bool,
    ) -> Result<Vec<Session>> {
        if limit <= 0 {
            return Ok(Vec::new());
        }
        let order_clause = if order_desc { "DESC" } else { "ASC" };
        let query = format!(
            "SELECT session_uuid, title, created_at, updated_at, server_updated_at, remote_id, needs_sync, deleted_at \
             FROM sessions \
             WHERE {SESSION_NEEDS_SYNC_PREDICATE} \
             ORDER BY updated_at {order_clause} \
             LIMIT ?"
        );
        let rows = self.backend.query(&query, &[Value::Integer(limit)])?;
        rows.iter().map(|row| self.session_from_row(row)).collect()
    }

    pub fn insert_message(
        &self,
        session_uuid: Uuid,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<AttachmentMeta>,
    ) -> Result<Message> {
        let sender: Sender = sender.parse()?;
        let now = self.clock.now_us();
        let message_uuid = self.uuid_gen.new_uuid();
        let encrypted_text = crypto::encrypt_string(text, &self.key)?;
        let attachments_json = self.serialize_attachments(&attachments)?;

        self.backend.transaction(|tx| {
            tx.execute(
                "INSERT INTO messages (message_uuid, session_uuid, parent_message_uuid, sender, text, attachments, created_at, needs_sync, deleted_at) \
                 VALUES (?, ?, ?, ?, ?, ?, ?, 1, NULL)",
                &[
                    Value::Text(message_uuid.to_string()),
                    Value::Text(session_uuid.to_string()),
                    parent
                        .map(|value| Value::Text(value.to_string()))
                        .unwrap_or(Value::Null),
                    Value::Text(sender.as_str().to_string()),
                    Value::Blob(encrypted_text),
                    attachments_json
                        .map(Value::Text)
                        .unwrap_or(Value::Null),
                    Value::Integer(now),
                ],
            )?;

            self.touch_session(tx, session_uuid, now)?;
            Ok(())
        })?;

        Ok(Message {
            uuid: message_uuid,
            session_uuid,
            parent_message_uuid: parent,
            sender,
            text: text.to_string(),
            attachments,
            created_at: now,
            remote_id: None,
            server_updated_at: None,
            needs_sync: true,
            deleted_at: None,
        })
    }

    pub fn insert_message_with_uuid_and_state(
        &self,
        message_uuid: Uuid,
        session_uuid: Uuid,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<AttachmentMeta>,
        created_at: i64,
        deleted_at: Option<i64>,
        needs_sync: bool,
    ) -> Result<Message> {
        let sender: Sender = sender.parse()?;
        let encrypted_text = crypto::encrypt_string(text, &self.key)?;
        let attachments_json = self.serialize_attachments(&attachments)?;
        let deleted_value = deleted_at.map(Value::Integer).unwrap_or(Value::Null);
        let needs_sync_value = if needs_sync { 1 } else { 0 };

        self.backend.execute(
            "INSERT INTO messages (message_uuid, session_uuid, parent_message_uuid, sender, text, attachments, created_at, remote_id, server_updated_at, needs_sync, deleted_at) \
             VALUES (?, ?, ?, ?, ?, ?, ?, NULL, NULL, ?, ?) \
             ON CONFLICT(message_uuid) DO NOTHING",
            &[
                Value::Text(message_uuid.to_string()),
                Value::Text(session_uuid.to_string()),
                parent
                    .map(|value| Value::Text(value.to_string()))
                    .unwrap_or(Value::Null),
                Value::Text(sender.as_str().to_string()),
                Value::Blob(encrypted_text),
                attachments_json
                    .map(Value::Text)
                    .unwrap_or(Value::Null),
                Value::Integer(created_at),
                Value::Integer(needs_sync_value),
                deleted_value,
            ],
        )?;

        Ok(Message {
            uuid: message_uuid,
            session_uuid,
            parent_message_uuid: parent,
            sender,
            text: text.to_string(),
            attachments,
            created_at,
            remote_id: None,
            server_updated_at: None,
            needs_sync,
            deleted_at,
        })
    }

    pub fn get_messages(&self, session_uuid: Uuid) -> Result<Vec<Message>> {
        let rows = self.backend.query(
            "SELECT message_uuid, session_uuid, parent_message_uuid, sender, text, attachments, created_at, remote_id, server_updated_at, needs_sync, deleted_at \
             FROM messages WHERE session_uuid = ? AND deleted_at IS NULL ORDER BY created_at ASC, message_uuid ASC",
            &[Value::Text(session_uuid.to_string())],
        )?;
        rows.iter().map(|row| self.message_from_row(row)).collect()
    }

    pub fn get_messages_needing_sync(&self, session_uuid: Uuid) -> Result<Vec<Message>> {
        let rows = self.backend.query(
            "SELECT message_uuid, session_uuid, parent_message_uuid, sender, text, attachments, created_at, remote_id, server_updated_at, needs_sync, deleted_at \
             FROM messages WHERE session_uuid = ? AND needs_sync = 1 AND deleted_at IS NULL ORDER BY created_at ASC, message_uuid ASC",
            &[Value::Text(session_uuid.to_string())],
        )?;
        rows.iter().map(|row| self.message_from_row(row)).collect()
    }

    pub fn update_message_text(&self, uuid: Uuid, text: &str) -> Result<()> {
        let now = self.clock.now_us();
        let encrypted_text = crypto::encrypt_string(text, &self.key)?;
        self.backend.transaction(|tx| {
            let row = tx.query_row(
                "SELECT session_uuid FROM messages WHERE message_uuid = ? AND deleted_at IS NULL",
                &[Value::Text(uuid.to_string())],
            )?;
            let row = row.ok_or(Error::NotFound {
                entity: EntityType::Message,
                id: uuid,
            })?;
            let session_uuid = Uuid::parse_str(&row.get_string(0)?)?;

            let affected = tx.execute(
                "UPDATE messages SET text = ?, needs_sync = 1, server_updated_at = NULL WHERE message_uuid = ? AND deleted_at IS NULL",
                &[Value::Blob(encrypted_text), Value::Text(uuid.to_string())],
            )?;
            ensure_row_updated(affected, EntityType::Message, uuid)?;

            self.touch_session(tx, session_uuid, now)
        })
    }

    pub fn delete_message(&self, uuid: Uuid) -> Result<()> {
        let now = self.clock.now_us();
        self.backend.transaction(|tx| {
            let row = tx.query_row(
                "SELECT session_uuid FROM messages WHERE message_uuid = ? AND deleted_at IS NULL",
                &[Value::Text(uuid.to_string())],
            )?;
            let row = row.ok_or(Error::NotFound {
                entity: EntityType::Message,
                id: uuid,
            })?;
            let session_uuid = Uuid::parse_str(&row.get_string(0)?)?;

            let affected = tx.execute(
                "UPDATE messages SET deleted_at = ?, server_updated_at = NULL WHERE message_uuid = ? AND deleted_at IS NULL",
                &[Value::Integer(now), Value::Text(uuid.to_string())],
            )?;
            ensure_row_updated(affected, EntityType::Message, uuid)?;

            self.touch_session(tx, session_uuid, now)
        })
    }

    pub fn mark_session_synced(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE sessions SET remote_id = ?, needs_sync = 0 WHERE session_uuid = ?",
            &[
                Value::Text(remote_id.to_string()),
                Value::Text(uuid.to_string()),
            ],
        )?;
        ensure_row_updated(affected, EntityType::Session, uuid)
    }

    pub fn get_session_remote_id(&self, uuid: Uuid) -> Result<Option<String>> {
        let row = self.backend.query_row(
            "SELECT remote_id FROM sessions WHERE session_uuid = ?",
            &[Value::Text(uuid.to_string())],
        )?;
        let remote_id = match row {
            Some(row) => row.get_optional_string(0)?,
            None => None,
        };
        Ok(remote_id)
    }

    pub fn set_session_remote_id(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE sessions SET remote_id = ? WHERE session_uuid = ?",
            &[
                Value::Text(remote_id.to_string()),
                Value::Text(uuid.to_string()),
            ],
        )?;
        ensure_row_updated(affected, EntityType::Session, uuid)
    }

    pub fn get_session_uuid_by_remote_id(&self, remote_id: &str) -> Result<Option<Uuid>> {
        let row = self.backend.query_row(
            "SELECT session_uuid FROM sessions WHERE remote_id = ?",
            &[Value::Text(remote_id.to_string())],
        )?;
        let uuid = match row {
            Some(row) => {
                let value = row.get_string(0)?;
                Some(Uuid::parse_str(&value)?)
            }
            None => None,
        };
        Ok(uuid)
    }

    pub fn set_session_server_updated_at(&self, uuid: Uuid, updated_at: i64) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE sessions SET server_updated_at = ? WHERE session_uuid = ?",
            &[Value::Integer(updated_at), Value::Text(uuid.to_string())],
        )?;
        ensure_row_updated(affected, EntityType::Session, uuid)
    }

    pub fn set_message_server_updated_at(&self, uuid: Uuid, updated_at: i64) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE messages SET server_updated_at = ? WHERE message_uuid = ?",
            &[Value::Integer(updated_at), Value::Text(uuid.to_string())],
        )?;
        ensure_row_updated(affected, EntityType::Message, uuid)
    }

    pub fn set_message_remote_id(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE messages SET remote_id = ? WHERE message_uuid = ?",
            &[
                Value::Text(remote_id.to_string()),
                Value::Text(uuid.to_string()),
            ],
        )?;
        ensure_row_updated(affected, EntityType::Message, uuid)
    }

    pub fn get_message_remote_id(&self, uuid: Uuid) -> Result<Option<String>> {
        let row = self.backend.query_row(
            "SELECT remote_id FROM messages WHERE message_uuid = ?",
            &[Value::Text(uuid.to_string())],
        )?;
        let remote_id = match row {
            Some(row) => row.get_optional_string(0)?,
            None => None,
        };
        Ok(remote_id)
    }

    pub fn get_message_uuid_by_remote_id(&self, remote_id: &str) -> Result<Option<Uuid>> {
        let row = self.backend.query_row(
            "SELECT message_uuid FROM messages WHERE remote_id = ?",
            &[Value::Text(remote_id.to_string())],
        )?;
        let uuid = match row {
            Some(row) => {
                let value = row.get_string(0)?;
                Some(Uuid::parse_str(&value)?)
            }
            None => None,
        };
        Ok(uuid)
    }

    pub fn mark_all_needs_sync(&self) -> Result<()> {
        self.backend.execute(
            "UPDATE sessions SET needs_sync = 1 WHERE deleted_at IS NULL",
            &[],
        )?;
        self.backend.execute(
            "UPDATE messages SET needs_sync = 1 WHERE deleted_at IS NULL",
            &[],
        )?;
        Ok(())
    }

    pub fn clear_all_server_timestamps(&self) -> Result<()> {
        self.backend
            .execute("UPDATE sessions SET server_updated_at = NULL", &[])?;
        self.backend
            .execute("UPDATE messages SET server_updated_at = NULL", &[])?;
        Ok(())
    }

    pub fn reset_sync_state(&self) -> Result<()> {
        self.backend.execute(
            "UPDATE sessions SET remote_id = NULL, server_updated_at = NULL, \
             needs_sync = CASE WHEN deleted_at IS NULL THEN 1 ELSE needs_sync END",
            &[],
        )?;
        self.backend.execute(
            "UPDATE messages SET remote_id = NULL, server_updated_at = NULL, \
             needs_sync = CASE WHEN deleted_at IS NULL THEN 1 ELSE needs_sync END",
            &[],
        )?;
        Ok(())
    }

    pub fn mark_message_synced(&self, uuid: Uuid) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE messages SET needs_sync = 0 WHERE message_uuid = ? AND deleted_at IS NULL",
            &[Value::Text(uuid.to_string())],
        )?;
        ensure_row_updated(affected, EntityType::Message, uuid)
    }

    pub fn upsert_session_from_remote(
        &self,
        session_uuid: Uuid,
        remote_id: &str,
        title: &str,
        created_at: i64,
        updated_at: i64,
    ) -> Result<Session> {
        let encrypted_title = crypto::encrypt_string(title, &self.key)?;
        self.backend.execute(
            "INSERT INTO sessions (session_uuid, title, created_at, updated_at, remote_id, needs_sync, deleted_at) \
             VALUES (?, ?, ?, ?, ?, 0, NULL) \
             ON CONFLICT(session_uuid) DO UPDATE SET \
               title = CASE WHEN sessions.needs_sync = 1 THEN sessions.title ELSE excluded.title END, \
               created_at = MIN(sessions.created_at, excluded.created_at), \
               updated_at = MAX(sessions.updated_at, excluded.updated_at), \
               remote_id = COALESCE(sessions.remote_id, excluded.remote_id), \
               needs_sync = CASE WHEN sessions.needs_sync = 1 THEN 1 ELSE excluded.needs_sync END, \
               deleted_at = NULL",
            &[
                Value::Text(session_uuid.to_string()),
                Value::Blob(encrypted_title),
                Value::Integer(created_at),
                Value::Integer(updated_at),
                Value::Text(remote_id.to_string()),
            ],
        )?;

        let session = self.get_session(session_uuid)?.ok_or(Error::NotFound {
            entity: EntityType::Session,
            id: session_uuid,
        })?;
        Ok(session)
    }

    pub fn apply_session_tombstone(&self, session_uuid: Uuid, deleted_at: i64) -> Result<()> {
        self.backend.transaction(|tx| {
            tx.execute(
                "UPDATE messages SET deleted_at = ? WHERE session_uuid = ? AND deleted_at IS NULL",
                &[
                    Value::Integer(deleted_at),
                    Value::Text(session_uuid.to_string()),
                ],
            )?;
            tx.execute(
                "UPDATE sessions SET deleted_at = ?, needs_sync = 0 WHERE session_uuid = ?",
                &[
                    Value::Integer(deleted_at),
                    Value::Text(session_uuid.to_string()),
                ],
            )?;
            Ok(())
        })
    }

    pub fn upsert_message_from_remote(
        &self,
        message_uuid: Uuid,
        session_uuid: Uuid,
        remote_id: &str,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<AttachmentMeta>,
        created_at: i64,
    ) -> Result<Message> {
        let sender: Sender = sender.parse()?;
        let encrypted_text = crypto::encrypt_string(text, &self.key)?;
        let attachments_json = self.serialize_attachments(&attachments)?;

        self.backend.execute(
            "INSERT INTO messages (message_uuid, session_uuid, parent_message_uuid, sender, text, attachments, created_at, remote_id, needs_sync, deleted_at) \
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, NULL) \
             ON CONFLICT(message_uuid) DO UPDATE SET \
               session_uuid = excluded.session_uuid, \
               parent_message_uuid = excluded.parent_message_uuid, \
               sender = excluded.sender, \
               text = excluded.text, \
               attachments = excluded.attachments, \
               created_at = MIN(messages.created_at, excluded.created_at), \
               remote_id = COALESCE(messages.remote_id, excluded.remote_id), \
               needs_sync = CASE WHEN messages.needs_sync = 1 THEN 1 ELSE excluded.needs_sync END, \
               deleted_at = NULL",
            &[
                Value::Text(message_uuid.to_string()),
                Value::Text(session_uuid.to_string()),
                parent
                    .map(|value| Value::Text(value.to_string()))
                    .unwrap_or(Value::Null),
                Value::Text(sender.as_str().to_string()),
                Value::Blob(encrypted_text),
                attachments_json
                    .map(Value::Text)
                    .unwrap_or(Value::Null),
                Value::Integer(created_at),
                Value::Text(remote_id.to_string()),
            ],
        )?;

        let _ = self.touch_session_remote(session_uuid, created_at);

        Ok(Message {
            uuid: message_uuid,
            session_uuid,
            parent_message_uuid: parent,
            sender,
            text: text.to_string(),
            attachments,
            created_at,
            remote_id: Some(remote_id.to_string()),
            server_updated_at: None,
            needs_sync: false,
            deleted_at: None,
        })
    }

    pub fn apply_message_tombstone(&self, message_uuid: Uuid, deleted_at: i64) -> Result<()> {
        self.backend.execute(
            "UPDATE messages SET deleted_at = ? WHERE message_uuid = ?",
            &[
                Value::Integer(deleted_at),
                Value::Text(message_uuid.to_string()),
            ],
        )?;
        Ok(())
    }

    pub fn get_pending_deletions(&self) -> Result<Vec<(EntityType, Uuid)>> {
        let session_rows = self.backend.query(
            "SELECT session_uuid FROM sessions WHERE remote_id IS NOT NULL AND deleted_at IS NOT NULL ORDER BY deleted_at ASC",
            &[],
        )?;

        let mut deletions = Vec::new();
        for row in session_rows {
            let uuid = Uuid::parse_str(&row.get_string(0)?)?;
            deletions.push((EntityType::Session, uuid));
        }

        let message_rows = self.backend.query(
            "SELECT messages.message_uuid \
             FROM messages \
             JOIN sessions ON messages.session_uuid = sessions.session_uuid \
             WHERE messages.deleted_at IS NOT NULL \
               AND sessions.remote_id IS NOT NULL \
               AND sessions.deleted_at IS NULL \
             ORDER BY messages.deleted_at ASC",
            &[],
        )?;

        for row in message_rows {
            let uuid = Uuid::parse_str(&row.get_string(0)?)?;
            deletions.push((EntityType::Message, uuid));
        }

        Ok(deletions)
    }

    pub fn get_deleted_sessions(&self) -> Result<Vec<(Uuid, i64)>> {
        let rows = self.backend.query(
            "SELECT session_uuid, deleted_at FROM sessions WHERE deleted_at IS NOT NULL ORDER BY deleted_at ASC",
            &[],
        )?;
        rows.iter()
            .map(|row| {
                let uuid = Uuid::parse_str(&row.get_string(0)?)?;
                let deleted_at = row.get_i64(1)?;
                Ok((uuid, deleted_at))
            })
            .collect()
    }

    pub fn get_deleted_messages(&self) -> Result<Vec<(Uuid, i64)>> {
        let rows = self.backend.query(
            "SELECT messages.message_uuid, messages.deleted_at \
             FROM messages \
             JOIN sessions ON messages.session_uuid = sessions.session_uuid \
             WHERE messages.deleted_at IS NOT NULL \
               AND sessions.deleted_at IS NULL \
             ORDER BY messages.deleted_at ASC",
            &[],
        )?;
        rows.iter()
            .map(|row| {
                let uuid = Uuid::parse_str(&row.get_string(0)?)?;
                let deleted_at = row.get_i64(1)?;
                Ok((uuid, deleted_at))
            })
            .collect()
    }

    pub fn hard_delete(&self, entity_type: EntityType, uuid: Uuid) -> Result<()> {
        match entity_type {
            EntityType::Session => {
                self.backend.execute(
                    "DELETE FROM sessions WHERE session_uuid = ?",
                    &[Value::Text(uuid.to_string())],
                )?;
            }
            EntityType::Message => {
                self.backend.execute(
                    "DELETE FROM messages WHERE message_uuid = ?",
                    &[Value::Text(uuid.to_string())],
                )?;
            }
        }
        Ok(())
    }

    fn session_from_row(&self, row: &crate::backend::Row) -> Result<Session> {
        let uuid = Uuid::parse_str(&row.get_string(0)?)?;
        let title_blob = row.get_blob(1)?;
        let title = crypto::decrypt_string(&title_blob, &self.key)?;
        let created_at = row.get_i64(2)?;
        let updated_at = row.get_i64(3)?;
        let server_updated_at = row.get_optional_i64(4)?;
        let remote_id = row.get_optional_string(5)?;
        let needs_sync = bool_from_i64(row.get_i64(6)?)?;
        let deleted_at = row.get_optional_i64(7)?;
        Ok(Session {
            uuid,
            title,
            created_at,
            updated_at,
            server_updated_at,
            remote_id,
            needs_sync,
            deleted_at,
        })
    }

    fn message_from_row(&self, row: &crate::backend::Row) -> Result<Message> {
        let uuid = Uuid::parse_str(&row.get_string(0)?)?;
        let session_uuid = Uuid::parse_str(&row.get_string(1)?)?;
        let parent_message_uuid = row
            .get_optional_string(2)?
            .map(|value| Uuid::parse_str(&value))
            .transpose()?;
        let sender: Sender = row.get_string(3)?.parse()?;
        let text_blob = row.get_blob(4)?;
        let text = crypto::decrypt_string(&text_blob, &self.key)?;
        let attachments_json = row.get_optional_string(5)?;
        let attachments = self.deserialize_attachments(attachments_json)?;
        let created_at = row.get_i64(6)?;
        let remote_id = row.get_optional_string(7)?;
        let server_updated_at = row.get_optional_i64(8)?;
        let needs_sync = bool_from_i64(row.get_i64(9)?)?;
        let deleted_at = row.get_optional_i64(10)?;

        Ok(Message {
            uuid,
            session_uuid,
            parent_message_uuid,
            sender,
            text,
            attachments,
            created_at,
            remote_id,
            server_updated_at,
            needs_sync,
            deleted_at,
        })
    }

    fn serialize_attachments(&self, attachments: &[AttachmentMeta]) -> Result<Option<String>> {
        if attachments.is_empty() {
            return Ok(None);
        }
        let mut stored = Vec::with_capacity(attachments.len());
        for attachment in attachments {
            stored.push(self.attachment_to_stored(attachment)?);
        }
        Ok(Some(serde_json::to_string(&stored)?))
    }

    fn deserialize_attachments(&self, raw: Option<String>) -> Result<Vec<AttachmentMeta>> {
        let stored = parse_stored_attachments(raw)?;
        stored
            .into_iter()
            .map(|attachment| self.stored_to_attachment(attachment))
            .collect()
    }

    fn attachment_to_stored(&self, attachment: &AttachmentMeta) -> Result<StoredAttachment> {
        Ok(StoredAttachment {
            id: attachment.id.clone(),
            kind: attachment.kind,
            size: attachment.size,
            encrypted_name: crypto::encrypt_json_field(&attachment.name, &self.key)?,
        })
    }

    fn stored_to_attachment(&self, attachment: StoredAttachment) -> Result<AttachmentMeta> {
        Ok(AttachmentMeta {
            id: attachment.id,
            kind: attachment.kind,
            size: attachment.size,
            name: crypto::decrypt_json_field(&attachment.encrypted_name, &self.key)?,
        })
    }

    fn touch_session<T: BackendTx>(
        &self,
        backend: &T,
        session_uuid: Uuid,
        updated_at: i64,
    ) -> Result<()> {
        let affected = backend.execute(
            "UPDATE sessions SET updated_at = ?, needs_sync = 1, server_updated_at = NULL WHERE session_uuid = ? AND deleted_at IS NULL",
            &[Value::Integer(updated_at), Value::Text(session_uuid.to_string())],
        )?;
        ensure_row_updated(affected, EntityType::Session, session_uuid)
    }

    fn touch_session_remote(&self, session_uuid: Uuid, updated_at: i64) -> Result<()> {
        let affected = self.backend.execute(
            "UPDATE sessions SET updated_at = MAX(updated_at, ?) WHERE session_uuid = ? AND deleted_at IS NULL",
            &[Value::Integer(updated_at), Value::Text(session_uuid.to_string())],
        )?;
        ensure_row_updated(affected, EntityType::Session, session_uuid)
    }
}

#[cfg(feature = "sqlite")]
impl ChatDb<crate::backend::sqlite::SqliteBackend> {
    pub fn open_sqlite(
        path: impl AsRef<std::path::Path>,
        key: Vec<u8>,
        clock: Arc<dyn Clock>,
        uuid_gen: Arc<dyn UuidGen>,
    ) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open(path)?;
        Self::new(backend, key, clock, uuid_gen)
    }

    pub fn open_sqlite_with_defaults(
        path: impl AsRef<std::path::Path>,
        key: Vec<u8>,
    ) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open(path)?;
        Self::new_with_defaults(backend, key)
    }

    pub fn open_in_memory(key: Vec<u8>) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open_in_memory()?;
        Self::new_with_defaults(backend, key)
    }
}

fn validate_key(key: Vec<u8>) -> Result<Zeroizing<Vec<u8>>> {
    if key.len() != crypto::KEY_BYTES {
        return Err(Error::InvalidKeyLength {
            expected: crypto::KEY_BYTES,
            actual: key.len(),
        });
    }
    Ok(Zeroizing::new(key))
}

fn bool_from_i64(value: i64) -> Result<bool> {
    match value {
        0 => Ok(false),
        1 => Ok(true),
        other => Err(Error::Row(format!("invalid bool value {other}"))),
    }
}

fn ensure_row_updated(affected: usize, entity: EntityType, uuid: Uuid) -> Result<()> {
    if affected == 0 {
        return Err(Error::NotFound { entity, id: uuid });
    }
    Ok(())
}

fn parse_stored_attachments(raw: Option<String>) -> Result<Vec<StoredAttachment>> {
    let Some(raw) = raw else {
        return Ok(Vec::new());
    };
    if raw.trim().is_empty() {
        return Ok(Vec::new());
    }
    Ok(serde_json::from_str(&raw)?)
}

#[cfg(all(test, feature = "sqlite"))]
mod tests {
    use std::collections::VecDeque;
    use std::sync::atomic::{AtomicI64, Ordering};
    use std::sync::{Arc, Mutex};

    use uuid::Uuid;

    use super::*;
    use crate::backend::sqlite::SqliteBackend;
    use crate::backend::{BackendTx, RowExt, Value};
    use crate::crypto::KEY_BYTES;
    use crate::models::{AttachmentKind, AttachmentMeta};

    #[derive(Debug)]
    struct StepClock {
        current: AtomicI64,
        step: i64,
    }

    impl StepClock {
        fn new(start: i64, step: i64) -> Self {
            Self {
                current: AtomicI64::new(start),
                step,
            }
        }
    }

    impl Clock for StepClock {
        fn now_us(&self) -> i64 {
            self.current.fetch_add(self.step, Ordering::SeqCst)
        }
    }

    #[derive(Debug)]
    struct TestUuidGen {
        uuids: Mutex<VecDeque<Uuid>>,
    }

    impl TestUuidGen {
        fn new(uuids: Vec<Uuid>) -> Self {
            Self {
                uuids: Mutex::new(uuids.into()),
            }
        }
    }

    impl UuidGen for TestUuidGen {
        fn new_uuid(&self) -> Uuid {
            self.uuids
                .lock()
                .expect("uuid lock poisoned")
                .pop_front()
                .expect("uuid queue empty")
        }
    }

    fn make_db(uuids: Vec<Uuid>, clock: Arc<dyn Clock>) -> ChatDb<SqliteBackend> {
        let backend = SqliteBackend::open_in_memory().unwrap();
        ChatDb::new(
            backend,
            vec![1u8; KEY_BYTES],
            clock,
            Arc::new(TestUuidGen::new(uuids)),
        )
        .unwrap()
    }

    #[test]
    fn create_and_get_session_encrypts_title() {
        let session_id = Uuid::from_u128(1);
        let clock = Arc::new(StepClock::new(100, 1));
        let db = make_db(vec![session_id], clock);

        let session = db.create_session("hello").unwrap();
        assert_eq!(session.uuid, session_id);
        assert_eq!(session.title, "hello");
        assert!(session.needs_sync);

        let fetched = db.get_session(session_id).unwrap().unwrap();
        assert_eq!(fetched.title, "hello");

        let row = db
            .backend
            .query_row(
                "SELECT title FROM sessions WHERE session_uuid = ?",
                &[Value::Text(session_id.to_string())],
            )
            .unwrap()
            .unwrap();
        let stored = row.get_blob(0).unwrap();
        assert!(stored.len() >= crypto::HEADER_BYTES);
        assert_ne!(stored, b"hello".to_vec());
    }

    #[test]
    fn message_updates_touch_session() {
        let session_id = Uuid::from_u128(2);
        let message_id = Uuid::from_u128(3);
        let clock = Arc::new(StepClock::new(10, 1));
        let db = make_db(vec![session_id, message_id], clock.clone());

        db.create_session("title").unwrap();
        let after_create = db.get_session(session_id).unwrap().unwrap().updated_at;

        let message = db
            .insert_message(session_id, "self", "hello", None, Vec::new())
            .unwrap();
        assert_eq!(message.uuid, message_id);

        let after_insert = db.get_session(session_id).unwrap().unwrap().updated_at;
        assert!(after_insert > after_create);

        db.update_message_text(message_id, "updated").unwrap();
        let after_update = db.get_session(session_id).unwrap().unwrap().updated_at;
        assert!(after_update > after_insert);
    }

    #[test]
    fn delete_session_soft_deletes_messages() {
        let session_id = Uuid::from_u128(4);
        let message_id = Uuid::from_u128(5);
        let clock = Arc::new(StepClock::new(1, 1));
        let db = make_db(vec![session_id, message_id], clock);

        db.create_session("title").unwrap();
        db.insert_message(session_id, "other", "hi", None, Vec::new())
            .unwrap();

        db.delete_session(session_id).unwrap();
        assert!(db.get_session(session_id).unwrap().is_none());

        let row = db
            .backend
            .query_row(
                "SELECT deleted_at FROM messages WHERE message_uuid = ?",
                &[Value::Text(message_id.to_string())],
            )
            .unwrap()
            .unwrap();
        assert!(row.get_optional_i64(0).unwrap().is_some());
    }

    #[test]
    fn attachment_metadata_is_encrypted_in_json() {
        let session_id = Uuid::from_u128(6);
        let message_id = Uuid::from_u128(7);
        let clock = Arc::new(StepClock::new(50, 1));
        let db = make_db(vec![session_id, message_id], clock.clone());

        db.create_session("title").unwrap();

        let attachments = vec![
            AttachmentMeta {
                id: "att-1".to_string(),
                kind: AttachmentKind::Image,
                size: 123,
                name: "photo.jpg".to_string(),
            },
            AttachmentMeta {
                id: "att-2".to_string(),
                kind: AttachmentKind::Document,
                size: 456,
                name: "doc.pdf".to_string(),
            },
        ];

        db.insert_message(session_id, "self", "hello", None, attachments)
            .unwrap();

        let row = db
            .backend
            .query_row(
                "SELECT attachments FROM messages WHERE message_uuid = ?",
                &[Value::Text(message_id.to_string())],
            )
            .unwrap()
            .unwrap();
        let json = row.get_optional_string(0).unwrap().unwrap();
        let stored: Vec<StoredAttachment> = serde_json::from_str(&json).unwrap();
        assert_eq!(stored.len(), 2);
        assert!(stored[0].encrypted_name.starts_with("enc:v1:"));
        assert!(!stored[0].encrypted_name.contains("photo.jpg"));
    }

    #[test]
    fn invalid_sender_is_rejected() {
        let session_id = Uuid::from_u128(8);
        let message_id = Uuid::from_u128(9);
        let clock = Arc::new(StepClock::new(1, 1));
        let db = make_db(vec![session_id, message_id], clock);

        db.create_session("title").unwrap();
        let err = db
            .insert_message(session_id, "invalid", "hello", None, Vec::new())
            .unwrap_err();

        match err {
            Error::InvalidSender(_) => {}
            other => panic!("unexpected error: {other:?}"),
        }
    }
}
