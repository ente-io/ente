use crate::{
    api::{ApiClient, AuthClient},
    cli::account::{AccountCommand, AccountSubcommands},
    models::{
        account::{Account, AccountSecrets, App},
        error::{Error, Result},
    },
    storage::Storage,
};
use base64::Engine;
use dialoguer::{Input, Password, Select};
use std::path::PathBuf;

use ente_core::auth::{self, DecryptedSecrets, KeyAttributes as CoreKeyAttributes, derive_kek};
use ente_core::crypto;

fn to_core_key_attributes(attrs: &crate::api::models::KeyAttributes) -> CoreKeyAttributes {
    CoreKeyAttributes {
        kek_salt: attrs.kek_salt.clone(),
        encrypted_key: attrs.encrypted_key.clone(),
        key_decryption_nonce: attrs.key_decryption_nonce.clone(),
        public_key: attrs.public_key.clone(),
        encrypted_secret_key: attrs.encrypted_secret_key.clone(),
        secret_key_decryption_nonce: attrs.secret_key_decryption_nonce.clone(),
        mem_limit: Some(attrs.mem_limit as u32),
        ops_limit: Some(attrs.ops_limit as u32),
        master_key_encrypted_with_recovery_key: None,
        master_key_decryption_nonce: None,
        recovery_key_encrypted_with_master_key: None,
        recovery_key_decryption_nonce: None,
    }
}

fn decrypt_secrets_with_plain_token(
    kek: &[u8],
    key_attrs: &CoreKeyAttributes,
    token: &str,
) -> auth::Result<DecryptedSecrets> {
    let (master_key, secret_key) = auth::decrypt_keys_only(kek, key_attrs)?;

    let token = base64::engine::general_purpose::URL_SAFE
        .decode(token)
        .or_else(|_| base64::engine::general_purpose::STANDARD.decode(token))
        .map_err(|e| auth::AuthError::Decode(format!("token: {e}")))?;

    Ok(DecryptedSecrets {
        master_key,
        secret_key,
        token,
    })
}

pub async fn handle_account_command(cmd: AccountCommand, storage: &Storage) -> Result<()> {
    match cmd.command {
        AccountSubcommands::List => list_accounts(storage).await,
        AccountSubcommands::Add {
            email,
            password,
            app,
            endpoint,
            export_dir,
        } => add_account(storage, email, password, app, endpoint, export_dir).await,
        AccountSubcommands::Update { email, dir, app } => {
            update_account(storage, &email, &dir, &app).await
        }
        AccountSubcommands::GetToken { email, app } => get_token(storage, &email, &app).await,
    }
}

async fn list_accounts(storage: &Storage) -> Result<()> {
    let accounts = storage.accounts().list()?;

    if accounts.is_empty() {
        println!("No accounts configured. Use 'ente account add' to add an account.");
        return Ok(());
    }

    println!("\nConfigured accounts:\n");
    println!(
        "{:<30} {:<10} {:<30} {:<40}",
        "Email", "App", "Endpoint", "Export Directory"
    );
    println!("{}", "-".repeat(110));

    for account in accounts {
        // Shorten endpoint display for better readability
        let endpoint_display = if account.endpoint == "https://api.ente.io" {
            "api.ente.io (prod)".to_string()
        } else if account.endpoint.starts_with("http://localhost") {
            format!(
                "localhost:{}",
                account.endpoint.split(':').next_back().unwrap_or("")
            )
        } else {
            account.endpoint.clone()
        };

        println!(
            "{:<30} {:<10} {:<30} {:<40}",
            account.email,
            format!("{:?}", account.app).to_lowercase(),
            endpoint_display,
            account.export_dir.as_deref().unwrap_or("Not configured")
        );
    }

    Ok(())
}

async fn add_account(
    storage: &Storage,
    email_arg: Option<String>,
    password_arg: Option<String>,
    app_arg: String,
    endpoint: String,
    export_dir_arg: Option<String>,
) -> Result<()> {
    println!("\n=== Add Ente Account ===\n");

    let email = if let Some(email) = email_arg {
        email
    } else {
        Input::new()
            .with_prompt("Enter your email address")
            .interact_text()
            .map_err(|e| Error::InvalidInput(e.to_string()))?
    };

    let app = match app_arg.to_lowercase().as_str() {
        "photos" => App::Photos,
        "locker" => App::Locker,
        "auth" => App::Auth,
        _ => {
            if password_arg.is_some() {
                return Err(Error::InvalidInput(format!(
                    "Invalid app: {app_arg}. Must be one of: photos, locker, auth"
                )));
            }
            let apps = vec!["photos", "locker", "auth"];
            let app_index = Select::new()
                .with_prompt("Select the Ente app")
                .items(&apps)
                .default(0)
                .interact()
                .map_err(|e| Error::InvalidInput(e.to_string()))?;
            match apps[app_index] {
                "photos" => App::Photos,
                "locker" => App::Locker,
                "auth" => App::Auth,
                _ => unreachable!(),
            }
        }
    };

    if let Ok(Some(_existing)) = storage.accounts().get(&email, app) {
        println!("\n❌ Account already exists for {email} with app {app:?}");
        return Ok(());
    }

    let is_non_interactive = password_arg.is_some();

    let mut password = if let Some(password) = password_arg {
        password
    } else {
        Password::new()
            .with_prompt("Enter your password")
            .interact()
            .map_err(|e| Error::InvalidInput(e.to_string()))?
    };

    let export_dir = if let Some(dir) = export_dir_arg {
        dir
    } else if is_non_interactive {
        format!("./exports/{email}")
    } else {
        Input::new()
            .with_prompt("Enter export directory path")
            .default(format!("./exports/{email}"))
            .interact_text()
            .map_err(|e| Error::InvalidInput(e.to_string()))?
    };

    let export_path = PathBuf::from(&export_dir);
    if !export_path.exists() {
        println!("Creating export directory: {export_dir}");
        std::fs::create_dir_all(&export_path).map_err(Error::Io)?;
    }

    log::info!("Using API endpoint: {endpoint}");
    let api_client = ApiClient::new(Some(endpoint.clone()))?;
    let auth_client = AuthClient::new(&api_client);

    println!("\nAuthenticating with Ente servers...");

    let srp_attrs = auth_client.get_srp_attributes(&email).await?;

    let (auth_response, mut key_enc_key) = if srp_attrs.is_email_mfa_enabled {
        println!("\n📧 Email MFA is enabled. Sending verification code...");
        auth_client.send_login_otp(&email).await?;

        let auth_response = loop {
            let otp: String = Input::new()
                .with_prompt("Enter the 6-digit code from your email")
                .validate_with(|input: &String| {
                    if input.len() == 6 && input.chars().all(char::is_numeric) {
                        Ok(())
                    } else {
                        Err("Code must be 6 digits")
                    }
                })
                .interact_text()
                .map_err(|e| Error::InvalidInput(e.to_string()))?;

            match auth_client.verify_email(&email, &otp).await {
                Ok(resp) => break resp,
                Err(Error::ApiError {
                    status: 400 | 401, ..
                }) => {
                    println!("❌ Invalid code, please try again.");
                }
                Err(Error::ApiError { status: 410, .. }) => {
                    println!("❌ Code expired. Sending a new code...");
                    auth_client.send_login_otp(&email).await?;
                }
                Err(e) => return Err(e),
            }
        };

        let auth_response = maybe_verify_2fa(&auth_client, auth_response, app).await?;

        println!("\nPlease wait authenticating...");
        let key_enc_key = derive_kek(
            &password,
            &srp_attrs.kek_salt,
            srp_attrs.mem_limit as u32,
            srp_attrs.ops_limit as u32,
        )?;

        (auth_response, key_enc_key)
    } else {
        let (auth_response, key_enc_key) = if is_non_interactive {
            auth_client.login_with_srp(&email, &password).await?
        } else {
            loop {
                match auth_client.login_with_srp(&email, &password).await {
                    Ok(result) => break result,
                    Err(Error::ApiError {
                        status: 400 | 401, ..
                    }) => {
                        println!("❌ Incorrect password, please try again.");
                        password = Password::new()
                            .with_prompt("Enter your password")
                            .interact()
                            .map_err(|e| Error::InvalidInput(e.to_string()))?;
                    }
                    Err(e) => return Err(e),
                }
            }
        };

        let auth_response = maybe_verify_2fa(&auth_client, auth_response, app).await?;
        (auth_response, key_enc_key)
    };

    let key_attributes = auth_response
        .key_attributes
        .as_ref()
        .ok_or_else(|| Error::AuthenticationFailed("No key attributes".to_string()))?;

    println!("\nDecrypting account keys...");

    let core_key_attrs = to_core_key_attributes(key_attributes);

    let encrypted_token = auth_response.encrypted_token.as_deref();
    let response_token = auth_response.token.as_deref();

    let secrets: DecryptedSecrets = loop {
        let result = if let Some(encrypted_token) = encrypted_token {
            auth::decrypt_secrets(&key_enc_key, &core_key_attrs, encrypted_token)
        } else if let Some(token) = response_token {
            decrypt_secrets_with_plain_token(&key_enc_key, &core_key_attrs, token)
        } else {
            return Err(Error::AuthenticationFailed(
                "No token in response".to_string(),
            ));
        };

        match result {
            Ok(secrets) => break secrets,
            Err(auth::AuthError::IncorrectPassword) if !is_non_interactive => {
                println!("❌ Incorrect password.");
                password = Password::new()
                    .with_prompt("Enter your password")
                    .interact()
                    .map_err(|e| Error::InvalidInput(e.to_string()))?;

                println!("\nPlease wait authenticating...");
                key_enc_key = derive_kek(
                    &password,
                    &key_attributes.kek_salt,
                    key_attributes.mem_limit as u32,
                    key_attributes.ops_limit as u32,
                )?;
            }
            Err(e) => return Err(e.into()),
        }
    };

    let public_key = crypto::decode_b64(&key_attributes.public_key)?;

    let account = Account {
        user_id: auth_response.id,
        email: email.clone(),
        app,
        endpoint: endpoint.clone(),
        export_dir: Some(export_dir.clone()),
    };

    let secrets = AccountSecrets {
        token: secrets.token,
        master_key: secrets.master_key,
        secret_key: secrets.secret_key,
        public_key,
    };

    storage.accounts().add(&account)?;
    storage
        .accounts()
        .store_secrets(account.user_id, account.app, &secrets)?;

    println!("\n✅ Account added successfully!");
    println!("   Email: {email}");
    println!("   App: {app:?}");
    println!("   Endpoint: {endpoint}");
    println!("   Export directory: {export_dir}");

    Ok(())
}

async fn maybe_verify_2fa(
    auth_client: &AuthClient<'_>,
    auth_resp: crate::api::models::AuthResponse,
    app: App,
) -> Result<crate::api::models::AuthResponse> {
    let has_totp = auth_resp.get_two_factor_session_id().is_some();
    let has_passkey = auth_resp
        .passkey_session_id
        .as_ref()
        .is_some_and(|s| !s.is_empty());

    if has_totp && has_passkey {
        println!("\n🔐 Two-factor authentication required");
        println!("Choose verification method:");
        let options = vec!["TOTP (Authenticator app)", "Passkey"];
        let choice = Select::new()
            .items(&options)
            .default(0)
            .interact()
            .map_err(|e| Error::InvalidInput(e.to_string()))?;

        if choice == 0 {
            verify_totp_2fa(auth_client, &auth_resp).await
        } else {
            verify_passkey_2fa(auth_client, &auth_resp, app).await
        }
    } else if has_totp {
        verify_totp_2fa(auth_client, &auth_resp).await
    } else if has_passkey {
        verify_passkey_2fa(auth_client, &auth_resp, app).await
    } else {
        Ok(auth_resp)
    }
}

async fn update_account(storage: &Storage, email: &str, dir: &str, app_str: &str) -> Result<()> {
    let app = match app_str.to_lowercase().as_str() {
        "photos" => App::Photos,
        "locker" => App::Locker,
        "auth" => App::Auth,
        _ => {
            return Err(Error::InvalidInput(format!(
                "Invalid app: {app_str}. Must be one of: photos, locker, auth"
            )));
        }
    };

    if storage.accounts().get(email, app)?.is_none() {
        return Err(Error::NotFound(format!(
            "Account not found: {} (app: {:?})",
            email, app
        )));
    }

    let export_path = PathBuf::from(dir);
    if !export_path.exists() {
        println!("Creating export directory: {dir}");
        std::fs::create_dir_all(&export_path).map_err(Error::Io)?;
    }

    storage.accounts().update_export_dir(email, app, dir)?;

    println!("\n✅ Account updated successfully!");
    println!("   Email: {email}");
    println!("   App: {app:?}");
    println!("   New export directory: {dir}");

    Ok(())
}

async fn get_token(storage: &Storage, email: &str, app_str: &str) -> Result<()> {
    let app = match app_str.to_lowercase().as_str() {
        "photos" => App::Photos,
        "locker" => App::Locker,
        "auth" => App::Auth,
        _ => {
            return Err(Error::InvalidInput(format!(
                "Invalid app: {app_str}. Must be one of: photos, locker, auth"
            )));
        }
    };

    let account = storage
        .accounts()
        .get(email, app)?
        .ok_or_else(|| Error::NotFound(format!("Account not found: {email}")))?;

    let secrets = storage
        .accounts()
        .get_secrets(account.user_id, account.app)?
        .ok_or_else(|| Error::NotFound(format!("Secrets not found for account {email}")))?;

    let token_str = base64::engine::general_purpose::URL_SAFE.encode(&secrets.token);

    println!("{token_str}");

    Ok(())
}

async fn verify_totp_2fa(
    auth_client: &AuthClient<'_>,
    auth_resp: &crate::api::models::AuthResponse,
) -> Result<crate::api::models::AuthResponse> {
    println!("\n📱 Two-factor authentication required");

    let session_id = auth_resp
        .get_two_factor_session_id()
        .ok_or_else(|| Error::AuthenticationFailed("No 2FA session ID".to_string()))?;

    loop {
        let totp_code: String = Input::new()
            .with_prompt("Enter TOTP code")
            .validate_with(|input: &String| {
                if input.len() == 6 && input.chars().all(char::is_numeric) {
                    Ok(())
                } else {
                    Err("TOTP code must be 6 digits")
                }
            })
            .interact_text()
            .map_err(|e| Error::InvalidInput(e.to_string()))?;

        match auth_client.verify_totp(session_id, &totp_code).await {
            Ok(result) => {
                println!("✓ Two-factor authentication verified!");
                return Ok(result);
            }
            Err(Error::ApiError {
                status: 400 | 401, ..
            }) => {
                println!("❌ Invalid code, please try again.");
            }
            Err(Error::ApiError { status: 410, .. }) => {
                return Err(Error::AuthenticationFailed(
                    "TOTP session expired. Please restart login.".to_string(),
                ));
            }
            Err(e) => return Err(e),
        }
    }
}

async fn verify_passkey_2fa(
    auth_client: &AuthClient<'_>,
    auth_resp: &crate::api::models::AuthResponse,
    app: App,
) -> Result<crate::api::models::AuthResponse> {
    let passkey_session_id = auth_resp
        .passkey_session_id
        .as_ref()
        .filter(|s| !s.is_empty())
        .ok_or_else(|| Error::AuthenticationFailed("No passkey session ID".to_string()))?;

    let accounts_url = auth_resp
        .accounts_url
        .as_ref()
        .filter(|s| !s.is_empty())
        .map(|s| s.as_str())
        .unwrap_or("https://accounts.ente.io");

    let client_package = match app {
        App::Photos => "io.ente.photos",
        App::Auth => "io.ente.auth",
        App::Locker => "io.ente.locker",
    };

    let passkey_url = format!(
        "{}/passkeys/verify?passkeySessionID={}&redirect=ente-cli://passkey&clientPackage={}",
        accounts_url, passkey_session_id, client_package
    );

    println!("\n🔑 Passkey verification required");
    println!("Open this URL in your browser to verify your passkey:\n{passkey_url}");

    if let Err(e) = open::that(&passkey_url) {
        log::error!("failed to open browser: {e}");
    }

    loop {
        let _: String = Input::new()
            .with_prompt("Press Enter once you have completed passkey verification")
            .allow_empty(true)
            .interact_text()
            .map_err(|e| Error::InvalidInput(e.to_string()))?;

        match auth_client.check_passkey_status(passkey_session_id).await {
            Ok(result) => {
                println!("✓ Passkey verification completed!");
                return Ok(result);
            }
            Err(Error::ApiError {
                status: 400 | 404, ..
            }) => {
                println!("⏳ Passkey verification not yet complete.");
            }
            Err(Error::ApiError { status: 410, .. }) => {
                return Err(Error::AuthenticationFailed(
                    "Passkey session expired. Please restart login.".to_string(),
                ));
            }
            Err(e) => return Err(e),
        }
    }
}
