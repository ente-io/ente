use std::sync::Arc;

use uuid::Uuid;

use crate::Result;
use crate::backend::{Backend, RowExt, Value};
use crate::traits::{Clock, SystemClock};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UploadState {
    Pending,
    Uploading,
    Uploaded,
    Failed,
}

impl UploadState {
    pub fn as_str(&self) -> &'static str {
        match self {
            UploadState::Pending => "pending",
            UploadState::Uploading => "uploading",
            UploadState::Uploaded => "uploaded",
            UploadState::Failed => "failed",
        }
    }
}

impl std::str::FromStr for UploadState {
    type Err = crate::Error;

    fn from_str(value: &str) -> std::result::Result<Self, Self::Err> {
        match value {
            "pending" => Ok(UploadState::Pending),
            "uploading" => Ok(UploadState::Uploading),
            "uploaded" => Ok(UploadState::Uploaded),
            "failed" => Ok(UploadState::Failed),
            _ => Err(crate::Error::Row(format!(
                "invalid upload_state value {value}"
            ))),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AttachmentUploadRow {
    pub attachment_id: String,
    pub session_uuid: Uuid,
    pub message_uuid: Uuid,
    pub size: i64,
    pub remote_id: Option<String>,
    pub upload_state: UploadState,
    pub uploaded_at: Option<i64>,
    pub updated_at: i64,
}

pub struct AttachmentsDb<B: Backend> {
    backend: B,
    clock: Arc<dyn Clock>,
}

impl<B: Backend> AttachmentsDb<B> {
    pub fn new(backend: B, clock: Arc<dyn Clock>) -> Result<Self> {
        crate::attachments_migrations::migrate(&backend)?;
        Ok(Self { backend, clock })
    }

    pub fn new_with_defaults(backend: B) -> Result<Self> {
        Self::new(backend, Arc::new(SystemClock))
    }

    pub fn upsert_pending_attachment(
        &self,
        attachment_id: &str,
        session_uuid: Uuid,
        message_uuid: Uuid,
        size: i64,
    ) -> Result<()> {
        let now = self.clock.now_us();
        // If row exists, do not overwrite an existing terminal state.
        // Only ensure it's present and updated.
        self.backend.execute(
            "INSERT INTO attachments (attachment_id, session_uuid, message_uuid, size, remote_id, upload_state, uploaded_at, updated_at) \
             VALUES (?, ?, ?, ?, NULL, 'pending', NULL, ?) \
             ON CONFLICT(attachment_id) DO UPDATE SET \
               session_uuid = excluded.session_uuid, \
               message_uuid = excluded.message_uuid, \
               size = excluded.size, \
               remote_id = attachments.remote_id, \
               updated_at = excluded.updated_at",
            &[
                Value::Text(attachment_id.to_string()),
                Value::Text(session_uuid.to_string()),
                Value::Text(message_uuid.to_string()),
                Value::Integer(size),
                Value::Integer(now),
            ],
        )?;
        Ok(())
    }

    pub fn set_attachment_upload_state(
        &self,
        attachment_id: &str,
        state: UploadState,
    ) -> Result<()> {
        let now = self.clock.now_us();
        self.backend.execute(
            "UPDATE attachments SET upload_state = ?, updated_at = ? WHERE attachment_id = ?",
            &[
                Value::Text(state.as_str().to_string()),
                Value::Integer(now),
                Value::Text(attachment_id.to_string()),
            ],
        )?;
        Ok(())
    }

    pub fn set_attachment_remote_id(
        &self,
        attachment_id: &str,
        remote_id: Option<&str>,
    ) -> Result<()> {
        let now = self.clock.now_us();
        let value = remote_id
            .map(|id| Value::Text(id.to_string()))
            .unwrap_or(Value::Null);
        self.backend.execute(
            "UPDATE attachments SET remote_id = ?, updated_at = ? WHERE attachment_id = ?",
            &[
                value,
                Value::Integer(now),
                Value::Text(attachment_id.to_string()),
            ],
        )?;
        Ok(())
    }

    pub fn get_attachment_remote_id(&self, attachment_id: &str) -> Result<Option<String>> {
        let row = self.backend.query_row(
            "SELECT remote_id FROM attachments WHERE attachment_id = ?",
            &[Value::Text(attachment_id.to_string())],
        )?;
        match row {
            Some(row) => Ok(row.get_optional_string(0)?),
            None => Ok(None),
        }
    }

    pub fn mark_attachment_uploaded(&self, attachment_id: &str) -> Result<()> {
        let now = self.clock.now_us();
        self.backend.execute(
            "UPDATE attachments SET upload_state = 'uploaded', uploaded_at = ?, updated_at = ? WHERE attachment_id = ?",
            &[
                Value::Integer(now),
                Value::Integer(now),
                Value::Text(attachment_id.to_string()),
            ],
        )?;
        Ok(())
    }

    pub fn reset_all_upload_state(&self) -> Result<()> {
        let now = self.clock.now_us();
        self.backend.execute(
            "UPDATE attachments SET upload_state = 'pending', remote_id = NULL, uploaded_at = NULL, updated_at = ?",
            &[Value::Integer(now)],
        )?;
        Ok(())
    }

    pub fn get_upload_state(&self, attachment_id: &str) -> Result<Option<UploadState>> {
        let row = self.backend.query_row(
            "SELECT upload_state FROM attachments WHERE attachment_id = ?",
            &[Value::Text(attachment_id.to_string())],
        )?;
        match row {
            Some(row) => {
                let state: UploadState = row.get_string(0)?.parse()?;
                Ok(Some(state))
            }
            None => Ok(None),
        }
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
        let now = self.clock.now_us();
        let uploaded_at = if state == UploadState::Uploaded {
            Value::Integer(now)
        } else {
            Value::Null
        };
        let remote_value = remote_id
            .map(|value| Value::Text(value.to_string()))
            .unwrap_or(Value::Null);
        self.backend.execute(
            "INSERT INTO attachments (attachment_id, session_uuid, message_uuid, size, remote_id, upload_state, uploaded_at, updated_at) \
             VALUES (?, ?, ?, ?, ?, ?, ?, ?) \
             ON CONFLICT(attachment_id) DO UPDATE SET \
               session_uuid = excluded.session_uuid, \
               message_uuid = excluded.message_uuid, \
               size = excluded.size, \
               remote_id = COALESCE(excluded.remote_id, attachments.remote_id), \
               upload_state = excluded.upload_state, \
               uploaded_at = excluded.uploaded_at, \
               updated_at = excluded.updated_at",
            &[
                Value::Text(attachment_id.to_string()),
                Value::Text(session_uuid.to_string()),
                Value::Text(message_uuid.to_string()),
                Value::Integer(size),
                remote_value,
                Value::Text(state.as_str().to_string()),
                uploaded_at,
                Value::Integer(now),
            ],
        )?;
        Ok(())
    }

    pub fn get_pending_uploads_for_session(
        &self,
        session_uuid: Uuid,
    ) -> Result<Vec<AttachmentUploadRow>> {
        let rows = self.backend.query(
            "SELECT attachment_id, session_uuid, message_uuid, size, remote_id, upload_state, uploaded_at, updated_at \
             FROM attachments \
             WHERE session_uuid = ? AND upload_state IN ('pending','uploading','failed') \
             ORDER BY updated_at ASC",
            &[Value::Text(session_uuid.to_string())],
        )?;

        rows.iter().map(Self::row_from_row).collect()
    }

    pub fn get_pending_uploads_for_message(
        &self,
        message_uuid: Uuid,
    ) -> Result<Vec<AttachmentUploadRow>> {
        let rows = self.backend.query(
            "SELECT attachment_id, session_uuid, message_uuid, size, remote_id, upload_state, uploaded_at, updated_at \
             FROM attachments \
             WHERE message_uuid = ? AND upload_state IN ('pending','uploading','failed') \
             ORDER BY updated_at ASC",
            &[Value::Text(message_uuid.to_string())],
        )?;

        rows.iter().map(Self::row_from_row).collect()
    }

    pub fn delete_attachment_tracking_for_message(&self, message_uuid: Uuid) -> Result<()> {
        self.backend.execute(
            "DELETE FROM attachments WHERE message_uuid = ?",
            &[Value::Text(message_uuid.to_string())],
        )?;
        Ok(())
    }

    pub fn delete_attachment_tracking_for_session(&self, session_uuid: Uuid) -> Result<()> {
        self.backend.execute(
            "DELETE FROM attachments WHERE session_uuid = ?",
            &[Value::Text(session_uuid.to_string())],
        )?;
        Ok(())
    }

    fn row_from_row(row: &crate::backend::Row) -> Result<AttachmentUploadRow> {
        let attachment_id = row.get_string(0)?;
        let session_uuid = Uuid::parse_str(&row.get_string(1)?)?;
        let message_uuid = Uuid::parse_str(&row.get_string(2)?)?;
        let size = row.get_i64(3)?;
        let remote_id = row.get_optional_string(4)?;
        let upload_state: UploadState = row.get_string(5)?.parse()?;
        let uploaded_at = row.get_optional_i64(6)?;
        let updated_at = row.get_i64(7)?;
        Ok(AttachmentUploadRow {
            attachment_id,
            session_uuid,
            message_uuid,
            size,
            remote_id,
            upload_state,
            uploaded_at,
            updated_at,
        })
    }
}

#[cfg(feature = "sqlite")]
impl AttachmentsDb<crate::backend::sqlite::SqliteBackend> {
    pub fn open_sqlite(path: impl AsRef<std::path::Path>, clock: Arc<dyn Clock>) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open(path)?;
        Self::new(backend, clock)
    }

    pub fn open_sqlite_with_defaults(path: impl AsRef<std::path::Path>) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open(path)?;
        Self::new_with_defaults(backend)
    }

    pub fn open_in_memory(clock: Arc<dyn Clock>) -> Result<Self> {
        let backend = crate::backend::sqlite::SqliteBackend::open_in_memory()?;
        Self::new(backend, clock)
    }
}

#[cfg(all(test, feature = "sqlite"))]
mod tests {
    use std::sync::atomic::{AtomicI64, Ordering};

    use super::*;
    use crate::backend::sqlite::SqliteBackend;

    #[derive(Debug)]
    struct StepClock {
        current: AtomicI64,
    }

    impl StepClock {
        fn new(start: i64) -> Self {
            Self {
                current: AtomicI64::new(start),
            }
        }
    }

    impl Clock for StepClock {
        fn now_us(&self) -> i64 {
            self.current.fetch_add(1, Ordering::SeqCst)
        }
    }

    #[test]
    fn pending_and_mark_uploaded() {
        let clock = Arc::new(StepClock::new(100));
        let backend = SqliteBackend::open_in_memory().unwrap();
        let db = AttachmentsDb::new(backend, clock.clone()).unwrap();

        let session = Uuid::from_u128(1);
        let message = Uuid::from_u128(2);

        db.upsert_pending_attachment("att-1", session, message, 123)
            .unwrap();

        let pending = db.get_pending_uploads_for_session(session).unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].upload_state, UploadState::Pending);

        db.set_attachment_upload_state("att-1", UploadState::Uploading)
            .unwrap();
        let pending = db.get_pending_uploads_for_message(message).unwrap();
        assert_eq!(pending[0].upload_state, UploadState::Uploading);

        db.mark_attachment_uploaded("att-1").unwrap();
        let pending_after = db.get_pending_uploads_for_session(session).unwrap();
        assert!(pending_after.is_empty());
    }
}
