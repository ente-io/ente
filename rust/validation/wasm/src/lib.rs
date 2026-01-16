//! WASM bindings for ente-core crypto benchmarks.

use wasm_bindgen::prelude::*;

use ente_core::{auth, crypto};

const AUTH_TOKEN: &[u8] = b"benchmark-auth-token";
const ARGON_MEM: u32 = 67_108_864; // 64 MiB
const ARGON_OPS: u32 = 2;

fn to_js_error(err: impl std::fmt::Display) -> JsValue {
    JsValue::from_str(&err.to_string())
}

/// SecretBox encryption using a caller-provided nonce.
#[wasm_bindgen]
pub fn secretbox_encrypt(plaintext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>, JsValue> {
    crypto::secretbox::encrypt_with_nonce(plaintext, nonce, key).map_err(to_js_error)
}

/// SecretBox decryption using a caller-provided nonce.
#[wasm_bindgen]
pub fn secretbox_decrypt(ciphertext: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>, JsValue> {
    crypto::secretbox::decrypt(ciphertext, nonce, key).map_err(to_js_error)
}

/// Argon2id key derivation.
#[wasm_bindgen]
pub fn argon2_derive(
    password: &str,
    salt: &[u8],
    mem_limit: u32,
    ops_limit: u32,
) -> Result<Vec<u8>, JsValue> {
    crypto::argon::derive_key(password, salt, mem_limit, ops_limit).map_err(to_js_error)
}

/// Auth signup (interactive strength). Returns login key bytes.
#[wasm_bindgen]
pub fn auth_signup(password: &str) -> Result<Vec<u8>, JsValue> {
    let result =
        auth::generate_keys_with_strength(password, auth::KeyDerivationStrength::Interactive)
            .map_err(to_js_error)?;
    Ok(result.login_key)
}

/// Auth artifacts used for login benchmarks.
#[wasm_bindgen]
pub struct AuthArtifacts {
    key_attrs_json: String,
    encrypted_token: String,
}

#[wasm_bindgen]
impl AuthArtifacts {
    /// Key attributes as JSON (camelCase).
    #[wasm_bindgen(getter)]
    pub fn key_attrs_json(&self) -> String {
        self.key_attrs_json.clone()
    }

    /// Encrypted token as base64.
    #[wasm_bindgen(getter)]
    pub fn encrypted_token(&self) -> String {
        self.encrypted_token.clone()
    }
}

/// Build auth artifacts used for login benchmarks.
#[wasm_bindgen]
pub fn auth_build_artifacts(password: &str) -> Result<AuthArtifacts, JsValue> {
    let result =
        auth::generate_keys_with_strength(password, auth::KeyDerivationStrength::Interactive)
            .map_err(to_js_error)?;

    let public_key = crypto::decode_b64(&result.key_attributes.public_key).map_err(to_js_error)?;
    let sealed_token = crypto::sealed::seal(AUTH_TOKEN, &public_key).map_err(to_js_error)?;

    let key_attrs_json = serde_json::to_string(&result.key_attributes).map_err(to_js_error)?;
    let encrypted_token = crypto::encode_b64(&sealed_token);

    Ok(AuthArtifacts {
        key_attrs_json,
        encrypted_token,
    })
}

/// Auth login benchmark (derive KEK + decrypt secrets).
#[wasm_bindgen]
pub fn auth_login(
    password: &str,
    key_attrs_json: &str,
    encrypted_token: &str,
) -> Result<Vec<u8>, JsValue> {
    let key_attrs: auth::KeyAttributes =
        serde_json::from_str(key_attrs_json).map_err(to_js_error)?;
    let mem = key_attrs.mem_limit.unwrap_or(ARGON_MEM);
    let ops = key_attrs.ops_limit.unwrap_or(ARGON_OPS);

    let kek = auth::derive_kek(password, &key_attrs.kek_salt, mem, ops).map_err(to_js_error)?;
    let secrets = auth::decrypt_secrets(&kek, &key_attrs, encrypted_token).map_err(to_js_error)?;
    Ok(secrets.master_key)
}

/// Streaming encryptor for SecretStream benchmarks.
#[wasm_bindgen]
pub struct StreamEncryptor {
    inner: crypto::stream::StreamEncryptor,
}

#[wasm_bindgen]
impl StreamEncryptor {
    /// Create a new encryptor with a random header.
    #[wasm_bindgen(constructor)]
    pub fn new(key: &[u8]) -> Result<StreamEncryptor, JsValue> {
        let inner = crypto::stream::StreamEncryptor::new(key).map_err(to_js_error)?;
        Ok(StreamEncryptor { inner })
    }

    /// Return the stream header.
    #[wasm_bindgen(getter)]
    pub fn header(&self) -> Vec<u8> {
        self.inner.header.clone()
    }

    /// Encrypt a chunk.
    pub fn push(&mut self, plaintext: &[u8], is_final: bool) -> Result<Vec<u8>, JsValue> {
        self.inner.push(plaintext, is_final).map_err(to_js_error)
    }
}

/// Streaming decryptor for SecretStream benchmarks.
#[wasm_bindgen]
pub struct StreamDecryptor {
    inner: crypto::stream::StreamDecryptor,
}

#[wasm_bindgen]
impl StreamDecryptor {
    /// Create a new decryptor from a header.
    #[wasm_bindgen(constructor)]
    pub fn new(header: &[u8], key: &[u8]) -> Result<StreamDecryptor, JsValue> {
        let inner = crypto::stream::StreamDecryptor::new(header, key).map_err(to_js_error)?;
        Ok(StreamDecryptor { inner })
    }

    /// Decrypt a chunk.
    pub fn pull(&mut self, ciphertext: &[u8]) -> Result<Vec<u8>, JsValue> {
        let (plaintext, _tag) = self.inner.pull(ciphertext).map_err(to_js_error)?;
        Ok(plaintext)
    }
}
