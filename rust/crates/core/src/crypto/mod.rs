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
//! - [`Key::generate`] - Generate a 256-bit symmetric key
//! - [`SecretKey::generate`] - Generate an X25519 secret key (public key via
//!   [`SecretKey::public_key`])
//! - [`Salt::generate`] - Generate a salt for key derivation
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
//! // Generate a key and encrypt some data
//! let key = crypto::Key::generate();
//! let plaintext = b"Hello, World!";
//!
//! // SecretBox encryption (for independent data)
//! let encrypted = crypto::secretbox::encrypt(plaintext, &key);
//! let decrypted = encrypted.decrypt(&key).unwrap();
//! assert_eq!(decrypted, plaintext);
//!
//! // Blob encryption (for metadata)
//! let encrypted = crypto::blob::encrypt(plaintext, &key).unwrap();
//! let decrypted = encrypted.decrypt(&key).unwrap();
//! assert_eq!(decrypted, plaintext);
//! ```

mod encoding;
mod error;
mod secret;
mod types;

pub mod argon;
pub mod blob;
pub mod hash;
pub mod kdf;
pub mod sealed;
pub mod secretbox;
pub mod stream;

pub use encoding::{
    b64_to_hex, base642bin, decode_b64, decode_b64_url_safe_no_padding, decode_hex, encode_b64,
    encode_b64_url_safe, encode_b64_url_safe_no_padding, encode_hex, hex_to_b64, str_to_bin,
};
pub use error::{CryptoError, Result};
pub use secret::{SecretString, SecretVec};
pub use types::{Header, Key, Nonce, PublicKey, Salt, SecretKey, random_bytes};
