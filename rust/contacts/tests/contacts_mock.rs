use ente_contacts::client::{ContactsCtx, OpenContactsCtxInput, RootKeySource};
use ente_contacts::crypto as contacts_crypto;
use ente_contacts::models::{ContactData, WrappedRootContactKey};
use ente_core::crypto::{encode_b64, keys};
use md5::Digest;
use mockito::{Matcher, Server};

fn sample_contact() -> ContactData {
    ContactData {
        contact_user_id: 42,
        name: "B Test".to_string(),
        birth_date: Some("2001-04-01".to_string()),
    }
}

fn open_input(base_url: String, master_key: Vec<u8>) -> OpenContactsCtxInput {
    OpenContactsCtxInput {
        base_url,
        auth_token: "auth-token".to_string(),
        user_id: 7,
        master_key,
        cached_root_key: None,
        user_agent: Some("ente-contacts-test".to_string()),
        client_package: Some("io.ente.photos".to_string()),
        client_version: Some("1.0.0".to_string()),
    }
}

fn wrap_root(root_key: &[u8], master_key: &[u8]) -> WrappedRootContactKey {
    contacts_crypto::encrypt_root_contact_key(root_key, master_key).unwrap()
}

fn live_entity_json(
    id: &str,
    data: &ContactData,
    email: Option<&str>,
    root_key: &[u8],
    profile_picture_attachment_id: Option<&str>,
) -> serde_json::Value {
    let contact_key = keys::generate_stream_key();
    let encrypted_key = contacts_crypto::wrap_contact_key(&contact_key, root_key).unwrap();
    let encrypted_data = contacts_crypto::encrypt_contact_data(data, &contact_key).unwrap();

    serde_json::json!({
        "id": id,
        "contactUserID": data.contact_user_id,
        "email": email,
        "profilePictureAttachmentID": profile_picture_attachment_id,
        "encryptedKey": encrypted_key,
        "encryptedData": encrypted_data,
        "isDeleted": false,
        "createdAt": 100,
        "updatedAt": 200
    })
}

#[tokio::test]
async fn open_fetches_existing_root_key_from_server() {
    let mut server = Server::new_async().await;
    let master_key = keys::generate_key();
    let root_key = keys::generate_key();
    let wrapped_root = wrap_root(&root_key, &master_key);

    let root_mock = server
        .mock("GET", "/user-entity/key")
        .match_query(Matcher::UrlEncoded("type".into(), "contact".into()))
        .with_status(200)
        .with_body(
            serde_json::json!({
                "userID": 7,
                "type": "contact",
                "encryptedKey": wrapped_root.encrypted_key,
                "header": wrapped_root.header,
                "createdAt": 1
            })
            .to_string(),
        )
        .create_async()
        .await;

    let opened = ContactsCtx::open(open_input(server.url(), master_key.clone()))
        .await
        .unwrap();

    root_mock.assert_async().await;
    assert_eq!(opened.root_key_source, RootKeySource::Server);
    assert_eq!(opened.wrapped_root_key, wrapped_root);
}

#[tokio::test]
async fn create_contact_uses_cached_root_key_but_confirms_before_write() {
    let mut server = Server::new_async().await;
    let master_key = keys::generate_key();
    let root_key = keys::generate_key();
    let wrapped_root = wrap_root(&root_key, &master_key);
    let contact = sample_contact();
    let resolved_email = "b@test.test";

    let root_mock = server
        .mock("GET", "/user-entity/key")
        .match_query(Matcher::UrlEncoded("type".into(), "contact".into()))
        .with_status(200)
        .with_body(
            serde_json::json!({
                "userID": 7,
                "type": "contact",
                "encryptedKey": wrapped_root.encrypted_key,
                "header": wrapped_root.header,
                "createdAt": 1
            })
            .to_string(),
        )
        .expect(1)
        .create_async()
        .await;

    let create_mock = server
        .mock("POST", "/contacts")
        .match_header("x-auth-token", "auth-token")
        .match_body(Matcher::PartialJson(serde_json::json!({
            "contactUserID": contact.contact_user_id
        })))
        .with_status(200)
        .with_body(
            live_entity_json(
                "ct_contact1",
                &contact,
                Some(resolved_email),
                &root_key,
                None,
            )
            .to_string(),
        )
        .expect(1)
        .create_async()
        .await;

    let ctx = ContactsCtx::open(OpenContactsCtxInput {
        cached_root_key: Some(wrapped_root),
        ..open_input(server.url(), master_key)
    })
    .await
    .unwrap()
    .ctx;

    let created = ctx.create_contact(&contact).await.unwrap();

    root_mock.assert_async().await;
    create_mock.assert_async().await;
    assert_eq!(created.id, "ct_contact1");
    assert_eq!(created.contact_user_id, contact.contact_user_id);
    assert_eq!(created.email.as_deref(), Some(resolved_email));
}

#[tokio::test]
async fn set_profile_picture_uses_signed_upload_url_and_commit() {
    let mut server = Server::new_async().await;
    let master_key = keys::generate_key();
    let root_key = keys::generate_key();
    let wrapped_root = wrap_root(&root_key, &master_key);
    let contact = sample_contact();
    let picture_bytes = b"profile-picture-bytes".to_vec();
    let resolved_email = "b@test.test";

    let root_mock = server
        .mock("GET", "/user-entity/key")
        .match_query(Matcher::UrlEncoded("type".into(), "contact".into()))
        .with_status(200)
        .with_body(
            serde_json::json!({
                "userID": 7,
                "type": "contact",
                "encryptedKey": wrapped_root.encrypted_key,
                "header": wrapped_root.header,
                "createdAt": 1
            })
            .to_string(),
        )
        .create_async()
        .await;

    let current_entity = live_entity_json(
        "ct_picture1",
        &contact,
        Some(resolved_email),
        &root_key,
        None,
    );

    let get_contact_for_upload = server
        .mock("GET", "/contacts/ct_picture1")
        .with_status(200)
        .with_body(current_entity.to_string())
        .expect(1)
        .create_async()
        .await;

    let upload_url = format!("{}/upload/ua_picture1", server.url());
    let encrypted_picture = {
        let contact_key = contacts_crypto::unwrap_contact_key(
            current_entity["encryptedKey"].as_str().unwrap(),
            &root_key,
        )
        .unwrap();
        contacts_crypto::encrypt_profile_picture(&picture_bytes, &contact_key).unwrap()
    };
    let _content_md5 = contacts_crypto::content_md5_base64(&encrypted_picture);

    let upload_url_mock = server
        .mock("POST", "/contacts/ct_picture1/profile-picture/upload-url")
        .with_status(200)
        .with_body(
            serde_json::json!({
                "attachmentID": "ua_picture1",
                "url": upload_url
            })
            .to_string(),
        )
        .expect(1)
        .create_async()
        .await;

    let upload_bytes_mock = server
        .mock("PUT", "/upload/ua_picture1")
        .with_status(200)
        .expect(1)
        .create_async()
        .await;

    let attached_entity = live_entity_json(
        "ct_picture1",
        &contact,
        Some(resolved_email),
        &root_key,
        Some("ua_picture1"),
    );
    let commit_mock = server
        .mock("PUT", "/contacts/ct_picture1/profile-picture")
        .with_status(200)
        .with_body(attached_entity.to_string())
        .expect(1)
        .create_async()
        .await;

    let ctx = ContactsCtx::open(open_input(server.url(), master_key))
        .await
        .unwrap()
        .ctx;

    let updated = ctx
        .set_profile_picture("ct_picture1", &picture_bytes)
        .await
        .unwrap();

    root_mock.assert_async().await;
    get_contact_for_upload.assert_async().await;
    upload_url_mock.assert_async().await;
    upload_bytes_mock.assert_async().await;
    commit_mock.assert_async().await;

    assert_eq!(
        updated.profile_picture_attachment_id.as_deref(),
        Some("ua_picture1")
    );
}

#[tokio::test]
async fn get_profile_picture_uses_signed_download_url() {
    let mut server = Server::new_async().await;
    let master_key = keys::generate_key();
    let root_key = keys::generate_key();
    let wrapped_root = wrap_root(&root_key, &master_key);
    let contact = sample_contact();
    let picture_bytes = b"profile-picture-bytes".to_vec();

    let root_mock = server
        .mock("GET", "/user-entity/key")
        .match_query(Matcher::UrlEncoded("type".into(), "contact".into()))
        .with_status(200)
        .with_body(
            serde_json::json!({
                "userID": 7,
                "type": "contact",
                "encryptedKey": wrapped_root.encrypted_key,
                "header": wrapped_root.header,
                "createdAt": 1
            })
            .to_string(),
        )
        .create_async()
        .await;

    let attached_entity = live_entity_json(
        "ct_picture1",
        &contact,
        Some("b@test.test"),
        &root_key,
        Some("ua_picture1"),
    );
    let contact_key = contacts_crypto::unwrap_contact_key(
        attached_entity["encryptedKey"].as_str().unwrap(),
        &root_key,
    )
    .unwrap();
    let encrypted_picture =
        contacts_crypto::encrypt_profile_picture(&picture_bytes, &contact_key).unwrap();

    let get_contact_mock = server
        .mock("GET", "/contacts/ct_picture1")
        .with_status(200)
        .with_body(attached_entity.to_string())
        .expect(1)
        .create_async()
        .await;

    let signed_download_url = format!("{}/download/ua_picture1", server.url());
    let signed_url_mock = server
        .mock("GET", "/contacts/ct_picture1/profile-picture")
        .with_status(200)
        .with_body(
            serde_json::json!({
                "url": signed_download_url
            })
            .to_string(),
        )
        .expect(1)
        .create_async()
        .await;

    let download_mock = server
        .mock("GET", "/download/ua_picture1")
        .with_status(200)
        .with_body(encrypted_picture.clone())
        .expect(1)
        .create_async()
        .await;

    let ctx = ContactsCtx::open(open_input(server.url(), master_key))
        .await
        .unwrap()
        .ctx;

    let downloaded = ctx.get_profile_picture("ct_picture1").await.unwrap();

    root_mock.assert_async().await;
    get_contact_mock.assert_async().await;
    signed_url_mock.assert_async().await;
    download_mock.assert_async().await;
    assert_eq!(downloaded, picture_bytes);
}

#[tokio::test]
async fn deleted_contacts_surface_as_tombstones() {
    let mut server = Server::new_async().await;
    let master_key = keys::generate_key();
    let root_key = keys::generate_key();
    let wrapped_root = wrap_root(&root_key, &master_key);

    let root_mock = server
        .mock("GET", "/user-entity/key")
        .match_query(Matcher::UrlEncoded("type".into(), "contact".into()))
        .with_status(200)
        .with_body(
            serde_json::json!({
                "userID": 7,
                "type": "contact",
                "encryptedKey": wrapped_root.encrypted_key,
                "header": wrapped_root.header,
                "createdAt": 1
            })
            .to_string(),
        )
        .create_async()
        .await;

    let diff_mock = server
        .mock("GET", "/contacts/diff")
        .match_query(Matcher::AllOf(vec![
            Matcher::UrlEncoded("sinceTime".into(), "0".into()),
            Matcher::UrlEncoded("limit".into(), "10".into()),
        ]))
        .with_status(200)
        .with_body(
            serde_json::json!({
                "diff": [{
                    "id": "ct_deleted1",
                    "contactUserID": 42,
                    "profilePictureAttachmentID": null,
                    "encryptedKey": null,
                    "encryptedData": null,
                    "isDeleted": true,
                    "createdAt": 100,
                    "updatedAt": 200
                }]
            })
            .to_string(),
        )
        .expect(1)
        .create_async()
        .await;

    let ctx = ContactsCtx::open(open_input(server.url(), master_key))
        .await
        .unwrap()
        .ctx;
    let diff = ctx.get_diff(0, 10).await.unwrap();

    root_mock.assert_async().await;
    diff_mock.assert_async().await;
    assert_eq!(diff.len(), 1);
    assert!(diff[0].is_deleted);
    assert_eq!(diff[0].id, "ct_deleted1");
    assert_eq!(diff[0].contact_user_id, 42);
    assert_eq!(diff[0].email, None);
}

#[test]
fn root_key_md5_helper_is_base64_digest() {
    let digest = contacts_crypto::content_md5_base64(b"hello");
    assert_eq!(digest, encode_b64(&md5::Md5::digest(b"hello")));
}
