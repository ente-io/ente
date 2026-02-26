//! SRP (Secure Remote Password) session implementation.
//!
//! Provides a minimal SRP client state machine that avoids exposing low-level
//! step ordering (e.g. calling set_b before compute_m1). Callers only need to
//! exchange the public value and proofs with the server.

use sha2::{Digest, Sha256};
use srp::client::SrpClient as SrpClientInner;
use srp::groups::G_4096;
use subtle::ConstantTimeEq;
use zeroize::Zeroize;

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
    m1: Option<Vec<u8>>,
    k: Option<Vec<u8>>,
}

const SRP_N_BYTES: usize = 512; // 4096-bit group size

fn pad_to_n(input: &[u8]) -> Vec<u8> {
    if input.len() >= SRP_N_BYTES {
        return input.to_vec();
    }

    let mut out = vec![0u8; SRP_N_BYTES - input.len()];
    out.extend_from_slice(input);
    out
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
            m1: None,
            k: None,
        })
    }

    /// Get the client's public ephemeral value A (padded to N length).
    ///
    /// This should be sent to the server to create an SRP session.
    /// Returns raw bytes (caller should base64 encode for API).
    pub fn public_a(&self) -> Vec<u8> {
        pad_to_n(&self.a_public)
    }

    /// Compute the client proof M1 from the server's public value B.
    ///
    /// This processes the server reply and stores internal state for
    /// `verify_m2()`.
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

        // The srp crate uses S directly for M2, but our server uses K = H(S).
        // Compute the proof values the way the server does.
        let s = verifier.key();
        let s_padded = pad_to_n(s);
        let a_padded = pad_to_n(&self.a_public);
        let b_padded = pad_to_n(server_b);

        // M1 = H(A | B | S)
        let mut m1_hasher = Sha256::new();
        m1_hasher.update(&a_padded);
        m1_hasher.update(&b_padded);
        m1_hasher.update(&s_padded);
        let m1 = m1_hasher.finalize().to_vec();

        // K = H(S)
        let mut k_hasher = Sha256::new();
        k_hasher.update(&s_padded);
        let k = k_hasher.finalize().to_vec();

        self.m1 = Some(m1.clone());
        self.k = Some(k);

        // No longer needed after we have computed M1/K.
        self.login_key.zeroize();
        self.a_private.zeroize();

        Ok(m1)
    }

    /// Verify the server's proof M2.
    ///
    /// # Arguments
    /// * `server_m2` - The server's proof M2 (raw bytes, not base64)
    pub fn verify_m2(&self, server_m2: &[u8]) -> Result<()> {
        let m1 = self
            .m1
            .as_ref()
            .ok_or_else(|| AuthError::Srp("Client proof not computed".to_string()))?;
        let k = self
            .k
            .as_ref()
            .ok_or_else(|| AuthError::Srp("Client proof not computed".to_string()))?;

        let a_padded = pad_to_n(&self.a_public);

        // M2 = H(A | M1 | K)
        let mut m2_hasher = Sha256::new();
        m2_hasher.update(&a_padded);
        m2_hasher.update(m1);
        m2_hasher.update(k);
        let expected = m2_hasher.finalize().to_vec();

        if expected.ct_eq(server_m2).unwrap_u8() != 1 {
            return Err(AuthError::Srp(
                "Server proof verification failed".to_string(),
            ));
        }

        Ok(())
    }
}

impl Drop for SrpSession {
    fn drop(&mut self) {
        self.login_key.zeroize();
        self.a_private.zeroize();
        if let Some(k) = &mut self.k {
            k.zeroize();
        }
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
        assert!(a.len() >= SRP_N_BYTES);
    }

    #[test]
    fn test_public_a_padding() {
        let a_public = vec![0xAB, 0xCD];
        let session = SrpSession {
            inner: SrpClientInner::<Sha256>::new(&G_4096),
            identity: b"test-user".to_vec(),
            login_key: vec![0u8; 16],
            salt: vec![0u8; 16],
            a_private: vec![0u8; 64],
            a_public: a_public.clone(),
            m1: None,
            k: None,
        };

        let padded = session.public_a();

        assert_eq!(padded.len(), SRP_N_BYTES);
        assert!(
            padded[..SRP_N_BYTES - a_public.len()]
                .iter()
                .all(|&b| b == 0)
        );
        assert_eq!(&padded[SRP_N_BYTES - a_public.len()..], a_public.as_slice());
    }

    #[test]
    fn test_compute_m1_and_verify_m2_match_expected() {
        crypto::init().unwrap();

        use srp::server::SrpServer;

        let srp_user_id = "test-user-id";
        let srp_salt = [0x22u8; 16];
        let login_key = [0x11u8; 16];

        let client = SrpClientInner::<Sha256>::new(&G_4096);
        let verifier = client.compute_verifier(srp_user_id.as_bytes(), &login_key, &srp_salt);

        let server = SrpServer::<Sha256>::new(&G_4096);
        let b_private = [0x33u8; 64];
        let b_pub = server.compute_public_ephemeral(&b_private, &verifier);

        let a_private = vec![0x44u8; 64];
        let a_public = client.compute_public_ephemeral(&a_private);

        let mut session = SrpSession {
            inner: SrpClientInner::<Sha256>::new(&G_4096),
            identity: srp_user_id.as_bytes().to_vec(),
            login_key: login_key.to_vec(),
            salt: srp_salt.to_vec(),
            a_private: a_private.clone(),
            a_public: a_public.clone(),
            m1: None,
            k: None,
        };

        let m1 = session.compute_m1(&b_pub).unwrap();

        let verifier_client = SrpClientInner::<Sha256>::new(&G_4096);
        let verifier = verifier_client
            .process_reply(
                &a_private,
                srp_user_id.as_bytes(),
                &login_key,
                &srp_salt,
                &b_pub,
            )
            .unwrap();

        let s = verifier.key();
        let s_padded = pad_to_n(s);
        let a_padded = pad_to_n(&a_public);
        let b_padded = pad_to_n(&b_pub);

        let mut m1_hasher = Sha256::new();
        m1_hasher.update(&a_padded);
        m1_hasher.update(&b_padded);
        m1_hasher.update(&s_padded);
        let expected_m1 = m1_hasher.finalize().to_vec();

        let mut k_hasher = Sha256::new();
        k_hasher.update(&s_padded);
        let expected_k = k_hasher.finalize().to_vec();

        assert_eq!(m1, expected_m1);
        assert_eq!(session.m1.as_ref().unwrap(), &expected_m1);
        assert_eq!(session.k.as_ref().unwrap(), &expected_k);

        let mut m2_hasher = Sha256::new();
        m2_hasher.update(&a_padded);
        m2_hasher.update(&expected_m1);
        m2_hasher.update(&expected_k);
        let expected_m2 = m2_hasher.finalize().to_vec();

        session.verify_m2(&expected_m2).unwrap();

        let mut bad_m2 = expected_m2.clone();
        bad_m2[0] ^= 0x01;
        assert!(session.verify_m2(&bad_m2).is_err());
    }

    #[test]
    fn test_sensitive_buffers_zeroized_after_compute_m1() {
        crypto::init().unwrap();

        use rand_core::RngCore;
        use srp::server::SrpServer;

        let srp_user_id = "test-user-id";
        let srp_salt = [0u8; 16];
        let login_key = [0x11u8; 16];

        let client = SrpClientInner::<Sha256>::new(&G_4096);
        let verifier = client.compute_verifier(srp_user_id.as_bytes(), &login_key, &srp_salt);

        let server = SrpServer::<Sha256>::new(&G_4096);
        let mut b = [0u8; 64];
        rand_core::OsRng.fill_bytes(&mut b);
        let b_pub = server.compute_public_ephemeral(&b, &verifier);

        let mut session = SrpSession::new(srp_user_id, &srp_salt, &login_key).unwrap();
        session.compute_m1(&b_pub).unwrap();

        assert!(session.login_key.iter().all(|&b| b == 0));
        assert!(session.a_private.iter().all(|&b| b == 0));
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
