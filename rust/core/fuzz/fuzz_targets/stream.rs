#![no_main]

use arbitrary::Arbitrary;
use libfuzzer_sys::fuzz_target;

#[derive(Arbitrary, Debug)]
struct StreamInput {
    header: [u8; 24],
    key: [u8; 32],
    ciphertext: Vec<u8>,
    ad: Vec<u8>,
}

fuzz_target!(|input: StreamInput| {
    // Primary goal: ensure secretstream parsing/decryption never panics.
    if let Ok(mut decryptor) = ente_core::crypto::stream::StreamDecryptor::new(&input.header, &input.key)
    {
        let _ = decryptor.pull_with_ad(&input.ciphertext, &input.ad);
        let _ = decryptor.pull_typed_with_ad(&input.ciphertext, &input.ad);
    }
});
