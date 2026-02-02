use crate::attachments_schema;
use crate::backend::RowExt;
use crate::{Backend, Error, Result};

pub const LATEST_VERSION: i64 = 2;

pub fn migrate<B: Backend>(backend: &B) -> Result<()> {
    let version = user_version(backend)?;
    match version {
        0 => {
            backend.execute_batch(attachments_schema::CREATE_ALL)?;
            backend.execute("PRAGMA user_version = 2;", &[])?;
            Ok(())
        }
        1 => {
            backend.execute("ALTER TABLE attachments ADD COLUMN remote_id TEXT;", &[])?;
            backend.execute("PRAGMA user_version = 2;", &[])?;
            Ok(())
        }
        LATEST_VERSION => Ok(()),
        other => Err(Error::Migration(format!(
            "unsupported attachments schema version {other}"
        ))),
    }
}

fn user_version<B: Backend>(backend: &B) -> Result<i64> {
    let row = backend
        .query_row("PRAGMA user_version;", &[])?
        .ok_or_else(|| Error::Migration("missing user_version pragma".to_string()))?;
    row.get_i64(0)
}

#[cfg(all(test, feature = "sqlite"))]
mod tests {
    use super::*;
    use crate::backend::sqlite::SqliteBackend;
    use crate::backend::{BackendTx, RowExt, Value};

    #[test]
    fn creates_schema_and_indexes() {
        let backend = SqliteBackend::open_in_memory().unwrap();
        migrate(&backend).unwrap();

        let row = backend
            .query_row(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
                &[Value::Text("attachments".to_string())],
            )
            .unwrap();
        assert!(row.is_some(), "missing attachments table");

        for index in [
            "idx_attachments_session",
            "idx_attachments_message",
            "idx_attachments_state",
        ] {
            let row = backend
                .query_row(
                    "SELECT name FROM sqlite_master WHERE type = 'index' AND name = ?",
                    &[Value::Text(index.to_string())],
                )
                .unwrap();
            assert!(row.is_some(), "missing index {index}");
        }

        let row = backend.query_row("PRAGMA user_version;", &[]).unwrap();
        let version = row.unwrap().get_i64(0).unwrap();
        assert_eq!(version, LATEST_VERSION);
    }
}
