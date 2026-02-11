pub const PRAGMA_FOREIGN_KEYS: &str = "PRAGMA foreign_keys = ON;";

pub const CREATE_SESSIONS: &str = "
CREATE TABLE IF NOT EXISTS sessions (
  session_uuid      TEXT PRIMARY KEY NOT NULL,
  title             BLOB NOT NULL,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,
  server_updated_at INTEGER,
  remote_id         TEXT UNIQUE,
  needs_sync        INTEGER NOT NULL DEFAULT 1 CHECK(needs_sync IN (0,1)),
  deleted_at        INTEGER
);
";

pub const CREATE_MESSAGES: &str = "
CREATE TABLE IF NOT EXISTS messages (
  message_uuid        TEXT PRIMARY KEY NOT NULL,
  session_uuid        TEXT NOT NULL,
  parent_message_uuid TEXT,
  sender              TEXT NOT NULL CHECK(sender IN ('self','other')),
  text                BLOB NOT NULL,
  attachments         TEXT,
  created_at          INTEGER NOT NULL,
  remote_id           TEXT,
  server_updated_at   INTEGER,
  needs_sync          INTEGER NOT NULL DEFAULT 1 CHECK(needs_sync IN (0,1)),
  deleted_at          INTEGER,
  FOREIGN KEY (session_uuid) REFERENCES sessions(session_uuid) ON DELETE CASCADE
);
";

pub const CREATE_INDEXES: &str = "
CREATE INDEX IF NOT EXISTS idx_messages_order ON messages(session_uuid, created_at, message_uuid);
CREATE INDEX IF NOT EXISTS idx_sessions_updated ON sessions(updated_at);
";

pub const CREATE_ALL: &str = "
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS sessions (
  session_uuid      TEXT PRIMARY KEY NOT NULL,
  title             BLOB NOT NULL,
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL,
  server_updated_at INTEGER,
  remote_id         TEXT UNIQUE,
  needs_sync        INTEGER NOT NULL DEFAULT 1 CHECK(needs_sync IN (0,1)),
  deleted_at        INTEGER
);

CREATE TABLE IF NOT EXISTS messages (
  message_uuid        TEXT PRIMARY KEY NOT NULL,
  session_uuid        TEXT NOT NULL,
  parent_message_uuid TEXT,
  sender              TEXT NOT NULL CHECK(sender IN ('self','other')),
  text                BLOB NOT NULL,
  attachments         TEXT,
  created_at          INTEGER NOT NULL,
  remote_id           TEXT,
  server_updated_at   INTEGER,
  needs_sync          INTEGER NOT NULL DEFAULT 1 CHECK(needs_sync IN (0,1)),
  deleted_at          INTEGER,
  FOREIGN KEY (session_uuid) REFERENCES sessions(session_uuid) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_messages_order ON messages(session_uuid, created_at, message_uuid);
CREATE INDEX IF NOT EXISTS idx_sessions_updated ON sessions(updated_at);
";
