#![forbid(unsafe_code)]

pub mod attachments_db;
pub mod attachments_migrations;
pub mod attachments_schema;
pub mod backend;
pub mod chat_db;
pub mod crypto;
pub mod ensu;
pub mod error;
pub mod image;
pub mod migrations;
pub mod models;
pub mod schema;
pub mod traits;

pub use crate::db::attachments_db::{AttachmentUploadRow, AttachmentsDb, UploadState};
pub use crate::db::backend::{Backend, BackendTx, Row, Value};
pub use crate::db::chat_db::ChatDb;
pub use crate::db::ensu::EnsuDb;
pub use crate::db::error::{Error, Result};
pub use crate::db::image::{
    ATTACHMENT_IMAGE_JPEG_QUALITY, ATTACHMENT_IMAGE_MAX_LONG_EDGE, compress_attachment_image,
};
pub use crate::db::models::{
    Attachment, AttachmentKind, AttachmentMeta, EntityType, Message, Sender, Session,
    SessionWithPreview,
};
pub use crate::db::traits::{
    AttachmentStore, Clock, FileMetaStore, FsAttachmentStore, MetaStore, RandomUuidGen,
    SystemClock, UuidGen,
};

#[cfg(feature = "sqlite")]
pub use crate::db::backend::sqlite::SqliteBackend;
