use ente_core::{auth::AuthError, crypto::CryptoError};
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

    #[error("API error ({status}): {message}")]
    ApiError { status: u16, message: String },

    #[error("{0}")]
    Generic(String),
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

impl From<AuthError> for Error {
    fn from(err: AuthError) -> Self {
        match err {
            AuthError::IncorrectPassword => {
                Error::AuthenticationFailed("Incorrect password".to_string())
            }
            AuthError::IncorrectRecoveryKey => {
                Error::AuthenticationFailed("Incorrect recovery key".to_string())
            }
            AuthError::InvalidKeyAttributes => Error::Crypto(err.to_string()),
            AuthError::MissingField(field) => Error::Crypto(format!("Missing field: {field}")),
            AuthError::Crypto(source) => source.into(),
            AuthError::Decode(msg) => Error::Crypto(msg),
            AuthError::InvalidKey(msg) => Error::Crypto(msg),
            AuthError::Srp(msg) => Error::Srp(msg),
        }
    }
}

pub type Result<T> = std::result::Result<T, Error>;
