use std::collections::HashMap;

use ente_media_inspector::ml::{
    indexing as shared_indexing,
    pet::cluster::{self, ClusterConfig, PetClusterInput, Species},
    runtime::{ExecutionProviderPolicy, MlRuntimeConfig, ModelPaths},
    types as shared_types,
};
use ente_media_inspector::vector_db::VectorDB;

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
    shared_indexing::init_ml_runtime(to_runtime_config(&config)).map_err(|e| e.to_string())
}

pub fn release_ml_runtime() -> Result<(), String> {
    shared_indexing::release_ml_runtime().map_err(|e| e.to_string())
}

pub fn analyze_image_rust(req: AnalyzeImageRequest) -> Result<AnalyzeImageResult, String> {
    let shared_req = shared_indexing::AnalyzeImageRequest {
        file_id: req.file_id,
        image_path: req.image_path,
        run_faces: req.run_faces,
        run_clip: req.run_clip,
        run_pets: req.run_pets,
        runtime_config: MlRuntimeConfig {
            model_paths: to_model_paths(&req.model_paths),
            provider_policy: to_provider_policy(&req.provider_policy),
        },
    };

    shared_indexing::analyze_image(shared_req)
        .map(to_api_analyze_image_result)
        .map_err(|e| e.to_string())
}

pub fn run_clip_text_rust(req: RunClipTextRequest) -> Result<RunClipTextResult, String> {
    let shared_req = shared_indexing::RunClipTextRequest {
        text: req.text,
        model_path: req.model_path,
        vocab_path: req.vocab_path,
        provider_policy: to_provider_policy(&req.provider_policy),
    };

    shared_indexing::run_clip_text(shared_req)
        .map(|result| RunClipTextResult {
            embedding: result
                .embedding
                .into_iter()
                .map(|value| value as f64)
                .collect(),
        })
        .map_err(|e| e.to_string())
}

pub fn tokenize_clip_text_rust(text: String, vocab_path: String) -> Result<Vec<i32>, String> {
    shared_indexing::tokenize_clip_text(&text, &vocab_path).map_err(|e| e.to_string())
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

fn to_api_analyze_image_result(result: shared_indexing::AnalyzeImageResult) -> AnalyzeImageResult {
    AnalyzeImageResult {
        file_id: result.file_id,
        decoded_image_size: RustDimensions {
            width: result.decoded_image_size.width as i32,
            height: result.decoded_image_size.height as i32,
        },
        faces: result
            .faces
            .map(|faces| faces.into_iter().map(to_api_face_result).collect()),
        clip: result.clip.map(|clip| RustClipResult {
            embedding: clip.embedding,
        }),
        pet_faces: result
            .pet_faces
            .map(|faces| faces.into_iter().map(to_api_pet_face_result).collect()),
        pet_bodies: result
            .pet_bodies
            .map(|bodies| bodies.into_iter().map(to_api_pet_body_result).collect()),
    }
}

fn to_api_face_result(result: shared_types::FaceResult) -> RustFaceResult {
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

fn to_api_pet_face_result(result: shared_types::PetFaceResult) -> RustPetFaceResult {
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
            center: result
                .alignment
                .center
                .into_iter()
                .map(|v| v as f64)
                .collect(),
            angle: result.alignment.angle as f64,
            crop_size: result.alignment.crop_size as f64,
        },
        species: result.species,
        face_embedding: result
            .face_embedding
            .into_iter()
            .map(|v| v as f64)
            .collect(),
        pet_face_id: result.pet_face_id,
    }
}

fn to_api_pet_body_result(result: shared_types::PetBodyResult) -> RustPetBodyResult {
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
        body_embedding: result
            .body_embedding
            .into_iter()
            .map(|v| v as f64)
            .collect(),
    }
}

// -- Pet Clustering API --

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

/// Cluster exemplars: multiple diverse real embeddings per cluster.
#[derive(Clone, Debug)]
pub struct RustPetClusterExemplarSummary {
    pub cluster_id: String,
    /// Multiple L2-normalized exemplar embeddings (real faces, not averaged).
    pub exemplars: Vec<Vec<f64>>,
    pub count: i32,
}

/// Existing cluster exemplars passed from Dart for incremental matching.
#[derive(Clone, Debug)]
pub struct RustPetClusterExemplarInput {
    pub cluster_id: String,
    pub exemplars: Vec<Vec<f64>>,
}

/// Full clustering result returned to Dart.
#[derive(Clone, Debug)]
pub struct RustPetClusterResult {
    pub assignments: Vec<RustPetClusterEntry>,
    pub summaries: Vec<RustPetClusterSummary>,
    /// Exemplar summaries for multi-exemplar incremental matching.
    pub exemplar_summaries: Vec<RustPetClusterExemplarSummary>,
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
        &config,
    );

    Ok(to_api_cluster_result(result))
}

/// Run incremental pet clustering using multi-exemplar matching.
///
/// Instead of comparing against a single centroid, compares new faces against
/// multiple real exemplar embeddings per cluster for better accuracy.
pub fn run_pet_clustering_incremental_exemplars_rust(
    new_inputs: Vec<RustPetClusterInput>,
    existing_exemplars: Vec<RustPetClusterExemplarInput>,
    species: u8,
) -> Result<RustPetClusterResult, String> {
    let config = ClusterConfig::for_species(Species::from_u8(species));

    let cluster_inputs: Vec<PetClusterInput> = new_inputs
        .into_iter()
        .map(|i| PetClusterInput {
            pet_face_id: i.pet_face_id,
            face_embedding: i.face_embedding.into_iter().map(|v| v as f32).collect(),
            species: i.species,
            file_id: i.file_id,
        })
        .collect();

    let exemplars: HashMap<String, Vec<Vec<f32>>> = existing_exemplars
        .into_iter()
        .map(|e| {
            (
                e.cluster_id,
                e.exemplars
                    .into_iter()
                    .map(|ex| ex.into_iter().map(|v| v as f32).collect())
                    .collect(),
            )
        })
        .collect();

    let result = cluster::run_pet_clustering_incremental_with_exemplars(
        &cluster_inputs,
        &exemplars,
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

    let exemplar_summaries: Vec<RustPetClusterExemplarSummary> = result
        .cluster_exemplars
        .into_iter()
        .map(|(cluster_id, exemplars)| {
            let count = result
                .cluster_counts
                .get(&cluster_id)
                .copied()
                .unwrap_or(0) as i32;
            RustPetClusterExemplarSummary {
                cluster_id,
                exemplars: exemplars
                    .into_iter()
                    .map(|ex| ex.into_iter().map(|v| v as f64).collect())
                    .collect(),
                count,
            }
        })
        .collect();

    RustPetClusterResult {
        assignments,
        summaries,
        exemplar_summaries,
        n_unclustered: result.n_unclustered as i32,
    }
}

// -- Pet Clustering with direct usearch access --

/// Lightweight face metadata passed from Dart (no embeddings).
#[derive(Clone, Debug)]
pub struct RustPetFaceMeta {
    pub pet_face_id: String,
    /// Integer key in the usearch index.
    pub vector_id: i64,
    pub species: u8,
    pub file_id: i64,
    /// Existing cluster ID, or empty string if unclustered.
    pub cluster_id: String,
}

/// Run batch pet clustering by reading embeddings directly from usearch.
///
/// Dart passes only lightweight metadata + the path to the usearch index file.
/// Rust opens the index, bulk-reads embeddings, clusters, and returns
/// assignments — no embedding round-trip through FFI.
pub fn run_pet_clustering_from_index(
    faces: Vec<RustPetFaceMeta>,
    face_index_path: String,
    species: u8,
) -> Result<RustPetClusterResult, String> {
    let config = ClusterConfig::for_species(Species::from_u8(species));
    let dim = 128; // pet face embedding dimension

    let vdb = VectorDB::new(&face_index_path, dim)
        .map_err(|e| format!("Failed to open face index: {e}"))?;

    let mut inputs = Vec::with_capacity(faces.len());
    for face in &faces {
        let emb = match vdb.get_vector(face.vector_id as u64) {
            Ok(v) => v,
            Err(_) => continue,
        };
        inputs.push(PetClusterInput {
            pet_face_id: face.pet_face_id.clone(),
            face_embedding: emb,
            species: face.species,
            file_id: face.file_id,
        });
    }

    if inputs.len() < 2 {
        return Ok(RustPetClusterResult {
            assignments: Vec::new(),
            summaries: Vec::new(),
            exemplar_summaries: Vec::new(),
            n_unclustered: inputs.len() as i32,
        });
    }

    let result = cluster::run_pet_clustering(&inputs, &config);
    Ok(to_api_cluster_result(result))
}

/// Run incremental pet clustering by reading embeddings directly from usearch.
///
/// Only unclustered faces are clustered against existing centroids.
/// Centroids are read from a separate usearch index.
pub fn run_pet_clustering_incremental_from_index(
    new_faces: Vec<RustPetFaceMeta>,
    face_index_path: String,
    centroid_index_path: String,
    // cluster_id -> vector_id in the centroid index
    centroid_mappings: Vec<RustCentroidMapping>,
    // cluster_id -> face count (unused for now, reserved for weighted merge)
    _centroid_counts: Vec<RustCentroidCount>,
    species: u8,
) -> Result<RustPetClusterResult, String> {
    let config = ClusterConfig::for_species(Species::from_u8(species));
    let dim = 128;

    let vdb = VectorDB::new(&face_index_path, dim)
        .map_err(|e| format!("Failed to open face index: {e}"))?;

    let mut inputs = Vec::with_capacity(new_faces.len());
    for face in &new_faces {
        let emb = match vdb.get_vector(face.vector_id as u64) {
            Ok(v) => v,
            Err(_) => continue,
        };
        inputs.push(PetClusterInput {
            pet_face_id: face.pet_face_id.clone(),
            face_embedding: emb,
            species: face.species,
            file_id: face.file_id,
        });
    }

    if inputs.is_empty() {
        return Ok(RustPetClusterResult {
            assignments: Vec::new(),
            summaries: Vec::new(),
            exemplar_summaries: Vec::new(),
            n_unclustered: 0,
        });
    }

    // Load existing centroids from centroid index
    let face_centroids: HashMap<String, Vec<f32>> = if !centroid_mappings.is_empty() {
        let centroid_vdb = VectorDB::new(&centroid_index_path, dim)
            .map_err(|e| format!("Failed to open centroid index: {e}"))?;

        let mut centroids = HashMap::new();
        for mapping in &centroid_mappings {
            if let Ok(emb) = centroid_vdb.get_vector(mapping.vector_id as u64) {
                centroids.insert(mapping.cluster_id.clone(), emb);
            }
        }
        centroids
    } else {
        HashMap::new()
    };

    let result = cluster::run_pet_clustering_incremental(
        &inputs,
        &face_centroids,
        &config,
    );

    Ok(to_api_cluster_result(result))
}

/// Mapping from cluster ID to its vector ID in the centroid usearch index.
#[derive(Clone, Debug)]
pub struct RustCentroidMapping {
    pub cluster_id: String,
    pub vector_id: i64,
}

/// Cluster ID with its face count (for incremental clustering).
#[derive(Clone, Debug)]
pub struct RustCentroidCount {
    pub cluster_id: String,
    pub count: i32,
}

/// Exemplar embeddings for a cluster, used for incremental matching.
#[derive(Clone, Debug)]
pub struct RustClusterExemplars {
    pub cluster_id: String,
    /// Multiple real face embeddings (not averaged), f64 for Dart compatibility.
    pub exemplars: Vec<Vec<f64>>,
}

/// Run incremental pet clustering using multi-exemplar matching.
///
/// Instead of comparing new faces against a single centroid per cluster,
/// compares against multiple diverse real face embeddings (exemplars).
/// Gives F1=0.96 vs centroid's F1=0.86.
pub fn run_pet_clustering_incremental_exemplars_from_index(
    new_faces: Vec<RustPetFaceMeta>,
    face_index_path: String,
    cluster_exemplars: Vec<RustClusterExemplars>,
    species: u8,
) -> Result<RustPetClusterResult, String> {
    let config = ClusterConfig::for_species(Species::from_u8(species));
    let dim = 128;

    let vdb = VectorDB::new(&face_index_path, dim)
        .map_err(|e| format!("Failed to open face index: {e}"))?;

    let mut inputs = Vec::with_capacity(new_faces.len());
    for face in &new_faces {
        let emb = match vdb.get_vector(face.vector_id as u64) {
            Ok(v) => v,
            Err(_) => continue,
        };
        inputs.push(PetClusterInput {
            pet_face_id: face.pet_face_id.clone(),
            face_embedding: emb,
            species: face.species,
            file_id: face.file_id,
        });
    }

    if inputs.is_empty() {
        return Ok(RustPetClusterResult {
            assignments: Vec::new(),
            summaries: Vec::new(),
            exemplar_summaries: Vec::new(),
            n_unclustered: 0,
        });
    }

    // Convert exemplars from f64 to f32
    let existing_exemplars: HashMap<String, Vec<Vec<f32>>> = cluster_exemplars
        .into_iter()
        .map(|ce| {
            let exs: Vec<Vec<f32>> = ce
                .exemplars
                .into_iter()
                .map(|e| e.into_iter().map(|v| v as f32).collect())
                .collect();
            (ce.cluster_id, exs)
        })
        .collect();

    let result = cluster::run_pet_clustering_incremental_with_exemplars(
        &inputs,
        &existing_exemplars,
        &config,
    );

    Ok(to_api_cluster_result(result))
}

