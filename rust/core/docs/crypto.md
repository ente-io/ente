# Crypto Module

Pure Rust cryptographic utilities, wire-compatible with JS/Dart clients.

## Quick Reference

```rust
use ente_core::crypto;

crypto::init().unwrap();  // Call once at startup
```

| Task | Module | Example |
|------|--------|---------|
| Encrypt keys/tokens | `secretbox` | `secretbox::encrypt(data, &key)` |
| Encrypt metadata | `blob` | `blob::encrypt(data, &key)` |
| Encrypt files | `stream` | `stream::encrypt_file(&mut src, &mut dst, None)` |
| Anonymous encrypt | `sealed` | `sealed::seal(data, &public_key)` |
| Password → Key | `argon` | `argon::derive_sensitive_key("password")` |
| Master → Subkey | `kdf` | `kdf::derive_login_key(&master_key)` |
| Hash data/files | `hash` | `hash::hash_reader(&mut file, None)` |
| Generate keys | `keys` | `keys::generate_key()` |

## Common Patterns

### Encrypt user data with password
```rust
let derived = argon::derive_sensitive_key("password")?;
let encrypted = secretbox::encrypt(&user_data, &derived.key)?;
// Store: encrypted.encrypted_data, encrypted.nonce, derived.salt
```

### Encrypt a file
```rust
let mut src = File::open("photo.jpg")?;
let mut dst = File::create("photo.enc")?;
let (key, header) = stream::encrypt_file(&mut src, &mut dst, None)?;
// Store key and header for decryption
```

### Share data with public key
```rust
let sealed = sealed::seal(&secret_data, &recipient_public_key)?;
// Only recipient can open with their secret key
let opened = sealed::open(&sealed, &recipient_pk, &recipient_sk)?;
```

### Derive login key for SRP
```rust
let kek = argon::derive_key("password", &salt, mem_limit, ops_limit)?;
let login_key = kdf::derive_login_key(&kek)?;
```

## Dart → Rust Mapping

| Dart | Rust |
|------|------|
| `encryptSync()` / `decryptSync()` | `secretbox::encrypt()` / `decrypt_box()` |
| `encryptChaCha()` / `decryptChaCha()` | `blob::encrypt()` / `decrypt()` |
| `encryptFile()` / `decryptFile()` | `stream::encrypt_file()` / `decrypt_file()` |
| `sealSync()` / `openSealSync()` | `sealed::seal()` / `open()` |
| `deriveSensitiveKey()` | `argon::derive_sensitive_key()` |
| `deriveLoginKey()` | `kdf::derive_login_key()` |
| `getHash()` | `hash::hash_reader()` |
| `generateKey()` | `keys::generate_key()` |
| `base642bin()` / `bin2base64()` | `decode_b64()` / `encode_b64()` |

## Key Constants

| Constant | Value | Where |
|----------|-------|-------|
| `ENCRYPTION_CHUNK_SIZE` | 4 MB | stream |
| `KEY_BYTES` | 32 | all modules |
| `NONCE_BYTES` | 24 | secretbox |
| `HEADER_BYTES` | 24 | stream/blob |
| `SALT_BYTES` | 16 | argon/keys |
| `SEAL_OVERHEAD` | 48 | sealed |

## Wire Formats

- **SecretBox**: `MAC (16) || ciphertext`
- **Stream chunk**: `tag (1) || ciphertext || MAC (16)`
- **Sealed**: `ephemeral_pk (32) || MAC (16) || ciphertext`
