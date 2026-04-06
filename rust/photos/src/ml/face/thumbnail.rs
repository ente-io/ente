use fast_image_resize::{
    FilterType, IntoImageView, PixelType, ResizeAlg, ResizeOptions, Resizer,
    images::{Image as FirImage, ImageRef as FirImageRef},
};

use crate::image::image_compression::{
    EncodedImageFormat, FACE_THUMBNAIL_JPEG_QUALITY, FACE_THUMBNAIL_MIN_DIMENSION, encode_rgb,
};
use crate::ml::{
    error::{MlError, MlResult},
    types::DecodedImage,
};

const REGULAR_PADDING: f64 = 0.4;
const MINIMUM_PADDING: f64 = 0.1;

#[derive(Clone, Debug)]
pub struct FaceBox {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}

#[derive(Clone, Debug)]
struct CropRect {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    output_width: u32,
    output_height: u32,
}

pub fn generate_face_thumbnails(
    decoded: &DecodedImage,
    face_boxes: &[FaceBox],
) -> MlResult<Vec<Vec<u8>>> {
    if face_boxes.is_empty() {
        return Ok(Vec::new());
    }
    if decoded.dimensions.width == 0 || decoded.dimensions.height == 0 {
        return Err(MlError::Decode(
            "decoded image dimensions cannot be empty".to_string(),
        ));
    }

    let source = fir_image_ref_from_decoded(decoded)?;
    let mut resizer = Resizer::new();
    let image_width = decoded.dimensions.width as f64;
    let image_height = decoded.dimensions.height as f64;
    let mut results = Vec::with_capacity(face_boxes.len());

    for (index, face_box) in face_boxes.iter().enumerate() {
        let crop = compute_crop_rect(face_box, image_width, image_height).map_err(|e| {
            MlError::InvalidRequest(format!("invalid face box at index {index}: {e}",))
        })?;
        let (target_width, target_height) =
            dimensions_with_min_side(crop.output_width, crop.output_height)?;
        let resized =
            resize_crop_with_fir(&source, &crop, target_width, target_height, &mut resizer)?;
        let compressed = encode_rgb(
            resized.buffer(),
            target_width,
            target_height,
            EncodedImageFormat::Jpeg {
                quality: FACE_THUMBNAIL_JPEG_QUALITY,
            },
        )?;
        results.push(compressed);
    }

    Ok(results)
}

fn fir_image_ref_from_decoded(decoded: &DecodedImage) -> MlResult<FirImageRef<'_>> {
    FirImageRef::new(
        decoded.dimensions.width,
        decoded.dimensions.height,
        decoded.rgb.as_slice(),
        PixelType::U8x3,
    )
    .map_err(|e| MlError::Decode(format!("invalid decoded RGB buffer: {e}")))
}

fn compute_crop_rect(
    face_box: &FaceBox,
    image_width: f64,
    image_height: f64,
) -> Result<CropRect, String> {
    if image_width <= 0.0 || image_height <= 0.0 {
        return Err("image dimensions must be positive".to_string());
    }

    let x_min_abs = face_box.x as f64 * image_width;
    let y_min_abs = face_box.y as f64 * image_height;
    let width_abs = face_box.width as f64 * image_width;
    let height_abs = face_box.height as f64 * image_height;

    if width_abs <= 0.0 || height_abs <= 0.0 {
        return Err("face box width/height must map to positive absolute dimensions".to_string());
    }

    let x_crop = x_min_abs - width_abs * REGULAR_PADDING;
    let x_overshoot = x_crop.min(0.0).abs() / width_abs;
    let width_crop = width_abs * (1.0 + 2.0 * REGULAR_PADDING)
        - 2.0 * x_overshoot.min(REGULAR_PADDING - MINIMUM_PADDING) * width_abs;

    let y_crop = y_min_abs - height_abs * REGULAR_PADDING;
    let y_overshoot = y_crop.min(0.0).abs() / height_abs;
    let height_crop = height_abs * (1.0 + 2.0 * REGULAR_PADDING)
        - 2.0 * y_overshoot.min(REGULAR_PADDING - MINIMUM_PADDING) * height_abs;

    let x_crop_safe = x_crop.clamp(0.0, image_width);
    let y_crop_safe = y_crop.clamp(0.0, image_height);
    let width_crop_safe = width_crop.clamp(0.0, (image_width - x_crop_safe).max(0.0));
    let height_crop_safe = height_crop.clamp(0.0, (image_height - y_crop_safe).max(0.0));

    let output_width = float_to_output_dimension(width_crop_safe)
        .ok_or_else(|| format!("invalid output width from crop value {width_crop_safe}"))?;
    let output_height = float_to_output_dimension(height_crop_safe)
        .ok_or_else(|| format!("invalid output height from crop value {height_crop_safe}"))?;

    if output_width == 0 || output_height == 0 {
        return Err(format!(
            "crop dimensions resolve to zero-sized output ({output_width}x{output_height})",
        ));
    }

    Ok(CropRect {
        x: x_crop_safe,
        y: y_crop_safe,
        width: width_crop_safe,
        height: height_crop_safe,
        output_width,
        output_height,
    })
}

fn float_to_output_dimension(value: f64) -> Option<u32> {
    if !value.is_finite() || value < 0.0 {
        return None;
    }
    let truncated = value.trunc();
    if truncated > u32::MAX as f64 {
        return None;
    }
    Some(truncated as u32)
}

fn resize_crop_with_fir(
    source: &impl IntoImageView,
    crop: &CropRect,
    target_width: u32,
    target_height: u32,
    resizer: &mut Resizer,
) -> MlResult<FirImage<'static>> {
    let mut resized = FirImage::new(target_width, target_height, PixelType::U8x3);
    let filter = select_resize_filter(crop, target_width, target_height);
    let options = ResizeOptions::new()
        .crop(crop.x, crop.y, crop.width, crop.height)
        .resize_alg(ResizeAlg::Convolution(filter));
    resizer
        .resize(source, &mut resized, Some(&options))
        .map_err(|e| MlError::Postprocess(format!("failed to resize face thumbnail crop: {e}")))?;
    Ok(resized)
}

fn select_resize_filter(crop: &CropRect, target_width: u32, target_height: u32) -> FilterType {
    let scale_x = crop.width / f64::from(target_width);
    let scale_y = crop.height / f64::from(target_height);
    let max_scale = scale_x.max(scale_y);

    if max_scale < 1.0 {
        // Upscaling: CatmullRom gives sharper results than bilinear while keeping
        // artifacts reasonably controlled for faces.
        FilterType::CatmullRom
    } else if max_scale <= 1.15 {
        // Mild downscale: bilinear stays closer to legacy canvas behavior.
        FilterType::Bilinear
    } else if max_scale <= 1.5 {
        // Moderate downscale: Mitchell gives stronger antialiasing with low ringing.
        FilterType::Mitchell
    } else {
        // Heavy downscale: Lanczos3 preserves detail best.
        FilterType::Lanczos3
    }
}

fn dimensions_with_min_side(width: u32, height: u32) -> MlResult<(u32, u32)> {
    if width == 0 || height == 0 {
        return Err(MlError::Postprocess(
            "cannot compute resize dimensions for zero-sized crop".to_string(),
        ));
    }

    if width <= height {
        Ok((
            FACE_THUMBNAIL_MIN_DIMENSION,
            scaled_long_side(height, width)?,
        ))
    } else {
        Ok((
            scaled_long_side(width, height)?,
            FACE_THUMBNAIL_MIN_DIMENSION,
        ))
    }
}

fn scaled_long_side(long_side: u32, short_side: u32) -> MlResult<u32> {
    if short_side == 0 {
        return Err(MlError::Postprocess(
            "cannot scale with zero short side".to_string(),
        ));
    }

    let numerator = u128::from(long_side) * u128::from(FACE_THUMBNAIL_MIN_DIMENSION);
    let denominator = u128::from(short_side);
    let rounded = (numerator + (denominator / 2)) / denominator;

    if rounded == 0 || rounded > u128::from(u32::MAX) {
        return Err(MlError::Postprocess(format!(
            "invalid scaled dimension computed from long={long_side}, short={short_side}",
        )));
    }

    Ok(rounded as u32)
}

#[cfg(test)]
mod tests {
    use fast_image_resize::FilterType;
    use image::ImageFormat;

    use super::{
        FaceBox, compute_crop_rect, dimensions_with_min_side, generate_face_thumbnails,
        select_resize_filter,
    };
    use crate::ml::types::{DecodedImage, Dimensions};

    #[test]
    fn compute_crop_rect_matches_canvas_math_for_center_box() {
        let face_box = FaceBox {
            x: 0.25,
            y: 0.25,
            width: 0.5,
            height: 0.5,
        };

        let crop = compute_crop_rect(&face_box, 100.0, 80.0).expect("crop should be valid");

        assert!((crop.x - 5.0).abs() < f64::EPSILON);
        assert!((crop.y - 4.0).abs() < f64::EPSILON);
        assert!((crop.width - 90.0).abs() < f64::EPSILON);
        assert!((crop.height - 72.0).abs() < f64::EPSILON);
        assert_eq!(crop.output_width, 90);
        assert_eq!(crop.output_height, 72);
    }

    #[test]
    fn compute_crop_rect_handles_left_edge_overshoot_like_canvas() {
        let face_box = FaceBox {
            x: 0.0,
            y: 0.2,
            width: 0.2,
            height: 0.2,
        };

        let crop = compute_crop_rect(&face_box, 100.0, 100.0).expect("crop should be valid");

        assert!(crop.x.abs() < 1e-6);
        assert!((crop.width - 24.0).abs() < 1e-5);
        assert_eq!(crop.output_width, 24);
    }

    #[test]
    fn generate_face_thumbnails_returns_jpeg_per_input_face() {
        let decoded = synthetic_decoded_image(16, 16);
        let face_boxes = vec![
            FaceBox {
                x: 0.1,
                y: 0.1,
                width: 0.4,
                height: 0.4,
            },
            FaceBox {
                x: 0.4,
                y: 0.2,
                width: 0.3,
                height: 0.5,
            },
        ];

        let thumbnails =
            generate_face_thumbnails(&decoded, &face_boxes).expect("thumbnails should generate");

        assert_eq!(thumbnails.len(), 2);
        for bytes in thumbnails {
            assert!(!bytes.is_empty());
            let decoded_jpeg = image::load_from_memory_with_format(&bytes, ImageFormat::Jpeg)
                .expect("thumbnail bytes should decode as JPEG");
            assert!(decoded_jpeg.width() > 0);
            assert!(decoded_jpeg.height() > 0);
        }
    }

    #[test]
    fn generate_face_thumbnails_fails_for_zero_sized_face_box() {
        let decoded = synthetic_decoded_image(16, 16);
        let face_boxes = vec![FaceBox {
            x: 0.1,
            y: 0.2,
            width: 0.0,
            height: 0.3,
        }];

        let result = generate_face_thumbnails(&decoded, &face_boxes);

        assert!(result.is_err());
    }

    #[test]
    fn select_resize_filter_is_scale_aware() {
        let upscale_crop = super::CropRect {
            x: 0.0,
            y: 0.0,
            width: 80.0,
            height: 80.0,
            output_width: 100,
            output_height: 100,
        };
        assert_eq!(
            select_resize_filter(&upscale_crop, 100, 100),
            FilterType::CatmullRom
        );

        let mild_crop = super::CropRect {
            x: 0.0,
            y: 0.0,
            width: 100.9,
            height: 100.0,
            output_width: 100,
            output_height: 100,
        };
        assert_eq!(
            select_resize_filter(&mild_crop, 100, 100),
            FilterType::Bilinear
        );

        let moderate_crop = super::CropRect {
            x: 0.0,
            y: 0.0,
            width: 149.0,
            height: 120.0,
            output_width: 100,
            output_height: 100,
        };
        assert_eq!(
            select_resize_filter(&moderate_crop, 100, 100),
            FilterType::Mitchell
        );

        let heavy_crop = super::CropRect {
            x: 0.0,
            y: 0.0,
            width: 180.0,
            height: 160.0,
            output_width: 100,
            output_height: 100,
        };
        assert_eq!(
            select_resize_filter(&heavy_crop, 100, 100),
            FilterType::Lanczos3
        );
    }

    #[test]
    fn dimensions_with_min_side_keeps_aspect_ratio_and_sets_short_side_to_512() {
        let (w1, h1) = dimensions_with_min_side(100, 200).expect("resize should succeed");
        assert_eq!(w1, 512);
        assert_eq!(h1, 1024);

        let (w2, h2) = dimensions_with_min_side(300, 120).expect("resize should succeed");
        assert_eq!(w2, 1280);
        assert_eq!(h2, 512);
    }

    #[test]
    fn generate_face_thumbnails_outputs_min_side_512() {
        let decoded = synthetic_decoded_image(100, 200);
        let face_boxes = vec![FaceBox {
            x: 0.0,
            y: 0.0,
            width: 1.0,
            height: 1.0,
        }];

        let thumbnails =
            generate_face_thumbnails(&decoded, &face_boxes).expect("thumbnails should generate");
        assert_eq!(thumbnails.len(), 1);

        let decoded_jpeg = image::load_from_memory_with_format(&thumbnails[0], ImageFormat::Jpeg)
            .expect("thumbnail bytes should decode as JPEG");
        let short_side = decoded_jpeg.width().min(decoded_jpeg.height());
        assert_eq!(short_side, 512);
    }

    fn synthetic_decoded_image(width: u32, height: u32) -> DecodedImage {
        let mut rgb = Vec::with_capacity((width * height * 3) as usize);
        for y in 0..height {
            for x in 0..width {
                rgb.push((x % 256) as u8);
                rgb.push((y % 256) as u8);
                rgb.push(((x + y) % 256) as u8);
            }
        }
        DecodedImage {
            dimensions: Dimensions { width, height },
            rgb,
        }
    }
}
