//! WASM bindings for pure-Rust cryptography.

use ente_core::crypto as core_crypto;
use wasm_bindgen::prelude::*;

/// Crypto error.
#[wasm_bindgen]
pub struct CryptoError {
    code: String,
    message: String,
}

#[wasm_bindgen]
impl CryptoError {
    /// A machine-readable error code.
    #[wasm_bindgen(getter)]
    pub fn code(&self) -> String {
        self.code.clone()
    }

    /// Human-readable error message.
    #[wasm_bindgen(getter)]
    pub fn message(&self) -> String {
        self.message.clone()
    }
}

impl From<core_crypto::CryptoError> for CryptoError {
    fn from(e: core_crypto::CryptoError) -> Self {
        use core_crypto::CryptoError as E;

        let code = match &e {
            E::Base64Decode(_) => "base64_decode",
            E::HexDecode(_) => "hex_decode",
            E::InvalidKeyLength { .. } => "invalid_key_length",
            E::InvalidNonceLength { .. } => "invalid_nonce_length",
            E::InvalidSaltLength { .. } => "invalid_salt_length",
            E::InvalidHeaderLength { .. } => "invalid_header_length",
            E::CiphertextTooShort { .. } => "ciphertext_too_short",
            E::InvalidKeyDerivationParams(_) => "invalid_kdf_params",
            E::KeyDerivationFailed => "key_derivation_failed",
            E::EncryptionFailed => "encryption_failed",
            E::DecryptionFailed => "decryption_failed",
            E::StreamInitFailed => "stream_init_failed",
            E::StreamPushFailed => "stream_push_failed",
            E::StreamPullFailed => "stream_pull_failed",
            E::StreamTruncated => "stream_truncated",
            E::SealedBoxOpenFailed => "sealed_box_open_failed",
            E::InvalidPublicKey => "invalid_public_key",
            E::HashFailed => "hash_failed",
            E::Argon2(_) => "argon2",
            E::Aead => "aead",
            E::ArrayConversion => "array_conversion",
            E::Io(_) => "io",
        }
        .to_string();

        Self {
            code,
            message: e.to_string(),
        }
    }
}

/// Initialize the crypto backend.
///
/// This is a no-op for the pure-Rust implementation, but is provided for API
/// symmetry with other platforms.
#[wasm_bindgen]
pub fn crypto_init() -> Result<(), CryptoError> {
    core_crypto::init().map_err(Into::into)
}

/// Generate a random 32-byte SecretBox key and return it as base64.
#[wasm_bindgen]
pub fn crypto_generate_key() -> String {
    core_crypto::encode_b64(&core_crypto::keys::generate_key())
}

/// Generate a random 32-byte SecretStream key and return it as base64.
#[wasm_bindgen]
pub fn crypto_generate_stream_key() -> String {
    core_crypto::encode_b64(&core_crypto::keys::generate_stream_key())
}

/// Generate a random 16-byte salt and return it as base64.
#[wasm_bindgen]
pub fn crypto_generate_salt() -> String {
    core_crypto::encode_b64(&core_crypto::keys::generate_salt())
}

/// A X25519 public/secret keypair.
#[wasm_bindgen]
pub struct CryptoKeyPair {
    public_key: String,
    secret_key: String,
}

#[wasm_bindgen]
impl CryptoKeyPair {
    #[wasm_bindgen(getter)]
    pub fn public_key(&self) -> String {
        self.public_key.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn secret_key(&self) -> String {
        self.secret_key.clone()
    }
}

/// Generate a random X25519 keypair and return it as base64.
#[wasm_bindgen]
pub fn crypto_generate_keypair() -> Result<CryptoKeyPair, CryptoError> {
    let (public_key, secret_key) = core_crypto::keys::generate_keypair()?;
    Ok(CryptoKeyPair {
        public_key: core_crypto::encode_b64(&public_key),
        secret_key: core_crypto::encode_b64(&secret_key),
    })
}

/// A SecretBox encryption result.
///
/// Wire format is compatible with libsodium's `crypto_secretbox_easy`.
#[wasm_bindgen]
pub struct EncryptedBox {
    encrypted_data: String,
    nonce: String,
}

#[wasm_bindgen]
impl EncryptedBox {
    #[wasm_bindgen(getter)]
    pub fn encrypted_data(&self) -> String {
        self.encrypted_data.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn nonce(&self) -> String {
        self.nonce.clone()
    }
}

/// Encrypt `data_b64` using SecretBox with `key_b64`.
///
/// Returns ciphertext (`encrypted_data`) and nonce as base64.
#[wasm_bindgen]
pub fn crypto_encrypt_box(data_b64: &str, key_b64: &str) -> Result<EncryptedBox, CryptoError> {
    let data = core_crypto::decode_b64(data_b64)?;
    let key = core_crypto::decode_b64(key_b64)?;

    let out = core_crypto::secretbox::encrypt_with_key(&data, &key)?;

    Ok(EncryptedBox {
        encrypted_data: core_crypto::encode_b64(&out.ciphertext),
        nonce: core_crypto::encode_b64(&out.nonce),
    })
}

/// Decrypt a SecretBox ciphertext using `key_b64` and `nonce_b64`.
///
/// Returns the plaintext as base64.
#[wasm_bindgen]
pub fn crypto_decrypt_box(
    encrypted_data_b64: &str,
    nonce_b64: &str,
    key_b64: &str,
) -> Result<String, CryptoError> {
    let ciphertext = core_crypto::decode_b64(encrypted_data_b64)?;
    let nonce = core_crypto::decode_b64(nonce_b64)?;
    let key = core_crypto::decode_b64(key_b64)?;

    let plaintext = core_crypto::secretbox::decrypt(&ciphertext, &nonce, &key)?;
    Ok(core_crypto::encode_b64(&plaintext))
}

/// A SecretStream (blob) encryption result.
#[wasm_bindgen]
pub struct EncryptedBlob {
    encrypted_data: String,
    decryption_header: String,
}

#[wasm_bindgen]
impl EncryptedBlob {
    #[wasm_bindgen(getter)]
    pub fn encrypted_data(&self) -> String {
        self.encrypted_data.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn decryption_header(&self) -> String {
        self.decryption_header.clone()
    }
}

/// Encrypt `data_b64` using SecretStream (single-message blob) with `key_b64`.
#[wasm_bindgen]
pub fn crypto_encrypt_blob(data_b64: &str, key_b64: &str) -> Result<EncryptedBlob, CryptoError> {
    let data = core_crypto::decode_b64(data_b64)?;
    let key = core_crypto::decode_b64(key_b64)?;

    let out = core_crypto::blob::encrypt(&data, &key)?;
    Ok(EncryptedBlob {
        encrypted_data: core_crypto::encode_b64(&out.encrypted_data),
        decryption_header: core_crypto::encode_b64(&out.decryption_header),
    })
}

/// Decrypt a SecretStream (blob) ciphertext.
///
/// Returns the plaintext as base64.
#[wasm_bindgen]
pub fn crypto_decrypt_blob(
    encrypted_data_b64: &str,
    decryption_header_b64: &str,
    key_b64: &str,
) -> Result<String, CryptoError> {
    let ciphertext = core_crypto::decode_b64(encrypted_data_b64)?;
    let header = core_crypto::decode_b64(decryption_header_b64)?;
    let key = core_crypto::decode_b64(key_b64)?;

    let plaintext = core_crypto::blob::decrypt(&ciphertext, &header, &key)?;
    Ok(core_crypto::encode_b64(&plaintext))
}

/// Seal (anonymous public-key encrypt) `data_b64` for `recipient_public_key_b64`.
///
/// Wire format matches libsodium `crypto_box_seal`.
#[wasm_bindgen]
pub fn crypto_box_seal(
    data_b64: &str,
    recipient_public_key_b64: &str,
) -> Result<String, CryptoError> {
    let data = core_crypto::decode_b64(data_b64)?;
    let pk = core_crypto::decode_b64(recipient_public_key_b64)?;
    let sealed = core_crypto::sealed::seal(&data, &pk)?;
    Ok(core_crypto::encode_b64(&sealed))
}

/// Open (decrypt) a sealed box.
///
/// Returns the plaintext as base64.
#[wasm_bindgen]
pub fn crypto_box_seal_open(
    sealed_b64: &str,
    recipient_public_key_b64: &str,
    recipient_secret_key_b64: &str,
) -> Result<String, CryptoError> {
    let sealed = core_crypto::decode_b64(sealed_b64)?;
    let pk = core_crypto::decode_b64(recipient_public_key_b64)?;
    let sk = core_crypto::decode_b64(recipient_secret_key_b64)?;
    let opened = core_crypto::sealed::open(&sealed, &pk, &sk)?;
    Ok(core_crypto::encode_b64(&opened))
}

/// Derive a 32-byte key from `password` using Argon2id.
///
/// Returns the derived key as base64.
#[wasm_bindgen]
pub fn crypto_derive_key(
    password: &str,
    salt_b64: &str,
    mem_limit: u32,
    ops_limit: u32,
) -> Result<String, CryptoError> {
    let salt = core_crypto::decode_b64(salt_b64)?;
    let key = core_crypto::argon::derive_key(password, &salt, mem_limit, ops_limit)?;
    Ok(core_crypto::encode_b64(&key))
}

/// Derive a subkey using BLAKE2b KDF (libsodium compatible).
///
/// Returns the derived subkey as base64.
#[wasm_bindgen]
pub fn crypto_derive_subkey(
    key_b64: &str,
    subkey_len: usize,
    subkey_id: u64,
    context: &str,
) -> Result<String, CryptoError> {
    let key = core_crypto::decode_b64(key_b64)?;
    let subkey = core_crypto::kdf::derive_subkey(&key, subkey_len, subkey_id, context.as_bytes())?;
    Ok(core_crypto::encode_b64(&subkey))
}

/// Derive the SRP login key from a 32-byte master key.
///
/// Returns the 16-byte login key as base64.
#[wasm_bindgen]
pub fn crypto_derive_login_key(master_key_b64: &str) -> Result<String, CryptoError> {
    let key = core_crypto::decode_b64(master_key_b64)?;
    let login_key = core_crypto::kdf::derive_login_key(&key)?;
    Ok(core_crypto::encode_b64(&login_key))
}
