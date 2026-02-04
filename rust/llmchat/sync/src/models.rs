use serde::{Deserialize, Serialize};

use crate::diff_cursor::SyncCursor;
use llmchat_db::AttachmentKind;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct EncryptedPayload {
    #[serde(
        alias = "encrypted_key",
        alias = "encryptedKey",
        alias = "encrypted_data",
        alias = "encryptedData"
    )]
    pub encrypted_data: String,
    pub header: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatKeyPayload {
    #[serde(
        rename = "encryptedKey",
        default,
        skip_serializing_if = "Option::is_none",
        alias = "encrypted_key"
    )]
    pub encrypted_key: Option<String>,
    #[serde(
        rename = "encryptedData",
        default,
        skip_serializing_if = "Option::is_none",
        alias = "encrypted_data"
    )]
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
#[serde(rename_all = "camelCase")]
pub struct RemoteSession {
    #[serde(rename = "sessionUUID", alias = "session_uuid")]
    pub session_uuid: String,
    #[serde(rename = "encryptedData", alias = "encrypted_data")]
    pub encrypted_data: String,
    pub header: String,
    #[serde(
        rename = "clientMetadata",
        alias = "client_metadata",
        skip_serializing_if = "Option::is_none"
    )]
    pub client_metadata: Option<String>,
    #[serde(alias = "created_at")]
    pub created_at: i64,
    #[serde(alias = "updated_at")]
    pub updated_at: i64,
    #[serde(alias = "is_deleted")]
    pub is_deleted: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RemoteMessage {
    #[serde(rename = "messageUUID", alias = "message_uuid")]
    pub message_uuid: String,
    #[serde(rename = "sessionUUID", alias = "session_uuid")]
    pub session_uuid: String,
    #[serde(rename = "parentMessageUUID", alias = "parent_message_uuid")]
    pub parent_message_uuid: Option<String>,
    pub sender: String,
    pub attachments: Vec<RemoteAttachment>,
    #[serde(rename = "encryptedData", alias = "encrypted_data")]
    pub encrypted_data: String,
    pub header: String,
    #[serde(
        rename = "clientMetadata",
        alias = "client_metadata",
        skip_serializing_if = "Option::is_none"
    )]
    pub client_metadata: Option<String>,
    #[serde(alias = "created_at")]
    pub created_at: i64,
    #[serde(alias = "updated_at")]
    pub updated_at: Option<i64>,
    #[serde(alias = "is_deleted")]
    pub is_deleted: Option<bool>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RemoteAttachment {
    pub id: String,
    pub size: i64,
    #[serde(
        rename = "clientMetadata",
        alias = "client_metadata",
        skip_serializing_if = "Option::is_none"
    )]
    pub client_metadata: Option<String>,
    #[serde(
        rename = "encryptedName",
        alias = "encrypted_name",
        skip_serializing_if = "Option::is_none"
    )]
    pub encrypted_name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub kind: Option<AttachmentKind>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionTombstone {
    #[serde(rename = "sessionUUID", alias = "session_uuid")]
    pub session_uuid: String,
    #[serde(alias = "deleted_at")]
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MessageTombstone {
    #[serde(rename = "messageUUID", alias = "message_uuid")]
    pub message_uuid: String,
    #[serde(alias = "deleted_at")]
    pub deleted_at: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct DiffTombstones {
    #[serde(default)]
    pub sessions: Vec<SessionTombstone>,
    #[serde(default)]
    pub messages: Vec<MessageTombstone>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
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
#[serde(rename_all = "camelCase")]
pub struct UploadUrlRequest {
    pub content_length: i64,
    #[serde(
        rename = "contentMD5",
        alias = "content_md5",
        skip_serializing_if = "Option::is_none"
    )]
    pub content_md5: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UploadUrlResponse {
    #[serde(rename = "attachmentId", alias = "attachment_id")]
    pub attachment_id: String,
    #[serde(rename = "objectKey", alias = "object_key")]
    pub object_key: String,
    pub url: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SessionPayload {
    pub title: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct MessagePayload {
    pub text: String,
}
