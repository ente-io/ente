//! Stream encryption (XChaCha20-Poly1305 secretstream) validation tests

use super::TestResult;
use crate::run_tests;
use ente_core::crypto;
use libsodium_sys as sodium;

const KEY_BYTES: usize = 32;
const HEADER_BYTES: usize = 24;
const TAG_MESSAGE: u8 = 0;
const TAG_PUSH: u8 = 1;
const TAG_REKEY: u8 = 2;
const TAG_FINAL: u8 = 3;

#[allow(dead_code)]
struct LibsodiumEncryptor {
    state: sodium::crypto_secretstream_xchacha20poly1305_state,
    header: Vec<u8>,
}

impl LibsodiumEncryptor {
    fn new(key: &[u8]) -> Self {
        let mut state = sodium::crypto_secretstream_xchacha20poly1305_state {
            k: [0u8; 32],
            nonce: [0u8; 12],
            _pad: [0u8; 8],
        };
        let mut header = vec![0u8; HEADER_BYTES];
        unsafe {
            sodium::crypto_secretstream_xchacha20poly1305_init_push(
                &mut state,
                header.as_mut_ptr(),
                key.as_ptr(),
            );
        }
        Self { state, header }
    }

    fn push(&mut self, plaintext: &[u8], tag: u8) -> Vec<u8> {
        let mut ciphertext = vec![0u8; plaintext.len() + 17];
        unsafe {
            sodium::crypto_secretstream_xchacha20poly1305_push(
                &mut self.state,
                ciphertext.as_mut_ptr(),
                std::ptr::null_mut(),
                plaintext.as_ptr(),
                plaintext.len() as u64,
                std::ptr::null(),
                0,
                tag,
            );
        }
        ciphertext
    }
}

struct LibsodiumDecryptor {
    state: sodium::crypto_secretstream_xchacha20poly1305_state,
}

impl LibsodiumDecryptor {
    fn new(key: &[u8], header: &[u8]) -> Option<Self> {
        let mut state = sodium::crypto_secretstream_xchacha20poly1305_state {
            k: [0u8; 32],
            nonce: [0u8; 12],
            _pad: [0u8; 8],
        };
        let result = unsafe {
            sodium::crypto_secretstream_xchacha20poly1305_init_pull(
                &mut state,
                header.as_ptr(),
                key.as_ptr(),
            )
        };
        if result == 0 {
            Some(Self { state })
        } else {
            None
        }
    }

    fn pull(&mut self, ciphertext: &[u8]) -> Option<(Vec<u8>, u8)> {
        if ciphertext.len() < 17 {
            return None;
        }
        let mut plaintext = vec![0u8; ciphertext.len() - 17];
        let mut tag: u8 = 0;
        let result = unsafe {
            sodium::crypto_secretstream_xchacha20poly1305_pull(
                &mut self.state,
                plaintext.as_mut_ptr(),
                std::ptr::null_mut(),
                &mut tag,
                ciphertext.as_ptr(),
                ciphertext.len() as u64,
                std::ptr::null(),
                0,
            )
        };
        if result == 0 {
            Some((plaintext, tag))
        } else {
            None
        }
    }
}

pub fn run_all() -> TestResult {
    println!("\n── Stream Encryption (XChaCha20-Poly1305) ──");
    run_tests! {
        "Single chunk roundtrip (core-only)" => test_single_chunk(),
        "Multi-chunk roundtrip (core-only)" => test_multi_chunk(),
        "Core encrypt, libsodium decrypt" => test_core_to_libsodium(),
        "Libsodium encrypt, core decrypt" => test_libsodium_to_core(),
        "Libsodium TAG_PUSH interop" => test_libsodium_push_tag(),
        "Libsodium TAG_REKEY interop" => test_libsodium_rekey_tag(),
        "Multi-chunk interop" => test_multi_chunk_interop(),
        "Empty plaintext interop" => test_empty_interop(),
        "Large plaintext interop (64KB)" => test_large_interop(),
        "File encryption exact chunk boundary" => test_file_encrypt_exact_chunk_boundary(),
        "File encryption exact two chunks boundary" => test_file_encrypt_exact_two_chunks_boundary(),
        "File decryption exact chunk boundary" => test_file_decrypt_exact_chunk_boundary(),
        "File decryption exact two chunks boundary" => test_file_decrypt_exact_two_chunks_boundary(),
    }
}

fn test_single_chunk() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = b"Single chunk test";

    let mut encryptor = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let ciphertext = encryptor.push(plaintext, false).unwrap();

    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();
    let (decrypted, tag) = decryptor.pull(&ciphertext).unwrap();

    decrypted == plaintext && tag == TAG_MESSAGE
}

fn test_multi_chunk() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let chunks = [b"First".to_vec(), b"Second".to_vec(), b"Third".to_vec()];

    let mut encryptor = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let mut encrypted_chunks = Vec::new();

    for (i, chunk) in chunks.iter().enumerate() {
        let is_final = i == chunks.len() - 1;
        encrypted_chunks.push(encryptor.push(chunk, is_final).unwrap());
    }

    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();

    for (i, (encrypted, original)) in encrypted_chunks.iter().zip(chunks.iter()).enumerate() {
        let (decrypted, tag) = decryptor.pull(encrypted).unwrap();
        if decrypted != *original {
            return false;
        }
        let expected_tag = if i == chunks.len() - 1 {
            TAG_FINAL
        } else {
            TAG_MESSAGE
        };
        if tag != expected_tag {
            return false;
        }
    }

    true
}

fn test_core_to_libsodium() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = b"Core to libsodium stream test";

    // Encrypt with core
    let mut encryptor = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let ciphertext = encryptor.push(plaintext, true).unwrap();

    // Decrypt with libsodium
    let mut decryptor = LibsodiumDecryptor::new(&key, &encryptor.header).unwrap();
    let (decrypted, tag) = decryptor.pull(&ciphertext).unwrap();

    decrypted == plaintext && tag == TAG_FINAL
}

fn test_libsodium_to_core() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = b"Libsodium to core stream test";

    // Encrypt with libsodium
    let mut encryptor = LibsodiumEncryptor::new(&key);
    let ciphertext = encryptor.push(plaintext, TAG_FINAL);

    // Decrypt with core
    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();
    let (decrypted, tag) = decryptor.pull(&ciphertext).unwrap();

    decrypted == plaintext && tag == TAG_FINAL
}

fn test_libsodium_push_tag() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let chunks = [b"Push tag chunk".to_vec(), b"Final chunk".to_vec()];

    // Encrypt with libsodium using TAG_PUSH then TAG_FINAL
    let mut encryptor = LibsodiumEncryptor::new(&key);
    let ct_push = encryptor.push(&chunks[0], TAG_PUSH);
    let ct_final = encryptor.push(&chunks[1], TAG_FINAL);

    // Decrypt with core and verify tags
    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();
    let (pt_push, tag_push) = decryptor.pull(&ct_push).unwrap();
    let (pt_final, tag_final) = decryptor.pull(&ct_final).unwrap();

    pt_push == chunks[0] && tag_push == TAG_PUSH && pt_final == chunks[1] && tag_final == TAG_FINAL
}

fn test_libsodium_rekey_tag() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let chunks = [b"Rekey chunk".to_vec(), b"After rekey".to_vec()];

    // Encrypt with libsodium using TAG_REKEY then TAG_FINAL
    let mut encryptor = LibsodiumEncryptor::new(&key);
    let ct_rekey = encryptor.push(&chunks[0], TAG_REKEY);
    let ct_final = encryptor.push(&chunks[1], TAG_FINAL);

    // Decrypt with core and verify tags
    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();
    let (pt_rekey, tag_rekey) = decryptor.pull(&ct_rekey).unwrap();
    let (pt_final, tag_final) = decryptor.pull(&ct_final).unwrap();

    pt_rekey == chunks[0]
        && tag_rekey == TAG_REKEY
        && pt_final == chunks[1]
        && tag_final == TAG_FINAL
}

fn test_multi_chunk_interop() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let chunks = [b"Alpha".to_vec(), b"Beta".to_vec(), b"Gamma".to_vec()];

    // Core encrypt, libsodium decrypt
    let mut core_enc = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let mut encrypted = Vec::new();
    for (i, chunk) in chunks.iter().enumerate() {
        let is_final = i == chunks.len() - 1;
        encrypted.push(core_enc.push(chunk, is_final).unwrap());
    }

    let mut ls_dec = LibsodiumDecryptor::new(&key, &core_enc.header).unwrap();
    for (i, (ct, original)) in encrypted.iter().zip(chunks.iter()).enumerate() {
        let (pt, tag) = ls_dec.pull(ct).unwrap();
        if pt != *original {
            return false;
        }
        let expected = if i == chunks.len() - 1 {
            TAG_FINAL
        } else {
            TAG_MESSAGE
        };
        if tag != expected {
            return false;
        }
    }

    // Libsodium encrypt, core decrypt
    let mut ls_enc = LibsodiumEncryptor::new(&key);
    let mut encrypted = Vec::new();
    for (i, chunk) in chunks.iter().enumerate() {
        let tag = if i == chunks.len() - 1 {
            TAG_FINAL
        } else {
            TAG_MESSAGE
        };
        encrypted.push(ls_enc.push(chunk, tag));
    }

    let mut core_dec = crypto::stream::StreamDecryptor::new(&ls_enc.header, &key).unwrap();
    for (i, (ct, original)) in encrypted.iter().zip(chunks.iter()).enumerate() {
        let (pt, tag) = core_dec.pull(ct).unwrap();
        if pt != *original {
            return false;
        }
        let expected = if i == chunks.len() - 1 {
            TAG_FINAL
        } else {
            TAG_MESSAGE
        };
        if tag != expected {
            return false;
        }
    }

    true
}

fn test_empty_interop() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = b"";

    // Core encrypt, libsodium decrypt
    let mut core_enc = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let ct = core_enc.push(plaintext, true).unwrap();
    let mut ls_dec = LibsodiumDecryptor::new(&key, &core_enc.header).unwrap();
    let (pt, tag) = ls_dec.pull(&ct).unwrap();
    if pt != plaintext || tag != TAG_FINAL {
        return false;
    }

    // Libsodium encrypt, core decrypt
    let mut ls_enc = LibsodiumEncryptor::new(&key);
    let ct = ls_enc.push(plaintext, TAG_FINAL);
    let mut core_dec = crypto::stream::StreamDecryptor::new(&ls_enc.header, &key).unwrap();
    let (pt, tag) = core_dec.pull(&ct).unwrap();

    pt == plaintext && tag == TAG_FINAL
}

fn test_large_interop() -> bool {
    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = crate::random_bytes(65536);

    // Core encrypt, libsodium decrypt
    let mut core_enc = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let ct = core_enc.push(&plaintext, true).unwrap();
    let mut ls_dec = LibsodiumDecryptor::new(&key, &core_enc.header).unwrap();
    let (pt, tag) = ls_dec.pull(&ct).unwrap();
    if pt != plaintext || tag != TAG_FINAL {
        return false;
    }

    // Libsodium encrypt, core decrypt
    let mut ls_enc = LibsodiumEncryptor::new(&key);
    let ct = ls_enc.push(&plaintext, TAG_FINAL);
    let mut core_dec = crypto::stream::StreamDecryptor::new(&ls_enc.header, &key).unwrap();
    let (pt, tag) = core_dec.pull(&ct).unwrap();

    pt == plaintext && tag == TAG_FINAL
}

fn test_file_encrypt_exact_chunk_boundary() -> bool {
    use std::io::Cursor;

    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = crate::random_bytes(crypto::stream::ENCRYPTION_CHUNK_SIZE);

    let mut ciphertext = Vec::new();
    let mut reader = Cursor::new(&plaintext);
    let (_returned_key, header) =
        crypto::stream::encrypt_file(&mut reader, &mut ciphertext, Some(&key)).unwrap();

    if ciphertext.len() != crypto::stream::DECRYPTION_CHUNK_SIZE {
        return false;
    }

    if ciphertext.len() != crypto::stream::estimate_encrypted_size(plaintext.len()) {
        return false;
    }

    let mut decryptor = LibsodiumDecryptor::new(&key, &header).unwrap();
    let (decrypted, tag) = decryptor.pull(&ciphertext).unwrap();

    decrypted == plaintext && tag == TAG_FINAL
}

fn test_file_encrypt_exact_two_chunks_boundary() -> bool {
    use std::io::Cursor;

    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = crate::random_bytes(crypto::stream::ENCRYPTION_CHUNK_SIZE * 2);

    let mut ciphertext = Vec::new();
    let mut reader = Cursor::new(&plaintext);
    let (_returned_key, header) =
        crypto::stream::encrypt_file(&mut reader, &mut ciphertext, Some(&key)).unwrap();

    let expected_len = 2 * crypto::stream::DECRYPTION_CHUNK_SIZE;
    if ciphertext.len() != expected_len {
        return false;
    }

    if ciphertext.len() != crypto::stream::estimate_encrypted_size(plaintext.len()) {
        return false;
    }

    let mut decryptor = LibsodiumDecryptor::new(&key, &header).unwrap();

    let (pt1, tag1) = decryptor
        .pull(&ciphertext[..crypto::stream::DECRYPTION_CHUNK_SIZE])
        .unwrap();
    let (pt2, tag2) = decryptor
        .pull(&ciphertext[crypto::stream::DECRYPTION_CHUNK_SIZE..])
        .unwrap();

    if tag1 != TAG_MESSAGE || tag2 != TAG_FINAL {
        return false;
    }

    let mut combined = Vec::with_capacity(pt1.len() + pt2.len());
    combined.extend_from_slice(&pt1);
    combined.extend_from_slice(&pt2);

    combined == plaintext
}

fn test_file_decrypt_exact_chunk_boundary() -> bool {
    use std::io::Cursor;

    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = crate::random_bytes(crypto::stream::ENCRYPTION_CHUNK_SIZE);

    let mut encryptor = LibsodiumEncryptor::new(&key);
    let ciphertext = encryptor.push(&plaintext, TAG_FINAL);

    let mut reader = Cursor::new(ciphertext);
    let mut decrypted = Vec::new();

    crypto::stream::decrypt_file(&mut reader, &mut decrypted, &encryptor.header, &key).is_ok()
        && decrypted == plaintext
}

fn test_file_decrypt_exact_two_chunks_boundary() -> bool {
    use std::io::Cursor;

    let key = crate::random_bytes(KEY_BYTES);
    let plaintext = crate::random_bytes(crypto::stream::ENCRYPTION_CHUNK_SIZE * 2);

    let chunk_size = crypto::stream::ENCRYPTION_CHUNK_SIZE;

    let mut encryptor = LibsodiumEncryptor::new(&key);
    let mut ciphertext = Vec::new();
    ciphertext.extend_from_slice(&encryptor.push(&plaintext[..chunk_size], TAG_MESSAGE));
    ciphertext.extend_from_slice(&encryptor.push(&plaintext[chunk_size..], TAG_FINAL));

    let mut reader = Cursor::new(ciphertext);
    let mut decrypted = Vec::new();

    crypto::stream::decrypt_file(&mut reader, &mut decrypted, &encryptor.header, &key).is_ok()
        && decrypted == plaintext
}
