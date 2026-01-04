//! Sealed box (anonymous public-key encryption).
//!
//! Sealed boxes provide encryption to a recipient's public key without revealing
//! the sender's identity. This is achieved using an ephemeral key pair.
//!
//! # Wire Format (libsodium crypto_box_seal)
//!
//! Output: ephemeral_pk (32 bytes) || ciphertext || MAC (16 bytes)
//!
//! - Nonce: BLAKE2b-24(ephemeral_pk || recipient_pk)
//! - Shared secret: X25519(ephemeral_sk, recipient_pk)
//! - Key: HSalsa20(shared_secret, zero_nonce)
//! - Encryption: XSalsa20-Poly1305 (ciphertext || MAC format)

use blake2b_simd::Params as Blake2bParams;
use rand_core::{OsRng, RngCore};
use salsa20::hsalsa;
use x25519_dalek::{PublicKey, StaticSecret};
use xsalsa20poly1305::XSalsa20Poly1305;
use xsalsa20poly1305::aead::generic_array::GenericArray;
use xsalsa20poly1305::aead::{Aead, KeyInit};
use zeroize::Zeroize;

use crate::crypto::{CryptoError, Result};

/// Size of a public key in bytes.
pub const PUBLIC_KEY_BYTES: usize = 32;

/// Size of a secret key in bytes.
pub const SECRET_KEY_BYTES: usize = 32;

/// Overhead added by sealing (ephemeral_pk + MAC).
pub const SEAL_OVERHEAD: usize = 32 + 16;

/// Size of sealed box overhead (API compatibility).
pub const SEAL_BYTES: usize = SEAL_OVERHEAD;

/// Derive nonce from ephemeral and recipient public keys.
///
/// Nonce = BLAKE2b-24(ephemeral_pk || recipient_pk)
fn seal_nonce(ephemeral_pk: &[u8; 32], recipient_pk: &[u8; 32]) -> [u8; 24] {
    let hash = Blake2bParams::new()
        .hash_length(24)
        .to_state()
        .update(ephemeral_pk)
        .update(recipient_pk)
        .finalize();

    let mut nonce = [0u8; 24];
    nonce.copy_from_slice(hash.as_bytes());
    nonce
}

/// Derive crypto_box key from X25519 shared secret.
///
/// Key = HSalsa20(shared_secret, zero_nonce)
fn derive_box_key(shared_secret: &[u8; 32]) -> [u8; 32] {
    use salsa20::cipher::consts::U10;

    let zero_nonce = [0u8; 16];

    // HSalsa20 core function with 20 rounds (U10 * 2)
    let result = hsalsa::<U10>(shared_secret.into(), (&zero_nonce).into());

    result.into()
}

/// Check if shared secret is contributory (not all zeros).
///
/// This prevents attacks using small-order points.
fn is_contributory(shared_secret: &[u8; 32]) -> bool {
    shared_secret.iter().any(|&b| b != 0)
}

/// Seal (encrypt) plaintext for a recipient's public key.
///
/// Creates an ephemeral key pair and encrypts the message such that only
/// the recipient can decrypt it, without revealing the sender's identity.
///
/// # Arguments
/// * `plaintext` - Data to encrypt.
/// * `recipient_pk` - Recipient's 32-byte public key.
///
/// # Returns
/// ephemeral_pk || ciphertext || MAC (libsodium crypto_box_seal format)
pub fn seal(plaintext: &[u8], recipient_pk: &[u8]) -> Result<Vec<u8>> {
    if recipient_pk.len() != PUBLIC_KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: PUBLIC_KEY_BYTES,
            actual: recipient_pk.len(),
        });
    }

    let recipient_pk_arr: [u8; 32] = recipient_pk
        .try_into()
        .map_err(|_| CryptoError::ArrayConversion)?;
    let recipient_pk_point = PublicKey::from(recipient_pk_arr);

    // Generate ephemeral keypair
    let mut ephemeral_secret_bytes = [0u8; 32];
    OsRng.fill_bytes(&mut ephemeral_secret_bytes);
    let ephemeral_secret = StaticSecret::from(ephemeral_secret_bytes);
    let ephemeral_public = PublicKey::from(&ephemeral_secret);

    // Compute shared secret
    let shared_secret = ephemeral_secret.diffie_hellman(&recipient_pk_point);

    // SECURITY: Reject non-contributory (small-order point)
    if !is_contributory(shared_secret.as_bytes()) {
        ephemeral_secret_bytes.zeroize();
        return Err(CryptoError::InvalidPublicKey);
    }

    // Derive encryption key
    let box_key = derive_box_key(shared_secret.as_bytes());

    // Compute nonce
    let nonce = seal_nonce(ephemeral_public.as_bytes(), &recipient_pk_arr);

    // Encrypt with XSalsa20-Poly1305
    // RustCrypto outputs: ciphertext || MAC (same as libsodium)
    let cipher = XSalsa20Poly1305::new(GenericArray::from_slice(&box_key));
    let encrypted = cipher
        .encrypt(GenericArray::from_slice(&nonce), plaintext)
        .map_err(|_| CryptoError::EncryptionFailed)?;

    // Build output: ephemeral_pk || ciphertext || MAC
    let mut result = Vec::with_capacity(32 + encrypted.len());
    result.extend_from_slice(ephemeral_public.as_bytes());
    result.extend_from_slice(&encrypted);

    // Clean up sensitive data
    ephemeral_secret_bytes.zeroize();

    Ok(result)
}

/// Open (decrypt) a sealed box.
///
/// # Arguments
/// * `ciphertext` - Sealed data (ephemeral_pk || ciphertext || MAC).
/// * `recipient_pk` - Recipient's 32-byte public key.
/// * `recipient_sk` - Recipient's 32-byte secret key.
///
/// # Returns
/// Decrypted plaintext.
pub fn open(ciphertext: &[u8], recipient_pk: &[u8], recipient_sk: &[u8]) -> Result<Vec<u8>> {
    if ciphertext.len() < SEAL_OVERHEAD {
        return Err(CryptoError::CiphertextTooShort {
            minimum: SEAL_OVERHEAD,
            actual: ciphertext.len(),
        });
    }

    if recipient_pk.len() != PUBLIC_KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: PUBLIC_KEY_BYTES,
            actual: recipient_pk.len(),
        });
    }

    if recipient_sk.len() != SECRET_KEY_BYTES {
        return Err(CryptoError::InvalidKeyLength {
            expected: SECRET_KEY_BYTES,
            actual: recipient_sk.len(),
        });
    }

    // Parse: ephemeral_pk (32) || ciphertext || MAC (16)
    let ephemeral_pk_bytes: [u8; 32] = ciphertext[..32]
        .try_into()
        .map_err(|_| CryptoError::ArrayConversion)?;
    let encrypted = &ciphertext[32..]; // ciphertext || MAC

    let ephemeral_pk = PublicKey::from(ephemeral_pk_bytes);
    let recipient_sk_arr: [u8; 32] = recipient_sk
        .try_into()
        .map_err(|_| CryptoError::ArrayConversion)?;
    let recipient_sk_key = StaticSecret::from(recipient_sk_arr);
    let recipient_pk_arr: [u8; 32] = recipient_pk
        .try_into()
        .map_err(|_| CryptoError::ArrayConversion)?;

    // Compute shared secret
    let shared_secret = recipient_sk_key.diffie_hellman(&ephemeral_pk);

    // SECURITY: Reject non-contributory (small-order point)
    if !is_contributory(shared_secret.as_bytes()) {
        return Err(CryptoError::InvalidPublicKey);
    }

    // Derive encryption key
    let box_key = derive_box_key(shared_secret.as_bytes());

    // Compute nonce
    let nonce = seal_nonce(&ephemeral_pk_bytes, &recipient_pk_arr);

    // Decrypt (RustCrypto expects same format: ciphertext || MAC)
    let cipher = XSalsa20Poly1305::new(GenericArray::from_slice(&box_key));
    cipher
        .decrypt(GenericArray::from_slice(&nonce), encrypted)
        .map_err(|_| CryptoError::DecryptionFailed)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::impl_pure::keys;

    #[test]
    fn test_seal_open() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Hello, sealed world!";

        let sealed = seal(plaintext, &pk).unwrap();
        let opened = open(&sealed, &pk, &sk).unwrap();

        assert_eq!(opened, plaintext);
    }

    #[test]
    fn test_seal_overhead() {
        let (pk, _sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Test";

        let sealed = seal(plaintext, &pk).unwrap();
        assert_eq!(sealed.len(), plaintext.len() + SEAL_OVERHEAD);
    }

    #[test]
    fn test_seal_non_deterministic() {
        let (pk, _sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Same message";

        let sealed1 = seal(plaintext, &pk).unwrap();
        let sealed2 = seal(plaintext, &pk).unwrap();

        // Different ephemeral keys -> different ciphertexts
        assert_ne!(sealed1, sealed2);
    }

    #[test]
    fn test_wrong_secret_key() {
        let (pk1, _sk1) = keys::generate_keypair().unwrap();
        let (_pk2, sk2) = keys::generate_keypair().unwrap();
        let plaintext = b"Secret";

        let sealed = seal(plaintext, &pk1).unwrap();
        let result = open(&sealed, &pk1, &sk2);

        assert!(result.is_err());
    }

    #[test]
    fn test_wrong_public_key() {
        let (pk1, sk1) = keys::generate_keypair().unwrap();
        let (pk2, _sk2) = keys::generate_keypair().unwrap();
        let plaintext = b"Secret";

        let sealed = seal(plaintext, &pk1).unwrap();
        let result = open(&sealed, &pk2, &sk1);

        assert!(result.is_err());
    }

    #[test]
    fn test_corrupted_ciphertext() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Original";

        let mut sealed = seal(plaintext, &pk).unwrap();

        // Corrupt a byte in the middle
        let mid = sealed.len() / 2;
        sealed[mid] ^= 1;

        let result = open(&sealed, &pk, &sk);
        assert!(result.is_err());
    }

    #[test]
    fn test_corrupted_ephemeral_key() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Original";

        let mut sealed = seal(plaintext, &pk).unwrap();

        // Corrupt ephemeral public key
        sealed[0] ^= 1;

        let result = open(&sealed, &pk, &sk);
        assert!(result.is_err());
    }

    #[test]
    fn test_corrupted_mac() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Original";

        let mut sealed = seal(plaintext, &pk).unwrap();

        // Corrupt MAC (at position 32-47)
        sealed[40] ^= 1;

        let result = open(&sealed, &pk, &sk);
        assert!(result.is_err());
    }

    #[test]
    fn test_invalid_public_key_length_seal() {
        let bad_pk = vec![0u8; 16]; // Wrong size
        let plaintext = b"Test";

        let result = seal(plaintext, &bad_pk);
        assert!(matches!(result, Err(CryptoError::InvalidKeyLength { .. })));
    }

    #[test]
    fn test_invalid_public_key_length_open() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Test";
        let sealed = seal(plaintext, &pk).unwrap();

        let bad_pk = vec![0u8; 16];
        let result = open(&sealed, &bad_pk, &sk);
        assert!(matches!(result, Err(CryptoError::InvalidKeyLength { .. })));
    }

    #[test]
    fn test_invalid_secret_key_length() {
        let (pk, _sk) = keys::generate_keypair().unwrap();
        let plaintext = b"Test";
        let sealed = seal(plaintext, &pk).unwrap();

        let bad_sk = vec![0u8; 16];
        let result = open(&sealed, &pk, &bad_sk);
        assert!(matches!(result, Err(CryptoError::InvalidKeyLength { .. })));
    }

    #[test]
    fn test_ciphertext_too_short() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let bad_ciphertext = vec![0u8; 40]; // Less than SEAL_OVERHEAD

        let result = open(&bad_ciphertext, &pk, &sk);
        assert!(matches!(
            result,
            Err(CryptoError::CiphertextTooShort { .. })
        ));
    }

    #[test]
    fn test_empty_plaintext() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = b"";

        let sealed = seal(plaintext, &pk).unwrap();
        let opened = open(&sealed, &pk, &sk).unwrap();

        assert_eq!(opened, plaintext);
        assert_eq!(sealed.len(), SEAL_OVERHEAD);
    }

    #[test]
    fn test_large_plaintext() {
        let (pk, sk) = keys::generate_keypair().unwrap();
        let plaintext = vec![0x42u8; 1024 * 1024]; // 1 MB

        let sealed = seal(&plaintext, &pk).unwrap();
        let opened = open(&sealed, &pk, &sk).unwrap();

        assert_eq!(opened, plaintext);
    }

    #[test]
    fn test_multiple_recipients() {
        let (pk1, sk1) = keys::generate_keypair().unwrap();
        let (pk2, sk2) = keys::generate_keypair().unwrap();
        let plaintext = b"Broadcast message";

        // Seal for different recipients
        let sealed1 = seal(plaintext, &pk1).unwrap();
        let sealed2 = seal(plaintext, &pk2).unwrap();

        // Each recipient can decrypt their own
        let opened1 = open(&sealed1, &pk1, &sk1).unwrap();
        let opened2 = open(&sealed2, &pk2, &sk2).unwrap();

        assert_eq!(opened1, plaintext);
        assert_eq!(opened2, plaintext);

        // But not each other's
        assert!(open(&sealed1, &pk2, &sk2).is_err());
        assert!(open(&sealed2, &pk1, &sk1).is_err());
    }
}
