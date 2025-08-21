#![allow(dead_code)]

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Collection {
    pub id: i64,
    pub owner: i64,
    pub key: String,
    pub name: String,
    #[serde(rename = "type")]
    pub collection_type: CollectionType,
    pub attributes: Option<CollectionAttributes>,
    #[serde(rename = "sharees")]
    pub sharees: Option<Vec<Sharee>>,
    #[serde(rename = "publicURLs")]
    pub public_urls: Option<Vec<PublicURL>>,
    #[serde(rename = "updatedAt")]
    pub updated_at: i64,
    #[serde(rename = "isDeleted")]
    pub is_deleted: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum CollectionType {
    #[serde(rename = "folder")]
    Folder,
    #[serde(rename = "favorites")]
    Favorites,
    #[serde(rename = "album")]
    Album,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CollectionAttributes {
    #[serde(rename = "encryptedPath")]
    pub encrypted_path: Option<String>,
    #[serde(rename = "pathDecryptionNonce")]
    pub path_decryption_nonce: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Sharee {
    pub id: i64,
    pub email: String,
    pub role: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PublicURL {
    pub url: String,
    #[serde(rename = "deviceLimit")]
    pub device_limit: i32,
    #[serde(rename = "validTill")]
    pub valid_till: i64,
}
