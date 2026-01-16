#![no_main]

use arbitrary::Arbitrary;
use libfuzzer_sys::fuzz_target;

#[derive(Arbitrary, Debug)]
struct SecretBoxInput {
    plaintext: Vec<u8>,
    key: [u8; 32],
    nonce: [u8; 24],
    flip_bit: bool,
}

fuzz_target!(|input: SecretBoxInput| {
    // Roundtrip: encrypt_with_nonce is deterministic, so fuzzing stays reproducible.
    if let Ok(ciphertext) = ente_core::crypto::secretbox::encrypt_with_nonce(
        &input.plaintext,
        &input.nonce,
        &input.key,
    ) {
        let mut ct = ciphertext;

        // Optional: corrupt a byte to exercise error paths.
        if input.flip_bit && !ct.is_empty() {
            ct[0] ^= 0x01;
        }

        let decrypted = ente_core::crypto::secretbox::decrypt(&ct, &input.nonce, &input.key);

        if input.flip_bit {
            // Corruption should fail (unless ciphertext was empty, which never happens: MAC is
            // always present, so ct is at least 16 bytes).
            assert!(decrypted.is_err());
        } else {
            assert_eq!(decrypted.unwrap(), input.plaintext);
        }
    }
});
