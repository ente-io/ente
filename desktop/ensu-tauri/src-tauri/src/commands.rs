use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Mutex;

use ente_core::{auth as core_auth, crypto as core_crypto};
use inference_rs as llm;
use llmchat_db::{ChatDb, Error as DbError};
use llmchat_db::backend::sqlite::SqliteBackend;
use serde::{Deserialize, Serialize};
use tauri::async_runtime;
use tauri::{AppHandle, State, Window};
use uuid::Uuid;

#[derive(Default)]
pub struct SrpState {
    sessions: Mutex<HashMap<String, core_auth::SrpSession>>,
}

#[derive(Default)]
pub struct LlmState {
    model: Mutex<Option<llm::ModelHandleRef>>,
    context: Mutex<Option<llm::ContextHandleRef>>,
}

#[derive(Default)]
pub struct ChatDbState {
    inner: Mutex<Option<ChatDbHolder>>,
}

struct ChatDbHolder {
    key_b64: String,
    db: ChatDb<SqliteBackend>,
}

#[derive(Debug, Serialize)]
pub struct ApiError {
    code: String,
    message: String,
}

impl ApiError {
    fn new(code: &str, message: impl Into<String>) -> Self {
        Self {
            code: code.to_string(),
            message: message.into(),
        }
    }
}

fn llm_error(message: impl Into<String>) -> ApiError {
    ApiError::new("llm", message)
}

impl From<core_auth::AuthError> for ApiError {
    fn from(e: core_auth::AuthError) -> Self {
        use core_auth::AuthError as E;

        let code = match &e {
            E::IncorrectPassword => "incorrect_password",
            E::IncorrectRecoveryKey => "incorrect_recovery_key",
            E::InvalidKeyAttributes => "invalid_key_attributes",
            E::MissingField(_) => "missing_field",
            E::Crypto(_) => "crypto",
            E::Decode(_) => "decode",
            E::InvalidKey(_) => "invalid_key",
            E::Srp(_) => "srp",
        };

        ApiError::new(code, e.to_string())
    }
}

impl From<core_crypto::CryptoError> for ApiError {
    fn from(e: core_crypto::CryptoError) -> Self {
        use core_crypto::CryptoError as E;

        let code = match &e {
            E::Base64Decode(_) => "base64_decode",
            E::HexDecode(_) => "hex_decode",
            E::InvalidKeyLength { .. } => "invalid_key_length",
            E::InvalidNonceLength { .. } => "invalid_nonce_length",
            E::InvalidSaltLength { .. } => "invalid_salt_length",
            E::InvalidHeaderLength { .. } => "invalid_header_length",
            E::CiphertextTooShort { .. } => "ciphertext_too_short",
            E::InvalidKeyDerivationParams(_) => "invalid_kdf_params",
            E::KeyDerivationFailed => "key_derivation_failed",
            E::EncryptionFailed => "encryption_failed",
            E::DecryptionFailed => "decryption_failed",
            E::StreamInitFailed => "stream_init_failed",
            E::StreamPushFailed => "stream_push_failed",
            E::StreamPullFailed => "stream_pull_failed",
            E::StreamTruncated => "stream_truncated",
            E::SealedBoxOpenFailed => "sealed_box_open_failed",
            E::InvalidPublicKey => "invalid_public_key",
            E::HashFailed => "hash_failed",
            E::Argon2(_) => "argon2",
            E::Aead => "aead",
            E::ArrayConversion => "array_conversion",
            E::Io(_) => "io",
        };

        ApiError::new(code, e.to_string())
    }
}

impl From<DbError> for ApiError {
    fn from(e: DbError) -> Self {
        use llmchat_db::Error as E;

        let code = match &e {
            E::InvalidKeyLength { .. } => "db_invalid_key_length",
            E::InvalidBlobLength { .. } => "db_invalid_blob_length",
            E::InvalidEncryptedField => "db_invalid_encrypted_field",
            E::UnsupportedValueType(_) => "db_unsupported_value_type",
            E::Row(_) => "db_row",
            E::InvalidSender(_) => "db_invalid_sender",
            E::NotFound { .. } => "db_not_found",
            E::AttachmentNotFound(_) => "db_attachment_not_found",
            E::Crypto(_) => "db_crypto",
            E::SerdeJson(_) => "db_serde_json",
            E::Uuid(_) => "db_uuid",
            E::Utf8(_) => "db_utf8",
            E::Io(_) => "db_io",
            E::Sqlite(_) => "db_sqlite",
            E::UnsupportedOperation(_) => "db_unsupported_operation",
            E::Migration(_) => "db_migration",
        };

        ApiError::new(code, e.to_string())
    }
}

#[derive(Serialize)]
pub struct SrpCredentials {
    kek: String,
    login_key: String,
}

#[derive(Serialize)]
pub struct DecryptedSecrets {
    master_key: String,
    secret_key: String,
    token: String,
}

#[derive(Serialize)]
pub struct DecryptedKeys {
    master_key: String,
    secret_key: String,
}

#[derive(Serialize)]
pub struct EncryptedBox {
    encrypted_data: String,
    nonce: String,
}

#[derive(Serialize)]
pub struct EncryptedBlob {
    encrypted_data: String,
    decryption_header: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrpSessionNewInput {
    srp_user_id: String,
    srp_salt_b64: String,
    login_key_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrpSessionComputeInput {
    session_id: String,
    srp_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrpSessionVerifyInput {
    session_id: String,
    srp_m2_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SrpSessionLookupInput {
    session_id: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeriveSrpCredentialsInput {
    password: String,
    srp_attrs: core_auth::SrpAttributes,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DecryptSecretsInput {
    kek_b64: String,
    key_attrs: core_auth::KeyAttributes,
    encrypted_token_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DecryptKeysInput {
    kek_b64: String,
    key_attrs: core_auth::KeyAttributes,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CryptoBoxInput {
    data_b64: String,
    key_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CryptoBoxDecryptInput {
    encrypted_data_b64: String,
    nonce_b64: String,
    key_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CryptoBlobInput {
    data_b64: String,
    key_b64: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CryptoBlobDecryptInput {
    encrypted_data_b64: String,
    header_b64: String,
    key_b64: String,
}

#[tauri::command]
pub fn crypto_init() -> Result<(), ApiError> {
    core_crypto::init().map_err(ApiError::from)
}

#[tauri::command]
pub fn crypto_generate_key() -> String {
    core_crypto::encode_b64(&core_crypto::keys::generate_key())
}

#[tauri::command]
pub fn crypto_encrypt_box(input: CryptoBoxInput) -> Result<EncryptedBox, ApiError> {
    let data = core_crypto::decode_b64(&input.data_b64).map_err(ApiError::from)?;
    let key = core_crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;
    let out = core_crypto::secretbox::encrypt_with_key(&data, &key).map_err(ApiError::from)?;

    Ok(EncryptedBox {
        encrypted_data: core_crypto::encode_b64(&out.ciphertext),
        nonce: core_crypto::encode_b64(&out.nonce),
    })
}

#[tauri::command]
pub fn crypto_decrypt_box(input: CryptoBoxDecryptInput) -> Result<String, ApiError> {
    let ciphertext = core_crypto::decode_b64(&input.encrypted_data_b64).map_err(ApiError::from)?;
    let nonce = core_crypto::decode_b64(&input.nonce_b64).map_err(ApiError::from)?;
    let key = core_crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;
    let plaintext =
        core_crypto::secretbox::decrypt(&ciphertext, &nonce, &key).map_err(ApiError::from)?;
    Ok(core_crypto::encode_b64(&plaintext))
}

#[tauri::command]
pub fn crypto_encrypt_blob(input: CryptoBlobInput) -> Result<EncryptedBlob, ApiError> {
    let data = core_crypto::decode_b64(&input.data_b64).map_err(ApiError::from)?;
    let key = core_crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;
    let out = core_crypto::blob::encrypt(&data, &key).map_err(ApiError::from)?;
    Ok(EncryptedBlob {
        encrypted_data: core_crypto::encode_b64(&out.encrypted_data),
        decryption_header: core_crypto::encode_b64(&out.decryption_header),
    })
}

#[tauri::command]
pub fn crypto_decrypt_blob(input: CryptoBlobDecryptInput) -> Result<String, ApiError> {
    let ciphertext = core_crypto::decode_b64(&input.encrypted_data_b64).map_err(ApiError::from)?;
    let header = core_crypto::decode_b64(&input.header_b64).map_err(ApiError::from)?;
    let key = core_crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;
    let plaintext =
        core_crypto::blob::decrypt(&ciphertext, &header, &key).map_err(ApiError::from)?;
    Ok(core_crypto::encode_b64(&plaintext))
}

#[tauri::command]
pub fn auth_derive_srp_credentials(
    input: DeriveSrpCredentialsInput,
) -> Result<SrpCredentials, ApiError> {
    let creds = core_auth::derive_srp_credentials(&input.password, &input.srp_attrs)?;
    Ok(SrpCredentials {
        kek: core_crypto::encode_b64(&creds.kek),
        login_key: core_crypto::encode_b64(&creds.login_key),
    })
}

#[tauri::command]
pub fn auth_decrypt_secrets(input: DecryptSecretsInput) -> Result<DecryptedSecrets, ApiError> {
    let kek = core_crypto::decode_b64(&input.kek_b64)
        .map_err(|e| ApiError::new("decode", format!("kek: {}", e)))?;

    let secrets = core_auth::decrypt_secrets(&kek, &input.key_attrs, &input.encrypted_token_b64)?;

    Ok(DecryptedSecrets {
        master_key: core_crypto::encode_b64(&secrets.master_key),
        secret_key: core_crypto::encode_b64(&secrets.secret_key),
        token: core_crypto::bin2base64(&secrets.token, true),
    })
}

#[tauri::command]
pub fn auth_decrypt_keys_only(input: DecryptKeysInput) -> Result<DecryptedKeys, ApiError> {
    let kek = core_crypto::decode_b64(&input.kek_b64)
        .map_err(|e| ApiError::new("decode", format!("kek: {}", e)))?;

    let (master_key, secret_key) = core_auth::decrypt_keys_only(&kek, &input.key_attrs)?;

    Ok(DecryptedKeys {
        master_key: core_crypto::encode_b64(&master_key),
        secret_key: core_crypto::encode_b64(&secret_key),
    })
}

#[tauri::command]
pub fn srp_session_new(
    state: State<SrpState>,
    input: SrpSessionNewInput,
) -> Result<String, ApiError> {
    let srp_salt = core_crypto::decode_b64(&input.srp_salt_b64)
        .map_err(|e| ApiError::new("decode", format!("srp_salt: {}", e)))?;
    let login_key = core_crypto::decode_b64(&input.login_key_b64)
        .map_err(|e| ApiError::new("decode", format!("login_key: {}", e)))?;

    let session = core_auth::SrpSession::new(&input.srp_user_id, &srp_salt, &login_key)?;

    let session_id = Uuid::new_v4().to_string();
    let mut sessions = state
        .sessions
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock SRP session store"))?;
    sessions.insert(session_id.clone(), session);

    Ok(session_id)
}

#[tauri::command]
pub fn srp_session_public_a(
    state: State<SrpState>,
    input: SrpSessionLookupInput,
) -> Result<String, ApiError> {
    let sessions = state
        .sessions
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock SRP session store"))?;
    let session = sessions
        .get(&input.session_id)
        .ok_or_else(|| ApiError::new("srp_session_not_found", "SRP session not found"))?;

    Ok(core_crypto::encode_b64(&session.public_a()))
}

#[tauri::command]
pub fn srp_session_compute_m1(
    state: State<SrpState>,
    input: SrpSessionComputeInput,
) -> Result<String, ApiError> {
    let srp_b = core_crypto::decode_b64(&input.srp_b64)
        .map_err(|e| ApiError::new("decode", format!("srpB: {}", e)))?;

    let mut sessions = state
        .sessions
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock SRP session store"))?;
    let session = sessions
        .get_mut(&input.session_id)
        .ok_or_else(|| ApiError::new("srp_session_not_found", "SRP session not found"))?;

    let m1 = session.compute_m1(&srp_b)?;
    Ok(core_crypto::encode_b64(&m1))
}

#[tauri::command]
pub fn srp_session_verify_m2(
    state: State<SrpState>,
    input: SrpSessionVerifyInput,
) -> Result<(), ApiError> {
    let srp_m2 = core_crypto::decode_b64(&input.srp_m2_b64)
        .map_err(|e| ApiError::new("decode", format!("srpM2: {}", e)))?;

    let mut sessions = state
        .sessions
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock SRP session store"))?;
    let session = sessions
        .get(&input.session_id)
        .ok_or_else(|| ApiError::new("srp_session_not_found", "SRP session not found"))?;

    session.verify_m2(&srp_m2)?;
    sessions.remove(&input.session_id);
    Ok(())
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatSessionDto {
    session_uuid: String,
    title: String,
    created_at: i64,
    updated_at: i64,
    remote_id: Option<String>,
    needs_sync: bool,
    deleted_at: Option<i64>,
}

impl From<llmchat_db::Session> for ChatSessionDto {
    fn from(session: llmchat_db::Session) -> Self {
        Self {
            session_uuid: session.uuid.to_string(),
            title: session.title,
            created_at: session.created_at,
            updated_at: session.updated_at,
            remote_id: session.remote_id,
            needs_sync: session.needs_sync,
            deleted_at: session.deleted_at,
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatMessageDto {
    message_uuid: String,
    session_uuid: String,
    parent_message_uuid: Option<String>,
    sender: String,
    text: String,
    created_at: i64,
    deleted_at: Option<i64>,
}

impl From<llmchat_db::Message> for ChatMessageDto {
    fn from(message: llmchat_db::Message) -> Self {
        let sender = match message.sender {
            llmchat_db::Sender::SelfUser => "self",
            llmchat_db::Sender::Other => "assistant",
        };

        Self {
            message_uuid: message.uuid.to_string(),
            session_uuid: message.session_uuid.to_string(),
            parent_message_uuid: message.parent_message_uuid.map(|value| value.to_string()),
            sender: sender.to_string(),
            text: message.text,
            created_at: message.created_at,
            deleted_at: message.deleted_at,
        }
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatMessageInsertInput {
    session_uuid: String,
    sender: String,
    text: String,
    parent_message_uuid: Option<String>,
}

#[tauri::command]
pub fn chat_db_list_sessions(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
) -> Result<Vec<ChatSessionDto>, ApiError> {
    with_chat_db(&state, &app, &key_b64, |db| {
        Ok(db
            .list_sessions()?
            .into_iter()
            .map(ChatSessionDto::from)
            .collect())
    })
}

#[tauri::command]
pub fn chat_db_get_session(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
) -> Result<Option<ChatSessionDto>, ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db(&state, &app, &key_b64, move |db| {
        Ok(db.get_session(uuid)?.map(ChatSessionDto::from))
    })
}

#[tauri::command]
pub fn chat_db_create_session(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    title: String,
) -> Result<ChatSessionDto, ApiError> {
    with_chat_db(&state, &app, &key_b64, |db| {
        let session = db.create_session(&title)?;
        Ok(ChatSessionDto::from(session))
    })
}

#[tauri::command]
pub fn chat_db_update_session_title(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
    title: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db(&state, &app, &key_b64, move |db| {
        db.update_session_title(uuid, &title)?;
        Ok(())
    })
}

#[tauri::command]
pub fn chat_db_delete_session(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db(&state, &app, &key_b64, move |db| {
        db.delete_session(uuid)?;
        Ok(())
    })
}

#[tauri::command]
pub fn chat_db_get_messages(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
) -> Result<Vec<ChatMessageDto>, ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db(&state, &app, &key_b64, move |db| {
        Ok(db
            .get_messages(uuid)?
            .into_iter()
            .map(ChatMessageDto::from)
            .collect())
    })
}

#[tauri::command]
pub fn chat_db_insert_message(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    input: ChatMessageInsertInput,
) -> Result<ChatMessageDto, ApiError> {
    let session_uuid = parse_uuid(&input.session_uuid)?;
    let parent = input
        .parent_message_uuid
        .as_deref()
        .map(parse_uuid)
        .transpose()?;
    let sender = normalize_sender(&input.sender)?;
    let text = input.text;

    with_chat_db(&state, &app, &key_b64, move |db| {
        let message = db.insert_message(session_uuid, sender, &text, parent, Vec::new())?;
        Ok(ChatMessageDto::from(message))
    })
}

#[tauri::command]
pub fn chat_db_update_message_text(
    state: State<ChatDbState>,
    app: AppHandle,
    key_b64: String,
    message_uuid: String,
    text: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&message_uuid)?;
    with_chat_db(&state, &app, &key_b64, move |db| {
        db.update_message_text(uuid, &text)?;
        Ok(())
    })
}

#[derive(Serialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
enum LlmEvent {
    Text {
        job_id: llm::JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done { summary: llm::GenerateSummary },
    Error {
        job_id: llm::JobId,
        message: String,
    },
}

impl From<llm::GenerateEvent> for LlmEvent {
    fn from(value: llm::GenerateEvent) -> Self {
        match value {
            llm::GenerateEvent::Text {
                job_id,
                text,
                token_id,
            } => Self::Text {
                job_id,
                text,
                token_id,
            },
            llm::GenerateEvent::Done { summary } => Self::Done { summary },
            llm::GenerateEvent::Error { job_id, message } => Self::Error {
                job_id,
                message,
            },
        }
    }
}

struct LlmEventSink {
    window: Window,
}

impl llm::EventSink for LlmEventSink {
    fn add(&mut self, event: llm::GenerateEvent) {
        let payload = LlmEvent::from(event);
        let _ = self.window.emit("llm-event", payload);
    }
}

#[tauri::command]
pub fn llm_init_backend() -> Result<(), ApiError> {
    llm::init_backend().map_err(llm_error)
}

#[tauri::command]
pub fn llm_load_model(
    state: State<LlmState>,
    params: llm::ModelLoadParams,
) -> Result<(), ApiError> {
    let model = llm::load_model(params).map_err(llm_error)?;
    let mut model_guard = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?;
    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;

    *model_guard = Some(model);
    *context_guard = None;

    Ok(())
}

#[tauri::command]
pub fn llm_create_context(
    state: State<LlmState>,
    params: llm::ContextParams,
) -> Result<(), ApiError> {
    let model = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_loaded", "Model not loaded"))?;

    let context = llm::create_context(model, params).map_err(llm_error)?;

    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    *context_guard = Some(context);

    Ok(())
}

#[tauri::command]
pub fn llm_free_context(state: State<LlmState>) -> Result<(), ApiError> {
    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    *context_guard = None;
    Ok(())
}

#[tauri::command]
pub fn llm_free_model(state: State<LlmState>) -> Result<(), ApiError> {
    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    let mut model_guard = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?;

    *context_guard = None;
    *model_guard = None;
    Ok(())
}

#[tauri::command]
pub fn llm_generate_chat_stream(
    state: State<LlmState>,
    window: Window,
    request: llm::GenerateChatRequest,
) -> Result<(), ApiError> {
    let context = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_ready", "Model context not loaded"))?;

    async_runtime::spawn_blocking(move || {
        let mut sink = LlmEventSink { window };
        let _ = llm::generate_chat_stream(context.as_ref(), request, &mut sink);
    });

    Ok(())
}

#[tauri::command]
pub fn llm_cancel(job_id: i64) -> Result<(), ApiError> {
    llm::cancel(job_id).map_err(llm_error)
}

fn normalize_sender(sender: &str) -> Result<&'static str, ApiError> {
    match sender {
        "self" => Ok("self"),
        "assistant" | "other" => Ok("other"),
        _ => Err(ApiError::new(
            "db_invalid_sender",
            format!("Unsupported sender: {sender}"),
        )),
    }
}

fn parse_uuid(value: &str) -> Result<Uuid, ApiError> {
    Uuid::parse_str(value).map_err(|err| ApiError::new("uuid", err.to_string()))
}

fn chat_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    let resolver = app.path_resolver();
    let dir = resolver
        .app_data_dir()
        .ok_or_else(|| ApiError::new("path", "App data directory unavailable"))?;
    std::fs::create_dir_all(&dir)
        .map_err(|err| ApiError::new("io", err.to_string()))?;
    Ok(dir.join("ensu_llmchat.db"))
}

fn with_chat_db<T>(
    state: &ChatDbState,
    app: &AppHandle,
    key_b64: &str,
    f: impl FnOnce(&ChatDb<SqliteBackend>) -> Result<T, DbError>,
) -> Result<T, ApiError> {
    let mut guard = state
        .inner
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock chat DB state"))?;

    let needs_open = guard
        .as_ref()
        .map(|holder| holder.key_b64 != key_b64)
        .unwrap_or(true);

    if needs_open {
        let key = core_crypto::decode_b64(key_b64).map_err(ApiError::from)?;
        let path = chat_db_path(app)?;
        let db = ChatDb::open_sqlite_with_defaults(path, key).map_err(ApiError::from)?;
        *guard = Some(ChatDbHolder {
            key_b64: key_b64.to_string(),
            db,
        });
    }

    let db = guard
        .as_ref()
        .ok_or_else(|| ApiError::new("db", "Chat DB not initialized"))?;
    f(&db.db).map_err(ApiError::from)
}
