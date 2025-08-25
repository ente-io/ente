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

    let mut key = vec![0u8; sodium::crypto_secretbox_KEYBYTES as usize]; // 32 bytes output

    // Convert password to bytes (matching JS sodium.from_string)
    let password_bytes = password.as_bytes();

    let result = unsafe {
        sodium::crypto_pwhash(
            key.as_mut_ptr(),
            key.len() as u64,
            password_bytes.as_ptr() as *const std::ffi::c_char,
            password_bytes.len() as u64,
            salt_bytes.as_ptr(),
            ops_limit as u64,
            mem_limit as usize, // API sends bytes, libsodium-sys expects bytes
            sodium::crypto_pwhash_ALG_ARGON2ID13 as i32,
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to derive key with Argon2id".into()));
    }

    Ok(key)
}
