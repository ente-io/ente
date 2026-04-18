mod support;

use ente_contacts::legacy_models::{LegacyContactState, LegacyRecoveryStatus};
use ente_contacts::models::ContactData;
use ente_accounts::Error as CliError;
use ente_core::http::Error as CoreHttpError;

use support::{auth, contacts, legacy};

#[tokio::test]
#[ignore = "requires local Museum at ENTE_E2E_ENDPOINT or http://localhost:8080"]
async fn auth_contacts_and_legacy_recovery_suite() {
    let endpoint = support::endpoint();
    if !support::assert_server_or_skip(&endpoint, "full rust e2e suite").await {
        return;
    }

    let pair = legacy::accepted_pair(&endpoint, 14).await;

    run_auth_stage(&endpoint, &pair.owner).await;
    run_contacts_stage(&pair).await;
    run_legacy_reject_stage(&pair).await;
    run_legacy_stop_stage(&pair).await;
    run_legacy_reinvite_stage(&pair).await;
    run_legacy_reset_stage(&endpoint, &pair).await;
}

async fn run_auth_stage(endpoint: &str, owner: &auth::TestAccount) {
    let first_login = auth::login_without_totp(endpoint, &owner.email, &owner.password)
        .await
        .expect("initial login failed");
    assert_eq!(first_login.user_id, owner.user_id);
    assert_eq!(first_login.secrets.master_key, owner.master_key);

    let totp_secret = auth::enable_totp(endpoint, owner).await;

    let second_login = auth::login_with_totp(endpoint, &owner.email, &owner.password, &totp_secret)
        .await
        .expect("two-factor login failed");
    assert_eq!(second_login.user_id, owner.user_id);
    assert_eq!(second_login.secrets.master_key, owner.master_key);
    assert!(
        auth::fetch_two_factor_status(endpoint, owner)
            .await
            .expect("two-factor status fetch failed")
    );
}

async fn run_contacts_stage(pair: &legacy::LegacyPair) {
    let initial_data = ContactData {
        contact_user_id: pair.trusted.user_id,
        name: "Trusted Contact".to_string(),
        birth_date: Some("2001-04-01".to_string()),
    };

    let contact = pair.owner_ctx.create_contact(&initial_data).await.unwrap();
    assert_eq!(contact.contact_user_id, pair.trusted.user_id);
    assert_eq!(contact.email.as_deref(), Some(pair.trusted.email.as_str()));

    let fetched = pair.owner_ctx.get_contact(&contact.id).await.unwrap();
    assert_eq!(fetched.id, contact.id);
    assert_eq!(fetched.name.as_deref(), Some("Trusted Contact"));

    let updated = pair
        .owner_ctx
        .update_contact(
            &contact.id,
            &ContactData {
                contact_user_id: pair.trusted.user_id,
                name: "Trusted Contact Updated".to_string(),
                birth_date: Some("2001-04-02".to_string()),
            },
        )
        .await
        .unwrap();
    assert_eq!(updated.name.as_deref(), Some("Trusted Contact Updated"));
    assert_eq!(updated.birth_date.as_deref(), Some("2001-04-02"));

    let diff = pair.owner_ctx.get_diff(0, 5000).await.unwrap();
    assert!(diff.iter().any(|entry| entry.id == contact.id));

    match pair.trusted_ctx.get_contact(&contact.id).await {
        Err(ente_contacts::ContactsError::Http(CoreHttpError::Http { status: 404, .. })) => {}
        other => panic!("expected trusted account to get 404 for owner contact, got {other:?}"),
    }

    pair.owner_ctx.delete_contact(&contact.id).await.unwrap();
}

async fn run_legacy_reject_stage(pair: &legacy::LegacyPair) {
    pair.trusted_ctx
        .legacy_start_recovery(pair.owner.user_id, pair.trusted.user_id)
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let recovery =
        contacts::owner_recovery_session(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("owner recovery session missing");
    assert_eq!(recovery.status, LegacyRecoveryStatus::Waiting);

    pair.owner_ctx
        .legacy_reject_recovery(&recovery.id, pair.owner.user_id, pair.trusted.user_id)
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let trusted_info = pair.trusted_ctx.legacy_info().await.unwrap();
    assert!(
        contacts::owner_recovery_session(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );
    assert!(
        contacts::trusted_recovery_session(&trusted_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );

    let owner_contact =
        contacts::owner_contact(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("legacy contact should stay accepted after rejection");
    assert_eq!(owner_contact.state, LegacyContactState::Accepted);
}

async fn run_legacy_stop_stage(pair: &legacy::LegacyPair) {
    pair.trusted_ctx
        .legacy_start_recovery(pair.owner.user_id, pair.trusted.user_id)
        .await
        .unwrap();

    let trusted_info = pair.trusted_ctx.legacy_info().await.unwrap();
    let recovery =
        contacts::trusted_recovery_session(&trusted_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("trusted recovery session missing");
    assert_eq!(recovery.status, LegacyRecoveryStatus::Waiting);

    pair.trusted_ctx
        .legacy_stop_recovery(&recovery.id, pair.owner.user_id, pair.trusted.user_id)
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let trusted_info = pair.trusted_ctx.legacy_info().await.unwrap();
    assert!(
        contacts::owner_recovery_session(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );
    assert!(
        contacts::trusted_recovery_session(&trusted_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );
}

async fn run_legacy_reinvite_stage(pair: &legacy::LegacyPair) {
    pair.owner_ctx
        .legacy_update_contact(
            pair.owner.user_id,
            pair.trusted.user_id,
            LegacyContactState::Revoked,
        )
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let trusted_info = pair.trusted_ctx.legacy_info().await.unwrap();
    assert!(
        contacts::owner_contact(&owner_info, pair.owner.user_id, pair.trusted.user_id).is_none()
    );
    assert!(
        contacts::trusted_contact(&trusted_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );

    pair.owner_ctx
        .legacy_add_contact(
            &pair.trusted.email,
            &contacts::to_core_key_attributes(&pair.owner.key_attributes),
            Some(14),
        )
        .await
        .unwrap();
    pair.trusted_ctx
        .legacy_update_contact(
            pair.owner.user_id,
            pair.trusted.user_id,
            LegacyContactState::Accepted,
        )
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let trusted_info = pair.trusted_ctx.legacy_info().await.unwrap();
    let owner_contact =
        contacts::owner_contact(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("reinvited contact missing from owner view");
    let trusted_contact =
        contacts::trusted_contact(&trusted_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("reinvited contact missing from trusted view");
    assert_eq!(owner_contact.state, LegacyContactState::Accepted);
    assert_eq!(trusted_contact.state, LegacyContactState::Accepted);
}

async fn run_legacy_reset_stage(endpoint: &str, pair: &legacy::LegacyPair) {
    assert!(
        auth::fetch_two_factor_status(endpoint, &pair.owner)
            .await
            .expect("two-factor status before recovery fetch failed")
    );

    pair.trusted_ctx
        .legacy_start_recovery(pair.owner.user_id, pair.trusted.user_id)
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let recovery =
        contacts::owner_recovery_session(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("owner recovery session missing");
    assert_eq!(recovery.status, LegacyRecoveryStatus::Waiting);

    pair.owner_ctx
        .legacy_approve_recovery(&recovery.id, pair.owner.user_id, pair.trusted.user_id)
        .await
        .unwrap();

    let owner_info = pair.owner_ctx.legacy_info().await.unwrap();
    let recovery =
        contacts::owner_recovery_session(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("approved recovery session missing");
    assert_eq!(recovery.status, LegacyRecoveryStatus::Ready);

    let new_password = support::unique_password("LegacyRecovered");
    pair.trusted_ctx
        .legacy_change_password(
            &recovery.id,
            &contacts::to_core_key_attributes(&pair.trusted.key_attributes),
            &new_password,
        )
        .await
        .unwrap();

    match auth::login_without_totp(endpoint, &pair.owner.email, &pair.owner.password).await {
        Err(CliError::AuthenticationFailed(message)) => {
            assert_eq!(message, "Incorrect password");
        }
        Err(error) if error.is_http_status(&[401]) => {}
        other => panic!("expected old password login to fail, got {other:?}"),
    }

    let recovered_login = auth::login_without_totp(endpoint, &pair.owner.email, &new_password)
        .await
        .expect("new password login should succeed after recovery");
    assert_eq!(recovered_login.user_id, pair.owner.user_id);
    assert_eq!(recovered_login.secrets.master_key, pair.owner.master_key);

    let recovered_owner = auth::test_account_from_authenticated(
        pair.owner.email.clone(),
        new_password,
        recovered_login,
    );
    assert!(
        !auth::fetch_two_factor_status(endpoint, &recovered_owner)
            .await
            .expect("two-factor status after recovery fetch failed")
    );

    let recovered_owner_ctx = contacts::open_ctx(endpoint, &recovered_owner).await;
    let owner_info = recovered_owner_ctx.legacy_info().await.unwrap();
    let trusted_info = pair.trusted_ctx.legacy_info().await.unwrap();
    assert!(
        contacts::owner_recovery_session(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );
    assert!(
        contacts::trusted_recovery_session(&trusted_info, pair.owner.user_id, pair.trusted.user_id)
            .is_none()
    );

    let owner_contact =
        contacts::owner_contact(&owner_info, pair.owner.user_id, pair.trusted.user_id)
            .expect("legacy contact should remain configured after recovery");
    assert_eq!(owner_contact.state, LegacyContactState::Accepted);
}
