//! Key generation for new account sign-up.

use crate::crypto::{self, argon, kdf, keys, secretbox};

use super::{KeyAttributes, KeyGenResult, PrivateKeyAttributes, Result};

/// Key derivation strength for password-based key generation.
#[derive(Debug, Clone, Copy, Default)]
pub enum KeyDerivationStrength {
    /// Fast derivation (64MB, 2 ops) - for testing only
    Interactive,
    /// Strong derivation (1GB, 4 ops) - for production
    #[default]
    Sensitive,
}

/// Encrypt data and return (encrypted_data, nonce) as base64 strings.
/// The encrypted_data is MAC || ciphertext format (compatible with Dart).
fn encrypt_to_b64(plaintext: &[u8], key: &[u8]) -> Result<(String, String)> {
    let nonce = keys::generate_secretbox_nonce();
    let encrypted = secretbox::encrypt_with_nonce(plaintext, &nonce, key)?;
    Ok((crypto::encode_b64(&encrypted), crypto::encode_b64(&nonce)))
}

/// Generate all keys needed for a new account.
///
/// Uses sensitive (slow, secure) key derivation by default.
/// For tests, use `generate_keys_with_strength` with `Interactive`.
pub fn generate_keys(password: &str) -> Result<KeyGenResult> {
    generate_keys_with_strength(password, KeyDerivationStrength::Sensitive)
}

/// Generate all keys with specified derivation strength.
pub fn generate_keys_with_strength(
    password: &str,
    strength: KeyDerivationStrength,
) -> Result<KeyGenResult> {
    // Create master key and recovery key
    let master_key = keys::generate_key();
    let recovery_key = keys::generate_key();

    // Encrypt master key with recovery key and vice versa
    let (enc_master_with_recovery, nonce_master_recovery) =
        encrypt_to_b64(&master_key, &recovery_key)?;
    let (enc_recovery_with_master, nonce_recovery_master) =
        encrypt_to_b64(&recovery_key, &master_key)?;

    // Derive key-encryption-key from password
    let derived = match strength {
        KeyDerivationStrength::Interactive => argon::derive_interactive_key(password)?,
        KeyDerivationStrength::Sensitive => argon::derive_sensitive_key(password)?,
    };
    let login_key = kdf::derive_login_key(&derived.key)?;

    // Encrypt master key with derived key
    let (enc_key, key_nonce) = encrypt_to_b64(&master_key, &derived.key)?;

    // Generate X25519 keypair
    let (public_key, secret_key) = keys::generate_keypair()?;

    // Encrypt secret key with master key
    let (enc_secret_key, secret_key_nonce) = encrypt_to_b64(&secret_key, &master_key)?;

    // Build key attributes for server
    let key_attributes = KeyAttributes {
        kek_salt: crypto::encode_b64(&derived.salt),
        encrypted_key: enc_key,
        key_decryption_nonce: key_nonce,
        public_key: crypto::encode_b64(&public_key),
        encrypted_secret_key: enc_secret_key,
        secret_key_decryption_nonce: secret_key_nonce,
        mem_limit: Some(derived.mem_limit),
        ops_limit: Some(derived.ops_limit),
        master_key_encrypted_with_recovery_key: Some(enc_master_with_recovery),
        master_key_decryption_nonce: Some(nonce_master_recovery),
        recovery_key_encrypted_with_master_key: Some(enc_recovery_with_master),
        recovery_key_decryption_nonce: Some(nonce_recovery_master),
    };

    // Build private key attributes for local storage
    let private_key_attributes = PrivateKeyAttributes {
        key: crypto::encode_b64(&master_key),
        recovery_key: crypto::encode_hex(&recovery_key),
        secret_key: crypto::encode_b64(&secret_key),
    };

    Ok(KeyGenResult {
        key_attributes,
        private_key_attributes,
        login_key,
    })
}

/// Generate new key attributes when user changes password.
pub fn generate_key_attributes_for_new_password(
    master_key: &[u8],
    password: &str,
) -> Result<(KeyAttributes, Vec<u8>)> {
    generate_key_attributes_for_new_password_with_strength(
        master_key,
        password,
        KeyDerivationStrength::Sensitive,
    )
}

/// Generate new key attributes with specified derivation strength.
pub fn generate_key_attributes_for_new_password_with_strength(
    master_key: &[u8],
    password: &str,
    strength: KeyDerivationStrength,
) -> Result<(KeyAttributes, Vec<u8>)> {
    // Derive new KEK from new password
    let derived = match strength {
        KeyDerivationStrength::Interactive => argon::derive_interactive_key(password)?,
        KeyDerivationStrength::Sensitive => argon::derive_sensitive_key(password)?,
    };
    let login_key = kdf::derive_login_key(&derived.key)?;

    // Encrypt master key with new derived key
    let (enc_key, key_nonce) = encrypt_to_b64(master_key, &derived.key)?;

    let key_attributes = KeyAttributes {
        kek_salt: crypto::encode_b64(&derived.salt),
        encrypted_key: enc_key,
        key_decryption_nonce: key_nonce,
        mem_limit: Some(derived.mem_limit),
        ops_limit: Some(derived.ops_limit),
        // These fields need to be filled from existing attributes
        public_key: String::new(),
        encrypted_secret_key: String::new(),
        secret_key_decryption_nonce: String::new(),
        master_key_encrypted_with_recovery_key: None,
        master_key_decryption_nonce: None,
        recovery_key_encrypted_with_master_key: None,
        recovery_key_decryption_nonce: None,
    };

    Ok((key_attributes, login_key))
}

/// Create a new recovery key for an existing account.
pub fn create_new_recovery_key(
    master_key: &[u8],
) -> Result<(String, String, String, String, String)> {
    let recovery_key = keys::generate_key();

    let (enc_master, nonce_master) = encrypt_to_b64(master_key, &recovery_key)?;
    let (enc_recovery, nonce_recovery) = encrypt_to_b64(&recovery_key, master_key)?;

    Ok((
        crypto::encode_hex(&recovery_key),
        enc_master,
        nonce_master,
        enc_recovery,
        nonce_recovery,
    ))
}

#[cfg(test)]
mod tests {
    use super::*;

    // Use Interactive strength for fast tests
    fn generate_test_keys(password: &str) -> Result<KeyGenResult> {
        generate_keys_with_strength(password, KeyDerivationStrength::Interactive)
    }

    #[test]
    fn test_generate_keys() {
        crypto::init().unwrap();

        let result = generate_test_keys("test_password_123").unwrap();

        assert!(!result.key_attributes.kek_salt.is_empty());
        assert!(!result.key_attributes.encrypted_key.is_empty());
        assert!(!result.key_attributes.public_key.is_empty());
        assert!(!result.private_key_attributes.key.is_empty());
        assert!(!result.private_key_attributes.recovery_key.is_empty());
        assert_eq!(result.login_key.len(), 16);

        let master_key = crypto::decode_b64(&result.private_key_attributes.key).unwrap();
        assert_eq!(master_key.len(), 32);
        assert_eq!(result.private_key_attributes.recovery_key.len(), 64);
    }

    #[test]
    fn test_generate_keys_can_decrypt_master_key() {
        crypto::init().unwrap();

        let password = "my_secure_password";
        let result = generate_test_keys(password).unwrap();

        let kek_salt = crypto::decode_b64(&result.key_attributes.kek_salt).unwrap();
        let kek = argon::derive_key(
            password,
            &kek_salt,
            result.key_attributes.mem_limit.unwrap(),
            result.key_attributes.ops_limit.unwrap(),
        )
        .unwrap();

        let encrypted_key = crypto::decode_b64(&result.key_attributes.encrypted_key).unwrap();
        let nonce = crypto::decode_b64(&result.key_attributes.key_decryption_nonce).unwrap();
        let decrypted_master = secretbox::decrypt(&encrypted_key, &nonce, &kek).unwrap();

        let original_master = crypto::decode_b64(&result.private_key_attributes.key).unwrap();
        assert_eq!(decrypted_master, original_master);
    }

    #[test]
    fn test_generate_keys_can_decrypt_secret_key() {
        crypto::init().unwrap();

        let result = generate_test_keys("password").unwrap();
        let master_key = crypto::decode_b64(&result.private_key_attributes.key).unwrap();

        let encrypted = crypto::decode_b64(&result.key_attributes.encrypted_secret_key).unwrap();
        let nonce = crypto::decode_b64(&result.key_attributes.secret_key_decryption_nonce).unwrap();
        let decrypted = secretbox::decrypt(&encrypted, &nonce, &master_key).unwrap();

        let original = crypto::decode_b64(&result.private_key_attributes.secret_key).unwrap();
        assert_eq!(decrypted, original);
    }

    #[test]
    fn test_generate_keys_recovery_key_can_decrypt_master() {
        crypto::init().unwrap();

        let result = generate_test_keys("password").unwrap();
        let recovery_key = crypto::decode_hex(&result.private_key_attributes.recovery_key).unwrap();

        let encrypted = crypto::decode_b64(
            result
                .key_attributes
                .master_key_encrypted_with_recovery_key
                .as_ref()
                .unwrap(),
        )
        .unwrap();
        let nonce = crypto::decode_b64(
            result
                .key_attributes
                .master_key_decryption_nonce
                .as_ref()
                .unwrap(),
        )
        .unwrap();
        let decrypted = secretbox::decrypt(&encrypted, &nonce, &recovery_key).unwrap();

        let original = crypto::decode_b64(&result.private_key_attributes.key).unwrap();
        assert_eq!(decrypted, original);
    }

    #[test]
    fn test_generate_keys_master_can_decrypt_recovery() {
        crypto::init().unwrap();

        let result = generate_test_keys("password").unwrap();
        let master_key = crypto::decode_b64(&result.private_key_attributes.key).unwrap();

        let encrypted = crypto::decode_b64(
            result
                .key_attributes
                .recovery_key_encrypted_with_master_key
                .as_ref()
                .unwrap(),
        )
        .unwrap();
        let nonce = crypto::decode_b64(
            result
                .key_attributes
                .recovery_key_decryption_nonce
                .as_ref()
                .unwrap(),
        )
        .unwrap();
        let decrypted = secretbox::decrypt(&encrypted, &nonce, &master_key).unwrap();

        let original = crypto::decode_hex(&result.private_key_attributes.recovery_key).unwrap();
        assert_eq!(decrypted, original);
    }

    #[test]
    fn test_password_change() {
        crypto::init().unwrap();

        let initial = generate_test_keys("old_password").unwrap();
        let master_key = crypto::decode_b64(&initial.private_key_attributes.key).unwrap();

        let (new_attrs, new_login_key) = generate_key_attributes_for_new_password_with_strength(
            &master_key,
            "new_password",
            KeyDerivationStrength::Interactive,
        )
        .unwrap();

        assert_ne!(new_attrs.kek_salt, initial.key_attributes.kek_salt);
        assert_ne!(new_login_key, initial.login_key);

        // Verify we can decrypt with new password
        let kek_salt = crypto::decode_b64(&new_attrs.kek_salt).unwrap();
        let kek = argon::derive_key(
            "new_password",
            &kek_salt,
            new_attrs.mem_limit.unwrap(),
            new_attrs.ops_limit.unwrap(),
        )
        .unwrap();
        let encrypted = crypto::decode_b64(&new_attrs.encrypted_key).unwrap();
        let nonce = crypto::decode_b64(&new_attrs.key_decryption_nonce).unwrap();
        let decrypted = secretbox::decrypt(&encrypted, &nonce, &kek).unwrap();
        assert_eq!(decrypted, master_key);
    }

    #[test]
    fn test_create_new_recovery_key() {
        crypto::init().unwrap();

        let master_key = keys::generate_key();
        let (recovery_hex, enc_master, nonce_master, enc_recovery, nonce_recovery) =
            create_new_recovery_key(&master_key).unwrap();

        assert_eq!(recovery_hex.len(), 64);

        let recovery_key = crypto::decode_hex(&recovery_hex).unwrap();
        let decrypted = secretbox::decrypt(
            &crypto::decode_b64(&enc_master).unwrap(),
            &crypto::decode_b64(&nonce_master).unwrap(),
            &recovery_key,
        )
        .unwrap();
        assert_eq!(decrypted, master_key);

        let decrypted_recovery = secretbox::decrypt(
            &crypto::decode_b64(&enc_recovery).unwrap(),
            &crypto::decode_b64(&nonce_recovery).unwrap(),
            &master_key,
        )
        .unwrap();
        assert_eq!(decrypted_recovery, recovery_key);
    }

    #[test]
    fn test_different_passwords_produce_different_keys() {
        crypto::init().unwrap();

        let result1 = generate_test_keys("password1").unwrap();
        let result2 = generate_test_keys("password2").unwrap();

        assert_ne!(
            result1.key_attributes.kek_salt,
            result2.key_attributes.kek_salt
        );
        assert_ne!(
            result1.private_key_attributes.key,
            result2.private_key_attributes.key
        );
        assert_ne!(result1.login_key, result2.login_key);
    }
}
