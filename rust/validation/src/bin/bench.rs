//! Simple crypto benchmarks for ente-core (pure Rust) vs libsodium-sys.
//!
//! Run with:
//!   cargo run -p ente-validation --bin bench

use std::collections::BTreeMap;
use std::ffi::c_char;
use std::hint::black_box;
use std::time::{Duration, Instant};

use base64::{engine::general_purpose::STANDARD, Engine};
use ente_core::auth::{
    decrypt_secrets, derive_kek, generate_keys_with_strength, KeyAttributes, KeyDerivationStrength,
};
use ente_core::crypto;
use libsodium_sys as sodium;
use serde::Serialize;

const MB: usize = 1024 * 1024;
const STREAM_CHUNK: usize = 64 * 1024;

const ARGON_MEM: u32 = 67_108_864; // 64 MiB
const ARGON_OPS: u32 = 2;

const AUTH_TOKEN: &[u8] = b"benchmark-auth-token";

const SECRETBOX_KEY_BYTES: usize = 32;
const SECRETBOX_NONCE_BYTES: usize = 24;

const STREAM_KEY_BYTES: usize = 32;
const STREAM_HEADER_BYTES: usize = 24;
const STREAM_ABYTES: usize = 17;
const STREAM_TAG_MESSAGE: u8 = 0;
const STREAM_TAG_FINAL: u8 = 3;

struct BenchResult {
    case: &'static str,
    implementation: &'static str,
    operation: &'static str,
    size_bytes: usize,
    iterations: usize,
    duration: Duration,
}

impl BenchResult {
    fn ms_per_op(&self) -> f64 {
        self.duration.as_secs_f64() * 1000.0 / self.iterations as f64
    }

    fn size_display(&self) -> String {
        if self.size_bytes == 0 {
            "n/a".to_string()
        } else {
            format!("{:.1}MiB", self.size_bytes as f64 / MB as f64)
        }
    }

    fn rate(&self) -> (&'static str, f64) {
        let seconds = self.duration.as_secs_f64();
        if self.size_bytes == 0 {
            ("ops/s", self.iterations as f64 / seconds)
        } else {
            let mib = self.size_bytes as f64 / MB as f64;
            ("MiB/s", mib * self.iterations as f64 / seconds)
        }
    }
}

#[derive(Serialize)]
struct BenchResultJson {
    case: &'static str,
    implementation: &'static str,
    operation: &'static str,
    size_bytes: usize,
    iterations: usize,
    duration_ms: f64,
}

struct CoreAuthArtifacts {
    key_attrs: KeyAttributes,
    encrypted_token: String,
}

struct LibsodiumAuthArtifacts {
    kek_salt_b64: String,
    mem_limit: u32,
    ops_limit: u32,
    encrypted_key_b64: String,
    key_nonce_b64: String,
    public_key_b64: String,
    encrypted_secret_key_b64: String,
    secret_key_nonce_b64: String,
    encrypted_token_b64: String,
}

fn write_json_if_requested(results: &[BenchResult]) {
    let path = match std::env::var("BENCH_JSON") {
        Ok(value) if !value.trim().is_empty() => value,
        _ => return,
    };

    let json_results: Vec<BenchResultJson> = results
        .iter()
        .map(|result| BenchResultJson {
            case: result.case,
            implementation: result.implementation,
            operation: result.operation,
            size_bytes: result.size_bytes,
            iterations: result.iterations,
            duration_ms: result.duration.as_secs_f64() * 1000.0,
        })
        .collect();

    let payload = serde_json::json!({ "results": json_results });
    let contents =
        serde_json::to_string_pretty(&payload).expect("Failed to serialize benchmark results");
    std::fs::write(&path, contents).expect("Failed to write benchmark JSON output");
}

fn main() {
    println!("╔══════════════════════════════════════════════════════════════╗");
    println!("║     ente-core vs libsodium Benchmark Suite                  ║");
    println!("╚══════════════════════════════════════════════════════════════╝\n");

    crypto::init().expect("Failed to init ente-core");
    unsafe {
        if sodium::sodium_init() < 0 {
            panic!("Failed to init libsodium");
        }
    }

    let mut results = Vec::new();

    // SecretBox (1 MiB)
    let secretbox_data = vec![0x2a; MB];
    let secretbox_key = vec![0x11; SECRETBOX_KEY_BYTES];
    let secretbox_nonce = vec![0x22; SECRETBOX_NONCE_BYTES];
    let secretbox_iters = 50;

    results.push(bench_secretbox_core_encrypt(
        &secretbox_data,
        &secretbox_key,
        &secretbox_nonce,
        secretbox_iters,
    ));
    results.push(bench_secretbox_core_decrypt(
        &secretbox_data,
        &secretbox_key,
        &secretbox_nonce,
        secretbox_iters,
    ));
    results.push(bench_secretbox_libsodium_encrypt(
        &secretbox_data,
        &secretbox_key,
        &secretbox_nonce,
        secretbox_iters,
    ));
    results.push(bench_secretbox_libsodium_decrypt(
        &secretbox_data,
        &secretbox_key,
        &secretbox_nonce,
        secretbox_iters,
    ));

    // Stream (1 MiB, 50 MiB)
    for &size in &[MB, 50 * MB] {
        let data = vec![0x5a; size];
        let key = vec![0x33; STREAM_KEY_BYTES];
        let iterations = if size >= 50 * MB { 3 } else { 10 };

        results.push(bench_stream_core_encrypt(&data, &key, iterations));
        results.push(bench_stream_core_decrypt(&data, &key, iterations));
        results.push(bench_stream_libsodium_encrypt(&data, &key, iterations));
        results.push(bench_stream_libsodium_decrypt(&data, &key, iterations));
    }

    // Argon2id (interactive params)
    let argon_iters = 3;
    results.push(bench_argon_core(argon_iters));
    results.push(bench_argon_libsodium(argon_iters));

    // Auth flow (signup + login)
    let auth_iters = 3;
    let auth_password = "benchmark-password";
    let core_auth = build_core_auth_artifacts(auth_password);
    let libsodium_auth = build_libsodium_auth_artifacts(auth_password);

    results.push(bench_auth_core_signup(auth_password, auth_iters));
    results.push(bench_auth_libsodium_signup(auth_password, auth_iters));
    results.push(bench_auth_core_login(auth_password, &core_auth, auth_iters));
    results.push(bench_auth_libsodium_login(
        auth_password,
        &libsodium_auth,
        auth_iters,
    ));

    print_results(&results);
    print_summary(&results);
    write_json_if_requested(&results);
}

fn print_results(results: &[BenchResult]) {
    println!("Impl        | Case        | Op      | Size     | Iters | ms/op     | Rate");
    println!("------------+-------------+---------+----------+-------+-----------+------------");

    for result in results {
        let size = result.size_display();
        let (label, rate) = result.rate();
        println!(
            "{:<11} | {:<11} | {:<7} | {:>8} | {:>5} | {:>9.3} ms/op | {} {:>8.2}",
            result.implementation,
            result.case,
            result.operation,
            size,
            result.iterations,
            result.ms_per_op(),
            label,
            rate
        );
    }
}

fn print_summary(results: &[BenchResult]) {
    let mut groups: BTreeMap<(String, String, usize), Vec<&BenchResult>> = BTreeMap::new();

    for result in results {
        groups
            .entry((
                result.case.to_string(),
                result.operation.to_string(),
                result.size_bytes,
            ))
            .or_default()
            .push(result);
    }

    println!("\nWinner Summary (lower ms/op wins)");

    for ((case, operation, size_bytes), mut entries) in groups {
        entries.sort_by(|a, b| {
            a.ms_per_op()
                .partial_cmp(&b.ms_per_op())
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        let size_label = size_label(size_bytes);

        if entries.len() == 1 {
            println!(
                "- {} {} {}: {} only",
                case, operation, size_label, entries[0].implementation
            );
            continue;
        }

        let best = entries[0];
        let runner_up = entries[1];
        let best_ms = best.ms_per_op();
        let runner_ms = runner_up.ms_per_op();
        let percent = if runner_ms > 0.0 {
            (runner_ms - best_ms) / runner_ms * 100.0
        } else {
            0.0
        };

        println!(
            "- {} {} {}: {} by {:.1}%",
            case, operation, size_label, best.implementation, percent
        );
    }
}

fn size_label(size_bytes: usize) -> String {
    if size_bytes == 0 {
        "n/a".to_string()
    } else {
        format!("{:.1}MiB", size_bytes as f64 / MB as f64)
    }
}

fn bench_secretbox_core_encrypt(
    plaintext: &[u8],
    key: &[u8],
    nonce: &[u8],
    iterations: usize,
) -> BenchResult {
    let mut sink = 0u64;
    let start = Instant::now();
    for _ in 0..iterations {
        let ciphertext = crypto::secretbox::encrypt_with_nonce(plaintext, nonce, key).unwrap();
        sink ^= ciphertext[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "secretbox",
        implementation: "rust-core",
        operation: "encrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_secretbox_core_decrypt(
    plaintext: &[u8],
    key: &[u8],
    nonce: &[u8],
    iterations: usize,
) -> BenchResult {
    let ciphertext = crypto::secretbox::encrypt_with_nonce(plaintext, nonce, key).unwrap();
    let mut sink = 0u64;
    let start = Instant::now();
    for _ in 0..iterations {
        let decrypted = crypto::secretbox::decrypt(&ciphertext, nonce, key).unwrap();
        sink ^= decrypted[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "secretbox",
        implementation: "rust-core",
        operation: "decrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_secretbox_libsodium_encrypt(
    plaintext: &[u8],
    key: &[u8],
    nonce: &[u8],
    iterations: usize,
) -> BenchResult {
    let mut sink = 0u64;
    let start = Instant::now();
    for _ in 0..iterations {
        let ciphertext = libsodium_secretbox_encrypt(plaintext, nonce, key);
        sink ^= ciphertext[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "secretbox",
        implementation: "libsodium",
        operation: "encrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_secretbox_libsodium_decrypt(
    plaintext: &[u8],
    key: &[u8],
    nonce: &[u8],
    iterations: usize,
) -> BenchResult {
    let ciphertext = libsodium_secretbox_encrypt(plaintext, nonce, key);
    let mut sink = 0u64;
    let start = Instant::now();
    for _ in 0..iterations {
        let decrypted = libsodium_secretbox_decrypt(&ciphertext, nonce, key);
        sink ^= decrypted[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "secretbox",
        implementation: "libsodium",
        operation: "decrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_stream_core_encrypt(plaintext: &[u8], key: &[u8], iterations: usize) -> BenchResult {
    let chunks = chunk_count(plaintext.len());
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let mut encryptor = crypto::stream::StreamEncryptor::new(key).unwrap();
        for (index, chunk) in plaintext.chunks(STREAM_CHUNK).enumerate() {
            let is_final = index + 1 == chunks;
            let ciphertext = encryptor.push(chunk, is_final).unwrap();
            sink ^= ciphertext[0] as u64;
        }
        sink ^= encryptor.header[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "stream",
        implementation: "rust-core",
        operation: "encrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_stream_core_decrypt(plaintext: &[u8], key: &[u8], iterations: usize) -> BenchResult {
    let (cipher_chunks, header) = build_core_stream_ciphertext(plaintext, key);
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let mut decryptor = crypto::stream::StreamDecryptor::new(&header, key).unwrap();
        for chunk in &cipher_chunks {
            let (decrypted, _tag) = decryptor.pull(chunk).unwrap();
            sink ^= decrypted[0] as u64;
        }
    }
    black_box(sink);

    BenchResult {
        case: "stream",
        implementation: "rust-core",
        operation: "decrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_stream_libsodium_encrypt(plaintext: &[u8], key: &[u8], iterations: usize) -> BenchResult {
    let chunks = chunk_count(plaintext.len());
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let mut encryptor = LibsodiumStreamEncryptor::new(key);
        for (index, chunk) in plaintext.chunks(STREAM_CHUNK).enumerate() {
            let is_final = index + 1 == chunks;
            let ciphertext = encryptor.push(chunk, is_final);
            sink ^= ciphertext[0] as u64;
        }
        sink ^= encryptor.header[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "stream",
        implementation: "libsodium",
        operation: "encrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_stream_libsodium_decrypt(plaintext: &[u8], key: &[u8], iterations: usize) -> BenchResult {
    let (cipher_chunks, header) = build_libsodium_stream_ciphertext(plaintext, key);
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let mut decryptor = LibsodiumStreamDecryptor::new(key, &header).unwrap();
        for chunk in &cipher_chunks {
            let (decrypted, _tag) = decryptor.pull(chunk).unwrap();
            sink ^= decrypted[0] as u64;
        }
    }
    black_box(sink);

    BenchResult {
        case: "stream",
        implementation: "libsodium",
        operation: "decrypt",
        size_bytes: plaintext.len(),
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_argon_core(iterations: usize) -> BenchResult {
    let password = "benchmark-password";
    let salt = [0x7b; 16];
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let key = crypto::argon::derive_key(password, &salt, ARGON_MEM, ARGON_OPS).unwrap();
        sink ^= key[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "argon2id",
        implementation: "rust-core",
        operation: "derive",
        size_bytes: 0,
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_argon_libsodium(iterations: usize) -> BenchResult {
    let password = "benchmark-password";
    let salt = [0x7b; 16];
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let key = libsodium_argon2(password, &salt, ARGON_MEM, ARGON_OPS);
        sink ^= key[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "argon2id",
        implementation: "libsodium",
        operation: "derive",
        size_bytes: 0,
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_auth_core_signup(password: &str, iterations: usize) -> BenchResult {
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let result = generate_keys_with_strength(password, KeyDerivationStrength::Interactive)
            .expect("core keygen failed");
        sink ^= result.login_key[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "auth",
        implementation: "rust-core",
        operation: "signup",
        size_bytes: 0,
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_auth_libsodium_signup(password: &str, iterations: usize) -> BenchResult {
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let artifacts = build_libsodium_auth_artifacts(password);
        sink ^= artifacts.encrypted_key_b64.len() as u64;
    }
    black_box(sink);

    BenchResult {
        case: "auth",
        implementation: "libsodium",
        operation: "signup",
        size_bytes: 0,
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_auth_core_login(
    password: &str,
    artifacts: &CoreAuthArtifacts,
    iterations: usize,
) -> BenchResult {
    let mut sink = 0u64;
    let mem = artifacts.key_attrs.mem_limit.unwrap_or(ARGON_MEM);
    let ops = artifacts.key_attrs.ops_limit.unwrap_or(ARGON_OPS);

    let start = Instant::now();
    for _ in 0..iterations {
        let kek = derive_kek(password, &artifacts.key_attrs.kek_salt, mem, ops)
            .expect("core derive_kek failed");
        let secrets = decrypt_secrets(&kek, &artifacts.key_attrs, &artifacts.encrypted_token)
            .expect("core decrypt_secrets failed");
        sink ^= secrets.master_key[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "auth",
        implementation: "rust-core",
        operation: "login",
        size_bytes: 0,
        iterations,
        duration: start.elapsed(),
    }
}

fn bench_auth_libsodium_login(
    password: &str,
    artifacts: &LibsodiumAuthArtifacts,
    iterations: usize,
) -> BenchResult {
    let mut sink = 0u64;

    let start = Instant::now();
    for _ in 0..iterations {
        let salt = STANDARD
            .decode(&artifacts.kek_salt_b64)
            .expect("decode kek_salt failed");
        let kek = libsodium_argon2(password, &salt, artifacts.mem_limit, artifacts.ops_limit);

        let enc_key = STANDARD
            .decode(&artifacts.encrypted_key_b64)
            .expect("decode encrypted_key failed");
        let key_nonce = STANDARD
            .decode(&artifacts.key_nonce_b64)
            .expect("decode key_nonce failed");
        let master_key = libsodium_secretbox_decrypt(&enc_key, &key_nonce, &kek);

        let enc_secret_key = STANDARD
            .decode(&artifacts.encrypted_secret_key_b64)
            .expect("decode encrypted_secret_key failed");
        let secret_key_nonce = STANDARD
            .decode(&artifacts.secret_key_nonce_b64)
            .expect("decode secret_key_nonce failed");
        let secret_key =
            libsodium_secretbox_decrypt(&enc_secret_key, &secret_key_nonce, &master_key);

        let public_key = STANDARD
            .decode(&artifacts.public_key_b64)
            .expect("decode public_key failed");
        let encrypted_token = STANDARD
            .decode(&artifacts.encrypted_token_b64)
            .expect("decode encrypted_token failed");
        let token = libsodium_seal_open(&encrypted_token, &public_key, &secret_key);
        sink ^= token[0] as u64;
    }
    black_box(sink);

    BenchResult {
        case: "auth",
        implementation: "libsodium",
        operation: "login",
        size_bytes: 0,
        iterations,
        duration: start.elapsed(),
    }
}

fn build_core_auth_artifacts(password: &str) -> CoreAuthArtifacts {
    let gen_result = generate_keys_with_strength(password, KeyDerivationStrength::Interactive)
        .expect("core keygen failed");
    let public_key = crypto::decode_b64(&gen_result.key_attributes.public_key)
        .expect("decode public key failed");
    let sealed_token = crypto::sealed::seal(AUTH_TOKEN, &public_key).expect("core seal failed");

    CoreAuthArtifacts {
        key_attrs: gen_result.key_attributes,
        encrypted_token: STANDARD.encode(sealed_token),
    }
}

fn build_libsodium_auth_artifacts(password: &str) -> LibsodiumAuthArtifacts {
    let master_key = libsodium_random_bytes(SECRETBOX_KEY_BYTES);
    let recovery_key = libsodium_random_bytes(SECRETBOX_KEY_BYTES);

    let nonce_master_recovery = libsodium_random_bytes(SECRETBOX_NONCE_BYTES);
    let enc_master_with_recovery =
        libsodium_secretbox_encrypt(&master_key, &nonce_master_recovery, &recovery_key);
    let _ = STANDARD.encode(&enc_master_with_recovery);
    let _ = STANDARD.encode(&nonce_master_recovery);

    let nonce_recovery_master = libsodium_random_bytes(SECRETBOX_NONCE_BYTES);
    let enc_recovery_with_master =
        libsodium_secretbox_encrypt(&recovery_key, &nonce_recovery_master, &master_key);
    let _ = STANDARD.encode(&enc_recovery_with_master);
    let _ = STANDARD.encode(&nonce_recovery_master);
    let _ = hex::encode(&recovery_key);

    let kek_salt = libsodium_random_bytes(16);
    let kek = libsodium_argon2(password, &kek_salt, ARGON_MEM, ARGON_OPS);
    let _login_key = libsodium_derive_login_key(&kek);

    let key_nonce = libsodium_random_bytes(SECRETBOX_NONCE_BYTES);
    let enc_key = libsodium_secretbox_encrypt(&master_key, &key_nonce, &kek);

    let (public_key, secret_key) = libsodium_box_keypair();

    let secret_key_nonce = libsodium_random_bytes(SECRETBOX_NONCE_BYTES);
    let enc_secret_key = libsodium_secretbox_encrypt(&secret_key, &secret_key_nonce, &master_key);

    let sealed_token = libsodium_seal(AUTH_TOKEN, &public_key);

    LibsodiumAuthArtifacts {
        kek_salt_b64: STANDARD.encode(&kek_salt),
        mem_limit: ARGON_MEM,
        ops_limit: ARGON_OPS,
        encrypted_key_b64: STANDARD.encode(&enc_key),
        key_nonce_b64: STANDARD.encode(&key_nonce),
        public_key_b64: STANDARD.encode(&public_key),
        encrypted_secret_key_b64: STANDARD.encode(&enc_secret_key),
        secret_key_nonce_b64: STANDARD.encode(&secret_key_nonce),
        encrypted_token_b64: STANDARD.encode(&sealed_token),
    }
}

fn libsodium_argon2(password: &str, salt: &[u8], mem_limit: u32, ops_limit: u32) -> Vec<u8> {
    let mut key = vec![0u8; 32];
    let result = unsafe {
        sodium::crypto_pwhash(
            key.as_mut_ptr(),
            key.len() as u64,
            password.as_ptr() as *const i8,
            password.len() as u64,
            salt.as_ptr(),
            ops_limit as u64,
            mem_limit as usize,
            sodium::crypto_pwhash_ALG_ARGON2ID13 as i32,
        )
    };
    assert_eq!(result, 0, "libsodium argon2 failed");
    key
}

fn libsodium_derive_login_key(kek: &[u8]) -> Vec<u8> {
    let mut subkey = vec![0u8; 32];
    let mut ctx = [0u8; 8];
    ctx[..8].copy_from_slice(b"loginctx");

    let result = unsafe {
        sodium::crypto_kdf_derive_from_key(
            subkey.as_mut_ptr(),
            subkey.len(),
            1,
            ctx.as_ptr() as *const c_char,
            kek.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium kdf failed");
    subkey[..16].to_vec()
}

fn libsodium_random_bytes(len: usize) -> Vec<u8> {
    let mut buf = vec![0u8; len];
    unsafe {
        sodium::randombytes_buf(buf.as_mut_ptr() as *mut _, len);
    }
    buf
}

fn libsodium_box_keypair() -> (Vec<u8>, Vec<u8>) {
    let mut public_key = vec![0u8; sodium::crypto_box_PUBLICKEYBYTES as usize];
    let mut secret_key = vec![0u8; sodium::crypto_box_SECRETKEYBYTES as usize];
    let result =
        unsafe { sodium::crypto_box_keypair(public_key.as_mut_ptr(), secret_key.as_mut_ptr()) };
    assert_eq!(result, 0, "libsodium keypair failed");
    (public_key, secret_key)
}

fn libsodium_seal(plaintext: &[u8], public_key: &[u8]) -> Vec<u8> {
    let mut ciphertext = vec![0u8; plaintext.len() + sodium::crypto_box_SEALBYTES as usize];
    unsafe {
        sodium::crypto_box_seal(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            public_key.as_ptr(),
        );
    }
    ciphertext
}

fn libsodium_seal_open(ciphertext: &[u8], public_key: &[u8], secret_key: &[u8]) -> Vec<u8> {
    let mut plaintext = vec![0u8; ciphertext.len() - sodium::crypto_box_SEALBYTES as usize];
    let result = unsafe {
        sodium::crypto_box_seal_open(
            plaintext.as_mut_ptr(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            public_key.as_ptr(),
            secret_key.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium seal open failed");
    plaintext
}

fn libsodium_secretbox_encrypt(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Vec<u8> {
    let mac_bytes = sodium::crypto_secretbox_MACBYTES as usize;
    let mut ciphertext = vec![0u8; plaintext.len() + mac_bytes];
    unsafe {
        sodium::crypto_secretbox_easy(
            ciphertext.as_mut_ptr(),
            plaintext.as_ptr(),
            plaintext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        );
    }
    ciphertext
}

fn libsodium_secretbox_decrypt(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Vec<u8> {
    let mac_bytes = sodium::crypto_secretbox_MACBYTES as usize;
    let mut plaintext = vec![0u8; ciphertext.len() - mac_bytes];
    let result = unsafe {
        sodium::crypto_secretbox_open_easy(
            plaintext.as_mut_ptr(),
            ciphertext.as_ptr(),
            ciphertext.len() as u64,
            nonce.as_ptr(),
            key.as_ptr(),
        )
    };
    assert_eq!(result, 0, "libsodium secretbox decrypt failed");
    plaintext
}

fn build_core_stream_ciphertext(plaintext: &[u8], key: &[u8]) -> (Vec<Vec<u8>>, Vec<u8>) {
    let chunks = chunk_count(plaintext.len());
    let mut encryptor = crypto::stream::StreamEncryptor::new(key).unwrap();
    let mut ciphertext = Vec::with_capacity(chunks);

    for (index, chunk) in plaintext.chunks(STREAM_CHUNK).enumerate() {
        let is_final = index + 1 == chunks;
        ciphertext.push(encryptor.push(chunk, is_final).unwrap());
    }

    (ciphertext, encryptor.header)
}

fn build_libsodium_stream_ciphertext(
    plaintext: &[u8],
    key: &[u8],
) -> (Vec<Vec<u8>>, [u8; STREAM_HEADER_BYTES]) {
    let chunks = chunk_count(plaintext.len());
    let mut encryptor = LibsodiumStreamEncryptor::new(key);
    let mut ciphertext = Vec::with_capacity(chunks);

    for (index, chunk) in plaintext.chunks(STREAM_CHUNK).enumerate() {
        let is_final = index + 1 == chunks;
        ciphertext.push(encryptor.push(chunk, is_final));
    }

    (ciphertext, encryptor.header)
}

fn chunk_count(len: usize) -> usize {
    len.div_ceil(STREAM_CHUNK)
}

struct LibsodiumStreamEncryptor {
    state: sodium::crypto_secretstream_xchacha20poly1305_state,
    header: [u8; STREAM_HEADER_BYTES],
}

impl LibsodiumStreamEncryptor {
    fn new(key: &[u8]) -> Self {
        let mut state = sodium::crypto_secretstream_xchacha20poly1305_state {
            k: [0u8; 32],
            nonce: [0u8; 12],
            _pad: [0u8; 8],
        };
        let mut header = [0u8; STREAM_HEADER_BYTES];
        unsafe {
            sodium::crypto_secretstream_xchacha20poly1305_init_push(
                &mut state,
                header.as_mut_ptr(),
                key.as_ptr(),
            );
        }
        Self { state, header }
    }

    fn push(&mut self, plaintext: &[u8], is_final: bool) -> Vec<u8> {
        let tag = if is_final {
            STREAM_TAG_FINAL
        } else {
            STREAM_TAG_MESSAGE
        };
        let mut ciphertext = vec![0u8; plaintext.len() + STREAM_ABYTES];
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

struct LibsodiumStreamDecryptor {
    state: sodium::crypto_secretstream_xchacha20poly1305_state,
}

impl LibsodiumStreamDecryptor {
    fn new(key: &[u8], header: &[u8; STREAM_HEADER_BYTES]) -> Option<Self> {
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
        if ciphertext.len() < STREAM_ABYTES {
            return None;
        }

        let mut plaintext = vec![0u8; ciphertext.len() - STREAM_ABYTES];
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
