use crate::api::client::ApiClient;
use crate::api::models::{
    AuthResponse, CreateSrpSessionRequest, CreateSrpSessionResponse, GetSrpAttributesResponse,
    SendOtpRequest, SrpAttributes, VerifyEmailRequest, VerifySrpSessionRequest, VerifyTotpRequest,
};
use crate::crypto::{derive_argon_key, derive_login_key};
use crate::models::error::Result;
use base64::{Engine, engine::general_purpose::STANDARD};
use sha2::Sha256;
use srp::client::SrpClient;
use srp::groups::G_4096;
use uuid::Uuid;

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

    /// Complete SRP authentication flow
    pub async fn login_with_srp(
        &self,
        email: &str,
        password: &str,
    ) -> Result<(AuthResponse, Vec<u8>)> {
        use rand::RngCore;

        // Step 1: Get SRP attributes
        let srp_attrs = self.get_srp_attributes(email).await?;

        // Step 2: Derive key encryption key from password
        let key_enc_key = derive_argon_key(
            password,
            &srp_attrs.kek_salt,
            srp_attrs.mem_limit as u32,
            srp_attrs.ops_limit as u32,
        )?;

        // Step 3: Derive login key
        let login_key = derive_login_key(&key_enc_key)?;

        // Step 4: Initialize SRP client
        let srp_salt = STANDARD.decode(&srp_attrs.srp_salt)?;
        // Use the UUID string directly as bytes (matching TypeScript's Buffer.from(srpUserID))
        let identity = srp_attrs.srp_user_id.to_string().into_bytes();

        // Create SRP client with 4096-bit group (matching Go's srp.GetParams(4096))
        let client = SrpClient::<Sha256>::new(&G_4096);

        // Generate random ephemeral private key
        let mut a = vec![0u8; 64];
        rand::thread_rng().fill_bytes(&mut a);

        // Compute public ephemeral
        let a_pub = client.compute_public_ephemeral(&a);

        // Step 5: Create SRP session
        log::debug!("Creating SRP session...");
        let session = self
            .create_srp_session(&srp_attrs.srp_user_id, &a_pub)
            .await?;
        log::debug!("Session created successfully: {}", session.session_id);

        // Add a small delay to avoid potential rate limiting
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        // Step 6: Process server's public key and generate proof
        let server_public = STANDARD.decode(&session.srp_b)?;

        // Process the server's response and generate client proof
        // The srp crate expects: a, username, password, salt, b_pub
        // But Ente uses the login_key (derived from password) as the password for SRP
        let verifier = client
            .process_reply(&a, &identity, &login_key, &srp_salt, &server_public)
            .map_err(|e| {
                crate::models::error::Error::AuthenticationFailed(format!(
                    "SRP client process failed: {e:?}"
                ))
            })?;

        // Step 7: Verify session with proof
        let proof = verifier.proof();

        let auth_response = self
            .verify_srp_session(&srp_attrs.srp_user_id, &session.session_id, proof)
            .await?;

        // TODO: Verify server proof if provided
        // if let Some(srp_m2) = &auth_response.srp_m2 {
        //     let server_proof = STANDARD.decode(srp_m2)?;
        //     verifier.verify_server(&server_proof).map_err(|_| {
        //         crate::models::error::Error::AuthenticationFailed(
        //             "Server proof verification failed".to_string()
        //         )
        //     })?;
        // }

        Ok((auth_response, key_enc_key))
    }

    /// Send OTP for email verification
    pub async fn send_login_otp(&self, email: &str) -> Result<()> {
        let request = SendOtpRequest {
            email: email.to_string(),
            purpose: "login".to_string(),
        };

        let _: serde_json::Value = self.api.post("/users/ott", &request, None).await?;
        Ok(())
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
    use crate::crypto::{derive_argon_key, derive_login_key};

    #[test]
    fn test_login_key_derivation() {
        // Test that login key derivation matches expected output
        let password = "test_password";
        let salt = b"test_salt_16bytes";

        let key = derive_argon_key(password, &STANDARD.encode(salt), 4, 3).unwrap();
        assert_eq!(key.len(), 32);

        let login_key = derive_login_key(&key).unwrap();
        assert_eq!(login_key.len(), 32);
    }
}
