pub mod auth;
pub mod contacts;
pub mod legacy;

use uuid::Uuid;

pub fn endpoint() -> String {
    std::env::var("ENTE_E2E_ENDPOINT").unwrap_or_else(|_| "http://localhost:8080".to_string())
}

pub async fn assert_server_or_skip(endpoint: &str, test_name: &str) -> bool {
    let ping_url = format!("{endpoint}/ping");
    match reqwest::get(&ping_url).await {
        Ok(response) if response.status().is_success() => true,
        Ok(response) => {
            eprintln!(
                "skipping {test_name}: {ping_url} returned {}",
                response.status()
            );
            false
        }
        Err(error) => {
            eprintln!("skipping {test_name}: could not reach {ping_url}: {error}");
            false
        }
    }
}

pub fn unique_test_email(prefix: &str) -> String {
    format!("{prefix}-{}@ente-rust-test.org", Uuid::new_v4())
}

pub fn unique_password(prefix: &str) -> String {
    format!("{prefix}-{}!", Uuid::new_v4().simple())
}
