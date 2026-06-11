//! Key and nonce generation functions.
//!
//! Sizes come from the modules that own the corresponding algorithm
//! ([`secretbox`], [`stream`], [`argon`], [`sealed`]).

use rand_core::{OsRng, RngCore};
use x25519_dalek::{PublicKey, StaticSecret};
use zeroize::Zeroize;

use super::{argon, sealed, secretbox, stream};
use crate::crypto::{CryptoError, Result, SecretVec};

/// Generate a random SecretBox encryption key.
///
/// # Returns
/// A 32-byte random key, zeroized on drop.
pub fn generate_key() -> SecretVec {
    let mut key = vec![0u8; secretbox::KEY_BYTES];
    OsRng.fill_bytes(&mut key);
    SecretVec::new(key)
}

/// Generate a random SecretStream encryption key.
///
/// # Returns
/// A 32-byte random key, zeroized on drop.
pub fn generate_stream_key() -> SecretVec {
    let mut key = vec![0u8; stream::KEY_BYTES];
    OsRng.fill_bytes(&mut key);
    SecretVec::new(key)
}

/// Generate a random salt for key derivation.
///
/// # Returns
/// A 16-byte random salt. Salts are not secret.
pub fn generate_salt() -> Vec<u8> {
    let mut salt = vec![0u8; argon::SALT_BYTES];
    OsRng.fill_bytes(&mut salt);
    salt
}

/// Generate a random nonce for SecretBox encryption.
///
/// # Returns
/// A 24-byte random nonce. Nonces are not secret.
pub fn generate_secretbox_nonce() -> Vec<u8> {
    let mut nonce = vec![0u8; secretbox::NONCE_BYTES];
    OsRng.fill_bytes(&mut nonce);
    nonce
}

/// Generate a random X25519 key pair.
///
/// # Returns
/// A tuple of (public_key, secret_key); the secret key is zeroized on drop.
pub fn generate_keypair() -> (Vec<u8>, SecretVec) {
    let mut secret_bytes = [0u8; sealed::SECRET_KEY_BYTES];
    OsRng.fill_bytes(&mut secret_bytes);

    let secret = StaticSecret::from(secret_bytes);
    let public = PublicKey::from(&secret);

    secret_bytes.zeroize();

    (
        public.as_bytes().to_vec(),
        SecretVec::new(secret.to_bytes().to_vec()),
    )
}

/// Deterministically derive an X25519 key pair from a 32-byte seed.
///
/// The seed is clamped by `StaticSecret::from` per the X25519 construction,
/// making this suitable for deriving stable box keys from a higher-entropy
/// master secret.
pub fn derive_keypair_from_seed(seed: &[u8]) -> Result<(Vec<u8>, SecretVec)> {
    if seed.len() != sealed::SECRET_KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: sealed::SECRET_KEY_BYTES,
            actual: seed.len(),
        });
    }

    let mut secret_bytes = [0u8; sealed::SECRET_KEY_BYTES];
    secret_bytes.copy_from_slice(seed);

    let secret = StaticSecret::from(secret_bytes);
    let public = PublicKey::from(&secret);

    secret_bytes.zeroize();

    Ok((
        public.as_bytes().to_vec(),
        SecretVec::new(secret.to_bytes().to_vec()),
    ))
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
        assert_eq!(key.len(), secretbox::KEY_BYTES);

        // Test randomness - two keys should be different
        let key2 = generate_key();
        assert_ne!(key.as_ref(), key2.as_ref());
    }

    #[test]
    fn test_generate_stream_key() {
        let key = generate_stream_key();
        assert_eq!(key.len(), stream::KEY_BYTES);

        let key2 = generate_stream_key();
        assert_ne!(key.as_ref(), key2.as_ref());
    }

    #[test]
    fn test_generate_salt() {
        let salt = generate_salt();
        assert_eq!(salt.len(), argon::SALT_BYTES);

        let salt2 = generate_salt();
        assert_ne!(salt, salt2);
    }

    #[test]
    fn test_generate_secretbox_nonce() {
        let nonce = generate_secretbox_nonce();
        assert_eq!(nonce.len(), secretbox::NONCE_BYTES);

        let nonce2 = generate_secretbox_nonce();
        assert_ne!(nonce, nonce2);
    }

    #[test]
    fn test_generate_keypair() {
        let (pk, sk) = generate_keypair();
        assert_eq!(pk.len(), sealed::PUBLIC_KEY_BYTES);
        assert_eq!(sk.len(), sealed::SECRET_KEY_BYTES);

        // Test that keys are different
        let (pk2, sk2) = generate_keypair();
        assert_ne!(pk, pk2);
        assert_ne!(sk.as_ref(), sk2.as_ref());
    }

    #[test]
    fn test_derive_keypair_from_seed() {
        let seed = [7u8; sealed::SECRET_KEY_BYTES];
        let (pk1, sk1) = derive_keypair_from_seed(&seed).unwrap();
        let (pk2, sk2) = derive_keypair_from_seed(&seed).unwrap();

        assert_eq!(pk1, pk2);
        assert_eq!(sk1.as_ref(), sk2.as_ref());
    }

    #[test]
    fn test_derive_keypair_from_seed_rejects_wrong_length() {
        let err = derive_keypair_from_seed(&[1u8; 16]).unwrap_err();
        assert!(matches!(err, CryptoError::InvalidKeyLength { .. }));
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
