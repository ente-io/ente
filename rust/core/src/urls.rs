//! URL construction utilities.

/// Production API base URL.
pub const PRODUCTION_API_BASE_URL: &str = "https://api.ente.com";

/// Generate the download URL for a file.
pub fn file_download_url(api_base_url: &str, file_id: i64) -> String {
    if api_base_url == PRODUCTION_API_BASE_URL {
        format!("https://files.ente.io/?fileID={}", file_id)
    } else {
        format!("{}/files/download/{}", api_base_url, file_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_production_url() {
        let url = file_download_url(PRODUCTION_API_BASE_URL, 12345);
        assert_eq!(url, "https://files.ente.io/?fileID=12345");
    }

    #[test]
    fn test_custom_server() {
        let url = file_download_url("https://my-server.example.com", 99);
        assert_eq!(url, "https://my-server.example.com/files/download/99");
    }
}
