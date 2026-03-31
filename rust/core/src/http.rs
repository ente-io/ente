//! HTTP client for communicating with the Ente API.

use reqwest::Url;
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

    /// Invalid base URL or request path.
    #[error("Invalid URL: {0}")]
    InvalidUrl(String),
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
        let url = self.resolve_url(path)?;
        let response = self.client.get(url).send().await?;
        let response = response.error_for_status()?;
        let text = response.text().await?;
        Ok(text)
    }

    fn resolve_url(&self, path: &str) -> Result<Url, Error> {
        if !path.starts_with('/') || path.starts_with("//") {
            return Err(Error::InvalidUrl(
                "request paths must start with a single '/'".to_string(),
            ));
        }

        let (path_and_query, fragment) = path
            .split_once('#')
            .map_or((path, None), |(path, fragment)| (path, Some(fragment)));
        if fragment.is_some() {
            return Err(Error::InvalidUrl(
                "request paths must not contain fragments".to_string(),
            ));
        }

        let (path_only, query) = path_and_query
            .split_once('?')
            .map_or((path_and_query, None), |(path, query)| (path, Some(query)));
        if path_only
            .split('/')
            .any(|segment| matches!(segment, "." | ".."))
        {
            return Err(Error::InvalidUrl(
                "request paths must not contain dot segments".to_string(),
            ));
        }

        let mut base = Url::parse(&self.base_url)
            .map_err(|e| Error::InvalidUrl(format!("invalid base URL: {e}")))?;
        base.set_query(None);
        base.set_fragment(None);

        let base_path = base.path().trim_end_matches('/');
        let resolved_path = if base_path.is_empty() || base_path == "/" {
            path_only.to_string()
        } else {
            format!("{base_path}{path_only}")
        };

        base.set_path(&resolved_path);
        base.set_query(query);
        Ok(base)
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

    fn test_client(base_url: &str) -> HttpClient {
        HttpClient {
            client: reqwest::Client::builder().no_proxy().build().unwrap(),
            base_url: base_url.to_string(),
        }
    }

    #[test]
    fn test_client_creation() {
        let client = test_client("https://api.ente.io");
        assert_eq!(client.base_url, "https://api.ente.io");
    }

    #[test]
    fn test_parse_error_conversion() {
        let bad_json = "not json";
        let err: Result<PingResponse, Error> = serde_json::from_str(bad_json).map_err(|e| e.into());
        println!("{:?}", err);
        assert!(matches!(err, Err(Error::Parse(_))))
    }

    #[test]
    fn test_resolve_url_uses_origin_path_join() {
        let client = test_client("https://api.ente.io/v1");
        let url = client.resolve_url("/ping").unwrap();
        assert_eq!(url.as_str(), "https://api.ente.io/v1/ping");
    }

    #[test]
    fn test_resolve_url_preserves_request_query_without_base_query() {
        let client = test_client("https://api.ente.io/v1?stale=true#old");
        let url = client.resolve_url("/ping?fresh=true").unwrap();
        assert_eq!(url.as_str(), "https://api.ente.io/v1/ping?fresh=true");
    }

    #[test]
    fn test_resolve_url_rejects_host_confusion_payload() {
        let client = test_client("https://api.ente.io");
        let err = client.resolve_url("@attacker.com").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_resolve_url_rejects_protocol_relative_path() {
        let client = test_client("https://api.ente.io");
        let err = client.resolve_url("//attacker.com").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_resolve_url_rejects_dot_segments() {
        let client = test_client("https://api.ente.io/v1");
        let err = client.resolve_url("/../admin").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_resolve_url_rejects_fragments() {
        let client = test_client("https://api.ente.io");
        let err = client.resolve_url("/ping#frag").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_resolve_url_rejects_invalid_base_url() {
        let client = test_client("not a url");
        let err = client.resolve_url("/ping").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }
}
