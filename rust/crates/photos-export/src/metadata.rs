use chrono::DateTime;
use ente_core::{
    b64,
    crypto::{Key, kdf},
};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value, json};

use ente_photos::{
    collections::Collection,
    files::{File, Kind},
    source::{self, Documents, MetadataError},
};

#[derive(Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Root {
    pub format: String,
    pub version: u32,
    pub source_verifier: String,
}

impl Root {
    pub fn new(master_key: &Key) -> ente_core::crypto::Result<Self> {
        Ok(Self {
            format: "ente-photos-export".into(),
            version: 1,
            source_verifier: b64::encode(&kdf::derive_subkey(master_key, 32, 1, b"photoexp")?),
        })
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    Original,
    Image,
    Video,
}

impl Role {
    pub fn name(&self) -> &'static str {
        match self {
            Self::Original => "original",
            Self::Image => "image",
            Self::Video => "video",
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct Component {
    pub role: Role,
    pub path: String,
    pub size: u64,
    pub hash: String,
}

pub fn album(
    album: &Collection,
    documents: &Documents,
    user_id: i64,
) -> Result<(Value, Vec<String>), MetadataError> {
    let private: AlbumPrivate = source::optional(
        documents.private.as_deref(),
        "invalid album private metadata",
    )?;
    let shared: AlbumShared =
        source::optional(documents.shared.as_deref(), "invalid album sharee metadata")?;
    let public: AlbumPublic =
        source::optional(documents.public.as_deref(), "invalid album public metadata")?;
    let owned = album.owner_id == user_id;
    let mut metadata = json!({
        "albumID": album.id.to_string(), "type": album.kind.name(), "visibility": album.visibility.name(),
    });
    optional(
        &mut metadata,
        "displayOrder",
        if owned { private.order } else { shared.order },
    );
    optional(
        &mut metadata,
        "muted",
        (!owned).then_some(shared.mute).flatten(),
    );
    optional(
        &mut metadata,
        "sortOrder",
        public
            .asc
            .map(|asc| if asc { "ascending" } else { "descending" }),
    );
    optional(&mut metadata, "description", public.caption.as_deref());
    optional(
        &mut metadata,
        "coverFileID",
        public.cover_id.map(|id| id.to_string()),
    );
    optional(&mut metadata, "layout", public.layout.as_deref());
    let mut warnings = Vec::new();
    unfamiliar(
        documents.private.as_deref(),
        &["visibility", "subType", "order"],
        &mut warnings,
    );
    unfamiliar(
        documents.shared.as_deref(),
        &["visibility", "mute", "order"],
        &mut warnings,
    );
    unfamiliar(
        documents.public.as_deref(),
        &["asc", "coverID", "layout", "caption"],
        &mut warnings,
    );
    Ok((json!({"title": album.name, "ente": metadata}), warnings))
}

pub fn file(file: &File, documents: &Documents) -> Result<Value, MetadataError> {
    let mut original: Map<String, Value> =
        source::parse(&documents.original, "invalid original file metadata")?;
    let mut public: Map<String, Value> =
        source::optional(documents.public.as_deref(), "invalid public file metadata")?;
    for field in [
        "localID",
        "deviceFolder",
        "subType",
        "version",
        "exif",
        "hasStaticThumbnail",
    ] {
        original.remove(field);
    }
    for field in ["sv", "noThumb"] {
        public.remove(field);
    }
    if public.get("editedName").and_then(Value::as_str).is_some() {
        original.remove("title");
    }
    if public.get("lat").and_then(Value::as_f64).is_some()
        && public.get("long").and_then(Value::as_f64).is_some()
    {
        original.remove("latitude");
        original.remove("longitude");
    }
    if public
        .get("editedTime")
        .and_then(Value::as_i64)
        .is_some_and(|time| time != 0)
    {
        original.remove("creationTime");
    }
    if public.get("uploaderName").and_then(Value::as_str).is_some() {
        original.remove("uploaderName");
    }
    let mut metadata = json!({
        "fileID": file.id.to_string(),
        "type": if file.kind == Kind::LivePhoto { "livePhoto" } else { file.kind.name() },
        "metadata": original,
    });
    if documents.public.is_some() {
        metadata["pubMagicMetadata"] = json!(public);
    }
    if let Some(private) = &documents.private {
        metadata["magicMetadata"] = json!(source::parse::<Map<String, Value>>(
            private,
            "invalid private file metadata",
        )?);
    }
    let taken = common_time(file.created_at_micros)?;
    let (latitude, longitude) = file.location.as_ref().map_or((0.0, 0.0), |location| {
        (location.latitude, location.longitude)
    });
    let mut record = json!({
        "title": file.name,
        "photoTakenTime": taken,
        "creationTime": taken,
        "geoData": {"latitude": latitude, "longitude": longitude},
        "ente": metadata,
    });
    optional(
        &mut record,
        "modificationTime",
        file.modified_at_micros.map(common_time).transpose()?,
    );
    optional(
        &mut record,
        "description",
        file.caption
            .as_deref()
            .filter(|caption| !caption.is_empty()),
    );
    Ok(record)
}

fn optional(object: &mut Value, name: &str, value: Option<impl Into<Value>>) {
    if let Some(value) = value {
        object[name] = value.into();
    }
}

fn time(micros: i64) -> Result<DateTime<chrono::Utc>, MetadataError> {
    DateTime::from_timestamp_micros(micros)
        .ok_or(MetadataError("timestamp is outside the supported range"))
}

fn common_time(micros: i64) -> Result<Value, MetadataError> {
    let time = time(micros)?;
    Ok(
        json!({"timestamp":micros.div_euclid(1_000_000).to_string(),"formatted":time.format("%b %-d, %Y, %-I:%M:%S %p UTC").to_string()}),
    )
}

pub fn publish(
    template: &Value,
    components: &[Component],
    component: usize,
    favorited: bool,
) -> Result<Value, MetadataError> {
    let selected = components
        .get(component)
        .ok_or(MetadataError("missing media component"))?;
    let mut record = template.clone();
    record["favorited"] = json!(favorited);
    record["ente"]["component"] = json!(selected.role);
    record["ente"]["components"] = json!(components);
    Ok(record)
}

#[derive(Default, Deserialize)]
struct AlbumPrivate {
    order: Option<i64>,
}

#[derive(Default, Deserialize)]
struct AlbumShared {
    order: Option<i64>,
    mute: Option<bool>,
}

#[derive(Default, Deserialize)]
struct AlbumPublic {
    asc: Option<bool>,
    #[serde(rename = "coverID")]
    cover_id: Option<i64>,
    layout: Option<String>,
    caption: Option<String>,
}

fn unfamiliar(bytes: Option<&[u8]>, known: &[&str], warnings: &mut Vec<String>) {
    if let Some(bytes) = bytes
        && let Ok(Value::Object(fields)) = serde_json::from_slice(bytes)
    {
        for key in fields.keys() {
            if !known.contains(&key.as_str()) {
                warnings.push(key.clone());
            }
        }
    }
}
