#![no_main]

use arbitrary::Arbitrary;
use libfuzzer_sys::fuzz_target;

#[derive(Arbitrary, Debug)]
struct ArgonInput {
    password: Vec<u8>,
    salt: [u8; 16],
    mem_kib: u16,
    ops: u8,
}

fuzz_target!(|input: ArgonInput| {
    // Clamp to values that are fast enough for fuzzing.
    let mem_limit = 8_192u32 + (u32::from(input.mem_kib % 64) * 1024); // 8 KiB .. 72 KiB
    let ops_limit = 1u32 + (u32::from(input.ops % 5)); // 1..=5

    let password = String::from_utf8_lossy(&input.password);
    let _ = ente_core::crypto::argon::derive_key(password.as_ref(), &input.salt, mem_limit, ops_limit);
});
