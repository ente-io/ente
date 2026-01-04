//! Authentication API client.
//!
//! Handles HTTP API calls for authentication. Crypto operations are delegated
//! to ente-core's auth module.

use crate::api::client::ApiClient;
use crate::api::models::{
    AuthResponse, CreateSrpSessionRequest, CreateSrpSessionResponse, GetSrpAttributesResponse,
    SendOtpRequest, SrpAttributes, VerifyEmailRequest, VerifySrpSessionRequest, VerifyTotpRequest,
};
use crate::models::error::Result;
use base64::{Engine, engine::general_purpose::STANDARD};
use uuid::Uuid;

// Use ente-core for crypto operations
use ente_core::auth::SrpAttributes as CoreSrpAttributes;

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

    /// Complete SRP authentication flow using ente-core
    pub async fn login_with_srp(
        &self,
        email: &str,
        password: &str,
    ) -> Result<(AuthResponse, Vec<u8>)> {
        // Step 1: Get SRP attributes
        let srp_attrs = self.get_srp_attributes(email).await?;

        // Step 2: Create SRP client using ente-core (handles key derivation)
        println!("Deriving encryption key (this may take a few seconds)...");
        let core_attrs = CoreSrpAttributes {
            srp_user_id: srp_attrs.srp_user_id.to_string(),
            srp_salt: srp_attrs.srp_salt.clone(),
            mem_limit: srp_attrs.mem_limit as u32,
            ops_limit: srp_attrs.ops_limit as u32,
            kek_salt: srp_attrs.kek_salt.clone(),
            is_email_mfa_enabled: srp_attrs.is_email_mfa_enabled,
        };

        let (mut srp_client, kek) = ente_core::auth::create_srp_client(password, &core_attrs)
            .map_err(|e| crate::models::error::Error::Crypto(e.to_string()))?;

        // Step 3: Get client's public value and create session
        let a_pub = srp_client.compute_a();

        log::debug!("Creating SRP session...");
        let session = self
            .create_srp_session(&srp_attrs.srp_user_id, &a_pub)
            .await?;
        log::debug!("Session created successfully: {}", session.session_id);

        // Add a small delay to avoid potential rate limiting
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        // Step 4: Process server's public key
        let server_b = STANDARD
            .decode(&session.srp_b)
            .map_err(|e| crate::models::error::Error::Crypto(format!("Invalid server B: {}", e)))?;

        srp_client
            .set_b(&server_b)
            .map_err(|e| crate::models::error::Error::Crypto(e.to_string()))?;

        // Step 5: Generate proof and verify session
        let proof = srp_client.compute_m1();

        let auth_response = self
            .verify_srp_session(&srp_attrs.srp_user_id, &session.session_id, &proof)
            .await?;

        // TODO: Verify server proof if provided
        // if let Some(srp_m2) = &auth_response.srp_m2 {
        //     let server_proof = STANDARD.decode(srp_m2)?;
        //     srp_client.verify_m2(&server_proof)?;
        // }

        Ok((auth_response, kek))
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

        let (client, kek) = ente_core::auth::create_srp_client(password, &srp_attrs).unwrap();

        assert_eq!(kek.len(), 32);
        assert!(!client.compute_a().is_empty());
    }
}
