use llmchat_db as core;
use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error, uniffi::Error)]
pub enum DbError {
    #[error("{0}")]
    Message(String),
}

impl From<core::Error> for DbError {
    fn from(err: core::Error) -> Self {
        DbError::Message(err.to_string())
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct Session {
    pub uuid: String,
    pub title: String,
    pub created_at_us: i64,
    pub updated_at_us: i64,
    pub remote_id: Option<String>,
    pub needs_sync: bool,
    pub deleted_at_us: Option<i64>,
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum Sender {
    SelfUser,
    Other,
}

impl Sender {
    fn as_str(&self) -> &'static str {
        match self {
            Sender::SelfUser => "self",
            Sender::Other => "other",
        }
    }
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum AttachmentKind {
    Image,
    Document,
}

impl From<AttachmentKind> for core::AttachmentKind {
    fn from(value: AttachmentKind) -> Self {
        match value {
            AttachmentKind::Image => core::AttachmentKind::Image,
            AttachmentKind::Document => core::AttachmentKind::Document,
        }
    }
}

impl From<core::AttachmentKind> for AttachmentKind {
    fn from(value: core::AttachmentKind) -> Self {
        match value {
            core::AttachmentKind::Image => AttachmentKind::Image,
            core::AttachmentKind::Document => AttachmentKind::Document,
        }
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct AttachmentMeta {
    pub id: String,
    pub kind: AttachmentKind,
    pub size: i64,
    pub name: String,
}

impl From<AttachmentMeta> for core::AttachmentMeta {
    fn from(value: AttachmentMeta) -> Self {
        core::AttachmentMeta {
            id: value.id,
            kind: value.kind.into(),
            size: value.size,
            name: value.name,
        }
    }
}

impl From<core::AttachmentMeta> for AttachmentMeta {
    fn from(value: core::AttachmentMeta) -> Self {
        AttachmentMeta {
            id: value.id,
            kind: value.kind.into(),
            size: value.size,
            name: value.name,
        }
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct Message {
    pub uuid: String,
    pub session_uuid: String,
    pub parent_message_uuid: Option<String>,
    pub sender: Sender,
    pub text: String,
    pub attachments: Vec<AttachmentMeta>,
    pub created_at_us: i64,
    pub deleted_at_us: Option<i64>,
}

#[derive(uniffi::Object)]
pub struct LlmChatDb {
    inner: core::LlmChatDb<core::SqliteBackend>,
}

fn to_session(session: core::Session) -> Session {
    Session {
        uuid: session.uuid.to_string(),
        title: session.title,
        created_at_us: session.created_at,
        updated_at_us: session.updated_at,
        remote_id: session.remote_id,
        needs_sync: session.needs_sync,
        deleted_at_us: session.deleted_at,
    }
}

fn to_message(message: core::Message) -> Message {
    Message {
        uuid: message.uuid.to_string(),
        session_uuid: message.session_uuid.to_string(),
        parent_message_uuid: message.parent_message_uuid.map(|v| v.to_string()),
        sender: match message.sender {
            core::Sender::SelfUser => Sender::SelfUser,
            core::Sender::Other => Sender::Other,
        },
        text: message.text,
        attachments: message.attachments.into_iter().map(Into::into).collect(),
        created_at_us: message.created_at,
        deleted_at_us: message.deleted_at,
    }
}

#[uniffi::export]
impl LlmChatDb {
    #[uniffi::constructor]
    pub fn open(main_db_path: String, attachments_db_path: String, key: Vec<u8>) -> Result<Self, DbError> {
        let inner = core::LlmChatDb::open_sqlite_with_defaults(main_db_path, attachments_db_path, key)?;
        Ok(Self { inner })
    }

    pub fn create_session(&self, title: String) -> Result<Session, DbError> {
        Ok(to_session(self.inner.create_session(&title)?))
    }

    pub fn list_sessions(&self) -> Result<Vec<Session>, DbError> {
        Ok(self.inner.list_sessions()?.into_iter().map(to_session).collect())
    }

    pub fn get_session(&self, uuid: String) -> Result<Option<Session>, DbError> {
        let uuid = Uuid::parse_str(&uuid).map_err(|e| DbError::Message(e.to_string()))?;
        Ok(self.inner.get_session(uuid)?.map(to_session))
    }

    pub fn delete_session(&self, uuid: String) -> Result<(), DbError> {
        let uuid = Uuid::parse_str(&uuid).map_err(|e| DbError::Message(e.to_string()))?;
        Ok(self.inner.delete_session(uuid)?)
    }

    pub fn update_session_title(&self, uuid: String, title: String) -> Result<(), DbError> {
        let uuid = Uuid::parse_str(&uuid).map_err(|e| DbError::Message(e.to_string()))?;
        Ok(self.inner.update_session_title(uuid, &title)?)
    }

    pub fn insert_message(
        &self,
        session_uuid: String,
        sender: Sender,
        text: String,
        parent_message_uuid: Option<String>,
        attachments: Vec<AttachmentMeta>,
    ) -> Result<Message, DbError> {
        let session_uuid = Uuid::parse_str(&session_uuid).map_err(|e| DbError::Message(e.to_string()))?;
        let parent = parent_message_uuid
            .map(|v| Uuid::parse_str(&v))
            .transpose()
            .map_err(|e| DbError::Message(e.to_string()))?;

        let message = self.inner.insert_message(
            session_uuid,
            sender.as_str(),
            &text,
            parent,
            attachments.into_iter().map(Into::into).collect(),
        )?;
        Ok(to_message(message))
    }

    pub fn get_messages(&self, session_uuid: String) -> Result<Vec<Message>, DbError> {
        let session_uuid = Uuid::parse_str(&session_uuid).map_err(|e| DbError::Message(e.to_string()))?;
        Ok(self.inner.get_messages(session_uuid)?.into_iter().map(to_message).collect())
    }

    pub fn update_message_text(&self, uuid: String, text: String) -> Result<(), DbError> {
        let uuid = Uuid::parse_str(&uuid).map_err(|e| DbError::Message(e.to_string()))?;
        Ok(self.inner.update_message_text(uuid, &text)?)
    }
}
