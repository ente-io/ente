use ente_contacts::client::ContactsCtx;

use crate::support::{
    auth::{self, TestAccount},
    contacts,
};

#[derive(Clone)]
pub struct LegacyKitOwnerState {
    pub owner: TestAccount,
}

pub struct LegacyKitOwner {
    pub owner: TestAccount,
    pub owner_ctx: ContactsCtx,
}

pub async fn create_owner_state(endpoint: &str) -> LegacyKitOwnerState {
    let owner = auth::create_account_strict(endpoint, "legacy-kit-owner", "LegacyKitOwner").await;
    let owner_ctx = contacts::open_ctx(endpoint, &owner).await;
    drop(owner_ctx);
    LegacyKitOwnerState { owner }
}

pub async fn open_owner(endpoint: &str, state: &LegacyKitOwnerState) -> LegacyKitOwner {
    let owner = state.owner.clone();
    let owner_ctx = contacts::open_ctx(endpoint, &owner).await;
    LegacyKitOwner { owner, owner_ctx }
}

pub fn persist_owner_state(state: &mut LegacyKitOwnerState, runtime: &LegacyKitOwner) {
    state.owner = runtime.owner.clone();
}
