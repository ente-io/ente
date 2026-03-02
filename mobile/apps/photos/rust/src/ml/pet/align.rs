use image::{ImageBuffer, Rgb, RgbImage};
use imageproc::geometric_transformations::{Interpolation, Projection, warp_into};

use crate::ml::{
    error::{MlError, MlResult},
    types::{DecodedImage, PetAlignmentResult, PetFaceDetection, PetFaceResult, to_face_id},
};


const PET_FACE_CROP_SIZE: u32 = 224;

/// Run pet face alignment using 3-point landmarks (left_eye, right_eye, nose).
///
/// For each detection:
///   1. Compute rotation angle from the eye line
///   2. Rotate image around eye midpoint
///   3. Crop a square region centered on the face bounding box
///   4. Resize to 224x224
///   5. Apply ImageNet normalization (CHW)
///
/// This mirrors `pet_pipeline/detection.py` `_align_face()`:
/// ```python
/// angle = np.degrees(np.arctan2(r_eye[1]-l_eye[1], r_eye[0]-l_eye[0]))
/// center = ((l_eye[0]+r_eye[0])//2, (l_eye[1]+r_eye[1])//2)
/// M = cv2.getRotationMatrix2D(center, angle, 1.0)
/// ```
pub fn run_pet_face_alignment(
    file_id: i64,
    decoded: &DecodedImage,
    detections: &[PetFaceDetection],
) -> MlResult<(Vec<Vec<f32>>, Vec<PetFaceResult>)> {
    let source = rgb_image_from_decoded(decoded)?;
    let img_w = decoded.dimensions.width as f32;
    let img_h = decoded.dimensions.height as f32;

    let mut aligned_inputs = Vec::with_capacity(detections.len());
    let mut face_results = Vec::with_capacity(detections.len());

    for detection in detections {
        // Convert relative keypoints to absolute
        let left_eye = [
            detection.keypoints[0][0] * img_w,
            detection.keypoints[0][1] * img_h,
        ];
        let right_eye = [
            detection.keypoints[1][0] * img_w,
            detection.keypoints[1][1] * img_h,
        ];

        // Compute rotation angle from eye line
        let dy = right_eye[1] - left_eye[1];
        let dx = right_eye[0] - left_eye[0];
        let angle = dy.atan2(dx); // radians

        // Eye midpoint as rotation center
        let center_x = (left_eye[0] + right_eye[0]) / 2.0;
        let center_y = (left_eye[1] + right_eye[1]) / 2.0;

        // Absolute bounding box
        let box_x1 = (detection.box_xyxy[0] * img_w).max(0.0);
        let box_y1 = (detection.box_xyxy[1] * img_h).max(0.0);
        let box_x2 = (detection.box_xyxy[2] * img_w).min(img_w);
        let box_y2 = (detection.box_xyxy[3] * img_h).min(img_h);

        // Square crop size: max of box width/height with some padding
        let box_w = box_x2 - box_x1;
        let box_h = box_y2 - box_y1;
        let crop_size = box_w.max(box_h) * 1.3; // 30% padding like Python pipeline

        // Skip degenerate detections where the bounding box is too small
        // to produce a valid affine transform (determinant = scale^2 ~ 0)
        if crop_size < 1.0 {
            eprintln!(
                "Skipping pet face detection with degenerate bounding box (crop_size={:.2})",
                crop_size
            );
            continue;
        }

        // Build rotation matrix (rotate then translate to center the crop)
        let cos_a = angle.cos();
        let sin_a = angle.sin();

        // The projection matrix maps OUTPUT coords to INPUT coords.
        // We want: rotate by -angle around (center_x, center_y), then
        // shift so that the crop center maps to (PET_FACE_CROP_SIZE/2, PET_FACE_CROP_SIZE/2).
        let scale = crop_size / PET_FACE_CROP_SIZE as f32;
        let half_out = PET_FACE_CROP_SIZE as f32 / 2.0;

        // Inverse transform: output -> input
        let a00 = cos_a * scale;
        let a01 = -sin_a * scale;
        let a10 = sin_a * scale;
        let a11 = cos_a * scale;
        let tx = center_x - half_out * a00 - half_out * a01;
        let ty = center_y - half_out * a10 - half_out * a11;

        let projection = match Projection::from_matrix([
            a00, a01, tx,
            a10, a11, ty,
            0.0, 0.0, 1.0,
        ]) {
            Some(p) => p,
            None => {
                eprintln!(
                    "Skipping pet face with non-invertible projection matrix (scale={:.4}, crop_size={:.2})",
                    scale, crop_size
                );
                continue;
            }
        };

        let mut output = RgbImage::from_pixel(
            PET_FACE_CROP_SIZE,
            PET_FACE_CROP_SIZE,
            Rgb([114, 114, 114]),
        );
        warp_into(
            &source,
            &projection,
            Interpolation::Bicubic,
            Rgb([114, 114, 114]),
            &mut output,
        );

        // Convert aligned face to ImageNet-normalized CHW tensor
        let normalized = aligned_face_to_tensor(&output);

        let pet_face_id = to_face_id(file_id, detection.box_xyxy);

        let alignment = PetAlignmentResult {
            center: [center_x, center_y],
            angle,
            crop_size,
        };

        aligned_inputs.push(normalized);
        face_results.push(PetFaceResult {
            detection: detection.clone(),
            species: 0, // will be set after species detection
            face_embedding: Vec::new(),
            pet_face_id,
            alignment,
        });
    }

    Ok((aligned_inputs, face_results))
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
