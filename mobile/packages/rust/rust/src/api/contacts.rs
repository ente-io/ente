//! FRB bindings for contacts APIs.

use std::sync::Arc;

use ente_contacts::{
    AttachmentType as CoreAttachmentType, ContactData as CoreContactData,
    ContactRecord as CoreContactRecord, ContactsCtx as CoreContactsCtx,
    ContactsError as CoreContactsError, OpenContactsCtxInput as CoreOpenContactsCtxInput,
    RootKeySource as CoreRootKeySource, WrappedRootContactKey as CoreWrappedRootContactKey,
};
use flutter_rust_bridge::frb;

#[frb]
/// Contact API errors exposed over Flutter Rust Bridge.
pub enum ContactsError {
    /// API HTTP error with status and message.
    Http {
        /// Error response body or summary message.
        message: String,
        /// HTTP status code returned by the API.
        status: u16,
    },
    /// Network transport error.
    Network {
        /// Underlying network error description.
        message: String,
    },
    /// Response or payload parse error.
    Parse {
        /// Parse failure description.
        message: String,
    },
    /// Invalid request or base URL error.
    InvalidUrl {
        /// Invalid URL description.
        message: String,
    },
    /// Cryptographic operation failed.
    Crypto {
        /// Cryptographic error description.
        message: String,
    },
    /// Input validation failed.
    InvalidInput {
        /// Validation failure description.
        message: String,
    },
    /// Missing encrypted contact payload on a live contact response.
    MissingEncryptedData,
    /// Missing encrypted contact key on a live contact response.
    MissingEncryptedKey,
    /// Contact profile picture does not exist.
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
/// Persistable wrapped root contact key returned from Rust.
pub struct WrappedRootContactKey {
    /// Wrapped root contact key bytes encoded as base64.
    pub encrypted_key: String,
    /// Blob header used to unwrap the root contact key.
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
/// Encrypted contact payload fields managed by the client.
pub struct ContactData {
    /// User id of the contact being referenced.
    pub contact_user_id: i64,
    /// User-chosen display name for the contact.
    pub name: String,
    /// Optional birthday in `yyyy-MM-dd` format.
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
/// Fully decoded contact record returned by Rust.
pub struct ContactRecord {
    /// Stable contact entity id.
    pub id: String,
    /// User id of the referenced contact.
    pub contact_user_id: i64,
    /// Server-resolved mutable email for the referenced user.
    pub email: Option<String>,
    /// Client-managed display name from the encrypted payload.
    pub name: Option<String>,
    /// Optional birthday from the encrypted payload.
    pub birth_date: Option<String>,
    /// Current profile picture attachment id, if any.
    pub profile_picture_attachment_id: Option<String>,
    /// Whether this record is a tombstone.
    pub is_deleted: bool,
    /// Contact creation timestamp in microseconds.
    pub created_at: i64,
    /// Last update timestamp in microseconds.
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
/// Source used to obtain the root contact key during open.
pub enum RootKeySource {
    /// Reused the caller-provided cached wrapped root key.
    Cache,
    /// Fetched the wrapped root key from the server.
    Server,
    /// Created a new wrapped root key on the server.
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
#[derive(Clone, Copy)]
/// Attachment types supported by the contacts subsystem.
pub enum AttachmentType {
    /// Current contact profile picture.
    ProfilePicture,
}

impl From<AttachmentType> for CoreAttachmentType {
    fn from(value: AttachmentType) -> Self {
        match value {
            AttachmentType::ProfilePicture => CoreAttachmentType::ProfilePicture,
        }
    }
}

#[frb]
/// Input required to open an account-scoped contacts context.
pub struct OpenContactsCtxInput {
    /// Base Ente API URL.
    pub base_url: String,
    /// Auth token for Ente API requests.
    pub auth_token: String,
    /// Logged-in owner user id.
    pub user_id: i64,
    /// Logged-in account key used to unwrap or create the root contact key.
    pub master_key: Vec<u8>,
    /// Optional cached wrapped root key for the current user.
    pub cached_root_key: Option<WrappedRootContactKey>,
    /// Optional user agent to send to Ente API endpoints.
    pub user_agent: Option<String>,
    /// Optional client package header to send to Ente API endpoints.
    pub client_package: Option<String>,
    /// Optional client version header to send to Ente API endpoints.
    pub client_version: Option<String>,
}

#[frb]
/// Result returned when opening a contacts context.
pub struct OpenContactsCtxResult {
    /// Opaque contacts context bound to the current account/session.
    pub ctx: ContactsCtx,
    /// Current wrapped root key that the caller may persist.
    pub wrapped_root_key: WrappedRootContactKey,
    /// Source used to obtain the root key during open.
    pub root_key_source: RootKeySource,
}

#[frb(opaque)]
#[derive(Clone)]
/// Opaque account-scoped contacts context exposed to Flutter.
pub struct ContactsCtx {
    inner: Arc<CoreContactsCtx>,
}

#[frb]
/// Open a contacts context for the current account.
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
    /// Return the owner user id for this contacts context.
    pub fn user_id(&self) -> i64 {
        self.inner.user_id()
    }

    /// Replace the auth token used for subsequent API requests.
    pub fn update_auth_token(&self, auth_token: String) {
        self.inner.update_auth_token(auth_token);
    }

    #[frb(sync)]
    /// Return the current wrapped root key for caller-managed persistence.
    pub fn current_wrapped_root_key(&self) -> WrappedRootContactKey {
        self.inner.current_wrapped_root_key().into()
    }

    /// Create a contact for the referenced user.
    pub async fn create_contact(&self, data: ContactData) -> Result<ContactRecord, ContactsError> {
        self.inner
            .create_contact(&data.into())
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    /// Fetch a single contact by id.
    pub async fn get_contact(&self, contact_id: String) -> Result<ContactRecord, ContactsError> {
        self.inner
            .get_contact(&contact_id)
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    /// Fetch a contacts diff since the provided timestamp.
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

    /// Update the encrypted payload for an existing contact.
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

    /// Tombstone a contact by id.
    pub async fn delete_contact(&self, contact_id: String) -> Result<(), ContactsError> {
        self.inner
            .delete_contact(&contact_id)
            .await
            .map_err(Into::into)
    }

    /// Encrypt and upload a new contact profile picture.
    pub async fn set_attachment(
        &self,
        contact_id: String,
        attachment_type: AttachmentType,
        attachment_bytes: Vec<u8>,
    ) -> Result<ContactRecord, ContactsError> {
        self.inner
            .set_attachment(&contact_id, attachment_type.into(), &attachment_bytes)
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    /// Download an attachment by type and attachment id.
    pub async fn get_attachment(
        &self,
        attachment_type: AttachmentType,
        attachment_id: String,
    ) -> Result<Vec<u8>, ContactsError> {
        self.inner
            .get_attachment(attachment_type.into(), &attachment_id)
            .await
            .map_err(Into::into)
    }

    /// Remove the current attachment for a contact and type.
    pub async fn delete_attachment(
        &self,
        contact_id: String,
        attachment_type: AttachmentType,
    ) -> Result<ContactRecord, ContactsError> {
        self.inner
            .delete_attachment(&contact_id, attachment_type.into())
            .await
            .map(Into::into)
            .map_err(Into::into)
    }

    /// Encrypt and upload a new contact profile picture.
    pub async fn set_profile_picture(
        &self,
        contact_id: String,
        profile_picture: Vec<u8>,
    ) -> Result<ContactRecord, ContactsError> {
        self.set_attachment(contact_id, AttachmentType::ProfilePicture, profile_picture)
            .await
    }

    /// Download and decrypt the current contact profile picture.
    pub async fn get_profile_picture(&self, contact_id: String) -> Result<Vec<u8>, ContactsError> {
        self.inner
            .get_profile_picture(&contact_id)
            .await
            .map_err(Into::into)
    }

    /// Remove the current contact profile picture.
    pub async fn delete_profile_picture(
        &self,
        contact_id: String,
    ) -> Result<ContactRecord, ContactsError> {
        self.delete_attachment(contact_id, AttachmentType::ProfilePicture)
            .await
    }
}
