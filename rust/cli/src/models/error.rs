use ente_core::crypto::CryptoError;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("Database error: {0}")]
    Database(#[from] rusqlite::Error),

    #[error("Crypto error: {0}")]
    Crypto(String),

    #[error("Authentication failed: {0}")]
    AuthenticationFailed(String),

    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),

    #[error("Not found: {0}")]
    NotFound(String),

    #[error("Invalid input: {0}")]
    InvalidInput(String),

    #[error("SRP error: {0}")]
    Srp(String),

    #[error("Base64 decode error: {0}")]
    Base64Decode(#[from] base64::DecodeError),

    #[error("ZIP error: {0}")]
    Zip(#[from] zip::result::ZipError),

    #[error("{0}")]
    Generic(String),

    #[error("Too many requests. Please wait a minute and try again.")]
    RateLimited,

    #[error("API error ({status}): {message}")]
    ApiError { status: u16, message: String },
}

impl Error {
    /// Create an API error with status code
    pub fn api_error(status: u16, message: String) -> Self {
        Error::ApiError { status, message }
    }

    /// Check if this is a specific HTTP status code
    pub fn is_status(&self, code: u16) -> bool {
        matches!(self, Error::ApiError { status, .. } if *status == code)
    }

    /// Check if this is an authentication error (401)
    pub fn is_unauthorized(&self) -> bool {
        self.is_status(401)
    }

    /// Check if this is a session expired error (410)
    pub fn is_gone(&self) -> bool {
        self.is_status(410)
    }

    /// Check if this is a rate limit error (429)
    pub fn is_rate_limited(&self) -> bool {
        matches!(self, Error::RateLimited) || self.is_status(429)
    }

    /// Check if this is a "not yet complete" error (400/404 for passkey polling)
    pub fn is_not_ready(&self) -> bool {
        self.is_status(400) || self.is_status(404)
    }

    /// Check if retry is appropriate for this error
    pub fn is_retryable_auth(&self) -> bool {
        self.is_unauthorized() || self.is_status(400)
    }

    /// Get a user-friendly display message
    pub fn user_message(&self) -> String {
        match self {
            Error::RateLimited => {
                "⏳ Too many requests. Please wait a minute and try again.".to_string()
            }
            Error::ApiError { status: 401, .. } => {
                "🔐 Invalid credentials. Please check your password.".to_string()
            }
            Error::ApiError { status: 410, .. } => {
                "🔐 Session expired. Please restart the login process.".to_string()
            }
            Error::ApiError { status: 429, .. } => {
                "⏳ Too many requests. Please wait a minute and try again.".to_string()
            }
            Error::ApiError { status: 404, .. } => "🔍 Not found.".to_string(),
            Error::AuthenticationFailed(msg) => format!("🔐 {}", msg),
            Error::Crypto(_) => "🔑 Decryption failed. Please check your password.".to_string(),
            Error::NotFound(msg) => format!("🔍 {}", msg),
            Error::Network(_) => "🌐 Network error. Please check your connection.".to_string(),
            Error::InvalidInput(msg) => format!("⚠️  {}", msg),
            _ => format!("❌ {}", self),
        }
    }
}

impl From<CryptoError> for Error {
    fn from(err: CryptoError) -> Self {
        match err {
            CryptoError::Base64Decode(source) => Error::Base64Decode(source),
            CryptoError::Io(source) => Error::Io(source),
            other => Error::Crypto(other.to_string()),
        }
    }
}

pub type Result<T> = std::result::Result<T, Error>;
