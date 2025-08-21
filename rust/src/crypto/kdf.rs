use crate::{Error, Result};
use libsodium_sys as sodium;

const LOGIN_SUB_KEY_LEN: usize = 32;
const LOGIN_SUB_KEY_ID: u64 = 1;
const LOGIN_SUB_KEY_CONTEXT: &[u8] = b"loginctx";

/// Derive login key from key encryption key
/// This matches the Go implementation's DeriveLoginKey function
pub fn derive_login_key(key_enc_key: &[u8]) -> Result<Vec<u8>> {
    let sub_key = derive_sub_key(
        key_enc_key,
        LOGIN_SUB_KEY_CONTEXT,
        LOGIN_SUB_KEY_ID,
        LOGIN_SUB_KEY_LEN,
    )?;
    
    // Return the first 16 bytes of the derived key
    Ok(sub_key[..16].to_vec())
}

/// Derive a subkey using Blake2b (matching Go's deriveSubKey)
fn derive_sub_key(
    master_key: &[u8],
    context: &[u8],
    sub_key_id: u64,
    sub_key_length: usize,
) -> Result<Vec<u8>> {
    const CRYPTO_KDF_BLAKE2B_BYTES_MIN: usize = 16;
    const CRYPTO_KDF_BLAKE2B_BYTES_MAX: usize = 64;
    
    if sub_key_length < CRYPTO_KDF_BLAKE2B_BYTES_MIN || sub_key_length > CRYPTO_KDF_BLAKE2B_BYTES_MAX {
        return Err(Error::Crypto("subKeyLength out of bounds".into()));
    }

    // Pad the context to 16 bytes (PERSONALBYTES)
    let mut ctx_padded = vec![0u8; sodium::crypto_generichash_blake2b_PERSONALBYTES as usize];
    let context_len = context.len().min(ctx_padded.len());
    ctx_padded[..context_len].copy_from_slice(&context[..context_len]);

    // Convert subKeyID to byte slice and pad to 16 bytes (SALTBYTES)
    let mut salt = vec![0u8; sodium::crypto_generichash_blake2b_SALTBYTES as usize];
    salt[..8].copy_from_slice(&sub_key_id.to_le_bytes());

    // Create output buffer
    let mut out = vec![0u8; sub_key_length];

    // Initialize Blake2b state with salt and personalization
    let mut state = std::mem::MaybeUninit::<sodium::crypto_generichash_blake2b_state>::uninit();
    
    let result = unsafe {
        sodium::crypto_generichash_blake2b_salt_personal(
            out.as_mut_ptr(),
            sub_key_length,
            std::ptr::null(),  // No input data, just using key, salt, and personalization
            0,
            master_key.as_ptr(),
            master_key.len(),
            salt.as_ptr(),
            ctx_padded.as_ptr(),
        )
    };

    if result != 0 {
        return Err(Error::Crypto("Failed to derive subkey with Blake2b".into()));
    }

    Ok(out)
}