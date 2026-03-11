use fast_image_resize::{
    FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer, images::Image as FirImage,
};

use crate::ml::{
    error::{MlError, MlResult},
    types::DecodedImage,
};

const PET_EMBED_INPUT_SIZE: usize = 224;

// ImageNet normalization constants
const IMAGENET_MEAN: [f32; 3] = [0.485, 0.456, 0.406];
const IMAGENET_STD: [f32; 3] = [0.229, 0.224, 0.225];

/// Preprocess a cropped pet face/body image for embedding extraction.
///
/// Steps:
///   1. Resize to 224x224 using bilinear interpolation
///   2. Normalize using ImageNet mean/std
///   3. Output CHW layout as float32
///
/// This mirrors the Python pipeline's preprocessing:
/// ```python
/// img = cv2.resize(crop, (224, 224))
/// img = img / 255.0
/// img = (img - IMAGENET_MEAN) / IMAGENET_STD
/// img = img.transpose(2, 0, 1)  # HWC -> CHW
/// ```
pub fn preprocess_pet_embedding(
    rgb_crop: &[u8],
    crop_width: u32,
    crop_height: u32,
) -> MlResult<Vec<f32>> {
    if crop_width == 0 || crop_height == 0 {
        return Err(MlError::Preprocess(
            "crop dimensions cannot be zero".to_string(),
        ));
    }

    let target_w = PET_EMBED_INPUT_SIZE as u32;
    let target_h = PET_EMBED_INPUT_SIZE as u32;

    let src_image = FirImage::from_vec_u8(crop_width, crop_height, rgb_crop.to_vec(), PixelType::U8x3)
        .map_err(|e| MlError::Preprocess(format!("failed to create FIR source image: {e}")))?;

    let mut resized_image = FirImage::new(target_w, target_h, PixelType::U8x3);
    let mut resizer = Resizer::new();
    let options = ResizeOptions::new().resize_alg(ResizeAlg::Interpolation(FilterType::Bilinear));
    resizer
        .resize(&src_image, &mut resized_image, Some(&options))
        .map_err(|e| MlError::Preprocess(format!("failed to resize pet embedding input: {e}")))?;

    let resized = resized_image.buffer();
    let pixel_count = PET_EMBED_INPUT_SIZE * PET_EMBED_INPUT_SIZE;
    let mut output = vec![0.0f32; 3 * pixel_count];

    // CHW layout with ImageNet normalization
    let r_offset = 0;
    let g_offset = pixel_count;
    let b_offset = 2 * pixel_count;

    for y in 0..PET_EMBED_INPUT_SIZE {
        for x in 0..PET_EMBED_INPUT_SIZE {
            let src_idx = (y * PET_EMBED_INPUT_SIZE + x) * 3;
            let dst_idx = y * PET_EMBED_INPUT_SIZE + x;

            let r = resized[src_idx] as f32 / 255.0;
            let g = resized[src_idx + 1] as f32 / 255.0;
            let b = resized[src_idx + 2] as f32 / 255.0;

            output[r_offset + dst_idx] = (r - IMAGENET_MEAN[0]) / IMAGENET_STD[0];
            output[g_offset + dst_idx] = (g - IMAGENET_MEAN[1]) / IMAGENET_STD[1];
            output[b_offset + dst_idx] = (b - IMAGENET_MEAN[2]) / IMAGENET_STD[2];
        }
    }

    Ok(output)
}

/// Extract a cropped region from a decoded image given a bounding box.
///
/// The bounding box is in relative coordinates [0, 1].
/// Returns the crop as RGB bytes and its dimensions.
pub fn extract_crop(
    decoded: &DecodedImage,
    box_xyxy: &[f32; 4],
) -> MlResult<(Vec<u8>, u32, u32)> {
    let img_w = decoded.dimensions.width;
    let img_h = decoded.dimensions.height;

    let x1 = (box_xyxy[0] * img_w as f32).round().clamp(0.0, img_w as f32) as u32;
    let y1 = (box_xyxy[1] * img_h as f32).round().clamp(0.0, img_h as f32) as u32;
    let x2 = (box_xyxy[2] * img_w as f32).round().clamp(0.0, img_w as f32) as u32;
    let y2 = (box_xyxy[3] * img_h as f32).round().clamp(0.0, img_h as f32) as u32;

    let crop_w = x2.saturating_sub(x1);
    let crop_h = y2.saturating_sub(y1);

    if crop_w == 0 || crop_h == 0 {
        return Err(MlError::Preprocess(
            "crop region has zero area".to_string(),
        ));
    }

    let mut crop = Vec::with_capacity((crop_w * crop_h * 3) as usize);
    for row in y1..y2 {
        let row_start = ((row * img_w + x1) * 3) as usize;
        let row_end = ((row * img_w + x2) * 3) as usize;
        if row_end > decoded.rgb.len() || row_start > decoded.rgb.len() {
            return Err(MlError::Preprocess(format!(
                "crop row {} out of bounds: start={}, end={}, buffer_len={}",
                row, row_start, row_end, decoded.rgb.len()
            )));
        }
        crop.extend_from_slice(&decoded.rgb[row_start..row_end]);
    }

    Ok((crop, crop_w, crop_h))
}
