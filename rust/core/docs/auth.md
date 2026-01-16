# Auth Module

The `auth` module provides high-level authentication operations for Ente clients. It handles:

- **Login**: Password verification via SRP or email MFA
- **Signup**: Key generation for new accounts
- **Recovery**: Account recovery with recovery key
- **SRP Login**: Client-side SRP exchange using derived credentials

SRP protocol exchange is handled in the application layer. This module only
provides credential derivation and secret decryption helpers.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application Layer (CLI/GUI)                   │
├─────────────────────────────────────────────────────────────────┤
│  • User interaction (prompts, passwords)                         │
│  • HTTP API calls (send OTP, verify email, SRP sessions)         │
│  • State management (storage, accounts)                          │
│  • Flow orchestration (which auth method, retry logic)           │
└───────────────────────────┬─────────────────────────────────────┘
                            │ calls
┌───────────────────────────▼─────────────────────────────────────┐
│                      ente-core/auth (This Module)                │
├─────────────────────────────────────────────────────────────────┤
│  • derive_srp_credentials() - Password → KEK + login key         │
│  • derive_kek()             - Password → KEK only                │
│  • decrypt_secrets()        - KEK → master key, secret key, token│
│  • generate_keys()          - Signup key generation              │
│  • recover_with_key()       - Recovery key → keys                │
└─────────────────────────────────────────────────────────────────┘
```

## Authentication Flows

### Flow 1: SRP Login (Email MFA Disabled)

```
User                    App                     Server              ente-core
 │                       │                        │                     │
 │ Enter password ──────►│                        │                     │
 │                       │ get_srp_attributes ───►│                     │
 │                       │◄─── srp_attrs ─────────│                     │
 │                       │                        │                     │
 │                       │ derive_srp_credentials(password, srp_attrs) ─►│
 │                       │◄──────── (login_key, kek) ───────────────────│
 │                       │                        │                     │
 │                       │ [SRP client] public_a(login_key, srp_attrs)   │
 │                       │ create_srp_session(a_pub) ──►│               │
 │                       │◄─── session_id, srp_b ─│                     │
 │                       │                        │                     │
 │                       │ [SRP client] compute_m1(srp_b, login_key)     │
 │                       │ verify_srp_session(m1) ►│                     │
 │                       │◄── auth_response ──────│                     │
 │                       │                        │                     │
 │                       │    [If 2FA required: TOTP/Passkey flow]      │
 │                       │                        │                     │
 │                       │ decrypt_secrets(kek, key_attrs, token) ─────►│
 │                       │◄────────── DecryptedSecrets ─────────────────│
 │                       │                        │                     │
 │◄── Login success ─────│                        │                     │
```

### Flow 2: Email MFA Login (Email MFA Enabled)

```
User                    App                     Server              ente-core
 │                       │                        │                     │
 │ Enter email ─────────►│                        │                     │
 │                       │ get_srp_attributes ───►│                     │
 │                       │◄─ is_email_mfa: true ──│                     │
 │                       │                        │                     │
 │ Enter password ──────►│  (store for later)     │                     │
 │                       │                        │                     │
 │                       │ send_otp(email) ──────►│                     │
 │                       │◄─── OK ────────────────│                     │
 │                       │                        │                     │
 │ Enter OTP ──────────►│                        │                     │
 │                       │ verify_email(otp) ────►│                     │
 │                       │◄── auth_response ──────│                     │
 │                       │                        │                     │
 │                       │    [If 2FA required: TOTP/Passkey flow]      │
 │                       │                        │                     │
 │                       │ derive_kek(password, kek_salt, ...) ────────►│
 │                       │◄─────────────────────────────── kek ──────────│
 │                       │                        │                     │
 │                       │ decrypt_secrets(kek, key_attrs, token) ─────►│
 │                       │◄────────── DecryptedSecrets ─────────────────│
 │                       │                        │                     │
 │◄── Login success ─────│                        │                     │
```

## API Reference

### Types

#### `SrpAttributes`
Server-provided attributes for SRP authentication.

```rust
pub struct SrpAttributes {
    pub srp_user_id: String,      // UUID for SRP identity
    pub srp_salt: String,         // Base64-encoded salt
    pub mem_limit: u32,           // Argon2 memory limit
    pub ops_limit: u32,           // Argon2 ops limit
    pub kek_salt: String,         // Base64-encoded KEK salt
    pub is_email_mfa_enabled: bool,
}
```

If `is_email_mfa_enabled` is missing, clients should fall back to the email OTP
flow for safety (matching mobile/web behavior).

#### `KeyAttributes`
Server-provided encrypted key material.

```rust
pub struct KeyAttributes {
    pub kek_salt: String,                    // Salt for KEK derivation
    pub encrypted_key: String,               // Master key encrypted with KEK
    pub key_decryption_nonce: String,        // Nonce for master key
    pub public_key: String,                  // X25519 public key
    pub encrypted_secret_key: String,        // Secret key encrypted with master key
    pub secret_key_decryption_nonce: String, // Nonce for secret key
    pub mem_limit: Option<u32>,              // Argon2 memory limit
    pub ops_limit: Option<u32>,              // Argon2 ops limit
    // ... recovery key fields (optional)
}
```

#### `SrpCredentials`
Derived credentials for SRP authentication.

```rust
pub struct SrpCredentials {
    pub kek: Vec<u8>,        // Key encryption key (32 bytes)
    pub login_key: Vec<u8>,  // SRP password (16 bytes)
}
```

#### `DecryptedSecrets`
Result of successful decryption.

```rust
pub struct DecryptedSecrets {
    pub master_key: Vec<u8>,  // For data encryption
    pub secret_key: Vec<u8>,  // X25519 private key
    pub token: Vec<u8>,       // Auth token
}
```

### Functions

#### `derive_srp_credentials`
Derive both KEK and login key from password.

```rust
pub fn derive_srp_credentials(
    password: &str,
    srp_attrs: &SrpAttributes,
) -> Result<SrpCredentials>
```

Use `login_key` with your SRP client to compute srpA/srpM1. Keep `kek` for
`decrypt_secrets`.

#### `derive_kek`
Derive only the KEK (for email MFA flow).

```rust
pub fn derive_kek(
    password: &str,
    kek_salt: &str,
    mem_limit: u32,
    ops_limit: u32,
) -> Result<Vec<u8>>
```

#### `decrypt_secrets`
Decrypt master key, secret key, and token.

```rust
pub fn decrypt_secrets(
    kek: &[u8],
    key_attrs: &KeyAttributes,
    encrypted_token: &str,
) -> Result<DecryptedSecrets>
```

## Error Handling

```rust
pub enum AuthError {
    IncorrectPassword,      // Wrong password
    IncorrectRecoveryKey,   // Wrong recovery key
    InvalidKeyAttributes,   // Corrupted key data
    MissingField(&'static str), // Missing required field
    Crypto(CryptoError),    // Underlying crypto error
    Decode(String),         // Base64/hex decode error
    InvalidKey(String),     // Invalid key format
    Srp(String),            // SRP protocol error
}
```

## Key Derivation

Ente uses Argon2id for password-based key derivation:

| Strength | Memory | Ops | Use Case |
|----------|--------|-----|----------|
| Interactive | 64 MB | 2 | Normal login |
| Moderate | 256 MB | 3 | Enhanced security |
| Sensitive | 1 GB | 4 | Maximum security |

Sensitive derivation uses an adaptive mem/ops fallback that preserves the
same strength while reducing memory on constrained devices. The selected
`mem_limit` and `ops_limit` are stored in key attributes for other clients.

The server specifies `mem_limit` and `ops_limit` in `SrpAttributes`.

## Security Notes

1. **KEK never leaves the client** - Only the login key (derived from KEK) is used in SRP
2. **SRP prevents password exposure** - Server never sees the password
3. **Argon2 is slow by design** - Prevents brute-force attacks
4. **Recovery key is separate** - Can recover without password

## Example: Full Login Flow

```rust
use ente_core::auth;

async fn login(email: &str, password: &str, api: &ApiClient) -> Result<Secrets> {
    // 1. Get SRP attributes
    let srp_attrs = api.get_srp_attributes(email).await?;
    
    // 2. Check auth method
    if srp_attrs.is_email_mfa_enabled {
        // Email MFA flow
        api.send_otp(email).await?;
        let otp = prompt_user("Enter OTP:")?;
        let auth_resp = api.verify_email(email, &otp).await?;
        
        // Handle 2FA if required
        let auth_resp = handle_2fa_if_needed(auth_resp, api).await?;
        
        // Derive KEK and decrypt
        let kek = auth::derive_kek(
            password,
            &srp_attrs.kek_salt,
            srp_attrs.mem_limit,
            srp_attrs.ops_limit,
        )?;
        
        let key_attrs = auth_resp.key_attributes.unwrap();
        let encrypted_token = auth_resp.encrypted_token.unwrap();
        
        auth::decrypt_secrets(&kek, &key_attrs, &encrypted_token)
    } else {
        // SRP flow
        let creds = auth::derive_srp_credentials(password, &srp_attrs)?;

        // Use login_key with your SRP client to compute srpA/srpM1.
        let mut srp = SrpClient::new(
            &srp_attrs.srp_user_id,
            &srp_attrs.srp_salt,
            &creds.login_key,
        )?;
        let a_pub = srp.public_a();
        let server_session = api.create_srp_session(&srp_attrs.srp_user_id, &a_pub).await?;
        let m1 = srp.compute_m1(&server_session.srp_b)?;

        let auth_resp = api.verify_srp_session(&server_session.id, &m1).await?;

        // Handle 2FA if required
        let auth_resp = handle_2fa_if_needed(auth_resp, api).await?;

        let key_attrs = auth_resp.key_attributes.unwrap();
        let encrypted_token = auth_resp.encrypted_token.unwrap();

        auth::decrypt_secrets(&creds.kek, &key_attrs, &encrypted_token)
    }
}
```
