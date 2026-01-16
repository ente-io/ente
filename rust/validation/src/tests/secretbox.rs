//! SecretBox (XSalsa20-Poly1305) validation tests

use super::TestResult;
use crate::run_tests;
use ente_core::crypto;
use libsodium_sys as sodium;

const KEY_BYTES: usize = 32;
const NONCE_BYTES: usize = 24;
const MAC_BYTES: usize = 16;

pub fn run_all() -> TestResult {
    println!("\n── SecretBox (XSalsa20-Poly1305) ──");
    run_tests! {
        "Encrypt then decrypt (roundtrip)" => test_roundtrip(),
        "Core encrypt, libsodium decrypt" => test_core_to_libsodium(),
        "Libsodium encrypt, core decrypt" => test_libsodium_to_core(),
        "Ciphertext format matches" => test_ciphertext_format(),
        "Empty plaintext" => test_empty_plaintext(),
        "Large plaintext (1MB)" => test_large_plaintext(),
        "Random data (100 iterations)" => test_random_data(),
        "Tampered ciphertext fails" => test_tampered_ciphertext(),
    }
}

fn libsodium_encrypt(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Vec<u8> {
    let mut ciphertext = vec![0u8; plaintext.len() + MAC_BYTES];
    let result = unsafe {
        sodium::crypto_secretbox_easy(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium encrypt failed");
    ciphertext
}

fn libsodium_decrypt(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Option<Vec<u8>> {
    if ciphertext.len() < MAC_BYTES {
        return None;
    }
    let mut plaintext = vec![0u8; ciphertext.len() - MAC_BYTES];
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

fn test_roundtrip() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let nonce = crate::random_bytes(NONCE_BYTES);
    let plaintext = b"Hello, World!";

    let ciphertext = crypto::secretbox::encrypt_with_nonce(plaintext, &nonce, &key).unwrap();
    let decrypted = crypto::secretbox::decrypt(&ciphertext, &nonce, &key).unwrap();

    plaintext.to_vec() == decrypted
}

fn test_core_to_libsodium() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let nonce = crate::random_bytes(NONCE_BYTES);
    let plaintext = b"Core to libsodium test";

    let ciphertext = crypto::secretbox::encrypt_with_nonce(plaintext, &nonce, &key).unwrap();
    let decrypted = libsodium_decrypt(&ciphertext, &nonce, &key);

    decrypted == Some(plaintext.to_vec())
}

fn test_libsodium_to_core() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let nonce = crate::random_bytes(NONCE_BYTES);
    let plaintext = b"Libsodium to core test";

    let ciphertext = libsodium_encrypt(plaintext, &nonce, &key);
    let decrypted = crypto::secretbox::decrypt(&ciphertext, &nonce, &key);

    decrypted.ok() == Some(plaintext.to_vec())
}

fn test_ciphertext_format() -> bool {
    let key = vec![0u8; KEY_BYTES];
    let nonce = vec![0u8; NONCE_BYTES];
    let plaintext = b"Format test";

    let core_ct = crypto::secretbox::encrypt_with_nonce(plaintext, &nonce, &key).unwrap();
    let libsodium_ct = libsodium_encrypt(plaintext, &nonce, &key);

    // Debug output
    if core_ct != libsodium_ct {
        eprintln!(
            "  Core     ({} bytes): {:02x?}",
            core_ct.len(),
            &core_ct[..core_ct.len().min(32)]
        );
        eprintln!(
            "  Libsodium({} bytes): {:02x?}",
            libsodium_ct.len(),
            &libsodium_ct[..libsodium_ct.len().min(32)]
        );
    }

    // Both should produce identical ciphertext
    core_ct == libsodium_ct
}

fn test_empty_plaintext() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let nonce = crate::random_bytes(NONCE_BYTES);
    let plaintext = b"";

    let core_ct = crypto::secretbox::encrypt_with_nonce(plaintext, &nonce, &key).unwrap();
    let libsodium_ct = libsodium_encrypt(plaintext, &nonce, &key);

    if core_ct != libsodium_ct {
        return false;
    }

    // Both should decrypt correctly
    let core_dec = crypto::secretbox::decrypt(&core_ct, &nonce, &key).unwrap();
    let libsodium_dec = libsodium_decrypt(&libsodium_ct, &nonce, &key).unwrap();

    core_dec.is_empty() && libsodium_dec.is_empty()
}

fn test_large_plaintext() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let nonce = crate::random_bytes(NONCE_BYTES);
    let plaintext = crate::random_bytes(1024 * 1024); // 1MB

    let core_ct = crypto::secretbox::encrypt_with_nonce(&plaintext, &nonce, &key).unwrap();
    let libsodium_ct = libsodium_encrypt(&plaintext, &nonce, &key);

    // Ciphertext should match
    if core_ct != libsodium_ct {
        return false;
    }

    // Cross-decrypt should work
    let dec1 = libsodium_decrypt(&core_ct, &nonce, &key).unwrap();
    let dec2 = crypto::secretbox::decrypt(&libsodium_ct, &nonce, &key).unwrap();

    dec1 == plaintext && dec2 == plaintext
}

fn test_random_data() -> bool {
    for _ in 0..100 {
        let key = crate::random_bytes(KEY_BYTES);
        let nonce = crate::random_bytes(NONCE_BYTES);
        let plaintext = crate::random_bytes(rand::random::<usize>() % 1000 + 1);

        let core_ct = crypto::secretbox::encrypt_with_nonce(&plaintext, &nonce, &key).unwrap();
        let libsodium_ct = libsodium_encrypt(&plaintext, &nonce, &key);

        if core_ct != libsodium_ct {
            return false;
        }
    }
    true
}

fn test_tampered_ciphertext() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let nonce = crate::random_bytes(NONCE_BYTES);
    let plaintext = b"Tamper test";

    let mut ciphertext = libsodium_encrypt(plaintext, &nonce, &key);

    // Tamper with ciphertext
    ciphertext[0] ^= 0xff;

    // Both should fail to decrypt
    let core_result = crypto::secretbox::decrypt(&ciphertext, &nonce, &key);
    let libsodium_result = libsodium_decrypt(&ciphertext, &nonce, &key);

    core_result.is_err() && libsodium_result.is_none()
}
