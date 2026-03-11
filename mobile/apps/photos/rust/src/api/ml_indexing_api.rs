use std::collections::HashMap;

use crate::image::decode::decode_image_from_path;
use crate::ml::{
    clip::{image::run_clip_image, text::run_clip_text_query, tokenizer::tokenize_clip_text},
    error::{MlError, MlResult},
    face::{align::run_face_alignment, detect::run_face_detection, embed::run_face_embedding},
    pet::{
        align::run_pet_face_alignment,
        cluster::{self, ClusterConfig, PetClusterInput, Species},
        detect::{run_pet_body_detection, run_pet_face_detection},
        embed::{run_pet_body_embedding, run_pet_face_embedding},
    },
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
    pub clip_text: String,
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

#[derive(Clone, Debug)]
pub struct RunClipTextRequest {
    pub text: String,
    pub model_path: String,
    pub vocab_path: String,
    pub provider_policy: RustExecutionProviderPolicy,
}

#[derive(Clone, Debug)]
pub struct RunClipTextResult {
    pub embedding: Vec<f64>,
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

pub fn run_clip_text_rust(req: RunClipTextRequest) -> Result<RunClipTextResult, String> {
    run_clip_text_rust_inner(req).map_err(|e| e.to_string())
}

pub fn tokenize_clip_text_rust(text: String, vocab_path: String) -> Result<Vec<i32>, String> {
    tokenize_clip_text_rust_inner(&text, &vocab_path).map_err(|e| e.to_string())
}

fn analyze_image_rust_inner(req: AnalyzeImageRequest) -> MlResult<AnalyzeImageResult> {
    validate_request_model_paths(&req)?;

    let runtime_config = MlRuntimeConfig {
        model_paths: to_model_paths(&req.model_paths),
        provider_policy: to_provider_policy(&req.provider_policy),
    };

    runtime::with_runtime(&runtime_config, |runtime| {
        let decoded = decode_image_from_path(&req.image_path)?;
        let dims = RustDimensions {
            width: decoded.dimensions.width as i32,
            height: decoded.dimensions.height as i32,
        };

        let faces = if req.run_faces {
            let detections = run_face_detection(runtime, &decoded)?;
            if detections.is_empty() {
                Some(Vec::new())
            } else {
                let (aligned, mut face_results) =
                    run_face_alignment(req.file_id, &decoded, detections)?;
                run_face_embedding(runtime, &aligned, &mut face_results)?;
                Some(face_results.into_iter().map(to_api_face_result).collect())
            }
        } else {
            None
        };

        let clip = if req.run_clip {
            let clip = run_clip_image(runtime, &decoded)?;
            Some(RustClipResult {
                embedding: clip.embedding,
            })
        } else {
            None
        };

        let (pet_faces, pet_bodies) = if req.run_pets {
            let pet_face_detections = run_pet_face_detection(runtime, &decoded)?;
            let body_detections = run_pet_body_detection(runtime, &decoded)?;

            let pet_face_results = if !pet_face_detections.is_empty() {
                let (aligned, mut pet_results) =
                    run_pet_face_alignment(req.file_id, &decoded, &pet_face_detections)?;
                run_pet_face_embedding(runtime, &aligned, &mut pet_results)?;
                pet_results
            } else {
                Vec::new()
            };

            let mut body_results: Vec<crate::ml::types::PetBodyResult> = body_detections
                .into_iter()
                .map(|det| {
                    let base_id = crate::ml::types::to_face_id(req.file_id, det.box_xyxy);
                    let pet_body_id = format!("{base_id}_c{}", det.coco_class);
                    crate::ml::types::PetBodyResult {
                        pet_body_id,
                        detection: det,
                        body_embedding: Vec::new(),
                    }
                })
                .collect();
            if !body_results.is_empty() {
                run_pet_body_embedding(runtime, &decoded, &mut body_results)?;
            }

            (
                Some(pet_face_results.into_iter().map(to_api_pet_face_result).collect()),
                Some(body_results.into_iter().map(to_api_pet_body_result).collect()),
            )
        } else {
            (None, None)
        };

        Ok(AnalyzeImageResult {
            file_id: req.file_id,
            decoded_image_size: dims,
            faces,
            clip,
            pet_faces,
            pet_bodies,
        })
    })
}

fn run_clip_text_rust_inner(req: RunClipTextRequest) -> MlResult<RunClipTextResult> {
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
        provider_policy: to_provider_policy(&provider_policy),
    };

    runtime::with_runtime(&runtime_config, |runtime| {
        let clip = run_clip_text_query(runtime, &text, &vocab_path)?;
        Ok(RunClipTextResult {
            embedding: clip
                .embedding
                .into_iter()
                .map(|value| value as f64)
                .collect(),
        })
    })
}

fn tokenize_clip_text_rust_inner(text: &str, vocab_path: &str) -> MlResult<Vec<i32>> {
    if vocab_path.trim().is_empty() {
        return Err(MlError::InvalidRequest(
            "missing model path: clipTextVocabPath".to_string(),
        ));
    }
    tokenize_clip_text(text, vocab_path)
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
        clip_text: paths.clip_text.clone(),
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

// ── Pet Clustering API ──────────────────────────────────────────────────

/// A single pet face/body entry for clustering, passed from Dart.
#[derive(Clone, Debug)]
pub struct RustPetClusterInput {
    pub pet_face_id: String,
    /// L2-normalized face embedding. Empty if no face detected.
    pub face_embedding: Vec<f64>,
    /// L2-normalized body embedding. Empty if no body detected.
    pub body_embedding: Vec<f64>,
    /// 0 = dog, 1 = cat.
    pub species: u8,
    pub file_id: i64,
}

/// Result entry: one pet_face_id mapped to a cluster.
#[derive(Clone, Debug)]
pub struct RustPetClusterEntry {
    pub pet_face_id: String,
    pub cluster_id: String,
}

/// Cluster summary: centroid + count.
#[derive(Clone, Debug)]
pub struct RustPetClusterSummary {
    pub cluster_id: String,
    pub centroid: Vec<f64>,
    pub count: i32,
}

/// Full clustering result returned to Dart.
#[derive(Clone, Debug)]
pub struct RustPetClusterResult {
    pub assignments: Vec<RustPetClusterEntry>,
    pub summaries: Vec<RustPetClusterSummary>,
    pub n_unclustered: i32,
}

/// Run batch pet clustering on all provided inputs.
pub fn run_pet_clustering_rust(
    inputs: Vec<RustPetClusterInput>,
    species: u8,
) -> Result<RustPetClusterResult, String> {
    let config = ClusterConfig::for_species(Species::from_u8(species));

    let cluster_inputs: Vec<PetClusterInput> = inputs
        .into_iter()
        .map(|i| PetClusterInput {
            pet_face_id: i.pet_face_id,
            face_embedding: i.face_embedding.into_iter().map(|v| v as f32).collect(),
            body_embedding: i.body_embedding.into_iter().map(|v| v as f32).collect(),
            species: i.species,
            file_id: i.file_id,
        })
        .collect();

    let result = cluster::run_pet_clustering(&cluster_inputs, &config);

    Ok(to_api_cluster_result(result))
}

/// Run incremental pet clustering: assign new inputs to existing clusters,
/// then cluster remainder among themselves.
pub fn run_pet_clustering_incremental_rust(
    new_inputs: Vec<RustPetClusterInput>,
    existing_face_centroids: Vec<RustPetClusterSummary>,
    existing_body_centroids: Vec<RustPetClusterSummary>,
    species: u8,
) -> Result<RustPetClusterResult, String> {
    let config = ClusterConfig::for_species(Species::from_u8(species));

    let cluster_inputs: Vec<PetClusterInput> = new_inputs
        .into_iter()
        .map(|i| PetClusterInput {
            pet_face_id: i.pet_face_id,
            face_embedding: i.face_embedding.into_iter().map(|v| v as f32).collect(),
            body_embedding: i.body_embedding.into_iter().map(|v| v as f32).collect(),
            species: i.species,
            file_id: i.file_id,
        })
        .collect();

    let face_centroids: HashMap<String, Vec<f32>> = existing_face_centroids
        .into_iter()
        .map(|s| {
            (
                s.cluster_id,
                s.centroid.into_iter().map(|v| v as f32).collect(),
            )
        })
        .collect();

    let body_centroids: HashMap<String, Vec<f32>> = existing_body_centroids
        .into_iter()
        .map(|s| {
            (
                s.cluster_id,
                s.centroid.into_iter().map(|v| v as f32).collect(),
            )
        })
        .collect();

    let result = cluster::run_pet_clustering_incremental(
        &cluster_inputs,
        &face_centroids,
        &body_centroids,
        &config,
    );

    Ok(to_api_cluster_result(result))
}

fn to_api_cluster_result(result: cluster::PetClusterResult) -> RustPetClusterResult {
    let assignments: Vec<RustPetClusterEntry> = result
        .face_to_cluster
        .into_iter()
        .map(|(face_id, cluster_id)| RustPetClusterEntry {
            pet_face_id: face_id,
            cluster_id,
        })
        .collect();

    let summaries: Vec<RustPetClusterSummary> = result
        .cluster_centroids
        .into_iter()
        .map(|(cluster_id, centroid)| {
            let count = result
                .cluster_counts
                .get(&cluster_id)
                .copied()
                .unwrap_or(0) as i32;
            RustPetClusterSummary {
                cluster_id,
                centroid: centroid.into_iter().map(|v| v as f64).collect(),
                count,
            }
        })
        .collect();

    RustPetClusterResult {
        assignments,
        summaries,
        n_unclustered: result.n_unclustered as i32,
    }
}
