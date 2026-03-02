use crate::ml::{
    error::{MlError, MlResult},
    onnx,
    runtime::MlRuntime,
    types::{DecodedImage, PetBodyResult, PetFaceResult},
};

use super::preprocess::{extract_crop, preprocess_pet_embedding};

const FACE_EMBED_INPUT_SIZE: i64 = 224;
const BODY_EMBED_INPUT_SIZE: i64 = 224;
const FACE_EMBED_CHANNELS: i64 = 3;
const BODY_EMBED_CHANNELS: i64 = 3;

/// Run pet face embedding on aligned face inputs.
///
/// The species parameter (0=dog, 1=cat) selects the model to use.
///
/// Input per face: CHW float32 of shape [1, 3, 224, 224], ImageNet-normalized.
/// Output: L2-normalized embedding vector (128-d for BYOL).
///
/// This mirrors `pet_pipeline/embedding.py` `Embedder.embed_face()`.
pub fn run_pet_face_embedding(
    runtime: &mut MlRuntime,
    aligned_faces: &[Vec<f32>],
    face_results: &mut [PetFaceResult],
    species: u8,
) -> MlResult<()> {
    if aligned_faces.is_empty() {
        return Ok(());
    }
    if aligned_faces.len() != face_results.len() {
        return Err(MlError::Postprocess(format!(
            "aligned pet faces count ({}) does not match face result count ({})",
            aligned_faces.len(),
            face_results.len()
        )));
    }

    let per_face_len = (FACE_EMBED_INPUT_SIZE * FACE_EMBED_INPUT_SIZE * FACE_EMBED_CHANNELS) as usize;
    let mut input = Vec::with_capacity(per_face_len * aligned_faces.len());
    for aligned in aligned_faces {
        if aligned.len() != per_face_len {
            return Err(MlError::Preprocess(format!(
                "aligned pet face tensor length {} does not match expected {}",
                aligned.len(),
                per_face_len
            )));
        }
        input.extend_from_slice(aligned);
    }

    let session = if species == 0 {
        runtime.pet_face_embedding_dog_session_mut()?
    } else {
        runtime.pet_face_embedding_cat_session_mut()?
    };

    let (shape, output) = onnx::run_f32(
        session,
        input,
        vec![
            aligned_faces.len() as i64,
            FACE_EMBED_CHANNELS,
            FACE_EMBED_INPUT_SIZE,
            FACE_EMBED_INPUT_SIZE,
        ],
    )?;

    if shape.is_empty() {
        return Err(MlError::Postprocess(
            "pet face embedding output shape is empty".to_string(),
        ));
    }
    let batch = shape[0] as usize;
    if batch != face_results.len() {
        return Err(MlError::Postprocess(format!(
            "pet face embedding batch mismatch: output={batch}, expected={}",
            face_results.len()
        )));
    }
    let embedding_size = output.len() / batch;

    for (idx, face_result) in face_results.iter_mut().enumerate() {
        let start = idx * embedding_size;
        let mut embedding = output[start..(start + embedding_size)].to_vec();
        normalize_embedding(&mut embedding);
        face_result.face_embedding = embedding;
        face_result.species = species;
    }

    Ok(())
}

/// Run pet body embedding on cropped body regions.
///
/// For each body detection, extracts a crop, preprocesses with ImageNet
/// normalization, and runs through the species-specific body embedding model.
///
/// This mirrors `pet_pipeline/embedding.py` `Embedder.embed_body()`.
pub fn run_pet_body_embedding(
    runtime: &mut MlRuntime,
    decoded: &DecodedImage,
    body_results: &mut [PetBodyResult],
    species: u8,
) -> MlResult<()> {
    for body_result in body_results.iter_mut() {
        let (crop_data, crop_w, crop_h) = extract_crop(decoded, &body_result.detection.box_xyxy)?;
        let input = preprocess_pet_embedding(&crop_data, crop_w, crop_h)?;

        let session = if species == 0 {
            runtime.pet_body_embedding_dog_session_mut()?
        } else {
            runtime.pet_body_embedding_cat_session_mut()?
        };

        let (_shape, output) = onnx::run_f32(
            session,
            input,
            vec![
                1,
                BODY_EMBED_CHANNELS,
                BODY_EMBED_INPUT_SIZE,
                BODY_EMBED_INPUT_SIZE,
            ],
        )?;

        let mut embedding = output;
        normalize_embedding(&mut embedding);
        body_result.body_embedding = embedding;
    }

    Ok(())
}

fn normalize_embedding(embedding: &mut [f32]) {
    let mut norm = 0.0f32;
    for value in embedding.iter() {
        norm += value * value;
    }
    let norm = norm.sqrt();
    if norm <= f32::EPSILON {
        return;
    }
    for value in embedding.iter_mut() {
        *value /= norm;
    }
}
