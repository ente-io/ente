use crate::{Error, Result};
use libsodium_sys as sodium;

const LOGIN_SUB_KEY_LEN: usize = 32;
const LOGIN_SUB_KEY_ID: u64 = 1;
const LOGIN_SUB_KEY_CONTEXT: &[u8] = b"loginctx";

/// Derive login key from key encryption key
/// This matches the web implementation's deriveSRPLoginSubKey function
pub fn derive_login_key(key_enc_key: &[u8]) -> Result<Vec<u8>> {
    // Derive 32 bytes using crypto_kdf_derive_from_key
    let mut sub_key = vec![0u8; LOGIN_SUB_KEY_LEN];

    // Ensure context is exactly 8 bytes (crypto_kdf_CONTEXTBYTES)
    let mut context = [0u8; sodium::crypto_kdf_CONTEXTBYTES as usize];
    let context_len = LOGIN_SUB_KEY_CONTEXT.len().min(context.len());
    context[..context_len].copy_from_slice(&LOGIN_SUB_KEY_CONTEXT[..context_len]);

    let result = unsafe {
        sodium::crypto_kdf_derive_from_key(
            sub_key.as_mut_ptr(),
            LOGIN_SUB_KEY_LEN,
            LOGIN_SUB_KEY_ID,
            context.as_ptr() as *const std::ffi::c_char,
            key_enc_key.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to derive login subkey".into()));
    }

    // Return the first 16 bytes of the derived key (matching web implementation)
    Ok(sub_key[..16].to_vec())
}
