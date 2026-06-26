#[cfg(feature = "sqlite")]
use std::sync::Arc;

use uuid::Uuid;

use crate::db::Result;
use crate::db::attachments::{AttachmentUploadRow, AttachmentsDb, UploadState};
use crate::db::chat::ChatDb;
use crate::db::models::{Attachment, AttachmentMeta, Message, Session, SessionWithPreview};
#[cfg(feature = "sqlite")]
use crate::db::traits::{Clock, UuidGen};

/// High-level DB that ties together the main chat DB and the attachments upload-state DB.
pub struct Db<B: crate::db::Backend> {
    pub chat: ChatDb<B>,
    pub attachments: AttachmentsDb<B>,
}

impl<B: crate::db::Backend> Db<B> {
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

    pub fn list_all_sessions(&self) -> Result<Vec<Session>> {
        self.chat.list_all_sessions()
    }

    pub fn list_sessions_with_preview(&self) -> Result<Vec<SessionWithPreview>> {
        self.chat.list_sessions_with_preview()
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

    #[allow(clippy::too_many_arguments)]
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

    #[allow(clippy::too_many_arguments)]
    pub fn insert_message_with_uuid_and_state(
        &self,
        message_uuid: Uuid,
        session_uuid: Uuid,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<Attachment>,
        created_at: i64,
        deleted_at: Option<i64>,
        needs_sync: bool,
    ) -> Result<Message> {
        let attachment_metas: Vec<AttachmentMeta> = attachments
            .iter()
            .cloned()
            .map(AttachmentMeta::from)
            .collect();
        let message = self.chat.insert_message_with_uuid_and_state(
            message_uuid,
            session_uuid,
            sender,
            text,
            parent,
            attachment_metas,
            created_at,
            deleted_at,
            needs_sync,
        )?;

        for attachment in attachments {
            if attachment.uploaded_at.is_some() {
                self.attachments.upsert_attachment_with_state(
                    &attachment.id,
                    session_uuid,
                    message_uuid,
                    attachment.size,
                    None,
                    UploadState::Uploaded,
                )?;
            } else {
                self.attachments.upsert_pending_attachment(
                    &attachment.id,
                    session_uuid,
                    message_uuid,
                    attachment.size,
                )?;
            }
        }

        Ok(message)
    }

    #[allow(clippy::too_many_arguments)]
    pub fn insert_message_with_uuid(
        &self,
        message_uuid: Uuid,
        session_uuid: Uuid,
        sender: &str,
        text: &str,
        parent: Option<Uuid>,
        attachments: Vec<Attachment>,
        created_at: i64,
        deleted_at: Option<i64>,
    ) -> Result<Message> {
        self.insert_message_with_uuid_and_state(
            message_uuid,
            session_uuid,
            sender,
            text,
            parent,
            attachments,
            created_at,
            deleted_at,
            false,
        )
    }

    pub fn get_message(&self, uuid: Uuid) -> Result<Option<Message>> {
        self.chat.get_message(uuid)
    }

    pub fn get_messages(&self, session_uuid: Uuid) -> Result<Vec<Message>> {
        self.chat.get_messages(session_uuid)
    }

    pub fn get_messages_for_sync(
        &self,
        session_uuid: Uuid,
        include_deleted: bool,
    ) -> Result<Vec<Message>> {
        self.chat
            .get_messages_for_sync(session_uuid, include_deleted)
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

    pub fn get_uploads_for_message(&self, message_uuid: Uuid) -> Result<Vec<AttachmentUploadRow>> {
        self.attachments.get_uploads_for_message(message_uuid)
    }

    pub fn delete_attachment_tracking_for_message(&self, message_uuid: Uuid) -> Result<()> {
        self.attachments
            .delete_attachment_tracking_for_message(message_uuid)
    }

    pub fn delete_attachment_tracking_for_session(&self, session_uuid: Uuid) -> Result<()> {
        self.attachments
            .delete_attachment_tracking_for_session(session_uuid)
    }

    pub fn set_message_remote_id(&self, uuid: Uuid, remote_id: &str) -> Result<()> {
        self.chat.set_message_remote_id(uuid, remote_id)
    }

    #[allow(clippy::too_many_arguments)]
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
}

#[cfg(feature = "sqlite")]
impl Db<crate::db::backend::sqlite::SqliteBackend> {
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
