# ente-core

Common Rust code for Ente apps.

## Modules

| Module | Description |
|--------|-------------|
| `auth` | Authentication (login, signup, recovery, SRP credentials) |
| `crypto` | Cryptographic utilities (pure Rust) |
| `http` | HTTP client for Ente API |
| `urls` | URL construction utilities |

## Auth

High-level authentication API for Ente clients.

| Function | Description |
|----------|-------------|
| `derive_srp_credentials()` | Derive KEK and login key from password |
| `derive_kek()` | Derive key-encryption-key only (for email MFA flow) |
| `decrypt_secrets()` | Decrypt master key, secret key, and token |
| `generate_keys()` | Generate keys for new account signup |
| `recover_with_key()` | Recover account with recovery key |

### Quick Start - SRP Login

```rust
use ente_core::auth;

// 1. Derive SRP credentials (KEK + login key)
let creds = auth::derive_srp_credentials(password, &srp_attrs)?;

// 2. Use login_key with your SRP client to compute srpA/srpM1
let mut srp = SrpClient::new(&srp_attrs.srp_user_id, &srp_attrs.srp_salt, &creds.login_key)?;
let a_pub = srp.public_a();
let session = api.create_srp_session(&a_pub).await?;
let m1 = srp.compute_m1(&session.srp_b)?;

// 3. Verify with server, get key attributes
let auth_response = api.verify_srp_session(&m1).await?;

// 4. Decrypt secrets
let secrets = auth::decrypt_secrets(&creds.kek, &key_attrs, &encrypted_token)?;
// secrets.master_key, secrets.secret_key, secrets.token
```

### Quick Start - Email MFA Login

```rust
use ente_core::auth;

// 1. Derive KEK from password (no SRP needed)
let kek = auth::derive_kek(password, &kek_salt, mem_limit, ops_limit)?;

// 2. Do email OTP + TOTP verification via API
// ...

// 3. Decrypt secrets
let secrets = auth::decrypt_secrets(&kek, &key_attrs, &encrypted_token)?;
```

📖 **[Full Auth Docs](docs/auth.md)**

## Crypto

Pure Rust cryptography, byte-compatible with JS/Dart clients.

| Submodule | Algorithm | Use Case |
|-----------|-----------|----------|
| `secretbox` | XSalsa20-Poly1305 | Encrypt keys, small data |
| `blob` | XChaCha20-Poly1305 | Encrypt metadata |
| `stream` | XChaCha20-Poly1305 | Encrypt large files (4MB chunks) |
| `sealed` | X25519 + XSalsa20-Poly1305 | Anonymous public-key encryption |
| `argon` | Argon2id | Password-based key derivation |
| `kdf` | BLAKE2b | Subkey derivation |
| `hash` | BLAKE2b | Cryptographic hashing |
| `keys` | - | Key generation |

### Quick Start

```rust
use ente_core::crypto;

crypto::init().unwrap();

let key = crypto::keys::generate_key();
let encrypted = crypto::secretbox::encrypt(b"Hello", &key).unwrap();
let decrypted = crypto::secretbox::decrypt_box(&encrypted, &key).unwrap();
```

📖 **[Full Crypto Docs](docs/crypto.md)**

## Development

```bash
cargo fmt      # format
cargo clippy   # lint  
cargo build    # build
cargo test     # test
```

## Fuzzing

Fuzzing is an automated technique that feeds randomized and malformed inputs into
functions to uncover panics, edge cases, and security bugs that unit tests may miss.

Fuzz targets live in `rust/core/fuzz` (cargo-fuzz). Requires a nightly toolchain.

```bash
cargo +nightly install cargo-fuzz
cd rust/core
cargo +nightly fuzz run secretbox -- -max_total_time=60
```

Other targets: `sealed_box`, `stream`, `argon`.

## Tests

```
tests/
├── auth_integration.rs          # Auth workflow tests
├── comprehensive_crypto_tests.rs # Stress tests (up to 50MB files)
└── libsodium_vectors.rs         # Libsodium compatibility

src/
├── auth/*.rs                    # Auth unit tests
└── crypto/*.rs                  # Crypto unit tests
```

**Total: 186+ tests**

| Test Suite | What it tests |
|------------|---------------|
| Auth unit tests | Login, signup, recovery, SRP |
| Auth integration | Full auth workflows |
| Crypto unit tests | Individual crypto operations |
| Libsodium vectors | Cross-platform compatibility |
| Comprehensive | Large files, edge cases |

### Running Tests

```bash
# All tests
cargo test

# Auth tests only
cargo test auth

# Crypto tests only  
cargo test crypto

# With output
cargo test -- --nocapture
```
