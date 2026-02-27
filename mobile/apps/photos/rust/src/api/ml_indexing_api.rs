use crate::image::decode::decode_image_from_path;
use crate::ml::{
    clip::image::run_clip_image,
    error::{MlError, MlResult},
    face::{align::run_face_alignment, detect::run_face_detection, embed::run_face_embedding},
    runtime::{self, ExecutionProviderPolicy, MlRuntimeConfig, ModelPaths},
};

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
    pub score: f64,
    pub box_xyxy: Vec<f64>,
    pub all_keypoints: Vec<Vec<f64>>,
}

#[derive(Clone, Debug)]
pub struct RustAlignmentResult {
    pub affine_matrix: Vec<Vec<f64>>,
    pub center: Vec<f64>,
    pub size: f64,
    pub rotation: f64,
}

#[derive(Clone, Debug)]
pub struct RustFaceResult {
    pub detection: RustDetection,
    pub blur_value: f64,
    pub alignment: RustAlignmentResult,
    pub embedding: Vec<f64>,
    pub face_id: String,
}

#[derive(Clone, Debug)]
pub struct RustClipResult {
    pub embedding: Vec<f64>,
}

#[derive(Clone, Debug)]
pub struct AnalyzeImageResult {
    pub file_id: i64,
    pub decoded_image_size: RustDimensions,
    pub faces: Option<Vec<RustFaceResult>>,
    pub clip: Option<RustClipResult>,
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

    let decoded = decode_image_from_path(&req.image_path)?;
    let dims = RustDimensions {
        width: decoded.dimensions.width as i32,
        height: decoded.dimensions.height as i32,
    };

    runtime::with_runtime_mut(&runtime_config, |runtime| {
        let faces = if req.run_faces {
            let detections = run_face_detection(runtime, &decoded)?;
            if detections.is_empty() {
                Some(Vec::new())
            } else {
                let (aligned, mut face_results) =
                    run_face_alignment(req.file_id, &decoded, &detections)?;
                run_face_embedding(runtime, &aligned, &mut face_results)?;
                Some(face_results.into_iter().map(to_api_face_result).collect())
            }
        } else {
            None
        };

        let clip = if req.run_clip {
            let clip = run_clip_image(runtime, &decoded)?;
            Some(RustClipResult {
                embedding: clip.embedding.into_iter().map(|v| v as f64).collect(),
            })
        } else {
            None
        };

        Ok(AnalyzeImageResult {
            file_id: req.file_id,
            decoded_image_size: dims.clone(),
            faces,
            clip,
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
            score: result.detection.score as f64,
            box_xyxy: result
                .detection
                .box_xyxy
                .into_iter()
                .map(|v| v as f64)
                .collect(),
            all_keypoints: result
                .detection
                .keypoints
                .into_iter()
                .map(|point| point.into_iter().map(|v| v as f64).collect())
                .collect(),
        },
        blur_value: result.blur_value as f64,
        alignment: RustAlignmentResult {
            affine_matrix: result
                .alignment
                .affine_matrix
                .into_iter()
                .map(|row| row.into_iter().map(|v| v as f64).collect())
                .collect(),
            center: result
                .alignment
                .center
                .into_iter()
                .map(|v| v as f64)
                .collect(),
            size: result.alignment.size as f64,
            rotation: result.alignment.rotation as f64,
        },
        embedding: result.embedding.into_iter().map(|v| v as f64).collect(),
        face_id: result.face_id,
    }
}
