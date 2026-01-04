//! Crypto error types.

use thiserror::Error;

/// Errors that can occur during cryptographic operations.
#[derive(Error, Debug)]
pub enum CryptoError {
    /// Base64 decoding failed.
    #[error("Base64 decode error: {0}")]
    Base64Decode(#[from] base64::DecodeError),

    /// Hex decoding failed.
    #[error("Hex decode error: {0}")]
    HexDecode(#[from] hex::FromHexError),

    /// Invalid key length.
    #[error("Invalid key length: expected {expected}, got {actual}")]
    InvalidKeyLength {
        /// Expected length.
        expected: usize,
        /// Actual length.
        actual: usize,
    },

    /// Invalid nonce length.
    #[error("Invalid nonce length: expected {expected}, got {actual}")]
    InvalidNonceLength {
        /// Expected length.
        expected: usize,
        /// Actual length.
        actual: usize,
    },

    /// Invalid salt length.
    #[error("Invalid salt length: expected {expected}, got {actual}")]
    InvalidSaltLength {
        /// Expected length.
        expected: usize,
        /// Actual length.
        actual: usize,
    },

    /// Invalid header length.
    #[error("Invalid header length: expected {expected}, got {actual}")]
    InvalidHeaderLength {
        /// Expected length.
        expected: usize,
        /// Actual length.
        actual: usize,
    },

    /// Ciphertext too short.
    #[error("Ciphertext too short: minimum {minimum}, got {actual}")]
    CiphertextTooShort {
        /// Minimum required length.
        minimum: usize,
        /// Actual length.
        actual: usize,
    },

    /// Invalid memory or operation limits for key derivation.
    #[error("Invalid key derivation parameters: {0}")]
    InvalidKeyDerivationParams(String),

    /// Key derivation failed.
    #[error("Key derivation failed")]
    KeyDerivationFailed,

    /// Encryption failed.
    #[error("Encryption failed")]
    EncryptionFailed,

    /// Decryption failed.
    #[error("Decryption failed")]
    DecryptionFailed,

    /// Stream initialization failed.
    #[error("Stream initialization failed")]
    StreamInitFailed,

    /// Stream push (encrypt) failed.
    #[error("Stream push failed")]
    StreamPushFailed,

    /// Stream pull (decrypt) failed.
    #[error("Stream pull failed")]
    StreamPullFailed,

    /// Sealed box open failed.
    #[error("Sealed box open failed")]
    SealedBoxOpenFailed,

    /// Invalid public key (e.g., small-order point).
    #[error("Invalid public key")]
    InvalidPublicKey,

    /// Hash computation failed.
    #[error("Hash computation failed")]
    HashFailed,

    /// Argon2 error.
    #[error("Argon2 error: {0:?}")]
    Argon2(argon2::Error),

    /// AEAD error.
    #[error("AEAD error")]
    Aead,

    /// Array conversion error.
    #[error("Array conversion error")]
    ArrayConversion,

    /// IO error.
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

/// Result type for crypto operations.
pub type Result<T> = std::result::Result<T, CryptoError>;

impl From<std::array::TryFromSliceError> for CryptoError {
    fn from(_: std::array::TryFromSliceError) -> Self {
        CryptoError::ArrayConversion
    }
}
