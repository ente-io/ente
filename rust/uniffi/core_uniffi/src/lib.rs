use ente_core::crypto;
use serde_json::Value;

uniffi::include_scaffolding!("ente_core");

#[derive(Debug, thiserror::Error)]
pub enum EnteCoreError {
    #[error("{detail}")]
    Message { detail: String },
}

fn message_error(detail: impl Into<String>) -> EnteCoreError {
    EnteCoreError::Message {
        detail: detail.into(),
    }
}

fn decrypt_with_stream_blob_fallback(
    encrypted_data: &[u8],
    decryption_header: &[u8],
    key: &[u8],
) -> Result<Vec<u8>, EnteCoreError> {
    match crypto::stream::decrypt_file_data(encrypted_data, decryption_header, key) {
        Ok(bytes) => Ok(bytes),
        Err(stream_err) => match crypto::blob::decrypt(encrypted_data, decryption_header, key) {
            Ok(bytes) => Ok(bytes),
            Err(blob_err) => Err(message_error(format!(
                "stream decrypt failed: {stream_err}; blob decrypt failed: {blob_err}"
            ))),
        },
    }
}

pub fn decrypt_blob_bytes(
    encrypted_data: Vec<u8>,
    decryption_header_b64: String,
    key: Vec<u8>,
) -> Result<Vec<u8>, EnteCoreError> {
    let decryption_header = crypto::decode_b64(&decryption_header_b64)
        .map_err(|e| message_error(format!("decryption_header_b64 decode failed: {e}")))?;

    decrypt_with_stream_blob_fallback(&encrypted_data, &decryption_header, &key)
}

pub fn decrypt_box_key(
    encrypted_key_b64: String,
    key_decryption_nonce_b64: String,
    collection_key_b64: String,
) -> Result<Vec<u8>, EnteCoreError> {
    let encrypted_key = crypto::decode_b64(&encrypted_key_b64)
        .map_err(|e| message_error(format!("encrypted_key_b64 decode failed: {e}")))?;
    let key_decryption_nonce = crypto::decode_b64(&key_decryption_nonce_b64)
        .map_err(|e| message_error(format!("key_decryption_nonce_b64 decode failed: {e}")))?;
    let collection_key = crypto::decode_b64(&collection_key_b64)
        .map_err(|e| message_error(format!("collection_key_b64 decode failed: {e}")))?;

    crypto::secretbox::decrypt(&encrypted_key, &key_decryption_nonce, &collection_key)
        .map_err(|e| message_error(format!("secretbox decrypt failed: {e}")))
}

pub fn decrypt_metadata_file_type(
    encrypted_data_b64: String,
    decryption_header_b64: String,
    key: Vec<u8>,
) -> Result<Option<i32>, EnteCoreError> {
    let encrypted_data = crypto::decode_b64(&encrypted_data_b64)
        .map_err(|e| message_error(format!("encrypted_data_b64 decode failed: {e}")))?;
    let decryption_header = crypto::decode_b64(&decryption_header_b64)
        .map_err(|e| message_error(format!("decryption_header_b64 decode failed: {e}")))?;

    let plaintext = decrypt_with_stream_blob_fallback(&encrypted_data, &decryption_header, &key)?;
    let metadata_json = String::from_utf8(plaintext)
        .map_err(|e| message_error(format!("metadata UTF-8 decode failed: {e}")))?;

    let metadata: Value = serde_json::from_str(&metadata_json)
        .map_err(|e| message_error(format!("metadata JSON parse failed: {e}")))?;

    Ok(extract_file_type(&metadata))
}

fn extract_file_type(metadata: &Value) -> Option<i32> {
    let direct = metadata
        .get("fileType")
        .or_else(|| metadata.get("file_type"));

    let nested = metadata
        .get("metadata")
        .and_then(|it| it.get("fileType").or_else(|| it.get("file_type")));

    direct
        .and_then(parse_file_type_value)
        .or_else(|| nested.and_then(parse_file_type_value))
}

fn parse_file_type_value(value: &Value) -> Option<i32> {
    if let Some(number) = value.as_i64() {
        return i32::try_from(number).ok();
    }
    if let Some(number) = value.as_u64() {
        return i32::try_from(number).ok();
    }
    if let Some(text) = value.as_str() {
        return text.parse::<i32>().ok();
    }
    None
}

pub fn derive_key(
    passphrase: String,
    salt_b64: String,
    ops_limit: u64,
    mem_limit: u64,
) -> Result<String, EnteCoreError> {
    let ops_limit_u32 = u32::try_from(ops_limit)
        .map_err(|_| message_error(format!("ops_limit out of range: {ops_limit}")))?;
    let mem_limit_u32 = u32::try_from(mem_limit)
        .map_err(|_| message_error(format!("mem_limit out of range: {mem_limit}")))?;

    let key = crypto::argon::derive_key_from_b64_salt(
        &passphrase,
        &salt_b64,
        mem_limit_u32,
        ops_limit_u32,
    )
    .map_err(|e| message_error(format!("derive key failed: {e}")))?;

    Ok(crypto::encode_b64(&key))
}

pub fn init_crypto() -> Result<(), EnteCoreError> {
    crypto::init().map_err(|e| message_error(format!("crypto init failed: {e}")))
}

pub fn secretbox_key_bytes() -> u32 {
    crypto::secretbox::KEY_BYTES as u32
}
