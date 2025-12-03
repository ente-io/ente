use crate::api::client::ApiClient;
use crate::api::models::{
    Collection, File, GetCollectionsResponse, GetDiffResponse, GetFileResponse, GetFilesResponse,
    GetThumbnailUrlResponse, UserDetails,
};
use crate::models::error::Result;

/// API methods for interacting with Ente services
pub struct ApiMethods<'a> {
    api: &'a ApiClient,
}

impl<'a> ApiMethods<'a> {
    pub fn new(api: &'a ApiClient) -> Self {
        Self { api }
    }

    // ========== User Methods ==========

    /// Get user details including subscription and storage info
    pub async fn get_user_details(&self, account_id: &str) -> Result<UserDetails> {
        self.api.get("/users/details", Some(account_id)).await
    }

    // ========== Collection Methods ==========

    /// Get all collections (albums) for the authenticated user
    ///
    /// # Arguments
    /// * `account_id` - The account identifier for authentication
    /// * `since_time` - Unix timestamp in microseconds to get collections modified after this time (0 for all)
    pub async fn get_collections(
        &self,
        account_id: &str,
        since_time: i64,
    ) -> Result<Vec<Collection>> {
        let url = format!("/collections/v2?sinceTime={since_time}");
        let response: GetCollectionsResponse = self.api.get(&url, Some(account_id)).await?;
        Ok(response.collections)
    }

    /// Get a specific collection by ID
    pub async fn get_collection(&self, account_id: &str, collection_id: i64) -> Result<Collection> {
        let url = format!("/collections/{collection_id}");
        self.api.get(&url, Some(account_id)).await
    }

    // ========== File Methods ==========

    /// Get files from a specific collection with pagination
    ///
    /// # Arguments
    /// * `account_id` - The account identifier for authentication
    /// * `collection_id` - The collection ID to fetch files from
    /// * `since_time` - Unix timestamp in microseconds to get files modified after this time
    ///
    /// # Returns
    /// A tuple of (files, has_more) where has_more indicates if there are more files to fetch
    pub async fn get_collection_files(
        &self,
        account_id: &str,
        collection_id: i64,
        since_time: i64,
    ) -> Result<(Vec<File>, bool)> {
        let url =
            format!("/collections/v2/diff?collectionID={collection_id}&sinceTime={since_time}");
        let response: GetFilesResponse = self.api.get(&url, Some(account_id)).await?;
        Ok((response.diff, response.has_more))
    }

    /// Get a specific file by ID
    pub async fn get_file(
        &self,
        account_id: &str,
        collection_id: i64,
        file_id: i64,
    ) -> Result<File> {
        let url = format!("/collections/file?collectionID={collection_id}&fileID={file_id}");
        let response: GetFileResponse = self.api.get(&url, Some(account_id)).await?;
        Ok(response.file)
    }

    /// Get all files across all collections (for incremental sync)
    ///
    /// # Arguments
    /// * `account_id` - The account identifier for authentication
    /// * `since_time` - Unix timestamp in microseconds to get files modified after this time
    /// * `limit` - Maximum number of files to return (typically 500)
    ///
    /// # Returns
    /// A tuple of (files, has_more) where has_more indicates if there are more files to fetch
    pub async fn get_diff(
        &self,
        account_id: &str,
        since_time: i64,
        limit: i32,
    ) -> Result<(Vec<File>, bool)> {
        let url = format!("/diff?sinceTime={since_time}&limit={limit}");
        let response: GetDiffResponse = self.api.get(&url, Some(account_id)).await?;
        Ok((response.diff, response.has_more))
    }

    /// Get download URL for a file
    pub async fn get_file_url(&self, _account_id: &str, file_id: i64) -> Result<String> {
        // Check if we're using the default API endpoint
        let base_url = &self.api.base_url;
        if base_url == "https://api.ente.io" {
            // Use the CDN URL for production
            Ok(format!("https://files.ente.io/?fileID={file_id}"))
        } else {
            // For custom/dev environments, use direct download URL
            // The Go implementation shows this is the pattern
            Ok(format!("{base_url}/files/download/{file_id}"))
        }
    }

    /// Get thumbnail URL for a file
    pub async fn get_thumbnail_url(&self, account_id: &str, file_id: i64) -> Result<String> {
        let url = format!("/files/preview/{file_id}");
        let response: GetThumbnailUrlResponse = self.api.get(&url, Some(account_id)).await?;
        Ok(response.url)
    }

    /// Download file content
    pub async fn download_file(&self, account_id: &str, file_id: i64) -> Result<Vec<u8>> {
        let url = self.get_file_url(account_id, file_id).await?;
        self.api.download_file(&url, Some(account_id)).await
    }

    /// Download thumbnail content
    pub async fn download_thumbnail(&self, account_id: &str, file_id: i64) -> Result<Vec<u8>> {
        let url = self.get_thumbnail_url(account_id, file_id).await?;
        self.api.download_file(&url, Some(account_id)).await
    }

    // ========== Trash Methods ==========

    /// Get deleted files
    pub async fn get_trash(&self, account_id: &str, since_time: i64) -> Result<(Vec<File>, bool)> {
        let url = format!("/trash/v2?sinceTime={since_time}");
        let response: GetDiffResponse = self.api.get(&url, Some(account_id)).await?;
        Ok((response.diff, response.has_more))
    }

    /// Permanently delete files from trash
    pub async fn delete_from_trash(&self, account_id: &str, file_ids: &[i64]) -> Result<()> {
        let body = serde_json::json!({
            "fileIDs": file_ids
        });
        let _: serde_json::Value = self
            .api
            .post("/trash/delete", &body, Some(account_id))
            .await?;
        Ok(())
    }

    /// Empty all trash
    pub async fn empty_trash(&self, account_id: &str) -> Result<()> {
        self.api.delete("/trash/empty", Some(account_id)).await
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_file_url_generation() {
        let api = ApiClient::new(None).unwrap();
        let methods = ApiMethods::new(&api);

        // For production endpoint, should use CDN
        let url = methods.get_file_url("test", 12345).await;
        assert!(url.is_ok());
        assert!(url.unwrap().contains("files.ente.io"));
    }
}
