pub const CREATE_ATTACHMENTS: &str = "
CREATE TABLE IF NOT EXISTS attachments (
  attachment_id TEXT PRIMARY KEY NOT NULL,
  session_uuid  TEXT NOT NULL,
  message_uuid  TEXT NOT NULL,
  size          INTEGER NOT NULL,
  remote_id     TEXT,
  upload_state  TEXT NOT NULL CHECK(upload_state IN ('pending','uploading','uploaded','failed')),
  uploaded_at   INTEGER,
  updated_at    INTEGER NOT NULL
);
";

pub const CREATE_INDEXES: &str = "
CREATE INDEX IF NOT EXISTS idx_attachments_session ON attachments(session_uuid);
CREATE INDEX IF NOT EXISTS idx_attachments_message ON attachments(message_uuid);
CREATE INDEX IF NOT EXISTS idx_attachments_state ON attachments(upload_state);
";

pub const CREATE_ALL: &str = "
CREATE TABLE IF NOT EXISTS attachments (
  attachment_id TEXT PRIMARY KEY NOT NULL,
  session_uuid  TEXT NOT NULL,
  message_uuid  TEXT NOT NULL,
  size          INTEGER NOT NULL,
  remote_id     TEXT,
  upload_state  TEXT NOT NULL CHECK(upload_state IN ('pending','uploading','uploaded','failed')),
  uploaded_at   INTEGER,
  updated_at    INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_attachments_session ON attachments(session_uuid);
CREATE INDEX IF NOT EXISTS idx_attachments_message ON attachments(message_uuid);
CREATE INDEX IF NOT EXISTS idx_attachments_state ON attachments(upload_state);
";
