use std::sync::Arc;

use uuid::Uuid;

use crate::attachments_db::{AttachmentUploadRow, AttachmentsDb, UploadState};
use crate::db::ChatDb;
use crate::models::{AttachmentMeta, EntityType, Message, Session};
use crate::traits::{Clock, UuidGen};
use crate::Result;

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
        let _ = self.attachments.delete_attachment_tracking_for_session(uuid);
        self.chat.delete_session(uuid)
    }

    pub fn insert_message(
        &self,
        session_uuid: Uuid,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<AttachmentMeta>,
    ) -> Result<Message> {
        let message = self
            .chat
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

    pub fn get_messages(&self, session_uuid: Uuid) -> Result<Vec<Message>> {
        self.chat.get_messages(session_uuid)
    }

    pub fn update_message_text(&self, uuid: Uuid, text: &str) -> Result<()> {
        self.chat.update_message_text(uuid, text)
    }

    pub fn delete_message(&self, uuid: Uuid) -> Result<()> {
        let _ = self.attachments.delete_attachment_tracking_for_message(uuid);
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

    pub fn set_attachment_upload_state(&self, attachment_id: &str, state: UploadState) -> Result<()> {
        self.attachments.set_attachment_upload_state(attachment_id, state)
    }

    pub fn mark_attachment_uploaded(&self, attachment_id: &str) -> Result<()> {
        self.attachments.mark_attachment_uploaded(attachment_id)
    }

    pub fn get_pending_uploads_for_session(
        &self,
        session_uuid: Uuid,
    ) -> Result<Vec<AttachmentUploadRow>> {
        self.attachments.get_pending_uploads_for_session(session_uuid)
    }

    pub fn get_pending_uploads_for_message(
        &self,
        message_uuid: Uuid,
    ) -> Result<Vec<AttachmentUploadRow>> {
        self.attachments.get_pending_uploads_for_message(message_uuid)
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

    pub fn get_sessions_needing_sync(&self) -> Result<Vec<Session>> {
        self.chat.get_sessions_needing_sync()
    }

    pub fn get_pending_deletions(&self) -> Result<Vec<(EntityType, Uuid)>> {
        self.chat.get_pending_deletions()
    }

    pub fn hard_delete(&self, entity_type: EntityType, uuid: Uuid) -> Result<()> {
        self.chat.hard_delete(entity_type, uuid)
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
