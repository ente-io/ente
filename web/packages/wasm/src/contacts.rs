//! WASM bindings for contacts sync and attachment reads.

use ente_contacts::{
    ContactsCtx, ContactsError as CoreContactsError, LegacyContactState, OpenContactsCtxInput,
    RootKeySource, WrappedRootContactKey,
};
use ente_core::{auth::KeyAttributes, crypto};
use js_sys::{Object, Reflect};
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
            CoreContactsError::Auth(_) => "auth",
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
    cached_wrapped_root_contact_key: Option<WrappedRootContactKey>,
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

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct LegacyRecoveryBundleJs {
    recovery_key: String,
    user_key_attributes: KeyAttributes,
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
pub async fn contacts_open_ctx(input: JsValue) -> Result<JsValue, ContactsError> {
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
        cached_wrapped_root_contact_key: input.cached_wrapped_root_contact_key,
        user_agent: input.user_agent,
        client_package: input.client_package,
        client_version: input.client_version,
    })
    .await?;

    let output = Object::new();
    Reflect::set(
        &output,
        &JsValue::from_str("ctx"),
        &JsValue::from(ContactsCtxHandle { inner: result.ctx }),
    )
    .expect("setting ctx should not fail");
    Reflect::set(
        &output,
        &JsValue::from_str("wrappedRootContactKey"),
        &swb::to_value(&result.wrapped_root_contact_key).map_err(ContactsError::from)?,
    )
    .expect("setting wrappedRootContactKey should not fail");
    Reflect::set(
        &output,
        &JsValue::from_str("rootKeySource"),
        &JsValue::from_str(match result.root_key_source {
            RootKeySource::Cache => "cache",
            RootKeySource::Unresolved => "unresolved",
        }),
    )
    .expect("setting rootKeySource should not fail");

    Ok(output.into())
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

    /// Return the wrapped root key currently held by this context, if resolved.
    pub fn current_wrapped_root_contact_key(&self) -> Result<JsValue, ContactsError> {
        swb::to_value(&self.inner.current_wrapped_root_contact_key()).map_err(Into::into)
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

    /// Fetch legacy/emergency contact info for the current user.
    pub async fn legacy_get_info(&self) -> Result<JsValue, ContactsError> {
        let info = self.inner.legacy_info().await?;
        swb::to_value(&info).map_err(Into::into)
    }

    /// Lookup a user's public key by email for legacy verify/add flows.
    pub async fn legacy_public_key(&self, email: String) -> Result<JsValue, ContactsError> {
        let public_key = self.inner.legacy_public_key(&email).await?;
        swb::to_value(&public_key).map_err(Into::into)
    }

    /// Generate the mnemonic-style verification ID for a public key.
    pub fn legacy_verification_id(&self, public_key_b64: String) -> Result<String, ContactsError> {
        self.inner
            .legacy_verification_id(&public_key_b64)
            .map_err(Into::into)
    }

    /// Add a trusted legacy contact after sealing the current user's recovery key in Rust.
    pub async fn legacy_add_contact(
        &self,
        email: String,
        current_user_key_attrs: JsValue,
        recovery_notice_in_days: Option<i32>,
    ) -> Result<(), ContactsError> {
        let current_user_key_attrs: KeyAttributes = swb::from_value(current_user_key_attrs)?;
        self.inner
            .legacy_add_contact(&email, &current_user_key_attrs, recovery_notice_in_days)
            .await
            .map_err(Into::into)
    }

    /// Update a legacy contact relationship state.
    pub async fn legacy_update_contact(
        &self,
        user_id: i64,
        emergency_contact_id: i64,
        state: JsValue,
    ) -> Result<(), ContactsError> {
        let state: LegacyContactState = swb::from_value(state)?;
        self.inner
            .legacy_update_contact(user_id, emergency_contact_id, state)
            .await
            .map_err(Into::into)
    }

    /// Update the notice period for an existing trusted contact.
    pub async fn legacy_update_recovery_notice(
        &self,
        emergency_contact_id: i64,
        recovery_notice_in_days: i32,
    ) -> Result<(), ContactsError> {
        self.inner
            .legacy_update_recovery_notice(emergency_contact_id, recovery_notice_in_days)
            .await
            .map_err(Into::into)
    }

    /// Start a recovery flow as the trusted contact.
    pub async fn legacy_start_recovery(
        &self,
        user_id: i64,
        emergency_contact_id: i64,
    ) -> Result<(), ContactsError> {
        self.inner
            .legacy_start_recovery(user_id, emergency_contact_id)
            .await
            .map_err(Into::into)
    }

    /// Stop a recovery flow as the trusted contact.
    pub async fn legacy_stop_recovery(
        &self,
        recovery_id: String,
        user_id: i64,
        emergency_contact_id: i64,
    ) -> Result<(), ContactsError> {
        self.inner
            .legacy_stop_recovery(&recovery_id, user_id, emergency_contact_id)
            .await
            .map_err(Into::into)
    }

    /// Reject a recovery flow as the account owner.
    pub async fn legacy_reject_recovery(
        &self,
        recovery_id: String,
        user_id: i64,
        emergency_contact_id: i64,
    ) -> Result<(), ContactsError> {
        self.inner
            .legacy_reject_recovery(&recovery_id, user_id, emergency_contact_id)
            .await
            .map_err(Into::into)
    }

    /// Approve a recovery flow as the account owner.
    pub async fn legacy_approve_recovery(
        &self,
        recovery_id: String,
        user_id: i64,
        emergency_contact_id: i64,
    ) -> Result<(), ContactsError> {
        self.inner
            .legacy_approve_recovery(&recovery_id, user_id, emergency_contact_id)
            .await
            .map_err(Into::into)
    }

    /// Fetch and decrypt the recovery payload for a ready session.
    pub async fn legacy_recovery_bundle(
        &self,
        recovery_id: String,
        current_user_key_attrs: JsValue,
    ) -> Result<JsValue, ContactsError> {
        let current_user_key_attrs: KeyAttributes = swb::from_value(current_user_key_attrs)?;
        let bundle = self
            .inner
            .legacy_recovery_bundle(&recovery_id, &current_user_key_attrs)
            .await?;
        swb::to_value(&LegacyRecoveryBundleJs {
            recovery_key: crypto::encode_b64(bundle.recovery_key.as_ref()),
            user_key_attributes: bundle.user_key_attributes,
        })
        .map_err(Into::into)
    }

    /// Complete the legacy password reset flow fully in Rust.
    pub async fn legacy_change_password(
        &self,
        recovery_id: String,
        current_user_key_attrs: JsValue,
        new_password: String,
    ) -> Result<(), ContactsError> {
        let current_user_key_attrs: KeyAttributes = swb::from_value(current_user_key_attrs)?;
        self.inner
            .legacy_change_password(&recovery_id, &current_user_key_attrs, &new_password)
            .await
            .map_err(Into::into)
    }
}
