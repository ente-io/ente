//! Authentication and account management module.
//!
//! Provides cryptographic key management for:
//! - Key generation (signup)
//! - Key decryption (login)
//! - Account recovery
//! - SRP credentials (password-based authentication)
//!
//! ## Quick Start
//!
//! For SRP login flow:
//! ```ignore
//! // 1. Derive SRP credentials from password
//! let creds = auth::derive_srp_credentials(password, &srp_attrs)?;
//!
//! // 2. Use creds.login_key with your SRP client to complete the SRP exchange
//! //    (create session with srpA, then verify with srpM1)
//!
//! // 3. Decrypt secrets
//! let secrets = auth::decrypt_secrets(&creds.kek, &key_attrs, &encrypted_token)?;
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
//!
//! ## Feature Flags
//!
//! - `srp`: Enables the SRP client implementation ([`SrpSession`]) for
//!   password-based authentication handshakes.
//!   Without this feature you can still derive KEK/login keys and decrypt
//!   secrets, but you cannot perform the SRP handshake.
//!
//! ```toml
//! ente-core = { version = "0.0.1", features = ["srp"] }
//! ```

mod api;
mod key_gen;
mod login;
mod recovery;
#[cfg(any(test, feature = "srp"))]
mod srp;
mod types;

// SRP session type (behind the `srp` feature)
#[cfg(any(test, feature = "srp"))]
pub use srp::SrpSession;

/// Stub type when the `srp` feature is disabled.
///
/// This allows downstream crates to reference [`SrpSession`] in signatures and
/// get a runtime error if they accidentally call it without enabling the
/// feature.
#[cfg(not(any(test, feature = "srp")))]
pub struct SrpSession {
    _private: (),
}

#[cfg(not(any(test, feature = "srp")))]
impl SrpSession {
    fn feature_disabled() -> types::AuthError {
        types::AuthError::Srp(
            "SRP support is disabled. Enable the `srp` feature on ente-core".to_string(),
        )
    }

    /// Create a new SRP session.
    ///
    /// Always errors when the `srp` feature is disabled.
    pub fn new(_srp_user_id: &str, _srp_salt: &[u8], _login_key: &[u8]) -> types::Result<Self> {
        Err(Self::feature_disabled())
    }

    /// Get the client's public ephemeral value A.
    ///
    /// When the `srp` feature is disabled, this returns an empty vector.
    pub fn public_a(&self) -> Vec<u8> {
        Vec::new()
    }

    /// Compute the client proof M1.
    ///
    /// Always errors when the `srp` feature is disabled.
    pub fn compute_m1(&mut self, _server_b: &[u8]) -> types::Result<Vec<u8>> {
        Err(Self::feature_disabled())
    }

    /// Verify the server's proof M2.
    ///
    /// Always errors when the `srp` feature is disabled.
    pub fn verify_m2(&self, _server_m2: &[u8]) -> types::Result<()> {
        Err(Self::feature_disabled())
    }
}

// High-level API (recommended for applications)
pub use api::{DecryptedSecrets, SrpCredentials};
pub use api::{decrypt_keys_only, decrypt_secrets, derive_kek, derive_srp_credentials};

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
