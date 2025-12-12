//! HTTP client for communicating with the Ente API.

use serde::Deserialize;
use thiserror::Error;

/// HTTP client errors.
#[derive(Error, Debug)]
pub enum Error {
    /// Network error - connection failed, timeout, etc.
    #[error("Network error: {0}")]
    Network(String),

    /// Server returned an HTTP error status.
    #[error("HTTP {status}: {message}")]
    Http {
        /// Error message or response body.
        message: String,
        /// HTTP status code.
        status: u16,
    },

    /// Failed to parse JSON response.
    #[error("JSON parse error: {0}")]
    Parse(String),
}

impl From<reqwest::Error> for Error {
    fn from(e: reqwest::Error) -> Self {
        if let Some(status) = e.status() {
            Error::Http {
                status: status.as_u16(),
                message: e.to_string(),
            }
        } else {
            Error::Network(e.to_string())
        }
    }
}

impl From<serde_json::Error> for Error {
    fn from(e: serde_json::Error) -> Self {
        Error::Parse(e.to_string())
    }
}

/// Response from the /ping endpoint
#[derive(Deserialize, Debug)]
pub struct PingResponse {
    /// "pong"
    pub message: String,
    /// Git commit hash of the server.
    pub id: String,
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
        let response = response.error_for_status()?;
        let text = response.text().await?;
        Ok(text)
    }

    /// Ping the API, returns [PingResponse].
    pub async fn ping(&self) -> Result<PingResponse, Error> {
        let text = self.get("/ping").await?;
        let response: PingResponse = serde_json::from_str(&text)?;
        Ok(response)
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

    #[test]
    fn test_parse_error_conversion() {
        let bad_json = "not json";
        let err: Result<PingResponse, Error> = serde_json::from_str(bad_json).map_err(|e| e.into());
        println!("{:?}", err);
        assert!(matches!(err, Err(Error::Parse(_))))
    }
}
