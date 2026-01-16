//! Integration tests for authentication module.

use ente_core::auth::{
    KeyAttributes, KeyDerivationStrength, SrpAttributes, create_new_recovery_key,
    decrypt_secrets_legacy, decrypt_secrets_with_kek, derive_keys_for_login,
    generate_key_attributes_for_new_password_with_strength, generate_keys_with_strength,
    get_recovery_key, recover_with_key,
};
use ente_core::crypto::{self, argon, keys, sealed, secretbox};

// Use Interactive for fast tests
fn generate_test_keys(password: &str) -> ente_core::auth::KeyGenResult {
    generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap()
}

fn create_sealed_token(token: &[u8], public_key: &[u8]) -> String {
    let sealed = sealed::seal(token, public_key).unwrap();
    crypto::encode_b64(&sealed)
}

mod signup {
    use super::*;

    #[test]
    fn test_complete_signup_flow() {
        crypto::init().unwrap();
        let result = generate_test_keys("secure_password_123!");

        assert!(!result.key_attributes.kek_salt.is_empty());
        assert!(!result.key_attributes.encrypted_key.is_empty());
        assert!(result.key_attributes.mem_limit.is_some());
        assert!(
            result
                .key_attributes
                .master_key_encrypted_with_recovery_key
                .is_some()
        );
        assert_eq!(result.login_key.len(), 16);
    }

    #[test]
    fn test_signup_produces_valid_keypair() {
        crypto::init().unwrap();
        let result = generate_test_keys("password");

        let public_key = crypto::decode_b64(&result.key_attributes.public_key).unwrap();
        let master_key = crypto::decode_b64(&result.private_key_attributes.key).unwrap();

        let enc_secret = crypto::decode_b64(&result.key_attributes.encrypted_secret_key).unwrap();
        let nonce = crypto::decode_b64(&result.key_attributes.secret_key_decryption_nonce).unwrap();
        let secret_key = secretbox::decrypt(&enc_secret, &nonce, &master_key).unwrap();

        let test_data = b"test message";
        let sealed = sealed::seal(test_data, &public_key).unwrap();
        let opened = sealed::open(&sealed, &public_key, &secret_key).unwrap();
        assert_eq!(opened, test_data);
    }
}

mod login {
    use super::*;

    #[test]
    fn test_complete_login_flow() {
        crypto::init().unwrap();
        let password = "my_password";
        let signup = generate_test_keys(password);
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();

        let token = b"auth_token_xyz";
        let encrypted_token = create_sealed_token(token, &public_key);

        let login_result =
            decrypt_secrets_legacy(password, &signup.key_attributes, &encrypted_token).unwrap();

        let expected_master = crypto::decode_b64(&signup.private_key_attributes.key).unwrap();
        assert_eq!(login_result.master_key, expected_master);
        assert_eq!(login_result.token, token);
    }

    #[test]
    fn test_wrong_password_fails() {
        crypto::init().unwrap();
        let signup = generate_test_keys("correct_password");
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"token", &public_key);

        let result =
            decrypt_secrets_legacy("wrong_password", &signup.key_attributes, &encrypted_token);
        assert!(result.is_err());
    }

    #[test]
    fn test_login_with_precomputed_kek() {
        crypto::init().unwrap();
        let password = "password";
        let signup = generate_test_keys(password);
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"token", &public_key);

        let kek_salt = crypto::decode_b64(&signup.key_attributes.kek_salt).unwrap();
        let kek = argon::derive_key(
            password,
            &kek_salt,
            signup.key_attributes.mem_limit.unwrap(),
            signup.key_attributes.ops_limit.unwrap(),
        )
        .unwrap();

        let result =
            decrypt_secrets_with_kek(&kek, &signup.key_attributes, &encrypted_token).unwrap();
        assert_eq!(result.token, b"token");
    }

    #[test]
    fn test_derive_keys_for_login() {
        crypto::init().unwrap();
        let password = "password";
        let signup = generate_test_keys(password);

        let srp_attrs = SrpAttributes {
            srp_user_id: "user123".to_string(),
            srp_salt: crypto::encode_b64(&keys::random_bytes(16)),
            mem_limit: signup.key_attributes.mem_limit.unwrap(),
            ops_limit: signup.key_attributes.ops_limit.unwrap(),
            kek_salt: signup.key_attributes.kek_salt.clone(),
            is_email_mfa_enabled: false,
        };

        let (kek, login_key) = derive_keys_for_login(password, &srp_attrs).unwrap();
        assert_eq!(kek.len(), 32);
        assert_eq!(login_key, signup.login_key);
    }
}

mod recovery {
    use super::*;

    #[test]
    fn test_complete_recovery_flow() {
        crypto::init().unwrap();
        let signup = generate_test_keys("original_password");
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"my_token", &public_key);

        let recovery_result = recover_with_key(
            &signup.private_key_attributes.recovery_key,
            &signup.key_attributes,
            &encrypted_token,
        )
        .unwrap();

        let expected_master = crypto::decode_b64(&signup.private_key_attributes.key).unwrap();
        assert_eq!(recovery_result.master_key, expected_master);
    }

    #[test]
    fn test_wrong_recovery_key_fails() {
        crypto::init().unwrap();
        let signup = generate_test_keys("password");
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();
        let encrypted_token = create_sealed_token(b"token", &public_key);

        let wrong_key = crypto::encode_hex(&keys::generate_key());
        let result = recover_with_key(&wrong_key, &signup.key_attributes, &encrypted_token);
        assert!(result.is_err());
    }

    #[test]
    fn test_get_recovery_key() {
        crypto::init().unwrap();
        let signup = generate_test_keys("password");
        let master_key = crypto::decode_b64(&signup.private_key_attributes.key).unwrap();

        let recovered = get_recovery_key(&master_key, &signup.key_attributes).unwrap();
        assert_eq!(recovered, signup.private_key_attributes.recovery_key);
    }

    #[test]
    fn test_create_new_recovery_key() {
        crypto::init().unwrap();
        let signup = generate_test_keys("password");
        let master_key = crypto::decode_b64(&signup.private_key_attributes.key).unwrap();
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();

        let (new_recovery_hex, enc_master, nonce_master, enc_recovery, nonce_recovery) =
            create_new_recovery_key(&master_key).unwrap();

        assert_ne!(new_recovery_hex, signup.private_key_attributes.recovery_key);

        let mut updated_attrs = signup.key_attributes.clone();
        updated_attrs.master_key_encrypted_with_recovery_key = Some(enc_master);
        updated_attrs.master_key_decryption_nonce = Some(nonce_master);
        updated_attrs.recovery_key_encrypted_with_master_key = Some(enc_recovery);
        updated_attrs.recovery_key_decryption_nonce = Some(nonce_recovery);

        let encrypted_token = create_sealed_token(b"token", &public_key);
        let result = recover_with_key(&new_recovery_hex, &updated_attrs, &encrypted_token).unwrap();
        assert_eq!(result.master_key, master_key);
    }
}

mod password_change {
    use super::*;

    #[test]
    fn test_password_change_flow() {
        crypto::init().unwrap();
        let old_password = "old_password";
        let new_password = "new_password";

        let signup = generate_test_keys(old_password);
        let master_key = crypto::decode_b64(&signup.private_key_attributes.key).unwrap();
        let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();

        let (new_attrs, _) = generate_key_attributes_for_new_password_with_strength(
            &master_key,
            new_password,
            KeyDerivationStrength::Interactive,
        )
        .unwrap();

        let mut updated = signup.key_attributes.clone();
        updated.kek_salt = new_attrs.kek_salt;
        updated.encrypted_key = new_attrs.encrypted_key;
        updated.key_decryption_nonce = new_attrs.key_decryption_nonce;
        updated.mem_limit = new_attrs.mem_limit;
        updated.ops_limit = new_attrs.ops_limit;

        let encrypted_token = create_sealed_token(b"token", &public_key);

        // Old password should fail
        let result = decrypt_secrets_legacy(old_password, &updated, &encrypted_token);
        assert!(result.is_err());

        // New password should work
        let result = decrypt_secrets_legacy(new_password, &updated, &encrypted_token).unwrap();
        assert_eq!(result.master_key, master_key);
    }
}

mod edge_cases {
    use super::*;

    #[test]
    fn test_unicode_passwords() {
        crypto::init().unwrap();

        let passwords = ["пароль", "密码", "🔐🔑🔒"];

        for password in &passwords {
            let signup = generate_test_keys(password);
            let public_key = crypto::decode_b64(&signup.key_attributes.public_key).unwrap();
            let encrypted_token = create_sealed_token(b"token", &public_key);

            let result =
                decrypt_secrets_legacy(password, &signup.key_attributes, &encrypted_token).unwrap();
            assert_eq!(result.token, b"token");
        }
    }

    #[test]
    fn test_empty_password() {
        crypto::init().unwrap();
        let result = generate_test_keys("");
        assert!(!result.key_attributes.encrypted_key.is_empty());
    }
}

mod serialization {
    use super::*;

    #[test]
    fn test_key_attributes_json_roundtrip() {
        crypto::init().unwrap();
        let signup = generate_test_keys("password");

        let json = serde_json::to_string(&signup.key_attributes).unwrap();
        let parsed: KeyAttributes = serde_json::from_str(&json).unwrap();

        assert_eq!(parsed.kek_salt, signup.key_attributes.kek_salt);
        assert_eq!(parsed.encrypted_key, signup.key_attributes.encrypted_key);
    }

    #[test]
    fn test_key_attributes_camel_case() {
        crypto::init().unwrap();
        let signup = generate_test_keys("password");
        let json = serde_json::to_string(&signup.key_attributes).unwrap();

        assert!(json.contains("kekSalt"));
        assert!(json.contains("encryptedKey"));
        assert!(json.contains("memLimit"));
    }

    #[test]
    fn test_srp_attributes_json() {
        let attrs = SrpAttributes {
            srp_user_id: "user123".to_string(),
            srp_salt: "c2FsdA==".to_string(),
            mem_limit: 67108864,
            ops_limit: 2,
            kek_salt: "a2VrU2FsdA==".to_string(),
            is_email_mfa_enabled: false,
        };

        let json = serde_json::to_string(&attrs).unwrap();
        let parsed: SrpAttributes = serde_json::from_str(&json).unwrap();

        assert_eq!(parsed.srp_user_id, attrs.srp_user_id);
        assert_eq!(parsed.mem_limit, attrs.mem_limit);
    }
}
