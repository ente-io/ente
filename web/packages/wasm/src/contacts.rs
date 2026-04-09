//! WASM bindings for contacts sync and attachment reads.

use ente_contacts::{
    ContactsCtx, ContactsError as CoreContactsError, OpenContactsCtxInput, WrappedRootContactKey,
};
use ente_core::crypto;
use serde::{Deserialize, Serialize};
use serde_wasm_bindgen as swb;
use wasm_bindgen::prelude::*;

/// Contacts error.
#[wasm_bindgen]
pub struct ContactsError {
    code: String,
    message: String,
}

#[wasm_bindgen]
impl ContactsError {
    /// Machine-readable error code.
    #[wasm_bindgen(getter)]
    pub fn code(&self) -> String {
        self.code.clone()
    }

    /// Human-readable error message.
    #[wasm_bindgen(getter)]
    pub fn message(&self) -> String {
        self.message.clone()
    }
}

impl From<CoreContactsError> for ContactsError {
    fn from(e: CoreContactsError) -> Self {
        let code = match &e {
            CoreContactsError::Http(_) => "http",
            CoreContactsError::Crypto(_) => "crypto",
            CoreContactsError::InvalidInput(_) => "invalid_input",
            CoreContactsError::MissingEncryptedData => "missing_encrypted_data",
            CoreContactsError::MissingEncryptedKey => "missing_encrypted_key",
            CoreContactsError::ProfilePictureNotFound => "profile_picture_not_found",
        }
        .to_string();

        Self {
            code,
            message: e.to_string(),
        }
    }
}

impl From<swb::Error> for ContactsError {
    fn from(e: swb::Error) -> Self {
        Self {
            code: "serde".to_string(),
            message: e.to_string(),
        }
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct OpenContactsCtxJsInput {
    base_url: String,
    auth_token: String,
    user_id: i64,
    master_key_b64: String,
    cached_root_key: Option<WrappedRootContactKey>,
    user_agent: Option<String>,
    client_package: Option<String>,
    client_version: Option<String>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ContactRecordJs {
    id: String,
    contact_user_id: i64,
    email: Option<String>,
    name: Option<String>,
    birth_date: Option<String>,
    #[serde(rename = "profilePictureAttachmentID")]
    profile_picture_attachment_id: Option<String>,
    is_deleted: bool,
    created_at: i64,
    updated_at: i64,
}

impl From<ente_contacts::ContactRecord> for ContactRecordJs {
    fn from(value: ente_contacts::ContactRecord) -> Self {
        Self {
            id: value.id,
            contact_user_id: value.contact_user_id,
            email: value.email,
            name: value.name,
            birth_date: value.birth_date,
            profile_picture_attachment_id: value.profile_picture_attachment_id,
            is_deleted: value.is_deleted,
            created_at: value.created_at,
            updated_at: value.updated_at,
        }
    }
}

/// Open contacts context for web.
#[wasm_bindgen]
pub async fn contacts_open_ctx(input: JsValue) -> Result<ContactsCtxHandle, ContactsError> {
    let input: OpenContactsCtxJsInput = swb::from_value(input)?;
    let master_key = crypto::decode_b64(&input.master_key_b64).map_err(|e| ContactsError {
        code: "decode".to_string(),
        message: e.to_string(),
    })?;

    let result = ContactsCtx::open(OpenContactsCtxInput {
        base_url: input.base_url,
        auth_token: input.auth_token,
        user_id: input.user_id,
        master_key,
        cached_root_key: input.cached_root_key,
        user_agent: input.user_agent,
        client_package: input.client_package,
        client_version: input.client_version,
    })
    .await?;

    Ok(ContactsCtxHandle { inner: result.ctx })
}

/// Handle to an open contacts context.
#[wasm_bindgen]
pub struct ContactsCtxHandle {
    inner: ContactsCtx,
}

#[wasm_bindgen]
impl ContactsCtxHandle {
    /// Update auth token without rebuilding the contacts context.
    pub fn update_auth_token(&self, auth_token: String) {
        self.inner.update_auth_token(auth_token);
    }

    /// Return the wrapped root key currently held by this context.
    pub fn current_wrapped_root_key(&self) -> Result<JsValue, ContactsError> {
        swb::to_value(&self.inner.current_wrapped_root_key()).map_err(Into::into)
    }

    /// Pull a diff page of contacts.
    pub async fn get_diff(&self, since_time: i64, limit: u16) -> Result<JsValue, ContactsError> {
        let diff: Vec<ContactRecordJs> = self
            .inner
            .get_diff(since_time, limit)
            .await?
            .into_iter()
            .map(Into::into)
            .collect();
        swb::to_value(&diff).map_err(Into::into)
    }

    /// Fetch and decrypt the profile picture bytes for a contact.
    pub async fn get_profile_picture(&self, contact_id: &str) -> Result<Vec<u8>, ContactsError> {
        self.inner
            .get_profile_picture(contact_id)
            .await
            .map_err(Into::into)
    }
}
