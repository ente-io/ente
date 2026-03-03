use crate::ml::{
    error::{MlError, MlResult},
    onnx, preprocess,
    runtime::MlRuntime,
    types::{DecodedImage, PetFaceDetection, PetBodyDetection},
};

const INPUT_WIDTH: f32 = 640.0;
const INPUT_HEIGHT: f32 = 640.0;

// Pet face detection thresholds (from Python config)
const PET_FACE_IOU_THRESHOLD: f32 = 0.5;
const PET_FACE_MIN_SCORE: f32 = 0.3;

// Body detection thresholds
const BODY_IOU_THRESHOLD: f32 = 0.5;
const BODY_MIN_SCORE: f32 = 0.3;

// COCO class IDs
const COCO_CAT: u8 = 15;
const COCO_DOG: u8 = 16;

/// Run pet face detection using YOLOv5-face model with 3 keypoints.
///
/// Output format per row: [x, y, w, h, obj_conf, lx, ly, rx, ry, nx, ny, ...]
/// 3 keypoints: left_eye, right_eye, nose (6 values for coords).
///
/// This mirrors `pet_pipeline/detection.py` `FaceDetector.detect()`.
pub fn run_pet_face_detection(
    runtime: &mut MlRuntime,
    decoded: &DecodedImage,
) -> MlResult<Vec<PetFaceDetection>> {
    let (input, scaled_width, scaled_height, pad_left, pad_top) =
        preprocess::preprocess_yolo(decoded)?;

    let pet_face_detection = runtime.pet_face_detection_session_mut()?;
    let (output_shape, output_data) = onnx::run_f32(
        pet_face_detection,
        input,
        [1, 3, INPUT_HEIGHT as i64, INPUT_WIDTH as i64],
    )?;

    // Row format: [x, y, w, h, conf, lm_x1, lm_y1, lm_x2, lm_y2, lm_x3, lm_y3, class_id]
    // row_len = 4 + 1 + 6 + 1 = 12
    // Use the output shape's last dimension to determine row length reliably.
    let row_len = if output_shape.len() >= 2 {
        *output_shape.last().unwrap() as usize
    } else if output_shape.len() == 1 {
        // Flat output: total_elements, must infer row_len
        // Try common sizes: 13 (2-class), 12 (1-class), 11 (no class)
        let total = output_data.len();
        if total % 13 == 0 { 13 }
        else if total % 12 == 0 { 12 }
        else if total % 11 == 0 { 11 }
        else {
            return Err(MlError::Postprocess(format!(
                "unexpected pet face detector output size: {} (shape: {:?})",
                total, output_shape
            )));
        }
    } else {
        return Err(MlError::Postprocess(
            "pet face detector output shape is empty".to_string(),
        ));
    };
    if row_len < 11 || output_data.len() < row_len {
        return Err(MlError::Postprocess(format!(
            "pet face detector row_len={} too small or output too short (len={})",
            row_len, output_data.len()
        )));
    }

    let detection_rows = output_data.len() / row_len;
    let mut detections = Vec::with_capacity(detection_rows);

    for i in 0..detection_rows {
        let start = i * row_len;
        let row = &output_data[start..(start + row_len)];
        let score = row[4];
        if score < PET_FACE_MIN_SCORE {
            continue;
        }

        let x_min_abs = row[0] - row[2] / 2.0;
        let y_min_abs = row[1] - row[3] / 2.0;
        let x_max_abs = row[0] + row[2] / 2.0;
        let y_max_abs = row[1] + row[3] / 2.0;

        let mut box_xyxy = [
            x_min_abs / INPUT_WIDTH,
            y_min_abs / INPUT_HEIGHT,
            x_max_abs / INPUT_WIDTH,
            y_max_abs / INPUT_HEIGHT,
        ];

        // 3 keypoints: left_eye, right_eye, nose
        let mut keypoints = [
            [row[5] / INPUT_WIDTH, row[6] / INPUT_HEIGHT],
            [row[7] / INPUT_WIDTH, row[8] / INPUT_HEIGHT],
            [row[9] / INPUT_WIDTH, row[10] / INPUT_HEIGHT],
        ];

        correct_for_maintained_aspect_ratio_3kp(
            &mut box_xyxy,
            &mut keypoints,
            scaled_width,
            scaled_height,
            pad_left,
            pad_top,
        );

        // class_id at index 11: 0=dog, 1=cat
        let class_id = if row_len >= 12 {
            row[11] as u8
        } else {
            0
        };

        detections.push(PetFaceDetection {
            score,
            box_xyxy,
            keypoints,
            class_id,
        });
    }

    Ok(naive_nms_pet_face(detections, PET_FACE_IOU_THRESHOLD))
}

/// Run pet body detection using YOLOv5n model.
///
/// Filters detections by COCO class 15 (cat) or 16 (dog).
/// Returns the best detection per species class found.
///
/// This mirrors `pet_pipeline/detection.py` `BodyDetector.detect()`.
pub fn run_pet_body_detection(
    runtime: &mut MlRuntime,
    decoded: &DecodedImage,
) -> MlResult<Vec<PetBodyDetection>> {
    let (input, scaled_width, scaled_height, pad_left, pad_top) =
        preprocess::preprocess_yolo(decoded)?;

    let body_detection = runtime.pet_body_detection_session_mut()?;
    let (_output_shape, output_data) = onnx::run_f32(
        body_detection,
        input,
        [1, 3, INPUT_HEIGHT as i64, INPUT_WIDTH as i64],
    )?;

    // YOLOv5 output format: [x, y, w, h, obj_conf, cls0, cls1, ..., cls79]
    // Total columns: 4 + 1 + 80 = 85
    let row_len = 85usize;
    if output_data.len() < row_len {
        return Ok(Vec::new());
    }

    let detection_rows = output_data.len() / row_len;
    let mut detections = Vec::new();

    for i in 0..detection_rows {
        let start = i * row_len;
        let row = &output_data[start..(start + row_len)];
        let obj_conf = row[4];

        // Check cat (class 15) and dog (class 16) scores
        for &class_id in &[COCO_CAT, COCO_DOG] {
            let class_score = row[5 + class_id as usize] * obj_conf;
            if class_score < BODY_MIN_SCORE {
                continue;
            }

            let x_min_abs = row[0] - row[2] / 2.0;
            let y_min_abs = row[1] - row[3] / 2.0;
            let x_max_abs = row[0] + row[2] / 2.0;
            let y_max_abs = row[1] + row[3] / 2.0;

            let mut box_xyxy = [
                x_min_abs / INPUT_WIDTH,
                y_min_abs / INPUT_HEIGHT,
                x_max_abs / INPUT_WIDTH,
                y_max_abs / INPUT_HEIGHT,
            ];

            correct_box_for_aspect_ratio(
                &mut box_xyxy,
                scaled_width,
                scaled_height,
                pad_left,
                pad_top,
            );

            detections.push(PetBodyDetection {
                score: class_score,
                box_xyxy,
                coco_class: class_id,
            });
        }
    }

    Ok(naive_nms_pet_body(detections, BODY_IOU_THRESHOLD))
}

/// Auto-detect which species is dominant in the body detections.
///
/// Returns 0 for dog, 1 for cat based on which class has more/higher confidence detections.
pub fn detect_species(body_detections: &[PetBodyDetection]) -> u8 {
    let mut dog_score: f32 = 0.0;
    let mut cat_score: f32 = 0.0;

    for det in body_detections {
        match det.coco_class {
            COCO_DOG => dog_score += det.score,
            COCO_CAT => cat_score += det.score,
            _ => {}
        }
    }

    if cat_score > dog_score { 1 } else { 0 }
}

fn correct_for_maintained_aspect_ratio_3kp(
    box_xyxy: &mut [f32; 4],
    keypoints: &mut [[f32; 2]; 3],
    scaled_width: usize,
    scaled_height: usize,
    pad_left: usize,
    pad_top: usize,
) {
    if scaled_width == INPUT_WIDTH as usize
        && scaled_height == INPUT_HEIGHT as usize
        && pad_left == 0
        && pad_top == 0
    {
        return;
    }

    let scaled_width = scaled_width as f32;
    let scaled_height = scaled_height as f32;
    let pad_left = pad_left as f32;
    let pad_top = pad_top as f32;

    let transform_x =
        |x: f32| -> f32 { ((x * INPUT_WIDTH - pad_left) / scaled_width).clamp(0.0, 1.0) };
    let transform_y =
        |y: f32| -> f32 { ((y * INPUT_HEIGHT - pad_top) / scaled_height).clamp(0.0, 1.0) };

    box_xyxy[0] = transform_x(box_xyxy[0]);
    box_xyxy[1] = transform_y(box_xyxy[1]);
    box_xyxy[2] = transform_x(box_xyxy[2]);
    box_xyxy[3] = transform_y(box_xyxy[3]);

    for point in keypoints.iter_mut() {
        point[0] = transform_x(point[0]);
        point[1] = transform_y(point[1]);
    }
}

fn correct_box_for_aspect_ratio(
    box_xyxy: &mut [f32; 4],
    scaled_width: usize,
    scaled_height: usize,
    pad_left: usize,
    pad_top: usize,
) {
    if scaled_width == INPUT_WIDTH as usize
        && scaled_height == INPUT_HEIGHT as usize
        && pad_left == 0
        && pad_top == 0
    {
        return;
    }

    let scaled_width = scaled_width as f32;
    let scaled_height = scaled_height as f32;
    let pad_left = pad_left as f32;
    let pad_top = pad_top as f32;

    let transform_x =
        |x: f32| -> f32 { ((x * INPUT_WIDTH - pad_left) / scaled_width).clamp(0.0, 1.0) };
    let transform_y =
        |y: f32| -> f32 { ((y * INPUT_HEIGHT - pad_top) / scaled_height).clamp(0.0, 1.0) };

    box_xyxy[0] = transform_x(box_xyxy[0]);
    box_xyxy[1] = transform_y(box_xyxy[1]);
    box_xyxy[2] = transform_x(box_xyxy[2]);
    box_xyxy[3] = transform_y(box_xyxy[3]);
}

fn calculate_iou_4(a: &[f32; 4], b: &[f32; 4]) -> f32 {
    let area_a = (a[2] - a[0]).max(0.0) * (a[3] - a[1]).max(0.0);
    let area_b = (b[2] - b[0]).max(0.0) * (b[3] - b[1]).max(0.0);

    let ix1 = a[0].max(b[0]);
    let iy1 = a[1].max(b[1]);
    let ix2 = a[2].min(b[2]);
    let iy2 = a[3].min(b[3]);

    let iw = ix2 - ix1;
    let ih = iy2 - iy1;
    if iw < 0.0 || ih < 0.0 {
        return 0.0;
    }

    let inter = iw * ih;
    let union = area_a + area_b - inter;
    if union <= 0.0 { 0.0 } else { inter / union }
}

fn naive_nms_pet_face(
    mut detections: Vec<PetFaceDetection>,
    iou_threshold: f32,
) -> Vec<PetFaceDetection> {
    detections.sort_by(|a, b| b.score.total_cmp(&a.score));
    let mut i = 0usize;
    while i + 1 < detections.len() {
        let mut j = i + 1;
        while j < detections.len() {
            let iou = calculate_iou_4(&detections[i].box_xyxy, &detections[j].box_xyxy);
            if iou >= iou_threshold {
                detections.remove(j);
            } else {
                j += 1;
            }
        }
        i += 1;
    }
    detections
}

fn naive_nms_pet_body(
    mut detections: Vec<PetBodyDetection>,
    iou_threshold: f32,
) -> Vec<PetBodyDetection> {
    detections.sort_by(|a, b| b.score.total_cmp(&a.score));
    let mut i = 0usize;
    while i + 1 < detections.len() {
        let mut j = i + 1;
        while j < detections.len() {
            let iou = calculate_iou_4(&detections[i].box_xyxy, &detections[j].box_xyxy);
            if iou >= iou_threshold {
                detections.remove(j);
            } else {
                j += 1;
            }
        }
        i += 1;
    }
    detections
}
