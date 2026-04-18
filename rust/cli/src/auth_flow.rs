use crate::{
    api::{ApiClient, models::KeyAttributes},
    models::{
        account::{AccountSecrets, App},
        error::{Error, Result},
    },
};
use ente_accounts as shared;
use ente_core::crypto::SecretVec;
use serde::{Serialize, de::DeserializeOwned};
use std::fmt;
use zeroize::Zeroizing;

fn convert<T, U>(value: T) -> Result<U>
where
    T: Serialize,
    U: DeserializeOwned,
{
    serde_json::from_value(serde_json::to_value(value)?).map_err(Error::from)
}

fn shared_client(api_client: &ApiClient, app: App, account_id: Option<&str>) -> Result<shared::AccountsClient> {
    let mut config = shared::AccountsClientConfig::new(app.client_package())
        .with_base_url(api_client.base_url().to_string())
        .with_user_agent(format!("ente-rs/{}", env!("CARGO_PKG_VERSION")));
    if let Some(token) = account_id.and_then(|id| api_client.get_token(id)) {
        config = config.with_auth_token(token);
    }
    shared::AccountsClient::new(config).map_err(Error::from)
}

fn to_shared_error(error: Error) -> shared::Error {
    match error {
        Error::Io(source) => shared::Error::Generic(source.to_string()),
        Error::Network(source) => shared::Error::Generic(source.to_string()),
        Error::Serialization(source) => shared::Error::Serialization(source),
        Error::Database(source) => shared::Error::Generic(source.to_string()),
        Error::Crypto(message) => shared::Error::Crypto(message),
        Error::AuthenticationFailed(message) => shared::Error::AuthenticationFailed(message),
        Error::InvalidConfig(message) => shared::Error::Generic(message),
        Error::NotFound(message) => shared::Error::Generic(message),
        Error::InvalidInput(message) => shared::Error::InvalidInput(message),
        Error::Srp(message) => shared::Error::Srp(message),
        Error::Base64Decode(source) => shared::Error::Base64Decode(source),
        Error::Zip(source) => shared::Error::Generic(source.to_string()),
        Error::ApiError {
            status,
            code,
            message,
        } => shared::Error::from(ente_core::http::Error::Http {
            status,
            code,
            message,
        }),
        Error::Generic(message) => shared::Error::Generic(message),
    }
}

pub use shared::{OtpPurpose, SecondFactorMethod, TotpPurpose};

pub trait AuthFlowUi {
    fn read_email_otp(&mut self, email: &str, purpose: OtpPurpose, resent: bool) -> Result<String>;
    fn read_totp_code(&mut self, purpose: TotpPurpose) -> Result<String>;
    fn report_retryable_error(&mut self, message: &str) -> Result<()>;
    fn choose_second_factor(
        &mut self,
        methods: &[SecondFactorMethod],
    ) -> Result<SecondFactorMethod>;
    fn present_passkey_verification(&mut self, url: &str) -> Result<()>;
    fn wait_for_passkey_verification(&mut self) -> Result<()>;
    fn present_totp_secret(&mut self, secret_code: &str, qr_code: &str) -> Result<()>;
}

struct UiAdapter<'a, U> {
    inner: &'a mut U,
}

impl<U: AuthFlowUi> shared::AuthFlowUi for UiAdapter<'_, U> {
    fn read_email_otp(&mut self, email: &str, purpose: OtpPurpose, resent: bool) -> shared::Result<String> {
        self.inner
            .read_email_otp(email, purpose, resent)
            .map_err(to_shared_error)
    }

    fn read_totp_code(&mut self, purpose: TotpPurpose) -> shared::Result<String> {
        self.inner.read_totp_code(purpose).map_err(to_shared_error)
    }

    fn report_retryable_error(&mut self, message: &str) -> shared::Result<()> {
        self.inner
            .report_retryable_error(message)
            .map_err(to_shared_error)
    }

    fn choose_second_factor(
        &mut self,
        methods: &[SecondFactorMethod],
    ) -> shared::Result<SecondFactorMethod> {
        self.inner
            .choose_second_factor(methods)
            .map_err(to_shared_error)
    }

    fn present_passkey_verification(&mut self, url: &str) -> shared::Result<()> {
        self.inner
            .present_passkey_verification(url)
            .map_err(to_shared_error)
    }

    fn wait_for_passkey_verification(&mut self) -> shared::Result<()> {
        self.inner
            .wait_for_passkey_verification()
            .map_err(to_shared_error)
    }

    fn present_totp_secret(&mut self, secret_code: &str, qr_code: &str) -> shared::Result<()> {
        self.inner
            .present_totp_secret(secret_code, qr_code)
            .map_err(to_shared_error)
    }
}

pub struct CreateAccountParams {
    pub email: String,
    pub password: Zeroizing<String>,
    pub source: Option<String>,
}

impl fmt::Debug for CreateAccountParams {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("CreateAccountParams")
            .field("email", &self.email)
            .field("password", &"[REDACTED]")
            .field("source", &self.source)
            .finish()
    }
}

pub struct LoginParams {
    pub email: String,
    pub password: Zeroizing<String>,
}

impl fmt::Debug for LoginParams {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("LoginParams")
            .field("email", &self.email)
            .field("password", &"[REDACTED]")
            .finish()
    }
}

pub struct SetupTwoFactorParams {
    pub account_id: String,
    pub master_key: SecretVec,
    pub key_attributes: Option<KeyAttributes>,
}

impl fmt::Debug for SetupTwoFactorParams {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("SetupTwoFactorParams")
            .field("account_id", &self.account_id)
            .field("master_key", &"[REDACTED]")
            .field("key_attributes", &self.key_attributes)
            .finish()
    }
}

pub struct AuthenticatedAccount {
    pub user_id: i64,
    pub key_attributes: KeyAttributes,
    pub secrets: AccountSecrets,
    pub recovery_key: Option<String>,
}

impl fmt::Debug for AuthenticatedAccount {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("AuthenticatedAccount")
            .field("user_id", &self.user_id)
            .field("key_attributes", &self.key_attributes)
            .field("secrets", &self.secrets)
            .field("recovery_key", &"[REDACTED]")
            .finish()
    }
}

pub struct SetupTwoFactorResult {
    pub secret_code: String,
    pub qr_code: String,
    pub recovery_key: String,
}

impl fmt::Debug for SetupTwoFactorResult {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("SetupTwoFactorResult")
            .field("secret_code", &"[REDACTED]")
            .field("qr_code", &"[REDACTED]")
            .field("recovery_key", &"[REDACTED]")
            .finish()
    }
}

fn from_shared_account(account: shared::AuthenticatedAccount) -> Result<AuthenticatedAccount> {
    Ok(AuthenticatedAccount {
        user_id: account.user_id,
        key_attributes: convert(account.key_attributes)?,
        secrets: AccountSecrets {
            token: account.secrets.token.clone(),
            master_key: account.secrets.master_key.clone(),
            secret_key: account.secrets.secret_key.clone(),
            public_key: account.secrets.public_key.clone(),
        },
        recovery_key: account.recovery_key,
    })
}

pub struct AuthFlow<'a, U> {
    api_client: &'a ApiClient,
    app: App,
    ui: &'a mut U,
}

impl<'a, U> AuthFlow<'a, U>
where
    U: AuthFlowUi,
{
    pub fn new(api_client: &'a ApiClient, app: App, ui: &'a mut U) -> Self {
        Self { api_client, app, ui }
    }

    pub async fn create_account(
        &mut self,
        params: CreateAccountParams,
    ) -> Result<AuthenticatedAccount> {
        let client = shared_client(self.api_client, self.app, None)?;
        let mut ui = UiAdapter { inner: self.ui };
        let mut flow = shared::AuthFlow::new(&client, &mut ui);
        from_shared_account(
            flow.create_account(shared::CreateAccountParams {
                email: params.email,
                password: params.password,
                source: params.source,
            })
            .await
            .map_err(Error::from)?,
        )
    }

    pub async fn login(&mut self, params: LoginParams) -> Result<AuthenticatedAccount> {
        let client = shared_client(self.api_client, self.app, None)?;
        let mut ui = UiAdapter { inner: self.ui };
        let mut flow = shared::AuthFlow::new(&client, &mut ui);
        from_shared_account(
            flow.login(shared::LoginParams {
                email: params.email,
                password: params.password,
            })
            .await
            .map_err(Error::from)?,
        )
    }

    pub async fn setup_two_factor(
        &mut self,
        params: SetupTwoFactorParams,
    ) -> Result<SetupTwoFactorResult> {
        let client = shared_client(self.api_client, self.app, Some(&params.account_id))?;
        let mut ui = UiAdapter { inner: self.ui };
        let mut flow = shared::AuthFlow::new(&client, &mut ui);
        let result = flow
            .setup_two_factor(shared::SetupTwoFactorParams {
                master_key: params.master_key,
                key_attributes: params.key_attributes.map(convert).transpose()?,
            })
            .await
            .map_err(Error::from)?;
        Ok(SetupTwoFactorResult {
            secret_code: result.secret_code,
            qr_code: result.qr_code,
            recovery_key: result.recovery_key,
        })
    }
}
