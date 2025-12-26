//! Argon2id validation tests

use super::TestResult;
use crate::run_tests;
use ente_core::crypto;
use libsodium_sys as sodium;

pub fn run_all() -> TestResult {
    println!("\n── Argon2id Key Derivation ──");
    run_tests! {
        "Interactive params (64MB, 2 ops)" => test_interactive_params(),
        "Moderate params (256MB, 3 ops)" => test_moderate_params(),
        "Custom params" => test_custom_params(),
        "Different passwords" => test_different_passwords(),
        "Different salts" => test_different_salts(),
        "Unicode password" => test_unicode_password(),
        "Empty password" => test_empty_password(),
        "Long password" => test_long_password(),
    }
}

fn derive_libsodium(password: &str, salt: &[u8], mem_limit: u32, ops_limit: u32) -> Vec<u8> {
    let mut key = vec![0u8; 32];
    let result = unsafe {
        sodium::crypto_pwhash(
            key.as_mut_ptr(),
            32,
            password.as_ptr() as *const i8,
            password.len() as u64,
            salt.as_ptr(),
            ops_limit as u64,
            mem_limit as usize,
            sodium::crypto_pwhash_ALG_ARGON2ID13 as i32,
        )
    };
    assert_eq!(result, 0, "libsodium argon2 failed");
    key
}

fn test_interactive_params() -> bool {
    let password = "test_password";
    let salt = crate::random_bytes(16);
    let mem = 67108864; // 64MB
    let ops = 2;

    let libsodium_key = derive_libsodium(password, &salt, mem, ops);
    let core_key = crypto::argon::derive_key(password, &salt, mem, ops).unwrap();

    libsodium_key == core_key
}

fn test_moderate_params() -> bool {
    let password = "moderate_password";
    let salt = crate::random_bytes(16);
    let mem = 268435456; // 256MB
    let ops = 3;

    let libsodium_key = derive_libsodium(password, &salt, mem, ops);
    let core_key = crypto::argon::derive_key(password, &salt, mem, ops).unwrap();

    libsodium_key == core_key
}

fn test_custom_params() -> bool {
    let password = "custom";
    let salt = crate::random_bytes(16);

    // Test various param combinations
    for (mem, ops) in [
        (32 * 1024 * 1024, 1),
        (128 * 1024 * 1024, 4),
        (64 * 1024 * 1024, 3),
    ] {
        let libsodium_key = derive_libsodium(password, &salt, mem, ops);
        let core_key = crypto::argon::derive_key(password, &salt, mem, ops).unwrap();
        if libsodium_key != core_key {
            return false;
        }
    }
    true
}

fn test_different_passwords() -> bool {
    let salt = crate::random_bytes(16);
    let mem = 67108864;
    let ops = 2;

    let passwords = ["password1", "password2", "p@ssw0rd!", ""];

    for p in &passwords {
        let libsodium_key = derive_libsodium(p, &salt, mem, ops);
        let core_key = crypto::argon::derive_key(p, &salt, mem, ops).unwrap();
        if libsodium_key != core_key {
            return false;
        }
    }
    true
}

fn test_different_salts() -> bool {
    let password = "password";
    let mem = 67108864;
    let ops = 2;

    for _ in 0..5 {
        let salt = crate::random_bytes(16);
        let libsodium_key = derive_libsodium(password, &salt, mem, ops);
        let core_key = crypto::argon::derive_key(password, &salt, mem, ops).unwrap();
        if libsodium_key != core_key {
            return false;
        }
    }
    true
}

fn test_unicode_password() -> bool {
    let passwords = ["пароль", "密码", "🔐🔑🔒", "café", "日本語"];
    let salt = crate::random_bytes(16);
    let mem = 67108864;
    let ops = 2;

    for p in &passwords {
        let libsodium_key = derive_libsodium(p, &salt, mem, ops);
        let core_key = crypto::argon::derive_key(p, &salt, mem, ops).unwrap();
        if libsodium_key != core_key {
            return false;
        }
    }
    true
}

fn test_empty_password() -> bool {
    let salt = crate::random_bytes(16);
    let mem = 67108864;
    let ops = 2;

    let libsodium_key = derive_libsodium("", &salt, mem, ops);
    let core_key = crypto::argon::derive_key("", &salt, mem, ops).unwrap();

    libsodium_key == core_key
}

fn test_long_password() -> bool {
    let password = "a".repeat(1000);
    let salt = crate::random_bytes(16);
    let mem = 67108864;
    let ops = 2;

    let libsodium_key = derive_libsodium(&password, &salt, mem, ops);
    let core_key = crypto::argon::derive_key(&password, &salt, mem, ops).unwrap();

    libsodium_key == core_key
}
