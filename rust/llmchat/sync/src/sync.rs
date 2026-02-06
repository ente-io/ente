use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

use zeroize::Zeroizing;

use ente_core::crypto::keys;
use llmchat_db::{
    AttachmentKind, AttachmentMeta, AttachmentStore, Clock, EntityType, FsAttachmentStore,
    LlmChatDb, Message, Sender, Session, SqliteBackend, SyncEntityState, SyncStateDb, SystemClock,
    UploadState,
};
use uuid::Uuid;

use crate::conflict::{
    LocalSyncState, find_duplicate_message, order_for_sync, should_accept_remote_message,
    should_accept_remote_session,
};
use crate::crypto::{
    decrypt_chat_key, decrypt_payload, encrypt_attachment_bytes, encrypt_chat_key, encrypt_payload,
};
use crate::diff_cursor::SyncCursor;
use crate::errors::SyncError;
use crate::http::{HttpClient, HttpConfig};
use crate::models::{
    ChatKeyPayload, DiffResponse, MessagePayload, RemoteAttachment, SessionPayload,
    UploadUrlRequest, UploadUrlResponse,
};

const CURSOR_META_KEY: &str = "llmchat.sync.cursor";
const CHAT_KEY_META_KEY: &str = "llmchat.chat.key";
const OFFLINE_SEED_META_KEY: &str = "llmchat.offline.seeded.v1";
const ZERO_UUID: &str = "00000000-0000-0000-0000-000000000000";

static SYNC_LOCK: AtomicBool = AtomicBool::new(false);

#[derive(Debug, Clone)]
pub struct MigrationConfig {
    pub batch_size: i64,
    pub priority: MigrationPriority,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MigrationPriority {
    RecentFirst,
    OldestFirst,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MigrationState {
    NotNeeded,
    InProgress,
    Complete,
    Failed,
}

#[derive(Debug, Clone)]
pub struct MigrationProgress {
    pub state: MigrationState,
    pub processed: i64,
    pub remaining: i64,
    pub total: i64,
}

pub trait MigrationProgressCallback: Send + Sync {
    fn on_progress(&self, progress: MigrationProgress);
}

struct SyncLockGuard;

impl Drop for SyncLockGuard {
    fn drop(&mut self) {
        SYNC_LOCK.store(false, Ordering::SeqCst);
    }
}

#[derive(Debug, Clone)]
pub struct SyncAuth {
    pub base_url: String,
    pub auth_token: String,
    pub master_key: Zeroizing<Vec<u8>>,
    pub user_agent: Option<String>,
    pub client_package: Option<String>,
    pub client_version: Option<String>,
}

#[derive(Debug, Default, Clone)]
pub struct SyncStats {
    pub sessions: i64,
    pub messages: i64,
}

#[derive(Debug, Default, Clone)]
pub struct SyncResult {
    pub pulled: SyncStats,
    pub pushed: SyncStats,
    pub uploaded_attachments: i64,
    pub downloaded_attachments: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum ChatKeyStatus {
    Cached,
    Remote,
    Created,
}

pub struct SyncEngine {
    db: LlmChatDb<SqliteBackend>,
    sync_state: SyncStateDb<SqliteBackend>,
    attachment_store: FsAttachmentStore,
    plaintext_dir: Option<PathBuf>,
    diff_limit: i64,
    offline_db: std::sync::Mutex<Option<OfflineDbConfig>>,
}

#[derive(Clone)]
struct OfflineDbConfig {
    path: String,
    key: Vec<u8>,
}

impl SyncEngine {
    pub fn new(
        main_db_path: String,
        sync_db_path: String,
        db_key: Vec<u8>,
        attachments_dir: String,
        _meta_dir: String,
        plaintext_dir: Option<String>,
    ) -> Result<Self, SyncError> {
        llmchat_db::traits::ensure_directory(&attachments_dir)?;
        if let Some(ref dir) = plaintext_dir {
            let _ = llmchat_db::traits::ensure_directory(dir);
        }

        let db = LlmChatDb::open_sqlite_with_defaults(main_db_path, sync_db_path.clone(), db_key)?;
        let sync_state = SyncStateDb::open_sqlite_with_defaults(sync_db_path)?;
        let attachment_store = FsAttachmentStore::new(attachments_dir);
        Ok(Self {
            db,
            sync_state,
            attachment_store,
            plaintext_dir: plaintext_dir.map(PathBuf::from),
            diff_limit: 500,
            offline_db: std::sync::Mutex::new(None),
        })
    }

    pub fn sync(&self, auth: SyncAuth) -> Result<SyncResult, SyncError> {
        if SYNC_LOCK
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            return Err(SyncError::SyncInProgress);
        }
        let _guard = SyncLockGuard;

        if auth.auth_token.trim().is_empty() {
            return Err(SyncError::NotLoggedIn);
        }
        if auth.master_key.len() != llmchat_db::crypto::KEY_BYTES {
            return Err(SyncError::Crypto("invalid master key length".to_string()));
        }

        let SyncAuth {
            base_url,
            auth_token,
            master_key,
            user_agent,
            client_package,
            client_version,
        } = auth;

        let http = HttpClient::new(HttpConfig {
            base_url,
            auth_token,
            user_agent,
            client_package,
            client_version,
            timeout_secs: None,
        })?;

        let (chat_key, key_status) = self.get_or_create_chat_key(&http, &master_key)?;
        let mut result = SyncResult::default();

        if key_status == ChatKeyStatus::Created {
            self.prepare_for_new_chat_key()?;
        } else {
            self.pull(&http, &chat_key, &mut result)?;
        }
        self.push(&http, &chat_key, &mut result)?;

        Ok(result)
    }

    pub fn sync_with_progress(
        &self,
        auth: SyncAuth,
        config: MigrationConfig,
        callback: &dyn MigrationProgressCallback,
    ) -> Result<SyncResult, SyncError> {
        if SYNC_LOCK
            .compare_exchange(false, true, Ordering::SeqCst, Ordering::SeqCst)
            .is_err()
        {
            return Err(SyncError::SyncInProgress);
        }
        let _guard = SyncLockGuard;

        if auth.auth_token.trim().is_empty() {
            return Err(SyncError::NotLoggedIn);
        }
        if auth.master_key.len() != llmchat_db::crypto::KEY_BYTES {
            return Err(SyncError::Crypto("invalid master key length".to_string()));
        }

        let SyncAuth {
            base_url,
            auth_token,
            master_key,
            user_agent,
            client_package,
            client_version,
        } = auth;

        let http = HttpClient::new(HttpConfig {
            base_url,
            auth_token,
            user_agent,
            client_package,
            client_version,
            timeout_secs: None,
        })?;

        let (chat_key, key_status) = self.get_or_create_chat_key(&http, &master_key)?;
        let mut result = SyncResult::default();

        if key_status == ChatKeyStatus::Created {
            self.prepare_for_new_chat_key()?;
        } else {
            self.pull(&http, &chat_key, &mut result)?;
        }

        let total = self.db.count_needing_sync()?;
        let mut processed = 0;
        callback.on_progress(MigrationProgress {
            state: MigrationState::InProgress,
            processed,
            remaining: total,
            total,
        });

        let batch_size = if config.batch_size <= 0 {
            1
        } else {
            config.batch_size
        };
        let order_desc = matches!(config.priority, MigrationPriority::RecentFirst);

        let sync_result = (|| -> Result<(), SyncError> {
            loop {
                let batch = self
                    .db
                    .get_sessions_needing_sync_batch(batch_size, order_desc)?;
                if batch.is_empty() {
                    break;
                }

                for session in batch {
                    self.push_session_with_messages(&http, &chat_key, &session, &mut result)?;
                    processed += 1;
                    let remaining = total.saturating_sub(processed);
                    callback.on_progress(MigrationProgress {
                        state: MigrationState::InProgress,
                        processed,
                        remaining,
                        total,
                    });
                }
            }
            Ok(())
        })();

        if let Err(err) = sync_result {
            let remaining = total.saturating_sub(processed);
            callback.on_progress(MigrationProgress {
                state: MigrationState::Failed,
                processed,
                remaining,
                total,
            });
            return Err(err);
        }

        callback.on_progress(MigrationProgress {
            state: MigrationState::Complete,
            processed,
            remaining: 0,
            total,
        });

        Ok(result)
    }

    pub fn sync_in_background(
        self: Arc<Self>,
        auth: SyncAuth,
    ) -> std::thread::JoinHandle<Result<SyncResult, SyncError>> {
        std::thread::spawn(move || self.sync(auth))
    }

    pub fn check_migration_status_local(&self) -> Result<Option<MigrationState>, SyncError> {
        let pending = self.db.count_needing_sync()?;
        if pending > 0 {
            return Ok(Some(MigrationState::InProgress));
        }
        Ok(None)
    }

    pub fn reset_sync_state(&self) -> Result<(), SyncError> {
        let _ = self.sync_state.delete_meta(CURSOR_META_KEY);
        let _ = self.sync_state.delete_meta(CHAT_KEY_META_KEY);
        let _ = self.sync_state.delete_meta(OFFLINE_SEED_META_KEY);
        let _ = self.sync_state.clear_state();
        let _ = self.sync_state.clear_meta();
        self.db.reset_attachment_sync_state()?;
        let _ = self.attachment_store.clear_all();
        if let Ok(mut offline) = self.offline_db.lock() {
            *offline = None;
        }
        Ok(())
    }

    pub fn seed_from_offline(
        &self,
        offline_db_path: String,
        offline_db_key: Vec<u8>,
    ) -> Result<(), SyncError> {
        if let Ok(mut offline) = self.offline_db.lock() {
            *offline = Some(OfflineDbConfig {
                path: offline_db_path.clone(),
                key: offline_db_key.clone(),
            });
        }
        if self.sync_state.get_meta(OFFLINE_SEED_META_KEY)?.is_some() {
            return Ok(());
        }

        let offline_db = llmchat_db::ChatDb::open_sqlite_with_defaults(
            offline_db_path.clone(),
            offline_db_key.clone(),
        )?;
        let sessions = offline_db.list_sessions()?;

        for session in sessions {
            let _ = self.db.upsert_session(
                session.uuid,
                &session.title,
                session.created_at,
                session.updated_at,
                None,
                true,
                session.deleted_at,
            )?;
            let messages = offline_db.get_messages(session.uuid)?;
            for message in messages {
                let _ = self.db.insert_message_with_uuid_and_state(
                    message.uuid,
                    session.uuid,
                    message.sender.as_str(),
                    &message.text,
                    message.parent_message_uuid,
                    message.attachments.clone(),
                    message.created_at,
                    message.deleted_at,
                    true,
                )?;
            }
        }

        self.sync_state.set_meta(OFFLINE_SEED_META_KEY, b"1")?;
        Ok(())
    }

    pub fn check_migration_status(&self, auth: SyncAuth) -> Result<MigrationState, SyncError> {
        if let Some(local) = self.check_migration_status_local()? {
            return Ok(local);
        }
        if auth.auth_token.trim().is_empty() {
            return Err(SyncError::NotLoggedIn);
        }
        if auth.master_key.len() != llmchat_db::crypto::KEY_BYTES {
            return Err(SyncError::Crypto("invalid master key length".to_string()));
        }

        let SyncAuth {
            base_url,
            auth_token,
            master_key,
            user_agent,
            client_package,
            client_version,
        } = auth;

        let http = HttpClient::new(HttpConfig {
            base_url,
            auth_token,
            user_agent,
            client_package,
            client_version,
            timeout_secs: None,
        })?;

        if self.load_chat_key_from_meta(&master_key)?.is_some() {
            return Ok(MigrationState::NotNeeded);
        }

        let remote = http.get_json_optional::<ChatKeyPayload>("/llmchat/chat/key", &[]);
        match remote {
            Ok(Some(_)) => Ok(MigrationState::InProgress),
            Ok(None) => Ok(MigrationState::InProgress),
            Err(SyncError::Http {
                status: 404,
                code: Some(code),
                ..
            }) if code == "NOT_FOUND" || code == "AuthKeyNotCreated" => {
                Ok(MigrationState::InProgress)
            }
            Err(err) => Err(err),
        }
    }

    fn prepare_for_new_chat_key(&self) -> Result<(), SyncError> {
        self.reset_cursor_to_now()?;
        let _ = self.sync_state.clear_state();
        self.db.mark_all_needs_sync()?;
        self.db.clear_all_server_timestamps()?;
        self.db.reset_attachment_sync_state()?;
        self.attachment_store.clear_all()?;
        Ok(())
    }

    fn reset_cursor_to_now(&self) -> Result<(), SyncError> {
        let clock = SystemClock;
        let now = clock.now_us();
        let cursor = SyncCursor {
            base_since_time: now,
            since_time: now,
            max_time: now,
            since_type: "sessions".to_string(),
            since_id: "00000000-0000-0000-0000-000000000000".to_string(),
        };
        self.save_cursor(&cursor)?;
        Ok(())
    }

    pub fn download_attachment(
        &self,
        auth: SyncAuth,
        attachment_id: String,
        session_uuid: String,
    ) -> Result<bool, SyncError> {
        if auth.auth_token.trim().is_empty() {
            return Err(SyncError::NotLoggedIn);
        }
        if auth.master_key.len() != llmchat_db::crypto::KEY_BYTES {
            return Err(SyncError::Crypto("invalid master key length".to_string()));
        }

        let session_uuid = Uuid::parse_str(&session_uuid)
            .map_err(|_| SyncError::InvalidResponse("invalid session uuid".to_string()))?;

        let plaintext_dir = self
            .plaintext_dir
            .as_ref()
            .ok_or_else(|| SyncError::AttachmentMissing(attachment_id.clone()))?;
        let plaintext_path = plaintext_dir.join(&attachment_id);
        if plaintext_path.exists() {
            return Ok(false);
        }

        let SyncAuth {
            base_url,
            auth_token,
            master_key,
            user_agent,
            client_package,
            client_version,
        } = auth;

        let base_url = base_url.trim_end_matches('/').to_string();
        let http = HttpClient::new(HttpConfig {
            base_url: base_url.clone(),
            auth_token,
            user_agent,
            client_package,
            client_version,
            timeout_secs: None,
        })?;

        let (chat_key, _) = self.get_or_create_chat_key(&http, &master_key)?;
        let encrypted = if self.attachment_store.exists(&attachment_id)? {
            self.attachment_store.read(&attachment_id)?
        } else {
            let mut remote_id = match self.db.get_attachment_remote_id(&attachment_id)? {
                Some(remote_id) => remote_id,
                None => {
                    let fallback = attachment_id.clone();
                    self.db
                        .set_attachment_remote_id(&attachment_id, Some(&fallback))?;
                    fallback
                }
            };
            let mut url = format!("{}/llmchat/chat/attachment/{}", base_url, remote_id);
            let bytes = match http.get_bytes(&url) {
                Ok(bytes) => bytes,
                Err(SyncError::Http { status: 404, .. }) => {
                    if let Err(err) =
                        self.force_upload_attachment(&http, &chat_key, session_uuid, &attachment_id)
                    {
                        return Err(err);
                    }
                    if let Some(updated) = self.db.get_attachment_remote_id(&attachment_id)? {
                        remote_id = updated;
                        url = format!("{}/llmchat/chat/attachment/{}", base_url, remote_id);
                    }
                    http.get_bytes(&url)?
                }
                Err(err) => return Err(err),
            };
            self.attachment_store.write(&attachment_id, &bytes)?;
            bytes
        };

        let plaintext =
            crate::crypto::decrypt_attachment_bytes(&encrypted, &chat_key, session_uuid)?;
        std::fs::write(plaintext_path, plaintext)?;
        Ok(true)
    }

    pub fn download_attachment_in_background(
        self: Arc<Self>,
        auth: SyncAuth,
        attachment_id: String,
        session_uuid: String,
    ) -> std::thread::JoinHandle<Result<bool, SyncError>> {
        std::thread::spawn(move || self.download_attachment(auth, attachment_id, session_uuid))
    }

    fn pull(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        result: &mut SyncResult,
    ) -> Result<(), SyncError> {
        let mut cursor = self.load_cursor()?;
        let mut seen_cursors: HashSet<SyncCursor> = HashSet::new();

        loop {
            let query = vec![
                ("sinceTime", cursor.since_time.to_string()),
                ("sinceType", cursor.since_type.clone()),
                ("sinceId", cursor.since_id.clone()),
                ("limit", self.diff_limit.to_string()),
            ];
            let response: DiffResponse = http.get_json("/llmchat/chat/diff", &query)?;

            self.apply_diff(&response, chat_key, result)?;

            let next_cursor = match response.cursor.clone() {
                Some(cursor) => cursor,
                None => {
                    if let Some(timestamp) = response.timestamp {
                        SyncCursor {
                            base_since_time: timestamp,
                            since_time: timestamp,
                            max_time: timestamp,
                            since_type: "sessions".to_string(),
                            since_id: "00000000-0000-0000-0000-000000000000".to_string(),
                        }
                    } else {
                        cursor.clone()
                    }
                }
            };

            if !seen_cursors.insert(next_cursor.clone()) {
                break;
            }

            cursor = next_cursor;
            self.save_cursor(&cursor)?;

            if cursor.is_complete_cycle() {
                break;
            }
        }

        Ok(())
    }

    fn apply_diff(
        &self,
        response: &DiffResponse,
        chat_key: &[u8],
        result: &mut SyncResult,
    ) -> Result<(), SyncError> {
        let mut local_messages_cache: HashMap<Uuid, Vec<Message>> = HashMap::new();
        let mut duplicate_map: HashMap<Uuid, Uuid> = HashMap::new();
        let mut remote_message_updates: HashMap<Uuid, i64> = HashMap::new();
        let mut remote_session_map: HashMap<Uuid, Uuid> = HashMap::new();
        let mut remote_message_map: HashMap<Uuid, Uuid> = HashMap::new();

        for message in &response.messages {
            if message.is_deleted == Some(true) {
                continue;
            }
            let session_uuid = Uuid::parse_str(&message.session_uuid)
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let timestamp = message.updated_at.unwrap_or(message.created_at);
            remote_message_updates
                .entry(session_uuid)
                .and_modify(|current| {
                    if *current < timestamp {
                        *current = timestamp;
                    }
                })
                .or_insert(timestamp);
        }

        for session in &response.sessions {
            if session.is_deleted == Some(true) {
                continue;
            }
            let payload: SessionPayload =
                decrypt_payload(&session.encrypted_data, &session.header, chat_key)?;
            let remote_uuid = Uuid::parse_str(&session.session_uuid)
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let mut local_uuid = session
                .client_metadata
                .as_deref()
                .and_then(decode_client_id)
                .and_then(|value| Uuid::parse_str(&value).ok())
                .unwrap_or(remote_uuid);
            let remote_uuid_str = remote_uuid.to_string();
            let mut local = self.db.get_session(local_uuid).ok().flatten();
            let mut local_state = self.sync_state.get_session_state(local_uuid).ok().flatten();
            if let Some(state) = local_state.as_ref() {
                if let Some(existing_remote) = state.remote_id.as_deref() {
                    if existing_remote != remote_uuid_str.as_str() {
                        local_uuid = remote_uuid;
                        local = self.db.get_session(local_uuid).ok().flatten();
                        local_state = self.sync_state.get_session_state(local_uuid).ok().flatten();
                    }
                }
            }
            remote_session_map.insert(remote_uuid, local_uuid);
            if let Some(local_session) = local.as_ref() {
                let local_sync = LocalSyncState {
                    uuid: local_session.uuid,
                    needs_sync: local_session.needs_sync,
                    server_updated_at: local_state
                        .as_ref()
                        .and_then(|state| state.server_updated_at),
                };
                if !should_accept_remote_session(local_sync, session.updated_at, remote_uuid) {
                    if local_state
                        .as_ref()
                        .and_then(|state| state.remote_id.as_deref())
                        .is_none()
                    {
                        let _ = self
                            .sync_state
                            .set_session_remote_id(local_uuid, Some(&remote_uuid_str));
                    }
                    continue;
                }
            }
            let title_changed = local
                .as_ref()
                .map(|existing| existing.title != payload.title)
                .unwrap_or(true);
            let mut effective_updated_at = local
                .as_ref()
                .map(|existing| existing.updated_at)
                .unwrap_or(session.updated_at);
            if let Some(remote_updated) = remote_message_updates.get(&remote_uuid) {
                if effective_updated_at < *remote_updated {
                    effective_updated_at = *remote_updated;
                }
            }
            if title_changed && effective_updated_at < session.updated_at {
                effective_updated_at = session.updated_at;
            }

            let created_at = session
                .client_metadata
                .as_deref()
                .and_then(|metadata| decode_client_created_at(metadata, chat_key))
                .unwrap_or(session.created_at);

            let _ = self.db.upsert_session_from_remote(
                local_uuid,
                &remote_uuid.to_string(),
                &payload.title,
                created_at,
                effective_updated_at,
            )?;
            self.sync_state.set_session_state(
                local_uuid,
                Some(&remote_uuid_str),
                Some(session.updated_at),
            )?;
            result.pulled.sessions += 1;
        }

        for message in &response.messages {
            if message.is_deleted == Some(true) {
                continue;
            }
            let payload: MessagePayload =
                decrypt_payload(&message.encrypted_data, &message.header, chat_key)?;
            let remote_message_uuid = Uuid::parse_str(&message.message_uuid)
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let remote_session_uuid = Uuid::parse_str(&message.session_uuid)
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let session_uuid = remote_session_map
                .get(&remote_session_uuid)
                .cloned()
                .or_else(|| {
                    self.sync_state
                        .get_session_uuid_by_remote_id(&remote_session_uuid.to_string())
                        .ok()
                        .flatten()
                })
                .unwrap_or(remote_session_uuid);
            let remote_message_uuid_str = remote_message_uuid.to_string();
            let mut message_uuid = message
                .client_metadata
                .as_deref()
                .and_then(decode_client_id)
                .and_then(|value| Uuid::parse_str(&value).ok())
                .unwrap_or(remote_message_uuid);
            let remote_updated_at = message.updated_at.unwrap_or(message.created_at);

            let sender: Sender = message
                .sender
                .parse::<Sender>()
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let (attachments, attachment_remote_ids) =
                self.decrypt_remote_attachments(&message.attachments, chat_key)?;

            let local_messages = local_messages_cache
                .entry(session_uuid)
                .or_insert_with(|| self.db.get_messages(session_uuid).unwrap_or_default());
            let mut local_message = local_messages
                .iter()
                .find(|local| local.uuid == message_uuid);
            let mut local_state = self
                .sync_state
                .get_message_state(message_uuid)
                .ok()
                .flatten();
            if let Some(state) = local_state.as_ref() {
                if let Some(existing_remote) = state.remote_id.as_deref() {
                    if existing_remote != remote_message_uuid_str.as_str() {
                        message_uuid = remote_message_uuid;
                        local_message = local_messages
                            .iter()
                            .find(|local| local.uuid == message_uuid);
                        local_state = self
                            .sync_state
                            .get_message_state(message_uuid)
                            .ok()
                            .flatten();
                    }
                }
            }
            remote_message_map.insert(remote_message_uuid, message_uuid);
            if let Some(local_message) = local_message {
                let local_sync = LocalSyncState {
                    uuid: local_message.uuid,
                    needs_sync: local_message.needs_sync,
                    server_updated_at: local_state
                        .as_ref()
                        .and_then(|state| state.server_updated_at),
                };
                if !should_accept_remote_message(local_sync, remote_updated_at, remote_message_uuid)
                {
                    if local_state
                        .as_ref()
                        .and_then(|state| state.remote_id.as_deref())
                        .is_none()
                    {
                        let _ = self
                            .sync_state
                            .set_message_remote_id(message_uuid, Some(&remote_message_uuid_str));
                    }
                    continue;
                }
            }

            let parent_uuid = message
                .parent_message_uuid
                .as_ref()
                .and_then(|parent| Uuid::parse_str(parent).ok())
                .and_then(|parent| {
                    duplicate_map
                        .get(&parent)
                        .cloned()
                        .or_else(|| remote_message_map.get(&parent).cloned())
                        .or_else(|| {
                            self.sync_state
                                .get_message_uuid_by_remote_id(&parent.to_string())
                                .ok()
                                .flatten()
                        })
                });

            let created_at = message
                .client_metadata
                .as_deref()
                .and_then(|metadata| decode_client_created_at(metadata, chat_key))
                .unwrap_or(message.created_at);

            if let Some(dup_uuid) = find_duplicate_message(
                local_messages,
                &sender,
                &payload.text,
                &attachments,
                created_at,
                parent_uuid,
            ) {
                duplicate_map.insert(remote_message_uuid, dup_uuid);
                remote_message_map.insert(remote_message_uuid, dup_uuid);
                continue;
            }

            let inserted = self.db.upsert_message_from_remote(
                message_uuid,
                session_uuid,
                &remote_message_uuid.to_string(),
                sender.as_str(),
                &payload.text,
                parent_uuid,
                attachments.clone(),
                created_at,
            )?;
            self.sync_state.set_message_state(
                message_uuid,
                Some(&remote_message_uuid_str),
                Some(remote_updated_at),
            )?;

            for attachment in &attachments {
                let remote_id = attachment_remote_ids
                    .get(&attachment.id)
                    .map(String::as_str);
                let _ = self.db.upsert_attachment_with_state(
                    &attachment.id,
                    session_uuid,
                    message_uuid,
                    attachment.size,
                    remote_id,
                    UploadState::Uploaded,
                );
            }

            local_messages.push(inserted);
            result.pulled.messages += 1;
        }

        let clock = SystemClock;
        let now = clock.now_us();
        let offline_db = self.open_offline_db()?;
        for tombstone in &response.tombstones.sessions {
            let remote_uuid = Uuid::parse_str(&tombstone.session_uuid)
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let local_uuid = remote_session_map.get(&remote_uuid).cloned().or_else(|| {
                self.sync_state
                    .get_session_uuid_by_remote_id(&remote_uuid.to_string())
                    .ok()
                    .flatten()
            });
            let Some(local_uuid) = local_uuid else {
                continue;
            };
            let deleted_at = tombstone.deleted_at.or(response.timestamp).unwrap_or(now);
            let local = self.db.get_session(local_uuid).ok().flatten();
            let local_state = self.sync_state.get_session_state(local_uuid).ok().flatten();
            self.apply_session_tombstone(local, local_state, local_uuid, deleted_at)?;
            if let Some(offline_db) = offline_db.as_ref() {
                if offline_db.get_session(local_uuid).ok().flatten().is_some() {
                    let _ = offline_db.apply_session_tombstone(local_uuid, deleted_at);
                }
            }
        }

        for tombstone in &response.tombstones.messages {
            let remote_uuid = Uuid::parse_str(&tombstone.message_uuid)
                .map_err(|e| SyncError::InvalidResponse(e.to_string()))?;
            let local_uuid = remote_message_map.get(&remote_uuid).cloned().or_else(|| {
                self.sync_state
                    .get_message_uuid_by_remote_id(&remote_uuid.to_string())
                    .ok()
                    .flatten()
            });
            let Some(local_uuid) = local_uuid else {
                continue;
            };
            let deleted_at = tombstone.deleted_at.or(response.timestamp).unwrap_or(now);
            let _ = self.db.apply_message_tombstone(local_uuid, deleted_at);
            let _ = self.sync_state.delete_message_state(local_uuid);
            if let Some(offline_db) = offline_db.as_ref() {
                let _ = offline_db.apply_message_tombstone(local_uuid, deleted_at);
            }
        }

        Ok(())
    }

    fn open_offline_db(&self) -> Result<Option<llmchat_db::ChatDb<SqliteBackend>>, SyncError> {
        let config = match self.offline_db.lock() {
            Ok(guard) => guard.clone(),
            Err(_) => None,
        };
        let Some(config) = config else {
            return Ok(None);
        };
        if config.path.trim().is_empty() {
            return Ok(None);
        }
        let db = llmchat_db::ChatDb::open_sqlite_with_defaults(config.path, config.key)?;
        Ok(Some(db))
    }

    fn apply_session_tombstone(
        &self,
        local: Option<Session>,
        local_state: Option<SyncEntityState>,
        session_uuid: Uuid,
        deleted_at: i64,
    ) -> Result<(), SyncError> {
        let Some(local) = local else {
            return Ok(());
        };

        let server_updated_at = local_state.and_then(|state| state.server_updated_at);

        if local.needs_sync && server_updated_at.is_none() {
            self.db.apply_session_tombstone(session_uuid, deleted_at)?;
            let _ = self.sync_state.delete_session_state(session_uuid);
            return Ok(());
        }

        if local.needs_sync && server_updated_at.is_some() {
            if local.updated_at > deleted_at {
                return Ok(());
            }
        }

        self.db.apply_session_tombstone(session_uuid, deleted_at)?;
        let _ = self.sync_state.delete_session_state(session_uuid);
        Ok(())
    }

    fn push(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        result: &mut SyncResult,
    ) -> Result<(), SyncError> {
        let deleted_sessions = self.db.get_deleted_sessions()?;
        for (uuid, _deleted_at) in deleted_sessions {
            if let Some(remote_id) = self.sync_state.get_session_remote_id(uuid)? {
                http.delete("/llmchat/chat/session", &[("id", remote_id)])?;
                let _ = self.sync_state.delete_session_state(uuid);
            }
            let _ = self.db.delete_attachment_tracking_for_session(uuid);
            let _ = self.db.hard_delete(EntityType::Session, uuid);
        }

        let deleted_messages = self.db.get_deleted_messages()?;
        for (uuid, _deleted_at) in deleted_messages {
            if let Some(remote_id) = self.sync_state.get_message_remote_id(uuid)? {
                http.delete("/llmchat/chat/message", &[("id", remote_id)])?;
                let _ = self.sync_state.delete_message_state(uuid);
            }
            let _ = self.db.delete_attachment_tracking_for_message(uuid);
            let _ = self.db.hard_delete(EntityType::Message, uuid);
        }

        let sessions = self.db.list_sessions()?;
        for session in sessions {
            self.push_session_with_messages(http, chat_key, &session, result)?;
        }

        Ok(())
    }

    fn push_session_with_messages(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        session: &Session,
        result: &mut SyncResult,
    ) -> Result<(), SyncError> {
        let session_uuid = session.uuid;
        let messages = self.collect_messages_for_sync(session_uuid)?;
        let session_state = self.sync_state.get_session_state(session_uuid)?;
        let should_upsert_session = session.needs_sync
            || session_state
                .as_ref()
                .and_then(|state| state.remote_id.as_deref())
                .is_none();
        let mut session_remote_id = session_state.and_then(|state| state.remote_id);

        if !messages.is_empty() {
            self.reconcile_attachments(session_uuid, &messages)?;

            let force_uploads =
                self.revalidate_uploaded_attachments(http, session_uuid, &messages)?;
            let uploaded =
                self.upload_pending_attachments(http, chat_key, session_uuid, &force_uploads)?;
            result.uploaded_attachments += uploaded;

            let upload_states = self.collect_attachment_states(&messages)?;
            let blocked = blocked_messages(&messages, &upload_states);

            let ordered = order_for_sync(&messages);
            let filtered: Vec<Message> = ordered
                .into_iter()
                .filter(|message| !blocked.contains(&message.uuid))
                .collect();

            if should_upsert_session {
                session_remote_id = Some(self.push_session(http, chat_key, session)?);
                result.pushed.sessions += 1;
            }

            for message in filtered.iter() {
                self.push_message_with_retry(http, chat_key, message, result)?;
                let _ = self.db.mark_message_synced(message.uuid);
            }

            if blocked.is_empty() && filtered.len() == messages.len() {
                if let Some(remote_id) = session_remote_id.clone().or_else(|| {
                    self.sync_state
                        .get_session_remote_id(session_uuid)
                        .ok()
                        .flatten()
                }) {
                    let _ = self.db.mark_session_synced(session_uuid, &remote_id);
                }
            }
        } else if should_upsert_session {
            session_remote_id = Some(self.push_session(http, chat_key, session)?);
            result.pushed.sessions += 1;
            if let Some(remote_id) = session_remote_id.clone().or_else(|| {
                self.sync_state
                    .get_session_remote_id(session_uuid)
                    .ok()
                    .flatten()
            }) {
                let _ = self.db.mark_session_synced(session_uuid, &remote_id);
            }
        }

        Ok(())
    }

    fn push_session(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        session: &Session,
    ) -> Result<String, SyncError> {
        let session_payload = SessionPayload {
            title: session.title.clone(),
        };
        let encrypted = encrypt_payload(&session_payload, chat_key)?;
        let client_metadata =
            encode_client_metadata(&session.uuid.to_string(), session.created_at, chat_key)?;
        let session_uuid =
            normalize_remote_uuid(self.sync_state.get_session_remote_id(session.uuid)?);
        let session_request = UpsertSessionRequest {
            session_uuid: session_uuid.clone(),
            encrypted_data: encrypted.encrypted_data,
            header: encrypted.header,
            client_metadata: Some(client_metadata),
        };
        let response: UpsertSessionResponse =
            http.post_json("/llmchat/chat/session", &session_request)?;
        let remote_id = response.session_uuid;
        self.sync_state
            .set_session_state(session.uuid, Some(&remote_id), response.updated_at)?;
        Ok(remote_id)
    }

    fn push_message_with_retry(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        message: &Message,
        result: &mut SyncResult,
    ) -> Result<(), SyncError> {
        match self.push_message(http, chat_key, message) {
            Ok(()) => {
                result.pushed.messages += 1;
                Ok(())
            }
            Err(err) => {
                if !self.is_attachment_size_mismatch(&err) {
                    return Err(err);
                }
                self.reset_attachments_for_message(message)?;
                let empty_force = HashSet::new();
                let uploaded = self.upload_pending_attachments(
                    http,
                    chat_key,
                    message.session_uuid,
                    &empty_force,
                )?;
                result.uploaded_attachments += uploaded;
                self.push_message(http, chat_key, message)?;
                result.pushed.messages += 1;
                Ok(())
            }
        }
    }

    fn push_message(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        message: &Message,
    ) -> Result<(), SyncError> {
        let message_payload = MessagePayload {
            text: message.text.clone(),
        };
        let encrypted = encrypt_payload(&message_payload, chat_key)?;
        let attachments = self.encrypt_attachments(
            message.session_uuid,
            message.uuid,
            &message.attachments,
            chat_key,
        )?;

        let session_remote_id = normalize_remote_uuid(
            self.sync_state
                .get_session_remote_id(message.session_uuid)?,
        )
        .ok_or_else(|| SyncError::InvalidResponse("missing session remote id".to_string()))?;
        let message_uuid =
            normalize_remote_uuid(self.sync_state.get_message_remote_id(message.uuid)?);
        let parent_message_uuid = message.parent_message_uuid.and_then(|parent| {
            normalize_remote_uuid(self.sync_state.get_message_remote_id(parent).ok().flatten())
        });
        let client_metadata =
            encode_client_metadata(&message.uuid.to_string(), message.created_at, chat_key)?;
        let message_request = UpsertMessageRequest {
            message_uuid,
            session_uuid: session_remote_id,
            parent_message_uuid,
            sender: message.sender.as_str().to_string(),
            attachments,
            encrypted_data: encrypted.encrypted_data,
            header: encrypted.header,
            client_metadata: Some(client_metadata),
        };
        let response: UpsertMessageResponse =
            http.post_json("/llmchat/chat/message", &message_request)?;
        self.sync_state.set_message_state(
            message.uuid,
            Some(&response.message_uuid),
            response.updated_at,
        )?;
        Ok(())
    }

    fn reset_attachments_for_message(&self, message: &Message) -> Result<(), SyncError> {
        for attachment in &message.attachments {
            let _ = self.attachment_store.delete(&attachment.id);
            let _ = self.db.upsert_pending_attachment(
                &attachment.id,
                message.session_uuid,
                message.uuid,
                attachment.size,
            );
            let _ = self
                .db
                .set_attachment_upload_state(&attachment.id, UploadState::Pending);
            let _ = self.db.set_attachment_remote_id(&attachment.id, None);
        }
        Ok(())
    }

    fn is_attachment_size_mismatch(&self, error: &SyncError) -> bool {
        match error {
            SyncError::Http {
                status: 400,
                message,
                ..
            } => message
                .to_ascii_lowercase()
                .contains("attachment size mismatch"),
            _ => false,
        }
    }

    fn encrypt_attachments(
        &self,
        session_uuid: Uuid,
        message_uuid: Uuid,
        attachments: &[AttachmentMeta],
        chat_key: &[u8],
    ) -> Result<Vec<RemoteAttachment>, SyncError> {
        attachments
            .iter()
            .map(|attachment| {
                let encrypted_size =
                    self.encrypted_attachment_size(&attachment.id, session_uuid, chat_key)?;
                let remote_id = match self.db.get_attachment_remote_id(&attachment.id)? {
                    Some(remote_id) => remote_id,
                    None => {
                        let fallback = attachment.id.clone();
                        self.db
                            .set_attachment_remote_id(&attachment.id, Some(&fallback))?;
                        fallback
                    }
                };
                let client_metadata =
                    encode_attachment_metadata(attachment, message_uuid, chat_key)?;
                Ok(RemoteAttachment {
                    id: remote_id,
                    size: encrypted_size,
                    client_metadata: Some(client_metadata),
                    encrypted_name: None,
                    kind: None,
                })
            })
            .collect()
    }

    fn decrypt_remote_attachments(
        &self,
        attachments: &[RemoteAttachment],
        chat_key: &[u8],
    ) -> Result<(Vec<AttachmentMeta>, HashMap<String, String>), SyncError> {
        let mut metas = Vec::with_capacity(attachments.len());
        let mut remote_ids = HashMap::new();
        for attachment in attachments {
            let (meta, client_id) = decode_attachment_metadata(attachment, chat_key)?;
            remote_ids.insert(client_id.clone(), attachment.id.clone());
            metas.push(meta);
        }
        Ok((metas, remote_ids))
    }

    fn collect_messages_for_sync(&self, session_uuid: Uuid) -> Result<Vec<Message>, SyncError> {
        let messages = self.db.get_messages(session_uuid)?;
        let mut pending = Vec::new();

        for message in messages {
            let state = self.sync_state.get_message_state(message.uuid)?;
            let missing_remote = state
                .as_ref()
                .and_then(|entry| entry.remote_id.as_deref())
                .is_none();
            let missing_server_ts = state
                .as_ref()
                .and_then(|entry| entry.server_updated_at)
                .is_none();
            if message.needs_sync || missing_remote || missing_server_ts {
                pending.push(message);
            }
        }

        Ok(pending)
    }

    fn reconcile_attachments(
        &self,
        session_uuid: Uuid,
        messages: &[Message],
    ) -> Result<(), SyncError> {
        for message in messages {
            for attachment in &message.attachments {
                if self
                    .db
                    .get_attachment_upload_state(&attachment.id)?
                    .is_none()
                {
                    let _ = self.db.upsert_pending_attachment(
                        &attachment.id,
                        session_uuid,
                        message.uuid,
                        attachment.size,
                    );
                }
            }
        }
        Ok(())
    }

    fn collect_attachment_states(
        &self,
        messages: &[Message],
    ) -> Result<HashMap<String, UploadState>, SyncError> {
        let mut states = HashMap::new();
        for message in messages {
            for attachment in &message.attachments {
                let state = self
                    .db
                    .get_attachment_upload_state(&attachment.id)?
                    .unwrap_or(UploadState::Pending);
                states.insert(attachment.id.clone(), state);
            }
        }
        Ok(states)
    }

    fn revalidate_uploaded_attachments(
        &self,
        http: &HttpClient,
        session_uuid: Uuid,
        messages: &[Message],
    ) -> Result<HashSet<String>, SyncError> {
        let states = self.collect_attachment_states(messages)?;
        let plaintext_dir = self.plaintext_dir.as_ref();
        let mut force_uploads = HashSet::new();
        let mut checked = HashSet::new();

        for message in messages {
            for attachment in &message.attachments {
                if !checked.insert(attachment.id.clone()) {
                    continue;
                }
                let state = states
                    .get(&attachment.id)
                    .copied()
                    .unwrap_or(UploadState::Pending);
                if state != UploadState::Uploaded {
                    continue;
                }

                let has_encrypted = self.attachment_store.exists(&attachment.id)?;
                let has_plaintext = plaintext_dir
                    .map(|dir| dir.join(&attachment.id).exists())
                    .unwrap_or(false);
                if !has_encrypted && !has_plaintext {
                    continue;
                }

                let remote_id = match self.db.get_attachment_remote_id(&attachment.id)? {
                    Some(remote_id) => remote_id,
                    None => {
                        let fallback = attachment.id.clone();
                        self.db
                            .set_attachment_remote_id(&attachment.id, Some(&fallback))?;
                        fallback
                    }
                };

                let status =
                    match http.head_status(&format!("/llmchat/chat/attachment/{}", remote_id)) {
                        Ok(status) => status,
                        Err(SyncError::Unauthorized) => return Err(SyncError::Unauthorized),
                        Err(_) => continue,
                    };

                if status == 404 {
                    let _ = self.db.upsert_pending_attachment(
                        &attachment.id,
                        session_uuid,
                        message.uuid,
                        attachment.size,
                    );
                    let _ = self
                        .db
                        .set_attachment_upload_state(&attachment.id, UploadState::Pending);
                    force_uploads.insert(attachment.id.clone());
                }
            }
        }

        Ok(force_uploads)
    }

    fn force_upload_attachment(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        session_uuid: Uuid,
        attachment_id: &str,
    ) -> Result<(), SyncError> {
        let (encrypted, content_length) =
            self.encrypted_attachment_bytes(attachment_id, session_uuid, chat_key)?;
        let request = UploadUrlRequest {
            content_length,
            content_md5: None,
        };
        let upload_url = http.post_json::<UploadUrlResponse, _>(
            "/llmchat/chat/attachment/upload-url?force=true",
            &request,
        )?;
        self.db
            .set_attachment_remote_id(attachment_id, Some(&upload_url.attachment_id))?;
        http.put_bytes(&upload_url.url, &encrypted, &[])?;
        if self
            .db
            .get_attachment_upload_state(attachment_id)?
            .is_some()
        {
            let _ = self.db.mark_attachment_uploaded(attachment_id);
        }
        Ok(())
    }

    fn upload_pending_attachments(
        &self,
        http: &HttpClient,
        chat_key: &[u8],
        session_uuid: Uuid,
        force_uploads: &HashSet<String>,
    ) -> Result<i64, SyncError> {
        let pending = self.db.get_pending_uploads_for_session(session_uuid)?;
        let mut uploaded = 0;

        for row in pending {
            self.db
                .set_attachment_upload_state(&row.attachment_id, UploadState::Uploading)?;

            let (encrypted, content_length) =
                match self.encrypted_attachment_bytes(&row.attachment_id, session_uuid, chat_key) {
                    Ok(data) => data,
                    Err(err) => {
                        let _ = self
                            .db
                            .set_attachment_upload_state(&row.attachment_id, UploadState::Failed);
                        return Err(err);
                    }
                };

            let request = UploadUrlRequest {
                content_length,
                content_md5: None,
            };

            let upload_path = if force_uploads.contains(&row.attachment_id) {
                "/llmchat/chat/attachment/upload-url?force=true".to_string()
            } else {
                "/llmchat/chat/attachment/upload-url".to_string()
            };

            let upload_url = match http.post_json::<UploadUrlResponse, _>(&upload_path, &request) {
                Ok(resp) => Some(resp),
                Err(SyncError::Http { status: 409, .. }) => {
                    let _ = self.db.mark_attachment_uploaded(&row.attachment_id);
                    uploaded += 1;
                    None
                }
                Err(SyncError::Http {
                    status: 404 | 501, ..
                }) => {
                    let _ = self
                        .db
                        .set_attachment_upload_state(&row.attachment_id, UploadState::Failed);
                    return Err(SyncError::AttachmentApiUnavailable);
                }
                Err(err) => {
                    let _ = self
                        .db
                        .set_attachment_upload_state(&row.attachment_id, UploadState::Failed);
                    return Err(err);
                }
            };

            if let Some(upload_url) = upload_url {
                self.db.set_attachment_remote_id(
                    &row.attachment_id,
                    Some(&upload_url.attachment_id),
                )?;
                if let Err(err) = http.put_bytes(&upload_url.url, &encrypted, &[]) {
                    let _ = self
                        .db
                        .set_attachment_upload_state(&row.attachment_id, UploadState::Failed);
                    return Err(err);
                }
                let _ = self.db.mark_attachment_uploaded(&row.attachment_id);
                uploaded += 1;
            }
        }

        Ok(uploaded)
    }

    fn encrypted_attachment_bytes(
        &self,
        attachment_id: &str,
        session_uuid: Uuid,
        chat_key: &[u8],
    ) -> Result<(Vec<u8>, i64), SyncError> {
        let bytes = self.ensure_encrypted_bytes(attachment_id, session_uuid, chat_key)?;
        let size = bytes.len() as i64;
        Ok((bytes, size))
    }

    fn encrypted_attachment_size(
        &self,
        attachment_id: &str,
        session_uuid: Uuid,
        chat_key: &[u8],
    ) -> Result<i64, SyncError> {
        if self.attachment_store.exists(attachment_id)? {
            let size = self.attachment_store.size(attachment_id)?;
            return Ok(size as i64);
        }

        let (_bytes, size) =
            self.encrypted_attachment_bytes(attachment_id, session_uuid, chat_key)?;
        Ok(size)
    }

    fn ensure_encrypted_bytes(
        &self,
        attachment_id: &str,
        session_uuid: Uuid,
        chat_key: &[u8],
    ) -> Result<Vec<u8>, SyncError> {
        if self.attachment_store.exists(attachment_id)? {
            return Ok(self.attachment_store.read(attachment_id)?);
        }

        let plaintext_dir = self
            .plaintext_dir
            .as_ref()
            .ok_or_else(|| SyncError::AttachmentMissing(attachment_id.to_string()))?;
        let path = plaintext_dir.join(attachment_id);
        if !path.exists() {
            return Err(SyncError::AttachmentMissing(attachment_id.to_string()));
        }
        let plaintext = std::fs::read(path)?;
        let encrypted = encrypt_attachment_bytes(&plaintext, chat_key, session_uuid)?;
        self.attachment_store.write(attachment_id, &encrypted)?;
        Ok(encrypted)
    }

    fn load_cursor(&self) -> Result<SyncCursor, SyncError> {
        match self.sync_state.get_meta(CURSOR_META_KEY)? {
            Some(data) => Ok(serde_json::from_slice(&data)?),
            None => Ok(SyncCursor::default()),
        }
    }

    fn save_cursor(&self, cursor: &SyncCursor) -> Result<(), SyncError> {
        let data = serde_json::to_vec(cursor)?;
        self.sync_state.set_meta(CURSOR_META_KEY, &data)?;
        Ok(())
    }

    fn load_chat_key_from_meta(&self, master_key: &[u8]) -> Result<Option<Vec<u8>>, SyncError> {
        load_chat_key_from_meta(&self.sync_state, master_key)
    }

    fn save_chat_key_to_meta(&self, payload: &ChatKeyPayload) -> Result<(), SyncError> {
        save_chat_key_to_meta(&self.sync_state, payload)
    }

    fn get_or_create_chat_key(
        &self,
        http: &HttpClient,
        master_key: &[u8],
    ) -> Result<(Vec<u8>, ChatKeyStatus), SyncError> {
        get_or_create_chat_key_with_state(&self.sync_state, http, master_key)
    }
}

pub fn fetch_chat_key(auth: SyncAuth, sync_db_path: String) -> Result<Vec<u8>, SyncError> {
    if auth.auth_token.trim().is_empty() {
        return Err(SyncError::NotLoggedIn);
    }
    if auth.master_key.len() != llmchat_db::crypto::KEY_BYTES {
        return Err(SyncError::Crypto("invalid master key length".to_string()));
    }

    let SyncAuth {
        base_url,
        auth_token,
        master_key,
        user_agent,
        client_package,
        client_version,
    } = auth;

    let http = HttpClient::new(HttpConfig {
        base_url,
        auth_token,
        user_agent,
        client_package,
        client_version,
        timeout_secs: None,
    })?;

    let sync_state = SyncStateDb::open_sqlite_with_defaults(sync_db_path)?;
    let (chat_key, _) = get_or_create_chat_key_with_state(&sync_state, &http, &master_key)?;
    Ok(chat_key)
}

fn load_chat_key_from_meta(
    sync_state: &SyncStateDb<SqliteBackend>,
    master_key: &[u8],
) -> Result<Option<Vec<u8>>, SyncError> {
    let data = match sync_state.get_meta(CHAT_KEY_META_KEY)? {
        Some(data) => data,
        None => return Ok(None),
    };
    let payload: ChatKeyPayload = serde_json::from_slice(&data)?;
    let encrypted = payload
        .encrypted_value()
        .ok_or_else(|| SyncError::InvalidResponse("missing encrypted chat key".to_string()))?;
    let encrypted_payload = crate::models::EncryptedPayload {
        encrypted_data: encrypted.to_string(),
        header: payload.header,
    };
    Ok(Some(decrypt_chat_key(&encrypted_payload, master_key)?))
}

fn save_chat_key_to_meta(
    sync_state: &SyncStateDb<SqliteBackend>,
    payload: &ChatKeyPayload,
) -> Result<(), SyncError> {
    let data = serde_json::to_vec(payload)?;
    sync_state.set_meta(CHAT_KEY_META_KEY, &data)?;
    Ok(())
}

fn get_or_create_chat_key_with_state(
    sync_state: &SyncStateDb<SqliteBackend>,
    http: &HttpClient,
    master_key: &[u8],
) -> Result<(Vec<u8>, ChatKeyStatus), SyncError> {
    if let Some(key) = load_chat_key_from_meta(sync_state, master_key)? {
        return Ok((key, ChatKeyStatus::Cached));
    }

    let remote = http.get_json_optional::<ChatKeyPayload>("/llmchat/chat/key", &[]);
    let remote = match remote {
        Ok(value) => value,
        Err(SyncError::Http {
            status: 400,
            code: Some(code),
            ..
        }) if code == "AuthKeyNotCreated" => None,
        Err(err) => return Err(err),
    };

    if let Some(payload) = remote {
        let encrypted = payload
            .encrypted_value()
            .ok_or_else(|| SyncError::InvalidResponse("missing encrypted chat key".to_string()))?;
        let encrypted_payload = crate::models::EncryptedPayload {
            encrypted_data: encrypted.to_string(),
            header: payload.header.clone(),
        };
        let key = decrypt_chat_key(&encrypted_payload, master_key)?;
        save_chat_key_to_meta(sync_state, &payload)?;
        return Ok((key, ChatKeyStatus::Remote));
    }

    let chat_key = keys::generate_stream_key();
    let encrypted = encrypt_chat_key(&chat_key, master_key)?;
    let payload = ChatKeyPayload::from_encrypted(&encrypted);

    match http.post_empty("/llmchat/chat/key", &payload) {
        Ok(()) => {
            save_chat_key_to_meta(sync_state, &payload)?;
            Ok((chat_key, ChatKeyStatus::Created))
        }
        Err(SyncError::Http { status: 409, .. }) => {
            let existing = http.get_json_optional::<ChatKeyPayload>("/llmchat/chat/key", &[])?;
            let payload = existing
                .ok_or_else(|| SyncError::InvalidResponse("chat key already exists".to_string()))?;
            let encrypted = payload.encrypted_value().ok_or_else(|| {
                SyncError::InvalidResponse("missing encrypted chat key".to_string())
            })?;
            let encrypted_payload = crate::models::EncryptedPayload {
                encrypted_data: encrypted.to_string(),
                header: payload.header.clone(),
            };
            let key = decrypt_chat_key(&encrypted_payload, master_key)?;
            save_chat_key_to_meta(sync_state, &payload)?;
            Ok((key, ChatKeyStatus::Remote))
        }
        Err(err) => Err(err),
    }
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct ClientMetadataPayload {
    #[serde(rename = "clientId")]
    client_id: String,
    #[serde(default)]
    created_at: Option<serde_json::Value>,
}

fn encode_client_metadata(
    client_id: &str,
    created_at: i64,
    chat_key: &[u8],
) -> Result<String, SyncError> {
    let created_at_value = if created_at > 0 {
        let encrypted = llmchat_db::crypto::encrypt_json_field(&created_at.to_string(), chat_key)
            .map_err(|err| SyncError::Crypto(err.to_string()))?;
        Some(serde_json::Value::String(encrypted))
    } else {
        None
    };

    let payload = ClientMetadataPayload {
        client_id: client_id.to_string(),
        created_at: created_at_value,
    };
    Ok(serde_json::to_string(&payload)?)
}

fn decode_client_id(value: &str) -> Option<String> {
    serde_json::from_str::<ClientMetadataPayload>(value)
        .ok()
        .map(|payload| payload.client_id)
        .filter(|client_id| !client_id.trim().is_empty())
}

fn decode_client_created_at(value: &str, chat_key: &[u8]) -> Option<i64> {
    if let Ok(payload) = serde_json::from_str::<ClientMetadataPayload>(value) {
        let created_at_value = payload.created_at?;
        let parsed = match created_at_value {
            serde_json::Value::Number(number) => number.as_i64(),
            serde_json::Value::String(raw) => {
                let decrypted =
                    llmchat_db::crypto::decrypt_json_field(&raw, chat_key).unwrap_or(raw);
                decrypted.parse::<i64>().ok()
            }
            _ => None,
        };
        return parsed.filter(|created_at| *created_at > 0);
    }

    let decrypted = llmchat_db::crypto::decrypt_json_field(value, chat_key)
        .unwrap_or_else(|_| value.to_string());
    decrypted
        .parse::<i64>()
        .ok()
        .filter(|created_at| *created_at > 0)
}

#[derive(Debug, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct AttachmentClientMetadata {
    #[serde(rename = "clientId")]
    client_id: String,
    #[serde(rename = "localId", default)]
    local_id: Option<String>,
    #[serde(default)]
    encrypted_name: Option<String>,
    #[serde(default)]
    kind: Option<AttachmentKind>,
}

fn encode_attachment_metadata(
    attachment: &AttachmentMeta,
    message_uuid: Uuid,
    chat_key: &[u8],
) -> Result<String, SyncError> {
    let encrypted_name = llmchat_db::crypto::encrypt_json_field(&attachment.name, chat_key)
        .map_err(|err| SyncError::Crypto(err.to_string()))?;
    let payload = AttachmentClientMetadata {
        client_id: format!("{}:{}", message_uuid, attachment.id),
        local_id: Some(attachment.id.clone()),
        encrypted_name: Some(encrypted_name),
        kind: Some(attachment.kind),
    };
    Ok(serde_json::to_string(&payload)?)
}

fn decode_attachment_metadata(
    attachment: &RemoteAttachment,
    chat_key: &[u8],
) -> Result<(AttachmentMeta, String), SyncError> {
    if let Some(metadata) = &attachment.client_metadata {
        let payload = serde_json::from_str::<AttachmentClientMetadata>(metadata).map_err(|_| {
            SyncError::InvalidResponse("invalid attachment clientMetadata".to_string())
        })?;
        let encrypted_name = payload.encrypted_name.ok_or_else(|| {
            SyncError::InvalidResponse("missing attachment encryptedName".to_string())
        })?;
        let name = llmchat_db::crypto::decrypt_json_field(&encrypted_name, chat_key)
            .map_err(|err| SyncError::Crypto(err.to_string()))?;
        let kind = payload.kind.unwrap_or_else(|| infer_kind(&name));
        let local_id = payload
            .local_id
            .clone()
            .filter(|value| !value.trim().is_empty())
            .unwrap_or(payload.client_id.clone());
        return Ok((
            AttachmentMeta {
                id: local_id.clone(),
                kind,
                size: attachment.size,
                name,
            },
            local_id,
        ));
    }

    let encrypted_name = attachment
        .encrypted_name
        .as_ref()
        .ok_or_else(|| SyncError::InvalidResponse("missing attachment metadata".to_string()))?;
    let name = llmchat_db::crypto::decrypt_json_field(encrypted_name, chat_key)
        .map_err(|err| SyncError::Crypto(err.to_string()))?;
    let kind = attachment.kind.unwrap_or_else(|| infer_kind(&name));
    let client_id = attachment.id.clone();
    Ok((
        AttachmentMeta {
            id: client_id.clone(),
            kind,
            size: attachment.size,
            name,
        },
        client_id,
    ))
}

#[derive(Debug, serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct UpsertSessionRequest {
    #[serde(
        rename = "sessionUUID",
        alias = "session_uuid",
        skip_serializing_if = "Option::is_none"
    )]
    session_uuid: Option<String>,
    #[serde(rename = "encryptedData", alias = "encrypted_data")]
    encrypted_data: String,
    header: String,
    #[serde(
        rename = "clientMetadata",
        alias = "client_metadata",
        skip_serializing_if = "Option::is_none"
    )]
    client_metadata: Option<String>,
}

#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct UpsertSessionResponse {
    #[serde(rename = "sessionUUID", alias = "session_uuid")]
    session_uuid: String,
    #[serde(alias = "updated_at")]
    updated_at: Option<i64>,
}

#[derive(Debug, serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct UpsertMessageResponse {
    #[serde(rename = "messageUUID", alias = "message_uuid")]
    message_uuid: String,
    #[serde(alias = "updated_at")]
    updated_at: Option<i64>,
}

#[derive(Debug, serde::Serialize)]
#[serde(rename_all = "camelCase")]
struct UpsertMessageRequest {
    #[serde(
        rename = "messageUUID",
        alias = "message_uuid",
        skip_serializing_if = "Option::is_none"
    )]
    message_uuid: Option<String>,
    #[serde(rename = "sessionUUID", alias = "session_uuid")]
    session_uuid: String,
    #[serde(rename = "parentMessageUUID", alias = "parent_message_uuid")]
    parent_message_uuid: Option<String>,
    sender: String,
    attachments: Vec<RemoteAttachment>,
    #[serde(rename = "encryptedData", alias = "encrypted_data")]
    encrypted_data: String,
    header: String,
    #[serde(
        rename = "clientMetadata",
        alias = "client_metadata",
        skip_serializing_if = "Option::is_none"
    )]
    client_metadata: Option<String>,
}

fn normalize_remote_uuid(value: Option<String>) -> Option<String> {
    value.and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() || trimmed == ZERO_UUID {
            None
        } else {
            Some(trimmed.to_string())
        }
    })
}

fn blocked_messages(messages: &[Message], states: &HashMap<String, UploadState>) -> HashSet<Uuid> {
    let mut blocked: HashSet<Uuid> = HashSet::new();
    let mut children: HashMap<Uuid, Vec<Uuid>> = HashMap::new();

    for message in messages {
        let parent = message.parent_message_uuid;
        if let Some(parent) = parent {
            children.entry(parent).or_default().push(message.uuid);
        }
        let is_blocked = message.attachments.iter().any(|att| {
            states
                .get(&att.id)
                .map(|state| *state != UploadState::Uploaded)
                .unwrap_or(true)
        });
        if is_blocked {
            blocked.insert(message.uuid);
        }
    }

    let mut queue: Vec<Uuid> = blocked.iter().cloned().collect();
    while let Some(current) = queue.pop() {
        if let Some(kids) = children.get(&current) {
            for child in kids {
                if blocked.insert(*child) {
                    queue.push(*child);
                }
            }
        }
    }

    blocked
}

fn infer_kind(name: &str) -> AttachmentKind {
    let lower = name.to_ascii_lowercase();
    if lower.ends_with(".png")
        || lower.ends_with(".jpg")
        || lower.ends_with(".jpeg")
        || lower.ends_with(".gif")
        || lower.ends_with(".webp")
        || lower.ends_with(".heic")
        || lower.ends_with(".bmp")
    {
        AttachmentKind::Image
    } else {
        AttachmentKind::Document
    }
}
