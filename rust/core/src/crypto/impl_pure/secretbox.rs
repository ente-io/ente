//! SecretBox (XSalsa20-Poly1305) authenticated encryption.
//!
//! This module provides authenticated encryption using XSalsa20-Poly1305.
//! The wire format maintains byte-for-byte compatibility with libsodium's crypto_secretbox_easy:
//!
//! Output: MAC (16 bytes) || ciphertext (plaintext_len bytes)
//!
//! Note: RustCrypto's AEAD outputs ciphertext || MAC, so we must reorder bytes.

use xsalsa20poly1305::XSalsa20Poly1305;
use xsalsa20poly1305::aead::generic_array::GenericArray;
use xsalsa20poly1305::aead::{Aead, KeyInit};

use super::keys;
use crate::crypto::{CryptoError, Result};

/// Result of SecretBox encryption.
#[derive(Debug, Clone, PartialEq)]
pub struct EncryptedData {
    /// The encrypted data (nonce || MAC || ciphertext).
    pub encrypted_data: Vec<u8>,
    /// The nonce used for encryption (24 bytes).
    pub nonce: Vec<u8>,
    /// The key used for encryption (32 bytes).
    pub key: Vec<u8>,
}

/// Size of a SecretBox key in bytes.
pub const KEY_BYTES: usize = 32;

/// Size of a SecretBox nonce in bytes.
pub const NONCE_BYTES: usize = 24;

/// Size of the authentication tag in bytes.
pub const MAC_BYTES: usize = 16;

/// Encrypt plaintext with a random nonce.
///
/// This is the high-level API that generates a random nonce and returns
/// an EncryptedData structure.
///
/// # Arguments
/// * `plaintext` - Data to encrypt.
/// * `key` - 32-byte encryption key.
///
/// # Returns
/// EncryptedData containing encrypted_data (nonce || MAC || ciphertext) and nonce.
pub fn encrypt(plaintext: &[u8], key: &[u8]) -> Result<EncryptedData> {
    let nonce = keys::generate_secretbox_nonce();
    let encrypted = encrypt_with_nonce(plaintext, &nonce, key)?;

    let mut result = Vec::with_capacity(NONCE_BYTES + encrypted.len());
    result.extend_from_slice(&nonce);
    result.extend_from_slice(&encrypted);

    Ok(EncryptedData {
        encrypted_data: result,
        nonce,
        key: key.to_vec(),
    })
}

/// Encrypt plaintext with a provided nonce.
///
/// # Wire Format
/// Output: MAC (16 bytes) || ciphertext (plaintext_len bytes)
///
/// # Arguments
/// * `plaintext` - Data to encrypt.
/// * `nonce` - 24-byte nonce.
/// * `key` - 32-byte encryption key.
///
/// # Returns
/// ciphertext || MAC (libsodium crypto_secretbox_easy format)
pub fn encrypt_with_nonce(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if key.len() != KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: KEY_BYTES,
            actual: key.len(),
        });
    }
    if nonce.len() != NONCE_BYTES {
        return Err(CryptoError::InvalidNonceLength {
            expected: NONCE_BYTES,
            actual: nonce.len(),
        });
    }

    let cipher = XSalsa20Poly1305::new(GenericArray::from_slice(key));
    let nonce_ga = GenericArray::from_slice(nonce);

    // RustCrypto returns: ciphertext || MAC (same as libsodium crypto_secretbox_easy)
    cipher
        .encrypt(nonce_ga, plaintext)
        .map_err(|_| CryptoError::EncryptionFailed)
}

/// Trait for types that can be decrypted as SecretBox.
pub trait SecretBoxDecryptable {
    /// Returns the ciphertext bytes for decryption.
    fn as_ciphertext(&self) -> &[u8];
}

impl SecretBoxDecryptable for Vec<u8> {
    fn as_ciphertext(&self) -> &[u8] {
        self.as_slice()
    }
}

impl SecretBoxDecryptable for EncryptedData {
    fn as_ciphertext(&self) -> &[u8] {
        &self.encrypted_data
    }
}

impl SecretBoxDecryptable for [u8] {
    fn as_ciphertext(&self) -> &[u8] {
        self
    }
}

/// Decrypt a SecretBox (nonce || MAC || ciphertext).
///
/// # Arguments
/// * `ciphertext_with_nonce` - Data encrypted with `encrypt()` (can be &[u8], &Vec<u8>, or &EncryptedData).
/// * `key` - 32-byte encryption key.
///
/// # Returns
/// Decrypted plaintext.
pub fn decrypt_box<T: SecretBoxDecryptable + ?Sized>(encrypted: &T, key: &[u8]) -> Result<Vec<u8>> {
    let ciphertext_with_nonce = encrypted.as_ciphertext();

    if ciphertext_with_nonce.len() < NONCE_BYTES + MAC_BYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: NONCE_BYTES + MAC_BYTES,
            actual: ciphertext_with_nonce.len(),
        });
    }

    let nonce = &ciphertext_with_nonce[..NONCE_BYTES];
    let ciphertext = &ciphertext_with_nonce[NONCE_BYTES..];
    decrypt(ciphertext, nonce, key)
}

/// Decrypt ciphertext with a provided nonce.
///
/// # Wire Format
/// Input: ciphertext || MAC (16 bytes) (libsodium crypto_secretbox_easy format)
///
/// # Arguments
/// * `ciphertext` - Encrypted data || MAC.
/// * `nonce` - 24-byte nonce.
/// * `key` - 32-byte encryption key.
///
/// # Returns
/// Decrypted plaintext.
pub fn decrypt(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>> {
    if key.len() != KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: KEY_BYTES,
            actual: key.len(),
        });
    }
    if nonce.len() != NONCE_BYTES {
        return Err(CryptoError::InvalidNonceLength {
            expected: NONCE_BYTES,
            actual: nonce.len(),
        });
    }
    if ciphertext.len() < MAC_BYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: MAC_BYTES,
            actual: ciphertext.len(),
        });
    }

    // libsodium crypto_secretbox_easy format: ciphertext || MAC
    // RustCrypto expects same format: ciphertext || MAC
    let cipher = XSalsa20Poly1305::new(GenericArray::from_slice(key));
    let nonce_ga = GenericArray::from_slice(nonce);

    cipher
        .decrypt(nonce_ga, ciphertext)
        .map_err(|_| CryptoError::DecryptionFailed)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt() {
        let key = keys::generate_key();
        let plaintext = b"Hello, World!";

        let encrypted = encrypt(plaintext, &key).unwrap();
        let decrypted = decrypt_box(&encrypted, &key).unwrap();

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_encrypt_with_nonce() {
        let key = keys::generate_key();
        let nonce = keys::generate_secretbox_nonce();
        let plaintext = b"Test message";

        let encrypted = encrypt_with_nonce(plaintext, &nonce, &key).unwrap();
        assert_eq!(encrypted.len(), MAC_BYTES + plaintext.len());

        let decrypted = decrypt(&encrypted, &nonce, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_deterministic_with_same_nonce() {
        let key = keys::generate_key();
        let nonce = keys::generate_secretbox_nonce();
        let plaintext = b"Deterministic test";

        let encrypted1 = encrypt_with_nonce(plaintext, &nonce, &key).unwrap();
        let encrypted2 = encrypt_with_nonce(plaintext, &nonce, &key).unwrap();

        assert_eq!(encrypted1, encrypted2);
    }

    #[test]
    fn test_different_nonces_produce_different_ciphertexts() {
        let key = keys::generate_key();
        let plaintext = b"Same plaintext";

        let encrypted1 = encrypt(plaintext, &key).unwrap();
        let encrypted2 = encrypt(plaintext, &key).unwrap();

        // Different nonces -> different ciphertexts
        assert_ne!(encrypted1, encrypted2);

        // But both decrypt to same plaintext
        let decrypted1 = decrypt_box(&encrypted1, &key).unwrap();
        let decrypted2 = decrypt_box(&encrypted2, &key).unwrap();
        assert_eq!(decrypted1, plaintext);
        assert_eq!(decrypted2, plaintext);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key = keys::generate_key();
        let wrong_key = keys::generate_key();
        let plaintext = b"Secret";

        let encrypted = encrypt(plaintext, &key).unwrap();
        let result = decrypt_box(&encrypted, &wrong_key);

        assert!(result.is_err());
    }

    #[test]
    fn test_corrupted_ciphertext_fails() {
        let key = keys::generate_key();
        let plaintext = b"Original";

        let mut encrypted = encrypt(plaintext, &key).unwrap();

        // Corrupt a byte in the middle
        let mid = encrypted.encrypted_data.len() / 2;
        encrypted.encrypted_data[mid] ^= 1;

        let result = decrypt_box(&encrypted, &key);
        assert!(result.is_err());
    }

    #[test]
    fn test_invalid_key_length() {
        let bad_key = vec![0u8; 16]; // Wrong size
        let nonce = keys::generate_secretbox_nonce();
        let plaintext = b"Test";

        let result = encrypt_with_nonce(plaintext, &nonce, &bad_key);
        assert!(matches!(result, Err(CryptoError::InvalidKeyLength { .. })));
    }

    #[test]
    fn test_invalid_nonce_length() {
        let key = keys::generate_key();
        let bad_nonce = vec![0u8; 12]; // Wrong size
        let plaintext = b"Test";

        let result = encrypt_with_nonce(plaintext, &bad_nonce, &key);
        assert!(matches!(
            result,
            Err(CryptoError::InvalidNonceLength { .. })
        ));
    }

    #[test]
    fn test_ciphertext_too_short() {
        let key = keys::generate_key();
        let nonce = keys::generate_secretbox_nonce();
        let bad_ciphertext = vec![0u8; 10]; // Less than MAC_BYTES

        let result = decrypt(&bad_ciphertext, &nonce, &key);
        assert!(matches!(
            result,
            Err(CryptoError::CiphertextTooShort { .. })
        ));
    }

    #[test]
    fn test_empty_plaintext() {
        let key = keys::generate_key();
        let plaintext = b"";

        let encrypted = encrypt(plaintext, &key).unwrap();
        let decrypted = decrypt_box(&encrypted, &key).unwrap();

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_large_plaintext() {
        let key = keys::generate_key();
        let plaintext = vec![0x42u8; 1024 * 1024]; // 1 MB

        let encrypted = encrypt(&plaintext, &key).unwrap();
        let decrypted = decrypt_box(&encrypted, &key).unwrap();

        assert_eq!(decrypted, plaintext);
    }
}
