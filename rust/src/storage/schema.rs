use crate::Result;
use rusqlite::Connection;

/// Create all database tables
pub fn create_tables(conn: &Connection) -> Result<()> {
    // Accounts table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY,
            email TEXT NOT NULL,
            user_id INTEGER NOT NULL,
            app TEXT NOT NULL,
            endpoint TEXT NOT NULL DEFAULT 'https://api.ente.io',
            export_dir TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            UNIQUE(email, app, endpoint)
        )",
        [],
    )?;

    // Secrets table (encrypted credentials)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS secrets (
            account_id INTEGER PRIMARY KEY,
            token BLOB NOT NULL,
            master_key BLOB NOT NULL,
            secret_key BLOB NOT NULL,
            public_key BLOB NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        )",
        [],
    )?;

    // Configuration table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
        )",
        [],
    )?;

    // Collections/Albums table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS collections (
            id INTEGER PRIMARY KEY,
            account_id INTEGER NOT NULL,
            collection_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            owner INTEGER NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            metadata TEXT,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
            UNIQUE(account_id, collection_id),
            UNIQUE(collection_id)
        )",
        [],
    )?;

    // Files table (for caching remote file metadata)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS files (
            id INTEGER PRIMARY KEY,
            account_id INTEGER NOT NULL,
            file_id INTEGER NOT NULL,
            collection_id INTEGER NOT NULL,
            encrypted_key TEXT NOT NULL,
            key_decryption_nonce TEXT NOT NULL,
            file_info TEXT NOT NULL,
            metadata TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            is_synced_locally INTEGER NOT NULL DEFAULT 0,
            local_path TEXT,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
            FOREIGN KEY (collection_id) REFERENCES collections(collection_id),
            UNIQUE(account_id, file_id)
        )",
        [],
    )?;

    // Album files mapping
    conn.execute(
        "CREATE TABLE IF NOT EXISTS album_files (
            id INTEGER PRIMARY KEY,
            account_id INTEGER NOT NULL,
            album_id INTEGER NOT NULL,
            file_id INTEGER NOT NULL,
            synced_locally INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE,
            UNIQUE(account_id, album_id, file_id)
        )",
        [],
    )?;

    // Sync state table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS sync_state (
            account_id INTEGER PRIMARY KEY,
            last_file_sync INTEGER,
            last_collection_sync INTEGER,
            last_album_sync INTEGER,
            sync_status TEXT,
            FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
        )",
        [],
    )?;

    // Create indices for better performance
    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_files_collection 
         ON files(account_id, collection_id)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_album_files_album 
         ON album_files(account_id, album_id)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_collections_account 
         ON collections(account_id)",
        [],
    )?;

    Ok(())
}
