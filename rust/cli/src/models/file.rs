#![allow(dead_code)]

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RemoteFile {
    pub id: i64,
    #[serde(rename = "collectionID")]
    pub collection_id: i64,
    #[serde(rename = "ownerID")]
    pub owner_id: i64,
    #[serde(rename = "encryptedKey")]
    pub encrypted_key: String,
    #[serde(rename = "keyDecryptionNonce")]
    pub key_decryption_nonce: String,
    pub file: FileInfo,
    pub thumbnail: FileInfo,
    pub metadata: MetadataInfo,
    #[serde(rename = "isDeleted")]
    pub is_deleted: bool,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
    #[serde(rename = "pubMagicMetadata")]
    pub pub_magic_metadata: Option<MagicMetadata>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MagicMetadata {
    pub version: i32,
    pub count: i32,
    pub data: String,
    pub header: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileInfo {
    #[serde(rename = "encryptedData")]
    pub encrypted_data: Option<String>,
    #[serde(rename = "decryptionHeader")]
    pub decryption_header: String,
    #[serde(rename = "objectKey")]
    pub object_key: Option<String>,
    pub size: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MetadataInfo {
    #[serde(rename = "encryptedData")]
    pub encrypted_data: String,
    #[serde(rename = "decryptionHeader")]
    pub decryption_header: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum FileType {
    Image,
    Video,
    LivePhoto,
    Other,
}
