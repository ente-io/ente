use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

use ente_core::crypto;
use ente_ensu::db::{self, Db, Error as DbError, SqliteBackend};
use serde::{Deserialize, Serialize};
use tauri::async_runtime;
use tauri::{AppHandle, Manager, State};
use uuid::Uuid;

use crate::commands::common::{ApiError, app_data_dir};
use crate::logging;

#[derive(Default)]
pub struct ChatDbState {
    inner: Arc<Mutex<Option<ChatDbHolder>>>,
}

struct ChatDbHolder {
    key_b64: String,
    db: Arc<Db<SqliteBackend>>,
}

const CHAT_DB_FILE_NAME_V2: &str = "ensu_llmchat_v2.db";
const LEGACY_CHAT_DB_FILE_NAME: &str = "ensu_llmchat.db";
const ATTACHMENTS_DB_FILE_NAME_V2: &str = "llmchat_sync_v2.db";
const LEGACY_ATTACHMENTS_DB_FILE_NAME: &str = "llmchat_sync.db";
const ATTACHMENTS_DIR_NAME_V2: &str = "ensu_llmchat_attachments_v2";
const LEGACY_ATTACHMENTS_DIR_NAME: &str = "ensu_llmchat_attachments";

fn chat_db_thread_error() -> ApiError {
    ApiError::new("db_thread", "Chat DB task failed")
}

fn image_thread_error() -> ApiError {
    ApiError::new("image_thread", "Image task failed")
}

impl From<DbError> for ApiError {
    fn from(e: DbError) -> Self {
        use db::Error as E;

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
            E::Image(_) => "db_image",
        };

        ApiError::new(code, e.to_string())
    }
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

impl From<db::Session> for ChatSessionDto {
    fn from(session: db::Session) -> Self {
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

impl From<db::SessionWithPreview> for ChatSessionPreviewDto {
    fn from(session: db::SessionWithPreview) -> Self {
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

impl From<db::Attachment> for ChatAttachmentDto {
    fn from(attachment: db::Attachment) -> Self {
        let kind = match attachment.kind {
            db::AttachmentKind::Image => "image",
            db::AttachmentKind::Document => "document",
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

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatDbMigrateLegacyInput {
    key_b64: String,
    legacy_key_b64: String,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ChatDbMigrateLegacyResult {
    did_migrate: bool,
    migrated_sessions: i64,
    migrated_messages: i64,
    migrated_attachments: i64,
}

impl TryFrom<ChatAttachmentInput> for db::Attachment {
    type Error = ApiError;

    fn try_from(value: ChatAttachmentInput) -> Result<Self, Self::Error> {
        let kind = match value.kind.as_str() {
            "image" => db::AttachmentKind::Image,
            "document" => db::AttachmentKind::Document,
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
    db: &Db<SqliteBackend>,
    message: db::Message,
) -> Result<ChatMessageDto, DbError> {
    let uploads = db.get_uploads_for_message(message.uuid)?;
    let mut uploads_by_id = HashMap::new();
    for upload in uploads {
        uploads_by_id.insert(upload.attachment_id, upload.uploaded_at);
    }

    let sender = match message.sender {
        db::Sender::SelfUser => "self",
        db::Sender::Other => "assistant",
    };

    let attachments = message
        .attachments
        .into_iter()
        .map(|meta| {
            let uploaded_at = uploads_by_id.get(&meta.id).and_then(|value| *value);
            db::Attachment {
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

impl From<db::Message> for ChatMessageDto {
    fn from(message: db::Message) -> Self {
        let sender = match message.sender {
            db::Sender::SelfUser => "self",
            db::Sender::Other => "assistant",
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
                .map(db::Attachment::from)
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
        .map(db::Attachment::try_from)
        .collect::<Result<Vec<_>, ApiError>>()?;

    with_chat_db_async(&state, app, key_b64, move |db| {
        let attachment_metas: Vec<db::AttachmentMeta> =
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
        .map(db::Attachment::try_from)
        .collect::<Result<Vec<_>, ApiError>>()?;

    with_chat_db_async(&state, app, key_b64, move |db| {
        let attachment_metas = attachments
            .iter()
            .cloned()
            .map(db::AttachmentMeta::from)
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
        let attachments_db_path = attachments_db_path(&app)?;
        let attachments_db_wal_path =
            PathBuf::from(format!("{}-wal", attachments_db_path.display()));
        let attachments_db_shm_path =
            PathBuf::from(format!("{}-shm", attachments_db_path.display()));

        for candidate in [
            path,
            wal_path,
            shm_path,
            attachments_db_path,
            attachments_db_wal_path,
            attachments_db_shm_path,
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

#[tauri::command]
pub async fn chat_db_compress_attachment_image_file(path: String) -> Result<Vec<u8>, ApiError> {
    async_runtime::spawn_blocking(move || {
        let data = fs::read(&path).map_err(|err| {
            ApiError::new("io", format!("failed to read image file '{path}': {err}"))
        })?;
        db::compress_attachment_image(&data).map_err(|err| ApiError::new("image", err.to_string()))
    })
    .await
    .map_err(|_| image_thread_error())?
}

fn chat_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(CHAT_DB_FILE_NAME_V2))
}

fn attachments_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(ATTACHMENTS_DB_FILE_NAME_V2))
}

fn attachments_dir_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    let dir = app_data_dir(app)?;
    let attachments_dir = dir.join(ATTACHMENTS_DIR_NAME_V2);
    std::fs::create_dir_all(&attachments_dir)
        .map_err(|err| ApiError::new("io", err.to_string()))?;
    Ok(attachments_dir)
}

fn legacy_chat_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(LEGACY_CHAT_DB_FILE_NAME))
}

fn legacy_attachments_db_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(LEGACY_ATTACHMENTS_DB_FILE_NAME))
}

fn legacy_attachments_dir_path(app: &AppHandle) -> Result<PathBuf, ApiError> {
    Ok(app_data_dir(app)?.join(LEGACY_ATTACHMENTS_DIR_NAME))
}

fn cleanup_legacy_chat_artifacts(app: &AppHandle) -> Result<(), ApiError> {
    let legacy_db_path = legacy_chat_db_path(app)?;
    let legacy_attachments_db_path = legacy_attachments_db_path(app)?;
    let legacy_attachments_dir = legacy_attachments_dir_path(app)?;

    for candidate in [
        legacy_db_path.clone(),
        PathBuf::from(format!("{}-wal", legacy_db_path.display())),
        PathBuf::from(format!("{}-shm", legacy_db_path.display())),
        legacy_attachments_db_path.clone(),
        PathBuf::from(format!("{}-wal", legacy_attachments_db_path.display())),
        PathBuf::from(format!("{}-shm", legacy_attachments_db_path.display())),
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
    target_db: &Db<SqliteBackend>,
    source_session_ids: &[Uuid],
    source_message_ids_by_session: &HashMap<Uuid, Vec<Uuid>>,
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

    let legacy_attachments_db_path = legacy_attachments_db_path(app)?;
    let legacy_attachments_dir = legacy_attachments_dir_path(app)?;
    let target_db_path = chat_db_path(app)?;
    let target_attachments_db_path = attachments_db_path(app)?;
    let target_attachments_dir = attachments_dir_path(app)?;

    let legacy_key = crypto::decode_b64(&input.legacy_key_b64).map_err(ApiError::from)?;
    let key = crypto::decode_b64(&input.key_b64).map_err(ApiError::from)?;

    let legacy_db =
        Db::open_sqlite_with_defaults(&legacy_db_path, &legacy_attachments_db_path, legacy_key)
            .map_err(ApiError::from)?;
    let target_db =
        Db::open_sqlite_with_defaults(&target_db_path, &target_attachments_db_path, key)
            .map_err(ApiError::from)?;

    let mut migrated_sessions = 0_i64;
    let mut migrated_messages = 0_i64;
    let mut migrated_attachments = 0_i64;
    let mut source_session_ids = Vec::new();
    let mut source_message_ids_by_session = HashMap::new();
    let mut expected_attachment_ids = Vec::new();
    let legacy_sessions = legacy_db.list_all_sessions().map_err(ApiError::from)?;

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
                    db::Attachment {
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
        &target_attachments_dir,
        &expected_attachment_ids,
    )?;

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
    F: FnOnce(&Db<SqliteBackend>) -> Result<T, DbError>,
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
            let key = crypto::decode_b64(key_b64).map_err(ApiError::from)?;
            let path = chat_db_path(app)?;
            let attachments_db_path = attachments_db_path(app)?;
            logging::log(
                "ChatDb",
                format!(
                    "opening chat DB db={} attachments={}",
                    path.display(),
                    attachments_db_path.display()
                ),
            );
            let db =
                Db::open_sqlite_with_defaults(path, attachments_db_path, key).map_err(|err| {
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
    F: FnOnce(&Db<SqliteBackend>) -> Result<T, DbError> + Send + 'static,
{
    let inner = state.inner.clone();
    async_runtime::spawn_blocking(move || with_chat_db(&inner, &app, &key_b64, f))
        .await
        .map_err(|_| chat_db_thread_error())?
}

pub(crate) fn clear_for_exit(app: &AppHandle) {
    if let Some(chat_db_state) = app.try_state::<ChatDbState>() {
        match chat_db_state.inner.lock() {
            Ok(mut guard) => {
                *guard = None;
                logging::log("App", "cleared chat DB state");
            }
            Err(_) => logging::log("App", "failed to lock chat DB state during exit"),
        }
    } else {
        logging::log("App", "chat DB state unavailable during exit");
    }
}
