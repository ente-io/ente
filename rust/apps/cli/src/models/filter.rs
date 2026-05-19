/// Export filter options
#[derive(Debug, Clone, Default)]
pub struct ExportFilter {
    /// Include shared albums
    pub include_shared: bool,

    /// Include hidden albums
    pub include_hidden: bool,

    /// Specific album names to export (None means all)
    pub albums: Option<Vec<String>>,

    /// Specific user emails to export files shared with (None means all)
    pub emails: Option<Vec<String>>,
}

impl ExportFilter {
    /// Check if a collection should be included based on filters
    pub fn should_include_collection(
        &self,
        collection_name: &str,
        is_shared: bool,
        is_hidden: bool,
    ) -> bool {
        // Check shared filter
        if is_shared && !self.include_shared {
            return false;
        }

        // Check hidden filter
        if is_hidden && !self.include_hidden {
            return false;
        }

        // Check album name filter
        if let Some(ref albums) = self.albums
            && !albums.is_empty()
            && !albums.iter().any(|a| a == collection_name)
        {
            return false;
        }

        true
    }

    /// Check if a file should be included based on email filter
    pub fn should_include_file_by_owner(&self, owner_email: Option<&str>) -> bool {
        if let Some(ref emails) = self.emails
            && !emails.is_empty()
        {
            if let Some(email) = owner_email {
                return emails.iter().any(|e| e == email);
            }
            return false;
        }
        true
    }
}
