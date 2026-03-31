use crate::{
    image::decode::decode_image_from_path,
    ml::{
        clip::{
            image::run_clip_image, text::run_clip_text_query,
            tokenizer::tokenize_clip_text as tokenize_clip_text_impl,
        },
        error::{MlError, MlResult},
        face::{align::run_face_alignment, detect::run_face_detection, embed::run_face_embedding},
        pet::{
            align::run_pet_face_alignment, detect::run_pet_face_detection,
            embed::run_pet_face_embedding,
        },
        runtime::{self, ExecutionProviderPolicy, MlRuntimeConfig, ModelPaths},
        types::{
            ClipResult, Dimensions, FaceResult, PetBodyResult, PetFaceDetection, PetFaceResult,
        },
    },
};

/// IoU threshold for suppressing pet face detections that overlap with
/// human face detections. A pet face box overlapping a human face box by
/// this much or more is assumed to be a misdetected human face.
const HUMAN_PET_OVERLAP_IOU: f32 = 0.3;

#[derive(Clone, Debug)]
pub struct AnalyzeImageRequest {
    pub file_id: i64,
    pub image_path: String,
    pub run_faces: bool,
    pub run_clip: bool,
    pub run_pets: bool,
    pub runtime_config: MlRuntimeConfig,
}

#[derive(Clone, Debug)]
pub struct AnalyzeImageResult {
    pub file_id: i64,
    pub decoded_image_size: Dimensions,
    pub faces: Option<Vec<FaceResult>>,
    pub clip: Option<ClipResult>,
    pub pet_faces: Option<Vec<PetFaceResult>>,
    pub pet_bodies: Option<Vec<PetBodyResult>>,
}

#[derive(Clone, Debug)]
pub struct RunClipTextRequest {
    pub text: String,
    pub model_path: String,
    pub vocab_path: String,
    pub provider_policy: ExecutionProviderPolicy,
}

#[derive(Clone, Debug)]
pub struct RunClipTextResult {
    pub embedding: Vec<f32>,
}

pub fn init_ml_runtime(config: MlRuntimeConfig) -> MlResult<()> {
    runtime::prepare_runtime(&config)
}

pub fn release_ml_runtime() -> MlResult<()> {
    runtime::release_runtime()
}

pub fn analyze_image(req: AnalyzeImageRequest) -> MlResult<AnalyzeImageResult> {
    validate_request_model_paths(&req)?;

    let AnalyzeImageRequest {
        file_id,
        image_path,
        run_faces,
        run_clip,
        run_pets,
        runtime_config,
    } = req;

    runtime::with_runtime(&runtime_config, |runtime| {
        let decoded = decode_image_from_path(&image_path)?;
        let dims = decoded.dimensions.clone();

        // Run face detection when explicitly requested, OR when pet detection
        // needs it to filter human faces that the pet model misdetects.
        let face_detections = if run_faces {
            run_face_detection(runtime, &decoded)?
        } else if run_pets {
            // Best-effort: run face detection for cross-model filtering.
            // If the model is unavailable, proceed without filtering.
            run_face_detection(runtime, &decoded).unwrap_or_else(|e| {
                eprintln!("[ml] face detection for pet filtering unavailable: {e}");
                Vec::new()
            })
        } else {
            Vec::new()
        };

        // Extract human face bounding boxes before face_detections is consumed
        // by alignment. These are used to suppress pet face false positives.
        let human_face_boxes: Vec<[f32; 4]> =
            face_detections.iter().map(|d| d.box_xyxy).collect();

        let faces = if run_faces {
            if face_detections.is_empty() {
                Some(Vec::new())
            } else {
                let (aligned, mut face_results) =
                    run_face_alignment(file_id, &decoded, face_detections)?;
                run_face_embedding(runtime, &aligned, &mut face_results)?;
                Some(face_results)
            }
        } else {
            None
        };

        let clip = if run_clip {
            Some(run_clip_image(runtime, &decoded)?)
        } else {
            None
        };

        let pet_faces = if run_pets {
            let mut pet_face_detections = run_pet_face_detection(runtime, &decoded)?;

            // Suppress pet face detections that overlap with confirmed human
            // faces — the pet face model sometimes fires on human faces.
            suppress_human_overlapping_pets(
                &mut pet_face_detections,
                &human_face_boxes,
            );

            if !pet_face_detections.is_empty() {
                let (aligned, mut pet_results) =
                    run_pet_face_alignment(file_id, &decoded, &pet_face_detections)?;
                run_pet_face_embedding(runtime, &aligned, &mut pet_results)?;
                Some(pet_results)
            } else {
                Some(Vec::new())
            }
        } else {
            None
        };

        Ok(AnalyzeImageResult {
            file_id,
            decoded_image_size: dims,
            faces,
            clip,
            pet_faces,
            pet_bodies: None,
        })
    })
}

pub fn run_clip_text(req: RunClipTextRequest) -> MlResult<RunClipTextResult> {
    let RunClipTextRequest {
        text,
        model_path,
        vocab_path,
        provider_policy,
    } = req;

    if model_path.trim().is_empty() {
        return Err(MlError::InvalidRequest(
            "missing model path: clipTextModelPath".to_string(),
        ));
    }
    if vocab_path.trim().is_empty() {
        return Err(MlError::InvalidRequest(
            "missing model path: clipTextVocabPath".to_string(),
        ));
    }

    let runtime_config = MlRuntimeConfig {
        model_paths: ModelPaths {
            face_detection: String::new(),
            face_embedding: String::new(),
            clip_image: String::new(),
            clip_text: model_path,
            pet_face_detection: String::new(),
            pet_face_embedding_dog: String::new(),
            pet_face_embedding_cat: String::new(),
            pet_body_detection: String::new(),
            pet_body_embedding_dog: String::new(),
            pet_body_embedding_cat: String::new(),
        },
        provider_policy,
    };

    runtime::with_runtime(&runtime_config, |runtime| {
        let clip = run_clip_text_query(runtime, &text, &vocab_path)?;
        Ok(RunClipTextResult {
            embedding: clip.embedding,
        })
    })
}

pub fn tokenize_clip_text(text: &str, vocab_path: &str) -> MlResult<Vec<i32>> {
    if vocab_path.trim().is_empty() {
        return Err(MlError::InvalidRequest(
            "missing model path: clipTextVocabPath".to_string(),
        ));
    }
    tokenize_clip_text_impl(text, vocab_path)
}

/// Remove pet face detections whose bounding box overlaps a human face
/// bounding box by at least [`HUMAN_PET_OVERLAP_IOU`].  This prevents the
/// pet face detector (which shares the YOLOv5-face architecture) from
/// keeping false positives on human faces.
fn suppress_human_overlapping_pets(
    pet_faces: &mut Vec<PetFaceDetection>,
    human_face_boxes: &[[f32; 4]],
) {
    if human_face_boxes.is_empty() || pet_faces.is_empty() {
        return;
    }
    let before = pet_faces.len();
    pet_faces.retain(|pet| {
        let dominated = human_face_boxes
            .iter()
            .any(|hb| iou_xyxy(&pet.box_xyxy, hb) >= HUMAN_PET_OVERLAP_IOU);
        if dominated {
            eprintln!(
                "[ml][pet] SUPPRESSED pet face (overlaps human face): score={:.3}, class={}",
                pet.score,
                if pet.class_id == 0 { "dog" } else { "cat" }
            );
        }
        !dominated
    });
    let suppressed = before - pet_faces.len();
    if suppressed > 0 {
        eprintln!("[ml][pet] suppressed {suppressed} pet face(s) overlapping human faces");
    }
}

/// Intersection-over-Union for two axis-aligned boxes in [x1, y1, x2, y2]
/// format with coordinates in [0, 1].
fn iou_xyxy(a: &[f32; 4], b: &[f32; 4]) -> f32 {
    let area_a = (a[2] - a[0]).max(0.0) * (a[3] - a[1]).max(0.0);
    let area_b = (b[2] - b[0]).max(0.0) * (b[3] - b[1]).max(0.0);
    let ix1 = a[0].max(b[0]);
    let iy1 = a[1].max(b[1]);
    let ix2 = a[2].min(b[2]);
    let iy2 = a[3].min(b[3]);
    let iw = (ix2 - ix1).max(0.0);
    let ih = (iy2 - iy1).max(0.0);
    let inter = iw * ih;
    let union = area_a + area_b - inter;
    if union <= 0.0 { 0.0 } else { inter / union }
}

fn validate_request_model_paths(req: &AnalyzeImageRequest) -> MlResult<()> {
    let model_paths = &req.runtime_config.model_paths;

    let mut missing = Vec::new();
    if req.run_faces {
        if model_paths.face_detection.trim().is_empty() {
            missing.push("faceDetectionModelPath");
        }
        if model_paths.face_embedding.trim().is_empty() {
            missing.push("faceEmbeddingModelPath");
        }
    }
    if req.run_clip && model_paths.clip_image.trim().is_empty() {
        missing.push("clipImageModelPath");
    }
    if req.run_pets {
        if model_paths.pet_face_detection.trim().is_empty() {
            missing.push("petFaceDetectionModelPath");
        }
        if model_paths.pet_face_embedding_dog.trim().is_empty() {
            missing.push("petFaceEmbeddingDogModelPath");
        }
        if model_paths.pet_face_embedding_cat.trim().is_empty() {
            missing.push("petFaceEmbeddingCatModelPath");
        }
    }
    if missing.is_empty() {
        return Ok(());
    }

    Err(MlError::InvalidRequest(format!(
        "missing required model paths: {}",
        missing.join(", ")
    )))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn pet_det(box_xyxy: [f32; 4], class_id: u8) -> PetFaceDetection {
        PetFaceDetection {
            score: 0.5,
            box_xyxy,
            keypoints: [[0.0; 2]; 3],
            class_id,
        }
    }

    #[test]
    fn iou_identical_boxes() {
        let b = [0.1, 0.1, 0.5, 0.5];
        assert!((iou_xyxy(&b, &b) - 1.0).abs() < 1e-6);
    }

    #[test]
    fn iou_disjoint_boxes() {
        let a = [0.0, 0.0, 0.1, 0.1];
        let b = [0.5, 0.5, 0.6, 0.6];
        assert_eq!(iou_xyxy(&a, &b), 0.0);
    }

    #[test]
    fn suppress_removes_overlapping_pet() {
        let human = vec![[0.1, 0.1, 0.5, 0.5]];
        // Pet box nearly identical to human face box
        let mut pets = vec![pet_det([0.12, 0.12, 0.48, 0.48], 0)];
        suppress_human_overlapping_pets(&mut pets, &human);
        assert!(pets.is_empty(), "overlapping pet should be suppressed");
    }

    #[test]
    fn suppress_keeps_non_overlapping_pet() {
        let human = vec![[0.1, 0.1, 0.3, 0.3]];
        // Pet box far from human face
        let mut pets = vec![pet_det([0.6, 0.6, 0.9, 0.9], 1)];
        suppress_human_overlapping_pets(&mut pets, &human);
        assert_eq!(pets.len(), 1, "non-overlapping pet should be kept");
    }

    #[test]
    fn suppress_mixed_keeps_real_pets() {
        let human = vec![[0.1, 0.1, 0.4, 0.4]];
        let mut pets = vec![
            pet_det([0.12, 0.12, 0.38, 0.38], 0), // overlaps human
            pet_det([0.6, 0.6, 0.9, 0.9], 1),      // real pet
        ];
        suppress_human_overlapping_pets(&mut pets, &human);
        assert_eq!(pets.len(), 1);
        assert_eq!(pets[0].class_id, 1);
    }

    #[test]
    fn suppress_noop_when_no_humans() {
        let mut pets = vec![pet_det([0.1, 0.1, 0.5, 0.5], 0)];
        suppress_human_overlapping_pets(&mut pets, &[]);
        assert_eq!(pets.len(), 1);
    }
}
