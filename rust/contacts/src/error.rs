use ente_core::{crypto::CryptoError, http::Error as HttpError};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum ContactsError {
    #[error(transparent)]
    Http(#[from] HttpError),

    #[error(transparent)]
    Crypto(#[from] CryptoError),

    #[error("invalid input: {0}")]
    InvalidInput(String),

    #[error("missing encrypted data for live contact")]
    MissingEncryptedData,

    #[error("missing encrypted key for live contact")]
    MissingEncryptedKey,

    #[error("profile picture not found")]
    ProfilePictureNotFound,
}

pub type Result<T> = std::result::Result<T, ContactsError>;
