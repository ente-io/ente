//! Pure Rust cryptographic implementation.
//!
//! This module provides cryptographic operations using pure Rust crates from RustCrypto.
//! All operations maintain byte-for-byte compatibility with the libsodium implementation.

use std::sync::Once;

pub mod argon;
pub mod blob;
pub mod hash;
pub mod kdf;
pub mod keys;
pub mod sealed;
pub mod secretbox;
pub mod stream;

static INIT: Once = Once::new();

/// Initialize crypto backend. For pure Rust implementation, this is a no-op.
///
/// This function is provided for API compatibility with the libsodium backend.
pub fn init() -> crate::crypto::Result<()> {
    INIT.call_once(|| {
        // Pure Rust implementation doesn't require initialization
    });
    Ok(())
}
