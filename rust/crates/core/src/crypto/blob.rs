//! Blob encryption (XChaCha20-Poly1305 SecretStream without chunking).
//!
//! This module provides encryption using SecretStream for small-ish data
//! that doesn't need to be chunked. Use this for encrypting metadata
//! associated with Ente objects.
//!
//! Two payload shapes are supported, mirroring [`super::secretbox`]:
//!
//! - Split ([`encrypt`] / [`decrypt`]): the ciphertext and the decryption
//!   header travel separately, matching the server's wire format.
//!
//! - Combined ([`encrypt_combined`] / [`decrypt_combined`]): a single
//!   self-contained `header ‖ ciphertext` buffer.

use super::stream::{Decryptor, Encryptor};
use crate::crypto::{CryptoError, Header, Key, Result};

/// Size of the encryption key in bytes.
pub const KEY_BYTES: usize = Key::BYTES;

/// Size of the decryption header in bytes.
pub const HEADER_BYTES: usize = Header::BYTES;

/// Overhead (tag + MAC) added to the plaintext by encryption.
pub use super::stream::ABYTES;

/// The result of blob encryption: ciphertext and decryption header, separate.
#[derive(Debug, Clone)]
pub struct EncryptedBlob {
    /// The encrypted data: a single secretstream message (plaintext length +
    /// [`ABYTES`] bytes).
    pub encrypted_data: Vec<u8>,
    /// The decryption header. Required for decryption; not secret.
    pub decryption_header: Header,
}

impl EncryptedBlob {
    /// Decrypt this blob.
    pub fn decrypt(&self, key: &Key) -> Result<Vec<u8>> {
        decrypt(&self.encrypted_data, &self.decryption_header, key)
    }
}

/// Encrypt the given data as a single secretstream message.
///
/// This is suitable for encrypting metadata and small files. Use [`decrypt`]
/// or [`EncryptedBlob::decrypt`] to decrypt the result.
pub fn encrypt(data: &[u8], key: &Key) -> Result<EncryptedBlob> {
    let mut encryptor = Encryptor::new(key);
    let decryption_header = *encryptor.header();
    let encrypted_data = encryptor.push(data, true)?;

    Ok(EncryptedBlob {
        encrypted_data,
        decryption_header,
    })
}

/// Decrypt data encrypted with [`encrypt`].
///
/// The data must carry the secretstream final tag; truncated or non-final
/// payloads are rejected with `CryptoError::StreamTruncated`. For older data
/// written without the final tag, use [`decrypt_legacy`].
pub fn decrypt(data: &[u8], header: &Header, key: &Key) -> Result<Vec<u8>> {
    let (plaintext, is_final) = decrypt_impl(data, header, key)?;
    if !is_final {
        return Err(CryptoError::StreamTruncated);
    }
    Ok(plaintext)
}

/// Decrypt a blob that may not carry the secretstream final tag.
///
/// Prefer [`decrypt`]. This exists as a migration fallback for older data
/// written without the final tag; it skips the truncation check.
pub fn decrypt_legacy(data: &[u8], header: &Header, key: &Key) -> Result<Vec<u8>> {
    Ok(decrypt_impl(data, header, key)?.0)
}

fn decrypt_impl(data: &[u8], header: &Header, key: &Key) -> Result<(Vec<u8>, bool)> {
    if data.len() < ABYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: ABYTES,
            actual: data.len(),
        });
    }

    let mut decryptor = Decryptor::new(header, key);
    decryptor.pull(data)
}

/// Encrypt data and return a single combined `header ‖ ciphertext` payload.
pub fn encrypt_combined(data: &[u8], key: &Key) -> Result<Vec<u8>> {
    let encrypted = encrypt(data, key)?;
    let mut combined = Vec::with_capacity(Header::BYTES + encrypted.encrypted_data.len());
    combined.extend_from_slice(encrypted.decryption_header.as_bytes());
    combined.extend_from_slice(&encrypted.encrypted_data);
    Ok(combined)
}

/// Decrypt a combined `header ‖ ciphertext` payload.
pub fn decrypt_combined(data: &[u8], key: &Key) -> Result<Vec<u8>> {
    if data.len() < Header::BYTES + ABYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: Header::BYTES + ABYTES,
            actual: data.len(),
        });
    }

    let (header, ciphertext) = data.split_at(Header::BYTES);
    decrypt(ciphertext, &Header::try_from_slice(header)?, key)
}

/// Encrypt a JSON value.
pub fn encrypt_json<T: serde::Serialize>(value: &T, key: &Key) -> Result<EncryptedBlob> {
    let json = serde_json::to_vec(value)
        .map_err(|e| CryptoError::Json(format!("JSON serialization failed: {}", e)))?;
    encrypt(&json, key)
}

/// Encrypt a JSON value and return a combined `header ‖ ciphertext` payload.
pub fn encrypt_json_combined<T: serde::Serialize>(value: &T, key: &Key) -> Result<Vec<u8>> {
    let json = serde_json::to_vec(value)
        .map_err(|e| CryptoError::Json(format!("JSON serialization failed: {}", e)))?;
    encrypt_combined(&json, key)
}

/// Decrypt an [`EncryptedBlob`] into a JSON value.
pub fn decrypt_json<T: serde::de::DeserializeOwned>(blob: &EncryptedBlob, key: &Key) -> Result<T> {
    let plaintext = blob.decrypt(key)?;
    serde_json::from_slice(&plaintext)
        .map_err(|e| CryptoError::Json(format!("JSON deserialization failed: {}", e)))
}

/// Decrypt a combined `header ‖ ciphertext` payload into a JSON value.
pub fn decrypt_json_combined<T: serde::de::DeserializeOwned>(
    combined: &[u8],
    key: &Key,
) -> Result<T> {
    let plaintext = decrypt_combined(combined, key)?;
    serde_json::from_slice(&plaintext)
        .map_err(|e| CryptoError::Json(format!("JSON deserialization failed: {}", e)))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt() {
        let key = Key::generate();
        let plaintext = b"Hello, World!";

        let encrypted = encrypt(plaintext, &key).unwrap();
        assert_eq!(encrypted.encrypted_data.len(), plaintext.len() + ABYTES);

        let decrypted = encrypted.decrypt(&key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_decrypt_requires_final_tag() {
        let key = Key::generate();
        let mut encryptor = Encryptor::new(&key);
        let header = *encryptor.header();
        let ciphertext = encryptor.push(b"partial", false).unwrap();

        assert!(matches!(
            decrypt(&ciphertext, &header, &key),
            Err(CryptoError::StreamTruncated)
        ));
    }

    #[test]
    fn test_decrypt_legacy_tolerates_missing_final_tag() {
        let key = Key::generate();
        let mut encryptor = Encryptor::new(&key);
        let header = *encryptor.header();
        let ciphertext = encryptor.push(b"partial", false).unwrap();

        let decrypted = decrypt_legacy(&ciphertext, &header, &key).unwrap();
        assert_eq!(decrypted, b"partial");
    }

    #[test]
    fn test_encrypt_decrypt_large() {
        let key = Key::generate();
        let plaintext = vec![0x42u8; 1024 * 1024]; // 1 MB

        let encrypted = encrypt(&plaintext, &key).unwrap();
        assert_eq!(encrypted.decrypt(&key).unwrap(), plaintext);
    }

    #[test]
    fn test_encrypt_decrypt_combined() {
        let key = Key::generate();
        let plaintext = b"Combined blob payload";

        let encrypted = encrypt_combined(plaintext, &key).unwrap();
        assert_eq!(decrypt_combined(&encrypted, &key).unwrap(), plaintext);
    }

    #[test]
    fn test_encrypt_decrypt_json_combined() {
        let key = Key::generate();
        let value = serde_json::json!({
            "name": "Alice",
            "birthDate": "2001-04-01"
        });

        let encrypted = encrypt_json_combined(&value, &key).unwrap();
        let decrypted: serde_json::Value = decrypt_json_combined(&encrypted, &key).unwrap();

        assert_eq!(decrypted, value);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key1 = Key::generate();
        let key2 = Key::generate();

        let encrypted = encrypt(b"Secret message", &key1).unwrap();
        assert!(matches!(
            encrypted.decrypt(&key2),
            Err(CryptoError::StreamPullFailed)
        ));
    }

    #[test]
    fn test_empty_plaintext() {
        let key = Key::generate();

        let encrypted = encrypt(b"", &key).unwrap();
        assert_eq!(encrypted.decrypt(&key).unwrap(), b"");
    }

    #[test]
    fn test_encrypt_decrypt_json() {
        let key = Key::generate();

        #[derive(serde::Serialize, serde::Deserialize, Debug, PartialEq)]
        struct TestData {
            name: String,
            value: i32,
        }

        let data = TestData {
            name: "test".to_string(),
            value: 42,
        };

        let encrypted = encrypt_json(&data, &key).unwrap();
        let decrypted: TestData = decrypt_json(&encrypted, &key).unwrap();
        assert_eq!(decrypted, data);
    }

    #[test]
    fn test_decrypt_json_wrong_type_returns_json_error() {
        let key = Key::generate();

        #[derive(serde::Serialize)]
        struct Original {
            name: String,
        }

        #[derive(serde::Deserialize, Debug)]
        #[allow(dead_code)]
        struct Different {
            count: u64,
        }

        let encrypted = encrypt_json(
            &Original {
                name: "test".to_string(),
            },
            &key,
        )
        .unwrap();

        // Decrypt into a mismatched type — should be CryptoError::Json
        let result: std::result::Result<Different, _> = decrypt_json(&encrypted, &key);
        assert!(
            matches!(result, Err(CryptoError::Json(_))),
            "Expected CryptoError::Json, got: {:?}",
            result
        );
    }

    #[test]
    fn test_ciphertext_too_short() {
        let key = Key::generate();
        let header = Header::try_from_slice(&[0u8; Header::BYTES]).unwrap();

        assert!(matches!(
            decrypt(&[0u8; ABYTES - 1], &header, &key),
            Err(CryptoError::CiphertextTooShort { .. })
        ));
    }

    #[test]
    fn test_corrupted_ciphertext() {
        let key = Key::generate();

        let mut encrypted = encrypt(b"Original data", &key).unwrap();
        encrypted.encrypted_data[10] ^= 1;

        assert!(encrypted.decrypt(&key).is_err());
    }

    #[test]
    fn test_corrupted_header() {
        let key = Key::generate();

        let encrypted = encrypt(b"Original data", &key).unwrap();
        let mut header_bytes = *encrypted.decryption_header.as_bytes();
        header_bytes[5] ^= 1;

        assert!(
            decrypt(
                &encrypted.encrypted_data,
                &Header::from_bytes(header_bytes),
                &key
            )
            .is_err()
        );
    }

    #[test]
    fn test_same_plaintext_produces_different_ciphertexts() {
        let key = Key::generate();
        let plaintext = b"Same message";

        let encrypted1 = encrypt(plaintext, &key).unwrap();
        let encrypted2 = encrypt(plaintext, &key).unwrap();

        // Different headers (random) -> different ciphertexts
        assert_ne!(encrypted1.decryption_header, encrypted2.decryption_header);
        assert_ne!(encrypted1.encrypted_data, encrypted2.encrypted_data);

        assert_eq!(encrypted1.decrypt(&key).unwrap(), plaintext);
        assert_eq!(encrypted2.decrypt(&key).unwrap(), plaintext);
    }
}
