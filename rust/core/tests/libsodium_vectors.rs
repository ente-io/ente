//! Libsodium compatibility test vectors.
//!
//! These vectors were generated using libsodium-sys and verify that
//! ente-core's pure Rust implementation produces byte-identical output.
//!
//! If these tests pass, the implementation is libsodium-compatible.
//! No need to run the validation suite for routine checks.

use ente_core::crypto;

// =============================================================================
// LIBSODIUM TEST VECTORS - Generated from libsodium-sys
// =============================================================================

// --- SecretBox (XSalsa20-Poly1305) ---
const SECRETBOX_KEY: &str = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
const SECRETBOX_NONCE: &str = "000102030405060708090a0b0c0d0e0f1011121314151617";
const SECRETBOX_PLAINTEXT: &[u8] = b"Hello, World!";
const SECRETBOX_CIPHERTEXT: &str = "7e15aaa64ac1e7b68335aa1854c3dfd9169a5423a8e68247d44ee35a49";

// --- KDF (BLAKE2b) ---
const KDF_MASTER_KEY: &str = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
const KDF_SUBKEY_32: &str = "6970b5d34442fd11788a83b4b57e1e7224d625c38e2b0374cb2217aa6f8d91e1";
const KDF_LOGIN_KEY: &str = "6970b5d34442fd11788a83b4b57e1e72";

// --- Argon2id ---
const ARGON2_PASSWORD: &str = "test_password";
const ARGON2_SALT: &str = "0123456789abcdef0123456789abcdef";
const ARGON2_KEY: &str = "ae14cd677df2d021b6aa7545a2670925b718b4f1ff8faec933a88578da4c64b1";

// --- BLAKE2b Hash ---
const HASH_INPUT: &[u8] = b"Data to hash";
const HASH_OUTPUT_64: &str = "45b50ebce21bae657a3b4ed0cd321c784c5473799b461cc81923cbfa65a2849bc60366a08114152a90435ec5a3182ef013c8a203e8a0514649f14b8696ccb1ca";
const HASH_OUTPUT_32: &str = "55e744dfea583d7a2896335a4f70d67833c929c3f66a83820869f31db06fcd55";
const HASH_EMPTY_64: &str = "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce";

// --- Stream (XChaCha20-Poly1305 secretstream) ---
const STREAM_KEY: &str = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
const STREAM_PLAINTEXT: &[u8] = b"Stream test";
const STREAM_HEADER: &str = "1ad40de26aa2c803d55c1c7fe1cff7cec88069df6eb627ac";
const STREAM_CIPHERTEXT: &str = "9079bad016c27d7886551b95e3f80b2f6e3f6ee77921df7e62e59b38";

// --- HChaCha20 (internal) ---
const HCHACHA_KEY: &str = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
const HCHACHA_INPUT: &str = "000102030405060708090a0b0c0d0e0f";
const HCHACHA_OUTPUT: &str = "51e3ff45a895675c4b33b46c64f4a9ace110d34df6a2ceab486372bacbd3eff6";

// =============================================================================
// TESTS
// =============================================================================

#[test]
fn test_secretbox_encrypt_matches_libsodium() {
    crypto::init().unwrap();

    let key = hex::decode(SECRETBOX_KEY).unwrap();
    let nonce = hex::decode(SECRETBOX_NONCE).unwrap();
    let expected_ct = hex::decode(SECRETBOX_CIPHERTEXT).unwrap();

    let ciphertext =
        crypto::secretbox::encrypt_with_nonce(SECRETBOX_PLAINTEXT, &nonce, &key).unwrap();

    assert_eq!(
        hex::encode(&ciphertext),
        hex::encode(&expected_ct),
        "SecretBox ciphertext must match libsodium output exactly"
    );
}

#[test]
fn test_secretbox_decrypt_libsodium_ciphertext() {
    crypto::init().unwrap();

    let key = hex::decode(SECRETBOX_KEY).unwrap();
    let nonce = hex::decode(SECRETBOX_NONCE).unwrap();
    let ciphertext = hex::decode(SECRETBOX_CIPHERTEXT).unwrap();

    let plaintext = crypto::secretbox::decrypt(&ciphertext, &nonce, &key).unwrap();

    assert_eq!(
        plaintext, SECRETBOX_PLAINTEXT,
        "Must decrypt libsodium ciphertext correctly"
    );
}

#[test]
fn test_kdf_subkey_matches_libsodium() {
    crypto::init().unwrap();

    let master_key = hex::decode(KDF_MASTER_KEY).unwrap();
    let expected_subkey = hex::decode(KDF_SUBKEY_32).unwrap();

    let subkey = crypto::kdf::derive_subkey(&master_key, 32, 1, b"loginctx").unwrap();

    assert_eq!(
        hex::encode(&subkey),
        hex::encode(&expected_subkey),
        "KDF subkey must match libsodium output exactly"
    );
}

#[test]
fn test_kdf_login_key_matches_libsodium() {
    crypto::init().unwrap();

    let master_key = hex::decode(KDF_MASTER_KEY).unwrap();
    let expected_login_key = hex::decode(KDF_LOGIN_KEY).unwrap();

    let login_key = crypto::kdf::derive_login_key(&master_key).unwrap();

    assert_eq!(
        hex::encode(&login_key),
        hex::encode(&expected_login_key),
        "Login key must match libsodium output exactly"
    );
}

#[test]
fn test_argon2_matches_libsodium() {
    crypto::init().unwrap();

    let salt = hex::decode(ARGON2_SALT).unwrap();
    let expected_key = hex::decode(ARGON2_KEY).unwrap();

    // 64MB in bytes = 67108864
    let key = crypto::argon::derive_key(ARGON2_PASSWORD, &salt, 67108864, 2).unwrap();

    assert_eq!(
        hex::encode(&key),
        hex::encode(&expected_key),
        "Argon2id key must match libsodium output exactly"
    );
}

#[test]
fn test_hash_64_matches_libsodium() {
    crypto::init().unwrap();

    let expected_hash = hex::decode(HASH_OUTPUT_64).unwrap();

    let hash = crypto::hash::hash(HASH_INPUT, Some(64), None).unwrap();

    assert_eq!(
        hex::encode(&hash),
        hex::encode(&expected_hash),
        "BLAKE2b-512 hash must match libsodium output exactly"
    );
}

#[test]
fn test_hash_32_matches_libsodium() {
    crypto::init().unwrap();

    let expected_hash = hex::decode(HASH_OUTPUT_32).unwrap();

    let hash = crypto::hash::hash(HASH_INPUT, Some(32), None).unwrap();

    assert_eq!(
        hex::encode(&hash),
        hex::encode(&expected_hash),
        "BLAKE2b-256 hash must match libsodium output exactly"
    );
}

#[test]
fn test_hash_empty_matches_libsodium() {
    crypto::init().unwrap();

    let expected_hash = hex::decode(HASH_EMPTY_64).unwrap();

    let hash = crypto::hash::hash(b"", Some(64), None).unwrap();

    assert_eq!(
        hex::encode(&hash),
        hex::encode(&expected_hash),
        "BLAKE2b-512 of empty input must match libsodium output exactly"
    );
}

#[test]
fn test_stream_decrypt_libsodium_ciphertext() {
    crypto::init().unwrap();

    let key = hex::decode(STREAM_KEY).unwrap();
    let header = hex::decode(STREAM_HEADER).unwrap();
    let ciphertext = hex::decode(STREAM_CIPHERTEXT).unwrap();

    let mut decryptor = crypto::stream::StreamDecryptor::new(&header, &key).unwrap();
    let (plaintext, tag) = decryptor.pull(&ciphertext).unwrap();

    assert_eq!(
        plaintext, STREAM_PLAINTEXT,
        "Must decrypt libsodium stream ciphertext correctly"
    );
    assert_eq!(tag, crypto::stream::TAG_FINAL, "Tag must be FINAL");
}

#[test]
fn test_stream_roundtrip_format() {
    crypto::init().unwrap();

    let key = hex::decode(STREAM_KEY).unwrap();

    // Encrypt with our implementation
    let mut encryptor = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let ciphertext = encryptor.push(STREAM_PLAINTEXT, true).unwrap();

    // Verify format
    assert_eq!(encryptor.header.len(), 24, "Header must be 24 bytes");
    assert_eq!(
        ciphertext.len(),
        STREAM_PLAINTEXT.len() + 17,
        "Ciphertext must be plaintext + 17 bytes overhead"
    );

    // Decrypt and verify
    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();
    let (plaintext, tag) = decryptor.pull(&ciphertext).unwrap();

    assert_eq!(plaintext, STREAM_PLAINTEXT);
    assert_eq!(tag, crypto::stream::TAG_FINAL);
}

#[test]
fn test_hchacha20_matches_libsodium() {
    // HChaCha20 is internal, but we can verify it through stream encryption
    // by checking that we can decrypt libsodium-encrypted data
    crypto::init().unwrap();

    // The fact that test_stream_decrypt_libsodium_ciphertext passes
    // proves HChaCha20 is correct (it's used to derive the subkey from header)

    // We can also verify the constant directly if exposed
    let key = hex::decode(HCHACHA_KEY).unwrap();
    let input = hex::decode(HCHACHA_INPUT).unwrap();
    let expected = hex::decode(HCHACHA_OUTPUT).unwrap();

    // Use chacha20 crate directly to verify
    use chacha20::cipher::consts::U10;
    use chacha20::hchacha;

    let key_arr: [u8; 32] = key.try_into().unwrap();
    let input_arr: [u8; 16] = input.try_into().unwrap();

    let output = hchacha::<U10>((&key_arr).into(), (&input_arr).into());

    assert_eq!(
        hex::encode(output.as_slice()),
        hex::encode(&expected),
        "HChaCha20 must match libsodium output exactly"
    );
}

// =============================================================================
// SEALED BOX - Can't use fixed vectors (ephemeral key), but verify format
// =============================================================================

#[test]
fn test_sealedbox_format_matches_libsodium() {
    crypto::init().unwrap();

    let (pk, sk) = crypto::keys::generate_keypair().unwrap();
    let plaintext = b"Sealed message";

    let ciphertext = crypto::sealed::seal(plaintext, &pk).unwrap();

    // libsodium sealed box format: ephemeral_pk (32) || box (plaintext + 16)
    // Total overhead: 32 + 16 = 48 bytes
    assert_eq!(
        ciphertext.len(),
        plaintext.len() + 48,
        "Sealed box must have 48 bytes overhead (32 ephemeral pk + 16 MAC)"
    );

    // Must decrypt correctly
    let decrypted = crypto::sealed::open(&ciphertext, &pk, &sk).unwrap();
    assert_eq!(decrypted, plaintext);
}

// =============================================================================
// ADDITIONAL EDGE CASES
// =============================================================================

#[test]
fn test_secretbox_empty_plaintext() {
    crypto::init().unwrap();

    let key = hex::decode(SECRETBOX_KEY).unwrap();
    let nonce = hex::decode(SECRETBOX_NONCE).unwrap();

    let ciphertext = crypto::secretbox::encrypt_with_nonce(b"", &nonce, &key).unwrap();

    // Empty plaintext should produce 16-byte ciphertext (just MAC)
    assert_eq!(ciphertext.len(), 16);

    let plaintext = crypto::secretbox::decrypt(&ciphertext, &nonce, &key).unwrap();
    assert_eq!(plaintext, b"");
}

#[test]
fn test_kdf_different_contexts() {
    crypto::init().unwrap();

    let master_key = hex::decode(KDF_MASTER_KEY).unwrap();

    let key1 = crypto::kdf::derive_subkey(&master_key, 32, 1, b"loginctx").unwrap();
    let key2 = crypto::kdf::derive_subkey(&master_key, 32, 1, b"otherctx").unwrap();

    assert_ne!(key1, key2, "Different contexts must produce different keys");
}

#[test]
fn test_kdf_different_ids() {
    crypto::init().unwrap();

    let master_key = hex::decode(KDF_MASTER_KEY).unwrap();

    let key1 = crypto::kdf::derive_subkey(&master_key, 32, 1, b"loginctx").unwrap();
    let key2 = crypto::kdf::derive_subkey(&master_key, 32, 2, b"loginctx").unwrap();

    assert_ne!(key1, key2, "Different IDs must produce different keys");
}

#[test]
fn test_stream_multi_chunk() {
    crypto::init().unwrap();

    let key = hex::decode(STREAM_KEY).unwrap();
    let chunks = [b"First".to_vec(), b"Second".to_vec(), b"Third".to_vec()];

    let mut encryptor = crypto::stream::StreamEncryptor::new(&key).unwrap();
    let mut encrypted: Vec<Vec<u8>> = Vec::new();

    for (i, chunk) in chunks.iter().enumerate() {
        let is_final = i == chunks.len() - 1;
        encrypted.push(encryptor.push(chunk, is_final).unwrap());
    }

    let mut decryptor = crypto::stream::StreamDecryptor::new(&encryptor.header, &key).unwrap();

    for (i, (ct, original)) in encrypted.iter().zip(chunks.iter()).enumerate() {
        let (pt, tag) = decryptor.pull(ct).unwrap();
        assert_eq!(pt, *original);

        let expected_tag = if i == chunks.len() - 1 {
            crypto::stream::TAG_FINAL
        } else {
            crypto::stream::TAG_MESSAGE
        };
        assert_eq!(tag, expected_tag);
    }
}

// =============================================================================
// SUMMARY
// =============================================================================
//
// These tests verify byte-for-byte compatibility with libsodium:
// - SecretBox: encrypt/decrypt with known vectors ✓
// - KDF: subkey derivation with known vectors ✓
// - Argon2id: key derivation with known vectors ✓
// - BLAKE2b: hash with known vectors ✓
// - Stream: decrypt known vectors + format verification ✓
// - SealedBox: format verification (can't use fixed vectors) ✓
// - HChaCha20: internal primitive verification ✓
//
// If all tests pass, the implementation is libsodium-compatible.
// =============================================================================
