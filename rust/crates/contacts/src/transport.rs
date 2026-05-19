use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RootKeyResponse {
    pub encrypted_key: String,
    pub header: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateRootKeyRequest<'a> {
    pub r#type: &'a str,
    pub encrypted_key: &'a str,
    pub header: &'a str,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CreateContactRequest<'a> {
    #[serde(rename = "contactUserID")]
    pub contact_user_id: i64,
    pub encrypted_key: &'a str,
    pub encrypted_data: &'a str,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdateContactRequest<'a> {
    #[serde(rename = "contactUserID")]
    pub contact_user_id: i64,
    pub encrypted_data: &'a str,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ContactEntityResponse {
    pub id: String,
    #[serde(rename = "contactUserID")]
    pub contact_user_id: i64,
    pub email: Option<String>,
    #[serde(rename = "profilePictureAttachmentID")]
    pub profile_picture_attachment_id: Option<String>,
    pub encrypted_key: Option<String>,
    pub encrypted_data: Option<String>,
    pub is_deleted: bool,
    pub created_at: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct ContactDiffResponse {
    pub diff: Vec<ContactEntityResponse>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct AttachmentUploadUrlRequest {
    pub content_length: i64,
    #[serde(rename = "contentMD5")]
    pub content_md5: String,
}

#[derive(Debug, Clone, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AttachmentUploadUrlResponse {
    #[serde(rename = "attachmentID")]
    pub attachment_id: String,
    pub url: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct CommitAttachmentRequest<'a> {
    #[serde(rename = "attachmentID")]
    pub attachment_id: &'a str,
    pub size: i64,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SignedUrlResponse {
    pub url: String,
}
