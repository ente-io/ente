//! SealedBox (X25519 + XSalsa20-Poly1305) validation tests

use super::TestResult;
use crate::run_tests;
use ente_core::crypto;
use libsodium_sys as sodium;

const PUBLIC_KEY_BYTES: usize = 32;
const SECRET_KEY_BYTES: usize = 32;
const SEAL_BYTES: usize = 48; // 32 (ephemeral pk) + 16 (MAC)

pub fn run_all() -> TestResult {
    println!("\n── SealedBox (X25519 + XSalsa20-Poly1305) ──");
    run_tests! {
        "Keypair generation compatible" => test_keypair_generation(),
        "Core seal, libsodium open" => test_core_to_libsodium(),
        "Libsodium seal, core open" => test_libsodium_to_core(),
        "Empty plaintext" => test_empty_plaintext(),
        "Large plaintext (1MB)" => test_large_plaintext(),
        "Random data (50 iterations)" => test_random_data(),
        "Wrong key fails" => test_wrong_key(),
    }
}

fn libsodium_keypair() -> (Vec<u8>, Vec<u8>) {
    let mut pk = vec![0u8; PUBLIC_KEY_BYTES];
    let mut sk = vec![0u8; SECRET_KEY_BYTES];
    unsafe {
        sodium::crypto_box_keypair(pk.as_mut_ptr(), sk.as_mut_ptr());
    }
    (pk, sk)
}

fn libsodium_seal(plaintext: &[u8], recipient_pk: &[u8]) -> Vec<u8> {
    let mut ciphertext = vec![0u8; plaintext.len() + SEAL_BYTES];
    let result = unsafe {
        sodium::crypto_box_seal(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            recipient_pk.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium seal failed");
    ciphertext
}

fn libsodium_open(ciphertext: &[u8], pk: &[u8], sk: &[u8]) -> Option<Vec<u8>> {
    if ciphertext.len() < SEAL_BYTES {
        return None;
    }
    let mut plaintext = vec![0u8; ciphertext.len() - SEAL_BYTES];
    let result = unsafe {
        sodium::crypto_box_seal_open(
            plaintext.as_mut_ptr(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            pk.as_ptr(),
            sk.as_ptr(),
        )
    };
    if result == 0 {
        Some(plaintext)
    } else {
        None
    }
}

fn test_keypair_generation() -> bool {
    // Generate keypair with core
    let (core_pk, core_sk) = crypto::keys::generate_keypair().unwrap();

    // Test that core keypair works with libsodium
    let plaintext = b"Keypair test";
    let sealed = libsodium_seal(plaintext, &core_pk);
    let opened = libsodium_open(&sealed, &core_pk, &core_sk);

    opened == Some(plaintext.to_vec())
}

fn test_core_to_libsodium() -> bool {
    let (pk, sk) = libsodium_keypair();
    let plaintext = b"Core to libsodium sealed box";

    let sealed = crypto::sealed::seal(plaintext, &pk).unwrap();
    let opened = libsodium_open(&sealed, &pk, &sk);

    opened == Some(plaintext.to_vec())
}

fn test_libsodium_to_core() -> bool {
    let (pk, sk) = crypto::keys::generate_keypair().unwrap();
    let plaintext = b"Libsodium to core sealed box";

    let sealed = libsodium_seal(plaintext, &pk);
    let opened = crypto::sealed::open(&sealed, &pk, &sk);

    opened.ok() == Some(plaintext.to_vec())
}

fn test_empty_plaintext() -> bool {
    let (pk, sk) = crypto::keys::generate_keypair().unwrap();
    let plaintext = b"";

    // Core seal, libsodium open
    let sealed1 = crypto::sealed::seal(plaintext, &pk).unwrap();
    let opened1 = libsodium_open(&sealed1, &pk, &sk);

    // Libsodium seal, core open
    let sealed2 = libsodium_seal(plaintext, &pk);
    let opened2 = crypto::sealed::open(&sealed2, &pk, &sk);

    opened1 == Some(vec![]) && opened2.ok() == Some(vec![])
}

fn test_large_plaintext() -> bool {
    let (pk, sk) = crypto::keys::generate_keypair().unwrap();
    let plaintext = crate::random_bytes(1024 * 1024); // 1MB

    // Core seal, libsodium open
    let sealed = crypto::sealed::seal(&plaintext, &pk).unwrap();
    let opened = libsodium_open(&sealed, &pk, &sk);

    if opened != Some(plaintext.clone()) {
        return false;
    }

    // Libsodium seal, core open
    let sealed = libsodium_seal(&plaintext, &pk);
    let opened = crypto::sealed::open(&sealed, &pk, &sk);

    opened.ok() == Some(plaintext)
}

fn test_random_data() -> bool {
    for _ in 0..50 {
        let (pk, sk) = crypto::keys::generate_keypair().unwrap();
        let plaintext = crate::random_bytes(rand::random::<usize>() % 1000 + 1);

        // Core seal, libsodium open
        let sealed = crypto::sealed::seal(&plaintext, &pk).unwrap();
        if libsodium_open(&sealed, &pk, &sk) != Some(plaintext.clone()) {
            return false;
        }

        // Libsodium seal, core open
        let sealed = libsodium_seal(&plaintext, &pk);
        if crypto::sealed::open(&sealed, &pk, &sk).ok() != Some(plaintext) {
            return false;
        }
    }
    true
}

fn test_wrong_key() -> bool {
    let (pk1, _sk1) = crypto::keys::generate_keypair().unwrap();
    let (_pk2, sk2) = crypto::keys::generate_keypair().unwrap();
    let plaintext = b"Wrong key test";

    let sealed = crypto::sealed::seal(plaintext, &pk1).unwrap();

    // Should fail with wrong secret key
    let result1 = libsodium_open(&sealed, &pk1, &sk2);
    let result2 = crypto::sealed::open(&sealed, &pk1, &sk2);

    result1.is_none() && result2.is_err()
}
