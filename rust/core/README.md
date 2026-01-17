# ente-core

Common Rust code for Ente apps.

## Modules

| Module | Description |
|--------|-------------|
| `auth` | Authentication helpers (signup/login/recovery, SRP credentials) |
| `crypto` | Cryptographic utilities (pure Rust, libsodium-wire-compatible) |
| `http` | HTTP client for Ente API |
| `urls` | URL construction utilities |

## Auth

High-level authentication helpers for Ente clients:

- Derive KEK/login key from password (SRP)
- Decrypt master key, secret key and token after authentication
- Signup key generation
- Account recovery

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
