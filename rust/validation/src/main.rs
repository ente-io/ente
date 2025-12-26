//! Validation of ente-core pure Rust crypto against libsodium reference.
//!
//! This tool compares every cryptographic operation between:
//! - ente-core (pure Rust implementation)
//! - libsodium-sys (C library reference)
//!
//! Run with: cargo run -p ente-validation

use ente_core::crypto;
use libsodium_sys as sodium;

mod tests;

fn main() {
    println!("╔══════════════════════════════════════════════════════════════╗");
    println!("║     ente-core vs libsodium Validation Suite                  ║");
    println!("╚══════════════════════════════════════════════════════════════╝\n");

    // Initialize both libraries
    crypto::init().expect("Failed to init ente-core");
    unsafe {
        if sodium::sodium_init() < 0 {
            panic!("Failed to init libsodium");
        }
    }

    let results = vec![
        ("Argon2id", tests::argon2::run_all()),
        ("KDF (BLAKE2b)", tests::kdf::run_all()),
        ("SecretBox (XSalsa20-Poly1305)", tests::secretbox::run_all()),
        (
            "SealedBox (X25519 + XSalsa20-Poly1305)",
            tests::sealed::run_all(),
        ),
        ("BLAKE2b Hash", tests::hash::run_all()),
        ("Stream (XChaCha20-Poly1305)", tests::stream::run_all()),
        ("Full Auth Flow", tests::auth_flow::run_all()),
    ];

    println!("\n╔══════════════════════════════════════════════════════════════╗");
    println!("║                         SUMMARY                              ║");
    println!("╠══════════════════════════════════════════════════════════════╣");

    let mut total_passed = 0;
    let mut total_failed = 0;

    for (name, (passed, failed)) in &results {
        let status = if *failed == 0 { "✅" } else { "❌" };
        println!("║ {status} {name:<40} {passed:>3} passed, {failed:>3} failed ║",);
        total_passed += passed;
        total_failed += failed;
    }

    println!("╠══════════════════════════════════════════════════════════════╣");
    let final_status = if total_failed == 0 { "✅" } else { "❌" };
    println!(
        "║ {final_status} TOTAL{:>42} passed, {:>3} failed ║",
        total_passed, total_failed
    );
    println!("╚══════════════════════════════════════════════════════════════╝");

    if total_failed > 0 {
        std::process::exit(1);
    }
}

/// Helper to generate random bytes using libsodium
pub fn random_bytes(len: usize) -> Vec<u8> {
    let mut buf = vec![0u8; len];
    unsafe {
        sodium::randombytes_buf(buf.as_mut_ptr() as *mut _, len);
    }
    buf
}
