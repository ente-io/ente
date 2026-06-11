//! Cryptographic utilities for Ente.
//!
//! This module provides all the cryptographic primitives used by Ente clients.
//!
//! # Implementation
//!
//! This crate uses **pure Rust** cryptographic implementations from the RustCrypto project.
//! All implementations maintain byte-for-byte wire format compatibility with libsodium
//! for interoperability with existing clients (mobile/web).
//!
//! # Overview
//!
//! ## Key Generation
//! - [`keys::generate_key`] - Generate a 256-bit key for SecretBox encryption
//! - [`keys::generate_stream_key`] - Generate a key for SecretStream encryption
//! - [`keys::generate_keypair`] - Generate a public/private key pair
//! - [`keys::generate_salt`] - Generate a salt for key derivation
//!
//! ## Key Derivation
//! - [`argon::derive_key`] - Derive a key from password using Argon2id
//! - [`argon::derive_sensitive_key`] - Derive with secure parameters
//! - [`kdf::derive_subkey`] - Derive a subkey from a master key
//! - [`kdf::derive_login_key`] - Derive login key for SRP authentication
//!
//! ## Symmetric Encryption
//! - [`secretbox`] - SecretBox (XSalsa20-Poly1305) for independent data
//! - [`blob`] - SecretStream without chunking for metadata
//! - [`stream`] - Chunked SecretStream for large files
//!
//! ## Asymmetric Encryption
//! - [`sealed`] - Sealed box for anonymous public-key encryption
//!
//! ## Hashing
//! - [`hash`] - BLAKE2b hashing
//!
//! # Example
//!
//! ```rust
//! use ente_core::crypto;
//!
//! // Initialize crypto backend (no-op for the pure Rust backend)
//! crypto::init().unwrap();
//!
//! // Generate a key and encrypt some data
//! let key = crypto::keys::generate_key();
//! let plaintext = b"Hello, World!";
//!
//! // SecretBox encryption (for independent data)
//! let encrypted = crypto::secretbox::encrypt(plaintext, &key).unwrap();
//! let decrypted = crypto::secretbox::decrypt_box(&encrypted, &key).unwrap();
//! assert_eq!(decrypted, plaintext);
//!
//! // Blob encryption (for metadata)
//! let key = crypto::keys::generate_stream_key();
//! let encrypted = crypto::blob::encrypt(plaintext, &key).unwrap();
//! let decrypted = crypto::blob::decrypt(&encrypted.encrypted_data, &encrypted.decryption_header, &key).unwrap();
//! assert_eq!(decrypted, plaintext);
//! ```

use std::sync::Once;

mod encoding;
mod error;
mod secret;

pub mod argon;
pub mod blob;
pub mod hash;
pub mod kdf;
pub mod keys;
pub mod sealed;
pub mod secretbox;
pub mod stream;

pub use encoding::{
    b64_to_hex, base642bin, bin2base64, decode_b64, decode_hex, encode_b64, encode_hex, hex_to_b64,
    str_to_bin,
};
pub use error::{CryptoError, Result};
pub use secret::{SecretString, SecretVec};

static INIT: Once = Once::new();

/// Initialize crypto backend. For the pure Rust implementation, this is a no-op.
///
/// This function is provided for API compatibility with the libsodium backend.
pub fn init() -> Result<()> {
    INIT.call_once(|| {
        // Pure Rust implementation doesn't require initialization
    });
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init() {
        // Should not panic
        init().unwrap();
        // Safe to call multiple times
        init().unwrap();
    }
}
