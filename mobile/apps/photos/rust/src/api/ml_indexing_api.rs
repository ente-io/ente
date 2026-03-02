use crate::image::decode::decode_image_from_path;
use crate::ml::{
    clip::image::run_clip_image,
    error::{MlError, MlResult},
    face::{align::run_face_alignment, detect::run_face_detection, embed::run_face_embedding},
    pet::{
        align::run_pet_face_alignment,
        detect::{detect_species, run_pet_body_detection, run_pet_face_detection},
        embed::{run_pet_body_embedding, run_pet_face_embedding},
    },
    runtime::{self, ExecutionProviderPolicy, MlRuntimeConfig, ModelPaths},
};

/// Read VmRSS from /proc/self/status (Linux/Android). Returns KB or 0 on failure.
fn vm_rss_kb() -> u64 {
    std::fs::read_to_string("/proc/self/status")
        .ok()
        .and_then(|s| {
            s.lines()
                .find(|l| l.starts_with("VmRSS:"))
                .and_then(|l| l.split_whitespace().nth(1))
                .and_then(|v| v.parse::<u64>().ok())
        })
        .unwrap_or(0)
}

/// Log a message to Android logcat (or stderr on other platforms).
fn ml_log(msg: &str) {
    #[cfg(target_os = "android")]
    {
        unsafe extern "C" {
            unsafe fn __android_log_write(
                prio: std::ffi::c_int,
                tag: *const std::ffi::c_char,
                text: *const std::ffi::c_char,
            ) -> std::ffi::c_int;
        }
        use std::ffi::CString;
        let tag = CString::new("ml_mem").unwrap();
        let cmsg = CString::new(msg).unwrap_or_else(|_| CString::new("(invalid msg)").unwrap());
        unsafe {
            __android_log_write(4, tag.as_ptr(), cmsg.as_ptr());
        }
    }
    #[cfg(not(target_os = "android"))]
    {
        eprintln!("{msg}");
    }
}

#[derive(Clone, Debug)]
pub struct RustExecutionProviderPolicy {
    pub prefer_coreml: bool,
    pub prefer_nnapi: bool,
    pub prefer_xnnpack: bool,
    pub allow_cpu_fallback: bool,
}

impl Default for RustExecutionProviderPolicy {
    fn default() -> Self {
        Self {
            prefer_coreml: true,
            prefer_nnapi: true,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        }
    }
}

#[derive(Clone, Debug)]
pub struct RustModelPaths {
    pub face_detection: String,
    pub face_embedding: String,
    pub clip_image: String,
    pub pet_face_detection: String,
    pub pet_face_embedding_dog: String,
    pub pet_face_embedding_cat: String,
    pub pet_body_detection: String,
    pub pet_body_embedding_dog: String,
    pub pet_body_embedding_cat: String,
}

#[derive(Clone, Debug)]
pub struct RustMlRuntimeConfig {
    pub model_paths: RustModelPaths,
    pub provider_policy: RustExecutionProviderPolicy,
}

#[derive(Clone, Debug)]
pub struct AnalyzeImageRequest {
    pub file_id: i64,
    pub image_path: String,
    pub run_faces: bool,
    pub run_clip: bool,
    pub run_pets: bool,
    pub model_paths: RustModelPaths,
    pub provider_policy: RustExecutionProviderPolicy,
}

#[derive(Clone, Debug)]
pub struct RustDimensions {
    pub width: i32,
    pub height: i32,
}

#[derive(Clone, Debug)]
pub struct RustDetection {
    pub score: f32,
    pub box_xyxy: Vec<f32>,
    pub all_keypoints: Vec<Vec<f32>>,
}

#[derive(Clone, Debug)]
pub struct RustAlignmentResult {
    pub affine_matrix: Vec<Vec<f32>>,
    pub center: Vec<f32>,
    pub size: f32,
    pub rotation: f32,
}

#[derive(Clone, Debug)]
pub struct RustFaceResult {
    pub detection: RustDetection,
    pub blur_value: f32,
    pub alignment: RustAlignmentResult,
    pub embedding: Vec<f32>,
    pub face_id: String,
}

#[derive(Clone, Debug)]
pub struct RustClipResult {
    pub embedding: Vec<f32>,
}

#[derive(Clone, Debug)]
pub struct RustPetFaceDetectionResult {
    pub score: f64,
    pub box_xyxy: Vec<f64>,
    /// 3 keypoints: [left_eye, right_eye, nose], each as [x, y]
    pub keypoints: Vec<Vec<f64>>,
}

#[derive(Clone, Debug)]
pub struct RustPetAlignmentResult {
    pub center: Vec<f64>,
    pub angle: f64,
    pub crop_size: f64,
}

#[derive(Clone, Debug)]
pub struct RustPetFaceResult {
    pub detection: RustPetFaceDetectionResult,
    pub alignment: RustPetAlignmentResult,
    /// 0 = dog, 1 = cat
    pub species: u8,
    pub face_embedding: Vec<f64>,
    pub pet_face_id: String,
}

#[derive(Clone, Debug)]
pub struct RustPetBodyResult {
    pub box_xyxy: Vec<f64>,
    pub score: f64,
    /// COCO class: 15 = cat, 16 = dog
    pub coco_class: u8,
    pub pet_body_id: String,
    pub body_embedding: Vec<f64>,
}

#[derive(Clone, Debug)]
pub struct AnalyzeImageResult {
    pub file_id: i64,
    pub decoded_image_size: RustDimensions,
    pub faces: Option<Vec<RustFaceResult>>,
    pub clip: Option<RustClipResult>,
    pub pet_faces: Option<Vec<RustPetFaceResult>>,
    pub pet_bodies: Option<Vec<RustPetBodyResult>>,
}

pub fn init_ml_runtime(config: RustMlRuntimeConfig) -> Result<(), String> {
    runtime::ensure_runtime(&to_runtime_config(&config)).map_err(|e| e.to_string())
}

pub fn release_ml_runtime() -> Result<(), String> {
    runtime::release_runtime().map_err(|e| e.to_string())
}

pub fn analyze_image_rust(req: AnalyzeImageRequest) -> Result<AnalyzeImageResult, String> {
    analyze_image_rust_inner(req).map_err(|e| e.to_string())
}

fn analyze_image_rust_inner(req: AnalyzeImageRequest) -> MlResult<AnalyzeImageResult> {
    validate_request_model_paths(&req)?;

    let runtime_config = MlRuntimeConfig {
        model_paths: to_model_paths(&req.model_paths),
        provider_policy: to_provider_policy(&req.provider_policy),
    };

    let t0 = std::time::Instant::now();

    runtime::with_runtime_mut(&runtime_config, |runtime| {
        // Decode inside the lock so only one image is in memory at a time.
        // Without this, all queued images decode simultaneously, wasting memory.
        let rss0 = vm_rss_kb();
        ml_log(&format!(
            "file={} start rss={}MB (faces={}, clip={}, pets={})",
            req.file_id, rss0 / 1024, req.run_faces, req.run_clip, req.run_pets
        ));
        let decoded = decode_image_from_path(&req.image_path)?;
        let dims = RustDimensions {
            width: decoded.dimensions.width as i32,
            height: decoded.dimensions.height as i32,
        };
        ml_log(&format!(
            "file={} decoded {}x{} in {:?} rss={}MB (+{}MB)",
            req.file_id, dims.width, dims.height, t0.elapsed(),
            vm_rss_kb() / 1024, (vm_rss_kb() as i64 - rss0 as i64) / 1024
        ));
        // Unload sessions between phases to keep peak native memory low.
        // Each phase lazily loads only the sessions it needs; unloading
        // after each phase ensures we never hold all models simultaneously.

        let faces = if req.run_faces {
            let t = std::time::Instant::now();
            let detections = run_face_detection(runtime, &decoded)?;
            ml_log(&format!("file={} face detection: {} faces in {:?} rss={}MB", req.file_id, detections.len(), t.elapsed(), vm_rss_kb() / 1024));
            if detections.is_empty() {
                runtime.unload_face_sessions();
                Some(Vec::new())
            } else {
                let t = std::time::Instant::now();
                let (aligned, mut face_results) =
                    run_face_alignment(req.file_id, &decoded, &detections)?;
                ml_log(&format!("file={} face alignment: {} faces in {:?} rss={}MB", req.file_id, face_results.len(), t.elapsed(), vm_rss_kb() / 1024));
                let t = std::time::Instant::now();
                run_face_embedding(runtime, &aligned, &mut face_results)?;
                ml_log(&format!("file={} face embedding done in {:?} rss={}MB", req.file_id, t.elapsed(), vm_rss_kb() / 1024));
                runtime.unload_face_sessions();
                ml_log(&format!("file={} face sessions unloaded rss={}MB", req.file_id, vm_rss_kb() / 1024));
                Some(face_results.into_iter().map(to_api_face_result).collect())
            }
        } else {
            None
        };

        let clip = if req.run_clip {
            let t = std::time::Instant::now();
            let clip = run_clip_image(runtime, &decoded)?;
            ml_log(&format!("file={} clip done in {:?} rss={}MB", req.file_id, t.elapsed(), vm_rss_kb() / 1024));
            runtime.unload_clip_session();
            ml_log(&format!("file={} clip session unloaded rss={}MB", req.file_id, vm_rss_kb() / 1024));
            Some(RustClipResult {
                embedding: clip.embedding.into_iter().map(|v| v as f64).collect(),
            })
        } else {
            None
        };

        // If pets are disabled, free decoded image early since it's no longer needed.
        let (pet_faces, pet_bodies) = if req.run_pets {
            ml_log(&format!("file={} pet pipeline start rss={}MB", req.file_id, vm_rss_kb() / 1024));
            let t = std::time::Instant::now();
            let pet_face_detections = run_pet_face_detection(runtime, &decoded)?;
            ml_log(&format!("file={} pet face detection: {} faces in {:?} rss={}MB", req.file_id, pet_face_detections.len(), t.elapsed(), vm_rss_kb() / 1024));

            let t = std::time::Instant::now();
            let body_detections = run_pet_body_detection(runtime, &decoded)?;
            ml_log(&format!("file={} pet body detection: {} bodies in {:?} rss={}MB", req.file_id, body_detections.len(), t.elapsed(), vm_rss_kb() / 1024));

            let species = detect_species(&body_detections);

            runtime.unload_pet_detection_sessions();
            ml_log(&format!("file={} pet detection sessions unloaded rss={}MB", req.file_id, vm_rss_kb() / 1024));

            let pet_face_results = if !pet_face_detections.is_empty() {
                let t = std::time::Instant::now();
                let (aligned, mut pet_results) =
                    run_pet_face_alignment(req.file_id, &decoded, &pet_face_detections)?;
                ml_log(&format!("file={} pet face aligned rss={}MB", req.file_id, vm_rss_kb() / 1024));
                run_pet_face_embedding(runtime, &aligned, &mut pet_results, species)?;
                ml_log(&format!("file={} pet face embedding: {} faces in {:?} rss={}MB", req.file_id, pet_results.len(), t.elapsed(), vm_rss_kb() / 1024));
                pet_results
            } else {
                Vec::new()
            };

            runtime.unload_pet_face_embedding_sessions();
            ml_log(&format!("file={} pet face embed sessions unloaded rss={}MB", req.file_id, vm_rss_kb() / 1024));

            let mut body_results: Vec<crate::ml::types::PetBodyResult> = body_detections
                .into_iter()
                .map(|det| crate::ml::types::PetBodyResult {
                    pet_body_id: crate::ml::types::to_face_id(req.file_id, det.box_xyxy),
                    detection: det,
                    body_embedding: Vec::new(),
                })
                .collect();
            if !body_results.is_empty() {
                let t = std::time::Instant::now();
                run_pet_body_embedding(runtime, &decoded, &mut body_results, species)?;
                ml_log(&format!("file={} pet body embedding: {} bodies in {:?} rss={}MB", req.file_id, body_results.len(), t.elapsed(), vm_rss_kb() / 1024));
            }

            // Free decoded image RGB buffer (~36 MB) now that all processing is done.
            drop(decoded);
            ml_log(&format!("file={} decoded dropped rss={}MB", req.file_id, vm_rss_kb() / 1024));

            runtime.unload_pet_body_embedding_sessions();
            ml_log(&format!("file={} pet body embed sessions unloaded rss={}MB", req.file_id, vm_rss_kb() / 1024));

            (
                Some(pet_face_results.into_iter().map(to_api_pet_face_result).collect()),
                Some(body_results.into_iter().map(to_api_pet_body_result).collect()),
            )
        } else {
            drop(decoded);
            (None, None)
        };

        let n_faces = faces.as_ref().map_or(0, Vec::len);
        let n_clip = if clip.is_some() { 1 } else { 0 };
        let n_pet_faces = pet_faces.as_ref().map_or(0, Vec::len);
        let n_pet_bodies = pet_bodies.as_ref().map_or(0, Vec::len);
        ml_log(&format!(
            "file={} COMPLETE in {:?} (faces={}, clip={}, pet_faces={}, pet_bodies={}) rss={}MB",
            req.file_id, t0.elapsed(), n_faces, n_clip, n_pet_faces, n_pet_bodies, vm_rss_kb() / 1024
        ));

        Ok(AnalyzeImageResult {
            file_id: req.file_id,
            decoded_image_size: dims.clone(),
            faces,
            clip,
            pet_faces,
            pet_bodies,
        })
    })
}

fn validate_request_model_paths(req: &AnalyzeImageRequest) -> MlResult<()> {
    let mut missing = Vec::new();
    if req.run_faces {
        if req.model_paths.face_detection.trim().is_empty() {
            missing.push("faceDetectionModelPath");
        }
        if req.model_paths.face_embedding.trim().is_empty() {
            missing.push("faceEmbeddingModelPath");
        }
    }
    if req.run_clip && req.model_paths.clip_image.trim().is_empty() {
        missing.push("clipImageModelPath");
    }
    if req.run_pets {
        if req.model_paths.pet_face_detection.trim().is_empty() {
            missing.push("petFaceDetectionModelPath");
        }
        if req.model_paths.pet_body_detection.trim().is_empty() {
            missing.push("petBodyDetectionModelPath");
        }
        if req.model_paths.pet_face_embedding_dog.trim().is_empty() {
            missing.push("petFaceEmbeddingDogModelPath");
        }
        if req.model_paths.pet_face_embedding_cat.trim().is_empty() {
            missing.push("petFaceEmbeddingCatModelPath");
        }
        if req.model_paths.pet_body_embedding_dog.trim().is_empty() {
            missing.push("petBodyEmbeddingDogModelPath");
        }
        if req.model_paths.pet_body_embedding_cat.trim().is_empty() {
            missing.push("petBodyEmbeddingCatModelPath");
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

fn to_runtime_config(config: &RustMlRuntimeConfig) -> MlRuntimeConfig {
    MlRuntimeConfig {
        model_paths: to_model_paths(&config.model_paths),
        provider_policy: to_provider_policy(&config.provider_policy),
    }
}

fn to_model_paths(paths: &RustModelPaths) -> ModelPaths {
    ModelPaths {
        face_detection: paths.face_detection.clone(),
        face_embedding: paths.face_embedding.clone(),
        clip_image: paths.clip_image.clone(),
        pet_face_detection: paths.pet_face_detection.clone(),
        pet_face_embedding_dog: paths.pet_face_embedding_dog.clone(),
        pet_face_embedding_cat: paths.pet_face_embedding_cat.clone(),
        pet_body_detection: paths.pet_body_detection.clone(),
        pet_body_embedding_dog: paths.pet_body_embedding_dog.clone(),
        pet_body_embedding_cat: paths.pet_body_embedding_cat.clone(),
    }
}

fn to_provider_policy(policy: &RustExecutionProviderPolicy) -> ExecutionProviderPolicy {
    ExecutionProviderPolicy {
        prefer_coreml: policy.prefer_coreml,
        prefer_nnapi: policy.prefer_nnapi,
        prefer_xnnpack: policy.prefer_xnnpack,
        allow_cpu_fallback: policy.allow_cpu_fallback,
    }
}

fn to_api_face_result(result: crate::ml::types::FaceResult) -> RustFaceResult {
    RustFaceResult {
        detection: RustDetection {
            score: result.detection.score,
            box_xyxy: result.detection.box_xyxy.into_iter().collect(),
            all_keypoints: result
                .detection
                .keypoints
                .into_iter()
                .map(|point| point.into_iter().collect())
                .collect(),
        },
        blur_value: result.blur_value,
        alignment: RustAlignmentResult {
            affine_matrix: result
                .alignment
                .affine_matrix
                .into_iter()
                .map(|row| row.into_iter().collect())
                .collect(),
            center: result.alignment.center.into_iter().collect(),
            size: result.alignment.size,
            rotation: result.alignment.rotation,
        },
        embedding: result.embedding,
        face_id: result.face_id,
    }
}

fn to_api_pet_face_result(result: crate::ml::types::PetFaceResult) -> RustPetFaceResult {
    RustPetFaceResult {
        detection: RustPetFaceDetectionResult {
            score: result.detection.score as f64,
            box_xyxy: result
                .detection
                .box_xyxy
                .into_iter()
                .map(|v| v as f64)
                .collect(),
            keypoints: result
                .detection
                .keypoints
                .into_iter()
                .map(|point| point.into_iter().map(|v| v as f64).collect())
                .collect(),
        },
        alignment: RustPetAlignmentResult {
            center: result.alignment.center.into_iter().map(|v| v as f64).collect(),
            angle: result.alignment.angle as f64,
            crop_size: result.alignment.crop_size as f64,
        },
        species: result.species,
        face_embedding: result.face_embedding.into_iter().map(|v| v as f64).collect(),
        pet_face_id: result.pet_face_id,
    }
}

fn to_api_pet_body_result(result: crate::ml::types::PetBodyResult) -> RustPetBodyResult {
    RustPetBodyResult {
        box_xyxy: result
            .detection
            .box_xyxy
            .into_iter()
            .map(|v| v as f64)
            .collect(),
        score: result.detection.score as f64,
        coco_class: result.detection.coco_class,
        pet_body_id: result.pet_body_id,
        body_embedding: result.body_embedding.into_iter().map(|v| v as f64).collect(),
    }
}
