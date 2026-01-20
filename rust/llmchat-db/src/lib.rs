#![forbid(unsafe_code)]

pub mod backend;
pub mod crypto;
pub mod db;
pub mod error;
pub mod migrations;
pub mod models;
pub mod schema;
pub mod traits;

pub use crate::backend::{Backend, BackendTx, Row, Value};
pub use crate::db::ChatDb;
pub use crate::error::{Error, Result};
pub use crate::models::{
    Attachment, AttachmentKind, EntityType, Message, Sender, Session,
};
pub use crate::traits::{
    AttachmentStore, Clock, FileMetaStore, FsAttachmentStore, MetaStore, RandomUuidGen,
    SystemClock, UuidGen,
};

#[cfg(feature = "sqlite")]
pub use crate::backend::sqlite::SqliteBackend;
