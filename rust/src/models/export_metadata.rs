use chrono::{DateTime, Local, TimeZone};
use serde::{Deserialize, Deserializer, Serialize, Serializer};

/// Custom serializer for timestamp fields to match Go CLI's ISO 8601 format
fn serialize_timestamp_as_iso8601<S>(
    timestamp_micros: &i64,
    serializer: S,
) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    let timestamp_secs = timestamp_micros / 1_000_000;
    let timestamp_nanos = ((timestamp_micros % 1_000_000) * 1000) as u32;

    let datetime = Local
        .timestamp_opt(timestamp_secs, timestamp_nanos)
        .single()
        .ok_or_else(|| serde::ser::Error::custom("Invalid timestamp"))?;

    // Format with milliseconds and timezone offset (matching Go CLI format)
    let iso_string = datetime.to_rfc3339_opts(chrono::SecondsFormat::Millis, true);

    serializer.serialize_str(&iso_string)
}

/// Custom deserializer that can handle both i64 and ISO string timestamps
fn deserialize_timestamp_from_iso_or_i64<'de, D>(deserializer: D) -> Result<i64, D::Error>
where
    D: Deserializer<'de>,
{
    use serde::de::Error;

    #[derive(Deserialize)]
    #[serde(untagged)]
    enum TimestampFormat {
        Microseconds(i64),
        IsoString(String),
    }

    match TimestampFormat::deserialize(deserializer)? {
        TimestampFormat::Microseconds(micros) => Ok(micros),
        TimestampFormat::IsoString(s) => {
            // Parse ISO string back to microseconds
            DateTime::parse_from_rfc3339(&s)
                .map(|dt| dt.timestamp_micros())
                .map_err(|e| Error::custom(format!("Invalid ISO timestamp: {}", e)))
        }
    }
}

/// Album metadata matching Go's export.AlbumMetadata structure
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AlbumMetadata {
    pub id: i64,
    #[serde(rename = "ownerID")]
    pub owner_id: i64,
    pub album_name: String,
    pub is_deleted: bool,
    /// Account IDs that own this album (for shared export directories)
    #[serde(rename = "accountOwnerIDs")]
    pub account_owner_ids: Vec<i64>,
    /// Folder name on disk (excluded from JSON)
    #[serde(skip)]
    pub folder_name: String,
}

impl AlbumMetadata {
    pub fn new(id: i64, owner_id: i64, album_name: String, account_id: i64) -> Self {
        Self {
            id,
            owner_id,
            album_name,
            is_deleted: false,
            account_owner_ids: vec![account_id],
            folder_name: String::new(),
        }
    }
}

/// File metadata matching Go's export.DiskFileMetadata structure
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DiskFileMetadata {
    pub title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub location: Option<Location>,
    #[serde(
        serialize_with = "serialize_timestamp_as_iso8601",
        deserialize_with = "deserialize_timestamp_from_iso_or_i64"
    )]
    pub creation_time: i64, // Unix timestamp in microseconds (serialized as ISO 8601)
    #[serde(
        serialize_with = "serialize_timestamp_as_iso8601",
        deserialize_with = "deserialize_timestamp_from_iso_or_i64"
    )]
    pub modification_time: i64, // Unix timestamp in microseconds (serialized as ISO 8601)
    pub info: FileInfo,
    /// Meta filename on disk (excluded from JSON)
    #[serde(skip)]
    pub meta_file_name: String,
}

/// File info matching Go's export.Info structure
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileInfo {
    pub id: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hash: Option<String>,
    #[serde(rename = "ownerID")]
    pub owner_id: i64,
    /// Multiple filenames for live photos or burst photos
    pub file_names: Vec<String>,
}

/// Location metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Location {
    pub latitude: f64,
    pub longitude: f64,
}

impl DiskFileMetadata {
    pub fn from_file(
        file: &crate::api::models::File,
        metadata: Option<&crate::models::metadata::FileMetadata>,
        filename: String,
    ) -> Self {
        // Extract metadata values
        let (title, location, creation_time) = if let Some(meta) = metadata {
            let title = meta.get_title().unwrap_or(&filename).to_string();
            let location = meta.latitude.and_then(|lat| {
                meta.longitude.map(|lon| Location {
                    latitude: lat,
                    longitude: lon,
                })
            });

            // Use creation time from metadata if available
            let creation_time = meta.creation_time.unwrap_or(file.updation_time);

            (title, location, creation_time)
        } else {
            let title = filename.clone();
            let creation_time = file.updation_time;
            (title, None, creation_time)
        };

        // Use modification time from metadata or fall back to updation time
        let modification_time = metadata
            .and_then(|m| m.modification_time)
            .unwrap_or(file.updation_time);

        // Get hash from metadata
        let hash = metadata.and_then(|m| {
            m.hash
                .as_ref()
                .or(m.image_hash.as_ref())
                .or(m.video_hash.as_ref())
                .cloned()
        });

        Self {
            title,
            description: None, // FileMetadata doesn't have description field
            location,
            creation_time,
            modification_time,
            info: FileInfo {
                id: file.id,
                hash,
                owner_id: file.owner_id,
                file_names: vec![filename],
            },
            meta_file_name: String::new(),
        }
    }

    pub fn add_file_name(&mut self, filename: String) {
        if !self.info.file_names.contains(&filename) {
            self.info.file_names.push(filename);
        }
    }
}
