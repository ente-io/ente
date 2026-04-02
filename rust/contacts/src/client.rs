use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, RwLock};

use ente_core::crypto::{SecretVec, keys};
use ente_core::http::{Error as HttpError, HttpClient, HttpConfig};

use crate::crypto as contacts_crypto;
use crate::error::{ContactsError, Result};
use crate::models::{ContactData, ContactRecord, WrappedRootContactKey};
use crate::transport::{
    CommitProfilePictureRequest, ContactDiffResponse, ContactEntityResponse, CreateContactRequest,
    CreateRootKeyRequest, ProfilePictureUploadUrlRequest, ProfilePictureUploadUrlResponse,
    RootKeyResponse, SignedUrlResponse, UpdateContactRequest,
};

const CONTACT_TYPE: &str = "contact";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RootKeySource {
    Cache,
    Server,
    Created,
}

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

pub struct OpenContactsCtxResult {
    pub ctx: ContactsCtx,
    pub wrapped_root_key: WrappedRootContactKey,
    pub root_key_source: RootKeySource,
}

pub struct ContactsCtx {
    user_id: i64,
    http: HttpClient,
    master_key: Arc<RwLock<SecretVec>>,
    root_contact_key: Arc<RwLock<SecretVec>>,
    wrapped_root_key: Arc<RwLock<WrappedRootContactKey>>,
    root_key_confirmed: AtomicBool,
}

impl ContactsCtx {
    pub async fn open(input: OpenContactsCtxInput) -> Result<OpenContactsCtxResult> {
        let http = HttpClient::new_with_config(HttpConfig {
            base_url: input.base_url,
            auth_token: Some(input.auth_token),
            user_agent: input.user_agent,
            client_package: input.client_package,
            client_version: input.client_version,
            timeout_secs: Some(30),
        })?;

        let (root_contact_key, wrapped_root_key, root_key_source, root_key_confirmed) =
            if let Some(cached_root_key) = input.cached_root_key {
                let root_contact_key =
                    contacts_crypto::decrypt_root_contact_key(&cached_root_key, &input.master_key)?;
                (
                    root_contact_key,
                    cached_root_key,
                    RootKeySource::Cache,
                    false,
                )
            } else if let Some(remote_root_key) = fetch_root_key(&http).await? {
                let wrapped_root_key = WrappedRootContactKey {
                    encrypted_key: remote_root_key.encrypted_key,
                    header: remote_root_key.header,
                };
                let root_contact_key = contacts_crypto::decrypt_root_contact_key(
                    &wrapped_root_key,
                    &input.master_key,
                )?;
                (
                    root_contact_key,
                    wrapped_root_key,
                    RootKeySource::Server,
                    true,
                )
            } else {
                let root_contact_key = keys::generate_key();
                let wrapped_root_key = contacts_crypto::encrypt_root_contact_key(
                    &root_contact_key,
                    &input.master_key,
                )?;
                create_root_key(&http, &wrapped_root_key).await?;
                (
                    root_contact_key,
                    wrapped_root_key,
                    RootKeySource::Created,
                    true,
                )
            };

        let ctx = Self {
            user_id: input.user_id,
            http,
            master_key: Arc::new(RwLock::new(SecretVec::new(input.master_key))),
            root_contact_key: Arc::new(RwLock::new(SecretVec::new(root_contact_key))),
            wrapped_root_key: Arc::new(RwLock::new(wrapped_root_key.clone())),
            root_key_confirmed: AtomicBool::new(root_key_confirmed),
        };

        Ok(OpenContactsCtxResult {
            ctx,
            wrapped_root_key,
            root_key_source,
        })
    }

    pub fn user_id(&self) -> i64 {
        self.user_id
    }

    pub fn update_auth_token(&self, auth_token: String) {
        self.http.set_auth_token(Some(auth_token));
    }

    pub fn current_wrapped_root_key(&self) -> WrappedRootContactKey {
        self.wrapped_root_key
            .read()
            .expect("wrapped root key lock poisoned")
            .clone()
    }

    pub async fn create_contact(&self, data: &ContactData) -> Result<ContactRecord> {
        contacts_crypto::validate_contact_data(data)?;
        self.ensure_root_key_confirmed().await?;

        let contact_key = keys::generate_stream_key();
        let wrapped_contact_key = {
            let root_contact_key = self
                .root_contact_key
                .read()
                .expect("root contact key lock poisoned");
            contacts_crypto::wrap_contact_key(&contact_key, &root_contact_key)?
        };
        let encrypted_data = contacts_crypto::encrypt_contact_data(data, &contact_key)?;
        let response = self
            .http
            .post_json::<ContactEntityResponse, _>(
                "/contacts",
                &CreateContactRequest {
                    contact_user_id: data.contact_user_id,
                    encrypted_key: &wrapped_contact_key,
                    encrypted_data: &encrypted_data,
                },
            )
            .await?;

        self.decode_contact(response)
    }

    pub async fn get_contact(&self, contact_id: &str) -> Result<ContactRecord> {
        let response = self
            .http
            .get_json::<ContactEntityResponse>(&format!("/contacts/{contact_id}"), &[])
            .await?;
        self.decode_contact(response)
    }

    pub async fn get_diff(&self, since_time: i64, limit: u16) -> Result<Vec<ContactRecord>> {
        let response = self
            .http
            .get_json::<ContactDiffResponse>(
                "/contacts/diff",
                &[
                    ("sinceTime", since_time.to_string()),
                    ("limit", limit.to_string()),
                ],
            )
            .await?;

        response
            .diff
            .into_iter()
            .map(|entity| self.decode_contact(entity))
            .collect()
    }

    pub async fn update_contact(
        &self,
        contact_id: &str,
        data: &ContactData,
    ) -> Result<ContactRecord> {
        contacts_crypto::validate_contact_data(data)?;
        self.ensure_root_key_confirmed().await?;

        let current = self
            .http
            .get_json::<ContactEntityResponse>(&format!("/contacts/{contact_id}"), &[])
            .await?;
        let encrypted_key = current
            .encrypted_key
            .as_deref()
            .ok_or(ContactsError::MissingEncryptedKey)?;
        let contact_key = {
            let root_contact_key = self
                .root_contact_key
                .read()
                .expect("root contact key lock poisoned");
            contacts_crypto::unwrap_contact_key(encrypted_key, &root_contact_key)?
        };
        let encrypted_data = contacts_crypto::encrypt_contact_data(data, &contact_key)?;

        let response = self
            .http
            .put_json::<ContactEntityResponse, _>(
                &format!("/contacts/{contact_id}"),
                &UpdateContactRequest {
                    contact_user_id: data.contact_user_id,
                    encrypted_data: &encrypted_data,
                },
            )
            .await?;

        self.decode_contact(response)
    }

    pub async fn delete_contact(&self, contact_id: &str) -> Result<()> {
        self.ensure_root_key_confirmed().await?;
        self.http
            .delete_empty(&format!("/contacts/{contact_id}"), &[])
            .await?;
        Ok(())
    }

    pub async fn set_profile_picture(
        &self,
        contact_id: &str,
        profile_picture: &[u8],
    ) -> Result<ContactRecord> {
        self.ensure_root_key_confirmed().await?;

        let current = self
            .http
            .get_json::<ContactEntityResponse>(&format!("/contacts/{contact_id}"), &[])
            .await?;
        let encrypted_key = current
            .encrypted_key
            .as_deref()
            .ok_or(ContactsError::MissingEncryptedKey)?;
        let contact_key = {
            let root_contact_key = self
                .root_contact_key
                .read()
                .expect("root contact key lock poisoned");
            contacts_crypto::unwrap_contact_key(encrypted_key, &root_contact_key)?
        };
        let encrypted_picture =
            contacts_crypto::encrypt_profile_picture(profile_picture, &contact_key)?;
        let content_md5 = contacts_crypto::content_md5_base64(&encrypted_picture);

        let upload = self
            .http
            .post_json::<ProfilePictureUploadUrlResponse, _>(
                &format!("/contacts/{contact_id}/profile-picture/upload-url"),
                &ProfilePictureUploadUrlRequest {
                    content_length: encrypted_picture.len() as i64,
                    content_md5: content_md5.clone(),
                },
            )
            .await?;

        self.http
            .put_bytes(
                &upload.url,
                &encrypted_picture,
                &[("Content-MD5", content_md5)],
            )
            .await?;

        let response = self
            .http
            .put_json::<ContactEntityResponse, _>(
                &format!("/contacts/{contact_id}/profile-picture"),
                &CommitProfilePictureRequest {
                    attachment_id: &upload.attachment_id,
                    size: encrypted_picture.len() as i64,
                },
            )
            .await?;

        self.decode_contact(response)
    }

    pub async fn get_profile_picture(&self, contact_id: &str) -> Result<Vec<u8>> {
        let current = self
            .http
            .get_json::<ContactEntityResponse>(&format!("/contacts/{contact_id}"), &[])
            .await?;
        if current.is_deleted || current.profile_picture_attachment_id.is_none() {
            return Err(ContactsError::ProfilePictureNotFound);
        }

        let encrypted_key = current
            .encrypted_key
            .as_deref()
            .ok_or(ContactsError::MissingEncryptedKey)?;
        let contact_key = {
            let root_contact_key = self
                .root_contact_key
                .read()
                .expect("root contact key lock poisoned");
            contacts_crypto::unwrap_contact_key(encrypted_key, &root_contact_key)?
        };
        let download = self
            .http
            .get_json::<SignedUrlResponse>(&format!("/contacts/{contact_id}/profile-picture"), &[])
            .await?;
        let encrypted_picture = self.http.get_bytes(&download.url).await?;
        contacts_crypto::decrypt_profile_picture(&encrypted_picture, &contact_key)
    }

    pub async fn delete_profile_picture(&self, contact_id: &str) -> Result<ContactRecord> {
        self.ensure_root_key_confirmed().await?;
        let response = self
            .http
            .delete_json::<ContactEntityResponse>(
                &format!("/contacts/{contact_id}/profile-picture"),
                &[],
            )
            .await?;
        self.decode_contact(response)
    }

    fn decode_contact(&self, entity: ContactEntityResponse) -> Result<ContactRecord> {
        if entity.is_deleted {
            return Ok(ContactRecord {
                id: entity.id,
                contact_user_id: entity.contact_user_id,
                email: None,
                name: None,
                birth_date: None,
                profile_picture_attachment_id: None,
                is_deleted: true,
                created_at: entity.created_at,
                updated_at: entity.updated_at,
            });
        }

        let encrypted_key = entity
            .encrypted_key
            .as_deref()
            .ok_or(ContactsError::MissingEncryptedKey)?;
        let encrypted_data = entity
            .encrypted_data
            .as_deref()
            .ok_or(ContactsError::MissingEncryptedData)?;
        let root_contact_key = self
            .root_contact_key
            .read()
            .expect("root contact key lock poisoned");
        let contact_key = contacts_crypto::unwrap_contact_key(encrypted_key, &root_contact_key)?;
        let data = contacts_crypto::decrypt_contact_data(encrypted_data, &contact_key)?;

        Ok(ContactRecord {
            id: entity.id,
            contact_user_id: entity.contact_user_id,
            email: entity.email,
            name: Some(data.name),
            birth_date: data.birth_date,
            profile_picture_attachment_id: entity.profile_picture_attachment_id,
            is_deleted: false,
            created_at: entity.created_at,
            updated_at: entity.updated_at,
        })
    }

    async fn ensure_root_key_confirmed(&self) -> Result<()> {
        if self.root_key_confirmed.load(Ordering::Acquire) {
            return Ok(());
        }

        if let Some(remote_root_key) = fetch_root_key(&self.http).await? {
            let wrapped_root_key = WrappedRootContactKey {
                encrypted_key: remote_root_key.encrypted_key,
                header: remote_root_key.header,
            };
            let master_key = self.master_key.read().expect("master key lock poisoned");
            let decrypted_root_key =
                contacts_crypto::decrypt_root_contact_key(&wrapped_root_key, &master_key)?;
            *self
                .root_contact_key
                .write()
                .expect("root contact key lock poisoned") = SecretVec::new(decrypted_root_key);
            *self
                .wrapped_root_key
                .write()
                .expect("wrapped root key lock poisoned") = wrapped_root_key;
        } else {
            let wrapped_root_key = self.current_wrapped_root_key();
            create_root_key(&self.http, &wrapped_root_key).await?;
        }

        self.root_key_confirmed.store(true, Ordering::Release);
        Ok(())
    }
}

async fn fetch_root_key(http: &HttpClient) -> Result<Option<RootKeyResponse>> {
    http.get_json_optional("/user-entity/key", &[("type", CONTACT_TYPE.to_string())])
        .await
        .map_err(Into::into)
}

async fn create_root_key(
    http: &HttpClient,
    wrapped_root_key: &WrappedRootContactKey,
) -> Result<()> {
    let request = CreateRootKeyRequest {
        r#type: CONTACT_TYPE,
        encrypted_key: &wrapped_root_key.encrypted_key,
        header: &wrapped_root_key.header,
    };

    match http.post_empty("/user-entity/key", &request).await {
        Ok(()) => Ok(()),
        Err(HttpError::Http { .. }) => {
            if fetch_root_key(http).await?.is_some() {
                Ok(())
            } else {
                Err(HttpError::Http {
                    status: 500,
                    message: "failed to create root contact key".to_string(),
                }
                .into())
            }
        }
        Err(err) => Err(err.into()),
    }
}
