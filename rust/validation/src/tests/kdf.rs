//! KDF (BLAKE2b) validation tests

use super::TestResult;
use crate::run_tests;
use ente_core::crypto;
use libsodium_sys as sodium;
use std::ffi::c_char;

pub fn run_all() -> TestResult {
    println!("\n── KDF (BLAKE2b) Subkey Derivation ──");
    run_tests! {
        "Login key derivation (context='loginctx', id=1)" => test_login_key(),
        "Different subkey IDs" => test_different_ids(),
        "Different contexts" => test_different_contexts(),
        "Different subkey lengths" => test_different_lengths(),
        "Context truncation (>8 bytes)" => test_context_truncation(),
        "Context padding (<8 bytes)" => test_context_padding(),
        "Empty context" => test_empty_context(),
        "Random master keys" => test_random_keys(),
    }
}

fn derive_libsodium(key: &[u8], subkey_len: usize, subkey_id: u64, context: &[u8]) -> Vec<u8> {
    let mut subkey = vec![0u8; subkey_len];

    // Context must be exactly 8 bytes, zero-padded
    let mut ctx = [0u8; 8];
    let ctx_len = context.len().min(8);
    ctx[..ctx_len].copy_from_slice(&context[..ctx_len]);

    let result = unsafe {
        sodium::crypto_kdf_derive_from_key(
            subkey.as_mut_ptr(),
            subkey_len,
            subkey_id,
            ctx.as_ptr() as *const c_char,
            key.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium kdf failed");
    subkey
}

fn test_login_key() -> bool {
    // Test vector used in ente's login flow
    let master_key =
        hex::decode("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f").unwrap();

    let libsodium_subkey = derive_libsodium(&master_key, 32, 1, b"loginctx");
    let libsodium_login_key = &libsodium_subkey[..16];

    let core_login_key = crypto::kdf::derive_login_key(&master_key).unwrap();

    libsodium_login_key == core_login_key.as_slice()
}

fn test_different_ids() -> bool {
    let master_key = crate::random_bytes(32);

    for id in [0, 1, 2, 100, u64::MAX] {
        let libsodium_key = derive_libsodium(&master_key, 32, id, b"testctx");
        let core_key = crypto::kdf::derive_subkey(&master_key, 32, id, b"testctx").unwrap();
        if libsodium_key != core_key {
            eprintln!("  Failed for id={}", id);
            return false;
        }
    }
    true
}

fn test_different_contexts() -> bool {
    let master_key = crate::random_bytes(32);

    let contexts: &[&[u8]] = &[b"context1", b"context2", b"test", b"loginctx", b"ABCDEFGH"];

    for ctx in contexts {
        let libsodium_key = derive_libsodium(&master_key, 32, 1, ctx);
        let core_key = crypto::kdf::derive_subkey(&master_key, 32, 1, ctx).unwrap();
        if libsodium_key != core_key {
            eprintln!("  Failed for context={:?}", String::from_utf8_lossy(ctx));
            return false;
        }
    }
    true
}

fn test_different_lengths() -> bool {
    let master_key = crate::random_bytes(32);

    for len in [16, 24, 32, 48, 64] {
        let libsodium_key = derive_libsodium(&master_key, len, 1, b"testctx");
        let core_key = crypto::kdf::derive_subkey(&master_key, len, 1, b"testctx").unwrap();
        if libsodium_key != core_key {
            eprintln!("  Failed for len={}", len);
            return false;
        }
    }
    true
}

fn test_context_truncation() -> bool {
    let master_key = crate::random_bytes(32);

    // Context > 8 bytes should be truncated to first 8
    let long_ctx = b"verylongcontext";
    let truncated_ctx = b"verylong"; // first 8 bytes

    let libsodium_long = derive_libsodium(&master_key, 32, 1, long_ctx);
    let libsodium_truncated = derive_libsodium(&master_key, 32, 1, truncated_ctx);
    let core_long = crypto::kdf::derive_subkey(&master_key, 32, 1, long_ctx).unwrap();

    // All three should be equal
    libsodium_long == libsodium_truncated && libsodium_long == core_long
}

fn test_context_padding() -> bool {
    let master_key = crate::random_bytes(32);

    // Short contexts should be zero-padded
    let short_contexts: &[&[u8]] = &[b"a", b"ab", b"abc", b"test"];

    for ctx in short_contexts {
        let libsodium_key = derive_libsodium(&master_key, 32, 1, ctx);
        let core_key = crypto::kdf::derive_subkey(&master_key, 32, 1, ctx).unwrap();
        if libsodium_key != core_key {
            eprintln!(
                "  Failed for short context={:?}",
                String::from_utf8_lossy(ctx)
            );
            return false;
        }
    }
    true
}

fn test_empty_context() -> bool {
    let master_key = crate::random_bytes(32);

    let libsodium_key = derive_libsodium(&master_key, 32, 1, b"");
    let core_key = crypto::kdf::derive_subkey(&master_key, 32, 1, b"").unwrap();

    libsodium_key == core_key
}

fn test_random_keys() -> bool {
    for _ in 0..10 {
        let master_key = crate::random_bytes(32);
        let libsodium_key = derive_libsodium(&master_key, 32, 1, b"randtest");
        let core_key = crypto::kdf::derive_subkey(&master_key, 32, 1, b"randtest").unwrap();
        if libsodium_key != core_key {
            return false;
        }
    }
    true
}
