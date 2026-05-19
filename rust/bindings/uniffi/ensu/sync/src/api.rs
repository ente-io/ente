use ensu_sync as core;
use thiserror::Error;

#[derive(Debug, Error, uniffi::Error)]
pub enum SyncError {
    #[error("{0}")]
    Message(String),
    #[error("sync already in progress")]
    SyncInProgress,
}

impl From<core::SyncError> for SyncError {
    fn from(err: core::SyncError) -> Self {
        match err {
            core::SyncError::SyncInProgress => SyncError::SyncInProgress,
            other => SyncError::Message(other.to_string()),
        }
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct SyncAuth {
    pub base_url: String,
    pub auth_token: String,
    pub master_key: Vec<u8>,
    pub user_agent: Option<String>,
    pub client_package: Option<String>,
    pub client_version: Option<String>,
}

impl From<SyncAuth> for core::SyncAuth {
    fn from(value: SyncAuth) -> Self {
        core::SyncAuth {
            base_url: value.base_url,
            auth_token: value.auth_token,
            master_key: value.master_key.into(),
            user_agent: value.user_agent,
            client_package: value.client_package,
            client_version: value.client_version,
        }
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct MigrationConfig {
    pub batch_size: i64,
    pub priority: MigrationPriority,
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum MigrationPriority {
    RecentFirst,
    OldestFirst,
}

impl From<MigrationPriority> for core::MigrationPriority {
    fn from(value: MigrationPriority) -> Self {
        match value {
            MigrationPriority::RecentFirst => core::MigrationPriority::RecentFirst,
            MigrationPriority::OldestFirst => core::MigrationPriority::OldestFirst,
        }
    }
}

impl From<core::MigrationPriority> for MigrationPriority {
    fn from(value: core::MigrationPriority) -> Self {
        match value {
            core::MigrationPriority::RecentFirst => MigrationPriority::RecentFirst,
            core::MigrationPriority::OldestFirst => MigrationPriority::OldestFirst,
        }
    }
}

impl From<MigrationConfig> for core::MigrationConfig {
    fn from(value: MigrationConfig) -> Self {
        core::MigrationConfig {
            batch_size: value.batch_size,
            priority: value.priority.into(),
        }
    }
}

#[derive(Debug, Clone, uniffi::Enum)]
pub enum MigrationState {
    NotNeeded,
    InProgress,
    Complete,
    Failed,
}

impl From<core::MigrationState> for MigrationState {
    fn from(value: core::MigrationState) -> Self {
        match value {
            core::MigrationState::NotNeeded => MigrationState::NotNeeded,
            core::MigrationState::InProgress => MigrationState::InProgress,
            core::MigrationState::Complete => MigrationState::Complete,
            core::MigrationState::Failed => MigrationState::Failed,
        }
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct MigrationProgress {
    pub state: MigrationState,
    pub processed: i64,
    pub remaining: i64,
    pub total: i64,
}

impl From<core::MigrationProgress> for MigrationProgress {
    fn from(value: core::MigrationProgress) -> Self {
        MigrationProgress {
            state: value.state.into(),
            processed: value.processed,
            remaining: value.remaining,
            total: value.total,
        }
    }
}

#[uniffi::export(callback_interface)]
pub trait MigrationProgressCallback: Send + Sync {
    fn on_progress(&self, progress: MigrationProgress);
}

struct MigrationCallbackAdapter {
    inner: Box<dyn MigrationProgressCallback>,
}

impl core::MigrationProgressCallback for MigrationCallbackAdapter {
    fn on_progress(&self, progress: core::MigrationProgress) {
        self.inner.on_progress(progress.into());
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct SyncStats {
    pub sessions: i64,
    pub messages: i64,
}

impl From<core::SyncStats> for SyncStats {
    fn from(value: core::SyncStats) -> Self {
        SyncStats {
            sessions: value.sessions,
            messages: value.messages,
        }
    }
}

#[derive(Debug, Clone, uniffi::Record)]
pub struct SyncResult {
    pub pulled: SyncStats,
    pub pushed: SyncStats,
    pub uploaded_attachments: i64,
    pub downloaded_attachments: i64,
}

impl From<core::SyncResult> for SyncResult {
    fn from(value: core::SyncResult) -> Self {
        SyncResult {
            pulled: value.pulled.into(),
            pushed: value.pushed.into(),
            uploaded_attachments: value.uploaded_attachments,
            downloaded_attachments: value.downloaded_attachments,
        }
    }
}

#[uniffi::export]
pub fn fetch_chat_key(auth: SyncAuth, sync_db_path: String) -> Result<Vec<u8>, SyncError> {
    let key = core::fetch_chat_key(auth.into(), sync_db_path)?;
    Ok(key)
}

#[derive(uniffi::Object)]
pub struct EnsuSync {
    inner: core::SyncEngine,
}

#[uniffi::export]
impl EnsuSync {
    #[uniffi::constructor]
    pub fn open(
        main_db_path: String,
        attachments_db_path: String,
        db_key: Vec<u8>,
        attachments_dir: String,
        meta_dir: String,
        plaintext_dir: Option<String>,
    ) -> Result<Self, SyncError> {
        let inner = core::SyncEngine::new(
            main_db_path,
            attachments_db_path,
            db_key,
            attachments_dir,
            meta_dir,
            plaintext_dir,
        )?;
        Ok(Self { inner })
    }

    pub fn sync(&self, auth: SyncAuth) -> Result<SyncResult, SyncError> {
        let result = self.inner.sync(auth.into())?;
        Ok(result.into())
    }

    pub fn check_migration_status_local(&self) -> Option<MigrationState> {
        self.inner
            .check_migration_status_local()
            .ok()
            .flatten()
            .map(Into::into)
    }

    pub fn check_migration_status(&self, auth: SyncAuth) -> Result<MigrationState, SyncError> {
        let state = self.inner.check_migration_status(auth.into())?;
        Ok(state.into())
    }

    pub fn reset_sync_state(&self) -> Result<(), SyncError> {
        self.inner.reset_sync_state()?;
        Ok(())
    }

    pub fn seed_from_offline(
        &self,
        offline_db_path: String,
        offline_db_key: Vec<u8>,
    ) -> Result<(), SyncError> {
        self.inner
            .seed_from_offline(offline_db_path, offline_db_key)?;
        Ok(())
    }

    pub fn sync_with_progress(
        &self,
        auth: SyncAuth,
        config: MigrationConfig,
        callback: Box<dyn MigrationProgressCallback>,
    ) -> Result<SyncResult, SyncError> {
        let adapter = MigrationCallbackAdapter { inner: callback };
        let result = self
            .inner
            .sync_with_progress(auth.into(), config.into(), &adapter)?;
        Ok(result.into())
    }

    pub fn download_attachment(
        &self,
        attachment_id: String,
        session_uuid: String,
        auth: SyncAuth,
    ) -> Result<bool, SyncError> {
        self.inner
            .download_attachment(auth.into(), attachment_id, session_uuid)
            .map_err(Into::into)
    }
}
