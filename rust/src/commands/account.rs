use crate::{
    api::{ApiClient, AuthClient},
    cli::account::{AccountCommand, AccountSubcommands},
    crypto::{decode_base64, sealed_box_open, secret_box_open},
    models::{
        account::{Account, AccountSecrets, App},
        error::Result,
    },
    storage::Storage,
};
use dialoguer::{Input, Password, Select};
use std::path::PathBuf;

pub async fn handle_account_command(cmd: AccountCommand, storage: &Storage) -> Result<()> {
    match cmd.command {
        AccountSubcommands::List => list_accounts(storage).await,
        AccountSubcommands::Add {
            email,
            password,
            app,
            export_dir,
        } => add_account(storage, email, password, app, export_dir).await,
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
    println!("{:<30} {:<10} {:<40}", "Email", "App", "Export Directory");
    println!("{}", "-".repeat(80));

    for account in accounts {
        println!(
            "{:<30} {:<10} {:<40}",
            account.email,
            format!("{:?}", account.app).to_lowercase(),
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

    // Get password (from arg or prompt)
    let password = if let Some(password) = password_arg {
        password
    } else {
        Password::new()
            .with_prompt("Enter your password")
            .interact()
            .map_err(|e| crate::models::error::Error::InvalidInput(e.to_string()))?
    };

    // Get export directory (from arg or prompt)
    let export_dir = if let Some(dir) = export_dir_arg {
        dir
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

    // Initialize API client (use ENTE_ENDPOINT env var if set, otherwise default to production)
    let api_endpoint = std::env::var("ENTE_ENDPOINT").ok();
    if let Some(ref endpoint) = api_endpoint {
        log::debug!("Using custom API endpoint: {endpoint}");
    }
    let api_client = ApiClient::new(api_endpoint)?;
    let auth_client = AuthClient::new(&api_client);

    println!("\nAuthenticating with Ente servers...");

    // Perform SRP authentication
    let (auth_response, key_enc_key) = match auth_client.login_with_srp(&email, &password).await {
        Ok(result) => result,
        Err(e) => {
            println!("\n❌ Authentication failed: {e}");
            return Err(e);
        }
    };

    // Handle 2FA if required
    let auth_response = if auth_response.is_mfa_required() {
        println!("\n📱 Two-factor authentication required");
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

        auth_client
            .verify_totp(
                auth_response
                    .two_factor_session_id
                    .as_ref()
                    .ok_or_else(|| {
                        crate::models::error::Error::AuthenticationFailed(
                            "No 2FA session ID".to_string(),
                        )
                    })?,
                &totp_code,
            )
            .await?
    } else if auth_response.is_passkey_required() {
        println!("\n🔑 Passkey verification required");
        println!("Please complete passkey verification in your browser...");
        // TODO: Implement passkey verification flow
        return Err(crate::models::error::Error::Generic(
            "Passkey verification not yet implemented".to_string(),
        ));
    } else {
        auth_response
    };

    // Decrypt keys
    let key_attributes = auth_response.key_attributes.as_ref().ok_or_else(|| {
        crate::models::error::Error::AuthenticationFailed("No key attributes".to_string())
    })?;

    println!("\nDecrypting account keys...");

    // Decrypt master key
    let master_key = secret_box_open(
        &decode_base64(&key_attributes.encrypted_key)?,
        &decode_base64(&key_attributes.key_decryption_nonce)?,
        &key_enc_key,
    )?;

    // Decrypt secret key
    let secret_key = secret_box_open(
        &decode_base64(&key_attributes.encrypted_secret_key)?,
        &decode_base64(&key_attributes.secret_key_decryption_nonce)?,
        &master_key,
    )?;

    // Get public key
    let public_key = decode_base64(&key_attributes.public_key)?;

    // Decrypt token if encrypted
    let token = if let Some(encrypted_token) = &auth_response.encrypted_token {
        sealed_box_open(&decode_base64(encrypted_token)?, &public_key, &secret_key)?
    } else if let Some(plain_token) = &auth_response.token {
        plain_token.as_bytes().to_vec()
    } else {
        return Err(crate::models::error::Error::AuthenticationFailed(
            "No token in response".to_string(),
        ));
    };

    // Create account
    let account = Account {
        id: 0, // Will be set by database
        email: email.clone(),
        user_id: auth_response.id,
        app,
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
    let account_id = storage.accounts().add(&account)?;
    storage.accounts().store_secrets(account_id, &secrets)?;

    println!("\n✅ Account added successfully!");
    println!("   Email: {email}");
    println!("   App: {app:?}");
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
    let secrets = storage.accounts().get_secrets(account.id)?.ok_or_else(|| {
        crate::models::error::Error::NotFound(format!("Secrets not found for account {email}"))
    })?;

    // Convert token to string (assuming it's UTF-8)
    let token_str = String::from_utf8(secrets.token.clone()).map_err(|_| {
        crate::models::error::Error::Generic("Token is not valid UTF-8".to_string())
    })?;

    println!("{token_str}");

    Ok(())
}
