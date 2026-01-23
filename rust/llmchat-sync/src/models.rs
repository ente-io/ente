use serde::{Deserialize, Serialize};

use crate::diff_cursor::SyncCursor;
use llmchat_db::AttachmentKind;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct EncryptedPayload {
    #[serde(alias = "encrypted_key", alias = "encryptedKey", alias = "encryptedData")]
    pub encrypted_data: String,
    pub header: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatKeyPayload {
    #[serde(rename = "encrypted_key", default, skip_serializing_if = "Option::is_none", alias = "encryptedKey")]
    pub encrypted_key: Option<String>,
    #[serde(rename = "encrypted_data", default, skip_serializing_if = "Option::is_none", alias = "encryptedData")]
    pub encrypted_data: Option<String>,
    pub header: String,
}

impl ChatKeyPayload {
    pub fn from_encrypted(encrypted: &EncryptedPayload) -> Self {
        Self {
            encrypted_key: Some(encrypted.encrypted_data.clone()),
            encrypted_data: Some(encrypted.encrypted_data.clone()),
            header: encrypted.header.clone(),
        }
    }

    pub fn encrypted_value(&self) -> Option<&str> {
        self.encrypted_data
            .as_deref()
            .or(self.encrypted_key.as_deref())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct RemoteSession {
    pub session_uuid: String,
    pub root_session_uuid: Option<String>,
    pub branch_from_message_uuid: Option<String>,
    pub encrypted_data: String,
    pub header: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub is_deleted: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct RemoteMessage {
    pub message_uuid: String,
    pub session_uuid: String,
    pub parent_message_uuid: Option<String>,
    pub sender: String,
    pub attachments: Vec<RemoteAttachment>,
    pub encrypted_data: String,
    pub header: String,
    pub created_at: i64,
    pub updated_at: Option<i64>,
    pub is_deleted: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct RemoteAttachment {
    pub id: String,
    pub size: i64,
    pub encrypted_name: String,
    pub kind: Option<AttachmentKind>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct SessionTombstone {
    pub session_uuid: String,
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct MessageTombstone {
    pub message_uuid: String,
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub struct DiffTombstones {
    #[serde(default)]
    pub sessions: Vec<SessionTombstone>,
    #[serde(default)]
    pub messages: Vec<MessageTombstone>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct DiffResponse {
    #[serde(default)]
    pub sessions: Vec<RemoteSession>,
    #[serde(default)]
    pub messages: Vec<RemoteMessage>,
    #[serde(default)]
    pub tombstones: DiffTombstones,
    pub cursor: Option<SyncCursor>,
    pub timestamp: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct UploadUrlRequest {
    pub content_length: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub content_md5: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct UploadUrlResponse {
    pub object_key: String,
    pub url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct SessionPayload {
    pub title: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub struct MessagePayload {
    pub text: String,
}
