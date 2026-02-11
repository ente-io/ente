use std::time::Duration;

use reqwest::Url;
use reqwest::blocking::{Client, Response};
use reqwest::header::{HeaderMap, HeaderName, HeaderValue, LOCATION};
use reqwest::redirect::Policy;
use serde::Serialize;
use serde::de::DeserializeOwned;
use uuid::Uuid;

use crate::errors::SyncError;

const DEFAULT_BASE_URL: &str = "https://api.ente.io";

#[derive(Debug, Clone)]
pub struct HttpConfig {
    pub base_url: String,
    pub auth_token: String,
    pub user_agent: Option<String>,
    pub client_package: Option<String>,
    pub client_version: Option<String>,
    pub timeout_secs: Option<u64>,
}

pub struct HttpClient {
    base_url: String,
    base_origin: Url,
    client: Client,
    auth_token: String,
    user_agent: Option<String>,
    client_package: Option<String>,
    client_version: Option<String>,
}

impl HttpClient {
    pub fn new(config: HttpConfig) -> Result<Self, SyncError> {
        let base_url = config.base_url.trim_end_matches('/').to_string();
        let base_origin = Url::parse(&base_url)
            .map_err(|_| SyncError::InvalidResponse("invalid base url".to_string()))?;
        let is_http = base_url.starts_with("http://");
        let is_default = base_url.starts_with(DEFAULT_BASE_URL);
        let allow_insecure = is_http || !is_default;

        let mut builder = Client::builder().redirect(Policy::none());
        if let Some(timeout) = config.timeout_secs {
            builder = builder.timeout(Duration::from_secs(timeout));
        }
        if allow_insecure {
            builder = builder.danger_accept_invalid_certs(true);
        }
        let client = builder.build().map_err(|e| SyncError::Http {
            status: 0,
            message: e.to_string(),
            code: None,
        })?;
        Ok(Self {
            base_url,
            base_origin,
            client,
            auth_token: config.auth_token,
            user_agent: config.user_agent,
            client_package: config.client_package,
            client_version: config.client_version,
        })
    }

    pub fn get_json<T: DeserializeOwned>(
        &self,
        path: &str,
        query: &[(&str, String)],
    ) -> Result<T, SyncError> {
        let url = format!("{}{}", self.base_url, path);
        let resp = self
            .client
            .get(&url)
            .headers(self.build_headers())
            .query(query)
            .send()
            .map_err(map_reqwest_error)?;
        parse_json_response(resp)
    }

    pub fn get_json_optional<T: DeserializeOwned>(
        &self,
        path: &str,
        query: &[(&str, String)],
    ) -> Result<Option<T>, SyncError> {
        let url = format!("{}{}", self.base_url, path);
        let resp = self
            .client
            .get(&url)
            .headers(self.build_headers())
            .query(query)
            .send()
            .map_err(map_reqwest_error)?;
        if resp.status().as_u16() == 404 {
            return Ok(None);
        }
        parse_json_response(resp).map(Some)
    }

    pub fn post_json<T: DeserializeOwned, B: Serialize>(
        &self,
        path: &str,
        body: &B,
    ) -> Result<T, SyncError> {
        let url = format!("{}{}", self.base_url, path);
        let resp = self
            .client
            .post(&url)
            .headers(self.build_headers())
            .json(body)
            .send()
            .map_err(map_reqwest_error)?;
        parse_json_response(resp)
    }

    pub fn post_empty<B: Serialize>(&self, path: &str, body: &B) -> Result<(), SyncError> {
        let url = format!("{}{}", self.base_url, path);
        let resp = self
            .client
            .post(&url)
            .headers(self.build_headers())
            .json(body)
            .send()
            .map_err(map_reqwest_error)?;
        parse_empty_response(resp)
    }

    pub fn delete(&self, path: &str, query: &[(&str, String)]) -> Result<(), SyncError> {
        let url = format!("{}{}", self.base_url, path);
        let resp = self
            .client
            .delete(&url)
            .headers(self.build_headers())
            .query(query)
            .send()
            .map_err(map_reqwest_error)?;
        parse_empty_response(resp)
    }

    pub fn get_bytes(&self, url: &str) -> Result<Vec<u8>, SyncError> {
        let mut current_url = self.parse_url(url)?;
        for _ in 0..5 {
            let headers = self.build_headers_for_url(&current_url);
            let resp = self
                .client
                .get(current_url.clone())
                .headers(headers)
                .send()
                .map_err(map_reqwest_error)?;
            if resp.status().is_redirection() {
                if let Some(location) = resp.headers().get(LOCATION) {
                    current_url = self.resolve_redirect(&current_url, location)?;
                    continue;
                }
            }
            return parse_bytes_response(resp);
        }
        Err(SyncError::InvalidResponse("too many redirects".to_string()))
    }

    pub fn head_status(&self, path: &str) -> Result<u16, SyncError> {
        let url = format!("{}{}", self.base_url, path);
        self.head_status_url(&url)
    }

    fn head_status_url(&self, url: &str) -> Result<u16, SyncError> {
        let mut current_url = self.parse_url(url)?;
        for _ in 0..5 {
            let headers = self.build_headers_for_url(&current_url);
            let resp = self
                .client
                .head(current_url.clone())
                .headers(headers)
                .send()
                .map_err(map_reqwest_error)?;
            let status = resp.status().as_u16();
            if status == 401 {
                return Err(SyncError::Unauthorized);
            }
            if resp.status().is_redirection() {
                if let Some(location) = resp.headers().get(LOCATION) {
                    current_url = self.resolve_redirect(&current_url, location)?;
                    continue;
                }
            }
            return Ok(status);
        }
        Err(SyncError::InvalidResponse("too many redirects".to_string()))
    }

    pub fn put_bytes(
        &self,
        url: &str,
        body: &[u8],
        headers: &[(&str, String)],
    ) -> Result<(), SyncError> {
        let mut header_map = HeaderMap::new();
        for (name, value) in headers {
            let header_name = HeaderName::from_bytes(name.as_bytes())
                .map_err(|_| SyncError::InvalidResponse("invalid header name".to_string()))?;
            let header_value = HeaderValue::from_str(value)
                .map_err(|_| SyncError::InvalidResponse("invalid header value".to_string()))?;
            header_map.insert(header_name, header_value);
        }

        let mut current_url = self.parse_url(url)?;
        for _ in 0..5 {
            let resp = self
                .client
                .put(current_url.clone())
                .headers(header_map.clone())
                .body(body.to_vec())
                .send()
                .map_err(map_reqwest_error)?;

            if resp.status().is_redirection() {
                if let Some(location) = resp.headers().get(LOCATION) {
                    current_url = self.resolve_redirect(&current_url, location)?;
                    continue;
                }
            }

            return parse_empty_response(resp);
        }

        Err(SyncError::InvalidResponse("too many redirects".to_string()))
    }

    fn parse_url(&self, url: &str) -> Result<Url, SyncError> {
        Url::parse(url).map_err(|_| SyncError::InvalidResponse("invalid url".to_string()))
    }

    fn resolve_redirect(
        &self,
        current_url: &Url,
        location: &HeaderValue,
    ) -> Result<Url, SyncError> {
        let next = location
            .to_str()
            .map_err(|_| SyncError::InvalidResponse("invalid redirect location".to_string()))?;
        Url::parse(next)
            .or_else(|_| current_url.join(next))
            .map_err(|_| SyncError::InvalidResponse("invalid redirect location".to_string()))
    }

    fn is_same_origin(&self, url: &Url) -> bool {
        self.base_origin.scheme() == url.scheme()
            && self.base_origin.host_str() == url.host_str()
            && self.base_origin.port_or_known_default() == url.port_or_known_default()
    }

    fn build_headers_for_url(&self, url: &Url) -> HeaderMap {
        if self.is_same_origin(url) {
            self.build_headers()
        } else {
            self.build_public_headers()
        }
    }

    fn build_public_headers(&self) -> HeaderMap {
        let mut headers = HeaderMap::new();
        if let Some(agent) = &self.user_agent {
            if let Ok(value) = HeaderValue::from_str(agent) {
                headers.insert("User-Agent", value);
            }
        }
        headers
    }

    fn build_headers(&self) -> HeaderMap {
        let mut headers = HeaderMap::new();
        if let Some(agent) = &self.user_agent {
            if let Ok(value) = HeaderValue::from_str(agent) {
                headers.insert("User-Agent", value);
            }
        }
        if let Some(pkg) = &self.client_package {
            if let Ok(value) = HeaderValue::from_str(pkg) {
                headers.insert("X-Client-Package", value);
            }
        }
        if let Some(version) = &self.client_version {
            if let Ok(value) = HeaderValue::from_str(version) {
                headers.insert("X-Client-Version", value);
            }
        }
        headers.insert(
            "x-request-id",
            HeaderValue::from_str(&Uuid::new_v4().to_string()).unwrap(),
        );
        if let Ok(value) = HeaderValue::from_str(&self.auth_token) {
            headers.insert("X-Auth-Token", value);
        }
        headers
    }
}

#[derive(Debug, serde::Deserialize)]
struct ErrorResponse {
    code: Option<String>,
    message: Option<String>,
}

fn parse_json_response<T: DeserializeOwned>(resp: Response) -> Result<T, SyncError> {
    let status = resp.status().as_u16();
    if status == 401 {
        return Err(SyncError::Unauthorized);
    }
    if status >= 300 {
        let body = resp.text().unwrap_or_default();
        return Err(map_error_response(status, &body));
    }
    resp.json::<T>().map_err(map_reqwest_error)
}

fn parse_empty_response(resp: Response) -> Result<(), SyncError> {
    let status = resp.status().as_u16();
    if status == 401 {
        return Err(SyncError::Unauthorized);
    }
    if status >= 300 {
        let body = resp.text().unwrap_or_default();
        return Err(map_error_response(status, &body));
    }
    Ok(())
}

fn parse_bytes_response(resp: Response) -> Result<Vec<u8>, SyncError> {
    let status = resp.status().as_u16();
    if status == 401 {
        return Err(SyncError::Unauthorized);
    }
    if status >= 300 {
        let body = resp.text().unwrap_or_default();
        return Err(map_error_response(status, &body));
    }
    resp.bytes()
        .map(|bytes| bytes.to_vec())
        .map_err(map_reqwest_error)
}

fn map_error_response(status: u16, body: &str) -> SyncError {
    if let Ok(err) = serde_json::from_str::<ErrorResponse>(body) {
        if let Some(code) = err.code.clone() {
            if matches!(
                code.as_str(),
                "LLMCHAT_MESSAGE_LIMIT_REACHED"
                    | "LLMCHAT_ATTACHMENT_LIMIT_REACHED"
                    | "LLMCHAT_PAYLOAD_TOO_LARGE"
            ) {
                return SyncError::LimitReached {
                    code,
                    message: err.message,
                };
            }
        }
        return SyncError::Http {
            status,
            message: err.message.unwrap_or_else(|| body.to_string()),
            code: err.code,
        };
    }
    SyncError::Http {
        status,
        message: body.to_string(),
        code: None,
    }
}

fn map_reqwest_error(err: reqwest::Error) -> SyncError {
    if let Some(status) = err.status() {
        SyncError::Http {
            status: status.as_u16(),
            message: err.to_string(),
            code: None,
        }
    } else {
        SyncError::Http {
            status: 0,
            message: err.to_string(),
            code: None,
        }
    }
}
