//! SRP (Secure Remote Password) session implementation.
//!
//! Provides a minimal SRP client state machine that avoids exposing low-level
//! step ordering (e.g. calling set_b before compute_m1). Callers only need to
//! exchange the public value and proofs with the server.

use sha2::Sha256;
use srp::client::{SrpClient as SrpClientInner, SrpClientVerifier};
use srp::groups::G_4096;

use super::{AuthError, Result};

/// SRP session for password-based authentication.
///
/// Usage:
/// 1. Create session with `new()`
/// 2. Send `public_a()` to the server
/// 3. Call `compute_m1(server_b)` to get the client proof
/// 4. Optionally verify server proof with `verify_m2(server_m2)`
pub struct SrpSession {
    inner: SrpClientInner<'static, Sha256>,
    identity: Vec<u8>,
    login_key: Vec<u8>,
    salt: Vec<u8>,
    a_private: Vec<u8>,
    a_public: Vec<u8>,
    verifier: Option<SrpClientVerifier<Sha256>>,
}

impl SrpSession {
    /// Create a new SRP session.
    ///
    /// # Arguments
    /// * `srp_user_id` - The SRP user ID (UUID string)
    /// * `srp_salt` - The SRP salt (raw bytes, not base64)
    /// * `login_key` - The login key derived from password (16 bytes)
    pub fn new(srp_user_id: &str, srp_salt: &[u8], login_key: &[u8]) -> Result<Self> {
        if login_key.len() != 16 {
            return Err(AuthError::InvalidKey(format!(
                "Login key must be 16 bytes, got {}",
                login_key.len()
            )));
        }

        let client = SrpClientInner::<Sha256>::new(&G_4096);

        // Generate random ephemeral private key (64 bytes)
        let mut a_private = vec![0u8; 64];
        getrandom::getrandom(&mut a_private)
            .map_err(|e| AuthError::Srp(format!("Failed to generate random bytes: {}", e)))?;

        // Compute public ephemeral
        let a_public = client.compute_public_ephemeral(&a_private);

        // Use the UUID string directly as bytes (matching TypeScript)
        let identity = srp_user_id.as_bytes().to_vec();

        Ok(Self {
            inner: client,
            identity,
            login_key: login_key.to_vec(),
            salt: srp_salt.to_vec(),
            a_private,
            a_public,
            verifier: None,
        })
    }

    /// Get the client's public ephemeral value A.
    ///
    /// This should be sent to the server to create an SRP session.
    /// Returns raw bytes (caller should base64 encode for API).
    pub fn public_a(&self) -> Vec<u8> {
        self.a_public.clone()
    }

    /// Compute the client proof M1 from the server's public value B.
    ///
    /// This processes the server reply and stores internal verifier state
    /// for optional `verify_m2()`.
    pub fn compute_m1(&mut self, server_b: &[u8]) -> Result<Vec<u8>> {
        let verifier = self
            .inner
            .process_reply(
                &self.a_private,
                &self.identity,
                &self.login_key,
                &self.salt,
                server_b,
            )
            .map_err(|e| AuthError::Srp(format!("Failed to process server response: {:?}", e)))?;

        let proof = verifier.proof().to_vec();
        self.verifier = Some(verifier);

        Ok(proof)
    }

    /// Verify the server's proof M2.
    ///
    /// # Arguments
    /// * `server_m2` - The server's proof M2 (raw bytes, not base64)
    pub fn verify_m2(&self, server_m2: &[u8]) -> Result<()> {
        let verifier = self
            .verifier
            .as_ref()
            .ok_or_else(|| AuthError::Srp("Client proof not computed".to_string()))?;

        verifier
            .verify_server(server_m2)
            .map_err(|_| AuthError::Srp("Server proof verification failed".to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::crypto;

    #[test]
    fn test_srp_session_creation() {
        crypto::init().unwrap();

        let srp_user_id = "test-user-id";
        let srp_salt = [0u8; 16];
        let login_key = [0u8; 16];

        let session = SrpSession::new(srp_user_id, &srp_salt, &login_key).unwrap();

        // Public value should be generated
        let a = session.public_a();
        assert!(!a.is_empty());
        assert!(a.len() > 100); // 4096-bit group produces large values
    }

    #[test]
    fn test_srp_session_invalid_login_key() {
        let srp_user_id = "test-user-id";
        let srp_salt = [0u8; 16];
        let login_key = [0u8; 32]; // Wrong size

        let result = SrpSession::new(srp_user_id, &srp_salt, &login_key);
        assert!(result.is_err());
    }

    #[test]
    fn test_verify_m2_requires_m1() {
        let srp_user_id = "test-user-id";
        let srp_salt = [0u8; 16];
        let login_key = [0u8; 16];

        let session = SrpSession::new(srp_user_id, &srp_salt, &login_key).unwrap();
        let result = session.verify_m2(&[0u8; 32]);
        assert!(result.is_err());
    }
}
