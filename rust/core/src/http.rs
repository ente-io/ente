//! HTTP client for communicating with the Ente API.

use std::sync::RwLock;
#[cfg(not(target_arch = "wasm32"))]
use std::time::Duration;

use reqwest::header::{HeaderMap, HeaderName, HeaderValue, LOCATION};
use reqwest::{Response, Url};
use serde::de::DeserializeOwned;
use serde::{Deserialize, Serialize};
use thiserror::Error;

const TOKEN_HEADER: &str = "X-Auth-Token";
const CLIENT_PKG_HEADER: &str = "X-Client-Package";
const CLIENT_VERSION_HEADER: &str = "X-Client-Version";

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

/// Response from the /ping endpoint.
#[derive(Deserialize, Debug)]
pub struct PingResponse {
    /// "pong"
    pub message: String,
    /// Git commit hash of the server.
    pub id: String,
}

/// Authenticated HTTP client configuration.
#[derive(Debug, Clone, Default)]
pub struct HttpConfig {
    /// Base API URL.
    pub base_url: String,
    /// Optional auth token sent via `X-Auth-Token`.
    pub auth_token: Option<String>,
    /// Optional user agent.
    pub user_agent: Option<String>,
    /// Optional client package header.
    pub client_package: Option<String>,
    /// Optional client version header.
    pub client_version: Option<String>,
    /// Optional request timeout.
    pub timeout_secs: Option<u64>,
}

/// HTTP client for making requests to the Ente API.
pub struct HttpClient {
    client: reqwest::Client,
    base_url: String,
    base_origin: Option<Url>,
    auth_token: RwLock<Option<String>>,
    user_agent: Option<String>,
    client_package: Option<String>,
    client_version: Option<String>,
}

impl HttpClient {
    /// Create a client with the given base URL.
    pub fn new(base_url: &str) -> Result<Self, Error> {
        Self::new_with_config(HttpConfig {
            base_url: base_url.to_string(),
            ..HttpConfig::default()
        })
    }

    /// Create a client with auth/header configuration.
    pub fn new_with_config(config: HttpConfig) -> Result<Self, Error> {
        let base_url = config.base_url.trim_end_matches('/').to_string();
        let base_origin = Url::parse(&base_url).ok().and_then(|base| {
            if base.query().is_none() && base.fragment().is_none() {
                Some(base)
            } else {
                None
            }
        });

        #[cfg(not(target_arch = "wasm32"))]
        let mut builder = reqwest::Client::builder();
        #[cfg(target_arch = "wasm32")]
        let builder = reqwest::Client::builder();
        #[cfg(not(target_arch = "wasm32"))]
        if let Some(timeout) = config.timeout_secs {
            builder = builder.timeout(Duration::from_secs(timeout));
        }

        let client = builder.build().map_err(Error::from)?;

        Ok(Self {
            client,
            base_url,
            base_origin,
            auth_token: RwLock::new(config.auth_token),
            user_agent: config.user_agent,
            client_package: config.client_package,
            client_version: config.client_version,
        })
    }

    /// Replace the auth token used for authenticated requests.
    pub fn set_auth_token(&self, auth_token: Option<String>) {
        *self.auth_token.write().expect("auth token lock poisoned") = auth_token;
    }

    /// GET request, returns response body as text.
    ///
    /// `path` is expected to be a trusted API endpoint path chosen by the
    /// caller. This helper intentionally preserves the request path verbatim
    /// after basic validation, so attacker-controlled paths must not be passed.
    pub async fn get(&self, path: &str) -> Result<String, Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .get(&url)
            .headers(self.build_headers()?)
            .send()
            .await?;
        parse_text_response(response).await
    }

    /// GET request returning JSON.
    pub async fn get_json<T: DeserializeOwned>(
        &self,
        path: &str,
        query: &[(&str, String)],
    ) -> Result<T, Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .get(&url)
            .headers(self.build_headers()?)
            .query(query)
            .send()
            .await?;
        parse_json_response(response).await
    }

    /// GET request returning `None` for 404.
    pub async fn get_json_optional<T: DeserializeOwned>(
        &self,
        path: &str,
        query: &[(&str, String)],
    ) -> Result<Option<T>, Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .get(&url)
            .headers(self.build_headers()?)
            .query(query)
            .send()
            .await?;
        if response.status().as_u16() == 404 {
            return Ok(None);
        }
        parse_json_response(response).await.map(Some)
    }

    /// POST JSON request.
    pub async fn post_json<T: DeserializeOwned, B: Serialize + ?Sized>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<T, Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .post(&url)
            .headers(self.build_headers()?)
            .json(body)
            .send()
            .await?;
        parse_json_response(response).await
    }

    /// POST JSON request expecting an empty response body.
    pub async fn post_empty<B: Serialize + ?Sized>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<(), Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .post(&url)
            .headers(self.build_headers()?)
            .json(body)
            .send()
            .await?;
        parse_empty_response(response).await
    }

    /// PUT JSON request.
    pub async fn put_json<T: DeserializeOwned, B: Serialize + ?Sized>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<T, Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .put(&url)
            .headers(self.build_headers()?)
            .json(body)
            .send()
            .await?;
        parse_json_response(response).await
    }

    /// PUT JSON request expecting an empty response body.
    pub async fn put_empty<B: Serialize + ?Sized>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<(), Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .put(&url)
            .headers(self.build_headers()?)
            .json(body)
            .send()
            .await?;
        parse_empty_response(response).await
    }

    /// DELETE request expecting an empty response body.
    pub async fn delete_empty(&self, path: &str, query: &[(&str, String)]) -> Result<(), Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .delete(&url)
            .headers(self.build_headers()?)
            .query(query)
            .send()
            .await?;
        parse_empty_response(response).await
    }

    /// DELETE request returning JSON.
    pub async fn delete_json<T: DeserializeOwned>(
        &self,
        path: &str,
        query: &[(&str, String)],
    ) -> Result<T, Error> {
        let url = self.request_url(path)?;
        let response = self
            .client
            .delete(&url)
            .headers(self.build_headers()?)
            .query(query)
            .send()
            .await?;
        parse_json_response(response).await
    }

    /// Download bytes from a URL, following redirects safely.
    pub async fn get_bytes(&self, url: &str) -> Result<Vec<u8>, Error> {
        let mut current_url = self.parse_url(url)?;
        for _ in 0..5 {
            let headers = self.build_headers_for_url(&current_url)?;
            let response = self
                .client
                .get(current_url.clone())
                .headers(headers)
                .send()
                .await?;
            if response.status().is_redirection()
                && let Some(location) = response.headers().get(LOCATION)
            {
                current_url = self.resolve_redirect(&current_url, location)?;
                continue;
            }
            return parse_bytes_response(response).await;
        }

        Err(Error::InvalidUrl("too many redirects".to_string()))
    }

    /// Upload raw bytes to a presigned URL, following redirects safely.
    pub async fn put_bytes(
        &self,
        url: &str,
        body: &[u8],
        headers: &[(&str, String)],
    ) -> Result<(), Error> {
        let mut header_map = HeaderMap::new();
        for (name, value) in headers {
            let header_name =
                HeaderName::from_bytes(name.as_bytes()).map_err(|e| Error::Parse(e.to_string()))?;
            let header_value =
                HeaderValue::from_str(value).map_err(|e| Error::Parse(e.to_string()))?;
            header_map.insert(header_name, header_value);
        }

        let mut current_url = self.parse_url(url)?;
        for _ in 0..5 {
            let response = self
                .client
                .put(current_url.clone())
                .headers(header_map.clone())
                .body(body.to_vec())
                .send()
                .await?;
            if response.status().is_redirection()
                && let Some(location) = response.headers().get(LOCATION)
            {
                current_url = self.resolve_redirect(&current_url, location)?;
                continue;
            }
            return parse_empty_response(response).await;
        }

        Err(Error::InvalidUrl("too many redirects".to_string()))
    }

    fn request_url(&self, path: &str) -> Result<String, Error> {
        if !path.starts_with('/') {
            return Err(Error::InvalidUrl(
                "request paths must start with '/'".to_string(),
            ));
        }
        debug_assert!(
            !path_contains_dot_segments(path),
            "request paths must be trusted endpoint paths without dot segments"
        );

        let base = Url::parse(&self.base_url)
            .map_err(|e| Error::InvalidUrl(format!("invalid base URL: {e}")))?;
        if base.query().is_some() || base.fragment().is_some() {
            return Err(Error::InvalidUrl(
                "base URL must not contain a query or fragment".to_string(),
            ));
        }

        Ok(format!("{}{}", self.base_url, path))
    }

    /// Ping the API, returns [PingResponse].
    pub async fn ping(&self) -> Result<PingResponse, Error> {
        self.get_json("/ping", &[]).await
    }

    fn request_url(&self, path: &str) -> Result<String, Error> {
        if !path.starts_with('/') {
            return Err(Error::InvalidUrl(
                "request paths must start with '/'".to_string(),
            ));
        }

        let base = Url::parse(&self.base_url)
            .map_err(|e| Error::InvalidUrl(format!("invalid base URL: {e}")))?;
        if base.query().is_some() || base.fragment().is_some() {
            return Err(Error::InvalidUrl(
                "base URL must not contain a query or fragment".to_string(),
            ));
        }

        Ok(format!("{}{}", self.base_url, path))
    }

    fn parse_url(&self, url: &str) -> Result<Url, Error> {
        Url::parse(url).map_err(|e| Error::InvalidUrl(format!("invalid url: {e}")))
    }

    fn resolve_redirect(&self, current_url: &Url, location: &HeaderValue) -> Result<Url, Error> {
        let next = location
            .to_str()
            .map_err(|e| Error::InvalidUrl(format!("invalid redirect location: {e}")))?;
        Url::parse(next)
            .or_else(|_| current_url.join(next))
            .map_err(|e| Error::InvalidUrl(format!("invalid redirect location: {e}")))
    }

    fn is_same_origin(&self, url: &Url) -> bool {
        self.base_origin.as_ref().is_some_and(|base| {
            base.scheme() == url.scheme()
                && base.host_str() == url.host_str()
                && base.port_or_known_default() == url.port_or_known_default()
        })
    }

    fn build_headers_for_url(&self, url: &Url) -> Result<HeaderMap, Error> {
        if self.is_same_origin(url) {
            self.build_headers()
        } else {
            self.build_public_headers()
        }
    }

    fn build_headers(&self) -> Result<HeaderMap, Error> {
        let mut headers = self.build_public_headers()?;
        if let Some(auth_token) = self
            .auth_token
            .read()
            .expect("auth token lock poisoned")
            .clone()
        {
            let token =
                HeaderValue::from_str(&auth_token).map_err(|e| Error::Parse(e.to_string()))?;
            headers.insert(TOKEN_HEADER, token);
        }
        Ok(headers)
    }

    fn build_public_headers(&self) -> Result<HeaderMap, Error> {
        let mut headers = HeaderMap::new();
        if let Some(user_agent) = &self.user_agent {
            let value =
                HeaderValue::from_str(user_agent).map_err(|e| Error::Parse(e.to_string()))?;
            headers.insert(reqwest::header::USER_AGENT, value);
        }
        if let Some(client_package) = &self.client_package {
            let value =
                HeaderValue::from_str(client_package).map_err(|e| Error::Parse(e.to_string()))?;
            headers.insert(CLIENT_PKG_HEADER, value);
        }
        if let Some(client_version) = &self.client_version {
            let value =
                HeaderValue::from_str(client_version).map_err(|e| Error::Parse(e.to_string()))?;
            headers.insert(CLIENT_VERSION_HEADER, value);
        }
        Ok(headers)
    }
}

async fn parse_text_response(response: Response) -> Result<String, Error> {
    if !response.status().is_success() {
        let status = response.status().as_u16();
        let message = response
            .text()
            .await
            .unwrap_or_else(|_| "failed to read error body".to_string());
        return Err(Error::Http { status, message });
    }
    response.text().await.map_err(Into::into)
}

async fn parse_json_response<T: DeserializeOwned>(response: Response) -> Result<T, Error> {
    let text = parse_text_response(response).await?;
    serde_json::from_str(&text).map_err(Into::into)
}

async fn parse_empty_response(response: Response) -> Result<(), Error> {
    if !response.status().is_success() {
        let status = response.status().as_u16();
        let message = response
            .text()
            .await
            .unwrap_or_else(|_| "failed to read error body".to_string());
        return Err(Error::Http { status, message });
    }
    Ok(())
}

async fn parse_bytes_response(response: Response) -> Result<Vec<u8>, Error> {
    if !response.status().is_success() {
        let status = response.status().as_u16();
        let message = response
            .text()
            .await
            .unwrap_or_else(|_| "failed to read error body".to_string());
        return Err(Error::Http { status, message });
    }
    response
        .bytes()
        .await
        .map(|bytes| bytes.to_vec())
        .map_err(Into::into)
}

fn path_contains_dot_segments(path: &str) -> bool {
    path.split(['?', '#'])
        .next()
        .unwrap_or(path)
        .split('/')
        .any(|segment| {
            matches!(segment, "." | "..")
                || segment.eq_ignore_ascii_case("%2e")
                || segment.eq_ignore_ascii_case("%2e%2e")
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_client(base_url: &str) -> HttpClient {
        HttpClient::new_with_config(HttpConfig {
            base_url: base_url.to_string(),
            ..HttpConfig::default()
        })
        .expect("test client creation should succeed")
    }

    #[test]
    fn test_client_creation() {
        let client = test_client("https://api.ente.io/");
        assert_eq!(client.base_url, "https://api.ente.io");
    }

    #[test]
    fn test_parse_error_conversion() {
        let bad_json = "not json";
        let err: Result<PingResponse, Error> = serde_json::from_str(bad_json).map_err(|e| e.into());
        assert!(matches!(err, Err(Error::Parse(_))))
    }

    #[test]
    fn test_request_url_uses_string_join() {
        let client = test_client("https://api.ente.io/v1");
        let url = client.request_url("/ping").unwrap();
        assert_eq!(url, "https://api.ente.io/v1/ping");
    }

    #[test]
    fn test_request_url_preserves_query_and_special_bytes() {
        let client = test_client("https://api.ente.io/v1");
        let url = client.request_url("/%2e%2e%5cadmin?fresh=true").unwrap();
        assert_eq!(url, "https://api.ente.io/v1/%2e%2e%5cadmin?fresh=true");
    }

    #[test]
    fn test_path_contains_dot_segments() {
        assert!(!path_contains_dot_segments("/ping?fresh=true"));
        assert!(path_contains_dot_segments("/../admin"));
        assert!(path_contains_dot_segments("/safe/%2e%2e/admin"));
        assert!(path_contains_dot_segments("/safe/%2E/admin"));
    }

    #[test]
    fn test_request_url_rejects_missing_leading_slash() {
        let client = test_client("https://api.ente.io");
        let err = client.request_url("ping").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_request_url_rejects_invalid_base_url() {
        let client = test_client("not a url");
        let err = client.request_url("/ping").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_request_url_rejects_base_url_with_query() {
        let client = test_client("https://api.ente.io/v1?stale=true");
        let err = client.request_url("/ping").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_request_url_rejects_base_url_with_fragment() {
        let client = test_client("https://api.ente.io/v1#old");
        let err = client.request_url("/ping").unwrap_err();
        assert!(matches!(err, Error::InvalidUrl(_)));
    }

    #[test]
    fn test_set_auth_token_replaces_token() {
        let client = test_client("https://api.ente.io");
        client.set_auth_token(Some("token-1".to_string()));
        assert_eq!(
            client.auth_token.read().unwrap().clone(),
            Some("token-1".to_string())
        );
        client.set_auth_token(None);
        assert_eq!(client.auth_token.read().unwrap().clone(), None);
    }
}
