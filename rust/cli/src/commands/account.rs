use crate::{
    api::{ApiClient, AuthClient},
    cli::account::{AccountCommand, AccountSubcommands},
    models::{
        account::{Account, AccountSecrets, App},
        error::Result,
    },
    storage::Storage,
};
use base64::Engine;
use dialoguer::{Input, Password, Select};
use std::path::PathBuf;

// Use ente-core for auth operations
use ente_core::auth::{DecryptedSecrets, KeyAttributes as CoreKeyAttributes, derive_kek};
use ente_core::crypto;

/// Convert CLI's KeyAttributes to core's KeyAttributes
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
    key_enc_key: &[u8],
    key_attrs: &CoreKeyAttributes,
    token: &str,
) -> std::result::Result<DecryptedSecrets, ente_core::auth::AuthError> {
    use ente_core::auth::AuthError;

    let encrypted_key = ente_core::crypto::decode_b64(&key_attrs.encrypted_key)
        .map_err(|e| AuthError::Decode(format!("encrypted_key: {}", e)))?;
    let key_nonce = ente_core::crypto::decode_b64(&key_attrs.key_decryption_nonce)
        .map_err(|e| AuthError::Decode(format!("key_decryption_nonce: {}", e)))?;
    let master_key = ente_core::crypto::secretbox::decrypt(&encrypted_key, &key_nonce, key_enc_key)
        .map_err(|_| AuthError::IncorrectPassword)?;

    let encrypted_secret_key = ente_core::crypto::decode_b64(&key_attrs.encrypted_secret_key)
        .map_err(|e| AuthError::Decode(format!("encrypted_secret_key: {}", e)))?;
    let secret_key_nonce = ente_core::crypto::decode_b64(&key_attrs.secret_key_decryption_nonce)
        .map_err(|e| AuthError::Decode(format!("secret_key_decryption_nonce: {}", e)))?;
    let secret_key = ente_core::crypto::secretbox::decrypt(
        &encrypted_secret_key,
        &secret_key_nonce,
        &master_key,
    )
    .map_err(|_| AuthError::InvalidKeyAttributes)?;

    let token = base64::engine::general_purpose::URL_SAFE
        .decode(token)
        .or_else(|_| base64::engine::general_purpose::STANDARD.decode(token))
        .map_err(|e| AuthError::Decode(format!("token: {}", e)))?;

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

    // Get email (from arg or prompt)
    let email = if let Some(email) = email_arg {
        email
    } else {
        Input::new()
            .with_prompt("Enter your email address")
            .interact_text()
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?
    };

    // Parse app type
    let app = match app_arg.to_lowercase().as_str() {
        "photos" => App::Photos,
        "locker" => App::Locker,
        "auth" => App::Auth,
        _ => {
            // If invalid app provided via CLI, use interactive selection
            if password_arg.is_some() {
                return Err(crate::models::error::Error::InvalidInput(format!(
                    "Invalid app: {app_arg}. Must be one of: photos, locker, auth"
                )));
            }
            let apps = vec!["photos", "locker", "auth"];
            let app_index = Select::new()
                .with_prompt("Select the Ente app")
                .items(&apps)
                .default(0)
                .interact()
                .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;
            match apps[app_index] {
                "photos" => App::Photos,
                "locker" => App::Locker,
                "auth" => App::Auth,
                _ => unreachable!(),
            }
        }
    };

    // Check if account already exists
    if let Ok(Some(_existing)) = storage.accounts().get(&email, app) {
        println!("\n❌ Account already exists for {email} with app {app:?}");
        return Ok(());
    }

    // Check if we're in non-interactive mode (password provided via CLI)
    let is_non_interactive = password_arg.is_some();

    // Get password (from arg or prompt)
    let password = if let Some(password) = password_arg {
        password
    } else {
        Password::new()
            .with_prompt("Enter your password")
            .interact()
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?
    };

    // Get export directory (from arg or use default)
    let export_dir = if let Some(dir) = export_dir_arg {
        dir
    } else if is_non_interactive {
        // If password was provided via CLI (non-interactive mode), use default path
        format!("./exports/{email}")
    } else {
        Input::new()
            .with_prompt("Enter export directory path")
            .default(format!("./exports/{email}"))
            .interact_text()
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?
    };

    // Validate export directory
    let export_path = PathBuf::from(&export_dir);
    if !export_path.exists() {
        println!("Creating export directory: {export_dir}");
        std::fs::create_dir_all(&export_path).map_err(crate::models::error::Error::Io)?;
    }

    // Initialize API client with the specified endpoint
    log::info!("Using API endpoint: {endpoint}");
    let api_client = ApiClient::new(Some(endpoint.clone()))?;
    let auth_client = AuthClient::new(&api_client);

    println!("\nAuthenticating with Ente servers...");

    // First, get SRP attributes to check if email MFA is enabled
    let srp_attrs = auth_client.get_srp_attributes(&email).await?;
    log::debug!(
        "SRP attributes: is_email_mfa_enabled={}",
        srp_attrs.is_email_mfa_enabled
    );

    // Determine auth flow based on email MFA setting
    let (auth_response, mut key_enc_key) = if srp_attrs.is_email_mfa_enabled {
        // Email MFA flow: send OTP, verify email first, then do SRP
        println!("\n📧 Email MFA is enabled. Sending verification code...");

        auth_client.send_login_otp(&email).await?;
        println!("✓ Verification code sent to {email}");

        // Prompt for OTP
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
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;

        // Verify email with OTP (with retry on wrong code)
        let mut current_otp = otp;
        let email_auth_resp = loop {
            println!("Verifying email...");
            match auth_client.verify_email(&email, &current_otp).await {
                Ok(resp) => {
                    println!("✓ Email verified!");
                    break resp;
                }
                Err(e) => {
                    // Invalid or expired code - allow retry
                    if e.is_retryable_auth() || e.is_gone() {
                        println!("❌ Invalid or expired code. Please try again.");
                        // Resend OTP
                        auth_client.send_login_otp(&email).await?;
                        println!("✓ New verification code sent to {email}");

                        // Prompt for new OTP
                        current_otp = Input::new()
                            .with_prompt("Enter the 6-digit code from your email")
                            .validate_with(|input: &String| {
                                if input.len() == 6 && input.chars().all(char::is_numeric) {
                                    Ok(())
                                } else {
                                    Err("Code must be 6 digits")
                                }
                            })
                            .interact_text()
                            .map_err(|e| {
                                crate::models::error::Error::InvalidInput(e.to_string())
                            })?;
                        continue;
                    } else {
                        return Err(e);
                    }
                }
            }
        };
        let mut email_auth_resp = email_auth_resp;

        // Check if 2FA is required after email verification
        let has_totp = email_auth_resp.get_two_factor_session_id().is_some();
        let has_passkey = email_auth_resp
            .passkey_session_id
            .as_ref()
            .is_some_and(|s| !s.is_empty());

        if has_totp && has_passkey {
            // Both available - let user choose
            println!("\n🔐 Two-factor authentication required");
            println!("Choose verification method:");
            let options = vec!["TOTP (Authenticator app)", "Passkey"];
            let choice = Select::new()
                .items(&options)
                .default(0)
                .interact()
                .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;

            if choice == 0 {
                // TOTP
                email_auth_resp = verify_totp_2fa(&auth_client, &email_auth_resp).await?;
            } else {
                // Passkey
                email_auth_resp = verify_passkey_2fa(&auth_client, &email_auth_resp, app).await?;
            }
        } else if has_totp {
            email_auth_resp = verify_totp_2fa(&auth_client, &email_auth_resp).await?;
        } else if has_passkey {
            email_auth_resp = verify_passkey_2fa(&auth_client, &email_auth_resp, app).await?;
        }

        // Derive key encryption key from password for decryption using ente-core
        println!("Deriving encryption key (this may take a few seconds)...");
        let key_enc_key = derive_kek(
            &password,
            &srp_attrs.kek_salt,
            srp_attrs.mem_limit as u32,
            srp_attrs.ops_limit as u32,
        )
        .map_err(|e| crate::models::error::Error::Crypto(e.to_string()))?;

        (email_auth_resp, key_enc_key)
    } else {
        // Standard SRP password authentication (with retry on wrong password)
        let mut current_password = password.clone();
        loop {
            match auth_client.login_with_srp(&email, &current_password).await {
                Ok(result) => break result,
                Err(e) => {
                    // Wrong password - allow retry
                    if e.is_unauthorized() || e.is_retryable_auth() {
                        println!("\n❌ Incorrect password. Please try again.");
                        current_password = Password::new()
                            .with_prompt("Enter your password")
                            .interact()
                            .map_err(|e| {
                                crate::models::error::Error::InvalidInput(e.to_string())
                            })?;
                        continue;
                    } else {
                        return Err(e);
                    }
                }
            }
        }
    };

    // Handle 2FA if required - for non-email-MFA flow
    let has_totp = auth_response.get_two_factor_session_id().is_some();
    let has_passkey = auth_response
        .passkey_session_id
        .as_ref()
        .is_some_and(|s| !s.is_empty());

    let auth_response = if has_totp && has_passkey {
        // Both available - let user choose
        println!("\n🔐 Two-factor authentication required");
        println!("Choose verification method:");
        let options = vec!["TOTP (Authenticator app)", "Passkey"];
        let choice = Select::new()
            .items(&options)
            .default(0)
            .interact()
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;

        if choice == 0 {
            verify_totp_2fa(&auth_client, &auth_response).await?
        } else {
            verify_passkey_2fa(&auth_client, &auth_response, app).await?
        }
    } else if has_totp {
        verify_totp_2fa(&auth_client, &auth_response).await?
    } else if has_passkey {
        verify_passkey_2fa(&auth_client, &auth_response, app).await?
    } else {
        auth_response
    };

    // Decrypt keys
    log::debug!(
        "Final auth_response: id={}, has_key_attributes={}, has_encrypted_token={}",
        auth_response.id,
        auth_response.key_attributes.is_some(),
        auth_response.encrypted_token.is_some()
    );

    let key_attributes = auth_response.key_attributes.as_ref().ok_or_else(|| {
        crate::models::error::Error::AuthenticationFailed("No key attributes".to_string())
    })?;

    println!("\nDecrypting account keys...");

    let encrypted_token = auth_response.encrypted_token.as_deref();
    let response_token = auth_response.token.as_deref();

    if encrypted_token.is_none() && response_token.is_none() {
        return Err(crate::models::error::Error::AuthenticationFailed(
            "No token in response".to_string(),
        ));
    }

    // Convert to core key attributes
    let core_key_attrs = to_core_key_attributes(key_attributes);

    // Decrypt secrets (with retry on wrong password)
    let secrets: DecryptedSecrets = loop {
        let decrypt_result = if let Some(encrypted_token) = encrypted_token {
            ente_core::auth::decrypt_secrets(&key_enc_key, &core_key_attrs, encrypted_token)
        } else if let Some(token) = response_token {
            decrypt_secrets_with_plain_token(&key_enc_key, &core_key_attrs, token)
        } else {
            return Err(crate::models::error::Error::AuthenticationFailed(
                "No token in response".to_string(),
            ));
        };

        match decrypt_result {
            Ok(secrets) => {
                log::info!("Secrets decrypted successfully");
                break secrets;
            }
            Err(e) => {
                if matches!(e, ente_core::auth::AuthError::IncorrectPassword) {
                    println!("❌ Incorrect password. Please try again.");

                    // Prompt for password again
                    let new_password = Password::new()
                        .with_prompt("Enter your password")
                        .interact()
                        .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;

                    // Re-derive key encryption key using ente-core
                    println!("Verifying password (this may take a few seconds)...");
                    key_enc_key = derive_kek(
                        &new_password,
                        &key_attributes.kek_salt,
                        key_attributes.mem_limit as u32,
                        key_attributes.ops_limit as u32,
                    )
                    .map_err(|e| crate::models::error::Error::Crypto(e.to_string()))?;

                    println!("Decrypting account keys...");
                    continue;
                } else {
                    return Err(crate::models::error::Error::Crypto(e.to_string()));
                }
            }
        }
    };

    // Extract keys from decrypted secrets
    let master_key = secrets.master_key;
    let secret_key = secrets.secret_key;
    let public_key = crypto::decode_b64(&key_attributes.public_key)?;

    // Token is already decrypted by decrypt_secrets
    let token = secrets.token;

    // Create account
    let account = Account {
        user_id: auth_response.id,
        email: email.clone(),
        app,
        endpoint: endpoint.clone(),
        export_dir: Some(export_dir.clone()),
    };

    // Create account secrets
    let secrets = AccountSecrets {
        token,
        master_key,
        secret_key,
        public_key,
    };

    // Store account in database
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

async fn update_account(storage: &Storage, email: &str, dir: &str, app_str: &str) -> Result<()> {
    let app = match app_str.to_lowercase().as_str() {
        "photos" => App::Photos,
        "locker" => App::Locker,
        "auth" => App::Auth,
        _ => {
            return Err(crate::models::error::Error::InvalidInput(format!(
                "Invalid app: {app_str}. Must be one of: photos, locker, auth"
            )));
        }
    };

    // Check if account exists
    if storage.accounts().get(email, app)?.is_none() {
        return Err(crate::models::error::Error::NotFound(format!(
            "Account not found: {} (app: {:?})",
            email, app
        )));
    }

    // Validate export directory
    let export_path = PathBuf::from(dir);
    if !export_path.exists() {
        println!("Creating export directory: {dir}");
        std::fs::create_dir_all(&export_path).map_err(crate::models::error::Error::Io)?;
    }

    // Update account
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
            return Err(crate::models::error::Error::InvalidInput(format!(
                "Invalid app: {app_str}. Must be one of: photos, locker, auth"
            )));
        }
    };

    // Get account
    let account = storage.accounts().get(email, app)?.ok_or_else(|| {
        crate::models::error::Error::NotFound(format!("Account not found: {email}"))
    })?;

    // Get account secrets
    let secrets = storage
        .accounts()
        .get_secrets(account.user_id, account.app)?
        .ok_or_else(|| {
            crate::models::error::Error::NotFound(format!("Secrets not found for account {email}"))
        })?;

    // Token is stored as raw bytes from sealed_box_open
    // The Go CLI returns it as base64 URL-encoded string WITH padding (matching TokenStr() in Go)
    let token_str = base64::engine::general_purpose::URL_SAFE.encode(&secrets.token);

    println!("{token_str}");

    Ok(())
}

/// Helper function to verify TOTP 2FA with retry on wrong code
async fn verify_totp_2fa(
    auth_client: &AuthClient<'_>,
    auth_resp: &crate::api::models::AuthResponse,
) -> Result<crate::api::models::AuthResponse> {
    println!("\n📱 Two-factor authentication required");

    let session_id = auth_resp.get_two_factor_session_id().ok_or_else(|| {
        crate::models::error::Error::AuthenticationFailed("No 2FA session ID".to_string())
    })?;

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
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;

        match auth_client.verify_totp(session_id, &totp_code).await {
            Ok(result) => {
                println!("✓ Two-factor authentication verified!");
                return Ok(result);
            }
            Err(e) => {
                // Invalid TOTP code - allow retry
                if e.is_retryable_auth() {
                    println!("❌ Invalid TOTP code. Please try again.");
                    continue;
                } else if e.is_gone() {
                    return Err(crate::models::error::Error::AuthenticationFailed(
                        "TOTP session expired. Please restart login.".to_string(),
                    ));
                } else {
                    return Err(e);
                }
            }
        }
    }
}

/// Helper function to verify Passkey 2FA
async fn verify_passkey_2fa(
    auth_client: &AuthClient<'_>,
    auth_resp: &crate::api::models::AuthResponse,
    app: App,
) -> Result<crate::api::models::AuthResponse> {
    let passkey_session_id = auth_resp
        .passkey_session_id
        .as_ref()
        .filter(|s| !s.is_empty())
        .ok_or_else(|| {
            crate::models::error::Error::AuthenticationFailed("No passkey session ID".to_string())
        })?;

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
    println!("Opening browser for passkey verification...");
    println!("URL: {}", passkey_url);

    // Try to open the URL in the browser
    if let Err(e) = open::that(&passkey_url) {
        println!("Failed to open browser: {e}");
        println!("Please open the URL manually.");
    }

    // Poll for passkey verification completion
    loop {
        let _: String = Input::new()
            .with_prompt("Press Enter after completing passkey verification in browser")
            .allow_empty(true)
            .interact_text()
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?;

        match auth_client.check_passkey_status(passkey_session_id).await {
            Ok(result) => {
                println!("✓ Passkey verification completed!");
                return Ok(result);
            }
            Err(e) => {
                if e.is_not_ready() {
                    println!("⏳ Passkey verification not yet complete.");
                    println!("Please complete the verification in your browser and press Enter.");
                } else if e.is_gone() {
                    return Err(crate::models::error::Error::AuthenticationFailed(
                        "Passkey session expired. Please restart login.".to_string(),
                    ));
                } else {
                    println!("Error checking passkey status: {e}");
                    println!("Please try again.");
                }
            }
        }
    }
}
