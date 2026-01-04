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
//! // Initialize crypto backend (must be called once)
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
//! let decrypted = crypto::blob::decrypt_blob(&encrypted, &key).unwrap();
//! assert_eq!(decrypted, plaintext);
//! ```

use base64::{Engine, engine::general_purpose::STANDARD as BASE64};

mod error;

// Pure Rust implementation
mod impl_pure;

// Re-export the pure Rust implementation
pub use impl_pure::*;

pub use error::{CryptoError, Result};

/// Decode a base64 string to bytes.
///
/// # Arguments
/// * `input` - Base64 encoded string.
///
/// # Returns
/// The decoded bytes.
pub fn decode_b64(input: &str) -> Result<Vec<u8>> {
    Ok(BASE64.decode(input)?)
}

/// Encode bytes to a base64 string.
///
/// # Arguments
/// * `input` - Bytes to encode.
///
/// # Returns
/// Base64 encoded string.
pub fn encode_b64(input: &[u8]) -> String {
    BASE64.encode(input)
}

/// Decode a hex string to bytes.
///
/// # Arguments
/// * `input` - Hex encoded string.
///
/// # Returns
/// The decoded bytes.
pub fn decode_hex(input: &str) -> Result<Vec<u8>> {
    Ok(hex::decode(input)?)
}

/// Encode bytes to a hex string.
///
/// # Arguments
/// * `input` - Bytes to encode.
///
/// # Returns
/// Hex encoded string (lowercase).
pub fn encode_hex(input: &[u8]) -> String {
    hex::encode(input)
}

/// Convert a base64 string to hex.
///
/// # Arguments
/// * `b64` - Base64 encoded string.
///
/// # Returns
/// Hex encoded string.
pub fn b64_to_hex(b64: &str) -> Result<String> {
    let bytes = decode_b64(b64)?;
    Ok(encode_hex(&bytes))
}

/// Convert a hex string to base64.
///
/// # Arguments
/// * `hex_str` - Hex encoded string.
///
/// # Returns
/// Base64 encoded string.
pub fn hex_to_b64(hex_str: &str) -> Result<String> {
    let bytes = decode_hex(hex_str)?;
    Ok(encode_b64(&bytes))
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

    #[test]
    fn test_base64_roundtrip() {
        let original = b"Hello, World!";
        let encoded = encode_b64(original);
        let decoded = decode_b64(&encoded).unwrap();
        assert_eq!(decoded, original);
    }

    #[test]
    fn test_hex_roundtrip() {
        let original = b"Hello, World!";
        let encoded = encode_hex(original);
        let decoded = decode_hex(&encoded).unwrap();
        assert_eq!(decoded, original);
    }

    #[test]
    fn test_b64_to_hex() {
        let original = b"Test";
        let b64 = encode_b64(original);
        let hex = b64_to_hex(&b64).unwrap();
        assert_eq!(hex, "54657374"); // "Test" in hex
    }

    #[test]
    fn test_hex_to_b64() {
        let hex = "54657374"; // "Test" in hex
        let b64 = hex_to_b64(hex).unwrap();
        let decoded = decode_b64(&b64).unwrap();
        assert_eq!(decoded, b"Test");
    }

    #[test]
    fn test_invalid_base64() {
        let result = decode_b64("not valid base64!!!");
        assert!(result.is_err());
    }

    #[test]
    fn test_invalid_hex() {
        let result = decode_hex("not valid hex!!!");
        assert!(result.is_err());
    }
}
