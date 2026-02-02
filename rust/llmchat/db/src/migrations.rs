use crate::backend::RowExt;
use crate::schema;
use crate::{Backend, Error, Result};

pub const LATEST_VERSION: i64 = 2;

pub fn migrate<B: Backend>(backend: &B) -> Result<()> {
    let version = user_version(backend)?;
    match version {
        0 => {
            backend.execute_batch(schema::CREATE_ALL)?;
            backend.execute("PRAGMA user_version = 2;", &[])?;
            Ok(())
        }
        1 => {
            backend.execute(
                "ALTER TABLE messages ADD COLUMN needs_sync INTEGER NOT NULL DEFAULT 1 CHECK(needs_sync IN (0,1));",
                &[],
            )?;
            backend.execute(
                "UPDATE messages SET needs_sync = 0 WHERE session_uuid IN (SELECT session_uuid FROM sessions WHERE needs_sync = 0);",
                &[],
            )?;
            backend.execute("PRAGMA user_version = 2;", &[])?;
            Ok(())
        }
        LATEST_VERSION => Ok(()),
        other => Err(Error::Migration(format!(
            "unsupported schema version {other}"
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

        for table in ["sessions", "messages"] {
            let row = backend
                .query_row(
                    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
                    &[Value::Text(table.to_string())],
                )
                .unwrap();
            assert!(row.is_some(), "missing table {table}");
        }

        for index in ["idx_messages_order", "idx_sessions_updated"] {
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
