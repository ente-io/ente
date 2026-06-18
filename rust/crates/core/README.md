# ente-core

Common Rust code for Ente apps.

## Modules

| Module   | Description                                                     |
| -------- | --------------------------------------------------------------- |
| `auth`   | Authentication helpers (signup/login/recovery, SRP credentials) |
| `crypto` | Cryptographic utilities (pure Rust, libsodium-wire-compatible)  |
| `http`   | HTTP client for Ente API                                        |
| `io`     | I/O adapters (e.g. single-pass MD5 of written data)             |
| `urls`   | URL construction utilities                                      |

## Auth

High-level authentication helpers for Ente clients:

- Derive KEK/login key from password (SRP)
- Decrypt master key, secret key and token after authentication
- Signup key generation
- Account recovery

## Crypto

Pure Rust cryptography, byte-compatible with JS/Dart clients. Key material is
typed (`Key`, `Nonce`, `Salt`, `Header`, `PublicKey`, `SecretKey`), so sizes
are validated once at the boundary where raw bytes enter, and secret types
zeroize on drop.

| Submodule   | Algorithm                  | Use Case                         |
| ----------- | -------------------------- | -------------------------------- |
| `secretbox` | XSalsa20-Poly1305          | Encrypt keys, small data         |
| `blob`      | XChaCha20-Poly1305         | Encrypt metadata                 |
| `stream`    | XChaCha20-Poly1305         | Encrypt large files (4MB chunks) |
| `sealed`    | X25519 + XSalsa20-Poly1305 | Anonymous public-key encryption  |
| `argon`     | Argon2id                   | Password-based key derivation    |
| `kdf`       | BLAKE2b                    | Subkey derivation                |
| `hash`      | BLAKE2b                    | Cryptographic hashing            |

### Quick Start

```rust
use ente_core::crypto::{Key, secretbox};

let key = Key::generate();
let encrypted = secretbox::encrypt(b"Hello", &key);
let decrypted = encrypted.decrypt(&key).unwrap();
```
