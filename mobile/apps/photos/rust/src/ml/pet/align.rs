use fast_image_resize::{
    FilterType, PixelType, ResizeAlg, ResizeOptions, Resizer, images::Image as FirImage,
};
use image::{ImageBuffer, Rgb, RgbImage};

use crate::ml::{
    error::{MlError, MlResult},
    types::{DecodedImage, PetAlignmentResult, PetFaceDetection, PetFaceResult, to_face_id},
};


const PET_FACE_CROP_SIZE: u32 = 224;
/// Minimum eye distance in pixels below which alignment is skipped.
const MIN_EYE_DISTANCE: f32 = 5.0;
/// Angle threshold in degrees; below this, skip rotation and just crop.
const ANGLE_SKIP_DEG: f32 = 1.0;
/// Expand factor applied to each side of the bounding box when cropping.
const CROP_EXPAND: f32 = 0.1;

/// Run pet face alignment using 3-point landmarks (left_eye, right_eye, nose).
///
/// Mirrors `pet_pipeline/detection.py` `_align_face()`:
///   1. Skip if eye distance < 5 px
///   2. If angle < 1°, crop bounding box directly (no rotation)
///   3. Otherwise rotate around face center, then crop with 10% expand
///   4. Resize to 224×224
///   5. Apply ImageNet normalization (CHW)
pub fn run_pet_face_alignment(
    file_id: i64,
    decoded: &DecodedImage,
    detections: &[PetFaceDetection],
) -> MlResult<(Vec<Vec<f32>>, Vec<PetFaceResult>)> {
    let source = rgb_image_from_decoded(decoded)?;
    let img_w = decoded.dimensions.width;
    let img_h = decoded.dimensions.height;
    let img_wf = img_w as f32;
    let img_hf = img_h as f32;

    let mut aligned_inputs = Vec::with_capacity(detections.len());
    let mut face_results = Vec::with_capacity(detections.len());

    for detection in detections {
        // Convert relative keypoints to absolute
        let left_eye = [
            detection.keypoints[0][0] * img_wf,
            detection.keypoints[0][1] * img_hf,
        ];
        let right_eye = [
            detection.keypoints[1][0] * img_wf,
            detection.keypoints[1][1] * img_hf,
        ];

        let dx = right_eye[0] - left_eye[0];
        let dy = right_eye[1] - left_eye[1];
        let eye_dist = (dx * dx + dy * dy).sqrt();

        // Skip if eyes are too close together
        if eye_dist < MIN_EYE_DISTANCE {
            continue;
        }

        // Absolute bounding box (clamped)
        let box_x1 = (detection.box_xyxy[0] * img_wf).max(0.0) as i32;
        let box_y1 = (detection.box_xyxy[1] * img_hf).max(0.0) as i32;
        let box_x2 = (detection.box_xyxy[2] * img_wf).min(img_wf) as i32;
        let box_y2 = (detection.box_xyxy[3] * img_hf).min(img_hf) as i32;

        let angle_deg = dy.atan2(dx).to_degrees();
        let angle_rad = dy.atan2(dx);

        let aligned_rgb = if angle_deg.abs() < ANGLE_SKIP_DEG {
            // No rotation needed — just crop the bounding box directly
            let cx1 = box_x1.max(0) as u32;
            let cy1 = box_y1.max(0) as u32;
            let cx2 = (box_x2 as u32).min(img_w);
            let cy2 = (box_y2 as u32).min(img_h);
            let crop_w = cx2.saturating_sub(cx1);
            let crop_h = cy2.saturating_sub(cy1);
            if crop_w == 0 || crop_h == 0 {
                continue;
            }
            crop_and_resize_rgb(&source, cx1, cy1, crop_w, crop_h)?
        } else {
            // Rotate around face center, then crop with expand
            let face_cx = (box_x1 + box_x2) as f64 / 2.0;
            let face_cy = (box_y1 + box_y2) as f64 / 2.0;

            let rotated = rotate_around_center(
                &source,
                angle_rad as f64,
                face_cx,
                face_cy,
            );

            // Crop with 10% expand on each side
            let bw = (box_x2 - box_x1) as f32;
            let bh = (box_y2 - box_y1) as f32;
            let nx1 = (box_x1 as f32 - bw * CROP_EXPAND).max(0.0) as u32;
            let ny1 = (box_y1 as f32 - bh * CROP_EXPAND).max(0.0) as u32;
            let nx2 = (box_x2 as f32 + bw * CROP_EXPAND).min(img_wf) as u32;
            let ny2 = (box_y2 as f32 + bh * CROP_EXPAND).min(img_hf) as u32;
            let crop_w = nx2.saturating_sub(nx1);
            let crop_h = ny2.saturating_sub(ny1);
            if crop_w == 0 || crop_h == 0 {
                continue;
            }
            crop_and_resize_rgb(&rotated, nx1, ny1, crop_w, crop_h)?
        };

        let normalized = aligned_face_to_tensor(&aligned_rgb);

        let pet_face_id = to_face_id(file_id, detection.box_xyxy);

        let center_x = (left_eye[0] + right_eye[0]) / 2.0;
        let center_y = (left_eye[1] + right_eye[1]) / 2.0;
        let box_w = (box_x2 - box_x1) as f32;
        let box_h = (box_y2 - box_y1) as f32;
        let crop_size = box_w.max(box_h) * (1.0 + 2.0 * CROP_EXPAND);

        let alignment = PetAlignmentResult {
            center: [center_x, center_y],
            angle: angle_rad,
            crop_size,
        };

        aligned_inputs.push(normalized);
        face_results.push(PetFaceResult {
            detection: detection.clone(),
            species: 0, // will be set after embedding
            face_embedding: Vec::new(),
            pet_face_id,
            alignment,
        });
    }

    Ok((aligned_inputs, face_results))
}

/// Rotate an image around a center point using bilinear interpolation
/// with BORDER_REPLICATE behaviour (clamp to nearest edge pixel).
fn rotate_around_center(
    source: &RgbImage,
    angle_rad: f64,
    cx: f64,
    cy: f64,
) -> RgbImage {
    let w = source.width();
    let h = source.height();
    let cos_a = angle_rad.cos();
    let sin_a = angle_rad.sin();

    // Build forward rotation matrix (output -> input):
    //   x_in = cos_a * (x_out - cx) + sin_a * (y_out - cy) + cx
    //   y_in = -sin_a * (x_out - cx) + cos_a * (y_out - cy) + cy

    let mut output = RgbImage::new(w, h);
    let w_f = w as f64;
    let h_f = h as f64;

    for out_y in 0..h {
        for out_x in 0..w {
            let dx = out_x as f64 - cx;
            let dy = out_y as f64 - cy;
            let src_x = cos_a * dx + sin_a * dy + cx;
            let src_y = -sin_a * dx + cos_a * dy + cy;

            // BORDER_REPLICATE: clamp to valid range
            let sx = src_x.max(0.0).min(w_f - 1.0);
            let sy = src_y.max(0.0).min(h_f - 1.0);

            // Bilinear interpolation
            let x0 = sx.floor() as u32;
            let y0 = sy.floor() as u32;
            let x1 = (x0 + 1).min(w - 1);
            let y1 = (y0 + 1).min(h - 1);
            let fx = (sx - sx.floor()) as f32;
            let fy = (sy - sy.floor()) as f32;

            let p00 = source.get_pixel(x0, y0).0;
            let p10 = source.get_pixel(x1, y0).0;
            let p01 = source.get_pixel(x0, y1).0;
            let p11 = source.get_pixel(x1, y1).0;

            let mut px = [0u8; 3];
            for c in 0..3 {
                let v = p00[c] as f32 * (1.0 - fx) * (1.0 - fy)
                    + p10[c] as f32 * fx * (1.0 - fy)
                    + p01[c] as f32 * (1.0 - fx) * fy
                    + p11[c] as f32 * fx * fy;
                px[c] = v.round().max(0.0).min(255.0) as u8;
            }
            output.put_pixel(out_x, out_y, Rgb(px));
        }
    }

    output
}

/// Crop a region from an RGB image and resize to 224×224 using bilinear interpolation.
fn crop_and_resize_rgb(
    source: &RgbImage,
    x: u32,
    y: u32,
    w: u32,
    h: u32,
) -> MlResult<RgbImage> {
    // Extract crop bytes
    let src_w = source.width();
    let mut crop_bytes = Vec::with_capacity((w * h * 3) as usize);
    for row in y..(y + h) {
        for col in x..(x + w) {
            let px = source.get_pixel(col.min(src_w - 1), row.min(source.height() - 1)).0;
            crop_bytes.extend_from_slice(&px);
        }
    }

    let src_img = FirImage::from_vec_u8(w, h, crop_bytes, PixelType::U8x3)
        .map_err(|e| MlError::Preprocess(format!("FIR source: {e}")))?;

    let mut dst_img = FirImage::new(PET_FACE_CROP_SIZE, PET_FACE_CROP_SIZE, PixelType::U8x3);
    let mut resizer = Resizer::new();
    let opts = ResizeOptions::new().resize_alg(ResizeAlg::Interpolation(FilterType::Bilinear));
    resizer
        .resize(&src_img, &mut dst_img, Some(&opts))
        .map_err(|e| MlError::Preprocess(format!("FIR resize: {e}")))?;

    let buf = dst_img.into_vec();
    ImageBuffer::<Rgb<u8>, _>::from_raw(PET_FACE_CROP_SIZE, PET_FACE_CROP_SIZE, buf)
        .ok_or_else(|| MlError::Preprocess("failed to build aligned face image".to_string()))
}

fn rgb_image_from_decoded(decoded: &DecodedImage) -> MlResult<RgbImage> {
    ImageBuffer::<Rgb<u8>, _>::from_raw(
        decoded.dimensions.width,
        decoded.dimensions.height,
        decoded.rgb.clone(),
    )
    .ok_or_else(|| MlError::Preprocess("failed to build RGB source image for pet alignment".to_string()))
}

/// Convert an aligned pet face image to ImageNet-normalized CHW tensor.
fn aligned_face_to_tensor(face_image: &RgbImage) -> Vec<f32> {
    let w = face_image.width() as usize;
    let h = face_image.height() as usize;
    let pixel_count = w * h;
    let mut output = vec![0.0f32; 3 * pixel_count];

    const MEAN: [f32; 3] = [0.485, 0.456, 0.406];
    const STD: [f32; 3] = [0.229, 0.224, 0.225];

    let r_off = 0;
    let g_off = pixel_count;
    let b_off = 2 * pixel_count;

    for y in 0..h {
        for x in 0..w {
            let px = face_image.get_pixel(x as u32, y as u32).0;
            let idx = y * w + x;
            output[r_off + idx] = (px[0] as f32 / 255.0 - MEAN[0]) / STD[0];
            output[g_off + idx] = (px[1] as f32 / 255.0 - MEAN[1]) / STD[1];
            output[b_off + idx] = (px[2] as f32 / 255.0 - MEAN[2]) / STD[2];
        }
    }

    output
}
