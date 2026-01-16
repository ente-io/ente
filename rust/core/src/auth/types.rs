//! Data types for authentication operations.

use serde::{Deserialize, Serialize};

/// Attributes stored on server for key derivation and encrypted keys.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct KeyAttributes {
    /// Salt for deriving key-encryption-key from password (base64)
    pub kek_salt: String,
    /// Master key encrypted with KEK (base64)
    pub encrypted_key: String,
    /// Nonce for master key decryption (base64)
    pub key_decryption_nonce: String,
    /// X25519 public key (base64)
    pub public_key: String,
    /// Secret key encrypted with master key (base64)
    pub encrypted_secret_key: String,
    /// Nonce for secret key decryption (base64)
    pub secret_key_decryption_nonce: String,
    /// Argon2 memory limit
    #[serde(skip_serializing_if = "Option::is_none")]
    pub mem_limit: Option<u32>,
    /// Argon2 ops limit
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ops_limit: Option<u32>,
    /// Master key encrypted with recovery key (base64)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub master_key_encrypted_with_recovery_key: Option<String>,
    /// Nonce for master key decryption with recovery key (base64)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub master_key_decryption_nonce: Option<String>,
    /// Recovery key encrypted with master key (base64)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recovery_key_encrypted_with_master_key: Option<String>,
    /// Nonce for recovery key decryption (base64)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recovery_key_decryption_nonce: Option<String>,
}

/// Private key material (never sent to server).
#[derive(Debug, Clone)]
pub struct PrivateKeyAttributes {
    /// Master key (base64)
    pub key: String,
    /// Recovery key (hex for display to user)
    pub recovery_key: String,
    /// X25519 secret key (base64)
    pub secret_key: String,
}

/// Result of key generation during sign-up.
#[derive(Debug, Clone)]
pub struct KeyGenResult {
    /// Attributes to send to server
    pub key_attributes: KeyAttributes,
    /// Private keys to store locally
    pub private_key_attributes: PrivateKeyAttributes,
    /// Login key for SRP registration (16 bytes)
    pub login_key: Vec<u8>,
}

/// Result of successful login/decryption.
#[derive(Debug, Clone)]
pub struct LoginResult {
    /// Decrypted master key
    pub master_key: Vec<u8>,
    /// Decrypted X25519 secret key
    pub secret_key: Vec<u8>,
    /// Decrypted auth token
    pub token: Vec<u8>,
    /// Key-encryption-key (for SRP setup if needed)
    pub key_encryption_key: Vec<u8>,
}

/// SRP attributes received from server.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrpAttributes {
    /// SRP user ID (UUID)
    pub srp_user_id: String,
    /// SRP salt (base64)
    pub srp_salt: String,
    /// Argon2 memory limit
    pub mem_limit: u32,
    /// Argon2 ops limit
    pub ops_limit: u32,
    /// KEK salt (base64) - same as in KeyAttributes
    pub kek_salt: String,
    /// Whether email MFA is enabled (use email OTT instead of SRP)
    pub is_email_mfa_enabled: bool,
}

/// Error types for auth operations.
#[derive(Debug, thiserror::Error)]
pub enum AuthError {
    /// Password verification failed.
    #[error("Incorrect password")]
    IncorrectPassword,

    /// Recovery key verification failed.
    #[error("Incorrect recovery key")]
    IncorrectRecoveryKey,

    /// Key attributes are invalid or corrupted.
    #[error("Invalid key attributes")]
    InvalidKeyAttributes,

    /// A required field is missing from the key attributes.
    #[error("Missing required field: {0}")]
    MissingField(&'static str),

    /// Underlying cryptographic operation failed.
    #[error("Crypto error: {0}")]
    Crypto(#[from] crate::crypto::CryptoError),

    /// Failed to decode base64 or hex data.
    #[error("Decode error: {0}")]
    Decode(String),

    /// Invalid key format or length.
    #[error("Invalid key: {0}")]
    InvalidKey(String),

    /// SRP protocol error.
    #[error("SRP error: {0}")]
    Srp(String),
}

/// Result type for auth operations.
pub type Result<T> = std::result::Result<T, AuthError>;
