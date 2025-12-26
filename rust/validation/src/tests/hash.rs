//! BLAKE2b hash validation tests

use super::TestResult;
use crate::run_tests;
use ente_core::crypto;
use libsodium_sys as sodium;

pub fn run_all() -> TestResult {
    println!("\n── BLAKE2b Hash ──");
    run_tests! {
        "Default hash (64 bytes)" => test_default_hash(),
        "Custom output lengths" => test_custom_lengths(),
        "Keyed hash" => test_keyed_hash(),
        "Empty input" => test_empty_input(),
        "Large input (1MB)" => test_large_input(),
        "Known test vector" => test_known_vector(),
        "Random data (100 iterations)" => test_random_data(),
    }
}

fn libsodium_hash(data: &[u8], out_len: usize) -> Vec<u8> {
    let mut hash = vec![0u8; out_len];
    let result = unsafe {
        sodium::crypto_generichash(
            hash.as_mut_ptr(),
            out_len,
            data.as_ptr(),
            data.len() as u64,
            std::ptr::null(),
            0,
        )
    };
    assert_eq!(result, 0, "libsodium hash failed");
    hash
}

fn libsodium_hash_keyed(data: &[u8], key: &[u8], out_len: usize) -> Vec<u8> {
    let mut hash = vec![0u8; out_len];
    let result = unsafe {
        sodium::crypto_generichash(
            hash.as_mut_ptr(),
            out_len,
            data.as_ptr(),
            data.len() as u64,
            key.as_ptr(),
            key.len(),
        )
    };
    assert_eq!(result, 0, "libsodium keyed hash failed");
    hash
}

fn test_default_hash() -> bool {
    let data = b"Hello, World!";

    let libsodium_hash = libsodium_hash(data, 64);
    let core_hash = crypto::hash::hash_default(data).unwrap();

    libsodium_hash == core_hash
}

fn test_custom_lengths() -> bool {
    let data = b"Custom length test";

    for len in [16, 24, 32, 48, 64] {
        let libsodium_h = libsodium_hash(data, len);
        let core_h = crypto::hash::hash(data, Some(len), None).unwrap();
        if libsodium_h != core_h {
            eprintln!("  Failed for length={}", len);
            return false;
        }
    }
    true
}

fn test_keyed_hash() -> bool {
    let data = b"Keyed hash test";
    let key = crate::random_bytes(32);

    let libsodium_h = libsodium_hash_keyed(data, &key, 64);
    let core_h = crypto::hash::hash(data, None, Some(&key)).unwrap();

    libsodium_h == core_h
}

fn test_empty_input() -> bool {
    let data = b"";

    let libsodium_h = libsodium_hash(data, 64);
    let core_h = crypto::hash::hash_default(data).unwrap();

    libsodium_h == core_h
}

fn test_large_input() -> bool {
    let data = crate::random_bytes(1024 * 1024); // 1MB

    let libsodium_h = libsodium_hash(&data, 64);
    let core_h = crypto::hash::hash_default(&data).unwrap();

    libsodium_h == core_h
}

fn test_known_vector() -> bool {
    // BLAKE2b test vector from RFC 7693
    let data = b"abc";

    let libsodium_h = libsodium_hash(data, 64);
    let core_h = crypto::hash::hash_default(data).unwrap();

    // Both should match
    if libsodium_h != core_h {
        return false;
    }

    // Check known value (BLAKE2b-512 of "abc")
    let expected = hex::decode(
        "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d1\
         7d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923",
    )
    .unwrap();

    libsodium_h == expected && core_h == expected
}

fn test_random_data() -> bool {
    for _ in 0..100 {
        let data = crate::random_bytes(rand::random::<usize>() % 10000 + 1);

        let libsodium_h = libsodium_hash(&data, 64);
        let core_h = crypto::hash::hash_default(&data).unwrap();

        if libsodium_h != core_h {
            return false;
        }
    }
    true
}
