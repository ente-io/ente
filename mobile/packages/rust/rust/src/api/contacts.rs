//! FRB bindings for contacts APIs.

use std::sync::Arc;

use ente_contacts::{
    ContactData as CoreContactData, ContactRecord as CoreContactRecord,
    ContactsCtx as CoreContactsCtx, ContactsError as CoreContactsError,
    OpenContactsCtxInput as CoreOpenContactsCtxInput, RootKeySource as CoreRootKeySource,
    WrappedRootContactKey as CoreWrappedRootContactKey,
};
use flutter_rust_bridge::frb;

#[frb]
pub enum ContactsError {
    Http { message: String, status: u16 },
    Network { message: String },
    Parse { message: String },
    InvalidUrl { message: String },
    Crypto { message: String },
    InvalidInput { message: String },
    MissingEncryptedData,
    MissingEncryptedKey,
    ProfilePictureNotFound,
}

impl From<CoreContactsError> for ContactsError {
    fn from(value: CoreContactsError) -> Self {
        match value {
            CoreContactsError::Http(ente_core::http::Error::Http { status, message }) => {
                ContactsError::Http { message, status }
            }
            CoreContactsError::Http(ente_core::http::Error::Network(message)) => {
                ContactsError::Network { message }
            }
            CoreContactsError::Http(ente_core::http::Error::Parse(message)) => {
                ContactsError::Parse { message }
            }
            CoreContactsError::Http(ente_core::http::Error::InvalidUrl(message)) => {
                ContactsError::InvalidUrl { message }
            }
            CoreContactsError::Crypto(message) => ContactsError::Crypto {
                message: message.to_string(),
            },
            CoreContactsError::InvalidInput(message) => ContactsError::InvalidInput { message },
            CoreContactsError::MissingEncryptedData => ContactsError::MissingEncryptedData,
            CoreContactsError::MissingEncryptedKey => ContactsError::MissingEncryptedKey,
            CoreContactsError::ProfilePictureNotFound => ContactsError::ProfilePictureNotFound,
        }
    }
}

#[frb]
#[derive(Clone)]
pub struct WrappedRootContactKey {
    pub encrypted_key: String,
    pub header: String,
}

impl From<CoreWrappedRootContactKey> for WrappedRootContactKey {
    fn from(value: CoreWrappedRootContactKey) -> Self {
        Self {
            encrypted_key: value.encrypted_key,
            header: value.header,
        }
    }
}

impl From<WrappedRootContactKey> for CoreWrappedRootContactKey {
    fn from(value: WrappedRootContactKey) -> Self {
        Self {
            encrypted_key: value.encrypted_key,
            header: value.header,
        }
    }
}

#[frb]
#[derive(Clone)]
pub struct ContactData {
    pub contact_user_id: i64,
    pub name: String,
    pub birth_date: Option<String>,
}

impl From<ContactData> for CoreContactData {
    fn from(value: ContactData) -> Self {
        Self {
            contact_user_id: value.contact_user_id,
            name: value.name,
            birth_date: value.birth_date,
        }
    }
}

#[frb]
#[derive(Clone)]
pub struct ContactRecord {
    pub id: String,
    pub contact_user_id: i64,
    pub email: Option<String>,
    pub name: Option<String>,
    pub birth_date: Option<String>,
    pub profile_picture_attachment_id: Option<String>,
    pub is_deleted: bool,
    pub created_at: i64,
    pub updated_at: i64,
}

impl From<CoreContactRecord> for ContactRecord {
    fn from(value: CoreContactRecord) -> Self {
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

#[frb]
#[derive(Clone)]
pub enum RootKeySource {
    Cache,
    Server,
    Created,
}

impl From<CoreRootKeySource> for RootKeySource {
    fn from(value: CoreRootKeySource) -> Self {
        match value {
            CoreRootKeySource::Cache => RootKeySource::Cache,
            CoreRootKeySource::Server => RootKeySource::Server,
            CoreRootKeySource::Created => RootKeySource::Created,
        }
    }
}

#[frb]
pub struct OpenContactsCtxInput {
    pub base_url: String,
    pub auth_token: String,
    pub user_id: i64,
    pub master_key: Vec<u8>,
    pub cached_root_key: Option<WrappedRootContactKey>,
    pub user_agent: Option<String>,
    pub client_package: Option<String>,
    pub client_version: Option<String>,
}

#[frb]
pub struct OpenContactsCtxResult {
    pub ctx: ContactsCtx,
    pub wrapped_root_key: WrappedRootContactKey,
    pub root_key_source: RootKeySource,
}

#[frb(opaque)]
#[derive(Clone)]
pub struct ContactsCtx {
    inner: Arc<CoreContactsCtx>,
}

#[frb]
pub async fn open_contacts_ctx(
    input: OpenContactsCtxInput,
) -> Result<OpenContactsCtxResult, ContactsError> {
    let opened = CoreContactsCtx::open(CoreOpenContactsCtxInput {
        base_url: input.base_url,
        auth_token: input.auth_token,
        user_id: input.user_id,
        master_key: input.master_key,
        cached_root_key: input.cached_root_key.map(Into::into),
        user_agent: input.user_agent,
        client_package: input.client_package,
        client_version: input.client_version,
    })
    .await
    .map_err(ContactsError::from)?;

    Ok(OpenContactsCtxResult {
        ctx: ContactsCtx {
            inner: Arc::new(opened.ctx),
        },
        wrapped_root_key: opened.wrapped_root_key.into(),
        root_key_source: opened.root_key_source.into(),
    })
}

impl ContactsCtx {
    #[frb(sync)]
    pub fn user_id(&self) -> i64 {
        self.inner.user_id()
    }

    pub fn update_auth_token(&self, auth_token: String) {
        self.inner.update_auth_token(auth_token);
    }

    #[frb(sync)]
    pub fn current_wrapped_root_key(&self) -> WrappedRootContactKey {
        self.inner.current_wrapped_root_key().into()
    }

    pub async fn create_contact(&self, data: ContactData) -> Result<ContactRecord, ContactsError> {
        self.inner
            .create_contact(&data.into())
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    pub async fn get_contact(&self, contact_id: String) -> Result<ContactRecord, ContactsError> {
        self.inner
            .get_contact(&contact_id)
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    pub async fn get_diff(
        &self,
        since_time: i64,
        limit: u16,
    ) -> Result<Vec<ContactRecord>, ContactsError> {
        self.inner
            .get_diff(since_time, limit)
            .await
            .map(|records| records.into_iter().map(Into::into).collect())
            .map_err(Into::into)
    }

    pub async fn update_contact(
        &self,
        contact_id: String,
        data: ContactData,
    ) -> Result<ContactRecord, ContactsError> {
        self.inner
            .update_contact(&contact_id, &data.into())
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    pub async fn delete_contact(&self, contact_id: String) -> Result<(), ContactsError> {
        self.inner
            .delete_contact(&contact_id)
            .await
            .map_err(Into::into)
    }

    pub async fn set_profile_picture(
        &self,
        contact_id: String,
        profile_picture: Vec<u8>,
    ) -> Result<ContactRecord, ContactsError> {
        self.inner
            .set_profile_picture(&contact_id, &profile_picture)
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    pub async fn get_profile_picture(&self, contact_id: String) -> Result<Vec<u8>, ContactsError> {
        self.inner
            .get_profile_picture(&contact_id)
            .await
            .map_err(Into::into)
    }

    pub async fn delete_profile_picture(
        &self,
        contact_id: String,
    ) -> Result<ContactRecord, ContactsError> {
        self.inner
            .delete_profile_picture(&contact_id)
            .await
            .map(Into::into)
            .map_err(Into::into)
    }
}
