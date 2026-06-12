//! SecretBox (XSalsa20-Poly1305) authenticated encryption.
//!
//! This module provides authenticated encryption using XSalsa20-Poly1305,
//! byte-for-byte compatible with libsodium's `crypto_secretbox_easy`.
//!
//! Two payload shapes are supported:
//!
//! - Split ([`encrypt`] / [`decrypt`]): the ciphertext (`MAC ‖ ct`) and the
//!   nonce travel separately. This matches the server's wire format, where
//!   encrypted fields are stored alongside their nonces.
//!
//! - Combined ([`encrypt_combined`] / [`decrypt_combined`]): a single
//!   self-contained buffer (`nonce ‖ MAC ‖ ct`).

use xsalsa20poly1305::XSalsa20Poly1305;
use xsalsa20poly1305::aead::generic_array::GenericArray;
use xsalsa20poly1305::aead::{Aead, KeyInit};

use crate::crypto::{CryptoError, Key, Nonce, Result};

/// Size of the authentication tag in bytes.
pub const MAC_BYTES: usize = 16;

/// The result of SecretBox encryption: ciphertext and nonce, separate.
#[derive(Debug, Clone, PartialEq)]
pub struct EncryptedBox {
    /// The encrypted data: `MAC (16 bytes) ‖ ciphertext`.
    pub encrypted_data: Vec<u8>,
    /// The nonce used during encryption. Required for decryption; not secret.
    pub nonce: Nonce,
}

impl EncryptedBox {
    /// Decrypt this box.
    pub fn decrypt(&self, key: &Key) -> Result<Vec<u8>> {
        decrypt(&self.encrypted_data, &self.nonce, key)
    }
}

/// Encrypt the given data with a randomly generated nonce.
///
/// Use [`decrypt`] or [`EncryptedBox::decrypt`] to decrypt the result.
pub fn encrypt(data: &[u8], key: &Key) -> EncryptedBox {
    let nonce = Nonce::generate();
    let encrypted_data = encrypt_with_nonce(data, &nonce, key);
    EncryptedBox {
        encrypted_data,
        nonce,
    }
}

/// Encrypt the given data with the provided nonce.
///
/// Returns `MAC (16 bytes) ‖ ciphertext` (libsodium `crypto_secretbox_easy`
/// format).
pub fn encrypt_with_nonce(data: &[u8], nonce: &Nonce, key: &Key) -> Vec<u8> {
    let cipher = XSalsa20Poly1305::new(GenericArray::from_slice(key.as_bytes()));
    let nonce_ga = GenericArray::from_slice(nonce.as_bytes());

    // The underlying AEAD encrypt only fails on plaintexts exceeding the
    // cipher's size bounds, which cannot be reached with in-memory slices.
    cipher
        .encrypt(nonce_ga, data)
        .expect("XSalsa20-Poly1305 encryption cannot fail for in-memory plaintexts")
}

/// Decrypt data encrypted with [`encrypt`] or [`encrypt_with_nonce`].
///
/// `data` is `MAC (16 bytes) ‖ ciphertext`.
pub fn decrypt(data: &[u8], nonce: &Nonce, key: &Key) -> Result<Vec<u8>> {
    if data.len() < MAC_BYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: MAC_BYTES,
            actual: data.len(),
        });
    }

    let cipher = XSalsa20Poly1305::new(GenericArray::from_slice(key.as_bytes()));
    let nonce_ga = GenericArray::from_slice(nonce.as_bytes());

    cipher
        .decrypt(nonce_ga, data)
        .map_err(|_| CryptoError::DecryptionFailed)
}

/// Encrypt the given data into a single self-contained buffer.
///
/// Returns `nonce (24 bytes) ‖ MAC (16 bytes) ‖ ciphertext`. Everything needed
/// for decryption except the key is in the returned buffer; use
/// [`decrypt_combined`] to decrypt it.
pub fn encrypt_combined(data: &[u8], key: &Key) -> Vec<u8> {
    let nonce = Nonce::generate();
    let encrypted = encrypt_with_nonce(data, &nonce, key);

    let mut combined = Vec::with_capacity(Nonce::BYTES + encrypted.len());
    combined.extend_from_slice(nonce.as_bytes());
    combined.extend_from_slice(&encrypted);
    combined
}

/// Decrypt a combined `nonce ‖ MAC ‖ ciphertext` buffer produced by
/// [`encrypt_combined`].
pub fn decrypt_combined(data: &[u8], key: &Key) -> Result<Vec<u8>> {
    if data.len() < Nonce::BYTES + MAC_BYTES {
        return Err(CryptoError::CiphertextTooShort {
            minimum: Nonce::BYTES + MAC_BYTES,
            actual: data.len(),
        });
    }

    let (nonce, encrypted) = data.split_at(Nonce::BYTES);
    decrypt(encrypted, &Nonce::try_from_slice(nonce)?, key)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt() {
        let key = Key::generate();
        let plaintext = b"Hello, World!";

        let encrypted = encrypt(plaintext, &key);
        assert_eq!(encrypted.encrypted_data.len(), MAC_BYTES + plaintext.len());

        let decrypted = encrypted.decrypt(&key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_encrypt_with_nonce_is_deterministic() {
        let key = Key::generate();
        let nonce = Nonce::generate();
        let plaintext = b"Deterministic test";

        let encrypted1 = encrypt_with_nonce(plaintext, &nonce, &key);
        let encrypted2 = encrypt_with_nonce(plaintext, &nonce, &key);
        assert_eq!(encrypted1, encrypted2);

        let decrypted = decrypt(&encrypted1, &nonce, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_different_nonces_produce_different_ciphertexts() {
        let key = Key::generate();
        let plaintext = b"Same plaintext";

        let encrypted1 = encrypt(plaintext, &key);
        let encrypted2 = encrypt(plaintext, &key);
        assert_ne!(encrypted1, encrypted2);

        assert_eq!(encrypted1.decrypt(&key).unwrap(), plaintext);
        assert_eq!(encrypted2.decrypt(&key).unwrap(), plaintext);
    }

    #[test]
    fn test_combined_roundtrip() {
        let key = Key::generate();
        let plaintext = b"Combined format test";

        let combined = encrypt_combined(plaintext, &key);
        assert_eq!(combined.len(), Nonce::BYTES + MAC_BYTES + plaintext.len());

        let decrypted = decrypt_combined(&combined, &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_combined_is_split_with_nonce_prefix() {
        // The combined format must be exactly nonce ‖ (split ciphertext), so
        // the two shapes stay interconvertible.
        let key = Key::generate();
        let plaintext = b"Interop test";

        let combined = encrypt_combined(plaintext, &key);
        let (nonce, encrypted) = combined.split_at(Nonce::BYTES);
        let decrypted = decrypt(encrypted, &Nonce::try_from_slice(nonce).unwrap(), &key).unwrap();
        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_wrong_key_fails() {
        let key = Key::generate();
        let wrong_key = Key::generate();

        let encrypted = encrypt(b"Secret", &key);
        assert!(encrypted.decrypt(&wrong_key).is_err());

        let combined = encrypt_combined(b"Secret", &key);
        assert!(decrypt_combined(&combined, &wrong_key).is_err());
    }

    #[test]
    fn test_corrupted_ciphertext_fails() {
        let key = Key::generate();

        let mut encrypted = encrypt(b"Original", &key);
        let mid = encrypted.encrypted_data.len() / 2;
        encrypted.encrypted_data[mid] ^= 1;

        assert!(matches!(
            encrypted.decrypt(&key),
            Err(CryptoError::DecryptionFailed)
        ));
    }

    #[test]
    fn test_ciphertext_too_short() {
        let key = Key::generate();

        assert!(matches!(
            decrypt(&[0u8; 10], &Nonce::generate(), &key),
            Err(CryptoError::CiphertextTooShort { .. })
        ));
        assert!(matches!(
            decrypt_combined(&[0u8; 30], &key),
            Err(CryptoError::CiphertextTooShort { .. })
        ));
    }

    #[test]
    fn test_empty_plaintext() {
        let key = Key::generate();

        let encrypted = encrypt(b"", &key);
        assert_eq!(encrypted.decrypt(&key).unwrap(), b"");

        let combined = encrypt_combined(b"", &key);
        assert_eq!(decrypt_combined(&combined, &key).unwrap(), b"");
    }

    #[test]
    fn test_large_plaintext() {
        let key = Key::generate();
        let plaintext = vec![0x42u8; 1024 * 1024]; // 1 MB

        let encrypted = encrypt(&plaintext, &key);
        assert_eq!(encrypted.decrypt(&key).unwrap(), plaintext);
    }
}
