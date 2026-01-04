# Auth Module

The `auth` module provides high-level authentication operations for Ente clients. It handles:

- **Login**: Password verification via SRP or email MFA
- **Signup**: Key generation for new accounts
- **Recovery**: Account recovery with recovery key
- **SRP Protocol**: Secure Remote Password authentication

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
│  • create_srp_client()      - Create SRP protocol client         │
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
 │                       │ create_srp_client(password, srp_attrs) ─────►│
 │                       │◄──────────────── (srp_client, kek) ──────────│
 │                       │                        │                     │
 │                       │ compute_a() ──────────────────────────────────►│
 │                       │◄─────────────────────────────── a_pub ────────│
 │                       │                        │                     │
 │                       │ create_srp_session(a_pub) ──►│               │
 │                       │◄─── session_id, srp_b ─│                     │
 │                       │                        │                     │
 │                       │ set_b(srp_b), compute_m1() ──────────────────►│
 │                       │◄─────────────────────────────── m1 ───────────│
 │                       │                        │                     │
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

#### `create_srp_client`
Create an SRP client ready for authentication.

```rust
pub fn create_srp_client(
    password: &str,
    srp_attrs: &SrpAttributes,
) -> Result<(SrpAuthClient, Vec<u8>)>  // (client, kek)
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

### SrpAuthClient

SRP protocol client for password authentication.

```rust
impl SrpAuthClient {
    /// Create new client
    pub fn new(srp_user_id: &str, srp_salt: &[u8], login_key: &[u8]) -> Result<Self>;
    
    /// Get client's public value A (send to server)
    pub fn compute_a(&self) -> Vec<u8>;
    
    /// Process server's public value B
    pub fn set_b(&mut self, server_b: &[u8]) -> Result<()>;
    
    /// Get proof M1 (send to server)
    pub fn compute_m1(&self) -> Vec<u8>;
    
    /// Verify server's proof M2 (optional)
    pub fn verify_m2(&self, server_m2: &[u8]) -> Result<()>;
}
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
        let (mut client, kek) = auth::create_srp_client(password, &srp_attrs)?;
        
        let a_pub = client.compute_a();
        let session = api.create_srp_session(&srp_attrs.srp_user_id, &a_pub).await?;
        
        client.set_b(&session.srp_b)?;
        let m1 = client.compute_m1();
        
        let auth_resp = api.verify_srp_session(&session.id, &m1).await?;
        
        // Handle 2FA if required
        let auth_resp = handle_2fa_if_needed(auth_resp, api).await?;
        
        let key_attrs = auth_resp.key_attributes.unwrap();
        let encrypted_token = auth_resp.encrypted_token.unwrap();
        
        auth::decrypt_secrets(&kek, &key_attrs, &encrypted_token)
    }
}
```
