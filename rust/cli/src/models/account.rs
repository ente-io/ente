#![allow(dead_code)]

use serde::{Deserialize, Serialize};
use uuid::Uuid;
use zeroize::Zeroize;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Account {
    pub user_id: i64,
    pub email: String,
    pub app: App,
    pub endpoint: String,
    pub export_dir: Option<String>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum App {
    Photos,
    Locker,
    Auth,
}

impl App {
    pub fn client_package(&self) -> &'static str {
        match self {
            App::Photos => "io.ente.photos",
            App::Locker => "io.ente.locker",
            App::Auth => "io.ente.auth",
        }
    }
}

impl Account {
    pub fn account_key(&self) -> String {
        format!("{}:{}", self.email, self.app.client_package())
    }
}

#[derive(Debug, Serialize, Deserialize, Zeroize)]
#[zeroize(drop)]
pub struct AccountSecrets {
    pub token: Vec<u8>,
    pub master_key: Vec<u8>,
    pub secret_key: Vec<u8>,
    pub public_key: Vec<u8>,
}

#[derive(Debug, Deserialize)]
pub struct SrpAttributes {
    #[serde(rename = "srpUserID")]
    pub srp_user_id: Uuid,
    #[serde(rename = "srpSalt")]
    pub srp_salt: String,
    #[serde(rename = "memLimit")]
    pub mem_limit: u32,
    #[serde(rename = "opsLimit")]
    pub ops_limit: u32,
    #[serde(rename = "kekSalt")]
    pub kek_salt: String,
    #[serde(rename = "isEmailMFAEnabled")]
    pub is_email_mfa_enabled: bool,
}

#[derive(Debug, Deserialize)]
pub struct KeyAttributes {
    #[serde(rename = "kekSalt")]
    pub kek_salt: String,
    #[serde(rename = "encryptedKey")]
    pub encrypted_key: String,
    #[serde(rename = "keyDecryptionNonce")]
    pub key_decryption_nonce: String,
    #[serde(rename = "publicKey")]
    pub public_key: String,
    #[serde(rename = "encryptedSecretKey")]
    pub encrypted_secret_key: String,
    #[serde(rename = "secretKeyDecryptionNonce")]
    pub secret_key_decryption_nonce: String,
    #[serde(rename = "memLimit")]
    pub mem_limit: u32,
    #[serde(rename = "opsLimit")]
    pub ops_limit: u32,
}

#[derive(Debug, Deserialize)]
pub struct AuthResponse {
    pub id: i64,
    pub token: Option<String>,
    #[serde(rename = "encryptedToken")]
    pub encrypted_token: Option<String>,
    #[serde(rename = "keyAttributes")]
    pub key_attributes: Option<KeyAttributes>,
}
