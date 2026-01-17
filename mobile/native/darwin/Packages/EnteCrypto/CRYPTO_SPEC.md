# Ente Cryptographic Operations Specification

## Overview

This document specifies the cryptographic operations used in the Ente ecosystem, with particular focus on the tvOS/Swift implementation via the EnteCrypto package. All crypto operations use libsodium for consistency across platforms (Mobile, Web, CLI, tvOS).

## Core Algorithms & Libraries

### Primary Dependencies
- **libsodium**: Cross-platform cryptographic library (via swift-sodium)
- **CryptoKit**: Apple's cryptographic framework (X25519 key generation only)
- **Swift Crypto**: Additional cryptographic primitives

### Algorithm Suite
- **Key Exchange**: X25519 Elliptic Curve Diffie-Hellman
- **Symmetric Encryption**: XSalsa20Poly1305 (secretbox), XChaCha20Poly1305 (secretstream)
- **Anonymous Encryption**: X25519 + XSalsa20Poly1305 (sealed box)
- **Hashing**: BLAKE2b (64-byte output)
- **Key Derivation**: Argon2id, libsodium KDF

---

## Authentication & Key Derivation

### Password-Based Key Derivation

**Purpose**: Convert user password into encryption keys
**Algorithm**: Argon2id
**Implementation**: `EnteCrypto.deriveArgonKey()`

```swift
// Parameters (configurable based on device capability)
memLimit: Int     // Memory limit in bytes
opsLimit: Int     // Time/CPU cost parameter
salt: String      // Base64-encoded 16-byte salt
output: 32 bytes  // keyEncryptionKey (KEK)
```

**Cross-Platform Notes**:
- Mobile/Web: argon2-browser, go-argon2
- tvOS: swift-sodium pwHash.hash()
- All platforms produce identical outputs for same parameters

### Login Key Derivation

**Purpose**: Derive authentication key from KEK for SRP
**Algorithm**: libsodium KDF (crypto_kdf_derive_from_key)
**Implementation**: `EnteCrypto.deriveLoginKey()`

```swift
input: keyEncryptionKey (32 bytes)
kdf_id: 1
context: "loginctx" (8 bytes)
output: 16 bytes (first half of 32-byte derived key)
```

---

## Secure Remote Password (SRP)

**Purpose**: Zero-knowledge password authentication
**Implementation**: `SRPClient` class
**Parameters**: 
- Group: 4096-bit safe prime (RFC 5054)
- Hash: SHA-256
- Generator: 5

### Authentication Flow
1. Client generates private key `a`, computes public key `A = g^a mod N`
2. Server responds with public key `B`, salt
3. Client computes shared secret `S` using password-derived `x`
4. Mutual authentication via evidence exchange (M1, M2)
5. Session key derived as `SHA-256(S)`

---

## Cast System Cryptography

### Key Generation

**Purpose**: Generate keypair for cast device pairing
**Algorithm**: X25519 ECDH
**Implementation**: `EnteCrypto.generateCastKeyPair()`

```swift
// Uses CryptoKit for X25519 generation (compatible with libsodium)
privateKey: Curve25519.KeyAgreement.PrivateKey
publicKey: derived from privateKey
output: base64-encoded key pair
```

### Cast Payload Encryption/Decryption

**Purpose**: Secure transmission of collection metadata from mobile to tvOS
**Algorithm**: X25519 + XSalsa20Poly1305 (NaCl sealed box)
**Implementation**: `EnteCrypto.decryptCastPayload()`

**Mobile Client (Dart)**:
```dart
final encPayload = CryptoUtil.sealSync(
  CryptoUtil.base642bin(base64Encode(payload.codeUnits)),
  CryptoUtil.base642bin(publicKey)
);
```

**tvOS Client (Swift)**:
```swift
let decryptedBytes = sodium.box.open(
    anonymousCipherText: cipherText,
    recipientPublicKey: publicKey,
    recipientSecretKey: privateKey
)
```

**Payload Structure**:
```json
{
  "collectionID": 12345,
  "castToken": "authentication-token",
  "collectionKey": "base64-encoded-collection-key"
}
```

---

## File Encryption System

### File Key Decryption

**Purpose**: Decrypt file-specific encryption keys
**Algorithm**: XSalsa20Poly1305 (libsodium secretbox)
**Implementation**: `EnteCrypto.secretBoxOpen()`

```swift
input: encryptedKey (base64) + nonce (base64) + collectionKey (32 bytes)
output: fileKey (32 bytes)
```

### File Content & Metadata Decryption

**Purpose**: Decrypt actual file data and metadata
**Algorithm**: XChaCha20Poly1305 (libsodium secretstream)  
**Implementation**: `EnteCrypto.decryptSecretStream()`

```text
Inputs:
  fileKey: 32 bytes (random; derived via key hierarchy)
  header:  24 bytes (emitted once by secretstream initPush; MUST be stored)
  cipher:  Concatenation of encrypted chunks (each chunk = plaintextChunk + 17 bytes overhead)
Output:
  Plaintext file bytes (exact original size)
```

#### File (NOT thumbnail) Encryption Format
All full-size files use libsodium secretstream XChaCha20-Poly1305 with FIXED PLAINTEXT CHUNK SIZE:
* Plaintext chunk size: 4,194,304 bytes (4 MiB) except final chunk (smaller or equal)
* Per-chunk overhead: 17 bytes (secretstream MAC + internal framing)
* Cipher chunk size (non-final): 4,194,321 bytes (4 MiB + 17)
* Final chunk: plaintext_len + 17 (tag = FINAL)

Encryption steps (producer):
1. Generate `fileKey` (32 random bytes) if not already present.
2. `state, header = initPush(fileKey)`; persist `header` alongside encrypted data record.
3. For each 4 MiB plaintext slice (streamed from disk):
   - Tag = `MESSAGE` for all but last; `FINAL` for last slice.
   - `cipherChunk = push(state, plaintextSlice, tag)` (cipherChunk length = sliceLen + 17)
   - Append `cipherChunk` to output blob.
4. Store: `header` (24B), concatenated cipher blob, original size metadata (optional but useful for validations), and hash (BLAKE2b) if required.

Decryption steps (consumer):
1. Retrieve `fileKey`, `header`, full `cipher` blob.
2. Initialize: `state = initPull(header, fileKey)`.
3. Iterate over the cipher blob in fixed sized chunks of 4,194,321 bytes (cipherChunkSize) until remaining < cipherChunkSize; treat remainder as final chunk.
4. For each chunk: `plaintext, tag = pull(state, cipherChunk)`; append `plaintext`.
5. Expect `FINAL` tag on the last chunk and no trailing bytes after a `FINAL`.
6. Authentication failure (pull returns nil) ⇒ abort: report `decryptionFailed`.

Notes:
* Each chunk MAC authenticates sequence + content; modification or truncation causes pull failure.
* If in future producers change chunk size, the decrypter MUST add negotiation metadata (e.g. store chunk size) or attempt adaptive boundary detection BEFORE deploying change.
* Metadata blobs (small) MAY still be single-chunk (then cipher length = plaintext + 17, tag = FINAL). Logic above still applies.

---

## Hash Verification System

### BLAKE2b Hashing

**Purpose**: Verify file content integrity
**Algorithm**: BLAKE2b (crypto_generichash)
**Output Length**: 64 bytes (512 bits)
**Implementation**: `EnteCrypto.computeBlake2bHash()`

```swift
input: file_content (Data)
process: sodium.genericHash.hash(message, outputLength: 64)
output: hex_string (128 characters)
```

### Cross-Platform Hash Verification

**Challenge**: Server stores hashes as base64, client computes as hex
**Solution**: Dual-format comparison in `EnteCrypto.verifyFileHash()`

```swift
// 1. Try direct hex comparison
if computedHex == expectedHash { return true }

// 2. Try base64→hex conversion  
if let base64Data = Data(base64Encoded: expectedHash) {
    let expectedHex = base64Data.hexString
    if computedHex == expectedHex { return true }
}
```

---

## Platform Consistency Matrix

| Operation | Mobile (Dart) | Web (TypeScript) | CLI (Go) | tvOS (Swift) |
|-----------|---------------|------------------|----------|--------------|
| **Key Derivation** | argon2-browser | argon2-browser | go-argon2 | swift-sodium |
| **SRP Auth** | custom | custom | custom | SRPClient |
| **Cast Payload** | sealSync() | boxSeal() | SealedBoxOpen() | box.open() |
| **File Key** | secretBox | secretBox | SecretBoxOpen() | secretBox.open() |
| **File Content** | decryptChaCha() | decryptStreamBytes() | DecryptFile() | secretStream.xchacha20poly1305 |
| **Hash** | blake2b (64B) | blake2b (64B) | blake2b (64B) | genericHash (64B) |

## Security Properties

### Cryptographic Guarantees
1. **Forward Secrecy**: Cast uses ephemeral X25519 keypairs
2. **Zero Knowledge**: Server cannot decrypt payloads or file contents  
3. **Authenticated Encryption**: All operations use AEAD ciphers
4. **Key Hierarchy**: `masterKey → collectionKey → fileKey → content`
5. **Integrity Verification**: BLAKE2b hashes validate authenticity

### Implementation Security
1. **Constant-Time Operations**: libsodium provides timing-safe implementations
2. **Memory Safety**: Swift automatic memory management + libsodium secure allocators
3. **Key Zeroization**: libsodium handles secure key deletion
4. **Side-Channel Resistance**: Hardware-accelerated crypto where available

---

## Error Handling

### CryptoError Types
- `invalidSalt`: Base64 decoding or format errors
- `invalidParameters`: Wrong key/nonce lengths, malformed input
- `invalidKeyLength`: Key size validation failures
- `derivationFailed`: Argon2id, KDF, or random generation failures  
- `decryptionFailed`: Authentication tag verification failures
- `encryptionFailed`: Encryption operation failures

### Error Recovery
1. **Cast Operations**: Fall back to demo mode on crypto failures
2. **File Operations**: Skip files with decryption/verification errors
3. **Authentication**: Clear stored credentials and restart flow
4. **Network**: Retry with exponential backoff for transient failures

---

## Performance Considerations

### Optimization Strategies
1. **Streaming**: Use secretstream for large files (>1MB)
2. **Hardware Acceleration**: Leverage ARM64 crypto extensions on Apple TV
3. **Memory Management**: Process files in chunks to limit peak memory
4. **Caching**: Reuse decrypted collection keys within session
5. **Precomputation**: Generate ephemeral keys during app startup

### Resource Limits
- **Memory**: Argon2id memLimit tuned per device capability
- **Time**: Argon2id opsLimit balanced for UX vs security
- **Storage**: No persistent key storage (session-only)
- **Network**: Cast payload <1KB, efficient for real-time transmission

---

## Testing & Validation

### Cross-Platform Test Vectors
1. **Key Derivation**: Same password/salt → identical KEK across platforms
2. **Cast Payload**: Mobile-encrypted → tvOS-decrypted → identical JSON
3. **File Decryption**: Server file → tvOS client → verified hash match
4. **Hash Computation**: Same content → identical BLAKE2b across platforms

### Security Testing
1. **Static Analysis**: SwiftLint crypto-specific rules
2. **Dynamic Analysis**: Memory leak detection during crypto operations  
3. **Fuzzing**: Malformed input handling in decrypt operations
4. **Side-Channel**: Timing analysis of key derivation and comparison

---

## Implementation Notes

### Swift-Specific Considerations
1. **libsodium Integration**: Use swift-sodium wrapper for cross-platform compatibility
2. **Memory Management**: Data types automatically zeroed by ARC
3. **Error Handling**: Typed errors with localized descriptions
4. **Concurrency**: All crypto operations are synchronous (libsodium requirement)

### tvOS Platform Constraints  
1. **No Persistent Storage**: Keys exist only in memory during session
2. **Limited Input**: QR code scanning for device pairing
3. **Network Only**: All crypto material received via cast protocol
4. **Performance**: ARM64 hardware acceleration available

---

## Version History

**v1.0 (August 2025)**: Initial implementation with working cast functionality
- Cast payload decryption (sealed box)
- File key/content decryption (secretbox/secretstream)  
- BLAKE2b hash verification (64-byte, dual-format)
- X25519 key generation (CryptoKit + libsodium compatible)
- Cross-platform compatibility verified

---

*This specification ensures cryptographic consistency across all Ente client platforms while maintaining the security guarantees of the zero-knowledge architecture.*