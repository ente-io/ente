use thiserror::Error;

#[derive(Debug, Error)]
pub enum SyncError {
    #[error("not logged in")]
    NotLoggedIn,
    #[error("unauthorized")]
    Unauthorized,
    #[error("db error: {0}")]
    Db(#[from] llmchat_db::Error),
    #[error("crypto error: {0}")]
    Crypto(String),
    #[error("http {status}: {message}")]
    Http {
        status: u16,
        message: String,
        code: Option<String>,
    },
    #[error("limit reached: {code}")]
    LimitReached {
        code: String,
        message: Option<String>,
    },
    #[error("attachment API unavailable")]
    AttachmentApiUnavailable,
    #[error("attachment missing: {0}")]
    AttachmentMissing(String),
    #[error("invalid response: {0}")]
    InvalidResponse(String),
    #[error("sync already in progress")]
    SyncInProgress,
    #[error("serde error: {0}")]
    Serde(String),
    #[error("io error: {0}")]
    Io(String),
}

impl From<ente_core::crypto::CryptoError> for SyncError {
    fn from(err: ente_core::crypto::CryptoError) -> Self {
        SyncError::Crypto(err.to_string())
    }
}

impl From<serde_json::Error> for SyncError {
    fn from(err: serde_json::Error) -> Self {
        SyncError::Serde(err.to_string())
    }
}

impl From<std::io::Error> for SyncError {
    fn from(err: std::io::Error) -> Self {
        SyncError::Io(err.to_string())
    }
}
