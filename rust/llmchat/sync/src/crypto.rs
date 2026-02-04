use ente_core::crypto::{self, blob};
use hkdf::Hkdf;
use serde::{Serialize, de::DeserializeOwned};
use sha2::Sha256;
use uuid::Uuid;

use crate::errors::SyncError;
use crate::models::EncryptedPayload;

pub fn encrypt_payload<T: Serialize>(
    payload: &T,
    key: &[u8],
) -> Result<EncryptedPayload, SyncError> {
    let json = serde_json::to_vec(payload)?;
    let encrypted = blob::encrypt(&json, key)?;
    Ok(EncryptedPayload {
        encrypted_data: crypto::encode_b64(&encrypted.encrypted_data),
        header: crypto::encode_b64(&encrypted.decryption_header),
    })
}

pub fn decrypt_payload<T: DeserializeOwned>(
    encrypted_data: &str,
    header: &str,
    key: &[u8],
) -> Result<T, SyncError> {
    let ciphertext = crypto::decode_b64(encrypted_data)?;
    let header = crypto::decode_b64(header)?;
    let plaintext = blob::decrypt(&ciphertext, &header, key)?;
    let payload = serde_json::from_slice(&plaintext)?;
    Ok(payload)
}

pub fn encrypt_chat_key(chat_key: &[u8], master_key: &[u8]) -> Result<EncryptedPayload, SyncError> {
    let encrypted = blob::encrypt(chat_key, master_key)?;
    Ok(EncryptedPayload {
        encrypted_data: crypto::encode_b64(&encrypted.encrypted_data),
        header: crypto::encode_b64(&encrypted.decryption_header),
    })
}

pub fn decrypt_chat_key(
    payload: &EncryptedPayload,
    master_key: &[u8],
) -> Result<Vec<u8>, SyncError> {
    let ciphertext = crypto::decode_b64(&payload.encrypted_data)?;
    let header = crypto::decode_b64(&payload.header)?;
    let plaintext = blob::decrypt(&ciphertext, &header, master_key)?;
    Ok(plaintext)
}

pub fn derive_attachment_key(chat_key: &[u8], session_uuid: Uuid) -> Result<Vec<u8>, SyncError> {
    let hk = Hkdf::<Sha256>::new(Some(session_uuid.as_bytes()), chat_key);
    let mut out = vec![0u8; blob::KEY_BYTES];
    hk.expand(b"llmchat_attachment_v1", &mut out)
        .map_err(|_| SyncError::Crypto("hkdf expand failed".to_string()))?;
    Ok(out)
}

pub fn encrypt_attachment_bytes(
    plaintext: &[u8],
    chat_key: &[u8],
    session_uuid: Uuid,
) -> Result<Vec<u8>, SyncError> {
    let key = derive_attachment_key(chat_key, session_uuid)?;
    Ok(llmchat_db::crypto::encrypt_blob(plaintext, &key)?)
}

pub fn decrypt_attachment_bytes(
    ciphertext: &[u8],
    chat_key: &[u8],
    session_uuid: Uuid,
) -> Result<Vec<u8>, SyncError> {
    let key = derive_attachment_key(chat_key, session_uuid)?;
    Ok(llmchat_db::crypto::decrypt_blob(ciphertext, &key)?)
}
