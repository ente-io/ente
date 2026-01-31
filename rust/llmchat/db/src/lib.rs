#![forbid(unsafe_code)]

pub mod backend;
pub mod crypto;
pub mod db;
pub mod attachments_db;
pub mod attachments_migrations;
pub mod attachments_schema;
pub mod error;
pub mod migrations;
pub mod models;
pub mod schema;
pub mod traits;
pub mod llmchat;

pub use crate::backend::{Backend, BackendTx, Row, Value};
pub use crate::db::ChatDb;
pub use crate::attachments_db::{AttachmentsDb, AttachmentUploadRow, UploadState};
pub use crate::llmchat::LlmChatDb;
pub use crate::error::{Error, Result};
pub use crate::models::{
    AttachmentKind, AttachmentMeta, EntityType, Message, Sender, Session,
};
pub use crate::traits::{
    AttachmentStore, Clock, FileMetaStore, FsAttachmentStore, MetaStore, RandomUuidGen,
    SystemClock, UuidGen,
};

#[cfg(feature = "sqlite")]
pub use crate::backend::sqlite::SqliteBackend;
