//! HTTP client for communicating with the Ente API.

use thiserror::Error;

/// HTTP client errors.
#[derive(Error, Debug)]
pub enum Error {
    /// A network or HTTP protocol error occurred during the request.
    #[error("HTTP request failed: {0}")]
    Request(#[from] reqwest::Error),
}

// TODO: Future HTTP features to implement:
// - POST/PUT/DELETE methods
// - JSON request bodies
// - Streaming uploads/downloads
// - Custom headers / auth tokens
// - Retry logic
// - Configurable timeouts

/// HTTP client for making requests to the Ente API.
pub struct HttpClient {
    client: reqwest::Client,
    base_url: String,
}

impl HttpClient {
    /// Create a client with the given base URL.
    pub fn new(base_url: &str) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url: base_url.to_string(),
        }
    }

    /// GET request, returns response body as text.
    pub async fn get(&self, path: &str) -> Result<String, Error> {
        let url = format!("{}{}", self.base_url, path);
        let response = self.client.get(&url).send().await?;
        let text = response.text().await?;
        Ok(text)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_client_creation() {
        let client = HttpClient::new("https://api.ente.io");
        assert_eq!(client.base_url, "https://api.ente.io");
    }
}
