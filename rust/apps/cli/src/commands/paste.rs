use crate::{
    api::client::USER_AGENT,
    cli::paste::{PasteCommand, PasteSubcommands},
    models::error::{Error, Result},
};
use base64::Engine;
use base64::engine::general_purpose::STANDARD as BASE64;
use ente_core::crypto::{self, argon, blob, keys, secretbox};
use reqwest::{Client, StatusCode, header};
use serde::{Deserialize, Serialize};
use std::ffi::OsStr;
use std::io::{self, IsTerminal, Read};
use std::path::PathBuf;

const MAX_PASTE_CHARS: usize = 4000;
const FRAGMENT_SECRET_LENGTH: usize = 12;
const FRAGMENT_SECRET_ALPHABET: &[u8] =
    b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const PASTE_GUARD_COOKIE: &str = "paste_guard";

pub async fn handle_paste_command(cmd: PasteCommand) -> Result<()> {
    match cmd.command {
        PasteSubcommands::Create {
            text,
            file,
            endpoint,
            paste_origin,
        } => {
            let text = read_paste_text(text, file)?;
            let link = create_paste(&endpoint, &paste_origin, &text).await?;
            println!("{link}");
            Ok(())
        }
        PasteSubcommands::Consume {
            link_or_token,
            key,
            endpoint,
        } => {
            let (access_token, fragment_secret) = parse_paste_reference(&link_or_token, key)?;
            let text = consume_paste(&endpoint, &access_token, &fragment_secret).await?;
            print!("{text}");
            Ok(())
        }
    }
}

fn read_paste_text(text: Option<String>, file: Option<PathBuf>) -> Result<String> {
    let text = match (text, file) {
        (Some(text), None) => text,
        (None, Some(path)) if path.as_os_str() == OsStr::new("-") => read_stdin()?,
        (None, Some(path)) => std::fs::read_to_string(path)?,
        (None, None) if !io::stdin().is_terminal() => read_stdin()?,
        (None, None) => {
            return Err(Error::InvalidInput(
                "Provide text, --file, or pipe text on stdin".to_string(),
            ));
        }
        (Some(_), Some(_)) => unreachable!("clap prevents text and --file together"),
    };

    if text.trim().is_empty() {
        return Err(Error::InvalidInput("Paste text is empty".to_string()));
    }
    if text.chars().count() > MAX_PASTE_CHARS {
        return Err(Error::InvalidInput(format!(
            "Paste is limited to {MAX_PASTE_CHARS} characters"
        )));
    }
    Ok(text)
}

fn read_stdin() -> Result<String> {
    let mut input = String::new();
    io::stdin().read_to_string(&mut input)?;
    Ok(input)
}

async fn create_paste(endpoint: &str, paste_origin: &str, text: &str) -> Result<String> {
    let client = paste_http_client()?;
    let (fragment_secret, payload) = encrypt_paste_for_create(text)?;
    let response: CreatePasteResponse =
        post_json(&client, endpoint, "/paste/create", &payload, None, None).await?;
    Ok(build_paste_link(
        paste_origin,
        &response.access_token,
        &fragment_secret,
    ))
}

async fn consume_paste(
    endpoint: &str,
    access_token: &str,
    fragment_secret: &str,
) -> Result<String> {
    let client = paste_http_client()?;
    let request = PasteTokenRequest {
        access_token: access_token.to_string(),
    };
    let cookie = guard_cookie(&client, endpoint, &request).await?;
    let payload: PastePayload = post_json(
        &client,
        endpoint,
        "/paste/consume",
        &request,
        Some(("X-Paste-Consume", "1")),
        Some(&cookie),
    )
    .await?;

    decrypt_consumed_paste(fragment_secret, &payload)
}

fn paste_http_client() -> Result<Client> {
    Ok(Client::builder().user_agent(USER_AGENT).build()?)
}

async fn guard_cookie(
    client: &Client,
    endpoint: &str,
    request: &PasteTokenRequest,
) -> Result<String> {
    let url = api_url(endpoint, "/paste/guard");
    let response = client.post(url).json(request).send().await?;
    if !response.status().is_success() {
        return Err(api_error(response).await);
    }

    let cookie_prefix = format!("{PASTE_GUARD_COOKIE}=");
    response
        .headers()
        .get_all(header::SET_COOKIE)
        .iter()
        .filter_map(|value| value.to_str().ok())
        .filter_map(|value| value.split(';').next())
        .find(|value| value.starts_with(&cookie_prefix))
        .map(str::to_string)
        .ok_or_else(|| Error::Generic("Paste guard cookie was not returned".to_string()))
}

async fn post_json<T, B>(
    client: &Client,
    endpoint: &str,
    path: &str,
    body: &B,
    header_pair: Option<(&str, &str)>,
    cookie: Option<&str>,
) -> Result<T>
where
    T: for<'de> Deserialize<'de>,
    B: Serialize,
{
    let mut request = client.post(api_url(endpoint, path)).json(body);
    if let Some((name, value)) = header_pair {
        request = request.header(name, value);
    }
    if let Some(cookie) = cookie {
        request = request.header(header::COOKIE, cookie);
    }

    let response = request.send().await?;
    if !response.status().is_success() {
        return Err(api_error(response).await);
    }

    Ok(response.json().await?)
}

async fn api_error(response: reqwest::Response) -> Error {
    let status = response.status();
    let body = response.text().await.unwrap_or_default();
    let parsed = serde_json::from_str::<ApiErrorBody>(&body).ok();
    let message = parsed
        .as_ref()
        .and_then(|body| body.message.clone().or_else(|| body.code.clone()))
        .unwrap_or_else(|| status_message(status, &body));

    Error::ApiError {
        status: status.as_u16(),
        code: parsed.and_then(|body| body.code),
        message,
    }
}

fn status_message(status: StatusCode, body: &str) -> String {
    if body.trim().is_empty() {
        status.to_string()
    } else {
        body.to_string()
    }
}

fn api_url(endpoint: &str, path: &str) -> String {
    format!("{}{}", endpoint.trim_end_matches('/'), path)
}

fn build_paste_link(paste_origin: &str, access_token: &str, fragment_secret: &str) -> String {
    format!(
        "{}/{}#{}",
        paste_origin.trim_end_matches('/'),
        access_token,
        fragment_secret
    )
}

fn encrypt_paste_for_create(text: &str) -> Result<(String, PastePayload)> {
    let paste_key = keys::generate_key();
    let fragment_secret = create_fragment_secret();
    let encrypted = blob::encrypt_json(
        &PasteText {
            text: text.to_string(),
        },
        &paste_key,
    )?;
    let key_encryption_key = argon::derive_interactive_key(&fragment_secret)?;
    let encrypted_paste_key = secretbox::encrypt_with_key(&paste_key, &key_encryption_key.key)?;

    Ok((
        fragment_secret,
        PastePayload {
            encrypted_data: crypto::encode_b64(&encrypted.encrypted_data),
            decryption_header: crypto::encode_b64(&encrypted.decryption_header),
            encrypted_paste_key: crypto::encode_b64(&encrypted_paste_key.ciphertext),
            encrypted_paste_key_nonce: crypto::encode_b64(&encrypted_paste_key.nonce),
            kdf_nonce: crypto::encode_b64(&key_encryption_key.salt),
            kdf_mem_limit: key_encryption_key.mem_limit,
            kdf_ops_limit: key_encryption_key.ops_limit,
        },
    ))
}

fn decrypt_consumed_paste(fragment_secret: &str, payload: &PastePayload) -> Result<String> {
    let salt = BASE64.decode(&payload.kdf_nonce)?;
    let key_encryption_key = argon::derive_key(
        fragment_secret,
        &salt,
        payload.kdf_mem_limit,
        payload.kdf_ops_limit,
    )?;
    let encrypted_paste_key = BASE64.decode(&payload.encrypted_paste_key)?;
    let encrypted_paste_key_nonce = BASE64.decode(&payload.encrypted_paste_key_nonce)?;
    let paste_key = secretbox::decrypt(
        &encrypted_paste_key,
        &encrypted_paste_key_nonce,
        &key_encryption_key,
    )?;
    let encrypted_data = BASE64.decode(&payload.encrypted_data)?;
    let decryption_header = BASE64.decode(&payload.decryption_header)?;
    let text: PasteText = blob::decrypt_json(
        &blob::EncryptedBlob {
            encrypted_data,
            decryption_header,
        },
        &paste_key,
    )?;
    Ok(text.text)
}

fn create_fragment_secret() -> String {
    let mut secret = String::with_capacity(FRAGMENT_SECRET_LENGTH);
    let threshold = 256 - (256 % FRAGMENT_SECRET_ALPHABET.len());

    while secret.len() < FRAGMENT_SECRET_LENGTH {
        for byte in keys::random_bytes(FRAGMENT_SECRET_LENGTH) {
            let byte = usize::from(byte);
            if byte >= threshold {
                continue;
            }
            let index = byte % FRAGMENT_SECRET_ALPHABET.len();
            secret.push(char::from(FRAGMENT_SECRET_ALPHABET[index]));
            if secret.len() == FRAGMENT_SECRET_LENGTH {
                break;
            }
        }
    }

    secret
}

fn parse_paste_reference(input: &str, key: Option<String>) -> Result<(String, String)> {
    let input = input.trim();
    if input.is_empty() {
        return Err(Error::InvalidInput(
            "Paste URL or access token is empty".to_string(),
        ));
    }

    let (access_token, embedded_secret) = match reqwest::Url::parse(input) {
        Ok(url) => {
            let token = url
                .path_segments()
                .and_then(|mut segments| segments.rfind(|segment| !segment.is_empty()))
                .ok_or_else(|| {
                    Error::InvalidInput("Paste URL is missing an access token".into())
                })?;
            (token.to_string(), url.fragment().map(str::to_string))
        }
        Err(_) => match input.split_once('#') {
            Some((token, secret)) => (token.trim().to_string(), Some(secret.trim().to_string())),
            None => (input.to_string(), None),
        },
    };

    if access_token.trim().is_empty() {
        return Err(Error::InvalidInput(
            "Paste access token is empty".to_string(),
        ));
    }

    let fragment_secret = match (embedded_secret, key) {
        (Some(embedded), Some(key)) if embedded != key => {
            return Err(Error::InvalidInput(
                "Paste URL fragment and --key do not match".to_string(),
            ));
        }
        (Some(embedded), _) => embedded,
        (None, Some(key)) => key,
        (None, None) => {
            return Err(Error::InvalidInput(
                "Paste key missing. Pass a full paste URL or --key".to_string(),
            ));
        }
    };
    validate_fragment_secret(&fragment_secret)?;

    Ok((access_token, fragment_secret))
}

fn validate_fragment_secret(fragment_secret: &str) -> Result<()> {
    if fragment_secret.len() == FRAGMENT_SECRET_LENGTH
        && fragment_secret
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric())
    {
        return Ok(());
    }

    Err(Error::InvalidInput("Invalid paste key".to_string()))
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PastePayload {
    encrypted_data: String,
    decryption_header: String,
    encrypted_paste_key: String,
    encrypted_paste_key_nonce: String,
    kdf_nonce: String,
    kdf_mem_limit: u32,
    kdf_ops_limit: u32,
}

#[derive(Serialize, Deserialize)]
struct PasteText {
    text: String,
}

#[derive(Deserialize)]
struct CreatePasteResponse {
    #[serde(rename = "accessToken")]
    access_token: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct PasteTokenRequest {
    access_token: String,
}

#[derive(Deserialize)]
struct ApiErrorBody {
    code: Option<String>,
    message: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockito::{Matcher, Server};

    #[test]
    fn encrypt_then_decrypt_paste_payload() {
        crypto::init().unwrap();

        let (fragment_secret, payload) = encrypt_paste_for_create("hello paste").unwrap();
        let text = decrypt_consumed_paste(&fragment_secret, &payload).unwrap();

        assert_eq!(text, "hello paste");
    }

    #[test]
    fn parse_full_paste_link() {
        let (token, secret) =
            parse_paste_reference("https://paste.ente.com/ABC123#AbCd1234EfGh", None).unwrap();

        assert_eq!(token, "ABC123");
        assert_eq!(secret, "AbCd1234EfGh");
    }

    #[test]
    fn parse_token_with_key() {
        let (token, secret) =
            parse_paste_reference("ABC123", Some("AbCd1234EfGh".to_string())).unwrap();

        assert_eq!(token, "ABC123");
        assert_eq!(secret, "AbCd1234EfGh");
    }

    #[test]
    fn reject_mismatched_fragment_and_key() {
        let error = parse_paste_reference(
            "https://paste.ente.com/ABC123#AbCd1234EfGh",
            Some("123456789012".to_string()),
        )
        .unwrap_err();

        assert!(matches!(error, Error::InvalidInput(_)));
    }

    #[tokio::test]
    async fn consume_paste_uses_guard_cookie_and_decrypts_payload() {
        crypto::init().unwrap();

        let access_token = "ABC123";
        let fragment_secret = "AbCd1234EfGh";
        let payload = test_payload("guarded paste", fragment_secret);
        let mut server = Server::new_async().await;

        let guard = server
            .mock("POST", "/paste/guard")
            .match_body(Matcher::PartialJson(serde_json::json!({
                "accessToken": access_token,
            })))
            .with_status(200)
            .with_header("set-cookie", "paste_guard=test-cookie; Path=/; HttpOnly")
            .with_body("{}")
            .create_async()
            .await;

        let consume = server
            .mock("POST", "/paste/consume")
            .match_header("x-paste-consume", "1")
            .match_header("cookie", "paste_guard=test-cookie")
            .match_body(Matcher::PartialJson(serde_json::json!({
                "accessToken": access_token,
            })))
            .with_status(200)
            .with_body(serde_json::to_string(&payload).unwrap())
            .create_async()
            .await;

        let text = consume_paste(&server.url(), access_token, fragment_secret)
            .await
            .unwrap();

        assert_eq!(text, "guarded paste");
        guard.assert_async().await;
        consume.assert_async().await;
    }

    fn test_payload(text: &str, fragment_secret: &str) -> PastePayload {
        let paste_key = [7u8; secretbox::KEY_BYTES];
        let encrypted = blob::encrypt_json(
            &PasteText {
                text: text.to_string(),
            },
            &paste_key,
        )
        .unwrap();
        let salt = [9u8; argon::SALT_BYTES];
        let key_encryption_key = argon::derive_key(
            fragment_secret,
            &salt,
            argon::MEMLIMIT_MIN,
            argon::OPSLIMIT_MIN,
        )
        .unwrap();
        let encrypted_paste_key =
            secretbox::encrypt_with_key(&paste_key, &key_encryption_key).unwrap();

        PastePayload {
            encrypted_data: crypto::encode_b64(&encrypted.encrypted_data),
            decryption_header: crypto::encode_b64(&encrypted.decryption_header),
            encrypted_paste_key: crypto::encode_b64(&encrypted_paste_key.ciphertext),
            encrypted_paste_key_nonce: crypto::encode_b64(&encrypted_paste_key.nonce),
            kdf_nonce: crypto::encode_b64(&salt),
            kdf_mem_limit: argon::MEMLIMIT_MIN,
            kdf_ops_limit: argon::OPSLIMIT_MIN,
        }
    }
}
