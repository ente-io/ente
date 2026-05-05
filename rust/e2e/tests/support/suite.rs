use tokio::sync::{Mutex, MutexGuard, OnceCell};

use crate::support::{legacy, legacy_kit};

pub struct SuiteState {
    pub legacy_pair: legacy::LegacyPairState,
    pub legacy_kit_owner: legacy_kit::LegacyKitOwnerState,
}

static SUITE: OnceCell<Mutex<SuiteState>> = OnceCell::const_new();

pub async fn lock_suite(endpoint: &str) -> MutexGuard<'static, SuiteState> {
    let endpoint = endpoint.to_string();
    let suite = SUITE
        .get_or_init(|| async move {
            Mutex::new(SuiteState {
                legacy_pair: legacy::create_accepted_pair_state(&endpoint, 14).await,
                legacy_kit_owner: legacy_kit::create_owner_state(&endpoint).await,
            })
        })
        .await;
    suite.lock().await
}
