//! Account recovery using recovery key.

use crate::crypto::{self, sealed, secretbox};

use super::{AuthError, KeyAttributes, LoginResult, Result};

/// Recover account using recovery key.
///
/// The recovery key should be provided as a hex string (64 characters).
pub fn recover_with_key(
    recovery_key_hex: &str,
    attributes: &KeyAttributes,
    encrypted_token: &str,
) -> Result<LoginResult> {
    let recovery_key = crypto::decode_hex(recovery_key_hex)
        .map_err(|e| AuthError::Decode(format!("recovery_key: {}", e)))?;

    if recovery_key.len() != 32 {
        return Err(AuthError::IncorrectRecoveryKey);
    }

    let encrypted_master_key = attributes
        .master_key_encrypted_with_recovery_key
        .as_ref()
        .ok_or(AuthError::MissingField(
            "master_key_encrypted_with_recovery_key",
        ))?;

    let master_key_nonce = attributes
        .master_key_decryption_nonce
        .as_ref()
        .ok_or(AuthError::MissingField("master_key_decryption_nonce"))?;

    let encrypted_master_key_bytes = crypto::decode_b64(encrypted_master_key)
        .map_err(|e| AuthError::Decode(format!("master_key_encrypted_with_recovery_key: {}", e)))?;
    let master_key_nonce_bytes = crypto::decode_b64(master_key_nonce)
        .map_err(|e| AuthError::Decode(format!("master_key_decryption_nonce: {}", e)))?;

    let master_key = secretbox::decrypt(
        &encrypted_master_key_bytes,
        &master_key_nonce_bytes,
        &recovery_key,
    )
    .map_err(|_| AuthError::IncorrectRecoveryKey)?;

    let encrypted_secret_key = crypto::decode_b64(&attributes.encrypted_secret_key)
        .map_err(|e| AuthError::Decode(format!("encrypted_secret_key: {}", e)))?;
    let secret_key_nonce = crypto::decode_b64(&attributes.secret_key_decryption_nonce)
        .map_err(|e| AuthError::Decode(format!("secret_key_decryption_nonce: {}", e)))?;

    let secret_key = secretbox::decrypt(&encrypted_secret_key, &secret_key_nonce, &master_key)
        .map_err(|_| AuthError::InvalidKeyAttributes)?;

    let public_key = crypto::decode_b64(&attributes.public_key)
        .map_err(|e| AuthError::Decode(format!("public_key: {}", e)))?;
    let sealed_token = crypto::decode_b64(encrypted_token)
        .map_err(|e| AuthError::Decode(format!("encrypted_token: {}", e)))?;

    let token = sealed::open(&sealed_token, &public_key, &secret_key)
        .map_err(|_| AuthError::InvalidKeyAttributes)?;

    Ok(LoginResult {
        master_key,
        secret_key,
        token,
        key_encryption_key: Vec::new(),
    })
}

/// Get the recovery key from stored encrypted form.
pub fn get_recovery_key(master_key: &[u8], attributes: &KeyAttributes) -> Result<String> {
    let encrypted_recovery_key = attributes
        .recovery_key_encrypted_with_master_key
        .as_ref()
        .ok_or(AuthError::MissingField(
            "recovery_key_encrypted_with_master_key",
        ))?;

    let nonce = attributes
        .recovery_key_decryption_nonce
        .as_ref()
        .ok_or(AuthError::MissingField("recovery_key_decryption_nonce"))?;

    let encrypted_bytes = crypto::decode_b64(encrypted_recovery_key)
        .map_err(|e| AuthError::Decode(format!("recovery_key_encrypted_with_master_key: {}", e)))?;
    let nonce_bytes = crypto::decode_b64(nonce)
        .map_err(|e| AuthError::Decode(format!("recovery_key_decryption_nonce: {}", e)))?;

    let recovery_key = secretbox::decrypt(&encrypted_bytes, &nonce_bytes, master_key)
        .map_err(|_| AuthError::InvalidKeyAttributes)?;

    Ok(crypto::encode_hex(&recovery_key))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::auth::{KeyDerivationStrength, generate_keys_with_strength};
    use crate::crypto::keys;

    fn generate_test_keys(password: &str) -> super::super::KeyGenResult {
        generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap()
    }

    fn create_sealed_token(token: &[u8], public_key: &[u8]) -> String {
        let sealed = sealed::seal(token, public_key).unwrap();
        crypto::encode_b64(&sealed)
    }

    #[test]
    fn test_recovery_roundtrip() {
        crypto::init().unwrap();

        let gen_result = generate_test_keys("original_password");
        let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"my_token", &public_key);

        let recovery_result = recover_with_key(
            &gen_result.private_key_attributes.recovery_key,
            &gen_result.key_attributes,
            &encrypted_token,
        )
        .unwrap();

        let expected_master = crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();
        assert_eq!(recovery_result.master_key, expected_master);
        assert_eq!(recovery_result.token, b"my_token");
    }

    #[test]
    fn test_wrong_recovery_key() {
        crypto::init().unwrap();

        let gen_result = generate_test_keys("password");
        let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"token", &public_key);

        let wrong_key = crypto::encode_hex(&keys::generate_key());
        let result = recover_with_key(&wrong_key, &gen_result.key_attributes, &encrypted_token);
        assert!(matches!(result, Err(AuthError::IncorrectRecoveryKey)));
    }

    #[test]
    fn test_get_recovery_key() {
        crypto::init().unwrap();

        let gen_result = generate_test_keys("password");
        let master_key = crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();

        let recovered = get_recovery_key(&master_key, &gen_result.key_attributes).unwrap();
        assert_eq!(recovered, gen_result.private_key_attributes.recovery_key);
    }
}
