//! Key and nonce generation functions.

use rand_core::{OsRng, RngCore};
use x25519_dalek::{PublicKey, StaticSecret};
use zeroize::Zeroize;

use crate::crypto::Result;

/// Size of a SecretBox key in bytes.
pub const SECRETBOX_KEY_BYTES: usize = 32;

/// Size of a SecretBox nonce in bytes.
pub const SECRETBOX_NONCE_BYTES: usize = 24;

/// Size of a SecretStream key in bytes.
pub const STREAM_KEY_BYTES: usize = 32;

/// Size of a salt in bytes.
pub const SALT_BYTES: usize = 16;

/// Size of a public key in bytes.
pub const BOX_PUBLIC_KEY_BYTES: usize = 32;

/// Size of a secret key in bytes.
pub const BOX_SECRET_KEY_BYTES: usize = 32;

/// Generate a random SecretBox encryption key.
///
/// # Returns
/// A 32-byte random key.
pub fn generate_key() -> Vec<u8> {
    let mut key = vec![0u8; SECRETBOX_KEY_BYTES];
    OsRng.fill_bytes(&mut key);
    key
}

/// Generate a random SecretStream encryption key.
///
/// # Returns
/// A 32-byte random key.
pub fn generate_stream_key() -> Vec<u8> {
    let mut key = vec![0u8; STREAM_KEY_BYTES];
    OsRng.fill_bytes(&mut key);
    key
}

/// Generate a random salt for key derivation.
///
/// # Returns
/// A 16-byte random salt.
pub fn generate_salt() -> Vec<u8> {
    let mut salt = vec![0u8; SALT_BYTES];
    OsRng.fill_bytes(&mut salt);
    salt
}

/// Generate a random nonce for SecretBox encryption.
///
/// # Returns
/// A 24-byte random nonce.
pub fn generate_secretbox_nonce() -> Vec<u8> {
    let mut nonce = vec![0u8; SECRETBOX_NONCE_BYTES];
    OsRng.fill_bytes(&mut nonce);
    nonce
}

/// Generate a random X25519 key pair.
///
/// # Returns
/// A tuple of (public_key, secret_key), both as 32-byte vectors.
pub fn generate_keypair() -> Result<(Vec<u8>, Vec<u8>)> {
    let mut secret_bytes = [0u8; 32];
    OsRng.fill_bytes(&mut secret_bytes);

    let secret = StaticSecret::from(secret_bytes);
    let public = PublicKey::from(&secret);

    secret_bytes.zeroize();

    Ok((public.as_bytes().to_vec(), secret.to_bytes().to_vec()))
}

/// Generate random bytes of specified length.
///
/// # Arguments
/// * `len` - Number of random bytes to generate.
///
/// # Returns
/// A vector of random bytes.
pub fn random_bytes(len: usize) -> Vec<u8> {
    let mut buf = vec![0u8; len];
    OsRng.fill_bytes(&mut buf);
    buf
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_key() {
        let key = generate_key();
        assert_eq!(key.len(), SECRETBOX_KEY_BYTES);

        // Test randomness - two keys should be different
        let key2 = generate_key();
        assert_ne!(key, key2);
    }

    #[test]
    fn test_generate_stream_key() {
        let key = generate_stream_key();
        assert_eq!(key.len(), STREAM_KEY_BYTES);

        let key2 = generate_stream_key();
        assert_ne!(key, key2);
    }

    #[test]
    fn test_generate_salt() {
        let salt = generate_salt();
        assert_eq!(salt.len(), SALT_BYTES);

        let salt2 = generate_salt();
        assert_ne!(salt, salt2);
    }

    #[test]
    fn test_generate_secretbox_nonce() {
        let nonce = generate_secretbox_nonce();
        assert_eq!(nonce.len(), SECRETBOX_NONCE_BYTES);

        let nonce2 = generate_secretbox_nonce();
        assert_ne!(nonce, nonce2);
    }

    #[test]
    fn test_generate_keypair() {
        let (pk, sk) = generate_keypair().unwrap();
        assert_eq!(pk.len(), BOX_PUBLIC_KEY_BYTES);
        assert_eq!(sk.len(), BOX_SECRET_KEY_BYTES);

        // Test that keys are different
        let (pk2, sk2) = generate_keypair().unwrap();
        assert_ne!(pk, pk2);
        assert_ne!(sk, sk2);
    }

    #[test]
    fn test_random_bytes() {
        let bytes = random_bytes(16);
        assert_eq!(bytes.len(), 16);

        let bytes2 = random_bytes(16);
        assert_ne!(bytes, bytes2);

        // Test different lengths
        let bytes_32 = random_bytes(32);
        assert_eq!(bytes_32.len(), 32);
    }
}
