#![no_main]

use arbitrary::Arbitrary;
use libfuzzer_sys::fuzz_target;

#[derive(Arbitrary, Debug)]
struct SealedBoxInput {
    ciphertext: Vec<u8>,
    recipient_pk: [u8; 32],
    recipient_sk: [u8; 32],
}

fuzz_target!(|input: SealedBoxInput| {
    // Primary goal: ensure `open()` never panics on malformed inputs.
    let _ = ente_core::crypto::sealed::open(
        &input.ciphertext,
        &input.recipient_pk,
        &input.recipient_sk,
    );
});
