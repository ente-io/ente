use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct WrappedRootContactKey {
    pub encrypted_key: String,
    pub header: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct ContactData {
    pub contact_user_id: i64,
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub birth_date: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ContactRecord {
    pub id: String,
    pub contact_user_id: i64,
    pub email: Option<String>,
    pub name: Option<String>,
    pub birth_date: Option<String>,
    pub profile_picture_attachment_id: Option<String>,
    pub is_deleted: bool,
    pub created_at: i64,
    pub updated_at: i64,
}
