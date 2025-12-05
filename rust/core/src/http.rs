use thiserror::Error;

#[derive(Error, Debug)]
pub enum Error {
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

pub struct HttpClient {
    client: reqwest::Client,
    base_url: String,
}

impl HttpClient {
    pub fn new(base_url: &str) -> Self {
        Self {
            client: reqwest::Client::new(),
            base_url: base_url.to_string(),
        }
    }

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
