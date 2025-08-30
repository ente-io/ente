#![allow(dead_code)]

use crate::Result;
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

pub mod account;
pub mod config;
pub mod schema;
pub mod sync;

pub use account::AccountStore;
pub use config::ConfigStore;
pub use sync::SyncStore;

/// Main storage handler that manages the SQLite database
pub struct Storage {
    conn: Connection,
    path: Option<PathBuf>,
}

impl Storage {
    /// Create a new storage instance with the given database path
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path_buf = path.as_ref().to_path_buf();
        let conn = Connection::open(&path_buf)?;

        // Enable foreign keys
        conn.execute("PRAGMA foreign_keys = ON", [])?;

        // Create tables
        schema::create_tables(&conn)?;

        Ok(Self {
            conn,
            path: Some(path_buf),
        })
    }

    /// Create an in-memory database (useful for testing)
    pub fn new_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        conn.execute("PRAGMA foreign_keys = ON", [])?;
        schema::create_tables(&conn)?;
        Ok(Self { conn, path: None })
    }

    /// Get a reference to the connection
    pub fn conn(&self) -> &Connection {
        &self.conn
    }

    /// Begin a transaction
    pub fn transaction<F, R>(&mut self, f: F) -> Result<R>
    where
        F: FnOnce(&rusqlite::Transaction) -> Result<R>,
    {
        let tx = self.conn.transaction()?;
        let result = f(&tx)?;
        tx.commit()?;
        Ok(result)
    }

    /// Get account store
    pub fn accounts(&self) -> AccountStore<'_> {
        AccountStore::new(&self.conn)
    }

    /// Get config store
    pub fn config(&self) -> ConfigStore<'_> {
        ConfigStore::new(&self.conn)
    }

    /// Get sync store
    pub fn sync(&self) -> SyncStore<'_> {
        SyncStore::new(&self.conn)
    }

    /// Get the database path
    pub fn db_path(&self) -> Option<&Path> {
        self.path.as_deref()
    }
}

/// Helper trait for JSON serialization in SQLite
pub trait JsonValue: Serialize + for<'de> Deserialize<'de> {
    fn to_json(&self) -> Result<String> {
        Ok(serde_json::to_string(self)?)
    }

    fn from_json(json: &str) -> Result<Self> {
        Ok(serde_json::from_str(json)?)
    }
}

// Implement for common types
impl<T> JsonValue for T where T: Serialize + for<'de> Deserialize<'de> {}

// Rusqlite error conversion is now handled in models/error.rs via #[from]
