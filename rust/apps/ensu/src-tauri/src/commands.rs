use std::collections::HashMap;
use std::fs;
use std::io::{Read, Write};
use std::panic::{AssertUnwindSafe, catch_unwind};
use std::path::{Path, PathBuf};
#[cfg(target_os = "macos")]
use std::process::Command;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

use ensu_db::backend::sqlite::SqliteBackend;
use ensu_db::{EnsuDb, Error as DbError, SyncStateDb};
use ensu_sync as chat_sync;
use ente_core::{auth as core_auth, crypto as core_crypto};
use inference_rs as llm;
use serde::{Deserialize, Serialize};
use tauri::async_runtime;
use tauri::{AppHandle, State, Window};
use uuid::Uuid;

use crate::logging;

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
    inner: Arc<Mutex<Option<ChatDbHolder>>>,
}

struct ChatDbHolder {
    key_b64: String,
    db: Arc<EnsuDb<SqliteBackend>>,
}

const SECURE_STORAGE_SERVICE: &str = "io.ente.ensu";
const CHAT_DB_FILE_NAME_V2: &str = "ensu_llmchat_v2.db";
const LEGACY_CHAT_DB_FILE_NAME: &str = "ensu_llmchat.db";
const SYNC_DB_FILE_NAME_V2: &str = "llmchat_sync_v2.db";
const LEGACY_SYNC_DB_FILE_NAME: &str = "llmchat_sync.db";
const ATTACHMENTS_DIR_NAME_V2: &str = "ensu_llmchat_attachments_v2";
const LEGACY_ATTACHMENTS_DIR_NAME: &str = "ensu_llmchat_attachments";
const SYNC_CURSOR_META_KEY: &str = "llmchat.sync.cursor";
const SYNC_CHAT_KEY_META_KEY: &str = "llmchat.chat.key";
const SYNC_OFFLINE_SEED_META_KEY: &str = "llmchat.offline.seeded.v1";

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

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SystemInfo {
    platform: String,
    total_memory_bytes: Option<u64>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TauriEnsuModelPreset {
    id: String,
    title: String,
    url: String,
    mmproj_url: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TauriEnsuDefaults {
    mobile_system_prompt_body: String,
    desktop_system_prompt_body: String,
    system_prompt_date_placeholder: String,
    session_summary_system_prompt: String,
    mobile_default_model: TauriEnsuModelPreset,
    mobile_model_presets: Vec<TauriEnsuModelPreset>,
    desktop_default_model: TauriEnsuModelPreset,
    desktop_model_presets: Vec<TauriEnsuModelPreset>,
}

impl From<llm::EnsuModelPreset> for TauriEnsuModelPreset {
    fn from(p: llm::EnsuModelPreset) -> Self {
        Self {
            id: p.id,
            title: p.title,
            url: p.url,
            mmproj_url: p.mmproj_url,
        }
    }
}

impl From<llm::EnsuDefaults> for TauriEnsuDefaults {
    fn from(d: llm::EnsuDefaults) -> Self {
        Self {
            mobile_system_prompt_body: d.mobile_system_prompt_body,
            desktop_system_prompt_body: d.desktop_system_prompt_body,
            system_prompt_date_placeholder: d.system_prompt_date_placeholder,
            session_summary_system_prompt: d.session_summary_system_prompt,
            mobile_default_model: d.mobile_default_model.into(),
            mobile_model_presets: d.mobile_model_presets.into_iter().map(Into::into).collect(),
            desktop_default_model: d.desktop_default_model.into(),
            desktop_model_presets: d
                .desktop_model_presets
                .into_iter()
                .map(Into::into)
                .collect(),
        }
    }
}

fn llm_error(message: impl Into<String>) -> ApiError {
    ApiError::new("llm", message)
}

fn llm_thread_error() -> ApiError {
    ApiError::new("llm", "LLM task failed")
}

fn chat_db_thread_error() -> ApiError {
    ApiError::new("db_thread", "Chat DB task failed")
}

fn fs_thread_error() -> ApiError {
    ApiError::new("io_thread", "FS task failed")
}

fn panic_message(payload: Box<dyn std::any::Any + Send>) -> String {
    match payload.downcast::<String>() {
        Ok(message) => *message,
        Err(payload) => match payload.downcast::<&'static str>() {
            Ok(message) => (*message).to_string(),
            Err(_) => "non-string panic payload".to_string(),
        },
    }
}

fn log_command_panic(command: &str, message: &str) {
    logging::log("Panic", format!("command={command} panic={message}"));
}

fn secure_storage_entry(key: &str) -> Result<keyring::Entry, ApiError> {
    keyring::Entry::new(SECURE_STORAGE_SERVICE, key)
        .map_err(|err| ApiError::new("secure_storage", err.to_string()))
}

fn default_llm_threads() -> i32 {
    let available = std::thread::available_parallelism()
        .map(|count| count.get())
        .unwrap_or(2);
    let half = available / 2;
    let threads = if half == 0 { 1 } else { half };
    i32::try_from(threads).unwrap_or(1)
}

#[cfg(target_os = "macos")]
fn macos_total_memory_bytes() -> Option<u64> {
    for candidate in ["/usr/sbin/sysctl", "/sbin/sysctl", "sysctl"] {
        let output = match Command::new(candidate).args(["-n", "hw.memsize"]).output() {
            Ok(output) => output,
            Err(_) => continue,
        };

        if !output.status.success() {
            continue;
        }

        if let Ok(text) = String::from_utf8(output.stdout) {
            if let Ok(bytes) = text.trim().parse::<u64>() {
                return Some(bytes);
            }
        }
    }

    None
}

#[cfg(not(target_os = "macos"))]
fn macos_total_memory_bytes() -> Option<u64> {
    None
}

impl From<core_auth::AuthError> for ApiError {
    fn from(e: core_auth::AuthError) -> Self {
        use core_auth::AuthError as E;

        let code = match &e {
            E::IncorrectPassword => "incorrect_password",
            E::IncorrectRecoveryKey => "incorrect_recovery_key",
            E::InvalidKeyAttributes => "invalid_key_attributes",
            E::InsufficientMemory => "insufficient_memory",
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
        use ensu_db::Error as E;

        let code = match &e {
            E::InvalidKeyLength { .. } => "db_invalid_key_length",
            E::InvalidBlobLength { .. } => "db_invalid_blob_length",
            E::InvalidEncryptedField => "db_invalid_encrypted_field",
            E::UnsupportedValueType(_) => "db_unsupported_value_type",
            E::Row(_) => "db_row",
            E::InvalidSender(_) => "db_invalid_sender",
            E::NotFound { .. } => "db_not_found",
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

fn map_sync_error(err: chat_sync::SyncError) -> ApiError {
    match err {
        chat_sync::SyncError::LimitReached { code, message } => {
            let message = message.unwrap_or_else(|| "Sync limit reached".to_string());
            ApiError::new(&code, message)
        }
        chat_sync::SyncError::Unauthorized => ApiError::new("unauthorized", err.to_string()),
        chat_sync::SyncError::NotLoggedIn => ApiError::new("not_logged_in", err.to_string()),
        other => ApiError::new("sync", other.to_string()),
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

impl From<ensu_db::Session> for ChatSessionDto {
    fn from(session: ensu_db::Session) -> Self {
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
pub struct ChatSessionPreviewDto {
    session_uuid: String,
    title: String,
    created_at: i64,
    updated_at: i64,
    remote_id: Option<String>,
    needs_sync: bool,
    deleted_at: Option<i64>,
    last_message_preview: Option<String>,
}

impl From<ensu_db::SessionWithPreview> for ChatSessionPreviewDto {
    fn from(session: ensu_db::SessionWithPreview) -> Self {
        Self {
            session_uuid: session.uuid.to_string(),
            title: session.title,
            created_at: session.created_at,
            updated_at: session.updated_at,
            remote_id: session.remote_id,
            needs_sync: session.needs_sync,
            deleted_at: session.deleted_at,
            last_message_preview: session.last_message_preview,
        }
    }
}

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ChatAttachmentDto {
    id: String,
    kind: String,
    size: i64,
    name: String,
    uploaded_at: Option<i64>,
}

impl From<ensu_db::Attachment> for ChatAttachmentDto {
    fn from(attachment: ensu_db::Attachment) -> Self {
        let kind = match attachment.kind {
            ensu_db::AttachmentKind::Image => "image",
            ensu_db::AttachmentKind::Document => "document",
        };

        Self {
            id: attachment.id,
            kind: kind.to_string(),
            size: attachment.size,
            name: attachment.name,
            uploaded_at: attachment.uploaded_at,
        }
    }
}

#[derive(Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ChatAttachmentInput {
    id: String,
    kind: String,
    size: i64,
    name: String,
    uploaded_at: Option<i64>,
}

#[derive(Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct ChatSyncInput {
    key_b64: String,
    base_url: String,
    auth_token: String,
    master_key_b64: String,
    user_agent: Option<String>,
    client_package: Option<String>,
    client_version: Option<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatDbMigrateLegacyInput {
    key_b64: String,
    legacy_key_b64: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatSyncStatsDto {
    sessions: i64,
    messages: i64,
}

impl From<chat_sync::SyncStats> for ChatSyncStatsDto {
    fn from(stats: chat_sync::SyncStats) -> Self {
        Self {
            sessions: stats.sessions,
            messages: stats.messages,
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatSyncResultDto {
    pulled: ChatSyncStatsDto,
    pushed: ChatSyncStatsDto,
    uploaded_attachments: i64,
    downloaded_attachments: i64,
}

impl From<chat_sync::SyncResult> for ChatSyncResultDto {
    fn from(result: chat_sync::SyncResult) -> Self {
        Self {
            pulled: result.pulled.into(),
            pushed: result.pushed.into(),
            uploaded_attachments: result.uploaded_attachments,
            downloaded_attachments: result.downloaded_attachments,
        }
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatDbMigrateLegacyResult {
    did_migrate: bool,
    migrated_sessions: i64,
    migrated_messages: i64,
    migrated_attachments: i64,
}

impl TryFrom<ChatAttachmentInput> for ensu_db::Attachment {
    type Error = ApiError;

    fn try_from(value: ChatAttachmentInput) -> Result<Self, Self::Error> {
        let kind = match value.kind.as_str() {
            "image" => ensu_db::AttachmentKind::Image,
            "document" => ensu_db::AttachmentKind::Document,
            other => {
                return Err(ApiError::new(
                    "db_invalid_attachment_kind",
                    format!("Unsupported attachment kind: {other}"),
                ));
            }
        };

        Ok(Self {
            id: value.id,
            kind,
            size: value.size,
            name: value.name,
            uploaded_at: value.uploaded_at,
        })
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
    attachments: Vec<ChatAttachmentDto>,
    deleted_at: Option<i64>,
}

fn build_message_dto(
    db: &EnsuDb<SqliteBackend>,
    message: ensu_db::Message,
) -> Result<ChatMessageDto, DbError> {
    let uploads = db.get_uploads_for_message(message.uuid)?;
    let mut uploads_by_id = HashMap::new();
    for upload in uploads {
        uploads_by_id.insert(upload.attachment_id, upload.uploaded_at);
    }

    let sender = match message.sender {
        ensu_db::Sender::SelfUser => "self",
        ensu_db::Sender::Other => "assistant",
    };

    let attachments = message
        .attachments
        .into_iter()
        .map(|meta| {
            let uploaded_at = uploads_by_id.get(&meta.id).and_then(|value| *value);
            ensu_db::Attachment {
                id: meta.id,
                kind: meta.kind,
                size: meta.size,
                name: meta.name,
                uploaded_at,
            }
        })
        .map(ChatAttachmentDto::from)
        .collect();

    Ok(ChatMessageDto {
        message_uuid: message.uuid.to_string(),
        session_uuid: message.session_uuid.to_string(),
        parent_message_uuid: message.parent_message_uuid.map(|value| value.to_string()),
        sender: sender.to_string(),
        text: message.text,
        created_at: message.created_at,
        attachments,
        deleted_at: message.deleted_at,
    })
}

impl From<ensu_db::Message> for ChatMessageDto {
    fn from(message: ensu_db::Message) -> Self {
        let sender = match message.sender {
            ensu_db::Sender::SelfUser => "self",
            ensu_db::Sender::Other => "assistant",
        };

        Self {
            message_uuid: message.uuid.to_string(),
            session_uuid: message.session_uuid.to_string(),
            parent_message_uuid: message.parent_message_uuid.map(|value| value.to_string()),
            sender: sender.to_string(),
            text: message.text,
            created_at: message.created_at,
            attachments: message
                .attachments
                .into_iter()
                .map(ensu_db::Attachment::from)
                .map(ChatAttachmentDto::from)
                .collect(),
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
    attachments: Option<Vec<ChatAttachmentInput>>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatSessionUpsertInput {
    session_uuid: String,
    title: String,
    created_at: i64,
    updated_at: i64,
    remote_id: Option<String>,
    needs_sync: bool,
    deleted_at: Option<i64>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatMessageUpsertInput {
    message_uuid: String,
    session_uuid: String,
    parent_message_uuid: Option<String>,
    sender: String,
    text: String,
    created_at: i64,
    remote_id: Option<String>,
    deleted_at: Option<i64>,
    attachments: Option<Vec<ChatAttachmentInput>>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatDeletionDto {
    entity_type: String,
    uuid: String,
}

#[tauri::command]
pub async fn chat_db_list_sessions(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
) -> Result<Vec<ChatSessionDto>, ApiError> {
    with_chat_db_async(&state, app, key_b64, |db| {
        Ok(db
            .list_sessions()?
            .into_iter()
            .map(ChatSessionDto::from)
            .collect())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_list_sessions_with_preview(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
) -> Result<Vec<ChatSessionPreviewDto>, ApiError> {
    with_chat_db_async(&state, app, key_b64, |db| {
        Ok(db
            .list_sessions_with_preview()?
            .into_iter()
            .map(ChatSessionPreviewDto::from)
            .collect())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_get_session(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
) -> Result<Option<ChatSessionDto>, ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        Ok(db.get_session(uuid)?.map(ChatSessionDto::from))
    })
    .await
}

#[tauri::command]
pub async fn chat_db_get_message(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    message_uuid: String,
) -> Result<Option<ChatMessageDto>, ApiError> {
    let uuid = parse_uuid(&message_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        let message = db.get_message(uuid)?;
        message
            .map(|message| build_message_dto(db, message))
            .transpose()
    })
    .await
}

#[tauri::command]
pub async fn chat_db_create_session(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    title: String,
) -> Result<ChatSessionDto, ApiError> {
    with_chat_db_async(&state, app, key_b64, move |db| {
        let session = db.create_session(&title)?;
        Ok(ChatSessionDto::from(session))
    })
    .await
}

#[tauri::command]
pub async fn chat_db_update_session_title(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
    title: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.update_session_title(uuid, &title)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_delete_session(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.delete_session(uuid)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_get_messages(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
) -> Result<Vec<ChatMessageDto>, ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        let messages = db.get_messages(uuid)?;
        messages
            .into_iter()
            .map(|message| build_message_dto(db, message))
            .collect()
    })
    .await
}

#[tauri::command]
pub async fn chat_db_get_messages_for_sync(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
    include_deleted: bool,
) -> Result<Vec<ChatMessageDto>, ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        let messages = if include_deleted {
            db.get_messages_for_sync(uuid, true)?
        } else {
            db.get_messages_needing_sync(uuid)?
        };
        messages
            .into_iter()
            .map(|message| build_message_dto(db, message))
            .collect()
    })
    .await
}

#[tauri::command]
pub async fn chat_db_insert_message(
    state: State<'_, ChatDbState>,
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
    let attachments = input
        .attachments
        .unwrap_or_default()
        .into_iter()
        .map(ensu_db::Attachment::try_from)
        .collect::<Result<Vec<_>, ApiError>>()?;

    with_chat_db_async(&state, app, key_b64, move |db| {
        let attachment_metas: Vec<ensu_db::AttachmentMeta> =
            attachments.into_iter().map(Into::into).collect();
        let message = db.insert_message(session_uuid, sender, &text, parent, attachment_metas)?;
        build_message_dto(db, message)
    })
    .await
}

#[tauri::command]
pub async fn chat_db_update_message_text(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    message_uuid: String,
    text: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&message_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.update_message_text(uuid, &text)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_list_sessions_for_sync(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
) -> Result<Vec<ChatSessionDto>, ApiError> {
    with_chat_db_async(&state, app, key_b64, |db| {
        Ok(db
            .get_sessions_needing_sync()?
            .into_iter()
            .map(ChatSessionDto::from)
            .collect())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_upsert_session(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    input: ChatSessionUpsertInput,
) -> Result<ChatSessionDto, ApiError> {
    let uuid = parse_uuid(&input.session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        let session = db.upsert_session(
            uuid,
            &input.title,
            input.created_at,
            input.updated_at,
            input.remote_id.clone(),
            input.needs_sync,
            input.deleted_at,
        )?;
        Ok(ChatSessionDto::from(session))
    })
    .await
}

#[tauri::command]
pub async fn chat_db_insert_message_with_uuid(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    input: ChatMessageUpsertInput,
) -> Result<ChatMessageDto, ApiError> {
    let message_uuid = parse_uuid(&input.message_uuid)?;
    let session_uuid = parse_uuid(&input.session_uuid)?;
    let parent = input
        .parent_message_uuid
        .as_deref()
        .map(parse_uuid)
        .transpose()?;
    let sender = normalize_sender(&input.sender)?;
    let attachments = input
        .attachments
        .unwrap_or_default()
        .into_iter()
        .map(ensu_db::Attachment::try_from)
        .collect::<Result<Vec<_>, ApiError>>()?;

    with_chat_db_async(&state, app, key_b64, move |db| {
        let attachment_metas = attachments
            .iter()
            .cloned()
            .map(ensu_db::AttachmentMeta::from)
            .collect::<Vec<_>>();
        let message = if let Some(remote_id) = input.remote_id.as_deref() {
            let message = db.upsert_message_from_remote(
                message_uuid,
                session_uuid,
                remote_id,
                sender,
                &input.text,
                parent,
                attachment_metas,
                input.created_at,
            )?;
            if let Some(deleted_at) = input.deleted_at {
                db.apply_message_tombstone(message_uuid, deleted_at)?;
            }
            message
        } else {
            db.insert_message_with_uuid(
                message_uuid,
                session_uuid,
                sender,
                &input.text,
                parent,
                attachments,
                input.created_at,
                input.deleted_at,
            )?
        };
        build_message_dto(db, message)
    })
    .await
}

#[tauri::command]
pub async fn chat_db_mark_session_synced(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
    remote_id: String,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.mark_session_synced(uuid, &remote_id)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_mark_session_deleted(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    session_uuid: String,
    deleted_at: i64,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&session_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.apply_session_tombstone(uuid, deleted_at)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_mark_message_deleted(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    message_uuid: String,
    deleted_at: i64,
) -> Result<(), ApiError> {
    let uuid = parse_uuid(&message_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.apply_message_tombstone(uuid, deleted_at)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_mark_attachment_uploaded(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    message_uuid: String,
    attachment_id: String,
) -> Result<(), ApiError> {
    let _ = parse_uuid(&message_uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.mark_attachment_uploaded(&attachment_id)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_get_pending_deletions(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
) -> Result<Vec<ChatDeletionDto>, ApiError> {
    with_chat_db_async(&state, app, key_b64, move |db| {
        let deletions = db.get_pending_deletions()?;
        Ok(deletions
            .into_iter()
            .map(|(entity, uuid)| ChatDeletionDto {
                entity_type: match entity {
                    ensu_db::EntityType::Session => "session".to_string(),
                    ensu_db::EntityType::Message => "message".to_string(),
                },
                uuid: uuid.to_string(),
            })
            .collect())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_hard_delete(
    state: State<'_, ChatDbState>,
    app: AppHandle,
    key_b64: String,
    entity_type: String,
    uuid: String,
) -> Result<(), ApiError> {
    let entity_type = parse_entity_type(&entity_type)?;
    let uuid = parse_uuid(&uuid)?;
    with_chat_db_async(&state, app, key_b64, move |db| {
        db.hard_delete(entity_type, uuid)?;
        Ok(())
    })
    .await
}

#[tauri::command]
pub async fn chat_db_reset(state: State<'_, ChatDbState>, app: AppHandle) -> Result<(), ApiError> {
    let inner = state.inner.clone();
    async_runtime::spawn_blocking(move || {
        {
            let mut guard = inner
                .lock()
                .map_err(|_| ApiError::new("lock", "Failed to lock chat DB state"))?;
            *guard = None;
        }

        let path = chat_db_path(&app)?;
        let wal_path = PathBuf::from(format!("{}-wal", path.display()));
        let shm_path = PathBuf::from(format!("{}-shm", path.display()));
        let sync_path = sync_db_path(&app)?;
        let sync_wal_path = PathBuf::from(format!("{}-wal", sync_path.display()));
        let sync_shm_path = PathBuf::from(format!("{}-shm", sync_path.display()));

        for candidate in [
            path,
            wal_path,
            shm_path,
            sync_path,
            sync_wal_path,
            sync_shm_path,
        ] {
            if candidate.exists() {
                fs::remove_file(&candidate).map_err(|err| ApiError::new("io", err.to_string()))?;
            }
        }

        Ok(())
    })
    .await
    .map_err(|_| chat_db_thread_error())?
}

#[tauri::command]
pub async fn chat_db_migrate_legacy(
    app: AppHandle,
    input: ChatDbMigrateLegacyInput,
) -> Result<ChatDbMigrateLegacyResult, ApiError> {
    async_runtime::spawn_blocking(move || migrate_legacy_chat_db(&app, &input))
        .await
        .map_err(|_| chat_db_thread_error())?
}

#[tauri::command]
pub async fn chat_sync(
    app: AppHandle,
    input: ChatSyncInput,
) -> Result<ChatSyncResultDto, ApiError> {
    async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| {
            logging::log(
                "Sync",
                format!(
                    "chat_sync start base_url={} has_user_agent={} has_client_package={} has_client_version={}",
                    input.base_url,
                    input.user_agent.is_some(),
                    input.client_package.is_some(),
                    input.client_version.is_some()
                ),
            );
            let key = core_crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;
            let master_key =
                core_crypto::decode_b64(&input.master_key_b64).map_err(ApiError::from)?;

            let db_path = chat_db_path(&app)?;
            let sync_path = sync_db_path(&app)?;
            let attachments_dir = attachments_dir_path(&app)?;
            let meta_dir = sync_meta_dir_path(&app)?;

            logging::log(
                "Sync",
                format!(
                    "chat_sync paths db={} sync={} attachments_dir={} meta_dir={}",
                    db_path.display(),
                    sync_path.display(),
                    attachments_dir.display(),
                    meta_dir.display()
                ),
            );

            let engine = chat_sync::SyncEngine::new(
                db_path.to_string_lossy().to_string(),
                sync_path.to_string_lossy().to_string(),
                key,
                attachments_dir.to_string_lossy().to_string(),
                meta_dir.to_string_lossy().to_string(),
                None,
            )
            .map_err(|err| {
                logging::log("Sync", format!("failed to create sync engine error={err}"));
                ApiError::new("sync", err.to_string())
            })?;

            let auth = chat_sync::SyncAuth {
                base_url: input.base_url,
                auth_token: input.auth_token,
                master_key: master_key.into(),
                user_agent: input.user_agent,
                client_package: input.client_package,
                client_version: input.client_version,
            };

            let result = engine.sync(auth).map_err(|err| {
                logging::log("Sync", format!("sync failed error={err}"));
                map_sync_error(err)
            })?;
            logging::log(
                "Sync",
                format!(
                    "chat_sync success pulled_sessions={} pulled_messages={} pushed_sessions={} pushed_messages={} uploaded_attachments={} downloaded_attachments={}",
                    result.pulled.sessions,
                    result.pulled.messages,
                    result.pushed.sessions,
                    result.pushed.messages,
                    result.uploaded_attachments,
                    result.downloaded_attachments
                ),
            );
            Ok(ChatSyncResultDto::from(result))
        })) {
            Ok(result) => result,
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("chat_sync", &message);
                Err(ApiError::new("sync_panic", format!("chat_sync panicked: {message}")))
            }
        }
    })
    .await
    .map_err(|err| {
        logging::log("Sync", format!("sync task join failed error={err}"));
        ApiError::new("sync", "Sync task failed")
    })?
}

#[derive(Serialize, Clone)]
#[serde(tag = "type", rename_all = "snake_case")]
enum LlmEvent {
    Text {
        job_id: llm::JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done {
        summary: llm::GenerateSummary,
    },
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
            llm::GenerateEvent::Error { job_id, message } => Self::Error { job_id, message },
        }
    }
}

const LLM_EVENT_BATCH_MS: u64 = 80;
const LLM_EVENT_BATCH_BYTES: usize = 2048;

struct LlmEventSink {
    window: Window,
    buffered_text: String,
    buffered_job_id: Option<llm::JobId>,
    buffered_token_id: Option<i32>,
    last_emit: Instant,
}

impl LlmEventSink {
    fn new(window: Window) -> Self {
        Self {
            window,
            buffered_text: String::new(),
            buffered_job_id: None,
            buffered_token_id: None,
            last_emit: Instant::now(),
        }
    }

    fn flush_text(&mut self) {
        if self.buffered_text.is_empty() {
            self.buffered_job_id = None;
            self.buffered_token_id = None;
            self.last_emit = Instant::now();
            return;
        }

        if let Some(job_id) = self.buffered_job_id.take() {
            let payload = LlmEvent::Text {
                job_id,
                text: std::mem::take(&mut self.buffered_text),
                token_id: self.buffered_token_id.take(),
            };
            let _ = self.window.emit("llm-event", payload);
        } else {
            self.buffered_text.clear();
            self.buffered_token_id = None;
        }

        self.last_emit = Instant::now();
    }
}

impl llm::EventSink for LlmEventSink {
    fn add(&mut self, event: llm::GenerateEvent) {
        match event {
            llm::GenerateEvent::Text {
                job_id,
                text,
                token_id,
            } => {
                if let Some(current) = self.buffered_job_id {
                    if current != job_id {
                        self.flush_text();
                    }
                }

                if self.buffered_text.is_empty() {
                    self.last_emit = Instant::now();
                }

                self.buffered_job_id = Some(job_id);
                self.buffered_token_id = token_id;
                self.buffered_text.push_str(&text);

                let elapsed = self.last_emit.elapsed();
                if self.buffered_text.len() >= LLM_EVENT_BATCH_BYTES
                    || elapsed >= Duration::from_millis(LLM_EVENT_BATCH_MS)
                {
                    self.flush_text();
                }
            }
            llm::GenerateEvent::Done { summary } => {
                self.flush_text();
                let _ = self.window.emit("llm-event", LlmEvent::Done { summary });
            }
            llm::GenerateEvent::Error { job_id, message } => {
                self.flush_text();
                let _ = self
                    .window
                    .emit("llm-event", LlmEvent::Error { job_id, message });
            }
        }
    }
}

#[tauri::command]
pub fn system_info() -> SystemInfo {
    SystemInfo {
        platform: std::env::consts::OS.to_string(),
        total_memory_bytes: macos_total_memory_bytes(),
    }
}

#[tauri::command]
pub fn get_ensu_defaults() -> TauriEnsuDefaults {
    llm::ensu_defaults().into()
}

#[tauri::command]
pub async fn llm_init_backend() -> Result<(), ApiError> {
    logging::log("LLM", "init backend requested");
    async_runtime::spawn_blocking(|| match catch_unwind(AssertUnwindSafe(|| llm::init_backend())) {
        Ok(result) => result.map_err(llm_error),
        Err(payload) => {
            let message = panic_message(payload);
            log_command_panic("llm_init_backend", &message);
            Err(ApiError::new(
                "llm_panic",
                format!("llm_init_backend panicked: {message}"),
            ))
        }
    })
        .await
        .map_err(|err| {
            logging::log("LLM", format!("init backend join failed error={err}"));
            llm_thread_error()
        })??;
    logging::log("LLM", "init backend succeeded");
    Ok(())
}

#[tauri::command]
pub async fn llm_load_model(
    state: State<'_, LlmState>,
    params: llm::ModelLoadParams,
) -> Result<(), ApiError> {
    logging::log("LLM", format!("load model requested model_path={}", params.model_path));
    let model = async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| llm::load_model(params))) {
            Ok(result) => result.map_err(llm_error),
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_load_model", &message);
                Err(ApiError::new(
                    "llm_panic",
                    format!("llm_load_model panicked: {message}"),
                ))
            }
        }
    })
        .await
        .map_err(|err| {
            logging::log("LLM", format!("load model join failed error={err}"));
            llm_thread_error()
        })??;
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

    logging::log("LLM", "load model succeeded");
    Ok(())
}

#[tauri::command]
pub async fn llm_create_context(
    state: State<'_, LlmState>,
    params: llm::ContextParams,
) -> Result<(), ApiError> {
    let model = state
        .model
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM model store"))?
        .clone()
        .ok_or_else(|| ApiError::new("llm_not_loaded", "Model not loaded"))?;

    let mut params = params;
    if params.n_threads.is_none() {
        params.n_threads = Some(default_llm_threads());
    }
    logging::log(
        "LLM",
        format!(
            "create context requested context_size={:?} n_threads={:?} n_batch={:?}",
            params.context_size, params.n_threads, params.n_batch
        ),
    );

    let context = async_runtime::spawn_blocking(move || {
        match catch_unwind(AssertUnwindSafe(|| llm::create_context(model, params))) {
            Ok(result) => result.map_err(llm_error),
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_create_context", &message);
                Err(ApiError::new(
                    "llm_panic",
                    format!("llm_create_context panicked: {message}"),
                ))
            }
        }
    })
    .await
    .map_err(|err| {
        logging::log("LLM", format!("create context join failed error={err}"));
        llm_thread_error()
    })??;

    let mut context_guard = state
        .context
        .lock()
        .map_err(|_| ApiError::new("lock", "Failed to lock LLM context store"))?;
    *context_guard = Some(context);

    logging::log("LLM", "create context succeeded");
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
        match catch_unwind(AssertUnwindSafe(|| {
            let mut sink = LlmEventSink::new(window);
            let _ = llm::generate_chat_stream(context.as_ref(), request, &mut sink);
        })) {
            Ok(()) => {}
            Err(payload) => {
                let message = panic_message(payload);
                log_command_panic("llm_generate_chat_stream", &message);
            }
        }
    });

    Ok(())
}

#[tauri::command]
pub fn llm_cancel(job_id: i64) -> Result<(), ApiError> {
    llm::cancel(job_id).map_err(llm_error)
}

#[tauri::command]
pub async fn fs_file_size(path: String) -> Result<Option<u64>, ApiError> {
    async_runtime::spawn_blocking(move || match fs::metadata(&path) {
        Ok(metadata) => Ok(Some(metadata.len())),
        Err(err) if err.kind() == std::io::ErrorKind::NotFound => Ok(None),
        Err(err) => Err(ApiError::new("io", err.to_string())),
    })
    .await
    .map_err(|_| fs_thread_error())?
}

#[tauri::command]
pub async fn fs_read_head(path: String, length: usize) -> Result<Vec<u8>, ApiError> {
    async_runtime::spawn_blocking(move || {
        if length == 0 {
            return Ok(Vec::new());
        }
        let mut file = fs::File::open(&path).map_err(|err| ApiError::new("io", err.to_string()))?;
        let mut buffer = vec![0u8; length];
        let bytes_read = file
            .read(&mut buffer)
            .map_err(|err| ApiError::new("io", err.to_string()))?;
        buffer.truncate(bytes_read);
        Ok(buffer)
    })
    .await
    .map_err(|_| fs_thread_error())?
}

#[tauri::command]
pub async fn fs_append_bytes(path: String, bytes: Vec<u8>) -> Result<(), ApiError> {
    async_runtime::spawn_blocking(move || {
        if bytes.is_empty() {
            return Ok(());
        }
        let mut file = fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&path)
            .map_err(|err| ApiError::new("io", err.to_string()))?;
        file.write_all(&bytes)
            .map_err(|err| ApiError::new("io", err.to_string()))?;
        Ok(())
    })
    .await
    .map_err(|_| fs_thread_error())?
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

fn parse_entity_type(value: &str) -> Result<ensu_db::EntityType, ApiError> {
    match value {
        "session" => Ok(ensu_db::EntityType::Session),
        "message" => Ok(ensu_db::EntityType::Message),
        other => Err(ApiError::new(
            "db_invalid_entity_type",
            format!("Unsupported entity type: {other}"),
        )),
    }
}

fn parse_uuid(value: &str) -> Result<Uuid, ApiError> {
    Uuid::parse_str(value).map_err(|err| ApiError::new("uuid", err.to_string()))
}

#[tauri::command]
pub fn secure_storage_get(key: String) -> Result<Option<String>, ApiError> {
    let entry = secure_storage_entry(&key)?;
    match entry.get_password() {
        Ok(value) => Ok(Some(value)),
        Err(keyring::Error::NoEntry) => Ok(None),
        Err(err) => Err(ApiError::new("secure_storage", err.to_string())),
    }
}

#[tauri::command]
pub fn secure_storage_set(key: String, value: String) -> Result<(), ApiError> {
    let entry = secure_storage_entry(&key)?;
    entry
        .set_password(&value)
        .map_err(|err| ApiError::new("secure_storage", err.to_string()))
}

#[tauri::command]
pub fn secure_storage_delete(key: String) -> Result<(), ApiError> {
    let entry = secure_storage_entry(&key)?;
    match entry.delete_credential() {
        Ok(()) | Err(keyring::Error::NoEntry) => Ok(()),
        Err(err) => Err(ApiError::new("secure_storage", err.to_string())),
    }
}

fn app_data_dir(app: &AppHandle) -> Result<PathBuf, ApiError> {
    let resolver = app.path_resolver();
    let dir = resolver
        .app_data_dir()
        .ok_or_else(|| ApiError::new("path", "App data directory unavailable"))?;
    std::fs::create_dir_all(&dir).map_err(|err| ApiError::new("io", err.to_string()))?;
    Ok(dir)
}

fn chat_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(CHAT_DB_FILE_NAME_V2))
}

fn sync_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(SYNC_DB_FILE_NAME_V2))
}

fn attachments_dir_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    let dir = app_data_dir(app)?;
    let attachments_dir = dir.join(ATTACHMENTS_DIR_NAME_V2);
    std::fs::create_dir_all(&attachments_dir)
        .map_err(|err| ApiError::new("io", err.to_string()))?;
    Ok(attachments_dir)
}

fn sync_meta_dir_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    let dir = app_data_dir(app)?;
    let meta_dir = dir.join("sync_meta");
    std::fs::create_dir_all(&meta_dir).map_err(|err| ApiError::new("io", err.to_string()))?;
    Ok(meta_dir)
}

fn legacy_chat_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(LEGACY_CHAT_DB_FILE_NAME))
}

fn legacy_sync_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(LEGACY_SYNC_DB_FILE_NAME))
}

fn legacy_attachments_dir_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(LEGACY_ATTACHMENTS_DIR_NAME))
}

fn cleanup_legacy_chat_artifacts(app: &AppHandle) -> Result<(), ApiError> {
    let legacy_db_path = legacy_chat_db_path(app)?;
    let legacy_sync_path = legacy_sync_db_path(app)?;
    let legacy_attachments_dir = legacy_attachments_dir_path(app)?;

    for candidate in [
        legacy_db_path.clone(),
        PathBuf::from(format!("{}-wal", legacy_db_path.display())),
        PathBuf::from(format!("{}-shm", legacy_db_path.display())),
        legacy_sync_path.clone(),
        PathBuf::from(format!("{}-wal", legacy_sync_path.display())),
        PathBuf::from(format!("{}-shm", legacy_sync_path.display())),
    ] {
        if candidate.exists() {
            fs::remove_file(&candidate).map_err(|err| ApiError::new("io", err.to_string()))?;
        }
    }

    if legacy_attachments_dir.exists() {
        fs::remove_dir_all(&legacy_attachments_dir)
            .map_err(|err| ApiError::new("io", err.to_string()))?;
    }

    Ok(())
}

fn verify_migrated_chat_db(
    target_db: &EnsuDb<SqliteBackend>,
    source_session_ids: &[Uuid],
    source_message_ids_by_session: &HashMap<Uuid, Vec<Uuid>>,
    migrated_meta_keys: &[&str],
    target_sync_state: &SyncStateDb<SqliteBackend>,
    target_attachments_dir: &Path,
    expected_attachment_ids: &[String],
) -> Result<(), ApiError> {
    let target_session_ids = target_db
        .list_all_sessions()
        .map_err(ApiError::from)?
        .into_iter()
        .map(|session| session.uuid)
        .collect::<std::collections::HashSet<_>>();

    for session_uuid in source_session_ids {
        if !target_session_ids.contains(session_uuid) {
            return Err(ApiError::new(
                "db_migration_verification",
                format!("Missing migrated session {session_uuid}"),
            ));
        }
    }

    for (session_uuid, message_ids) in source_message_ids_by_session {
        let target_message_ids = target_db
            .get_messages_for_sync(*session_uuid, true)
            .map_err(ApiError::from)?
            .into_iter()
            .map(|message| message.uuid)
            .collect::<std::collections::HashSet<_>>();

        for message_uuid in message_ids {
            if !target_message_ids.contains(message_uuid) {
                return Err(ApiError::new(
                    "db_migration_verification",
                    format!("Missing migrated message {message_uuid}"),
                ));
            }
        }
    }

    for meta_key in migrated_meta_keys {
        if target_sync_state
            .get_meta(meta_key)
            .map_err(ApiError::from)?
            .is_none()
        {
            return Err(ApiError::new(
                "db_migration_verification",
                format!("Missing migrated sync meta key {meta_key}"),
            ));
        }
    }

    for attachment_id in expected_attachment_ids {
        let target_path = target_attachments_dir.join(attachment_id);
        if !target_path.exists() {
            return Err(ApiError::new(
                "db_migration_verification",
                format!("Missing migrated attachment {attachment_id}"),
            ));
        }
    }

    Ok(())
}

fn migrate_legacy_chat_db(
    app: &AppHandle,
    input: &ChatDbMigrateLegacyInput,
) -> Result<ChatDbMigrateLegacyResult, ApiError> {
    let legacy_db_path = legacy_chat_db_path(app)?;
    if !legacy_db_path.exists() {
        return Ok(ChatDbMigrateLegacyResult {
            did_migrate: false,
            migrated_sessions: 0,
            migrated_messages: 0,
            migrated_attachments: 0,
        });
    }

    let legacy_sync_path = legacy_sync_db_path(app)?;
    let legacy_attachments_dir = legacy_attachments_dir_path(app)?;
    let target_db_path = chat_db_path(app)?;
    let target_sync_path = sync_db_path(app)?;
    let target_attachments_dir = attachments_dir_path(app)?;

    let legacy_key = core_crypto::decode_b64(&input.legacy_key_b64).map_err(ApiError::from)?;
    let key = core_crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;

    let legacy_db =
        EnsuDb::open_sqlite_with_defaults(&legacy_db_path, &legacy_sync_path, legacy_key)
            .map_err(ApiError::from)?;
    let target_db = EnsuDb::open_sqlite_with_defaults(&target_db_path, &target_sync_path, key)
        .map_err(ApiError::from)?;
    let legacy_sync_state =
        SyncStateDb::open_sqlite_with_defaults(&legacy_sync_path).map_err(ApiError::from)?;
    let target_sync_state =
        SyncStateDb::open_sqlite_with_defaults(&target_sync_path).map_err(ApiError::from)?;

    let mut migrated_sessions = 0_i64;
    let mut migrated_messages = 0_i64;
    let mut migrated_attachments = 0_i64;
    let mut migrated_meta_keys = Vec::new();
    let mut source_session_ids = Vec::new();
    let mut source_message_ids_by_session = HashMap::new();
    let mut expected_attachment_ids = Vec::new();
    let legacy_sessions = legacy_db.list_all_sessions().map_err(ApiError::from)?;

    for meta_key in [
        SYNC_CURSOR_META_KEY,
        SYNC_CHAT_KEY_META_KEY,
        SYNC_OFFLINE_SEED_META_KEY,
    ] {
        if let Some(value) = legacy_sync_state
            .get_meta(meta_key)
            .map_err(ApiError::from)?
        {
            target_sync_state
                .set_meta(meta_key, &value)
                .map_err(ApiError::from)?;
            migrated_meta_keys.push(meta_key);
        }
    }

    for session in legacy_sessions {
        source_session_ids.push(session.uuid);
        target_db
            .upsert_session(
                session.uuid,
                &session.title,
                session.created_at,
                session.updated_at,
                session.remote_id.clone(),
                session.needs_sync,
                session.deleted_at,
            )
            .map_err(ApiError::from)?;
        if let Some(state) = legacy_sync_state
            .get_session_state(session.uuid)
            .map_err(ApiError::from)?
        {
            target_sync_state
                .set_session_state(
                    session.uuid,
                    state.remote_id.as_deref(),
                    state.server_updated_at,
                )
                .map_err(ApiError::from)?;
        }
        migrated_sessions += 1;

        for message in legacy_db
            .get_messages_for_sync(session.uuid, true)
            .map_err(ApiError::from)?
        {
            source_message_ids_by_session
                .entry(session.uuid)
                .or_insert_with(Vec::new)
                .push(message.uuid);
            let uploads = legacy_db
                .get_uploads_for_message(message.uuid)
                .map_err(ApiError::from)?;
            let uploaded_at_by_id = uploads
                .into_iter()
                .map(|upload| (upload.attachment_id, upload.uploaded_at))
                .collect::<HashMap<_, _>>();
            let attachments = message
                .attachments
                .iter()
                .cloned()
                .map(|attachment| {
                    let uploaded_at = uploaded_at_by_id
                        .get(&attachment.id)
                        .and_then(|value| *value);
                    ensu_db::Attachment {
                        id: attachment.id,
                        kind: attachment.kind,
                        size: attachment.size,
                        name: attachment.name,
                        uploaded_at,
                    }
                })
                .collect::<Vec<_>>();

            target_db
                .insert_message_with_uuid_and_state(
                    message.uuid,
                    message.session_uuid,
                    message.sender.as_str(),
                    &message.text,
                    message.parent_message_uuid,
                    attachments.clone(),
                    message.created_at,
                    message.deleted_at,
                    message.needs_sync,
                )
                .map_err(ApiError::from)?;

            if let Some(remote_id) = message.remote_id.as_deref() {
                target_db
                    .set_message_remote_id(message.uuid, remote_id)
                    .map_err(ApiError::from)?;
            }
            if let Some(state) = legacy_sync_state
                .get_message_state(message.uuid)
                .map_err(ApiError::from)?
            {
                target_sync_state
                    .set_message_state(
                        message.uuid,
                        state.remote_id.as_deref(),
                        state.server_updated_at,
                    )
                    .map_err(ApiError::from)?;
            }

            for attachment in attachments {
                if let Some(remote_id) = legacy_db
                    .get_attachment_remote_id(&attachment.id)
                    .map_err(ApiError::from)?
                {
                    target_db
                        .set_attachment_remote_id(&attachment.id, Some(&remote_id))
                        .map_err(ApiError::from)?;
                }

                if let Some(state) = legacy_db
                    .get_attachment_upload_state(&attachment.id)
                    .map_err(ApiError::from)?
                {
                    target_db
                        .set_attachment_upload_state(&attachment.id, state)
                        .map_err(ApiError::from)?;
                }

                let source_path = legacy_attachments_dir.join(&attachment.id);
                let target_path = target_attachments_dir.join(&attachment.id);
                if source_path.exists() && !target_path.exists() {
                    fs::copy(&source_path, &target_path)
                        .map_err(|err| ApiError::new("io", err.to_string()))?;
                    migrated_attachments += 1;
                }
                if source_path.exists() {
                    expected_attachment_ids.push(attachment.id.clone());
                }
            }

            migrated_messages += 1;
        }
    }

    verify_migrated_chat_db(
        &target_db,
        &source_session_ids,
        &source_message_ids_by_session,
        &migrated_meta_keys,
        &target_sync_state,
        &target_attachments_dir,
        &expected_attachment_ids,
    )?;

    drop(legacy_sync_state);
    drop(legacy_db);

    cleanup_legacy_chat_artifacts(app)?;

    Ok(ChatDbMigrateLegacyResult {
        did_migrate: true,
        migrated_sessions,
        migrated_messages,
        migrated_attachments,
    })
}

fn with_chat_db<T, F>(
    inner: &Arc<Mutex<Option<ChatDbHolder>>>,
    app: &AppHandle,
    key_b64: &str,
    f: F,
) -> Result<T, ApiError>
where
    F: FnOnce(&EnsuDb<SqliteBackend>) -> Result<T, DbError>,
{
    let db = {
        let mut guard = inner
            .lock()
            .map_err(|_| ApiError::new("lock", "Failed to lock chat DB state"))?;

        let needs_open = guard
            .as_ref()
            .map(|holder| holder.key_b64 != key_b64)
            .unwrap_or(true);

        if needs_open {
            let key = core_crypto::decode_b64(key_b64).map_err(ApiError::from)?;
            let path = chat_db_path(app)?;
            let sync_path = sync_db_path(app)?;
            logging::log(
                "ChatDb",
                format!(
                    "opening chat DB db={} sync={}",
                    path.display(),
                    sync_path.display()
                ),
            );
            let db =
                EnsuDb::open_sqlite_with_defaults(path, sync_path, key).map_err(|err| {
                    logging::log("ChatDb", format!("failed to open chat DB error={err}"));
                    ApiError::from(err)
                })?;
            *guard = Some(ChatDbHolder {
                key_b64: key_b64.to_string(),
                db: Arc::new(db),
            });
            logging::log("ChatDb", "chat DB opened");
        }

        guard
            .as_ref()
            .ok_or_else(|| ApiError::new("db", "Chat DB not initialized"))?
            .db
            .clone()
    };

    f(db.as_ref()).map_err(ApiError::from)
}

async fn with_chat_db_async<T, F>(
    state: &ChatDbState,
    app: AppHandle,
    key_b64: String,
    f: F,
) -> Result<T, ApiError>
where
    T: Send + 'static,
    F: FnOnce(&EnsuDb<SqliteBackend>) -> Result<T, DbError> + Send + 'static,
{
    let inner = state.inner.clone();
    async_runtime::spawn_blocking(move || with_chat_db(&inner, &app, &key_b64, f))
        .await
        .map_err(|_| chat_db_thread_error())?
}
