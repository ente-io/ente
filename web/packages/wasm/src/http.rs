//! WASM bindings for the HTTP client.

use ente_core::http::HttpClient as CoreHttpClient;
use wasm_bindgen::prelude::*;

/// HTTP client for making requests to the Ente API.
#[wasm_bindgen]
pub struct HttpClient {
    inner: CoreHttpClient,
}

#[wasm_bindgen]
impl HttpClient {
    /// Create a client with the given base URL.
    #[wasm_bindgen(constructor)]
    pub fn new(base_url: &str) -> Self {
        Self {
            inner: CoreHttpClient::new(base_url),
        }
    }

    /// GET request, returns response body as text.
    pub async fn get(&self, path: &str) -> Result<String, JsError> {
        self.inner
            .get(path)
            .await
            .map_err(|e| JsError::new(&e.to_string()))
    }
}
