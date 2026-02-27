use image::{ImageBuffer, Rgb, RgbImage};
use imageproc::geometric_transformations::{Interpolation, Projection, warp_into};
use nalgebra::{Matrix2, Matrix3, Vector2};

use crate::ml::{
    error::{MlError, MlResult},
    types::{AlignmentResult, DecodedImage, FaceDetection, FaceResult, to_face_id},
};

const FACE_SIZE: u32 = 112;
const LAPLACIAN_HARD_THRESHOLD: f32 = 10.0;
const REMOVE_SIDE_COLUMNS: usize = 56;

const MOBILEFACENET_IDEAL_5_LANDMARKS: [[f32; 2]; 5] = [
    [38.2946 / 112.0, 51.6963 / 112.0],
    [73.5318 / 112.0, 51.5014 / 112.0],
    [56.0252 / 112.0, 71.7366 / 112.0],
    [41.5493 / 112.0, 92.3655 / 112.0],
    [70.7299 / 112.0, 92.2041 / 112.0],
];

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum FaceDirection {
    Left,
    Right,
    Straight,
}

#[derive(Clone, Debug)]
struct FaceDetectionAbsolute {
    keypoints: [[f32; 2]; 5],
}

pub fn run_face_alignment(
    file_id: i64,
    decoded: &DecodedImage,
    detections: &[FaceDetection],
) -> MlResult<(Vec<Vec<f32>>, Vec<FaceResult>)> {
    let source = rgb_image_from_decoded(decoded)?;
    let mut aligned_face_inputs = Vec::with_capacity(detections.len());
    let mut face_results = Vec::with_capacity(detections.len());

    for detection in detections {
        let absolute_detection = to_absolute_detection(
            detection,
            decoded.dimensions.width,
            decoded.dimensions.height,
        );
        let alignment = estimate_similarity_transform(&absolute_detection.keypoints)?;
        let aligned = warp_face_image(&source, &alignment.affine_matrix)?;
        let normalized = normalize_face_rgb_for_mobilefacenet(&aligned);
        let blur_value = compute_blur_value(&aligned, face_direction(&absolute_detection));
        let face_id = to_face_id(file_id, detection.box_xyxy);

        aligned_face_inputs.push(normalized);
        face_results.push(FaceResult {
            detection: detection.clone(),
            blur_value,
            alignment,
            embedding: Vec::new(),
            face_id,
        });
    }

    Ok((aligned_face_inputs, face_results))
}

fn rgb_image_from_decoded(decoded: &DecodedImage) -> MlResult<RgbImage> {
    ImageBuffer::<Rgb<u8>, _>::from_raw(
        decoded.dimensions.width,
        decoded.dimensions.height,
        decoded.rgb.clone(),
    )
    .ok_or_else(|| MlError::Preprocess("failed to build RGB source image".to_string()))
}

fn to_absolute_detection(
    detection: &FaceDetection,
    image_width: u32,
    image_height: u32,
) -> FaceDetectionAbsolute {
    let width = image_width as f32;
    let height = image_height as f32;
    let mut keypoints = [[0.0f32; 2]; 5];
    for (i, point) in detection.keypoints.iter().enumerate() {
        keypoints[i] = [point[0] * width, point[1] * height];
    }

    FaceDetectionAbsolute { keypoints }
}

fn estimate_similarity_transform(src_points: &[[f32; 2]; 5]) -> MlResult<AlignmentResult> {
    let src_mean = mean_2d(src_points);
    let dst_mean = mean_2d(&MOBILEFACENET_IDEAL_5_LANDMARKS);
    let n = src_points.len() as f32;

    let mut a = Matrix2::<f32>::zeros();
    let mut src_var_sum = 0.0f32;
    for (src, dst) in src_points
        .iter()
        .zip(MOBILEFACENET_IDEAL_5_LANDMARKS.iter())
    {
        let src_d = Vector2::new(src[0] - src_mean.x, src[1] - src_mean.y);
        let dst_d = Vector2::new(dst[0] - dst_mean.x, dst[1] - dst_mean.y);
        a += dst_d * src_d.transpose();
        src_var_sum += src_d.dot(&src_d);
    }
    a /= n;
    src_var_sum /= n;

    let mut d = Vector2::new(1.0f32, 1.0f32);
    if a.determinant() < 0.0 {
        d[1] = -1.0;
    }

    let svd = a.svd(true, true);
    let u = svd
        .u
        .ok_or_else(|| MlError::Postprocess("SVD failed to produce U".to_string()))?;
    let v_t = svd
        .v_t
        .ok_or_else(|| MlError::Postprocess("SVD failed to produce V^T".to_string()))?;
    let singular = svd.singular_values;

    let rank = singular.iter().filter(|v| **v > 1e-6).count();
    if rank == 0 {
        return Err(MlError::Postprocess(
            "failed to estimate similarity transform (rank=0)".to_string(),
        ));
    }

    let r;
    if rank == 1 {
        if u.determinant() * v_t.transpose().determinant() > 0.0 {
            r = u * v_t;
        } else {
            let mut d_local = d;
            let last = d_local[1];
            d_local[1] = -1.0;
            r = u * Matrix2::new(d_local[0], 0.0, 0.0, d_local[1]) * v_t;
            d[1] = last;
        }
    } else {
        r = u * Matrix2::new(d[0], 0.0, 0.0, d[1]) * v_t;
    }

    let scale = if src_var_sum <= f32::EPSILON {
        1.0
    } else {
        (singular[0] * d[0] + singular[1] * d[1]) / src_var_sum
    };

    let src_mean_v = Vector2::new(src_mean.x, src_mean.y);
    let dst_mean_v = Vector2::new(dst_mean.x, dst_mean.y);
    let translation = dst_mean_v - (r * src_mean_v) * scale;

    let mut t = Matrix3::<f32>::identity();
    let r_scaled = r * scale;
    t[(0, 0)] = r_scaled[(0, 0)];
    t[(0, 1)] = r_scaled[(0, 1)];
    t[(1, 0)] = r_scaled[(1, 0)];
    t[(1, 1)] = r_scaled[(1, 1)];
    t[(0, 2)] = translation[0];
    t[(1, 2)] = translation[1];

    let size = if scale.abs() < f32::EPSILON {
        1.0
    } else {
        1.0 / scale
    };
    let rotation = r[(1, 0)].atan2(r[(0, 0)]);
    let mean_translation = (dst_mean_v - Vector2::new(0.5, 0.5)) * size;
    let center = src_mean_v - mean_translation;

    Ok(AlignmentResult {
        affine_matrix: [
            [t[(0, 0)], t[(0, 1)], t[(0, 2)]],
            [t[(1, 0)], t[(1, 1)], t[(1, 2)]],
            [t[(2, 0)], t[(2, 1)], t[(2, 2)]],
        ],
        center: [center[0], center[1]],
        size,
        rotation,
    })
}

fn mean_2d(points: &[[f32; 2]]) -> Vector2<f32> {
    let mut sum = Vector2::new(0.0f32, 0.0f32);
    for point in points {
        sum[0] += point[0];
        sum[1] += point[1];
    }
    sum / points.len() as f32
}

fn warp_face_image(source: &RgbImage, affine_matrix: &[[f32; 3]; 3]) -> MlResult<RgbImage> {
    let mut transform = [[0.0f32; 3]; 3];
    for row in 0..3 {
        for col in 0..3 {
            let value = affine_matrix[row][col];
            transform[row][col] = if (value - 1.0).abs() <= f32::EPSILON {
                1.0
            } else {
                value * FACE_SIZE as f32
            };
        }
    }

    let projection = Projection::from_matrix([
        transform[0][0],
        transform[0][1],
        transform[0][2],
        transform[1][0],
        transform[1][1],
        transform[1][2],
        transform[2][0],
        transform[2][1],
        transform[2][2],
    ])
    .ok_or_else(|| MlError::Postprocess("invalid affine matrix projection".to_string()))?;

    let mut output = RgbImage::from_pixel(FACE_SIZE, FACE_SIZE, Rgb([114, 114, 114]));
    warp_into(
        source,
        &projection,
        Interpolation::Bicubic,
        Rgb([114, 114, 114]),
        &mut output,
    );
    Ok(output)
}

fn normalize_face_rgb_for_mobilefacenet(face_image: &RgbImage) -> Vec<f32> {
    let mut output = Vec::with_capacity((FACE_SIZE * FACE_SIZE * 3) as usize);
    for y in 0..FACE_SIZE {
        for x in 0..FACE_SIZE {
            let px = face_image.get_pixel(x, y).0;
            output.push(px[0] as f32 / 127.5 - 1.0);
            output.push(px[1] as f32 / 127.5 - 1.0);
            output.push(px[2] as f32 / 127.5 - 1.0);
        }
    }
    output
}

fn face_direction(detection: &FaceDetectionAbsolute) -> FaceDirection {
    let left_eye = detection.keypoints[0];
    let right_eye = detection.keypoints[1];
    let nose = detection.keypoints[2];
    let left_mouth = detection.keypoints[3];
    let right_mouth = detection.keypoints[4];

    let eye_distance_x = (right_eye[0] - left_eye[0]).abs();
    let eye_distance_y = (right_eye[1] - left_eye[1]).abs();
    let mouth_distance_y = (right_mouth[1] - left_mouth[1]).abs();

    let face_is_upright = left_eye[1].max(right_eye[1]) + 0.5 * eye_distance_y < nose[1]
        && nose[1] + 0.5 * mouth_distance_y < left_mouth[1].min(right_mouth[1]);

    let nose_sticking_out_left =
        nose[0] < left_eye[0].min(right_eye[0]) && nose[0] < left_mouth[0].min(right_mouth[0]);
    let nose_sticking_out_right =
        nose[0] > left_eye[0].max(right_eye[0]) && nose[0] > left_mouth[0].max(right_mouth[0]);

    let nose_close_to_left_eye = (nose[0] - left_eye[0]).abs() < 0.2 * eye_distance_x;
    let nose_close_to_right_eye = (nose[0] - right_eye[0]).abs() < 0.2 * eye_distance_x;

    if nose_sticking_out_left || (face_is_upright && nose_close_to_left_eye) {
        FaceDirection::Left
    } else if nose_sticking_out_right || (face_is_upright && nose_close_to_right_eye) {
        FaceDirection::Right
    } else {
        FaceDirection::Straight
    }
}

fn compute_blur_value(face_image: &RgbImage, direction: FaceDirection) -> f32 {
    let gray = to_grayscale_matrix(face_image);
    let lap = apply_laplacian(&gray, direction);
    let variance = variance_2d(&lap);
    if variance.is_finite() {
        variance
    } else {
        LAPLACIAN_HARD_THRESHOLD + 1.0
    }
}

fn to_grayscale_matrix(face_image: &RgbImage) -> Vec<Vec<i32>> {
    let w = face_image.width() as usize;
    let h = face_image.height() as usize;
    let mut gray = vec![vec![0i32; w]; h];
    for (y, row) in gray.iter_mut().enumerate().take(h) {
        for (x, value) in row.iter_mut().enumerate().take(w) {
            let px = face_image.get_pixel(x as u32, y as u32).0;
            *value = (0.299 * px[0] as f32 + 0.587 * px[1] as f32 + 0.114 * px[2] as f32)
                .round()
                .clamp(0.0, 255.0) as i32;
        }
    }
    gray
}

fn apply_laplacian(image: &[Vec<i32>], direction: FaceDirection) -> Vec<Vec<i32>> {
    let padded = pad_image_for_direction(image, direction);
    let rows = padded.len().saturating_sub(2);
    let cols = padded
        .first()
        .map(|r| r.len().saturating_sub(2))
        .unwrap_or(0);
    let kernel = [[0i32, 1, 0], [1, -4, 1], [0, 1, 0]];
    let mut out = vec![vec![0i32; cols]; rows];

    for i in 0..rows {
        for j in 0..cols {
            let mut sum = 0i32;
            for ki in 0..3 {
                for kj in 0..3 {
                    sum += padded[i + ki][j + kj] * kernel[ki][kj];
                }
            }
            out[i][j] = sum;
        }
    }
    out
}

fn pad_image_for_direction(image: &[Vec<i32>], direction: FaceDirection) -> Vec<Vec<i32>> {
    let rows = image.len();
    let cols = image.first().map(|r| r.len()).unwrap_or(0);
    let padded_cols = cols + 2 - REMOVE_SIDE_COLUMNS;
    let padded_rows = rows + 2;
    let mut padded = vec![vec![0i32; padded_cols]; padded_rows];

    let start_col = match direction {
        FaceDirection::Straight => REMOVE_SIDE_COLUMNS / 2,
        FaceDirection::Left => REMOVE_SIDE_COLUMNS,
        FaceDirection::Right => 0,
    };
    let copy_cols = padded_cols.saturating_sub(2);

    for i in 0..rows {
        for j in 0..copy_cols {
            padded[i + 1][j + 1] = image[i][j + start_col];
        }
    }

    if copy_cols > 0 {
        {
            let (top_rows, other_rows) = padded.split_at_mut(1);
            top_rows[0][1..=copy_cols].copy_from_slice(&other_rows[1][1..=copy_cols]);
        }
        {
            let (upper_rows, bottom_rows) = padded.split_at_mut(rows + 1);
            bottom_rows[0][1..=copy_cols].copy_from_slice(&upper_rows[rows - 1][1..=copy_cols]);
        }
    }
    for row in padded.iter_mut().take(rows + 2) {
        row[0] = row[2];
        row[padded_cols - 1] = row[padded_cols - 3];
    }

    padded
}

fn variance_2d(matrix: &[Vec<i32>]) -> f32 {
    if matrix.is_empty() || matrix[0].is_empty() {
        return 0.0;
    }

    let rows = matrix.len();
    let cols = matrix[0].len();
    let total = (rows * cols) as f32;

    let mut mean = 0.0f32;
    for row in matrix {
        for value in row {
            mean += *value as f32;
        }
    }
    mean /= total;

    let mut variance = 0.0f32;
    for row in matrix {
        for value in row {
            let diff = *value as f32 - mean;
            variance += diff * diff;
        }
    }
    variance / total
}
