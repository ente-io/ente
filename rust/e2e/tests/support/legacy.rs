use crate::support::{
    auth::{self, TestAccount},
    contacts,
};
use ente_contacts::client::ContactsCtx;

#[derive(Clone)]
pub struct LegacyPairState {
    pub owner: TestAccount,
    pub trusted: TestAccount,
}

pub struct LegacyPair {
    pub owner: TestAccount,
    pub trusted: TestAccount,
    pub owner_ctx: ContactsCtx,
    pub trusted_ctx: ContactsCtx,
}

pub async fn create_accepted_pair_state(
    endpoint: &str,
    recovery_notice_in_days: i32,
) -> LegacyPairState {
    let owner = auth::create_account_strict(endpoint, "legacy-owner", "LegacyOwner").await;
    let trusted = auth::create_account_strict(endpoint, "legacy-trusted", "LegacyTrusted").await;

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

    LegacyPairState { owner, trusted }
}

pub async fn open_pair(endpoint: &str, state: &LegacyPairState) -> LegacyPair {
    let owner = state.owner.clone();
    let trusted = state.trusted.clone();
    let (owner_ctx, trusted_ctx) = tokio::join!(
        contacts::open_ctx(endpoint, &owner),
        contacts::open_ctx(endpoint, &trusted)
    );

    LegacyPair {
        owner,
        trusted,
        owner_ctx,
        trusted_ctx,
    }
}

pub fn persist_pair_state(state: &mut LegacyPairState, runtime: &LegacyPair) {
    state.owner = runtime.owner.clone();
    state.trusted = runtime.trusted.clone();
}
