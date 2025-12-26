//! Key derivation functions using BLAKE2b.
//!
//! This module provides key derivation using BLAKE2b with salt and personalization.
//! Maintains compatibility with libsodium's crypto_kdf_derive_from_key.

use blake2b_simd::Params as Blake2bParams;

use crate::crypto::Result;

/// Size of KDF context in bytes.
pub const CONTEXT_BYTES: usize = 8;

/// Size of master key in bytes.
pub const KEY_BYTES: usize = 32;

/// Minimum subkey length in bytes.
pub const SUBKEY_BYTES_MIN: usize = 16;

/// Maximum subkey length in bytes.
pub const SUBKEY_BYTES_MAX: usize = 64;

/// Login subkey length in bytes (used by derive_login_key).
pub const LOGIN_SUBKEY_LEN: usize = 32;

/// Login subkey ID (used by derive_login_key).
pub const LOGIN_SUBKEY_ID: u64 = 1;

/// Login subkey context (used by derive_login_key).
pub const LOGIN_SUBKEY_CONTEXT: &[u8] = b"loginctx";

/// Derive a subkey from a master key.
///
/// # Wire Format
/// - salt = subkey_id (8 bytes LE) || zeros (8 bytes)
/// - personal = context (up to 8 bytes, zero-padded) || zeros (8 bytes)
///
/// # Arguments
/// * `key` - Master key.
/// * `subkey_len` - Length of the derived subkey (16-64 bytes).
/// * `subkey_id` - Subkey identifier (used as salt).
/// * `context` - Context string (up to 8 bytes, will be truncated/padded).
///
/// # Returns
/// Derived subkey of the specified length.
pub fn derive_subkey(
    key: &[u8],
    subkey_len: usize,
    subkey_id: u64,
    context: &[u8],
) -> Result<Vec<u8>> {
    if !(SUBKEY_BYTES_MIN..=SUBKEY_BYTES_MAX).contains(&subkey_len) {
        return Err(crate::crypto::CryptoError::InvalidKeyLength {
            expected: SUBKEY_BYTES_MAX,
            actual: subkey_len,
        });
    }

    // Build salt: subkey_id (8 bytes LE) || zeros (8 bytes)
    let mut salt = [0u8; 16];
    salt[0..8].copy_from_slice(&subkey_id.to_le_bytes());

    // Build personal: context (truncate/pad to 8 bytes) || zeros (8 bytes)
    let mut personal = [0u8; 16];
    let ctx_len = context.len().min(CONTEXT_BYTES);
    personal[0..ctx_len].copy_from_slice(&context[..ctx_len]);

    let hash = Blake2bParams::new()
        .hash_length(subkey_len)
        .key(key)
        .salt(&salt)
        .personal(&personal)
        .to_state()
        .finalize();

    Ok(hash.as_bytes()[..subkey_len].to_vec())
}

/// Derive a login key from a master key.
///
/// This is a specialized wrapper around `derive_subkey` used for SRP authentication.
/// Returns the first 16 bytes of a 32-byte subkey derived with context "loginctx" and ID 1.
///
/// # Arguments
/// * `master_key` - Master key to derive from (must be exactly 32 bytes).
///
/// # Returns
/// 16-byte login key.
pub fn derive_login_key(master_key: &[u8]) -> Result<Vec<u8>> {
    if master_key.len() != 32 {
        return Err(crate::crypto::CryptoError::InvalidKeyLength {
            expected: 32,
            actual: master_key.len(),
        });
    }

    let subkey = derive_subkey(master_key, 32, 1, b"loginctx")?;
    Ok(subkey[..16].to_vec())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_derive_subkey() {
        let master_key = vec![0x42u8; 32];
        let subkey = derive_subkey(&master_key, 32, 1, b"test").unwrap();

        assert_eq!(subkey.len(), 32);
    }

    #[test]
    fn test_derive_subkey_deterministic() {
        let master_key = vec![0x42u8; 32];

        let subkey1 = derive_subkey(&master_key, 32, 1, b"context").unwrap();
        let subkey2 = derive_subkey(&master_key, 32, 1, b"context").unwrap();

        assert_eq!(subkey1, subkey2);
    }

    #[test]
    fn test_different_subkey_ids() {
        let master_key = vec![0x42u8; 32];

        let subkey1 = derive_subkey(&master_key, 32, 1, b"context").unwrap();
        let subkey2 = derive_subkey(&master_key, 32, 2, b"context").unwrap();

        assert_ne!(subkey1, subkey2);
    }

    #[test]
    fn test_different_contexts() {
        let master_key = vec![0x42u8; 32];

        let subkey1 = derive_subkey(&master_key, 32, 1, b"context1").unwrap();
        let subkey2 = derive_subkey(&master_key, 32, 1, b"context2").unwrap();

        assert_ne!(subkey1, subkey2);
    }

    #[test]
    fn test_different_master_keys() {
        let key1 = vec![0x42u8; 32];
        let key2 = vec![0x43u8; 32];

        let subkey1 = derive_subkey(&key1, 32, 1, b"context").unwrap();
        let subkey2 = derive_subkey(&key2, 32, 1, b"context").unwrap();

        assert_ne!(subkey1, subkey2);
    }

    #[test]
    fn test_different_lengths() {
        let master_key = vec![0x42u8; 32];

        // Test various subkey lengths
        for &len in &[16, 24, 32, 48, 64] {
            let subkey = derive_subkey(&master_key, len, 1, b"test").unwrap();
            assert_eq!(subkey.len(), len);
        }
    }

    #[test]
    fn test_context_truncation() {
        let master_key = vec![0x42u8; 32];

        // Context longer than 8 bytes should be truncated
        let long_context = b"verylongcontext";
        let subkey1 = derive_subkey(&master_key, 32, 1, long_context).unwrap();

        // First 8 bytes should matter
        let short_context = b"verylong";
        let subkey2 = derive_subkey(&master_key, 32, 1, short_context).unwrap();

        assert_eq!(subkey1, subkey2);
    }

    #[test]
    fn test_context_padding() {
        let master_key = vec![0x42u8; 32];

        // Short contexts should be zero-padded
        let subkey1 = derive_subkey(&master_key, 32, 1, b"abc").unwrap();
        let subkey2 = derive_subkey(&master_key, 32, 1, b"abc").unwrap();

        assert_eq!(subkey1, subkey2);
    }

    #[test]
    fn test_empty_context() {
        let master_key = vec![0x42u8; 32];
        let subkey = derive_subkey(&master_key, 32, 1, b"").unwrap();

        assert_eq!(subkey.len(), 32);
    }

    #[test]
    fn test_derive_login_key() {
        let master_key = vec![0x42u8; 32];
        let login_key = derive_login_key(&master_key).unwrap();

        assert_eq!(login_key.len(), 16);
    }

    #[test]
    fn test_derive_login_key_deterministic() {
        let master_key = vec![0x42u8; 32];

        let key1 = derive_login_key(&master_key).unwrap();
        let key2 = derive_login_key(&master_key).unwrap();

        assert_eq!(key1, key2);
    }

    #[test]
    fn test_login_key_is_subkey() {
        let master_key = vec![0x42u8; 32];

        let login_key = derive_login_key(&master_key).unwrap();
        let subkey = derive_subkey(&master_key, 32, 1, b"loginctx").unwrap();

        // Login key should be first 16 bytes of subkey
        assert_eq!(login_key, &subkey[..16]);
    }

    #[test]
    fn test_invalid_subkey_length_too_small() {
        let master_key = vec![0x42u8; 32];
        let result = derive_subkey(&master_key, 8, 1, b"test");

        assert!(result.is_err());
    }

    #[test]
    fn test_invalid_subkey_length_too_large() {
        let master_key = vec![0x42u8; 32];
        let result = derive_subkey(&master_key, 128, 1, b"test");

        assert!(result.is_err());
    }
}
