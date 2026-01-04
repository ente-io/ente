//! Argon2id password hashing and key derivation.
//!
//! This module provides password-based key derivation using Argon2id.

use argon2::{Algorithm, Argon2, Params, Version};

use crate::crypto::{CryptoError, Result};

/// Result of key derivation with password.
#[derive(Debug, Clone)]
pub struct DerivedKeyResult {
    /// The derived key.
    pub key: Vec<u8>,
    /// The salt used for derivation.
    pub salt: Vec<u8>,
    /// Memory limit used.
    pub mem_limit: u32,
    /// Operations limit used.
    pub ops_limit: u32,
}

/// Memory limit for interactive operations (64 MiB).
pub const MEMLIMIT_INTERACTIVE: u32 = 67_108_864;

/// Memory limit for moderate operations (256 MiB).
pub const MEMLIMIT_MODERATE: u32 = 268_435_456;

/// Memory limit for sensitive operations (1 GiB).
pub const MEMLIMIT_SENSITIVE: u32 = 1_073_741_824;

/// Minimum memory limit.
pub const MEMLIMIT_MIN: u32 = 8_192;

/// Operations limit for interactive use.
pub const OPSLIMIT_INTERACTIVE: u32 = 2;

/// Operations limit for moderate use.
pub const OPSLIMIT_MODERATE: u32 = 3;

/// Operations limit for sensitive use.
pub const OPSLIMIT_SENSITIVE: u32 = 4;

/// Minimum operations limit.
pub const OPSLIMIT_MIN: u32 = 1;

/// Maximum operations limit.
pub const OPSLIMIT_MAX: u32 = u32::MAX;

/// Size of salt in bytes.
pub const SALT_BYTES: usize = 16;

/// Size of derived key in bytes.
pub const KEY_BYTES: usize = 32;

/// Derive a key from a password using Argon2id.
///
/// # Arguments
/// * `password` - Password string (UTF-8).
/// * `salt` - 16-byte salt.
/// * `mem_limit` - Memory limit in bytes.
/// * `ops_limit` - Operations/iterations limit.
///
/// # Returns
/// 32-byte derived key.
pub fn derive_key(password: &str, salt: &[u8], mem_limit: u32, ops_limit: u32) -> Result<Vec<u8>> {
    if salt.len() != SALT_BYTES {
        return Err(CryptoError::InvalidSaltLength {
            expected: SALT_BYTES,
            actual: salt.len(),
        });
    }

    if mem_limit < MEMLIMIT_MIN {
        return Err(CryptoError::InvalidKeyDerivationParams(format!(
            "Memory limit {} is below minimum {}",
            mem_limit, MEMLIMIT_MIN
        )));
    }

    if ops_limit < OPSLIMIT_MIN {
        return Err(CryptoError::InvalidKeyDerivationParams(format!(
            "Operations limit {} is below minimum {}",
            ops_limit, OPSLIMIT_MIN
        )));
    }

    // Convert bytes to KiB (Argon2 uses KiB internally)
    let m_cost = mem_limit / 1024;
    let t_cost = ops_limit;
    let p_cost = 1; // Parallelism degree

    let params = Params::new(m_cost, t_cost, p_cost, Some(KEY_BYTES))
        .map_err(|e| CryptoError::InvalidKeyDerivationParams(e.to_string()))?;

    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, params);

    let mut key = vec![0u8; KEY_BYTES];
    argon2
        .hash_password_into(password.as_bytes(), salt, &mut key)
        .map_err(CryptoError::Argon2)?;

    Ok(key)
}

/// Derive a key with interactive parameters (fast, for UI responsiveness).
///
/// Uses OPSLIMIT_INTERACTIVE and MEMLIMIT_INTERACTIVE.
/// Generates a random salt if none is provided.
///
/// # Arguments
/// * `password` - Password string.
///
/// # Returns
/// DerivedKeyResult containing the key, salt, and parameters used.
pub fn derive_interactive_key(password: &str) -> Result<DerivedKeyResult> {
    let salt = super::keys::generate_salt();
    let key = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE)?;
    Ok(DerivedKeyResult {
        key,
        salt,
        mem_limit: MEMLIMIT_INTERACTIVE,
        ops_limit: OPSLIMIT_INTERACTIVE,
    })
}

/// Derive a key with interactive parameters using provided salt.
///
/// # Arguments
/// * `password` - Password string.
/// * `salt` - 16-byte salt.
///
/// # Returns
/// 32-byte derived key.
pub fn derive_interactive_key_with_salt(password: &str, salt: &[u8]) -> Result<Vec<u8>> {
    derive_key(password, salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE)
}

/// Derive a key with moderate parameters (balanced security/performance).
///
/// Uses OPSLIMIT_MODERATE and MEMLIMIT_MODERATE.
///
/// # Arguments
/// * `password` - Password string.
/// * `salt` - 16-byte salt.
///
/// # Returns
/// 32-byte derived key.
pub fn derive_moderate_key(password: &str, salt: &[u8]) -> Result<Vec<u8>> {
    derive_key(password, salt, MEMLIMIT_MODERATE, OPSLIMIT_MODERATE)
}

/// Derive a key with sensitive parameters (maximum security).
///
/// Uses OPSLIMIT_SENSITIVE and MEMLIMIT_SENSITIVE.
///
/// # Arguments
/// * `password` - Password string.
///
/// # Returns
/// DerivedKeyResult containing the key, salt, and parameters used.
pub fn derive_sensitive_key(password: &str) -> Result<DerivedKeyResult> {
    let salt = super::keys::generate_salt();
    let key = derive_key(password, &salt, MEMLIMIT_SENSITIVE, OPSLIMIT_SENSITIVE)?;
    Ok(DerivedKeyResult {
        key,
        salt,
        mem_limit: MEMLIMIT_SENSITIVE,
        ops_limit: OPSLIMIT_SENSITIVE,
    })
}

/// Derive a key with sensitive parameters using provided salt.
///
/// # Arguments
/// * `password` - Password string.
/// * `salt` - 16-byte salt.
///
/// # Returns
/// 32-byte derived key.
pub fn derive_sensitive_key_with_salt(password: &str, salt: &[u8]) -> Result<Vec<u8>> {
    derive_key(password, salt, MEMLIMIT_SENSITIVE, OPSLIMIT_SENSITIVE)
}

/// Derive a key from a password with base64-encoded salt.
///
/// # Arguments
/// * `password` - Password string.
/// * `salt_b64` - Base64-encoded salt.
/// * `mem_limit` - Memory limit in bytes.
/// * `ops_limit` - Operations/iterations limit.
///
/// # Returns
/// 32-byte derived key.
pub fn derive_key_from_b64_salt(
    password: &str,
    salt_b64: &str,
    mem_limit: u32,
    ops_limit: u32,
) -> Result<Vec<u8>> {
    let salt = crate::crypto::decode_b64(salt_b64)?;
    derive_key(password, &salt, mem_limit, ops_limit)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto::impl_pure::keys;

    #[test]
    fn test_derive_key() {
        let password = "correct horse battery staple";
        let salt = keys::generate_salt();

        let key = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();
        assert_eq!(key.len(), KEY_BYTES);
    }

    #[test]
    fn test_derive_key_deterministic() {
        let password = "test password";
        let salt = vec![0x42u8; SALT_BYTES];

        let key1 = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();
        let key2 = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();

        assert_eq!(key1, key2);
    }

    #[test]
    fn test_different_passwords() {
        let salt = vec![0x42u8; SALT_BYTES];

        let key1 = derive_key(
            "password1",
            &salt,
            MEMLIMIT_INTERACTIVE,
            OPSLIMIT_INTERACTIVE,
        )
        .unwrap();
        let key2 = derive_key(
            "password2",
            &salt,
            MEMLIMIT_INTERACTIVE,
            OPSLIMIT_INTERACTIVE,
        )
        .unwrap();

        assert_ne!(key1, key2);
    }

    #[test]
    fn test_different_salts() {
        let password = "same password";
        let salt1 = vec![0x42u8; SALT_BYTES];
        let salt2 = vec![0x43u8; SALT_BYTES];

        let key1 =
            derive_key(password, &salt1, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();
        let key2 =
            derive_key(password, &salt2, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();

        assert_ne!(key1, key2);
    }

    #[test]
    fn test_different_mem_limits() {
        let password = "test";
        let salt = vec![0x42u8; SALT_BYTES];

        let key1 = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();
        let key2 = derive_key(password, &salt, MEMLIMIT_MODERATE, OPSLIMIT_INTERACTIVE).unwrap();

        assert_ne!(key1, key2);
    }

    #[test]
    fn test_different_ops_limits() {
        let password = "test";
        let salt = vec![0x42u8; SALT_BYTES];

        let key1 = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_INTERACTIVE).unwrap();
        let key2 = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, OPSLIMIT_MODERATE).unwrap();

        assert_ne!(key1, key2);
    }

    #[test]
    fn test_derive_interactive_key() {
        let password = "interactive test";

        let result = derive_interactive_key(password).unwrap();
        assert_eq!(result.key.len(), KEY_BYTES);
        assert_eq!(result.salt.len(), SALT_BYTES);
        assert_eq!(result.mem_limit, MEMLIMIT_INTERACTIVE);
        assert_eq!(result.ops_limit, OPSLIMIT_INTERACTIVE);
    }

    #[test]
    fn test_derive_moderate_key() {
        let password = "moderate test";
        let salt = keys::generate_salt();

        let key = derive_moderate_key(password, &salt).unwrap();
        assert_eq!(key.len(), KEY_BYTES);
    }

    #[test]
    #[ignore] // Slow: uses 1GB memory
    fn test_derive_sensitive_key() {
        let password = "sensitive test";

        let result = derive_sensitive_key(password).unwrap();
        assert_eq!(result.key.len(), KEY_BYTES);
        assert_eq!(result.salt.len(), SALT_BYTES);
        assert_eq!(result.mem_limit, MEMLIMIT_SENSITIVE);
        assert_eq!(result.ops_limit, OPSLIMIT_SENSITIVE);
    }

    #[test]
    fn test_invalid_salt_length() {
        let password = "test";
        let bad_salt = vec![0u8; 8]; // Wrong size

        let result = derive_interactive_key_with_salt(password, &bad_salt);
        assert!(matches!(result, Err(CryptoError::InvalidSaltLength { .. })));
    }

    #[test]
    fn test_memlimit_too_low() {
        let password = "test";
        let salt = keys::generate_salt();

        let result = derive_key(password, &salt, 4096, OPSLIMIT_INTERACTIVE);
        assert!(result.is_err());
    }

    #[test]
    fn test_opslimit_zero() {
        let password = "test";
        let salt = keys::generate_salt();

        let result = derive_key(password, &salt, MEMLIMIT_INTERACTIVE, 0);
        assert!(result.is_err());
    }

    #[test]
    fn test_empty_password() {
        let password = "";
        let salt = keys::generate_salt();

        let key = derive_interactive_key_with_salt(password, &salt).unwrap();
        assert_eq!(key.len(), KEY_BYTES);
    }

    #[test]
    fn test_long_password() {
        let password = "a".repeat(1000);
        let salt = keys::generate_salt();

        let key = derive_interactive_key_with_salt(&password, &salt).unwrap();
        assert_eq!(key.len(), KEY_BYTES);
    }

    #[test]
    fn test_unicode_password() {
        let password = "пароль 密码 🔐";
        let salt = keys::generate_salt();

        let key = derive_interactive_key_with_salt(password, &salt).unwrap();
        assert_eq!(key.len(), KEY_BYTES);
    }

    #[test]
    #[ignore] // Slow: uses 1GB memory
    fn test_presets_produce_different_keys() {
        let password = "test password";
        let salt = vec![0x42u8; SALT_BYTES];

        let interactive = derive_interactive_key_with_salt(password, &salt).unwrap();
        let moderate = derive_moderate_key(password, &salt).unwrap();
        let sensitive = derive_sensitive_key_with_salt(password, &salt).unwrap();

        // All should be different
        assert_ne!(interactive, moderate);
        assert_ne!(moderate, sensitive);
        assert_ne!(interactive, sensitive);
    }
}
