use crate::{
    api::{ApiClient, models::*},
    models::error::{Error, Result},
};
use ente_accounts::{AccountsClient, AccountsClientConfig};
use ente_core::crypto::SecretVec;
use serde::{Serialize, de::DeserializeOwned};
use uuid::Uuid;

fn convert<T, U>(value: T) -> Result<U>
where
    T: Serialize,
    U: DeserializeOwned,
{
    serde_json::from_value(serde_json::to_value(value)?).map_err(Error::from)
}

fn shared_client(api: &ApiClient, account_id: Option<&str>) -> Result<AccountsClient> {
    let mut config = AccountsClientConfig::new(api.client_package())
        .with_base_url(api.base_url().to_string())
        .with_user_agent(format!("ente-rs/{}", env!("CARGO_PKG_VERSION")));
    if let Some(token) = account_id.and_then(|id| api.get_token(id)) {
        config = config.with_auth_token(token);
    }
    AccountsClient::new(config).map_err(Error::from)
}

/// Compatibility wrapper over `ente_accounts::AccountsClient`.
pub struct AuthClient<'a> {
    api: &'a ApiClient,
}

impl<'a> AuthClient<'a> {
    pub fn new(api: &'a ApiClient) -> Self {
        Self { api }
    }

    pub async fn get_srp_attributes(&self, email: &str) -> Result<SrpAttributes> {
        let client = shared_client(self.api, None)?;
        convert(client.get_srp_attributes(email).await?)
    }

    pub async fn create_srp_session(
        &self,
        srp_user_id: &Uuid,
        client_public: &[u8],
    ) -> Result<CreateSrpSessionResponse> {
        let client = shared_client(self.api, None)?;
        convert(
            client
                .create_srp_session(srp_user_id, client_public)
                .await?,
        )
    }

    pub async fn verify_srp_session(
        &self,
        srp_user_id: &Uuid,
        session_id: &Uuid,
        client_proof: &[u8],
    ) -> Result<AuthResponse> {
        let client = shared_client(self.api, None)?;
        convert(
            client
                .verify_srp_session(srp_user_id, session_id, client_proof)
                .await?,
        )
    }

    pub async fn login_with_srp(
        &self,
        email: &str,
        password: &str,
    ) -> Result<(AuthResponse, SecretVec)> {
        let client = shared_client(self.api, None)?;
        let (response, kek) = client.login_with_srp(email, password).await?;
        Ok((convert(response)?, kek))
    }

    pub async fn send_otp(&self, email: &str, purpose: &str) -> Result<()> {
        let client = shared_client(self.api, None)?;
        client.send_otp(email, purpose).await.map_err(Error::from)
    }

    pub async fn verify_email(
        &self,
        email: &str,
        otp: &str,
        source: Option<&str>,
    ) -> Result<AuthResponse> {
        let client = shared_client(self.api, None)?;
        convert(client.verify_email(email, otp, source).await?)
    }

    pub async fn set_user_key_attributes(
        &self,
        account_id: &str,
        key_attributes: KeyAttributes,
    ) -> Result<()> {
        let client = shared_client(self.api, Some(account_id))?;
        client
            .set_user_key_attributes(convert(key_attributes)?)
            .await
            .map_err(Error::from)
    }

    pub async fn setup_srp(
        &self,
        account_id: &str,
        request: &SetupSrpRequest,
    ) -> Result<SetupSrpResponse> {
        let client = shared_client(self.api, Some(account_id))?;
        let request = ente_accounts::models::SetupSrpRequest {
            srp_user_id: request.srp_user_id.clone(),
            srp_salt: request.srp_salt.clone(),
            srp_verifier: request.srp_verifier.clone(),
            srp_a: request.srp_a.clone(),
        };
        convert(client.setup_srp(&request).await?)
    }

    pub async fn complete_srp_setup(
        &self,
        account_id: &str,
        setup_id: &Uuid,
        srp_m1: &str,
    ) -> Result<CompleteSrpSetupResponse> {
        let client = shared_client(self.api, Some(account_id))?;
        convert(client.complete_srp_setup(setup_id, srp_m1).await?)
    }

    pub async fn verify_totp(&self, session_id: &str, code: &str) -> Result<AuthResponse> {
        let client = shared_client(self.api, None)?;
        convert(client.verify_totp(session_id, code).await?)
    }

    pub async fn check_passkey_status(&self, session_id: &str) -> Result<AuthResponse> {
        let client = shared_client(self.api, None)?;
        convert(client.check_passkey_status(session_id).await?)
    }

    pub async fn get_session_validity(&self, account_id: &str) -> Result<SessionValidityResponse> {
        let client = shared_client(self.api, Some(account_id))?;
        convert(client.get_session_validity().await?)
    }

    pub async fn setup_two_factor(&self, account_id: &str) -> Result<TwoFactorSecret> {
        let client = shared_client(self.api, Some(account_id))?;
        convert(client.setup_two_factor().await?)
    }

    pub async fn enable_two_factor(
        &self,
        account_id: &str,
        request: &EnableTwoFactorRequest,
    ) -> Result<()> {
        let client = shared_client(self.api, Some(account_id))?;
        let request = ente_accounts::models::EnableTwoFactorRequest {
            code: request.code.clone(),
            encrypted_two_factor_secret: request.encrypted_two_factor_secret.clone(),
            two_factor_secret_decryption_nonce: request.two_factor_secret_decryption_nonce.clone(),
        };
        client
            .enable_two_factor(&request)
            .await
            .map_err(Error::from)
    }
}
