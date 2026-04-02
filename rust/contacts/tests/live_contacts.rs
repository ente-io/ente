use std::time::Duration;

use base64::{Engine, engine::general_purpose::URL_SAFE};
use ente_contacts::client::{ContactsCtx, OpenContactsCtxInput};
use ente_contacts::models::ContactData;
use ente_core::http::Error as CoreHttpError;
use ente_rs::{
    api::ApiClient,
    auth_flow::{
        AuthFlow, AuthFlowUi, CreateAccountParams, LoginParams, OtpPurpose, SecondFactorMethod,
        TotpPurpose,
    },
    models::{
        account::App,
        error::{Error as CliError, Result as CliResult},
    },
};
use zeroize::Zeroizing;

struct LiveUi;

impl AuthFlowUi for LiveUi {
    fn read_email_otp(
        &mut self,
        _email: &str,
        _purpose: OtpPurpose,
        _resent: bool,
    ) -> CliResult<String> {
        Ok("123456".to_string())
    }

    fn read_totp_code(&mut self, _purpose: TotpPurpose) -> CliResult<String> {
        Err(CliError::InvalidInput(
            "TOTP not expected in local live contacts test".into(),
        ))
    }

    fn report_retryable_error(&mut self, _message: &str) -> CliResult<()> {
        Ok(())
    }

    fn choose_second_factor(
        &mut self,
        _methods: &[SecondFactorMethod],
    ) -> CliResult<SecondFactorMethod> {
        Err(CliError::InvalidInput(
            "Second factor not expected in local live contacts test".into(),
        ))
    }

    fn present_passkey_verification(&mut self, _url: &str) -> CliResult<()> {
        Err(CliError::InvalidInput(
            "Passkey flow not expected in local live contacts test".into(),
        ))
    }

    fn wait_for_passkey_verification(&mut self) -> CliResult<()> {
        Err(CliError::InvalidInput(
            "Passkey flow not expected in local live contacts test".into(),
        ))
    }

    fn present_totp_secret(&mut self, _secret_code: &str, _qr_code: &str) -> CliResult<()> {
        Err(CliError::InvalidInput(
            "TOTP setup not expected in local live contacts test".into(),
        ))
    }
}

struct TestAccount {
    email: String,
    user_id: i64,
    auth_token: String,
    master_key: Vec<u8>,
}

#[tokio::test]
#[ignore = "requires local Museum at http://localhost:8080"]
async fn live_contacts_crud_and_profile_picture_flow() {
    let endpoint = std::env::var("ENTE_CONTACTS_TEST_ENDPOINT")
        .unwrap_or_else(|_| "http://localhost:8080".to_string());

    let ping_url = format!("{endpoint}/ping");
    let ping = match reqwest::get(&ping_url).await {
        Ok(response) if response.status().is_success() => response,
        Ok(response) => {
            eprintln!(
                "skipping live contacts test: {ping_url} returned {}",
                response.status()
            );
            return;
        }
        Err(error) => {
            eprintln!("skipping live contacts test: could not reach {ping_url}: {error}");
            return;
        }
    };
    assert!(ping.status().is_success());

    let account_a = ensure_account(&endpoint, "a@test.test").await;
    let account_b = ensure_account(&endpoint, "b@test.test").await;

    let ctx_a = open_ctx(&endpoint, &account_a).await;
    let ctx_b = open_ctx(&endpoint, &account_b).await;

    let mut existing = ctx_a.get_diff(0, 5000).await.unwrap();
    existing.retain(|contact| !contact.is_deleted && contact.contact_user_id == account_b.user_id);
    assert!(
        existing.len() <= 1,
        "expected at most one live contact for account B, found {}",
        existing.len()
    );

    let initial_data = ContactData {
        contact_user_id: account_b.user_id,
        email: account_b.email.clone(),
        name: "B Contact".to_string(),
        birth_date: Some("2001-04-01".to_string()),
    };

    let contact = if let Some(existing_contact) = existing.into_iter().next() {
        ctx_a
            .update_contact(&existing_contact.id, &initial_data)
            .await
            .unwrap()
    } else {
        ctx_a.create_contact(&initial_data).await.unwrap()
    };

    assert_eq!(contact.contact_user_id, account_b.user_id);
    assert_eq!(contact.email.as_deref(), Some(account_b.email.as_str()));

    let fetched = ctx_a.get_contact(&contact.id).await.unwrap();
    assert_eq!(fetched.id, contact.id);
    assert_eq!(fetched.name.as_deref(), Some("B Contact"));

    let updated = ctx_a
        .update_contact(
            &contact.id,
            &ContactData {
                contact_user_id: account_b.user_id,
                email: account_b.email.clone(),
                name: "B Contact Updated".to_string(),
                birth_date: Some("2001-04-02".to_string()),
            },
        )
        .await
        .unwrap();
    assert_eq!(updated.name.as_deref(), Some("B Contact Updated"));
    assert_eq!(updated.birth_date.as_deref(), Some("2001-04-02"));

    let diff = ctx_a.get_diff(0, 5000).await.unwrap();
    assert!(diff.iter().any(|entry| entry.id == contact.id));

    let picture = b"local-live-profile-picture".to_vec();
    let with_picture = ctx_a
        .set_profile_picture(&contact.id, &picture)
        .await
        .unwrap();
    assert!(with_picture.profile_picture_attachment_id.is_some());

    let downloaded_picture = ctx_a.get_profile_picture(&contact.id).await.unwrap();
    assert_eq!(downloaded_picture, picture);

    let without_picture = ctx_a.delete_profile_picture(&contact.id).await.unwrap();
    assert_eq!(without_picture.profile_picture_attachment_id, None);

    match ctx_b.get_contact(&contact.id).await {
        Err(ente_contacts::ContactsError::Http(CoreHttpError::Http { status: 404, .. })) => {}
        other => panic!("expected account B to get 404 for account A's contact, got {other:?}"),
    }
}

async fn open_ctx(endpoint: &str, account: &TestAccount) -> ContactsCtx {
    ContactsCtx::open(OpenContactsCtxInput {
        base_url: endpoint.to_string(),
        auth_token: account.auth_token.clone(),
        user_id: account.user_id,
        master_key: account.master_key.clone(),
        cached_root_key: None,
        user_agent: Some("ente-contacts-live-test".to_string()),
        client_package: Some(App::Photos.client_package().to_string()),
        client_version: Some("0.0.1".to_string()),
    })
    .await
    .unwrap()
    .ctx
}

async fn ensure_account(endpoint: &str, email: &str) -> TestAccount {
    let password = test_password_for(email);
    let api = ApiClient::new_with_client_package(
        Some(endpoint.to_string()),
        App::Photos.client_package(),
    )
    .unwrap();
    let mut ui = LiveUi;

    let authenticated = tokio::time::timeout(Duration::from_secs(90), async {
        let mut flow = AuthFlow::new(&api, App::Photos, &mut ui);
        match flow
            .login(LoginParams {
                email: email.to_string(),
                password: Zeroizing::new(password.clone()),
            })
            .await
        {
            Ok(account) => Ok(account),
            Err(_) => {
                flow.create_account(CreateAccountParams {
                    email: email.to_string(),
                    password: Zeroizing::new(password.clone()),
                    source: Some("testAccount".into()),
                })
                .await
            }
        }
    })
    .await
    .expect("auth flow timed out")
    .unwrap();

    let auth_token = URL_SAFE.encode(&authenticated.secrets.token);

    TestAccount {
        email: email.to_string(),
        user_id: authenticated.user_id,
        auth_token,
        master_key: authenticated.secrets.master_key.clone(),
    }
}

fn test_password_for(email: &str) -> String {
    std::env::var("ENTE_CONTACTS_TEST_PASSWORD").unwrap_or_else(|_| email.to_string())
}
