//! FRB bindings for the HTTP client

use ente_core::http::HttpClient as CoreHttpClient;
use flutter_rust_bridge::frb;

/// HTTP client fro making requests to the Ente API.
#[frb(opaque)]
pub struct HttpClient {
    inner: CoreHttpClient,
}

impl HttpClient {
    /// Create a client with the given base URL.
    #[frb(sync)]
    pub fn new(base_url: String) -> HttpClient {
        Self {
            inner: CoreHttpClient::new(&base_url),
        }
    }

    /// GET request, returns response body as text.
    pub async fn get(&self, path: String) -> Result<String, String> {
        self.inner.get(&path).await.map_err(|e| e.to_string())
    }
}
