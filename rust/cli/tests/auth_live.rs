use std::time::{Duration, SystemTime, UNIX_EPOCH};

use ente_core::crypto::SecretVec;
use ente_rs::{
    api::ApiClient,
    auth_flow::{
        AuthFlow, AuthFlowUi, CreateAccountParams, LoginParams, OtpPurpose, SecondFactorMethod,
        SetupTwoFactorParams, TotpPurpose,
    },
    models::{account::App, error::Error},
};
use hmac::{Hmac, Mac};
use sha1::Sha1;
use uuid::Uuid;
use zeroize::Zeroizing;

type HmacSha1 = Hmac<Sha1>;

struct LiveUi {
    otp: String,
    totp_secret: Option<String>,
}

impl LiveUi {
    fn new() -> Self {
        Self {
            otp: "123456".into(),
            totp_secret: None,
        }
    }
}

impl AuthFlowUi for LiveUi {
    fn read_email_otp(
        &mut self,
        _email: &str,
        _purpose: OtpPurpose,
        _resent: bool,
    ) -> ente_rs::Result<String> {
        Ok(self.otp.clone())
    }

    fn read_totp_code(&mut self, _purpose: TotpPurpose) -> ente_rs::Result<String> {
        let secret = self
            .totp_secret
            .as_deref()
            .ok_or_else(|| Error::InvalidInput("No TOTP secret captured for live test".into()))?;

        Ok(current_totp(secret))
    }

    fn report_retryable_error(&mut self, _message: &str) -> ente_rs::Result<()> {
        Ok(())
    }

    fn choose_second_factor(
        &mut self,
        _methods: &[SecondFactorMethod],
    ) -> ente_rs::Result<SecondFactorMethod> {
        Ok(SecondFactorMethod::Totp)
    }

    fn present_passkey_verification(&mut self, _url: &str) -> ente_rs::Result<()> {
        Ok(())
    }

    fn wait_for_passkey_verification(&mut self) -> ente_rs::Result<()> {
        Ok(())
    }

    fn present_totp_secret(&mut self, secret_code: &str, _qr_code: &str) -> ente_rs::Result<()> {
        self.totp_secret = Some(secret_code.to_string());
        Ok(())
    }
}

#[tokio::test]
#[ignore = "requires local Museum at http://localhost:8080 with hardcoded OTT config"]
async fn live_create_login_and_enable_totp() {
    let endpoint = "http://localhost:8080".to_string();
    let ping_url = format!("{endpoint}/ping");
    let ping = match reqwest::get(&ping_url).await {
        Ok(response) if response.status().is_success() => response,
        Ok(response) => {
            eprintln!(
                "skipping live auth test: {ping_url} returned {}",
                response.status()
            );
            return;
        }
        Err(error) => {
            eprintln!("skipping live auth test: could not reach {ping_url}: {error}");
            return;
        }
    };
    assert!(ping.status().is_success());

    let email = format!("ente-rs-{}@ente-rust-test.org", Uuid::new_v4());
    let password = format!("EnteLiveTest-{}!", Uuid::new_v4().simple());

    let create_api =
        ApiClient::new_with_client_package(Some(endpoint.clone()), App::Photos.client_package())
            .unwrap();
    let mut ui = LiveUi::new();

    let created = tokio::time::timeout(Duration::from_secs(120), async {
        let mut flow = AuthFlow::new(&create_api, App::Photos, &mut ui);
        flow.create_account(CreateAccountParams {
            email: email.clone(),
            password: Zeroizing::new(password.clone()),
            source: Some("testAccount".into()),
        })
        .await
    })
    .await
    .expect("signup timed out")
    .expect("signup failed");

    assert!(created.recovery_key.is_some());
    let created_user_id = created.user_id;
    let created_master_key = created.secrets.master_key.clone();
    let created_key_attributes = created.key_attributes.clone();

    let login_api =
        ApiClient::new_with_client_package(Some(endpoint.clone()), App::Photos.client_package())
            .unwrap();
    let first_login = tokio::time::timeout(Duration::from_secs(90), async {
        let mut flow = AuthFlow::new(&login_api, App::Photos, &mut ui);
        flow.login(LoginParams {
            email: email.clone(),
            password: Zeroizing::new(password.clone()),
        })
        .await
    })
    .await
    .expect("initial login timed out")
    .expect("initial login failed");

    assert_eq!(first_login.user_id, created_user_id);
    assert_eq!(first_login.secrets.master_key, created_master_key);

    let setup_result = tokio::time::timeout(Duration::from_secs(60), async {
        let mut flow = AuthFlow::new(&create_api, App::Photos, &mut ui);
        flow.setup_two_factor(SetupTwoFactorParams {
            account_id: email.clone(),
            master_key: SecretVec::new(created_master_key.clone()),
            key_attributes: Some(created_key_attributes),
        })
        .await
    })
    .await
    .expect("two-factor setup timed out")
    .expect("two-factor setup failed");

    assert_eq!(
        ui.totp_secret.as_deref(),
        Some(setup_result.secret_code.as_str())
    );

    let login_after_2fa_api =
        ApiClient::new_with_client_package(Some(endpoint.clone()), App::Photos.client_package())
            .unwrap();
    let second_login = tokio::time::timeout(Duration::from_secs(90), async {
        let mut flow = AuthFlow::new(&login_after_2fa_api, App::Photos, &mut ui);
        flow.login(LoginParams {
            email: email.clone(),
            password: Zeroizing::new(password.clone()),
        })
        .await
    })
    .await
    .expect("two-factor login timed out")
    .expect("two-factor login failed");

    assert_eq!(second_login.user_id, created_user_id);
    assert_eq!(second_login.secrets.master_key, created_master_key);
}

fn current_totp(secret: &str) -> String {
    let key = decode_base32(secret);
    let counter = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system time before UNIX_EPOCH")
        .as_secs()
        / 30;

    let mut mac = HmacSha1::new_from_slice(&key).expect("invalid HMAC key");
    mac.update(&counter.to_be_bytes());
    let digest = mac.finalize().into_bytes();
    let offset = (digest[19] & 0x0f) as usize;

    let binary = ((digest[offset] as u32 & 0x7f) << 24)
        | ((digest[offset + 1] as u32) << 16)
        | ((digest[offset + 2] as u32) << 8)
        | digest[offset + 3] as u32;

    format!("{:06}", binary % 1_000_000)
}

fn decode_base32(secret: &str) -> Vec<u8> {
    let mut output = Vec::new();
    let mut buffer = 0u32;
    let mut bits = 0u8;

    for ch in secret
        .chars()
        .filter(|ch| !ch.is_whitespace() && *ch != '=')
    {
        let value = match ch {
            'A'..='Z' => ch as u8 - b'A',
            'a'..='z' => ch as u8 - b'a',
            '2'..='7' => ch as u8 - b'2' + 26,
            _ => panic!("invalid base32 character in TOTP secret: {ch}"),
        } as u32;

        buffer = (buffer << 5) | value;
        bits += 5;

        while bits >= 8 {
            bits -= 8;
            output.push(((buffer >> bits) & 0xff) as u8);
        }
    }

    output
}
