use std::sync::Mutex;

use once_cell::sync::Lazy;
use ort::Session;

use crate::ml::{
    error::{MlError, MlResult},
    onnx,
};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ExecutionProviderPolicy {
    pub prefer_coreml: bool,
    pub prefer_nnapi: bool,
    pub prefer_xnnpack: bool,
    pub allow_cpu_fallback: bool,
}

impl Default for ExecutionProviderPolicy {
    fn default() -> Self {
        Self {
            prefer_coreml: true,
            prefer_nnapi: true,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ModelPaths {
    pub face_detection: String,
    pub face_embedding: String,
    pub clip_image: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MlRuntimeConfig {
    pub model_paths: ModelPaths,
    pub provider_policy: ExecutionProviderPolicy,
}

#[derive(Debug)]
pub struct MlRuntime {
    face_detection: Option<Session>,
    face_embedding: Option<Session>,
    clip_image: Option<Session>,
}

#[derive(Debug)]
struct RuntimeState {
    config: MlRuntimeConfig,
    runtime: MlRuntime,
}

static GLOBAL_RUNTIME: Lazy<Mutex<Option<RuntimeState>>> = Lazy::new(|| Mutex::new(None));

fn create_runtime(config: &MlRuntimeConfig) -> MlResult<MlRuntime> {
    let face_detection =
        build_optional_session(&config.model_paths.face_detection, &config.provider_policy)?;
    let face_embedding =
        build_optional_session(&config.model_paths.face_embedding, &config.provider_policy)?;
    let clip_image =
        build_optional_session(&config.model_paths.clip_image, &config.provider_policy)?;
    Ok(MlRuntime {
        face_detection,
        face_embedding,
        clip_image,
    })
}

fn build_optional_session(
    model_path: &str,
    provider_policy: &ExecutionProviderPolicy,
) -> MlResult<Option<Session>> {
    if model_path.trim().is_empty() {
        return Ok(None);
    }
    Ok(Some(onnx::build_session(model_path, provider_policy)?))
}

impl MlRuntime {
    pub fn face_detection_session_mut(&mut self) -> MlResult<&mut Session> {
        self.face_detection.as_mut().ok_or_else(|| {
            MlError::InvalidRequest(
                "missing model path: faceDetectionModelPath is required when runFaces is true"
                    .to_string(),
            )
        })
    }

    pub fn face_embedding_session_mut(&mut self) -> MlResult<&mut Session> {
        self.face_embedding.as_mut().ok_or_else(|| {
            MlError::InvalidRequest(
                "missing model path: faceEmbeddingModelPath is required when runFaces is true"
                    .to_string(),
            )
        })
    }

    pub fn clip_image_session_mut(&mut self) -> MlResult<&mut Session> {
        self.clip_image.as_mut().ok_or_else(|| {
            MlError::InvalidRequest(
                "missing model path: clipImageModelPath is required when runClip is true"
                    .to_string(),
            )
        })
    }
}

fn lock_runtime() -> std::sync::MutexGuard<'static, Option<RuntimeState>> {
    match GLOBAL_RUNTIME.lock() {
        Ok(guard) => guard,
        Err(poisoned) => {
            // Recover from a previous panic by clearing runtime state.
            let mut guard = poisoned.into_inner();
            *guard = None;
            guard
        }
    }
}

pub fn ensure_runtime(config: &MlRuntimeConfig) -> MlResult<()> {
    let should_rebuild = {
        let guard = lock_runtime();
        match guard.as_ref() {
            Some(existing) => existing.config != *config,
            None => true,
        }
    };

    if should_rebuild {
        let runtime = create_runtime(config)?;
        let mut guard = lock_runtime();
        *guard = Some(RuntimeState {
            config: config.clone(),
            runtime,
        });
    }
    Ok(())
}

pub fn with_runtime_mut<F, R>(config: &MlRuntimeConfig, func: F) -> MlResult<R>
where
    F: FnMut(&mut MlRuntime) -> MlResult<R>,
{
    with_runtime_mut_inner(config, func)
}

fn with_runtime_mut_inner<F, R>(config: &MlRuntimeConfig, mut func: F) -> MlResult<R>
where
    F: FnMut(&mut MlRuntime) -> MlResult<R>,
{
    ensure_runtime(config)?;

    let first_result = {
        let mut guard = lock_runtime();
        let state = guard
            .as_mut()
            .ok_or_else(|| MlError::Runtime("runtime is not initialized".to_string()))?;
        func(&mut state.runtime)
    };

    match first_result {
        Ok(result) => Ok(result),
        Err(first_error) => {
            if !should_retry_with_cpu_only_runtime(config, &first_error) {
                return Err(first_error);
            }

            let fallback_config = cpu_only_runtime_config(config);
            eprintln!(
                "[ml][runtime] execution provider failed, retrying with CPU-only runtime: {first_error}"
            );
            ensure_runtime(&fallback_config)?;
            let retry_result = {
                let mut guard = lock_runtime();
                let state = guard
                    .as_mut()
                    .ok_or_else(|| MlError::Runtime("runtime is not initialized".to_string()))?;
                func(&mut state.runtime)
            };

            if retry_result.is_ok() {
                let mut guard = lock_runtime();
                if let Some(state) = guard.as_mut() {
                    // Keep the recovered runtime hot for this requested config to avoid
                    // repeatedly attempting the failing EP combination on every image.
                    state.config = config.clone();
                }
            }

            retry_result
        }
    }
}

fn should_retry_with_cpu_only_runtime(config: &MlRuntimeConfig, error: &MlError) -> bool {
    if !config.provider_policy.allow_cpu_fallback {
        return false;
    }
    if !is_execution_provider_failure(error) {
        return false;
    }
    cpu_only_runtime_config(config) != *config
}

fn cpu_only_runtime_config(config: &MlRuntimeConfig) -> MlRuntimeConfig {
    let mut fallback = config.clone();
    fallback.provider_policy.prefer_coreml = false;
    fallback.provider_policy.prefer_nnapi = false;
    fallback.provider_policy.prefer_xnnpack = false;
    fallback
}

fn is_execution_provider_failure(error: &MlError) -> bool {
    let MlError::Ort(message) = error else {
        return false;
    };
    let normalized = message.to_ascii_lowercase();
    normalized.contains("executionprovider")
        || normalized.contains("unknown allocation device")
        || normalized.contains("xnnpackexecutionprovider")
        || normalized.contains("nnapiexecutionprovider")
        || normalized.contains("coremlexecutionprovider")
        || normalized.contains("ep error")
}

pub fn release_runtime() -> MlResult<()> {
    let mut guard = lock_runtime();
    *guard = None;
    Ok(())
}
