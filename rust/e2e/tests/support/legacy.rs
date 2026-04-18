use ente_contacts::client::ContactsCtx;

use crate::support::{
    auth::{self, TestAccount},
    contacts, unique_password, unique_test_email,
};

pub struct LegacyPair {
    pub owner: TestAccount,
    pub trusted: TestAccount,
    pub owner_ctx: ContactsCtx,
    pub trusted_ctx: ContactsCtx,
}

pub async fn accepted_pair(endpoint: &str, recovery_notice_in_days: i32) -> LegacyPair {
    let (owner, trusted) = tokio::join!(
        auth::create_account(
            endpoint,
            unique_test_email("legacy-owner"),
            unique_password("LegacyOwner"),
        ),
        auth::create_account(
            endpoint,
            unique_test_email("legacy-trusted"),
            unique_password("LegacyTrusted"),
        )
    );

    let (owner_ctx, trusted_ctx) = tokio::join!(
        contacts::open_ctx(endpoint, &owner),
        contacts::open_ctx(endpoint, &trusted)
    );

    contacts::establish_legacy_contact(
        &owner_ctx,
        &owner,
        &trusted_ctx,
        &trusted,
        recovery_notice_in_days,
    )
    .await;

    LegacyPair {
        owner,
        trusted,
        owner_ctx,
        trusted_ctx,
    }
}
