use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::fs;
use std::path::{Path, PathBuf};

const XMP_MARKER_BEGIN: &[u8] = b"<x:xmpmeta";
const XMP_MARKER_END: &[u8] = b"</x:xmpmeta>";
const ITEM_LENGTH_OFFSET_KEY: &str = "Item:Length";
const GCAMERA_MOTION_PHOTO: &str = "GCamera:MotionPhoto";
const ITEM_MIME_TYPE: &str = "Item:Mime";
const FILE_OFFSET_KEYS: [&str; 2] = [ITEM_LENGTH_OFFSET_KEY, "GCamera:MicroVideoOffset"];
const MP4_HEADER_PATTERN: [u8; 16] = [
    0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32, 0x00, 0x00, 0x00, 0x00,
];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VideoIndex {
    pub start: usize,
    pub end: usize,
}

#[derive(Debug)]
pub enum MotionPhotoError {
    Io(std::io::Error),
    Xml(String),
    InvalidIndex,
    VideoNotFound,
}

impl Display for MotionPhotoError {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::Io(err) => write!(f, "io error: {err}"),
            Self::Xml(err) => write!(f, "xmp parse error: {err}"),
            Self::InvalidIndex => write!(f, "invalid video index"),
            Self::VideoNotFound => write!(f, "unable to find video index"),
        }
    }
}

impl std::error::Error for MotionPhotoError {}

impl From<std::io::Error> for MotionPhotoError {
    fn from(value: std::io::Error) -> Self {
        Self::Io(value)
    }
}

pub fn get_motion_video_index_from_path<P: AsRef<Path>>(
    file_path: P,
) -> Result<Option<VideoIndex>, MotionPhotoError> {
    let bytes = fs::read(file_path)?;
    Ok(get_motion_video_index(&bytes))
}

fn get_motion_video_index(bytes: &[u8]) -> Option<VideoIndex> {
    if let Some(start) = find_subslice(bytes, &MP4_HEADER_PATTERN) {
        return Some(VideoIndex {
            start,
            end: bytes.len(),
        });
    }

    extract_video_index_from_xmp(bytes)
}

pub fn extract_motion_video_from_path<P: AsRef<Path>>(
    file_path: P,
    index: Option<VideoIndex>,
) -> Result<Option<Vec<u8>>, MotionPhotoError> {
    let bytes = fs::read(file_path)?;
    extract_motion_video(&bytes, index).map(Some)
}

fn extract_motion_video(
    bytes: &[u8],
    index: Option<VideoIndex>,
) -> Result<Vec<u8>, MotionPhotoError> {
    let video_index = index.or_else(|| get_motion_video_index(bytes));
    let video_index = match video_index {
        Some(value) => value,
        None => return Err(MotionPhotoError::VideoNotFound),
    };

    if video_index.start >= video_index.end || video_index.end > bytes.len() {
        return Err(MotionPhotoError::InvalidIndex);
    }

    Ok(bytes[video_index.start..video_index.end].to_vec())
}

pub fn extract_motion_video_file_from_path<P: AsRef<Path>, Q: AsRef<Path>>(
    file_path: P,
    destination_directory: Q,
    file_name: &str,
    index: Option<VideoIndex>,
) -> Result<Option<PathBuf>, MotionPhotoError> {
    let video = match extract_motion_video_from_path(file_path, index)? {
        Some(data) => data,
        None => return Ok(None),
    };
    fs::create_dir_all(destination_directory.as_ref())?;
    let output = destination_directory.as_ref().join(file_name);
    fs::write(&output, video)?;
    Ok(Some(output))
}

pub fn extract_xmp_from_path<P: AsRef<Path>>(
    file_path: P,
) -> Result<HashMap<String, String>, MotionPhotoError> {
    let bytes = fs::read(file_path)?;
    extract_xmp(&bytes)
}

fn extract_xmp(source: &[u8]) -> Result<HashMap<String, String>, MotionPhotoError> {
    let (begin, end) = extract_xmp_bounds(source)
        .ok_or_else(|| MotionPhotoError::Xml("xmp markers not found".to_string()))?;
    let xml_bytes = &source[begin..end];
    parse_xmp_attributes(xml_bytes)
}

fn extract_video_index_from_xmp(bytes: &[u8]) -> Option<VideoIndex> {
    let xmp_data = extract_xmp(bytes).ok()?;
    let size = bytes.len();

    for offset_key in FILE_OFFSET_KEYS {
        let Some(raw_offset) = xmp_data.get(offset_key) else {
            continue;
        };
        let Ok(offset_from_end) = raw_offset.parse::<usize>() else {
            continue;
        };

        if offset_key == ITEM_LENGTH_OFFSET_KEY
            && offset_from_end + offset_from_end < size
            && !has_motion_photo_tags(&xmp_data)
        {
            continue;
        }

        if offset_from_end == 0 || offset_from_end > size {
            continue;
        }

        return Some(VideoIndex {
            start: size - offset_from_end,
            end: size,
        });
    }

    None
}

fn has_motion_photo_tags(xmp_data: &HashMap<String, String>) -> bool {
    if xmp_data.contains_key(GCAMERA_MOTION_PHOTO) {
        return true;
    }

    xmp_data
        .get(ITEM_MIME_TYPE)
        .map(|value| value.starts_with("video"))
        .unwrap_or(false)
}

fn extract_xmp_bounds(source: &[u8]) -> Option<(usize, usize)> {
    let offset_begin = find_subslice(source, XMP_MARKER_BEGIN)?;
    let offset_end_start = find_subslice(&source[offset_begin..], XMP_MARKER_END)? + offset_begin;
    let offset_end = offset_end_start + XMP_MARKER_END.len();
    Some((offset_begin, offset_end))
}

fn parse_xmp_attributes(xml_bytes: &[u8]) -> Result<HashMap<String, String>, MotionPhotoError> {
    use quick_xml::Reader;
    use quick_xml::events::Event;

    let xml_buffer = String::from_utf8_lossy(xml_bytes);
    let mut reader = Reader::from_str(&xml_buffer);
    let mut result = HashMap::<String, String>::new();
    let mut scratch = Vec::<u8>::new();

    loop {
        match reader.read_event_into(&mut scratch) {
            Ok(Event::Start(element)) | Ok(Event::Empty(element)) => {
                for attribute in element.attributes() {
                    let attribute = attribute.map_err(|err| {
                        MotionPhotoError::Xml(format!("invalid attribute: {err}"))
                    })?;
                    let key = std::str::from_utf8(attribute.key.as_ref())
                        .map_err(|err| MotionPhotoError::Xml(format!("invalid key bytes: {err}")))?
                        .trim()
                        .to_string();
                    if key.starts_with("xmlns:") || key.starts_with("xml:") {
                        continue;
                    }

                    let value = attribute
                        .decode_and_unescape_value(reader.decoder())
                        .map_err(|err| MotionPhotoError::Xml(format!("invalid value: {err}")))?
                        .to_string();
                    result.insert(key, value);
                }
            }
            Ok(Event::Eof) => break,
            Ok(_) => {}
            Err(err) => return Err(MotionPhotoError::Xml(format!("xml parse failed: {err}"))),
        }
        scratch.clear();
    }

    Ok(result)
}

fn find_subslice(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    if needle.is_empty() {
        return Some(0);
    }
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    fn xmp_with_offset(offset: usize, extra_attributes: &str) -> String {
        format!(
            r#"<x:xmpmeta><rdf:RDF><rdf:Description xmlns:x="adobe:ns:meta/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" Item:Length="{offset}" {extra_attributes} /></rdf:RDF></x:xmpmeta>"#
        )
    }

    fn append_video_payload(mut bytes: Vec<u8>, payload_len: usize) -> Vec<u8> {
        bytes.extend(std::iter::repeat_n(0xAB, payload_len));
        bytes
    }

    fn bytes_with_xmp_and_video(offset: usize, extra_attributes: &str) -> Vec<u8> {
        let mut bytes = b"jpeg-prefix-data".to_vec();
        bytes.extend_from_slice(xmp_with_offset(offset, extra_attributes).as_bytes());
        append_video_payload(bytes, offset)
    }

    #[test]
    fn finds_mp4_header_in_jpeg_like_file() {
        let mut bytes = b"jpeg-prefix".to_vec();
        bytes.extend_from_slice(&MP4_HEADER_PATTERN);
        bytes.extend_from_slice(&[1, 2, 3, 4]);

        let index = get_motion_video_index(&bytes).expect("video index should exist");
        assert_eq!(index.start, "jpeg-prefix".len());
        assert_eq!(index.end, bytes.len());
    }

    #[test]
    fn finds_xmp_offset_for_jpeg_like_file() {
        let bytes = bytes_with_xmp_and_video(24, "GCamera:MotionPhoto=\"1\"");
        let index = get_motion_video_index(&bytes).expect("video index should exist");
        assert_eq!(index.start, bytes.len() - 24);
        assert_eq!(index.end, bytes.len());
    }

    #[test]
    fn finds_xmp_offset_for_heic_like_file() {
        let mut bytes = b"heic-prefix-data".to_vec();
        bytes.extend_from_slice(xmp_with_offset(32, "Item:Mime=\"video/mp4\"").as_bytes());
        bytes = append_video_payload(bytes, 32);

        let index = get_motion_video_index(&bytes).expect("video index should exist");
        assert_eq!(index.start, bytes.len() - 32);
        assert_eq!(index.end, bytes.len());
    }

    #[test]
    fn returns_none_for_non_motion_file() {
        let bytes = b"plain-still-image-data-without-motion-video-or-xmp".to_vec();
        assert_eq!(get_motion_video_index(&bytes), None);
    }

    #[test]
    fn skips_invalid_item_length_without_motion_tags() {
        let mut bytes = b"prefix-data".to_vec();
        bytes.extend_from_slice(xmp_with_offset(8, "").as_bytes());
        bytes.extend_from_slice(b"small-tail");
        assert_eq!(get_motion_video_index(&bytes), None);
    }

    #[test]
    fn extracts_video_bytes_for_valid_index() {
        let bytes = bytes_with_xmp_and_video(20, "GCamera:MotionPhoto=\"1\"");
        let video = extract_motion_video(&bytes, None).expect("video bytes should extract");
        assert_eq!(video.len(), 20);
        assert!(video.iter().all(|byte| *byte == 0xAB));
    }

    #[test]
    fn extracts_xmp_attributes() {
        let bytes = bytes_with_xmp_and_video(
            16,
            "GPano:ProjectionType=\"equirectangular\" GCamera:MotionPhoto=\"1\"",
        );
        let xmp = extract_xmp(&bytes).expect("xmp must parse");
        assert_eq!(
            xmp.get("GPano:ProjectionType"),
            Some(&"equirectangular".to_string())
        );
        assert_eq!(xmp.get("GCamera:MotionPhoto"), Some(&"1".to_string()));
    }

    #[test]
    fn path_apis_work_for_various_file_types() {
        let temp = tempdir().expect("temp dir");
        let jpeg_motion = temp.path().join("motion.jpg");
        let heic_motion = temp.path().join("motion.heic");
        let non_motion = temp.path().join("normal.jpg");

        fs::write(
            &jpeg_motion,
            bytes_with_xmp_and_video(40, "GCamera:MotionPhoto=\"1\""),
        )
        .expect("write jpeg motion");

        fs::write(
            &heic_motion,
            bytes_with_xmp_and_video(28, "Item:Mime=\"video/mp4\""),
        )
        .expect("write heic motion");

        fs::write(&non_motion, b"non-motion-image").expect("write still");

        assert!(
            get_motion_video_index_from_path(&jpeg_motion)
                .expect("jpeg read")
                .is_some()
        );
        assert!(
            get_motion_video_index_from_path(&heic_motion)
                .expect("heic read")
                .is_some()
        );
        assert_eq!(
            get_motion_video_index_from_path(&non_motion).expect("still read"),
            None
        );
    }
}
