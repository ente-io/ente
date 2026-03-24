use image::{
    ColorType, ImageEncoder,
    codecs::{jpeg::JpegEncoder, png::PngEncoder},
};

use crate::ml::error::{MlError, MlResult};

pub const FACE_THUMBNAIL_JPEG_QUALITY: u8 = 90;
pub const FACE_THUMBNAIL_MIN_DIMENSION: u32 = 512;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EncodedImageFormat {
    Jpeg { quality: u8 },
    Png,
}

pub fn encode_rgb(
    rgb_bytes: &[u8],
    width: u32,
    height: u32,
    format: EncodedImageFormat,
) -> MlResult<Vec<u8>> {
    if width == 0 || height == 0 {
        return Err(MlError::Postprocess(
            "cannot encode image with zero width or height".to_string(),
        ));
    }

    let expected_len = width as usize * height as usize * 3;
    if rgb_bytes.len() != expected_len {
        return Err(MlError::Postprocess(format!(
            "invalid RGB buffer length {}, expected {} for {}x{}",
            rgb_bytes.len(),
            expected_len,
            width,
            height
        )));
    }

    let mut encoded = Vec::new();
    match format {
        EncodedImageFormat::Jpeg { quality } => {
            JpegEncoder::new_with_quality(&mut encoded, quality)
                .write_image(rgb_bytes, width, height, ColorType::Rgb8.into())
                .map_err(|e| MlError::Postprocess(format!("failed to encode JPEG: {e}")))?;
        }
        EncodedImageFormat::Png => {
            PngEncoder::new(&mut encoded)
                .write_image(rgb_bytes, width, height, ColorType::Rgb8.into())
                .map_err(|e| MlError::Postprocess(format!("failed to encode PNG: {e}")))?;
        }
    }
    Ok(encoded)
}

#[cfg(test)]
mod tests {
    use image::ImageFormat;

    use super::{EncodedImageFormat, FACE_THUMBNAIL_JPEG_QUALITY, encode_rgb};

    #[test]
    fn encode_rgb_jpeg_produces_valid_jpeg() {
        let rgb = vec![255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 255];
        let encoded = encode_rgb(
            &rgb,
            2,
            2,
            EncodedImageFormat::Jpeg {
                quality: FACE_THUMBNAIL_JPEG_QUALITY,
            },
        )
        .expect("jpeg encoding should succeed");

        assert!(!encoded.is_empty());
        image::load_from_memory_with_format(&encoded, ImageFormat::Jpeg)
            .expect("encoded bytes should be valid JPEG");
    }

    #[test]
    fn encode_rgb_rejects_invalid_buffer_size() {
        let invalid_rgb = vec![0, 1, 2];
        let result = encode_rgb(
            &invalid_rgb,
            2,
            2,
            EncodedImageFormat::Jpeg {
                quality: FACE_THUMBNAIL_JPEG_QUALITY,
            },
        );

        assert!(result.is_err());
    }
}
