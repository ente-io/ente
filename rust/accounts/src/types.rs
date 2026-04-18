//! Shared reusable types for account clients.

use ente_core::http::HttpConfig;
use serde::{Deserialize, Serialize};
use zeroize::Zeroize;

/// Default base URL for Ente's public API.
pub const DEFAULT_API_BASE_URL: &str = "https://api.ente.io";

/// Default base URL for Ente's accounts broker.
pub const DEFAULT_ACCOUNTS_URL: &str = "https://accounts.ente.io";

/// Configuration for constructing an [`crate::client::AccountsClient`].
#[derive(Debug, Clone)]
pub struct AccountsClientConfig {
    /// Base Ente API URL.
    pub base_url: String,
    /// Optional auth token for authenticated requests.
    pub auth_token: Option<String>,
    /// Concrete client package header value.
    pub client_package: String,
    /// Optional client version header.
    pub client_version: Option<String>,
    /// Optional user agent.
    pub user_agent: Option<String>,
    /// Optional request timeout.
    pub timeout_secs: Option<u64>,
}

impl AccountsClientConfig {
    /// Create a config for the given client package.
    pub fn new(client_package: impl Into<String>) -> Self {
        Self {
            base_url: DEFAULT_API_BASE_URL.to_string(),
            auth_token: None,
            client_package: client_package.into(),
            client_version: None,
            user_agent: None,
            timeout_secs: None,
        }
    }

    /// Override the API base URL.
    pub fn with_base_url(mut self, base_url: impl Into<String>) -> Self {
        self.base_url = base_url.into();
        self
    }

    /// Attach an auth token.
    pub fn with_auth_token(mut self, auth_token: impl Into<String>) -> Self {
        self.auth_token = Some(auth_token.into());
        self
    }

    /// Set a client version header.
    pub fn with_client_version(mut self, client_version: impl Into<String>) -> Self {
        self.client_version = Some(client_version.into());
        self
    }

    /// Set a user agent.
    pub fn with_user_agent(mut self, user_agent: impl Into<String>) -> Self {
        self.user_agent = Some(user_agent.into());
        self
    }

    /// Set a request timeout in seconds.
    pub fn with_timeout_secs(mut self, timeout_secs: u64) -> Self {
        self.timeout_secs = Some(timeout_secs);
        self
    }
}

impl From<AccountsClientConfig> for HttpConfig {
    fn from(value: AccountsClientConfig) -> Self {
        HttpConfig {
            base_url: value.base_url,
            auth_token: value.auth_token,
            user_agent: value.user_agent,
            client_package: Some(value.client_package),
            client_version: value.client_version,
            timeout_secs: value.timeout_secs,
        }
    }
}

/// Decrypted account secrets.
#[derive(Serialize, Deserialize, Zeroize)]
#[zeroize(drop)]
pub struct AccountSecrets {
    /// Plain auth token bytes.
    pub token: Vec<u8>,
    /// Master key bytes.
    pub master_key: Vec<u8>,
    /// X25519 secret key bytes.
    pub secret_key: Vec<u8>,
    /// X25519 public key bytes.
    pub public_key: Vec<u8>,
}

impl std::fmt::Debug for AccountSecrets {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AccountSecrets")
            .field("token", &"[REDACTED]")
            .field("master_key", &"[REDACTED]")
            .field("secret_key", &"[REDACTED]")
            .field("public_key_len", &self.public_key.len())
            .finish()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn account_secrets_debug_redacts_secret_material() {
        let secrets = AccountSecrets {
            token: vec![1, 2, 3],
            master_key: vec![4, 5, 6],
            secret_key: vec![7, 8, 9],
            public_key: vec![10, 11, 12],
        };

        let debug = format!("{secrets:?}");
        assert!(debug.contains("[REDACTED]"));
        assert!(!debug.contains("[1, 2, 3]"));
        assert!(!debug.contains("[4, 5, 6]"));
        assert!(!debug.contains("[7, 8, 9]"));
    }
}
