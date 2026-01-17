//! Login and password verification.

use crate::crypto::{self, argon, kdf, sealed, secretbox};

use super::{AuthError, KeyAttributes, LoginResult, Result, SrpAttributes};

/// Decrypt secrets and get the key-encryption-key for login.
///
/// This is the main login flow that:
/// 1. Derives KEK from password
/// 2. Decrypts master key with KEK
/// 3. Decrypts secret key with master key
/// 4. Opens the sealed token with secret key
pub fn decrypt_secrets(
    password: &str,
    attributes: &KeyAttributes,
    encrypted_token: &str,
) -> Result<LoginResult> {
    let mem_limit = attributes
        .mem_limit
        .ok_or(AuthError::MissingField("mem_limit"))?;
    let ops_limit = attributes
        .ops_limit
        .ok_or(AuthError::MissingField("ops_limit"))?;

    let kek_salt = crypto::decode_b64(&attributes.kek_salt)
        .map_err(|e| AuthError::Decode(format!("kek_salt: {}", e)))?;

    let key_encryption_key = argon::derive_key(password, &kek_salt, mem_limit, ops_limit)?;

    decrypt_secrets_with_kek(&key_encryption_key, attributes, encrypted_token)
}

/// Decrypt secrets using a pre-derived key-encryption-key.
pub fn decrypt_secrets_with_kek(
    key_encryption_key: &[u8],
    attributes: &KeyAttributes,
    encrypted_token: &str,
) -> Result<LoginResult> {
    let encrypted_key = crypto::decode_b64(&attributes.encrypted_key)
        .map_err(|e| AuthError::Decode(format!("encrypted_key: {}", e)))?;
    let key_nonce = crypto::decode_b64(&attributes.key_decryption_nonce)
        .map_err(|e| AuthError::Decode(format!("key_decryption_nonce: {}", e)))?;

    let master_key = secretbox::decrypt(&encrypted_key, &key_nonce, key_encryption_key)
        .map_err(|_| AuthError::IncorrectPassword)?;

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
        key_encryption_key: key_encryption_key.to_vec(),
    })
}

/// Derive the login key from password for SRP authentication.
pub fn derive_login_key_for_srp(password: &str, srp_attributes: &SrpAttributes) -> Result<Vec<u8>> {
    let kek_salt = crypto::decode_b64(&srp_attributes.kek_salt)
        .map_err(|e| AuthError::Decode(format!("kek_salt: {}", e)))?;

    let kek = argon::derive_key(
        password,
        &kek_salt,
        srp_attributes.mem_limit,
        srp_attributes.ops_limit,
    )?;
    let login_key = kdf::derive_login_key(&kek)?;

    Ok(login_key)
}

/// Derive KEK and login key together.
pub fn derive_keys_for_login(
    password: &str,
    srp_attributes: &SrpAttributes,
) -> Result<(Vec<u8>, Vec<u8>)> {
    let kek_salt = crypto::decode_b64(&srp_attributes.kek_salt)
        .map_err(|e| AuthError::Decode(format!("kek_salt: {}", e)))?;

    let kek = argon::derive_key(
        password,
        &kek_salt,
        srp_attributes.mem_limit,
        srp_attributes.ops_limit,
    )?;
    let login_key = kdf::derive_login_key(&kek)?;

    Ok((kek, login_key))
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
    fn test_decrypt_secrets_roundtrip() {
        crypto::init().unwrap();

        let password = "test_password_123";
        let gen_result = generate_test_keys(password);

        let token = b"auth_token_12345";
        let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(token, &public_key);

        let login_result =
            decrypt_secrets(password, &gen_result.key_attributes, &encrypted_token).unwrap();

        let original_master_key =
            crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();
        assert_eq!(login_result.master_key, original_master_key);

        let original_secret_key =
            crypto::decode_b64(&gen_result.private_key_attributes.secret_key).unwrap();
        assert_eq!(login_result.secret_key, original_secret_key);

        assert_eq!(login_result.token, token);
    }

    #[test]
    fn test_wrong_password() {
        crypto::init().unwrap();

        let gen_result = generate_test_keys("correct_password");
        let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"token", &public_key);

        let result = decrypt_secrets(
            "wrong_password",
            &gen_result.key_attributes,
            &encrypted_token,
        );
        assert!(matches!(result, Err(AuthError::IncorrectPassword)));
    }

    #[test]
    fn test_derive_login_key_for_srp() {
        crypto::init().unwrap();

        let password = "test_password";
        let gen_result = generate_test_keys(password);

        let srp_attrs = SrpAttributes {
            srp_user_id: "test_user".to_string(),
            srp_salt: crypto::encode_b64(&keys::random_bytes(16)),
            mem_limit: gen_result.key_attributes.mem_limit.unwrap(),
            ops_limit: gen_result.key_attributes.ops_limit.unwrap(),
            kek_salt: gen_result.key_attributes.kek_salt.clone(),
            is_email_mfa_enabled: false,
        };

        let login_key = derive_login_key_for_srp(password, &srp_attrs).unwrap();
        assert_eq!(login_key.len(), 16);
        assert_eq!(login_key, gen_result.login_key);
    }
}
