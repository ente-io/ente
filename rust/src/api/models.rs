use serde::{Deserialize, Serialize};
use uuid::Uuid;

// ========== Authentication Models ==========

#[derive(Debug, Deserialize, Serialize)]
pub struct SrpAttributes {
    #[serde(rename = "srpUserID")]
    pub srp_user_id: Uuid,
    #[serde(rename = "srpSalt")]
    pub srp_salt: String,
    #[serde(rename = "memLimit")]
    pub mem_limit: i32,
    #[serde(rename = "opsLimit")]
    pub ops_limit: i32,
    #[serde(rename = "kekSalt")]
    pub kek_salt: String,
    #[serde(rename = "isEmailMFAEnabled")]
    pub is_email_mfa_enabled: bool,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GetSrpAttributesResponse {
    pub attributes: SrpAttributes,
}

#[derive(Debug, Serialize)]
pub struct CreateSrpSessionRequest {
    #[serde(rename = "srpUserID")]
    pub srp_user_id: String,
    #[serde(rename = "srpA")]
    pub srp_a: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateSrpSessionResponse {
    #[serde(rename = "sessionID")]
    pub session_id: Uuid,
    #[serde(rename = "srpB")]
    pub srp_b: String,
}

#[derive(Debug, Serialize)]
pub struct VerifySrpSessionRequest {
    #[serde(rename = "srpUserID")]
    pub srp_user_id: String,
    #[serde(rename = "sessionID")]
    pub session_id: String,
    #[serde(rename = "srpM1")]
    pub srp_m1: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct KeyAttributes {
    pub kek_salt: String,
    pub kek_hash: Option<String>,
    pub encrypted_key: String,
    pub key_decryption_nonce: String,
    pub public_key: String,
    pub encrypted_secret_key: String,
    pub secret_key_decryption_nonce: String,
    pub mem_limit: i32,
    pub ops_limit: i32,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub id: i64,
    pub key_attributes: Option<KeyAttributes>,
    pub encrypted_token: Option<String>,
    pub token: Option<String>,
    pub two_factor_session_id: Option<String>,
    pub passkey_session_id: Option<String>,
    pub srp_m2: Option<String>,
    pub accounts_url: Option<String>,
}

impl AuthResponse {
    pub fn is_mfa_required(&self) -> bool {
        self.two_factor_session_id.is_some()
    }

    pub fn is_passkey_required(&self) -> bool {
        self.passkey_session_id.is_some()
    }
}

#[derive(Debug, Serialize)]
pub struct SendOtpRequest {
    pub email: String,
    pub purpose: String,
}

#[derive(Debug, Serialize)]
pub struct VerifyEmailRequest {
    pub email: String,
    pub ott: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct VerifyTotpRequest {
    pub session_id: String,
    pub code: String,
}

// ========== User Models ==========

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UserDetails {
    pub user: User,
    pub subscription: Subscription,
    pub family_data: Option<FamilyData>,
    pub storage: Storage,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct User {
    pub id: i64,
    pub email: String,
    pub profile_data: Option<ProfileData>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ProfileData {
    pub can_disable_emails: bool,
    pub is_email_mfa_enabled: bool,
    pub is_two_factor_enabled: bool,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Subscription {
    pub product_id: String,
    pub storage: i64,
    pub expiry_time: i64,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FamilyData {
    pub members: Vec<FamilyMember>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FamilyMember {
    pub id: i64,
    pub email: String,
    pub usage: i64,
    pub is_admin: bool,
}

#[derive(Debug, Deserialize)]
pub struct Storage {
    pub used: i64,
}

// ========== Collection Models ==========

#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Collection {
    pub id: i64,
    pub owner: CollectionUser,
    pub encrypted_key: String,
    pub key_decryption_nonce: Option<String>,
    pub name: Option<String>,
    pub encrypted_name: Option<String>,
    pub name_decryption_nonce: Option<String>,
    #[serde(rename = "type")]
    pub collection_type: String,
    pub attributes: Option<CollectionAttributes>,
    pub sharees: Option<Vec<CollectionUser>>,
    #[serde(rename = "publicURLs")]
    pub public_urls: Option<Vec<PublicUrl>>,
    pub updation_time: i64,
    #[serde(default)]
    pub is_deleted: bool,
    pub magic_metadata: Option<MagicMetadata>,
    pub pub_magic_metadata: Option<MagicMetadata>,
    pub shared_magic_metadata: Option<MagicMetadata>,
    pub app: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct CollectionAttributes {
    pub version: i32,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct PublicUrl {
    pub url: String,
    pub device_limit: i32,
    pub valid_till: i64,
    pub enable_download: bool,
    pub enable_collect: bool,
    pub password_enabled: bool,
    pub enable_join: bool,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct CollectionUser {
    pub id: i64,
    #[serde(default)]
    pub email: String,
    pub name: Option<String>,
    pub role: Option<String>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct MagicMetadata {
    pub version: i32,
    pub count: i32,
    pub data: String,
    pub header: String,
}

#[derive(Debug, Deserialize)]
pub struct GetCollectionsResponse {
    pub collections: Vec<Collection>,
}

// ========== File Models ==========

#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct File {
    pub id: i64,
    #[serde(rename = "ownerID")]
    pub owner_id: i64,
    #[serde(rename = "collectionID")]
    pub collection_id: i64,
    #[serde(rename = "collectionOwnerID")]
    pub collection_owner_id: Option<i64>,
    pub encrypted_key: String,
    pub key_decryption_nonce: String,
    pub file: FileAttributes,
    pub thumbnail: FileAttributes,
    pub metadata: FileAttributes,
    pub is_deleted: bool,
    pub updation_time: i64,
    pub magic_metadata: Option<MagicMetadata>,
    #[serde(rename = "pubMagicMetadata")]
    pub pub_magic_metadata: Option<MagicMetadata>,
    pub info: Option<FileInfo>,
}

impl File {
    pub fn is_removed_from_album(&self) -> bool {
        self.is_deleted || self.file.encrypted_data == Some("-".to_string())
    }
}

#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct FileAttributes {
    pub encrypted_data: Option<String>,
    pub decryption_header: String,
    pub size: Option<i64>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct FileInfo {
    pub file_size: Option<i64>,
    pub thumbnail_size: Option<i64>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct GetFilesRequest {
    pub collection_id: i64,
    pub since_time: i64,
    pub limit: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct GetFilesResponse {
    pub diff: Vec<File>,
    #[serde(rename = "hasMore")]
    pub has_more: bool,
}

#[derive(Debug, Deserialize)]
pub struct GetFileResponse {
    pub file: File,
}

// ========== Diff/Sync Models ==========

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct GetDiffRequest {
    pub since_time: i64,
    pub limit: i32,
}

#[derive(Debug, Deserialize)]
pub struct GetDiffResponse {
    pub diff: Vec<File>,
    #[serde(rename = "hasMore")]
    pub has_more: bool,
}

// ========== Download Models ==========

#[derive(Debug, Deserialize)]
pub struct GetFileUrlResponse {
    pub url: String,
}

#[derive(Debug, Deserialize)]
pub struct GetThumbnailUrlResponse {
    pub url: String,
}
