#![forbid(unsafe_code)]

pub mod attachments_db;
pub mod attachments_migrations;
pub mod attachments_schema;
pub mod backend;
pub mod crypto;
pub mod db;
pub mod error;
pub mod llmchat;
pub mod migrations;
pub mod models;
pub mod schema;
pub mod sync_state_db;
pub mod sync_state_schema;
pub mod traits;

pub use crate::attachments_db::{AttachmentUploadRow, AttachmentsDb, UploadState};
pub use crate::backend::{Backend, BackendTx, Row, Value};
pub use crate::db::ChatDb;
pub use crate::error::{Error, Result};
pub use crate::llmchat::LlmChatDb;
pub use crate::models::{AttachmentKind, AttachmentMeta, EntityType, Message, Sender, Session};
pub use crate::sync_state_db::{SyncEntityState, SyncStateDb};
pub use crate::traits::{
    AttachmentStore, Clock, FileMetaStore, FsAttachmentStore, MetaStore, RandomUuidGen,
    SystemClock, UuidGen,
};

#[cfg(feature = "sqlite")]
pub use crate::backend::sqlite::SqliteBackend;
