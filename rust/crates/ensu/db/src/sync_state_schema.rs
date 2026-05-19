pub const CREATE_SYNC_SESSIONS: &str = "
CREATE TABLE IF NOT EXISTS sync_sessions (
  client_id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  server_updated_at INTEGER
);
";

pub const CREATE_SYNC_MESSAGES: &str = "
CREATE TABLE IF NOT EXISTS sync_messages (
  client_id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  server_updated_at INTEGER
);
";

pub const CREATE_SYNC_META: &str = "
CREATE TABLE IF NOT EXISTS sync_meta (
  key TEXT PRIMARY KEY NOT NULL,
  value BLOB NOT NULL
);
";

pub const CREATE_INDEXES: &str = "
CREATE INDEX IF NOT EXISTS idx_sync_sessions_remote ON sync_sessions(remote_id);
CREATE INDEX IF NOT EXISTS idx_sync_messages_remote ON sync_messages(remote_id);
";

pub const CREATE_ALL: &str = "
CREATE TABLE IF NOT EXISTS sync_sessions (
  client_id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  server_updated_at INTEGER
);

CREATE TABLE IF NOT EXISTS sync_messages (
  client_id TEXT PRIMARY KEY NOT NULL,
  remote_id TEXT,
  server_updated_at INTEGER
);

CREATE TABLE IF NOT EXISTS sync_meta (
  key TEXT PRIMARY KEY NOT NULL,
  value BLOB NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sync_sessions_remote ON sync_sessions(remote_id);
CREATE INDEX IF NOT EXISTS idx_sync_messages_remote ON sync_messages(remote_id);
";
