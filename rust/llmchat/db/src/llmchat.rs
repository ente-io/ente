use std::sync::Arc;

use uuid::Uuid;

use crate::Result;
use crate::attachments_db::{AttachmentUploadRow, AttachmentsDb, UploadState};
use crate::db::ChatDb;
use crate::models::{AttachmentMeta, EntityType, Message, Session};
use crate::traits::{Clock, UuidGen};

/// High-level DB that ties together the main chat DB and the attachments upload-state DB.
pub struct LlmChatDb<B: crate::Backend> {
    pub chat: ChatDb<B>,
    pub attachments: AttachmentsDb<B>,
}

impl<B: crate::Backend> LlmChatDb<B> {
    pub fn new(chat: ChatDb<B>, attachments: AttachmentsDb<B>) -> Self {
        Self { chat, attachments }
    }

    pub fn create_session(&self, title: &str) -> Result<Session> {
        self.chat.create_session(title)
    }

    pub fn get_session(&self, uuid: Uuid) -> Result<Option<Session>> {
        self.chat.get_session(uuid)
    }

    pub fn list_sessions(&self) -> Result<Vec<Session>> {
        self.chat.list_sessions()
    }

    pub fn update_session_title(&self, uuid: Uuid, title: &str) -> Result<()> {
        self.chat.update_session_title(uuid, title)
    }

    pub fn delete_session(&self, uuid: Uuid) -> Result<()> {
        // Best-effort cleanup in attachments DB. If this fails, still delete session.
        let _ = self
            .attachments
            .delete_attachment_tracking_for_session(uuid);
        self.chat.delete_session(uuid)
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
        self.chat.upsert_session(
            session_uuid,
            title,
            created_at,
            updated_at,
            remote_id,
            needs_sync,
            deleted_at,
        )
    }

    pub fn insert_message(
        &self,
        session_uuid: Uuid,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<AttachmentMeta>,
    ) -> Result<Message> {
        let message =
            self.chat
                .insert_message(session_uuid, sender, text, parent, attachments.clone())?;

        for attachment in attachments {
            self.attachments.upsert_pending_attachment(
                &attachment.id,
                session_uuid,
                message.uuid,
                attachment.size,
            )?;
        }

        Ok(message)
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
        self.chat.insert_message_with_uuid_and_state(
            message_uuid,
            session_uuid,
            sender,
            text,
            parent,
            attachments,
            created_at,
            deleted_at,
            needs_sync,
        )
    }

    pub fn get_messages(&self, session_uuid: Uuid) -> Result<Vec<Message>> {
        self.chat.get_messages(session_uuid)
    }

    pub fn get_messages_needing_sync(&self, session_uuid: Uuid) -> Result<Vec<Message>> {
        self.chat.get_messages_needing_sync(session_uuid)
    }

    pub fn update_message_text(&self, uuid: Uuid, text: &str) -> Result<()> {
        self.chat.update_message_text(uuid, text)
    }

    pub fn delete_message(&self, uuid: Uuid) -> Result<()> {
        let _ = self
            .attachments
            .delete_attachment_tracking_for_message(uuid);
        self.chat.delete_message(uuid)
    }

    // Attachments DB APIs
    pub fn upsert_pending_attachment(
        &self,
        attachment_id: &str,
        session_uuid: Uuid,
        message_uuid: Uuid,
        size: i64,
    ) -> Result<()> {
        self.attachments
            .upsert_pending_attachment(attachment_id, session_uuid, message_uuid, size)
    }

    pub fn set_attachment_upload_state(
        &self,
        attachment_id: &str,
        state: UploadState,
    ) -> Result<()> {
        self.attachments
            .set_attachment_upload_state(attachment_id, state)
    }

    pub fn mark_attachment_uploaded(&self, attachment_id: &str) -> Result<()> {
        self.attachments.mark_attachment_uploaded(attachment_id)
    }

    pub fn get_pending_uploads_for_session(
        &self,
        session_uuid: Uuid,
    ) -> Result<Vec<AttachmentUploadRow>> {
        self.attachments
            .get_pending_uploads_for_session(session_uuid)
    }

    pub fn get_pending_uploads_for_message(
        &self,
        message_uuid: Uuid,
    ) -> Result<Vec<AttachmentUploadRow>> {
        self.attachments
            .get_pending_uploads_for_message(message_uuid)
    }

    pub fn delete_attachment_tracking_for_message(&self, message_uuid: Uuid) -> Result<()> {
        self.attachments
            .delete_attachment_tracking_for_message(message_uuid)
    }

    pub fn delete_attachment_tracking_for_session(&self, session_uuid: Uuid) -> Result<()> {
        self.attachments
            .delete_attachment_tracking_for_session(session_uuid)
    }

    // Sync helpers
    pub fn mark_session_synced(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        self.chat.mark_session_synced(uuid, remote_id)
    }

    pub fn get_session_remote_id(&self, uuid: Uuid) -> Result<Option<String>> {
        self.chat.get_session_remote_id(uuid)
    }

    pub fn set_session_remote_id(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        self.chat.set_session_remote_id(uuid, remote_id)
    }

    pub fn get_session_uuid_by_remote_id(&self, remote_id: &str) -> Result<Option<Uuid>> {
        self.chat.get_session_uuid_by_remote_id(remote_id)
    }

    pub fn mark_message_synced(&self, uuid: Uuid) -> Result<()> {
        self.chat.mark_message_synced(uuid)
    }

    pub fn set_message_remote_id(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        self.chat.set_message_remote_id(uuid, remote_id)
    }

    pub fn get_message_remote_id(&self, uuid: Uuid) -> Result<Option<String>> {
        self.chat.get_message_remote_id(uuid)
    }

    pub fn get_message_uuid_by_remote_id(&self, remote_id: &str) -> Result<Option<Uuid>> {
        self.chat.get_message_uuid_by_remote_id(remote_id)
    }

    pub fn get_sessions_needing_sync(&self) -> Result<Vec<Session>> {
        self.chat.get_sessions_needing_sync()
    }

    pub fn count_needing_sync(&self) -> Result<i64> {
        self.chat.count_needing_sync()
    }

    pub fn get_sessions_needing_sync_batch(
        &self,
        limit: i64,
        order_desc: bool,
    ) -> Result<Vec<Session>> {
        self.chat.get_sessions_needing_sync_batch(limit, order_desc)
    }

    pub fn set_session_server_updated_at(&self, uuid: Uuid, updated_at: i64) -> Result<()> {
        self.chat.set_session_server_updated_at(uuid, updated_at)
    }

    pub fn set_message_server_updated_at(&self, uuid: Uuid, updated_at: i64) -> Result<()> {
        self.chat.set_message_server_updated_at(uuid, updated_at)
    }

    pub fn get_pending_deletions(&self) -> Result<Vec<(EntityType, Uuid)>> {
        self.chat.get_pending_deletions()
    }

    pub fn get_deleted_sessions(&self) -> Result<Vec<(Uuid, i64)>> {
        self.chat.get_deleted_sessions()
    }

    pub fn get_deleted_messages(&self) -> Result<Vec<(Uuid, i64)>> {
        self.chat.get_deleted_messages()
    }

    pub fn hard_delete(&self, entity_type: EntityType, uuid: Uuid) -> Result<()> {
        self.chat.hard_delete(entity_type, uuid)
    }

    // Sync apply helpers
    pub fn upsert_session_from_remote(
        &self,
        session_uuid: Uuid,
        remote_id: &str,
        title: &str,
        created_at: i64,
        updated_at: i64,
    ) -> Result<Session> {
        self.chat
            .upsert_session_from_remote(session_uuid, remote_id, title, created_at, updated_at)
    }

    pub fn apply_session_tombstone(&self, session_uuid: Uuid, deleted_at: i64) -> Result<()> {
        self.chat.apply_session_tombstone(session_uuid, deleted_at)
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
        self.chat.upsert_message_from_remote(
            message_uuid,
            session_uuid,
            remote_id,
            sender,
            text,
            parent,
            attachments,
            created_at,
        )
    }

    pub fn apply_message_tombstone(&self, message_uuid: Uuid, deleted_at: i64) -> Result<()> {
        self.chat.apply_message_tombstone(message_uuid, deleted_at)
    }

    pub fn upsert_attachment_with_state(
        &self,
        attachment_id: &str,
        session_uuid: Uuid,
        message_uuid: Uuid,
        size: i64,
        remote_id: Option<&str>,
        state: UploadState,
    ) -> Result<()> {
        self.attachments.upsert_attachment_with_state(
            attachment_id,
            session_uuid,
            message_uuid,
            size,
            remote_id,
            state,
        )
    }

    pub fn set_attachment_remote_id(
        &self,
        attachment_id: &str,
        remote_id: Option<&str>,
    ) -> Result<()> {
        self.attachments
            .set_attachment_remote_id(attachment_id, remote_id)
    }

    pub fn get_attachment_remote_id(&self, attachment_id: &str) -> Result<Option<String>> {
        self.attachments.get_attachment_remote_id(attachment_id)
    }

    pub fn get_attachment_upload_state(&self, attachment_id: &str) -> Result<Option<UploadState>> {
        self.attachments.get_upload_state(attachment_id)
    }

    pub fn mark_all_needs_sync(&self) -> Result<()> {
        self.chat.mark_all_needs_sync()
    }

    pub fn clear_all_server_timestamps(&self) -> Result<()> {
        self.chat.clear_all_server_timestamps()
    }

    pub fn reset_sync_state(&self) -> Result<()> {
        self.chat.reset_sync_state()?;
        self.attachments.reset_all_upload_state()?;
        Ok(())
    }

    pub fn reset_attachment_sync_state(&self) -> Result<()> {
        self.attachments.reset_all_upload_state()
    }
}

#[cfg(feature = "sqlite")]
impl LlmChatDb<crate::backend::sqlite::SqliteBackend> {
    pub fn open_sqlite(
        main_path: impl AsRef<std::path::Path>,
        attachments_path: impl AsRef<std::path::Path>,
        key: Vec<u8>,
        clock: Arc<dyn Clock>,
        uuid_gen: Arc<dyn UuidGen>,
    ) -> Result<Self> {
        let chat = ChatDb::open_sqlite(main_path, key, clock.clone(), uuid_gen)?;
        let attachments = AttachmentsDb::open_sqlite(attachments_path, clock)?;
        Ok(Self { chat, attachments })
    }

    pub fn open_sqlite_with_defaults(
        main_path: impl AsRef<std::path::Path>,
        attachments_path: impl AsRef<std::path::Path>,
        key: Vec<u8>,
    ) -> Result<Self> {
        let chat = ChatDb::open_sqlite_with_defaults(main_path, key)?;
        let attachments = AttachmentsDb::open_sqlite_with_defaults(attachments_path)?;
        Ok(Self { chat, attachments })
    }
}
