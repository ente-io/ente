use crate::{
    api::{
        ApiClient, AuthClient,
        models::{
            AuthResponse, EnableTwoFactorRequest, KeyAttributes, SetupSrpRequest,
            SrpAttributes as RemoteSrpAttributes,
        },
    },
    models::{
        account::{AccountSecrets, App},
        error::{Error, Result},
    },
};
use base64::{
    Engine,
    engine::general_purpose::{STANDARD, URL_SAFE},
};
use ente_core::{
    auth::{
        self, DecryptedSecrets, GeneratedSrpSetup, KeyAttributes as CoreKeyAttributes,
        KeyDerivationStrength, derive_kek, generate_keys_with_strength, generate_srp_setup,
        get_recovery_key,
    },
    crypto::{self, SecretVec, secretbox},
};
use std::fmt;
use uuid::Uuid;
use zeroize::Zeroizing;

const SRP_A_LEN: usize = 512; // 4096-bit group

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OtpPurpose {
    Login,
    Signup,
}

impl OtpPurpose {
    fn as_api_purpose(self) -> &'static str {
        match self {
            OtpPurpose::Login => "login",
            OtpPurpose::Signup => "signup",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TotpPurpose {
    Login,
    Setup,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SecondFactorMethod {
    Totp,
    Passkey,
}

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
        Self {
            api_client,
            app,
            ui,
        }
    }

    pub async fn create_account(
        &mut self,
        params: CreateAccountParams,
    ) -> Result<AuthenticatedAccount> {
        self.create_account_with_strength(params, KeyDerivationStrength::Sensitive)
            .await
    }

    async fn create_account_with_strength(
        &mut self,
        params: CreateAccountParams,
        key_derivation_strength: KeyDerivationStrength,
    ) -> Result<AuthenticatedAccount> {
        crypto::init()?;

        let auth_client = AuthClient::new(self.api_client);
        let email = params.email;
        let password = params.password;

        auth_client
            .send_otp(&email, OtpPurpose::Signup.as_api_purpose())
            .await?;

        let verification = self
            .verify_email_otp(
                &auth_client,
                &email,
                OtpPurpose::Signup,
                params.source.as_deref(),
            )
            .await?;

        let token = verification.token.clone().ok_or_else(|| {
            Error::AuthenticationFailed("Signup verification did not return a session token".into())
        })?;

        self.api_client.add_token(&email, &token);
        let session_validity = auth_client.get_session_validity(&email).await?;
        if verification.key_attributes.is_some()
            || verification.encrypted_token.is_some()
            || verification.is_mfa_required()
            || verification.is_passkey_required()
            || session_validity.has_set_keys
            || session_validity.key_attributes.is_some()
        {
            return Err(Error::AuthenticationFailed(
                "Email already has server-side key state; use 'ente account add' or recover the incomplete signup instead of creating a new account.".into(),
            ));
        }

        let key_gen_result = generate_keys_with_strength(&password, key_derivation_strength)?;

        let srp_user_id = Uuid::new_v4();
        let srp_setup =
            generate_srp_setup(&key_gen_result.key_encryption_key, &srp_user_id.to_string())?;
        let key_attributes = to_api_key_attributes(&key_gen_result.key_attributes);

        auth_client
            .set_user_key_attributes(&email, key_attributes.clone())
            .await?;
        self.complete_signup_srp(&auth_client, &email, &srp_user_id, &srp_setup)
            .await?;
        let remote_srp_attributes = auth_client.get_srp_attributes(&email).await?;
        validate_remote_srp_attributes(
            &remote_srp_attributes,
            &srp_user_id,
            &srp_setup,
            &key_attributes,
        )?;

        let secrets = AccountSecrets {
            token: decode_plain_token(&token)?.into_vec(),
            master_key: crypto::decode_b64(&key_gen_result.private_key_attributes.key)?,
            secret_key: crypto::decode_b64(&key_gen_result.private_key_attributes.secret_key)?,
            public_key: crypto::decode_b64(&key_attributes.public_key)?,
        };

        Ok(AuthenticatedAccount {
            user_id: verification.id,
            key_attributes,
            secrets,
            recovery_key: Some(key_gen_result.private_key_attributes.recovery_key),
        })
    }

    pub async fn login(&mut self, params: LoginParams) -> Result<AuthenticatedAccount> {
        crypto::init()?;

        let auth_client = AuthClient::new(self.api_client);
        let srp_attrs = auth_client.get_srp_attributes(&params.email).await?;

        let (auth_response, kek) = if srp_attrs.is_email_mfa_enabled {
            auth_client
                .send_otp(&params.email, OtpPurpose::Login.as_api_purpose())
                .await?;
            let response = self
                .verify_email_otp(&auth_client, &params.email, OtpPurpose::Login, None)
                .await?;
            let response = self.resolve_second_factor(&auth_client, response).await?;
            let kek = derive_kek(
                &params.password,
                &srp_attrs.kek_salt,
                srp_attrs.mem_limit as u32,
                srp_attrs.ops_limit as u32,
            )?;
            (response, kek)
        } else {
            let (response, kek) = auth_client
                .login_with_srp(&params.email, &params.password)
                .await?;
            let response = self.resolve_second_factor(&auth_client, response).await?;
            (response, kek)
        };

        self.build_authenticated_account(auth_response, &kek)
    }

    pub async fn setup_two_factor(
        &mut self,
        params: SetupTwoFactorParams,
    ) -> Result<SetupTwoFactorResult> {
        crypto::init()?;

        let auth_client = AuthClient::new(self.api_client);
        let key_attributes = if let Some(key_attributes) = params.key_attributes {
            key_attributes
        } else {
            auth_client
                .get_session_validity(&params.account_id)
                .await?
                .key_attributes
                .ok_or_else(|| {
                    Error::AuthenticationFailed(
                        "Account keys are not available for two-factor setup".into(),
                    )
                })?
        };

        let recovery_key =
            get_recovery_key(&params.master_key, &to_core_key_attributes(&key_attributes))
                .map_err(Error::from)?;

        let secret = auth_client.setup_two_factor(&params.account_id).await?;
        self.ui
            .present_totp_secret(&secret.secret_code, &secret.qr_code)?;

        loop {
            let code = self.ui.read_totp_code(TotpPurpose::Setup)?;
            let request = encrypt_two_factor_secret(&secret.secret_code, &recovery_key, &code)?;

            match auth_client
                .enable_two_factor(&params.account_id, &request)
                .await
            {
                Ok(()) => {
                    return Ok(SetupTwoFactorResult {
                        secret_code: secret.secret_code,
                        qr_code: secret.qr_code,
                        recovery_key,
                    });
                }
                Err(Error::ApiError {
                    status: 400 | 401, ..
                }) => {
                    self.ui.report_retryable_error(
                        "Incorrect TOTP code. Enter the current code from your authenticator app and try again.",
                    )?;
                }
                Err(e) => return Err(e),
            }
        }
    }

    fn build_authenticated_account(
        &self,
        auth_response: AuthResponse,
        kek: &[u8],
    ) -> Result<AuthenticatedAccount> {
        let key_attributes = auth_response
            .key_attributes
            .clone()
            .ok_or_else(|| Error::AuthenticationFailed("No key attributes".into()))?;

        let core_key_attributes = to_core_key_attributes(&key_attributes);
        let secrets = decrypt_auth_response(&auth_response, &core_key_attributes, kek)?;
        let public_key = crypto::decode_b64(&key_attributes.public_key)?;
        let recovery_key = get_recovery_key(&secrets.master_key, &core_key_attributes).ok();

        Ok(AuthenticatedAccount {
            user_id: auth_response.id,
            key_attributes,
            secrets: AccountSecrets {
                token: secrets.token.into_vec(),
                master_key: secrets.master_key.into_vec(),
                secret_key: secrets.secret_key.into_vec(),
                public_key,
            },
            recovery_key,
        })
    }

    async fn verify_email_otp(
        &mut self,
        auth_client: &AuthClient<'_>,
        email: &str,
        purpose: OtpPurpose,
        source: Option<&str>,
    ) -> Result<AuthResponse> {
        let mut resent = false;

        loop {
            let otp = self.ui.read_email_otp(email, purpose, resent)?;
            match auth_client.verify_email(email, &otp, source).await {
                Ok(response) => return Ok(response),
                Err(Error::ApiError {
                    status: 400 | 401, ..
                }) => {
                    self.ui
                        .report_retryable_error("Incorrect email verification code. Try again.")?;
                    resent = false;
                }
                Err(Error::ApiError { status: 410, .. }) => {
                    auth_client
                        .send_otp(email, purpose.as_api_purpose())
                        .await?;
                    resent = true;
                }
                Err(e) => return Err(e),
            }
        }
    }

    async fn resolve_second_factor(
        &mut self,
        auth_client: &AuthClient<'_>,
        auth_response: AuthResponse,
    ) -> Result<AuthResponse> {
        let has_totp = auth_response.get_two_factor_session_id().is_some();
        let has_passkey = auth_response.is_passkey_required();

        let method = match (has_totp, has_passkey) {
            (false, false) => return Ok(auth_response),
            (true, false) => SecondFactorMethod::Totp,
            (false, true) => SecondFactorMethod::Passkey,
            (true, true) => self
                .ui
                .choose_second_factor(&[SecondFactorMethod::Totp, SecondFactorMethod::Passkey])?,
        };

        match method {
            SecondFactorMethod::Totp => self.verify_totp(auth_client, &auth_response).await,
            SecondFactorMethod::Passkey => self.verify_passkey(auth_client, &auth_response).await,
        }
    }

    async fn verify_totp(
        &mut self,
        auth_client: &AuthClient<'_>,
        auth_response: &AuthResponse,
    ) -> Result<AuthResponse> {
        let session_id = auth_response
            .get_two_factor_session_id()
            .ok_or_else(|| Error::AuthenticationFailed("No 2FA session ID".into()))?;

        loop {
            let code = self.ui.read_totp_code(TotpPurpose::Login)?;
            match auth_client.verify_totp(session_id, &code).await {
                Ok(response) => return Ok(response),
                Err(Error::ApiError {
                    status: 400 | 401, ..
                }) => {
                    self.ui
                        .report_retryable_error("Incorrect TOTP code. Try again.")?;
                }
                Err(Error::ApiError { status: 410, .. }) => {
                    return Err(Error::AuthenticationFailed(
                        "TOTP session expired. Please restart login.".into(),
                    ));
                }
                Err(e) => return Err(e),
            }
        }
    }

    async fn verify_passkey(
        &mut self,
        auth_client: &AuthClient<'_>,
        auth_response: &AuthResponse,
    ) -> Result<AuthResponse> {
        let passkey_session_id = auth_response
            .passkey_session_id
            .as_ref()
            .filter(|session_id| !session_id.is_empty())
            .ok_or_else(|| Error::AuthenticationFailed("No passkey session ID".into()))?;

        let accounts_url = auth_response
            .accounts_url
            .as_ref()
            .filter(|url| !url.is_empty())
            .map(String::as_str)
            .unwrap_or("https://accounts.ente.io");

        let verification_url = format!(
            "{accounts_url}/passkeys/verify?passkeySessionID={passkey_session_id}&redirect=ente-cli://passkey&clientPackage={}",
            self.app.client_package()
        );

        self.ui.present_passkey_verification(&verification_url)?;

        loop {
            self.ui.wait_for_passkey_verification()?;
            match auth_client.check_passkey_status(passkey_session_id).await {
                Ok(result) => return Ok(result),
                Err(Error::ApiError {
                    status: 400 | 404, ..
                }) => {}
                Err(Error::ApiError { status: 410, .. }) => {
                    return Err(Error::AuthenticationFailed(
                        "Passkey session expired. Please restart login.".into(),
                    ));
                }
                Err(e) => return Err(e),
            }
        }
    }

    async fn complete_signup_srp(
        &self,
        auth_client: &AuthClient<'_>,
        account_id: &str,
        srp_user_id: &Uuid,
        srp_setup: &GeneratedSrpSetup,
    ) -> Result<()> {
        let mut srp_session = auth::SrpSession::new(
            &srp_user_id.to_string(),
            &srp_setup.srp_salt,
            &srp_setup.login_sub_key,
        )?;
        let srp_a = STANDARD.encode(pad_left(&srp_session.public_a(), SRP_A_LEN));

        let response = auth_client
            .setup_srp(
                account_id,
                &SetupSrpRequest {
                    srp_user_id: srp_user_id.to_string(),
                    srp_salt: STANDARD.encode(&srp_setup.srp_salt),
                    srp_verifier: STANDARD.encode(&srp_setup.srp_verifier),
                    srp_a,
                },
            )
            .await?;

        let srp_b = STANDARD.decode(&response.srp_b)?;
        let srp_m1 = STANDARD.encode(srp_session.compute_m1(&srp_b)?);

        let complete = auth_client
            .complete_srp_setup(account_id, &response.setup_id, &srp_m1)
            .await?;
        let srp_m2 = STANDARD.decode(&complete.srp_m2)?;
        srp_session.verify_m2(&srp_m2).map_err(Error::from)?;
        Ok(())
    }
}

fn pad_left(data: &[u8], len: usize) -> Vec<u8> {
    if data.len() >= len {
        return data.to_vec();
    }

    let mut padded = vec![0u8; len - data.len()];
    padded.extend_from_slice(data);
    padded
}

fn to_core_key_attributes(attributes: &KeyAttributes) -> CoreKeyAttributes {
    CoreKeyAttributes {
        kek_salt: attributes.kek_salt.clone(),
        encrypted_key: attributes.encrypted_key.clone(),
        key_decryption_nonce: attributes.key_decryption_nonce.clone(),
        public_key: attributes.public_key.clone(),
        encrypted_secret_key: attributes.encrypted_secret_key.clone(),
        secret_key_decryption_nonce: attributes.secret_key_decryption_nonce.clone(),
        mem_limit: Some(attributes.mem_limit as u32),
        ops_limit: Some(attributes.ops_limit as u32),
        master_key_encrypted_with_recovery_key: attributes
            .master_key_encrypted_with_recovery_key
            .clone(),
        master_key_decryption_nonce: attributes.master_key_decryption_nonce.clone(),
        recovery_key_encrypted_with_master_key: attributes
            .recovery_key_encrypted_with_master_key
            .clone(),
        recovery_key_decryption_nonce: attributes.recovery_key_decryption_nonce.clone(),
    }
}

fn to_api_key_attributes(attributes: &CoreKeyAttributes) -> KeyAttributes {
    KeyAttributes {
        kek_salt: attributes.kek_salt.clone(),
        kek_hash: None,
        encrypted_key: attributes.encrypted_key.clone(),
        key_decryption_nonce: attributes.key_decryption_nonce.clone(),
        public_key: attributes.public_key.clone(),
        encrypted_secret_key: attributes.encrypted_secret_key.clone(),
        secret_key_decryption_nonce: attributes.secret_key_decryption_nonce.clone(),
        mem_limit: attributes.mem_limit.unwrap_or_default() as i32,
        ops_limit: attributes.ops_limit.unwrap_or_default() as i32,
        master_key_encrypted_with_recovery_key: attributes
            .master_key_encrypted_with_recovery_key
            .clone(),
        master_key_decryption_nonce: attributes.master_key_decryption_nonce.clone(),
        recovery_key_encrypted_with_master_key: attributes
            .recovery_key_encrypted_with_master_key
            .clone(),
        recovery_key_decryption_nonce: attributes.recovery_key_decryption_nonce.clone(),
    }
}

fn decode_plain_token(token: &str) -> Result<SecretVec> {
    let bytes = URL_SAFE
        .decode(token)
        .or_else(|_| STANDARD.decode(token))
        .map_err(|e| Error::Crypto(format!("token: {e}")))?;
    Ok(SecretVec::new(bytes))
}

fn decrypt_auth_response(
    auth_response: &AuthResponse,
    key_attributes: &CoreKeyAttributes,
    kek: &[u8],
) -> Result<DecryptedSecrets> {
    if let Some(encrypted_token) = auth_response.encrypted_token.as_deref() {
        auth::decrypt_secrets(kek, key_attributes, encrypted_token).map_err(Error::from)
    } else if let Some(token) = auth_response.token.as_deref() {
        let (master_key, secret_key) = auth::decrypt_keys_only(kek, key_attributes)?;
        Ok(DecryptedSecrets {
            master_key,
            secret_key,
            token: decode_plain_token(token)?,
        })
    } else {
        Err(Error::AuthenticationFailed("No token in response".into()))
    }
}

fn validate_remote_srp_attributes(
    remote: &RemoteSrpAttributes,
    srp_user_id: &Uuid,
    srp_setup: &GeneratedSrpSetup,
    key_attributes: &KeyAttributes,
) -> Result<()> {
    let expected_salt = STANDARD.encode(&srp_setup.srp_salt);

    let mut mismatches = Vec::new();

    if remote.srp_user_id != *srp_user_id {
        mismatches.push("srpUserID");
    }
    if remote.srp_salt != expected_salt {
        mismatches.push("srpSalt");
    }
    if remote.kek_salt != key_attributes.kek_salt {
        mismatches.push("kekSalt");
    }
    if remote.mem_limit != key_attributes.mem_limit {
        mismatches.push("memLimit");
    }
    if remote.ops_limit != key_attributes.ops_limit {
        mismatches.push("opsLimit");
    }

    if !mismatches.is_empty() {
        return Err(Error::AuthenticationFailed(format!(
            "Remote SRP attributes mismatched after signup: {}",
            mismatches.join(", ")
        )));
    }

    Ok(())
}

fn encrypt_two_factor_secret(
    secret_code: &str,
    recovery_key_hex: &str,
    code: &str,
) -> Result<EnableTwoFactorRequest> {
    let recovery_key = crypto::decode_hex(recovery_key_hex)?;
    let encrypted = secretbox::encrypt_with_key(secret_code.as_bytes(), &recovery_key)?;

    Ok(EnableTwoFactorRequest {
        code: code.to_string(),
        encrypted_two_factor_secret: crypto::encode_b64(&encrypted.ciphertext),
        two_factor_secret_decryption_nonce: crypto::encode_b64(&encrypted.nonce),
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockito::{Matcher, Server};
    use serde::{Deserialize, de::DeserializeOwned};
    use sha2::{Digest, Sha256};
    use srp::{groups::G_4096, server::SrpServer};
    use std::{
        collections::VecDeque,
        sync::{Arc, Mutex},
    };

    #[derive(Default)]
    struct MockSignupState {
        uploaded_key_attributes: Option<KeyAttributes>,
        remote_srp_attributes: Option<RemoteSrpAttributes>,
        pending_setup_id: Option<Uuid>,
        pending_client_proof: Option<Vec<u8>>,
        pending_server_proof: Option<Vec<u8>>,
    }

    #[derive(Debug, Deserialize)]
    #[serde(rename_all = "camelCase")]
    struct SetUserAttributesPayload {
        key_attributes: KeyAttributes,
    }

    #[derive(Debug, Deserialize)]
    struct SetupSrpPayload {
        #[serde(rename = "srpUserID")]
        srp_user_id: String,
        #[serde(rename = "srpSalt")]
        srp_salt: String,
        #[serde(rename = "srpVerifier")]
        srp_verifier: String,
        #[serde(rename = "srpA")]
        srp_a: String,
    }

    #[derive(Debug, Deserialize)]
    struct CompleteSrpSetupPayload {
        #[serde(rename = "setupID")]
        setup_id: String,
        #[serde(rename = "srpM1")]
        srp_m1: String,
    }

    fn parse_request_body<T>(request: &mockito::Request) -> T
    where
        T: DeserializeOwned,
    {
        serde_json::from_str(&request.utf8_lossy_body().unwrap()).unwrap()
    }

    struct ScriptedUi {
        email_otps: VecDeque<String>,
        login_totps: VecDeque<String>,
        setup_totps: VecDeque<String>,
        chosen_second_factor: Option<SecondFactorMethod>,
        last_totp_secret: Option<String>,
        passkey_presented: bool,
        retryable_errors: Vec<String>,
    }

    impl ScriptedUi {
        fn new() -> Self {
            Self {
                email_otps: VecDeque::new(),
                login_totps: VecDeque::new(),
                setup_totps: VecDeque::new(),
                chosen_second_factor: None,
                last_totp_secret: None,
                passkey_presented: false,
                retryable_errors: Vec::new(),
            }
        }
    }

    impl AuthFlowUi for ScriptedUi {
        fn read_email_otp(
            &mut self,
            _email: &str,
            _purpose: OtpPurpose,
            _resent: bool,
        ) -> Result<String> {
            self.email_otps
                .pop_front()
                .ok_or_else(|| Error::InvalidInput("No scripted email OTP available".into()))
        }

        fn read_totp_code(&mut self, purpose: TotpPurpose) -> Result<String> {
            let queue = match purpose {
                TotpPurpose::Login => &mut self.login_totps,
                TotpPurpose::Setup => &mut self.setup_totps,
            };

            queue
                .pop_front()
                .ok_or_else(|| Error::InvalidInput("No scripted TOTP code available".into()))
        }

        fn report_retryable_error(&mut self, message: &str) -> Result<()> {
            self.retryable_errors.push(message.to_string());
            Ok(())
        }

        fn choose_second_factor(
            &mut self,
            methods: &[SecondFactorMethod],
        ) -> Result<SecondFactorMethod> {
            if let Some(choice) = self.chosen_second_factor {
                Ok(choice)
            } else {
                methods
                    .first()
                    .copied()
                    .ok_or_else(|| Error::InvalidInput("No second-factor method available".into()))
            }
        }

        fn present_passkey_verification(&mut self, _url: &str) -> Result<()> {
            self.passkey_presented = true;
            Ok(())
        }

        fn wait_for_passkey_verification(&mut self) -> Result<()> {
            Ok(())
        }

        fn present_totp_secret(&mut self, secret_code: &str, _qr_code: &str) -> Result<()> {
            self.last_totp_secret = Some(secret_code.to_string());
            Ok(())
        }
    }

    fn build_login_response(
        password: &str,
        token: &str,
    ) -> (KeyAttributes, String, String, String, String) {
        let key_gen =
            auth::generate_keys_with_strength(password, auth::KeyDerivationStrength::Interactive)
                .unwrap();
        let key_attributes = to_api_key_attributes(&key_gen.key_attributes);
        let encrypted_token = {
            let public_key = crypto::decode_b64(&key_attributes.public_key).unwrap();
            let sealed = crypto::sealed::seal(token.as_bytes(), &public_key).unwrap();
            crypto::encode_b64(&sealed)
        };

        (
            key_attributes,
            encrypted_token,
            key_gen.private_key_attributes.recovery_key,
            key_gen.private_key_attributes.key,
            key_gen.private_key_attributes.secret_key,
        )
    }

    #[tokio::test]
    async fn login_with_email_mfa_and_totp_decrypts_account() {
        crypto::init().unwrap();

        let password = "hunter2";
        let (key_attributes, encrypted_token, recovery_key, _, _) =
            build_login_response(password, "plain-auth-token");

        let mut server = Server::new_async().await;
        let mut ui = ScriptedUi::new();
        ui.email_otps.push_back("123456".into());
        ui.login_totps.push_back("654321".into());

        let srp_attrs = server
            .mock("GET", Matcher::Any)
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "attributes": {
                        "srpUserID": Uuid::new_v4(),
                        "srpSalt": STANDARD.encode([1u8; 16]),
                        "memLimit": key_attributes.mem_limit,
                        "opsLimit": key_attributes.ops_limit,
                        "kekSalt": key_attributes.kek_salt,
                        "isEmailMFAEnabled": true
                    }
                })
                .to_string(),
            )
            .create_async()
            .await;

        let ott = server
            .mock("POST", "/users/ott")
            .with_status(200)
            .create_async()
            .await;

        let verify_email = server
            .mock("POST", "/users/verify-email")
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "id": 77,
                    "twoFactorSessionID": "session-1",
                })
                .to_string(),
            )
            .create_async()
            .await;

        let verify_totp = server
            .mock("POST", "/users/two-factor/verify")
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "id": 77,
                    "keyAttributes": key_attributes,
                    "encryptedToken": encrypted_token,
                })
                .to_string(),
            )
            .create_async()
            .await;

        let api_client = ApiClient::new(Some(server.url())).unwrap();
        let mut flow = AuthFlow::new(&api_client, App::Photos, &mut ui);

        let result = flow
            .login(LoginParams {
                email: "user@example.org".into(),
                password: Zeroizing::new(password.into()),
            })
            .await
            .unwrap();

        assert_eq!(result.user_id, 77);
        assert_eq!(result.secrets.token, b"plain-auth-token");
        assert_eq!(result.recovery_key.as_deref(), Some(recovery_key.as_str()));

        srp_attrs.assert_async().await;
        ott.assert_async().await;
        verify_email.assert_async().await;
        verify_totp.assert_async().await;
    }

    #[tokio::test]
    async fn login_with_totp_reports_invalid_code_before_retrying() {
        crypto::init().unwrap();

        let password = "hunter2";
        let (key_attributes, encrypted_token, _, _, _) =
            build_login_response(password, "plain-auth-token");

        let mut server = Server::new_async().await;
        let mut ui = ScriptedUi::new();
        ui.email_otps.push_back("123456".into());
        ui.login_totps.push_back("000000".into());
        ui.login_totps.push_back("654321".into());

        let srp_attrs = server
            .mock("GET", Matcher::Any)
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "attributes": {
                        "srpUserID": Uuid::new_v4(),
                        "srpSalt": STANDARD.encode([1u8; 16]),
                        "memLimit": key_attributes.mem_limit,
                        "opsLimit": key_attributes.ops_limit,
                        "kekSalt": key_attributes.kek_salt,
                        "isEmailMFAEnabled": true
                    }
                })
                .to_string(),
            )
            .create_async()
            .await;

        let ott = server
            .mock("POST", "/users/ott")
            .with_status(200)
            .create_async()
            .await;

        let verify_email = server
            .mock("POST", "/users/verify-email")
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "id": 77,
                    "twoFactorSessionID": "session-1",
                })
                .to_string(),
            )
            .create_async()
            .await;

        let rejected_totp = server
            .mock("POST", "/users/two-factor/verify")
            .match_body(Matcher::PartialJson(
                serde_json::json!({ "code": "000000" }),
            ))
            .with_status(401)
            .create_async()
            .await;

        let accepted_totp = server
            .mock("POST", "/users/two-factor/verify")
            .match_body(Matcher::PartialJson(
                serde_json::json!({ "code": "654321" }),
            ))
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "id": 77,
                    "keyAttributes": key_attributes,
                    "encryptedToken": encrypted_token,
                })
                .to_string(),
            )
            .create_async()
            .await;

        let api_client = ApiClient::new(Some(server.url())).unwrap();
        let mut flow = AuthFlow::new(&api_client, App::Photos, &mut ui);

        let result = flow
            .login(LoginParams {
                email: "user@example.org".into(),
                password: Zeroizing::new(password.into()),
            })
            .await
            .unwrap();

        assert_eq!(result.user_id, 77);
        assert_eq!(
            ui.retryable_errors,
            vec!["Incorrect TOTP code. Try again.".to_string()]
        );

        srp_attrs.assert_async().await;
        ott.assert_async().await;
        verify_email.assert_async().await;
        rejected_totp.assert_async().await;
        accepted_totp.assert_async().await;
    }

    #[tokio::test]
    async fn setup_two_factor_encrypts_secret_with_recovery_key() {
        crypto::init().unwrap();

        let password = "pw";
        let key_gen =
            auth::generate_keys_with_strength(password, auth::KeyDerivationStrength::Interactive)
                .unwrap();
        let recovery_key = key_gen.private_key_attributes.recovery_key.clone();
        let master_key = crypto::decode_b64(&key_gen.private_key_attributes.key).unwrap();
        let key_attributes = to_api_key_attributes(&key_gen.key_attributes);

        let mut server = Server::new_async().await;
        let mut ui = ScriptedUi::new();
        ui.setup_totps.push_back("123123".into());

        let setup = server
            .mock("POST", "/users/two-factor/setup")
            .match_header("x-auth-token", "session-token")
            .match_header("x-client-package", "io.ente.photos")
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "secretCode": "JBSWY3DPEHPK3PXP",
                    "qrCode": "qr-png-b64"
                })
                .to_string(),
            )
            .create_async()
            .await;

        let enable = server
            .mock("POST", "/users/two-factor/enable")
            .match_header("x-auth-token", "session-token")
            .match_header("x-client-package", "io.ente.photos")
            .match_body(Matcher::Regex("\"encryptedTwoFactorSecret\"".into()))
            .with_status(200)
            .create_async()
            .await;

        let api_client = ApiClient::new(Some(server.url())).unwrap();
        api_client.add_token("user@example.org", "session-token");
        let mut flow = AuthFlow::new(&api_client, App::Photos, &mut ui);

        let result = flow
            .setup_two_factor(SetupTwoFactorParams {
                account_id: "user@example.org".into(),
                master_key: SecretVec::new(master_key),
                key_attributes: Some(key_attributes),
            })
            .await
            .unwrap();

        assert_eq!(result.secret_code, "JBSWY3DPEHPK3PXP");
        assert_eq!(result.recovery_key, recovery_key);
        assert_eq!(ui.last_totp_secret.as_deref(), Some("JBSWY3DPEHPK3PXP"));

        setup.assert_async().await;
        enable.assert_async().await;
    }

    #[tokio::test]
    async fn create_account_uploads_keys_and_completes_srp_setup() {
        crypto::init().unwrap();

        let email = "fresh-user@example.org";
        let encoded_email = urlencoding::encode(email).into_owned();
        let signup_token_bytes = b"signup-session-token";
        let signup_token = URL_SAFE.encode(signup_token_bytes);
        let signup_state = Arc::new(Mutex::new(MockSignupState::default()));

        let mut server = Server::new_async().await;
        let mut ui = ScriptedUi::new();
        ui.email_otps.push_back("123456".into());

        let send_otp = server
            .mock("POST", "/users/ott")
            .match_body(Matcher::PartialJson(serde_json::json!({
                "email": email,
                "purpose": "signup",
            })))
            .with_status(200)
            .create_async()
            .await;

        let verify_email = server
            .mock("POST", "/users/verify-email")
            .match_body(Matcher::PartialJson(serde_json::json!({
                "email": email,
                "ott": "123456",
                "source": "testAccount",
            })))
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "id": 99,
                    "token": signup_token,
                })
                .to_string(),
            )
            .create_async()
            .await;

        let session_validity = server
            .mock("GET", "/users/session-validity/v2")
            .match_header("x-auth-token", signup_token.as_str())
            .match_header("x-client-package", "io.ente.photos")
            .with_status(200)
            .with_body(
                serde_json::json!({
                    "hasSetKeys": false,
                })
                .to_string(),
            )
            .create_async()
            .await;

        let state = Arc::clone(&signup_state);
        let set_attributes = server
            .mock("PUT", "/users/attributes")
            .match_header("x-auth-token", signup_token.as_str())
            .match_header("x-client-package", "io.ente.photos")
            .with_status(200)
            .with_body_from_request(move |request| {
                let payload: SetUserAttributesPayload = parse_request_body(request);
                let key_attributes = payload.key_attributes;
                let mem_limit = u64::try_from(key_attributes.mem_limit).unwrap();
                let ops_limit = u64::try_from(key_attributes.ops_limit).unwrap();

                assert!(!key_attributes.kek_salt.is_empty());
                assert_eq!(mem_limit * ops_limit, 4_294_967_296);
                assert!(
                    key_attributes
                        .master_key_encrypted_with_recovery_key
                        .is_some()
                );
                assert!(
                    key_attributes
                        .recovery_key_encrypted_with_master_key
                        .is_some()
                );

                state.lock().unwrap().uploaded_key_attributes = Some(key_attributes);
                Vec::new()
            })
            .create_async()
            .await;

        let state = Arc::clone(&signup_state);
        let setup_srp = server
            .mock("POST", "/users/srp/setup")
            .match_header("x-auth-token", signup_token.as_str())
            .match_header("x-client-package", "io.ente.photos")
            .with_status(200)
            .with_body_from_request(move |request| {
                let payload: SetupSrpPayload = parse_request_body(request);
                let srp_user_id = Uuid::parse_str(&payload.srp_user_id).unwrap();
                let srp_verifier = STANDARD.decode(&payload.srp_verifier).unwrap();
                let srp_a = STANDARD.decode(&payload.srp_a).unwrap();
                let server = SrpServer::<Sha256>::new(&G_4096);
                let b_private = [0x33u8; 64];
                let srp_b = pad_left(
                    &server.compute_public_ephemeral(&b_private, &srp_verifier),
                    SRP_A_LEN,
                );
                let verifier = server
                    .process_reply(&b_private, &srp_verifier, &srp_a)
                    .unwrap();
                let setup_id = Uuid::new_v4();
                let srp_a = pad_left(&srp_a, SRP_A_LEN);
                let shared_secret = pad_left(verifier.key(), SRP_A_LEN);

                let mut client_proof_hasher = Sha256::new();
                client_proof_hasher.update(&srp_a);
                client_proof_hasher.update(&srp_b);
                client_proof_hasher.update(&shared_secret);
                let client_proof = client_proof_hasher.finalize().to_vec();

                let server_key = Sha256::digest(&shared_secret);
                let mut server_proof_hasher = Sha256::new();
                server_proof_hasher.update(&srp_a);
                server_proof_hasher.update(&client_proof);
                server_proof_hasher.update(server_key);
                let server_proof = server_proof_hasher.finalize().to_vec();

                let mut state = state.lock().unwrap();
                let uploaded_key_attributes = state.uploaded_key_attributes.clone().unwrap();
                state.remote_srp_attributes = Some(RemoteSrpAttributes {
                    srp_user_id,
                    srp_salt: payload.srp_salt,
                    mem_limit: uploaded_key_attributes.mem_limit,
                    ops_limit: uploaded_key_attributes.ops_limit,
                    kek_salt: uploaded_key_attributes.kek_salt,
                    is_email_mfa_enabled: false,
                });
                state.pending_setup_id = Some(setup_id);
                state.pending_client_proof = Some(client_proof);
                state.pending_server_proof = Some(server_proof);

                serde_json::json!({
                    "setupID": setup_id,
                    "srpB": STANDARD.encode(&srp_b),
                })
                .to_string()
                .into_bytes()
            })
            .create_async()
            .await;

        let state = Arc::clone(&signup_state);
        let complete_srp = server
            .mock("POST", "/users/srp/complete")
            .match_header("x-auth-token", signup_token.as_str())
            .match_header("x-client-package", "io.ente.photos")
            .with_status(200)
            .with_body_from_request(move |request| {
                let payload: CompleteSrpSetupPayload = parse_request_body(request);
                let setup_id = Uuid::parse_str(&payload.setup_id).unwrap();
                let srp_m1 = STANDARD.decode(&payload.srp_m1).unwrap();

                let mut state = state.lock().unwrap();
                assert_eq!(state.pending_setup_id, Some(setup_id));
                assert_eq!(state.pending_client_proof.take().unwrap(), srp_m1);

                serde_json::json!({
                    "setupID": setup_id,
                    "srpM2": STANDARD.encode(state.pending_server_proof.take().unwrap()),
                })
                .to_string()
                .into_bytes()
            })
            .create_async()
            .await;

        let state = Arc::clone(&signup_state);
        let srp_attributes = server
            .mock("GET", Matcher::Any)
            .match_request(move |request| {
                request.path() == "/users/srp/attributes"
                    && request.path_and_query()
                        == format!("/users/srp/attributes?email={encoded_email}")
            })
            .with_status(200)
            .with_body_from_request(move |_| {
                let state = state.lock().unwrap();
                serde_json::to_vec(&serde_json::json!({
                    "attributes": state.remote_srp_attributes.as_ref().unwrap()
                }))
                .unwrap()
            })
            .create_async()
            .await;

        let api_client = ApiClient::new(Some(server.url())).unwrap();
        let mut flow = AuthFlow::new(&api_client, App::Photos, &mut ui);

        let result = flow
            .create_account(CreateAccountParams {
                email: email.into(),
                password: Zeroizing::new("correct horse battery staple".into()),
                source: Some("testAccount".into()),
            })
            .await
            .unwrap();

        let uploaded_key_attributes = signup_state
            .lock()
            .unwrap()
            .uploaded_key_attributes
            .clone()
            .unwrap();

        assert_eq!(result.user_id, 99);
        assert_eq!(result.secrets.token, signup_token_bytes);
        assert_eq!(
            result.key_attributes.public_key,
            uploaded_key_attributes.public_key
        );
        assert_eq!(
            result.key_attributes.kek_salt,
            uploaded_key_attributes.kek_salt
        );
        assert_eq!(
            result.key_attributes.mem_limit,
            uploaded_key_attributes.mem_limit
        );
        assert_eq!(
            result.key_attributes.ops_limit,
            uploaded_key_attributes.ops_limit
        );
        assert!(result.recovery_key.is_some());
        assert_eq!(result.secrets.master_key.len(), 32);
        assert_eq!(result.secrets.secret_key.len(), 32);
        assert_eq!(result.secrets.public_key.len(), 32);

        send_otp.assert_async().await;
        verify_email.assert_async().await;
        session_validity.assert_async().await;
        set_attributes.assert_async().await;
        setup_srp.assert_async().await;
        complete_srp.assert_async().await;
        srp_attributes.assert_async().await;
    }

    #[test]
    fn validate_remote_srp_attributes_reports_mismatched_fields() {
        crypto::init().unwrap();

        let key_gen =
            auth::generate_keys_with_strength("password", auth::KeyDerivationStrength::Interactive)
                .unwrap();
        let key_attributes = to_api_key_attributes(&key_gen.key_attributes);
        let srp_user_id = Uuid::new_v4();
        let srp_setup =
            generate_srp_setup(&key_gen.key_encryption_key, &srp_user_id.to_string()).unwrap();

        let remote = RemoteSrpAttributes {
            srp_user_id,
            srp_salt: "wrong-salt".into(),
            mem_limit: key_attributes.mem_limit + 1,
            ops_limit: key_attributes.ops_limit + 1,
            kek_salt: key_attributes.kek_salt.clone(),
            is_email_mfa_enabled: false,
        };

        let error =
            validate_remote_srp_attributes(&remote, &srp_user_id, &srp_setup, &key_attributes)
                .unwrap_err();

        match error {
            Error::AuthenticationFailed(message) => {
                assert!(message.contains("srpSalt"));
                assert!(message.contains("memLimit"));
                assert!(message.contains("opsLimit"));
            }
            other => panic!("unexpected error: {other}"),
        }
    }
}
