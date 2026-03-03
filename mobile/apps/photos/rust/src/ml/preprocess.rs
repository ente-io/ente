use fast_image_resize::{
    FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer,
    images::{Image as FirImage, ImageRef as FirImageRef},
};

use crate::ml::{
    error::{MlError, MlResult},
    types::DecodedImage,
};

const YOLO_INPUT_WIDTH: usize = 640;
const YOLO_INPUT_HEIGHT: usize = 640;
const CLIP_INPUT_WIDTH: usize = 256;
const CLIP_INPUT_HEIGHT: usize = 256;
const PAD_VALUE: f32 = 114.0;

pub fn preprocess_yolo(decoded: &DecodedImage) -> MlResult<(Vec<f32>, usize, usize, usize, usize)> {
    if decoded.dimensions.width == 0 || decoded.dimensions.height == 0 {
        return Err(MlError::Preprocess(
            "image dimensions cannot be zero".to_string(),
        ));
    }

    let src_w = decoded.dimensions.width as f32;
    let src_h = decoded.dimensions.height as f32;
    let scale = (YOLO_INPUT_WIDTH as f32 / src_w).min(YOLO_INPUT_HEIGHT as f32 / src_h);
    let scaled_width = (src_w * scale).round().clamp(1.0, YOLO_INPUT_WIDTH as f32) as u32;
    let scaled_height = (src_h * scale).round().clamp(1.0, YOLO_INPUT_HEIGHT as f32) as u32;

    let src_image = FirImageRef::new(
        decoded.dimensions.width,
        decoded.dimensions.height,
        decoded.rgb.as_slice(),
        PixelType::U8x3,
    )
    .map_err(|e| MlError::Preprocess(format!("failed to create FIR source image: {e}")))?;

    let mut resized_image = FirImage::new(scaled_width, scaled_height, PixelType::U8x3);
    let mut resizer = Resizer::new();
    let options = ResizeOptions::new().resize_alg(ResizeAlg::Interpolation(FilterType::Bilinear));
    resizer
        .resize(&src_image, &mut resized_image, Some(&options))
        .map_err(|e| MlError::Preprocess(format!("failed to resize YOLO image input: {e}")))?;

    let scaled_width_usize = scaled_width as usize;
    let scaled_height_usize = scaled_height as usize;
    let pad_left = (YOLO_INPUT_WIDTH.saturating_sub(scaled_width_usize)) / 2;
    let pad_top = (YOLO_INPUT_HEIGHT.saturating_sub(scaled_height_usize)) / 2;

    let pad_norm = PAD_VALUE / 255.0;
    let mut output = vec![pad_norm; 3 * YOLO_INPUT_WIDTH * YOLO_INPUT_HEIGHT];
    let green_offset = YOLO_INPUT_WIDTH * YOLO_INPUT_HEIGHT;
    let blue_offset = 2 * YOLO_INPUT_WIDTH * YOLO_INPUT_HEIGHT;
    let resized = resized_image.buffer();

    for y in 0..scaled_height_usize {
        for x in 0..scaled_width_usize {
            let src_idx = (y * scaled_width_usize + x) * 3;
            let dst_x = x + pad_left;
            let dst_y = y + pad_top;
            let dst_idx = dst_y * YOLO_INPUT_WIDTH + dst_x;

            output[dst_idx] = resized[src_idx] as f32 / 255.0;
            output[dst_idx + green_offset] = resized[src_idx + 1] as f32 / 255.0;
            output[dst_idx + blue_offset] = resized[src_idx + 2] as f32 / 255.0;
        }
    }

    Ok((
        output,
        scaled_width_usize,
        scaled_height_usize,
        pad_left,
        pad_top,
    ))
}

pub fn preprocess_clip(decoded: &DecodedImage) -> MlResult<Vec<f32>> {
    if decoded.dimensions.width == 0 || decoded.dimensions.height == 0 {
        return Err(MlError::Preprocess(
            "image dimensions cannot be zero".to_string(),
        ));
    }

    let src_w = decoded.dimensions.width as f32;
    let src_h = decoded.dimensions.height as f32;
    let scale = (CLIP_INPUT_WIDTH as f32 / src_w).max(CLIP_INPUT_HEIGHT as f32 / src_h);
    let scaled_width = (src_w * scale).round().max(CLIP_INPUT_WIDTH as f32) as u32;
    let scaled_height = (src_h * scale).round().max(CLIP_INPUT_HEIGHT as f32) as u32;

    let src_image = FirImageRef::new(
        decoded.dimensions.width,
        decoded.dimensions.height,
        decoded.rgb.as_slice(),
        PixelType::U8x3,
    )
    .map_err(|e| MlError::Preprocess(format!("failed to create FIR source image: {e}")))?;

    let mut resized_image = FirImage::new(scaled_width, scaled_height, PixelType::U8x3);
    let mut resizer = Resizer::new();
    let options = ResizeOptions::new().resize_alg(ResizeAlg::Convolution(FilterType::Bilinear));
    resizer
        .resize(&src_image, &mut resized_image, Some(&options))
        .map_err(|e| MlError::Preprocess(format!("failed to resize CLIP image input: {e}")))?;

    let resized = resized_image.buffer();
    let start_x = ((scaled_width as i32 - CLIP_INPUT_WIDTH as i32) / 2).max(0) as usize;
    let start_y = ((scaled_height as i32 - CLIP_INPUT_HEIGHT as i32) / 2).max(0) as usize;
    let scaled_width_usize = scaled_width as usize;

    let mut output = vec![0f32; 3 * CLIP_INPUT_WIDTH * CLIP_INPUT_HEIGHT];
    let green_offset = CLIP_INPUT_WIDTH * CLIP_INPUT_HEIGHT;
    let blue_offset = 2 * CLIP_INPUT_WIDTH * CLIP_INPUT_HEIGHT;

    for y in 0..CLIP_INPUT_HEIGHT {
        for x in 0..CLIP_INPUT_WIDTH {
            let src_x = start_x + x;
            let src_y = start_y + y;
            let src_idx = (src_y * scaled_width_usize + src_x) * 3;
            let dst_idx = y * CLIP_INPUT_WIDTH + x;
            output[dst_idx] = resized[src_idx] as f32 / 255.0;
            output[dst_idx + green_offset] = resized[src_idx + 1] as f32 / 255.0;
            output[dst_idx + blue_offset] = resized[src_idx + 2] as f32 / 255.0;
        }
    }

    Ok(output)
}
