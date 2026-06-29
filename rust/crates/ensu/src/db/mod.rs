#![forbid(unsafe_code)]

pub mod attachments;
pub mod backend;
pub mod chat;
pub mod crypto;
pub mod database;
pub mod error;
pub mod image;
pub mod models;
pub mod traits;

pub use crate::db::attachments::{AttachmentUploadRow, AttachmentsDb, UploadState};
pub use crate::db::backend::{Backend, BackendTx, Row, Value};
pub use crate::db::chat::ChatDb;
pub use crate::db::database::Db;
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
