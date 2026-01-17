use crate::api::client::ApiClient;
use crate::api::models::{
    AuthResponse, CreateSrpSessionRequest, CreateSrpSessionResponse, GetSrpAttributesResponse,
    SendOtpRequest, SrpAttributes, VerifyEmailRequest, VerifySrpSessionRequest, VerifyTotpRequest,
};
use crate::models::error::Result;
use base64::{Engine, engine::general_purpose::STANDARD};
use uuid::Uuid;

use ente_core::auth::{SrpAttributes as CoreSrpAttributes, SrpSession};

const SRP_A_LEN: usize = 512; // 4096-bit group

fn pad_left(data: &[u8], len: usize) -> Vec<u8> {
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
        // Step 1: Get SRP attributes
        let srp_attrs = self.get_srp_attributes(email).await?;

        let core_attrs = CoreSrpAttributes {
            srp_user_id: srp_attrs.srp_user_id.to_string(),
            srp_salt: srp_attrs.srp_salt.clone(),
            mem_limit: srp_attrs.mem_limit as u32,
            ops_limit: srp_attrs.ops_limit as u32,
            kek_salt: srp_attrs.kek_salt.clone(),
            is_email_mfa_enabled: srp_attrs.is_email_mfa_enabled,
        };

        // Step 2: Derive SRP credentials
        let creds = ente_core::auth::derive_srp_credentials(password, &core_attrs)?;

        // Step 3: Start SRP session
        let srp_salt = STANDARD.decode(&srp_attrs.srp_salt)?;
        let mut srp_session =
            SrpSession::new(&core_attrs.srp_user_id, &srp_salt, &creds.login_key)?;
        let a_pub = pad_left(&srp_session.public_a(), SRP_A_LEN);

        // Step 4: Create SRP session
        log::debug!("Creating SRP session...");
        let session = self
            .create_srp_session(&srp_attrs.srp_user_id, &a_pub)
            .await?;
        log::debug!("Session created successfully: {}", session.session_id);

        // Add a small delay to avoid potential rate limiting
        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

        // Step 5: Compute and send proof
        let server_b = STANDARD.decode(&session.srp_b)?;
        let proof = srp_session.compute_m1(&server_b)?;

        let auth_response = self
            .verify_srp_session(&srp_attrs.srp_user_id, &session.session_id, &proof)
            .await?;

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

    #[test]
    fn test_derive_srp_credentials() {
        ente_core::crypto::init().unwrap();

        let password = "test_password";

        let srp_attrs = CoreSrpAttributes {
            srp_user_id: "test-user".to_string(),
            srp_salt: STANDARD.encode([0u8; 16]),
            mem_limit: 67108864, // Interactive
            ops_limit: 2,
            kek_salt: STANDARD.encode(b"test_salt_16byte"),
            is_email_mfa_enabled: false,
        };

        let creds = ente_core::auth::derive_srp_credentials(password, &srp_attrs).unwrap();
        let srp_salt = STANDARD.decode(&srp_attrs.srp_salt).unwrap();
        let session = SrpSession::new(&srp_attrs.srp_user_id, &srp_salt, &creds.login_key).unwrap();

        assert_eq!(creds.kek.len(), 32);
        assert_eq!(creds.login_key.len(), 16);
        assert!(!session.public_a().is_empty());
    }
}
