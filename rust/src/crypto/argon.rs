use crate::{Error, Result};
use libsodium_sys as sodium;

/// Derive a key using Argon2id algorithm
/// This matches the Go implementation using libsodium
pub fn derive_argon_key(
    password: &str,
    salt: &str,
    mem_limit: u32,
    ops_limit: u32,
) -> Result<Vec<u8>> {
    if mem_limit < 1024 || ops_limit < 1 {
        return Err(Error::InvalidInput(
            "Invalid memory or operation limits".into(),
        ));
    }

    // Decode salt from base64
    let salt_bytes = super::decode_base64(salt)?;

    // libsodium requires salt to be exactly crypto_pwhash_SALTBYTES
    if salt_bytes.len() != sodium::crypto_pwhash_SALTBYTES as usize {
        return Err(Error::Crypto(format!(
            "Invalid salt length: expected {}, got {}",
            sodium::crypto_pwhash_SALTBYTES,
            salt_bytes.len()
        )));
    }

    let mut key = vec![0u8; 32]; // 32 bytes output

    let result = unsafe {
        sodium::crypto_pwhash(
            key.as_mut_ptr(),
            key.len() as u64,
            password.as_ptr() as *const std::ffi::c_char,
            password.len() as u64,
            salt_bytes.as_ptr(),
            ops_limit as u64,
            mem_limit as usize * 1024, // Convert from KB to bytes
            sodium::crypto_pwhash_ALG_ARGON2ID13 as i32,
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to derive key with Argon2id".into()));
    }

    Ok(key)
}
