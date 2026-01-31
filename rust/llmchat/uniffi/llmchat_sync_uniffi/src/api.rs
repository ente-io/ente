use llmchat_sync as core;
use thiserror::Error;

#[derive(Debug, Error, uniffi::Error)]
pub enum SyncError {
    #[error("{0}")]
    Message(String),
}

impl From<core::SyncError> for SyncError {
    fn from(err: core::SyncError) -> Self {
        SyncError::Message(err.to_string())
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
            master_key: value.master_key,
            user_agent: value.user_agent,
            client_package: value.client_package,
            client_version: value.client_version,
        }
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

#[derive(uniffi::Object)]
pub struct LlmChatSync {
    inner: core::SyncEngine,
}

#[uniffi::export]
impl LlmChatSync {
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
