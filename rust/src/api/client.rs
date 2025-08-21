use crate::{Error, Result};
use reqwest::{Client, Response};
use std::time::Duration;

const ENTE_API_ENDPOINT: &str = "https://api.ente.io";
const TOKEN_HEADER: &str = "X-Auth-Token";
const CLIENT_PKG_HEADER: &str = "X-Client-Package";

pub struct ApiClient {
    client: Client,
    base_url: String,
}

impl ApiClient {
    pub fn new(base_url: Option<String>) -> Result<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(30))
            .build()?;
            
        Ok(Self {
            client,
            base_url: base_url.unwrap_or_else(|| ENTE_API_ENDPOINT.to_string()),
        })
    }
    
    // TODO: Implement API methods
}