//! Blob encryption (XChaCha20-Poly1305 SecretStream without chunking).
//!
//! This module provides encryption using SecretStream for small-ish data
//! that doesn't need to be chunked. Use this for encrypting metadata
//! associated with Ente objects.

use super::stream::{StreamDecryptor, StreamEncryptor};
use crate::crypto::{CryptoError, Result};

// Re-export stream constants for public API compatibility
pub use super::stream::{ABYTES, HEADER_BYTES, KEY_BYTES, TAG_FINAL, TAG_MESSAGE};

/// Result of blob encryption.
#[derive(Debug, Clone)]
pub struct EncryptedBlob {
    /// The encrypted data.
    pub encrypted_data: Vec<u8>,
    /// The decryption header.
    pub decryption_header: Vec<u8>,
}

/// Encrypt data using SecretStream (XChaCha20-Poly1305) without chunking.
///
/// This is suitable for encrypting metadata and small files.
///
/// # Arguments
/// * `plaintext` - Data to encrypt.
/// * `key` - 32-byte encryption key.
///
/// # Returns
/// An [`EncryptedBlob`] containing the ciphertext and decryption header.
pub fn encrypt(plaintext: &[u8], key: &[u8]) -> Result<EncryptedBlob> {
    if key.len() != KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: KEY_BYTES,
            actual: key.len(),
        });
    }

    // Create encryptor
    let mut encryptor = StreamEncryptor::new(key)?;
    let header = encryptor.header.clone();

    // Encrypt with final tag (single message)
    let ciphertext = encryptor.push(plaintext, true)?;

    Ok(EncryptedBlob {
        encrypted_data: ciphertext,
        decryption_header: header,
    })
}

/// Decrypt data encrypted with [`encrypt`].
///
/// # Arguments
/// * `ciphertext` - The encrypted data.
/// * `header` - The decryption header.
/// * `key` - The 32-byte encryption key.
///
/// # Returns
/// The decrypted plaintext.
pub fn decrypt(ciphertext: &[u8], header: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if key.len() != KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: KEY_BYTES,
            actual: key.len(),
        });
    }

    if header.len() != HEADER_BYTES {
        return Err(CryptoError::InvalidHeaderLength {
            expected: HEADER_BYTES,
            actual: header.len(),
        });
    }

    if ciphertext.len() < ABYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: ABYTES,
            actual: ciphertext.len(),
        });
    }

    // Create decryptor
    let mut decryptor = StreamDecryptor::new(header, key)?;

    // Decrypt
    let (plaintext, _tag) = decryptor.pull(ciphertext)?;

    Ok(plaintext)
}

/// Decrypt an [`EncryptedBlob`].
///
/// # Arguments
/// * `blob` - The encrypted blob.
/// * `key` - The 32-byte encryption key.
///
/// # Returns
/// The decrypted plaintext.
pub fn decrypt_blob(blob: &EncryptedBlob, key: &[u8]) -> Result<Vec<u8>> {
    decrypt(&blob.encrypted_data, &blob.decryption_header, key)
}

/// Encrypt a JSON value.
///
/// # Arguments
/// * `value` - The value to serialize and encrypt.
/// * `key` - The 32-byte encryption key.
///
/// # Returns
/// An [`EncryptedBlob`] containing the encrypted JSON.
pub fn encrypt_json<T: serde::Serialize>(value: &T, key: &[u8]) -> Result<EncryptedBlob> {
    let json = serde_json::to_vec(value).map_err(|e| {
        CryptoError::InvalidKeyDerivationParams(format!("JSON serialization failed: {}", e))
    })?;
    encrypt(&json, key)
}

/// Decrypt to a JSON value.
///
/// # Arguments
/// * `blob` - The encrypted blob.
/// * `key` - The 32-byte encryption key.
///
/// # Returns
/// The deserialized JSON value.
pub fn decrypt_json<T: serde::de::DeserializeOwned>(blob: &EncryptedBlob, key: &[u8]) -> Result<T> {
    let plaintext = decrypt_blob(blob, key)?;
    serde_json::from_slice(&plaintext).map_err(|e| {
        CryptoError::InvalidKeyDerivationParams(format!("JSON deserialization failed: {}", e))
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::impl_pure::keys;

    #[test]
    fn test_encrypt_decrypt() {
        let key = keys::generate_stream_key();
        let plaintext = b"Hello, World!";

        let encrypted = encrypt(plaintext, &key).unwrap();
        assert_eq!(encrypted.decryption_header.len(), HEADER_BYTES);
        assert_eq!(encrypted.encrypted_data.len(), plaintext.len() + ABYTES);

        let decrypted = decrypt_blob(&encrypted, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_encrypt_decrypt_large() {
        let key = keys::generate_stream_key();
        let plaintext = vec![0x42u8; 1024 * 1024]; // 1 MB

        let encrypted = encrypt(&plaintext, &key).unwrap();
        let decrypted = decrypt_blob(&encrypted, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key1 = keys::generate_stream_key();
        let key2 = keys::generate_stream_key();
        let plaintext = b"Secret message";

        let encrypted = encrypt(plaintext, &key1).unwrap();
        let result = decrypt_blob(&encrypted, &key2);
        assert!(matches!(result, Err(CryptoError::StreamPullFailed)));
    }

    #[test]
    fn test_empty_plaintext() {
        let key = keys::generate_stream_key();
        let plaintext = b"";

        let encrypted = encrypt(plaintext, &key).unwrap();
        let decrypted = decrypt_blob(&encrypted, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_encrypt_decrypt_json() {
        let key = keys::generate_stream_key();

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
    fn test_invalid_key_length() {
        let short_key = vec![0u8; 16];
        let result = encrypt(b"test", &short_key);
        assert!(matches!(result, Err(CryptoError::InvalidKeyLength { .. })));
    }

    #[test]
    fn test_invalid_header_length() {
        let key = keys::generate_stream_key();
        let short_header = vec![0u8; 12];
        let result = decrypt(b"test_ciphertext_here", &short_header, &key);
        assert!(matches!(
            result,
            Err(CryptoError::InvalidHeaderLength { .. })
        ));
    }

    #[test]
    fn test_corrupted_ciphertext() {
        let key = keys::generate_stream_key();
        let plaintext = b"Original data";

        let encrypted = encrypt(plaintext, &key).unwrap();
        let mut corrupted = encrypted.clone();

        // Corrupt a byte in the encrypted data
        corrupted.encrypted_data[10] ^= 1;

        let result = decrypt_blob(&corrupted, &key);
        assert!(result.is_err());
    }

    #[test]
    fn test_corrupted_header() {
        let key = keys::generate_stream_key();
        let plaintext = b"Original data";

        let encrypted = encrypt(plaintext, &key).unwrap();
        let mut corrupted_header = encrypted.decryption_header.clone();

        // Corrupt a byte in the header
        corrupted_header[5] ^= 1;

        let result = decrypt(&encrypted.encrypted_data, &corrupted_header, &key);
        assert!(result.is_err());
    }

    #[test]
    fn test_different_plaintexts_produce_different_ciphertexts() {
        let key = keys::generate_stream_key();

        let encrypted1 = encrypt(b"Message 1", &key).unwrap();
        let encrypted2 = encrypt(b"Message 2", &key).unwrap();

        assert_ne!(encrypted1.encrypted_data, encrypted2.encrypted_data);
    }

    #[test]
    fn test_same_plaintext_produces_different_ciphertexts() {
        let key = keys::generate_stream_key();
        let plaintext = b"Same message";

        let encrypted1 = encrypt(plaintext, &key).unwrap();
        let encrypted2 = encrypt(plaintext, &key).unwrap();

        // Different headers (random) -> different ciphertexts
        assert_ne!(encrypted1.decryption_header, encrypted2.decryption_header);
        assert_ne!(encrypted1.encrypted_data, encrypted2.encrypted_data);

        // But both decrypt to same plaintext
        let decrypted1 = decrypt_blob(&encrypted1, &key).unwrap();
        let decrypted2 = decrypt_blob(&encrypted2, &key).unwrap();
        assert_eq!(decrypted1, plaintext);
        assert_eq!(decrypted2, plaintext);
    }
}
