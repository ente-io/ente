use crate::{
    image::decode::decode_image_from_path,
    ml::face::thumbnail::{FaceBox, generate_face_thumbnails as generate_face_thumbnails_impl},
};

#[derive(Clone, Debug)]
pub struct RustFaceBox {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

#[derive(Clone, Debug)]
pub struct RustFaceThumbnailBatch {
    pub thumbnails: Vec<Vec<u8>>,
    pub source_width: u32,
    pub source_height: u32,
}

pub fn generate_face_thumbnails(
    image_path: String,
    face_boxes: Vec<RustFaceBox>,
) -> Result<Vec<Vec<u8>>, String> {
    generate_face_thumbnails_with_metadata(image_path, face_boxes).map(|batch| batch.thumbnails)
}

pub fn generate_face_thumbnails_with_metadata(
    image_path: String,
    face_boxes: Vec<RustFaceBox>,
) -> Result<RustFaceThumbnailBatch, String> {
    let decoded = decode_image_from_path(&image_path).map_err(|e| e.to_string())?;
    let face_boxes = parse_face_boxes(face_boxes)?;
    let thumbnails =
        generate_face_thumbnails_impl(&decoded, &face_boxes).map_err(|e| e.to_string())?;

    Ok(RustFaceThumbnailBatch {
        thumbnails,
        source_width: decoded.dimensions.width,
        source_height: decoded.dimensions.height,
    })
}

fn parse_face_boxes(face_boxes: Vec<RustFaceBox>) -> Result<Vec<FaceBox>, String> {
    face_boxes
        .into_iter()
        .enumerate()
        .map(|(index, face_box)| {
            FaceBox::try_from(face_box)
                .map_err(|e| format!("invalid face box at index {index}: {e}"))
        })
        .collect::<Result<Vec<_>, _>>()
}

impl TryFrom<RustFaceBox> for FaceBox {
    type Error = String;

    fn try_from(value: RustFaceBox) -> Result<Self, Self::Error> {
        if !value.x.is_finite()
            || !value.y.is_finite()
            || !value.width.is_finite()
            || !value.height.is_finite()
        {
            return Err("non-finite values are not allowed".to_string());
        }
        if value.width <= 0.0 || value.height <= 0.0 {
            return Err("width and height must be greater than 0".to_string());
        }

        Ok(Self {
            x: value.x as f32,
            y: value.y as f32,
            width: value.width as f32,
            height: value.height as f32,
        })
    }
}
