#![allow(dead_code)]

use crate::api::retry::RetryConfig;
use crate::models::error::{Error, Result};
use reqwest::{Client, RequestBuilder, Response, StatusCode};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::time::Duration;
use tokio::time::sleep;

const ENTE_API_ENDPOINT: &str = "https://api.ente.io";
const TOKEN_HEADER: &str = "X-Auth-Token";
const CLIENT_PKG_HEADER: &str = "X-Client-Package";
const CLIENT_PACKAGE: &str = "io.ente.cli";

/// Maximum number of retry attempts for failed requests
const MAX_RETRIES: u32 = 3;
/// Initial retry delay in milliseconds
const INITIAL_RETRY_DELAY_MS: u64 = 1000;
/// Maximum retry delay in milliseconds
const MAX_RETRY_DELAY_MS: u64 = 20000;

#[derive(Debug, Deserialize)]
pub struct ApiError {
    pub code: Option<String>,
    pub message: Option<String>,
}

pub struct ApiClient {
    client: Client,
    download_client: Client,
    pub(crate) base_url: String,
    /// Token storage for multi-account support: account_id -> token
    tokens: Arc<RwLock<HashMap<String, String>>>,
    /// Retry configuration
    retry_config: RetryConfig,
}

impl ApiClient {
    pub fn new(base_url: Option<String>) -> Result<Self> {
        // Main API client with standard timeout
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .user_agent(format!("ente-cli-rust/{}", env!("CARGO_PKG_VERSION")))
            .build()?;

        // Download client with longer timeout and connection pool settings
        let download_client = Client::builder()
            .timeout(Duration::from_secs(300))
            .pool_idle_timeout(Duration::from_secs(90))
            .pool_max_idle_per_host(10)
            .user_agent(format!("ente-cli-rust/{}", env!("CARGO_PKG_VERSION")))
            .build()?;

        Ok(Self {
            client,
            download_client,
            base_url: base_url.unwrap_or_else(|| ENTE_API_ENDPOINT.to_string()),
            tokens: Arc::new(RwLock::new(HashMap::new())),
            retry_config: RetryConfig::default(),
        })
    }

    /// Add or update authentication token for an account
    pub fn add_token(&self, account_id: &str, token: &str) {
        let mut tokens = self.tokens.write().unwrap();
        tokens.insert(account_id.to_string(), token.to_string());
    }

    /// Remove authentication token for an account
    pub fn remove_token(&self, account_id: &str) {
        let mut tokens = self.tokens.write().unwrap();
        tokens.remove(account_id);
    }

    /// Get authentication token for an account
    pub fn get_token(&self, account_id: &str) -> Option<String> {
        let tokens = self.tokens.read().unwrap();
        tokens.get(account_id).cloned()
    }

    /// Set retry configuration
    pub fn set_retry_config(&mut self, config: RetryConfig) {
        self.retry_config = config;
    }

    /// Build a request with common headers
    fn build_request(&self, builder: RequestBuilder, account_id: Option<&str>) -> RequestBuilder {
        let mut req = builder.header(CLIENT_PKG_HEADER, CLIENT_PACKAGE);

        // Add auth token if account_id is provided
        if let Some(id) = account_id {
            if let Some(token) = self.get_token(id) {
                log::debug!("Adding auth token for account {id}");
                req = req.header(TOKEN_HEADER, token);
            } else {
                log::warn!("No token found for account {id}");
            }
        }

        req
    }

    /// Execute request with retry logic
    async fn execute_with_retry(&self, request_builder: RequestBuilder) -> Result<Response> {
        let mut retry_count = 0;
        let mut delay_ms = INITIAL_RETRY_DELAY_MS;

        loop {
            let req = request_builder
                .try_clone()
                .ok_or_else(|| Error::Generic("Failed to clone request for retry".to_string()))?;

            match req.send().await {
                Ok(response) => {
                    // Check if we should retry based on status code
                    if (response.status() == StatusCode::TOO_MANY_REQUESTS
                        || response.status().is_server_error())
                        && retry_count < MAX_RETRIES
                    {
                        retry_count += 1;
                        log::warn!(
                            "Request failed with status {}, retry attempt {}/{}",
                            response.status(),
                            retry_count,
                            MAX_RETRIES
                        );

                        // Exponential backoff with jitter
                        sleep(Duration::from_millis(delay_ms)).await;
                        delay_ms = (delay_ms * 2).min(MAX_RETRY_DELAY_MS);
                        continue;
                    }

                    return Ok(response);
                }
                Err(e) => {
                    if retry_count < MAX_RETRIES {
                        retry_count += 1;
                        log::warn!(
                            "Request failed with error: {e}, retry attempt {retry_count}/{MAX_RETRIES}"
                        );

                        sleep(Duration::from_millis(delay_ms)).await;
                        delay_ms = (delay_ms * 2).min(MAX_RETRY_DELAY_MS);
                        continue;
                    }
                    return Err(e.into());
                }
            }
        }
    }

    /// Make a GET request
    pub async fn get<T>(&self, path: &str, account_id: Option<&str>) -> Result<T>
    where
        T: for<'de> Deserialize<'de>,
    {
        let url = format!("{}{}", self.base_url, path);
        let request = self.client.get(&url);
        let request = self.build_request(request, account_id);

        let response = self.execute_with_retry(request).await?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());

            // Try to parse as JSON to get error details
            if let Ok(error_json) = serde_json::from_str::<serde_json::Value>(&error_text) {
                log::error!(
                    "API error: status={}, body={}",
                    status,
                    serde_json::to_string_pretty(&error_json).unwrap_or(error_text.clone())
                );
            } else {
                log::error!("API error: status={status}, body={error_text}");
            }

            return Err(Error::Generic(format!(
                "API error ({status}): {error_text}"
            )));
        }

        let text = response.text().await?;
        serde_json::from_str(&text).map_err(|e| {
            log::error!("Failed to deserialize response: {e}");
            log::error!(
                "Response text (first 1000 chars): {}",
                &text[..1000.min(text.len())]
            );
            Error::Generic(format!("Deserialization failed: {e}"))
        })
    }

    /// Make a POST request
    pub async fn post<T, B>(&self, path: &str, body: &B, account_id: Option<&str>) -> Result<T>
    where
        T: for<'de> Deserialize<'de>,
        B: Serialize,
    {
        let url = format!("{}{}", self.base_url, path);

        // Debug log the JSON being sent
        if path.contains("verify-session") {
            log::debug!(
                "POST {} with JSON: {}",
                url,
                serde_json::to_string_pretty(body)?
            );
        }

        let request = self.client.post(&url).json(body);
        let request = self.build_request(request, account_id);

        let response = self.execute_with_retry(request).await?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());

            // Try to parse as JSON to get error details
            if let Ok(error_json) = serde_json::from_str::<serde_json::Value>(&error_text) {
                log::error!(
                    "API error: status={}, body={}",
                    status,
                    serde_json::to_string_pretty(&error_json).unwrap_or(error_text.clone())
                );
            } else {
                log::error!("API error: status={status}, body={error_text}");
            }

            return Err(Error::Generic(format!(
                "API error ({status}): {error_text}"
            )));
        }

        let text = response.text().await?;
        serde_json::from_str(&text).map_err(|e| {
            log::error!("Failed to deserialize response: {e}");
            log::error!(
                "Response text (first 1000 chars): {}",
                &text[..1000.min(text.len())]
            );
            Error::Generic(format!("Deserialization failed: {e}"))
        })
    }

    /// Make a PUT request
    pub async fn put<T, B>(&self, path: &str, body: &B, account_id: Option<&str>) -> Result<T>
    where
        T: for<'de> Deserialize<'de>,
        B: Serialize,
    {
        let url = format!("{}{}", self.base_url, path);
        let request = self.client.put(&url).json(body);
        let request = self.build_request(request, account_id);

        let response = self.execute_with_retry(request).await?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());

            // Try to parse as JSON to get error details
            if let Ok(error_json) = serde_json::from_str::<serde_json::Value>(&error_text) {
                log::error!(
                    "API error: status={}, body={}",
                    status,
                    serde_json::to_string_pretty(&error_json).unwrap_or(error_text.clone())
                );
            } else {
                log::error!("API error: status={status}, body={error_text}");
            }

            return Err(Error::Generic(format!(
                "API error ({status}): {error_text}"
            )));
        }

        let text = response.text().await?;
        serde_json::from_str(&text).map_err(|e| {
            log::error!("Failed to deserialize response: {e}");
            log::error!(
                "Response text (first 1000 chars): {}",
                &text[..1000.min(text.len())]
            );
            Error::Generic(format!("Deserialization failed: {e}"))
        })
    }

    /// Make a DELETE request  
    pub async fn delete(&self, path: &str, account_id: Option<&str>) -> Result<()> {
        let url = format!("{}{}", self.base_url, path);
        let request = self.client.delete(&url);
        let request = self.build_request(request, account_id);

        let response = self.execute_with_retry(request).await?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());

            // Try to parse as JSON to get error details
            if let Ok(error_json) = serde_json::from_str::<serde_json::Value>(&error_text) {
                log::error!(
                    "API error: status={}, body={}",
                    status,
                    serde_json::to_string_pretty(&error_json).unwrap_or(error_text.clone())
                );
            } else {
                log::error!("API error: status={status}, body={error_text}");
            }

            return Err(Error::Generic(format!(
                "API error ({status}): {error_text}"
            )));
        }

        Ok(())
    }

    /// Download a file with the download client
    pub async fn download_file(&self, url: &str, account_id: Option<&str>) -> Result<Vec<u8>> {
        let request = self.download_client.get(url);
        let request = self.build_request(request, account_id);

        let response = self.execute_with_retry(request).await?;

        if !response.status().is_success() {
            let error_text = response
                .text()
                .await
                .unwrap_or_else(|_| "Unknown error".to_string());
            return Err(Error::Generic(format!("Download error: {error_text}")));
        }

        Ok(response.bytes().await?.to_vec())
    }
}
