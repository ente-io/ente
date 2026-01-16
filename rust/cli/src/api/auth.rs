//! Authentication API client.
//!
//! Handles HTTP API calls for authentication. Crypto operations are delegated
//! to ente-core's auth module.

use crate::api::client::ApiClient;
use crate::api::models::{
    AuthResponse, CreateSrpSessionRequest, CreateSrpSessionResponse, GetSrpAttributesResponse,
    SendOtpRequest, SrpAttributes, VerifyEmailRequest, VerifySrpSessionRequest, VerifyTotpRequest,
};
use crate::models::error::{Error, Result};
use base64::{Engine, engine::general_purpose::STANDARD};
use rand::RngCore;
use sha2::Sha256;
use srp::client::{SrpClient as SrpClientInner, SrpClientVerifier};
use srp::groups::G_4096;
use uuid::Uuid;

// Use ente-core for crypto operations
use ente_core::auth::SrpAttributes as CoreSrpAttributes;

struct SrpSession {
    inner: SrpClientInner<'static, Sha256>,
    identity: Vec<u8>,
    login_key: Vec<u8>,
    salt: Vec<u8>,
    a_private: Vec<u8>,
    a_public: Vec<u8>,
    verifier: Option<SrpClientVerifier<Sha256>>,
}

impl SrpSession {
    fn new(srp_user_id: &str, srp_salt: &[u8], login_key: &[u8]) -> Result<Self> {
        if login_key.len() != 16 {
            return Err(Error::Srp(format!(
                "login key must be 16 bytes, got {}",
                login_key.len()
            )));
        }

        let client = SrpClientInner::<Sha256>::new(&G_4096);

        let mut a_private = vec![0u8; 64];
        rand::rngs::OsRng.fill_bytes(&mut a_private);

        let a_public = client.compute_public_ephemeral(&a_private);
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

    fn public_a(&self) -> Vec<u8> {
        self.a_public.clone()
    }

    fn compute_m1(&mut self, server_b: &[u8]) -> Result<Vec<u8>> {
        let verifier = self
            .inner
            .process_reply(
                &self.a_private,
                &self.identity,
                &self.login_key,
                &self.salt,
                server_b,
            )
            .map_err(|e| Error::Srp(format!("Failed to process server response: {:?}", e)))?;

        let proof = verifier.proof().to_vec();
        self.verifier = Some(verifier);

        Ok(proof)
    }

    #[allow(dead_code)]
    fn verify_m2(&self, server_m2: &[u8]) -> Result<()> {
        let verifier = self
            .verifier
            .as_ref()
            .ok_or_else(|| Error::Srp("Client proof not computed".to_string()))?;

        verifier
            .verify_server(server_m2)
            .map_err(|_| Error::Srp("Server proof verification failed".to_string()))
    }
}

fn pad_bytes(data: &[u8], len: usize) -> Vec<u8> {
    if data.len() >= len {
        return data.to_vec();
    }
    let mut padded = vec![0u8; len - data.len()];
    padded.extend_from_slice(data);
    padded
}

/// SRP authentication implementation for Ente API
pub struct AuthClient<'a> {
    api: &'a ApiClient,
}

impl<'a> AuthClient<'a> {
    pub fn new(api: &'a ApiClient) -> Self {
        Self { api }
    }

    /// Get SRP attributes for a user by email
    pub async fn get_srp_attributes(&self, email: &str) -> Result<SrpAttributes> {
        let url = format!("/users/srp/attributes?email={}", urlencoding::encode(email));
        let response: GetSrpAttributesResponse = self.api.get(&url, None).await?;
        log::debug!(
            "SRP attributes response: is_email_mfa_enabled={}",
            response.attributes.is_email_mfa_enabled
        );
        Ok(response.attributes)
    }

    /// Create SRP session - first step of SRP authentication
    pub async fn create_srp_session(
        &self,
        srp_user_id: &Uuid,
        client_public: &[u8],
    ) -> Result<CreateSrpSessionResponse> {
        let request = CreateSrpSessionRequest {
            srp_user_id: srp_user_id.to_string(),
            srp_a: STANDARD.encode(client_public),
        };

        self.api
            .post("/users/srp/create-session", &request, None)
            .await
    }

    /// Verify SRP session - final step of SRP authentication
    pub async fn verify_srp_session(
        &self,
        srp_user_id: &Uuid,
        session_id: &Uuid,
        client_proof: &[u8],
    ) -> Result<AuthResponse> {
        let request = VerifySrpSessionRequest {
            srp_user_id: srp_user_id.to_string(),
            session_id: session_id.to_string(),
            srp_m1: STANDARD.encode(client_proof),
        };

        log::debug!(
            "Sending verify-session request for session_id: {}",
            request.session_id
        );

        self.api
            .post("/users/srp/verify-session", &request, None)
            .await
    }

    /// Complete SRP authentication flow using ente-core credential derivation
    pub async fn login_with_srp(
        &self,
        email: &str,
        password: &str,
    ) -> Result<(AuthResponse, Vec<u8>)> {
        // Step 1: Get SRP attributes
        let srp_attrs = self.get_srp_attributes(email).await?;

        // Step 2: Derive SRP credentials and build SRP client state
        println!("Deriving encryption key (this may take a few seconds)...");
        let core_attrs = CoreSrpAttributes {
            srp_user_id: srp_attrs.srp_user_id.to_string(),
            srp_salt: srp_attrs.srp_salt.clone(),
            mem_limit: srp_attrs.mem_limit as u32,
            ops_limit: srp_attrs.ops_limit as u32,
            kek_salt: srp_attrs.kek_salt.clone(),
            is_email_mfa_enabled: srp_attrs.is_email_mfa_enabled,
        };

        let creds = ente_core::auth::derive_srp_credentials(password, &core_attrs)
            .map_err(|e| Error::Crypto(e.to_string()))?;
        let srp_salt = STANDARD
            .decode(&srp_attrs.srp_salt)
            .map_err(|e| Error::Crypto(format!("Invalid srp_salt: {}", e)))?;

        let mut srp_session = SrpSession::new(
            &srp_attrs.srp_user_id.to_string(),
            &srp_salt,
            &creds.login_key,
        )?;

        // Step 3: Get client's public value and create session
        let a_pub = pad_bytes(&srp_session.public_a(), 512);

        log::debug!("Creating SRP session...");
        let session = self
            .create_srp_session(&srp_attrs.srp_user_id, &a_pub)
            .await?;
        log::debug!("Session created successfully: {}", session.session_id);

        // Add a small delay to avoid potential rate limiting
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        // Step 4: Decode server's public key
        let server_b = STANDARD
            .decode(&session.srp_b)
            .map_err(|e| Error::Crypto(format!("Invalid server B: {}", e)))?;

        // Step 5: Compute proof using server's public value
        let proof = srp_session.compute_m1(&server_b)?;
        let proof = pad_bytes(&proof, 32);

        let auth_response = self
            .verify_srp_session(&srp_attrs.srp_user_id, &session.session_id, &proof)
            .await?;

        // TODO: Verify server proof if provided
        // if let Some(srp_m2) = &auth_response.srp_m2 {
        //     let server_proof = STANDARD.decode(srp_m2)?;
        //     srp_session.verify_m2(&server_proof)?;
        // }

        Ok((auth_response, creds.kek))
    }

    /// Send OTP for email verification
    pub async fn send_login_otp(&self, email: &str) -> Result<()> {
        let request = SendOtpRequest {
            email: email.to_string(),
            purpose: "login".to_string(),
        };

        self.api.post_empty("/users/ott", &request, None).await
    }

    /// Verify email with OTP
    pub async fn verify_email(&self, email: &str, otp: &str) -> Result<AuthResponse> {
        let request = VerifyEmailRequest {
            email: email.to_string(),
            ott: otp.to_string(),
        };

        self.api.post("/users/verify-email", &request, None).await
    }

    /// Verify TOTP for two-factor authentication
    pub async fn verify_totp(&self, session_id: &str, code: &str) -> Result<AuthResponse> {
        let request = VerifyTotpRequest {
            session_id: session_id.to_string(),
            code: code.to_string(),
        };

        self.api
            .post("/users/two-factor/verify", &request, None)
            .await
    }

    /// Check passkey verification status
    pub async fn check_passkey_status(&self, session_id: &str) -> Result<AuthResponse> {
        let url = format!("/users/two-factor/passkeys/get-token?sessionID={session_id}");
        self.api.get(&url, None).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use base64::engine::general_purpose::STANDARD;

    #[test]
    fn test_login_key_derivation() {
        ente_core::crypto::init().unwrap();

        // Test that ente-core's key derivation works correctly
        let password = "test_password";
        let salt = b"test_salt_16byte"; // Exactly 16 bytes

        let srp_attrs = CoreSrpAttributes {
            srp_user_id: "test-user".to_string(),
            srp_salt: STANDARD.encode([0u8; 16]),
            mem_limit: 67108864, // Interactive
            ops_limit: 2,
            kek_salt: STANDARD.encode(salt),
            is_email_mfa_enabled: false,
        };

        let creds = ente_core::auth::derive_srp_credentials(password, &srp_attrs).unwrap();
        let srp_salt = STANDARD.decode(&srp_attrs.srp_salt).unwrap();
        let session = SrpSession::new(&srp_attrs.srp_user_id, &srp_salt, &creds.login_key).unwrap();

        assert_eq!(creds.kek.len(), 32);
        assert!(!session.public_a().is_empty());
    }
}
