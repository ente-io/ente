//! High-level authentication API for applications.
//!
//! This module provides the main entry points that CLI/GUI applications should use
//! for authentication flows. It wraps the lower-level crypto operations.

use crate::crypto::{self, argon, kdf, sealed, secretbox};

use super::{AuthError, KeyAttributes, Result, SrpAttributes, SrpAuthClient};

/// Credentials derived from password for SRP authentication.
#[derive(Debug)]
pub struct SrpCredentials {
    /// Key encryption key (32 bytes) - used to decrypt master key after auth.
    pub kek: Vec<u8>,
    /// Login key (16 bytes) - used as password in SRP protocol.
    pub login_key: Vec<u8>,
}

/// Decrypted secrets after successful authentication.
#[derive(Debug)]
pub struct DecryptedSecrets {
    /// Master key for encrypting/decrypting data.
    pub master_key: Vec<u8>,
    /// Secret key (private key) for asymmetric operations.
    pub secret_key: Vec<u8>,
    /// Authentication token (decrypted).
    pub token: Vec<u8>,
}

/// Derive SRP credentials from password.
///
/// This is the first step in the SRP login flow. Call this after password entry
/// to get the credentials needed for the SRP protocol.
///
/// # Arguments
/// * `password` - User's password
/// * `srp_attrs` - SRP attributes from the server
///
/// # Returns
/// * `SrpCredentials` containing KEK (for later decryption) and login_key (for SRP)
pub fn derive_srp_credentials(password: &str, srp_attrs: &SrpAttributes) -> Result<SrpCredentials> {
    let kek_salt = crypto::decode_b64(&srp_attrs.kek_salt)
        .map_err(|e| AuthError::Decode(format!("kek_salt: {}", e)))?;

    let kek = argon::derive_key(
        password,
        &kek_salt,
        srp_attrs.mem_limit,
        srp_attrs.ops_limit,
    )?;

    let login_key = kdf::derive_login_key(&kek)?;

    Ok(SrpCredentials { kek, login_key })
}

/// Derive only the KEK from password.
///
/// Use this for email MFA flow where SRP is skipped. The KEK is used
/// to decrypt the master key after email/TOTP verification.
///
/// # Arguments
/// * `password` - User's password
/// * `kek_salt` - Base64-encoded salt from key attributes
/// * `mem_limit` - Argon2 memory limit
/// * `ops_limit` - Argon2 operations limit
pub fn derive_kek(
    password: &str,
    kek_salt: &str,
    mem_limit: u32,
    ops_limit: u32,
) -> Result<Vec<u8>> {
    let salt =
        crypto::decode_b64(kek_salt).map_err(|e| AuthError::Decode(format!("kek_salt: {}", e)))?;

    argon::derive_key(password, &salt, mem_limit, ops_limit).map_err(AuthError::from)
}

/// Decrypt secrets after successful authentication.
///
/// Call this after SRP + 2FA is complete, when you have the key attributes
/// and encrypted token from the server.
///
/// # Arguments
/// * `kek` - Key encryption key (from `derive_srp_credentials` or `derive_kek`)
/// * `key_attrs` - Key attributes from the server
/// * `encrypted_token` - Base64-encoded encrypted authentication token
///
/// # Returns
/// * `DecryptedSecrets` containing master_key, secret_key, and token
pub fn decrypt_secrets(
    kek: &[u8],
    key_attrs: &KeyAttributes,
    encrypted_token: &str,
) -> Result<DecryptedSecrets> {
    // Decrypt master key with KEK
    let encrypted_key = crypto::decode_b64(&key_attrs.encrypted_key)
        .map_err(|e| AuthError::Decode(format!("encrypted_key: {}", e)))?;
    let key_nonce = crypto::decode_b64(&key_attrs.key_decryption_nonce)
        .map_err(|e| AuthError::Decode(format!("key_decryption_nonce: {}", e)))?;

    let master_key = secretbox::decrypt(&encrypted_key, &key_nonce, kek)
        .map_err(|_| AuthError::IncorrectPassword)?;

    // Decrypt secret key with master key
    let encrypted_secret_key = crypto::decode_b64(&key_attrs.encrypted_secret_key)
        .map_err(|e| AuthError::Decode(format!("encrypted_secret_key: {}", e)))?;
    let secret_key_nonce = crypto::decode_b64(&key_attrs.secret_key_decryption_nonce)
        .map_err(|e| AuthError::Decode(format!("secret_key_decryption_nonce: {}", e)))?;

    let secret_key = secretbox::decrypt(&encrypted_secret_key, &secret_key_nonce, &master_key)
        .map_err(|_| AuthError::InvalidKeyAttributes)?;

    // Decrypt token with sealed box (public key crypto)
    let public_key = crypto::decode_b64(&key_attrs.public_key)
        .map_err(|e| AuthError::Decode(format!("public_key: {}", e)))?;
    let sealed_token = crypto::decode_b64(encrypted_token)
        .map_err(|e| AuthError::Decode(format!("encrypted_token: {}", e)))?;

    let token = sealed::open(&sealed_token, &public_key, &secret_key)
        .map_err(|_| AuthError::InvalidKeyAttributes)?;

    Ok(DecryptedSecrets {
        master_key,
        secret_key,
        token,
    })
}

/// Create an SRP client for password authentication.
///
/// This is a convenience function that:
/// 1. Derives credentials from password
/// 2. Creates an SRP client ready for the protocol
///
/// # Arguments
/// * `password` - User's password
/// * `srp_attrs` - SRP attributes from the server
///
/// # Returns
/// * Tuple of (SrpAuthClient, kek) - use client for SRP, keep kek for later decryption
pub fn create_srp_client(
    password: &str,
    srp_attrs: &SrpAttributes,
) -> Result<(SrpAuthClient, Vec<u8>)> {
    let creds = derive_srp_credentials(password, srp_attrs)?;

    let srp_salt = crypto::decode_b64(&srp_attrs.srp_salt)
        .map_err(|e| AuthError::Decode(format!("srp_salt: {}", e)))?;

    let client = SrpAuthClient::new(&srp_attrs.srp_user_id, &srp_salt, &creds.login_key)?;

    Ok((client, creds.kek))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::auth::{KeyDerivationStrength, generate_keys_with_strength};

    #[test]
    fn test_derive_srp_credentials() {
        crate::crypto::init().unwrap();

        let password = "test_password";
        let gen_result =
            generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap();

        let srp_attrs = SrpAttributes {
            srp_user_id: "test-user".to_string(),
            srp_salt: crypto::encode_b64(&[0u8; 16]),
            mem_limit: gen_result.key_attributes.mem_limit.unwrap(),
            ops_limit: gen_result.key_attributes.ops_limit.unwrap(),
            kek_salt: gen_result.key_attributes.kek_salt.clone(),
            is_email_mfa_enabled: false,
        };

        let creds = derive_srp_credentials(password, &srp_attrs).unwrap();

        assert_eq!(creds.kek.len(), 32);
        assert_eq!(creds.login_key.len(), 16);
        assert_eq!(creds.login_key, gen_result.login_key);
    }

    #[test]
    fn test_decrypt_secrets_roundtrip() {
        crate::crypto::init().unwrap();

        let password = "test_password";
        let gen_result =
            generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap();

        // Create a sealed token
        let token = b"auth_token_12345";
        let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
        let sealed_token = sealed::seal(token, &public_key).unwrap();
        let encrypted_token = crypto::encode_b64(&sealed_token);

        // Derive KEK
        let kek = derive_kek(
            password,
            &gen_result.key_attributes.kek_salt,
            gen_result.key_attributes.mem_limit.unwrap(),
            gen_result.key_attributes.ops_limit.unwrap(),
        )
        .unwrap();

        // Decrypt secrets
        let secrets = decrypt_secrets(&kek, &gen_result.key_attributes, &encrypted_token).unwrap();

        // Verify
        let original_master_key =
            crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();
        assert_eq!(secrets.master_key, original_master_key);

        let original_secret_key =
            crypto::decode_b64(&gen_result.private_key_attributes.secret_key).unwrap();
        assert_eq!(secrets.secret_key, original_secret_key);

        assert_eq!(secrets.token, token);
    }

    #[test]
    fn test_wrong_password_fails() {
        crate::crypto::init().unwrap();

        let gen_result =
            generate_keys_with_strength("correct_password", KeyDerivationStrength::Interactive)
                .unwrap();

        let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
        let sealed_token = sealed::seal(b"token", &public_key).unwrap();
        let encrypted_token = crypto::encode_b64(&sealed_token);

        // Derive KEK with wrong password
        let kek = derive_kek(
            "wrong_password",
            &gen_result.key_attributes.kek_salt,
            gen_result.key_attributes.mem_limit.unwrap(),
            gen_result.key_attributes.ops_limit.unwrap(),
        )
        .unwrap();

        // Decryption should fail
        let result = decrypt_secrets(&kek, &gen_result.key_attributes, &encrypted_token);
        assert!(matches!(result, Err(AuthError::IncorrectPassword)));
    }

    #[test]
    fn test_create_srp_client() {
        crate::crypto::init().unwrap();

        let password = "test_password";
        let gen_result =
            generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap();

        let srp_attrs = SrpAttributes {
            srp_user_id: "test-user".to_string(),
            srp_salt: crypto::encode_b64(&[0u8; 16]),
            mem_limit: gen_result.key_attributes.mem_limit.unwrap(),
            ops_limit: gen_result.key_attributes.ops_limit.unwrap(),
            kek_salt: gen_result.key_attributes.kek_salt.clone(),
            is_email_mfa_enabled: false,
        };

        let (client, kek) = create_srp_client(password, &srp_attrs).unwrap();

        assert_eq!(kek.len(), 32);
        assert!(!client.compute_a().is_empty());
    }
}
