use std::sync::RwLock;

use once_cell::sync::{Lazy, OnceCell};
use ort::Session;

use crate::ml::{
    error::{MlError, MlResult},
    onnx,
};

/// Log to Android logcat or stderr.
fn rt_log(msg: &str) {
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
        let tag = CString::new("ml_rt").unwrap();
        let cmsg = CString::new(msg).unwrap_or_else(|_| CString::new("(invalid)").unwrap());
        unsafe { __android_log_write(4, tag.as_ptr(), cmsg.as_ptr()); }
    }
    #[cfg(not(target_os = "android"))]
    {
        eprintln!("[ml][rt] {msg}");
    }
}

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
    pub clip_text: String,
    pub pet_face_detection: String,
    pub pet_face_embedding_dog: String,
    pub pet_face_embedding_cat: String,
    pub pet_body_detection: String,
    pub pet_body_embedding_dog: String,
    pub pet_body_embedding_cat: String,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MlRuntimeConfig {
    pub model_paths: ModelPaths,
    pub provider_policy: ExecutionProviderPolicy,
}

/// A lazily-initialized ONNX session that is thread-safe for concurrent reads.
///
/// `OnceLock` ensures the session is loaded exactly once (on first use) and
/// then shared via `&Session` for concurrent inference — `ort::Session::run()`
/// takes `&self` and is `Send + Sync`.
#[derive(Debug)]
struct LazySession {
    path: String,
    policy: ExecutionProviderPolicy,
    session: OnceCell<Session>,
}

impl LazySession {
    fn new(path: String, policy: ExecutionProviderPolicy) -> Self {
        Self {
            path,
            policy,
            session: OnceCell::new(),
        }
    }

    fn get(&self, error_msg: &str) -> MlResult<&Session> {
        if self.path.trim().is_empty() {
            return Err(MlError::InvalidRequest(error_msg.to_string()));
        }
        self.session
            .get_or_try_init(|| {
                let model_name = self.path.rsplit('/').next().unwrap_or(&self.path);
                rt_log(&format!("loading {model_name}"));
                let t = std::time::Instant::now();
                let s = onnx::build_session(&self.path, &self.policy)?;
                rt_log(&format!("loaded {model_name} in {:?}", t.elapsed()));
                Ok(s)
            })
    }
}

#[derive(Debug)]
pub struct MlRuntime {
    face_detection: LazySession,
    face_embedding: LazySession,
    clip_image: LazySession,
    clip_text: LazySession,
    pet_face_detection: LazySession,
    pet_face_embedding_dog: LazySession,
    pet_face_embedding_cat: LazySession,
    pet_body_detection: LazySession,
    pet_body_embedding_dog: LazySession,
    pet_body_embedding_cat: LazySession,
}

#[derive(Debug)]
struct RuntimeState {
    config: MlRuntimeConfig,
    runtime: MlRuntime,
}

static GLOBAL_RUNTIME: Lazy<RwLock<Option<RuntimeState>>> = Lazy::new(|| RwLock::new(None));

fn create_runtime(config: &MlRuntimeConfig) -> MlRuntime {
    let p = &config.provider_policy;
    // Pet models use CPU-only to avoid NNAPI/CoreML driver issues with
    // FP16 models on some devices.
    let pet_policy = ExecutionProviderPolicy {
        prefer_coreml: false,
        prefer_nnapi: false,
        prefer_xnnpack: false,
        allow_cpu_fallback: true,
    };
    MlRuntime {
        face_detection: LazySession::new(config.model_paths.face_detection.clone(), p.clone()),
        face_embedding: LazySession::new(config.model_paths.face_embedding.clone(), p.clone()),
        clip_image: LazySession::new(config.model_paths.clip_image.clone(), p.clone()),
        clip_text: LazySession::new(config.model_paths.clip_text.clone(), p.clone()),
        pet_face_detection: LazySession::new(config.model_paths.pet_face_detection.clone(), pet_policy.clone()),
        pet_face_embedding_dog: LazySession::new(config.model_paths.pet_face_embedding_dog.clone(), pet_policy.clone()),
        pet_face_embedding_cat: LazySession::new(config.model_paths.pet_face_embedding_cat.clone(), pet_policy.clone()),
        pet_body_detection: LazySession::new(config.model_paths.pet_body_detection.clone(), pet_policy.clone()),
        pet_body_embedding_dog: LazySession::new(config.model_paths.pet_body_embedding_dog.clone(), pet_policy.clone()),
        pet_body_embedding_cat: LazySession::new(config.model_paths.pet_body_embedding_cat.clone(), pet_policy),
    }
}

impl MlRuntime {
    pub fn face_detection_session(&self) -> MlResult<&Session> {
        self.face_detection.get(
            "missing model path: faceDetectionModelPath is required when runFaces is true",
        )
    }

    pub fn face_embedding_session(&self) -> MlResult<&Session> {
        self.face_embedding.get(
            "missing model path: faceEmbeddingModelPath is required when runFaces is true",
        )
    }

    pub fn clip_image_session(&self) -> MlResult<&Session> {
        self.clip_image.get(
            "missing model path: clipImageModelPath is required when runClip is true",
        )
    }

    pub fn clip_text_session(&self) -> MlResult<&Session> {
        self.clip_text.get(
            "missing model path: clipTextModelPath is required when running clip text",
        )
    }

    pub fn pet_face_detection_session(&self) -> MlResult<&Session> {
        self.pet_face_detection.get(
            "missing model path: petFaceDetectionModelPath is required when runPets is true",
        )
    }

    pub fn pet_face_embedding_dog_session(&self) -> MlResult<&Session> {
        self.pet_face_embedding_dog
            .get("missing model path: petFaceEmbeddingDogModelPath is required")
    }

    pub fn pet_face_embedding_cat_session(&self) -> MlResult<&Session> {
        self.pet_face_embedding_cat
            .get("missing model path: petFaceEmbeddingCatModelPath is required")
    }

    pub fn pet_body_detection_session(&self) -> MlResult<&Session> {
        self.pet_body_detection.get(
            "missing model path: petBodyDetectionModelPath is required when runPets is true",
        )
    }

    pub fn pet_body_embedding_dog_session(&self) -> MlResult<&Session> {
        self.pet_body_embedding_dog
            .get("missing model path: petBodyEmbeddingDogModelPath is required")
    }

    pub fn pet_body_embedding_cat_session(&self) -> MlResult<&Session> {
        self.pet_body_embedding_cat
            .get("missing model path: petBodyEmbeddingCatModelPath is required")
    }
}

fn read_runtime() -> std::sync::RwLockReadGuard<'static, Option<RuntimeState>> {
    match GLOBAL_RUNTIME.read() {
        Ok(guard) => guard,
        Err(poisoned) => poisoned.into_inner(),
    }
}

fn write_runtime() -> std::sync::RwLockWriteGuard<'static, Option<RuntimeState>> {
    match GLOBAL_RUNTIME.write() {
        Ok(guard) => guard,
        Err(poisoned) => {
            let mut guard = poisoned.into_inner();
            *guard = None;
            guard
        }
    }
}

pub fn ensure_runtime(config: &MlRuntimeConfig) -> MlResult<()> {
    let should_rebuild = {
        let guard = read_runtime();
        match guard.as_ref() {
            Some(existing) => existing.config != *config,
            None => true,
        }
    };

    if should_rebuild {
        let runtime = create_runtime(config);
        let mut guard = write_runtime();
        *guard = Some(RuntimeState {
            config: config.clone(),
            runtime,
        });
    }
    Ok(())
}

/// Run a function with a shared (read) reference to the runtime.
///
/// Multiple callers can hold the read lock concurrently, so CLIP text
/// queries no longer block on image indexing and vice versa. The write
/// lock is only acquired during `ensure_runtime` to swap the config.
pub fn with_runtime<F, R>(config: &MlRuntimeConfig, func: F) -> MlResult<R>
where
    F: Fn(&MlRuntime) -> MlResult<R>,
{
    ensure_runtime(config)?;

    let first_result = {
        let guard = read_runtime();
        let state = guard
            .as_ref()
            .ok_or_else(|| MlError::Runtime("runtime is not initialized".to_string()))?;
        func(&state.runtime)
    };

    match first_result {
        Ok(result) => Ok(result),
        Err(first_error) => {
            if !should_retry_with_cpu_only_runtime(config, &first_error) {
                return Err(first_error);
            }

            let fallback_config = cpu_only_runtime_config(config);
            rt_log(&format!("execution provider failed, retrying with CPU-only runtime: {first_error}"));
            ensure_runtime(&fallback_config)?;
            let retry_result = {
                let guard = read_runtime();
                let state = guard
                    .as_ref()
                    .ok_or_else(|| MlError::Runtime("runtime is not initialized".to_string()))?;
                func(&state.runtime)
            };

            if retry_result.is_ok() {
                let mut guard = write_runtime();
                if let Some(state) = guard.as_mut() {
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
    let mut guard = write_runtime();
    *guard = None;
    Ok(())
}
