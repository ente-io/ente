//! Authentication and account management module.
//!
//! Provides cryptographic key management for:
//! - Key generation (signup)
//! - Key decryption (login)
//! - Account recovery
//! - SRP protocol (password-based authentication)
//!
//! ## Quick Start
//!
//! For SRP login flow:
//! ```ignore
//! // 1. Derive credentials and create SRP client
//! let (mut srp_client, kek) = auth::create_srp_client(password, &srp_attrs)?;
//!
//! // 2. Get client's public value and send to server
//! let a_pub = srp_client.compute_a();
//! let session = api.create_srp_session(&a_pub).await?;
//!
//! // 3. Process server's response
//! srp_client.set_b(&session.srp_b)?;
//! let m1 = srp_client.compute_m1();
//!
//! // 4. Verify with server
//! let auth_response = api.verify_srp_session(&m1).await?;
//!
//! // 5. Decrypt secrets
//! let secrets = auth::decrypt_secrets(&kek, &key_attrs, &encrypted_token)?;
//! ```
//!
//! For email MFA flow (no SRP):
//! ```ignore
//! // 1. Derive KEK from password
//! let kek = auth::derive_kek(password, &kek_salt, mem_limit, ops_limit)?;
//!
//! // 2. Do email OTP + TOTP verification via API
//!
//! // 3. Decrypt secrets
//! let secrets = auth::decrypt_secrets(&kek, &key_attrs, &encrypted_token)?;
//! ```

mod api;
mod key_gen;
mod login;
mod recovery;
mod srp;
mod types;

// High-level API (recommended for applications)
pub use api::{DecryptedSecrets, SrpCredentials};
pub use api::{create_srp_client, decrypt_secrets, derive_kek, derive_srp_credentials};
pub use srp::SrpAuthClient;

// Key generation (for signup)
pub use key_gen::{
    KeyDerivationStrength, create_new_recovery_key, generate_key_attributes_for_new_password,
    generate_key_attributes_for_new_password_with_strength, generate_keys,
    generate_keys_with_strength,
};

// Lower-level login utilities (prefer api module for new code)
pub use login::{
    decrypt_secrets as decrypt_secrets_legacy, decrypt_secrets_with_kek, derive_keys_for_login,
    derive_login_key_for_srp,
};

// Recovery
pub use recovery::{get_recovery_key, recover_with_key};

// Types
pub use types::{
    AuthError, KeyAttributes, KeyGenResult, LoginResult, PrivateKeyAttributes, Result,
    SrpAttributes,
};
