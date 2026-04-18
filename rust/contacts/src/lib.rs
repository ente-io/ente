pub mod client;
pub mod crypto;
pub mod error;
pub mod legacy_models;
pub mod legacy_transport;
pub mod models;
pub mod transport;

pub use client::{ContactsCtx, OpenContactsCtxInput, OpenContactsCtxResult, RootKeySource};
pub use error::{ContactsError, Result};
pub use legacy_models::{
    LegacyContactRecord, LegacyContactState, LegacyInfo, LegacyRecoveryBundle,
    LegacyRecoverySession, LegacyRecoveryStatus, LegacyUser,
};
pub use models::{AttachmentType, ContactData, ContactRecord, WrappedRootContactKey};
