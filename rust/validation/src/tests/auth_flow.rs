//! Full authentication flow validation
//!
//! Tests the complete signup/login flow comparing ente-core with libsodium.

use super::TestResult;
use crate::run_tests;
use base64::{engine::general_purpose::STANDARD, Engine};
use ente_core::auth::{
    decrypt_secrets, derive_kek, generate_keys_with_strength, KeyDerivationStrength,
};
use ente_core::crypto;
use libsodium_sys as sodium;
use std::ffi::c_char;

pub fn run_all() -> TestResult {
    println!("\n── Full Authentication Flow ──");
    run_tests! {
        "Key generation produces valid keys" => test_key_generation(),
        "Login key matches between core and libsodium" => test_login_key_derivation(),
        "Decrypt secrets roundtrip" => test_decrypt_secrets(),
        "Recovery key roundtrip" => test_recovery_key(),
        "Password change flow" => test_password_change(),
        "Cross-implementation auth flow" => test_cross_impl_auth(),
    }
}

/// Derive KEK using libsodium
fn libsodium_derive_kek(password: &str, salt: &[u8], mem: u32, ops: u32) -> Vec<u8> {
    let mut key = vec![0u8; 32];
    let result = unsafe {
        sodium::crypto_pwhash(
            key.as_mut_ptr(),
            32,
            password.as_ptr() as *const i8,
            password.len() as u64,
            salt.as_ptr(),
            ops as u64,
            mem as usize,
            sodium::crypto_pwhash_ALG_ARGON2ID13 as i32,
        )
    };
    assert_eq!(result, 0, "libsodium argon2 failed");
    key
}

/// Derive login key using libsodium KDF
fn libsodium_derive_login_key(kek: &[u8]) -> Vec<u8> {
    let mut subkey = vec![0u8; 32];
    let mut ctx = [0u8; 8];
    ctx[..8].copy_from_slice(b"loginctx");

    let result = unsafe {
        sodium::crypto_kdf_derive_from_key(
            subkey.as_mut_ptr(),
            32,
            1, // subkey_id
            ctx.as_ptr() as *const c_char,
            kek.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium kdf failed");
    subkey[..16].to_vec()
}

/// Encrypt with libsodium secretbox
#[allow(dead_code)]
fn libsodium_secretbox_seal(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Vec<u8> {
    let mut ciphertext = vec![0u8; plaintext.len() + 16];
    unsafe {
        sodium::crypto_secretbox_easy(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        );
    }
    ciphertext
}

/// Decrypt with libsodium secretbox
fn libsodium_secretbox_open(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Option<Vec<u8>> {
    if ciphertext.len() < 16 {
        return None;
    }
    let mut plaintext = vec![0u8; ciphertext.len() - 16];
    let result = unsafe {
        sodium::crypto_secretbox_open_easy(
            plaintext.as_mut_ptr(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };
    if result == 0 {
        Some(plaintext)
    } else {
        None
    }
}

/// Seal with libsodium sealed box
#[allow(dead_code)]
fn libsodium_seal(plaintext: &[u8], pk: &[u8]) -> Vec<u8> {
    let mut ciphertext = vec![0u8; plaintext.len() + 48];
    unsafe {
        sodium::crypto_box_seal(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            pk.as_ptr(),
        );
    }
    ciphertext
}

fn test_key_generation() -> bool {
    crypto::init().unwrap();

    let password = "test_password_123!";
    let result = generate_keys_with_strength(password, KeyDerivationStrength::Interactive);

    if result.is_err() {
        return false;
    }

    let result = result.unwrap();

    // Verify all keys have correct lengths
    let master_key = crypto::decode_b64(&result.private_key_attributes.key).unwrap();
    let secret_key = crypto::decode_b64(&result.private_key_attributes.secret_key).unwrap();
    let public_key = crypto::decode_b64(&result.key_attributes.public_key).unwrap();

    master_key.len() == 32
        && secret_key.len() == 32
        && public_key.len() == 32
        && result.login_key.len() == 16
        && result.private_key_attributes.recovery_key.len() == 64 // hex encoded
}

fn test_login_key_derivation() -> bool {
    crypto::init().unwrap();

    let password = "login_test_password";
    let salt = crate::random_bytes(16);
    let mem = 67108864; // 64MB
    let ops = 2;

    // Derive KEK with both implementations
    let libsodium_kek = libsodium_derive_kek(password, &salt, mem, ops);
    let core_kek = crypto::argon::derive_key(password, &salt, mem, ops).unwrap();

    if libsodium_kek != core_kek {
        eprintln!("  KEK mismatch!");
        return false;
    }

    // Derive login key with both implementations
    let libsodium_login = libsodium_derive_login_key(&libsodium_kek);
    let core_login = crypto::kdf::derive_login_key(&core_kek).unwrap();

    if libsodium_login != core_login {
        eprintln!("  Login key mismatch!");
        eprintln!("  libsodium: {}", hex::encode(&libsodium_login));
        eprintln!("  core:      {}", hex::encode(&core_login));
        return false;
    }

    true
}

fn test_decrypt_secrets() -> bool {
    crypto::init().unwrap();

    let password = "decrypt_test_password";

    // Generate keys with core
    let gen_result =
        generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap();

    // Create a sealed token
    let token = b"test_auth_token_12345";
    let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key).unwrap();
    let sealed_token = crypto::sealed::seal(token, &public_key).unwrap();
    let encrypted_token = STANDARD.encode(&sealed_token);

    // Decrypt with core
    let mem_limit = gen_result
        .key_attributes
        .mem_limit
        .expect("missing mem_limit");
    let ops_limit = gen_result
        .key_attributes
        .ops_limit
        .expect("missing ops_limit");
    let kek = derive_kek(
        password,
        &gen_result.key_attributes.kek_salt,
        mem_limit,
        ops_limit,
    )
    .unwrap();

    let result = decrypt_secrets(&kek, &gen_result.key_attributes, &encrypted_token);

    if result.is_err() {
        eprintln!("  Decrypt failed: {:?}", result.err());
        return false;
    }

    let result = result.unwrap();

    // Verify decrypted values
    let expected_master = crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();
    let expected_secret =
        crypto::decode_b64(&gen_result.private_key_attributes.secret_key).unwrap();

    result.master_key == expected_master
        && result.secret_key == expected_secret
        && result.token == token
}

fn test_recovery_key() -> bool {
    crypto::init().unwrap();

    let password = "recovery_test_password";
    let gen_result =
        generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap();

    // Get recovery key
    let recovery_key_hex = &gen_result.private_key_attributes.recovery_key;
    let recovery_key = crypto::decode_hex(recovery_key_hex).unwrap();

    // Verify recovery key can decrypt master key
    let enc_master = crypto::decode_b64(
        gen_result
            .key_attributes
            .master_key_encrypted_with_recovery_key
            .as_ref()
            .unwrap(),
    )
    .unwrap();
    let nonce = crypto::decode_b64(
        gen_result
            .key_attributes
            .master_key_decryption_nonce
            .as_ref()
            .unwrap(),
    )
    .unwrap();

    // Decrypt with libsodium
    let decrypted = libsodium_secretbox_open(&enc_master, &nonce, &recovery_key);

    if decrypted.is_none() {
        return false;
    }

    let expected_master = crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();
    decrypted.unwrap() == expected_master
}

fn test_password_change() -> bool {
    crypto::init().unwrap();

    let old_password = "old_password_123";
    let new_password = "new_password_456";

    // Generate initial keys
    let gen_result =
        generate_keys_with_strength(old_password, KeyDerivationStrength::Interactive).unwrap();
    let master_key = crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();

    // Generate new key attributes for new password
    let (new_attrs, new_login_key) =
        ente_core::auth::generate_key_attributes_for_new_password_with_strength(
            &master_key,
            new_password,
            KeyDerivationStrength::Interactive,
        )
        .unwrap();

    // Verify new login key is different
    if new_login_key == gen_result.login_key {
        return false;
    }

    // Verify can decrypt master key with new password using libsodium
    let new_salt = crypto::decode_b64(&new_attrs.kek_salt).unwrap();
    let new_kek = libsodium_derive_kek(
        new_password,
        &new_salt,
        new_attrs.mem_limit.unwrap(),
        new_attrs.ops_limit.unwrap(),
    );

    let enc_key = crypto::decode_b64(&new_attrs.encrypted_key).unwrap();
    let nonce = crypto::decode_b64(&new_attrs.key_decryption_nonce).unwrap();

    let decrypted = libsodium_secretbox_open(&enc_key, &nonce, &new_kek);

    decrypted == Some(master_key)
}

fn test_cross_impl_auth() -> bool {
    crypto::init().unwrap();

    let password = "cross_impl_password";

    // Simulate signup with core
    let gen_result =
        generate_keys_with_strength(password, KeyDerivationStrength::Interactive).unwrap();

    // Simulate server storing key attributes
    let key_attrs = &gen_result.key_attributes;

    // Simulate login with libsodium (like the CLI would do)
    let kek_salt = crypto::decode_b64(&key_attrs.kek_salt).unwrap();
    let kek = libsodium_derive_kek(
        password,
        &kek_salt,
        key_attrs.mem_limit.unwrap(),
        key_attrs.ops_limit.unwrap(),
    );

    // Decrypt master key with libsodium
    let enc_key = crypto::decode_b64(&key_attrs.encrypted_key).unwrap();
    let nonce = crypto::decode_b64(&key_attrs.key_decryption_nonce).unwrap();
    let master_key = libsodium_secretbox_open(&enc_key, &nonce, &kek);

    if master_key.is_none() {
        eprintln!("  Failed to decrypt master key with libsodium");
        return false;
    }
    let master_key = master_key.unwrap();

    // Decrypt secret key with libsodium
    let enc_secret = crypto::decode_b64(&key_attrs.encrypted_secret_key).unwrap();
    let secret_nonce = crypto::decode_b64(&key_attrs.secret_key_decryption_nonce).unwrap();
    let secret_key = libsodium_secretbox_open(&enc_secret, &secret_nonce, &master_key);

    if secret_key.is_none() {
        eprintln!("  Failed to decrypt secret key with libsodium");
        return false;
    }

    // Verify keys match
    let expected_master = crypto::decode_b64(&gen_result.private_key_attributes.key).unwrap();
    let expected_secret =
        crypto::decode_b64(&gen_result.private_key_attributes.secret_key).unwrap();

    master_key == expected_master && secret_key.unwrap() == expected_secret
}
