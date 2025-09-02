use crate::Result;
use base64::{Engine, engine::general_purpose::STANDARD as BASE64};
use libsodium_sys as sodium;
use std::sync::Once;

mod argon;
mod chacha;
mod kdf;
mod stream;

pub use argon::derive_argon_key;
pub use chacha::{
    decrypt_chacha, encrypt_chacha, sealed_box_open, secret_box_open, secret_box_seal,
};
pub use kdf::derive_login_key;
pub use stream::{StreamDecryptor, decrypt_file_data, decrypt_stream};

static INIT: Once = Once::new();

/// Initialize libsodium. Must be called before any crypto operations.
pub fn init() -> Result<()> {
    INIT.call_once(|| unsafe {
        if sodium::sodium_init() < 0 {
            panic!("Failed to initialize libsodium");
        }
    });
    Ok(())
}

/// Decode base64 string to bytes
pub fn decode_base64(input: &str) -> Result<Vec<u8>> {
    Ok(BASE64.decode(input)?)
}

/// Encode bytes to base64 string
pub fn encode_base64(input: &[u8]) -> String {
    BASE64.encode(input)
}
