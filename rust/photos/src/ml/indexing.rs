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
        types::{ClipResult, Dimensions, FaceResult, PetBodyResult, PetFaceResult},
    },
};

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

        let face_detections = if run_faces {
            run_face_detection(runtime, &decoded)?
        } else {
            Vec::new()
        };

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
            let pet_face_detections = run_pet_face_detection(runtime, &decoded)?;

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
