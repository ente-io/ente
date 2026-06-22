use ente_core::crypto as core_crypto;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct CryptoError {
    code: &'static str,
    message: String,
}

#[wasm_bindgen]
impl CryptoError {
    #[wasm_bindgen(getter)]
    pub fn code(&self) -> String {
        self.code.to_owned()
    }

    #[wasm_bindgen(getter)]
    pub fn message(&self) -> String {
        self.message.clone()
    }
}

impl From<core_crypto::CryptoError> for CryptoError {
    fn from(e: core_crypto::CryptoError) -> Self {
        Self {
            code: e.code(),
            message: e.to_string(),
        }
    }
}

#[wasm_bindgen]
pub struct EncryptedBox {
    encrypted_data: Vec<u8>,
    nonce: Vec<u8>,
}

#[wasm_bindgen]
impl EncryptedBox {
    #[wasm_bindgen(getter, js_name = encryptedData)]
    pub fn encrypted_data(&self) -> Vec<u8> {
        self.encrypted_data.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn nonce(&self) -> Vec<u8> {
        self.nonce.clone()
    }
}

#[wasm_bindgen(js_name = encryptBox)]
pub fn encrypt_box(data: &[u8], key: &[u8]) -> Result<EncryptedBox, CryptoError> {
    let out = core_crypto::secretbox::encrypt(data, &core_crypto::Key::try_from_slice(key)?);
    Ok(EncryptedBox {
        encrypted_data: out.encrypted_data,
        nonce: out.nonce.as_bytes().to_vec(),
    })
}

#[wasm_bindgen(js_name = decryptBox)]
pub fn decrypt_box(data: &[u8], nonce: &[u8], key: &[u8]) -> Result<Vec<u8>, CryptoError> {
    Ok(core_crypto::secretbox::decrypt(
        data,
        &core_crypto::Nonce::try_from_slice(nonce)?,
        &core_crypto::Key::try_from_slice(key)?,
    )?)
}
