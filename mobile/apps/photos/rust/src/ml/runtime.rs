use std::sync::RwLock;

use once_cell::sync::Lazy;
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

impl ModelPaths {
    /// Check whether the existing runtime can serve a request with `requested` paths.
    /// An empty path in `requested` means "not needed" and is always compatible.
    fn can_serve(&self, requested: &ModelPaths) -> bool {
        fn ok(existing: &str, requested: &str) -> bool {
            requested.is_empty() || existing == requested
        }
        ok(&self.face_detection, &requested.face_detection)
            && ok(&self.face_embedding, &requested.face_embedding)
            && ok(&self.clip_image, &requested.clip_image)
            && ok(&self.clip_text, &requested.clip_text)
            && ok(&self.pet_face_detection, &requested.pet_face_detection)
            && ok(&self.pet_face_embedding_dog, &requested.pet_face_embedding_dog)
            && ok(&self.pet_face_embedding_cat, &requested.pet_face_embedding_cat)
            && ok(&self.pet_body_detection, &requested.pet_body_detection)
            && ok(&self.pet_body_embedding_dog, &requested.pet_body_embedding_dog)
            && ok(&self.pet_body_embedding_cat, &requested.pet_body_embedding_cat)
    }

    /// Merge two configs: keep existing non-empty paths, override with non-empty
    /// paths from `other`.
    fn merge(&self, other: &ModelPaths) -> ModelPaths {
        fn pick(existing: &str, new: &str) -> String {
            if new.is_empty() { existing.to_string() } else { new.to_string() }
        }
        ModelPaths {
            face_detection: pick(&self.face_detection, &other.face_detection),
            face_embedding: pick(&self.face_embedding, &other.face_embedding),
            clip_image: pick(&self.clip_image, &other.clip_image),
            clip_text: pick(&self.clip_text, &other.clip_text),
            pet_face_detection: pick(&self.pet_face_detection, &other.pet_face_detection),
            pet_face_embedding_dog: pick(&self.pet_face_embedding_dog, &other.pet_face_embedding_dog),
            pet_face_embedding_cat: pick(&self.pet_face_embedding_cat, &other.pet_face_embedding_cat),
            pet_body_detection: pick(&self.pet_body_detection, &other.pet_body_detection),
            pet_body_embedding_dog: pick(&self.pet_body_embedding_dog, &other.pet_body_embedding_dog),
            pet_body_embedding_cat: pick(&self.pet_body_embedding_cat, &other.pet_body_embedding_cat),
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MlRuntimeConfig {
    pub model_paths: ModelPaths,
    pub provider_policy: ExecutionProviderPolicy,
}

#[derive(Debug)]
struct LazySession {
    path: String,
    policy: ExecutionProviderPolicy,
    session: Option<Session>,
}

impl LazySession {
    fn new(path: String, policy: ExecutionProviderPolicy) -> Self {
        Self {
            path,
            policy,
            session: None,
        }
    }

    fn get_mut(&mut self, error_msg: &str) -> MlResult<&mut Session> {
        if self.path.trim().is_empty() {
            return Err(MlError::InvalidRequest(error_msg.to_string()));
        }
        if self.session.is_none() {
            let model_name = self.path.rsplit('/').next().unwrap_or(&self.path);
            rt_log(&format!("loading {model_name}"));
            let t = std::time::Instant::now();
            // Lazy sessions load while the runtime mutex is held (inside func()),
            // so the with_runtime_mut_inner EP fallback cannot catch hangs or OOM
            // during session building. Use CPU-friendly policy to avoid NNAPI/CoreML
            // driver issues (e.g. NNAPI on some MTK devices hangs or OOMs even when
            // it only accelerates <1% of graph nodes).
            let load_policy = ExecutionProviderPolicy {
                prefer_coreml: false,
                prefer_nnapi: false,
                prefer_xnnpack: self.policy.prefer_xnnpack,
                allow_cpu_fallback: true,
            };
            self.session = Some(onnx::build_session(&self.path, &load_policy)?);
            rt_log(&format!("loaded {model_name} in {:?}", t.elapsed()));
        }
        Ok(self.session.as_mut().unwrap())
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
    /// Set after a hardware EP failure triggers a successful CPU-only fallback.
    /// While true, `ensure_runtime` treats a CPU-only runtime as compatible
    /// with requests that prefer hardware acceleration (when
    /// `allow_cpu_fallback` is set), avoiding repeated rebuild/retry cycles
    /// on devices where NNAPI/CoreML is broken.
    fell_back_to_cpu: bool,
}

static GLOBAL_RUNTIME: Lazy<RwLock<Option<RuntimeState>>> = Lazy::new(|| RwLock::new(None));

fn create_runtime(config: &MlRuntimeConfig) -> MlRuntime {
    let p = &config.provider_policy;
    // Pet models use CPU-only to avoid NNAPI/CoreML driver issues with
    // FP16 models on some devices.
    // TODO: Make pet EP policy configurable so hardware acceleration can be
    // re-enabled once driver issues are resolved.
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
    pub fn face_detection_session_mut(&mut self) -> MlResult<&mut Session> {
        self.face_detection.get_mut(
            "missing model path: faceDetectionModelPath is required when runFaces is true",
        )
    }

    pub fn face_embedding_session_mut(&mut self) -> MlResult<&mut Session> {
        self.face_embedding.get_mut(
            "missing model path: faceEmbeddingModelPath is required when runFaces is true",
        )
    }

    pub fn clip_image_session_mut(&mut self) -> MlResult<&mut Session> {
        self.clip_image.get_mut(
            "missing model path: clipImageModelPath is required when runClip is true",
        )
    }

    pub fn clip_text_session_mut(&mut self) -> MlResult<&mut Session> {
        self.clip_text.get_mut(
            "missing model path: clipTextModelPath is required when running clip text",
        )
    }

    pub fn pet_face_detection_session_mut(&mut self) -> MlResult<&mut Session> {
        self.pet_face_detection.get_mut(
            "missing model path: petFaceDetectionModelPath is required when runPets is true",
        )
    }

    pub fn pet_face_embedding_dog_session_mut(&mut self) -> MlResult<&mut Session> {
        self.pet_face_embedding_dog
            .get_mut("missing model path: petFaceEmbeddingDogModelPath is required")
    }

    pub fn pet_face_embedding_cat_session_mut(&mut self) -> MlResult<&mut Session> {
        self.pet_face_embedding_cat
            .get_mut("missing model path: petFaceEmbeddingCatModelPath is required")
    }

    pub fn pet_body_detection_session_mut(&mut self) -> MlResult<&mut Session> {
        self.pet_body_detection.get_mut(
            "missing model path: petBodyDetectionModelPath is required when runPets is true",
        )
    }

    pub fn pet_body_embedding_dog_session_mut(&mut self) -> MlResult<&mut Session> {
        self.pet_body_embedding_dog
            .get_mut("missing model path: petBodyEmbeddingDogModelPath is required")
    }

    pub fn pet_body_embedding_cat_session_mut(&mut self) -> MlResult<&mut Session> {
        self.pet_body_embedding_cat
            .get_mut("missing model path: petBodyEmbeddingCatModelPath is required")
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

/// A CPU-only runtime satisfies a hardware-preferring request when the
/// runtime was installed via EP fallback and the caller allows CPU fallback.
fn policy_compatible(existing: &RuntimeState, requested: &ExecutionProviderPolicy) -> bool {
    existing.config.provider_policy == *requested
        || (existing.fell_back_to_cpu && requested.allow_cpu_fallback)
}

pub fn ensure_runtime(config: &MlRuntimeConfig) -> MlResult<()> {
    ensure_runtime_inner(config, false)
}

/// When `mark_as_fallback` is true the installed runtime is atomically
/// tagged with `fell_back_to_cpu = true` inside the same write lock,
/// preventing a concurrent caller from observing an un-tagged CPU runtime
/// and replacing it with a hardware EP runtime before the flag is set.
fn ensure_runtime_inner(config: &MlRuntimeConfig, mark_as_fallback: bool) -> MlResult<()> {
    // Fast path: check under read lock whether the current runtime can serve.
    // Skip the fast path when marking a fallback — we need the write lock to
    // set `fell_back_to_cpu` atomically.
    if !mark_as_fallback {
        let guard = read_runtime();
        if let Some(existing) = guard.as_ref()
            && policy_compatible(existing, &config.provider_policy)
            && existing.config.model_paths.can_serve(&config.model_paths)
        {
            return Ok(()); // existing runtime handles this request
        }
    }

    // Slow path: acquire write lock, re-check (another thread may have
    // already merged), compute the merged config, build, and install.
    let mut guard = write_runtime();
    let (merged, preserve_fallback) = match guard.as_ref() {
        Some(existing) => {
            // Re-check: a concurrent caller may have updated since the
            // read-lock check above.
            if policy_compatible(existing, &config.provider_policy)
                && existing.config.model_paths.can_serve(&config.model_paths)
            {
                // Runtime already compatible — just ensure the fallback
                // flag is set when requested.
                if mark_as_fallback
                    && let Some(state) = guard.as_mut()
                {
                    state.fell_back_to_cpu = true;
                }
                return Ok(());
            }
            // If we previously fell back to CPU, keep the CPU-only policy
            // for the merged config instead of re-trying the broken EP.
            let effective_policy =
                if existing.fell_back_to_cpu && config.provider_policy.allow_cpu_fallback {
                    existing.config.provider_policy.clone()
                } else {
                    config.provider_policy.clone()
                };
            (
                MlRuntimeConfig {
                    model_paths: existing.config.model_paths.merge(&config.model_paths),
                    provider_policy: effective_policy,
                },
                existing.fell_back_to_cpu,
            )
        }
        None => (config.clone(), false),
    };

    let runtime = create_runtime(&merged);
    *guard = Some(RuntimeState {
        config: merged,
        runtime,
        fell_back_to_cpu: preserve_fallback || mark_as_fallback,
    });
    Ok(())
}

/// Run a function with an exclusive (write) reference to the runtime.
///
/// The write lock is needed because `LazySession` uses mutable access
/// for lazy loading and `unload()` support.
pub fn with_runtime<F, R>(config: &MlRuntimeConfig, func: F) -> MlResult<R>
where
    F: Fn(&mut MlRuntime) -> MlResult<R>,
{
    ensure_runtime(config)?;

    let first_result = {
        let mut guard = write_runtime();
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
            rt_log(&format!("execution provider failed, retrying with CPU-only runtime: {first_error}"));
            // Install the CPU-only runtime and atomically mark it as a
            // fallback so concurrent callers see `fell_back_to_cpu = true`
            // immediately and don't rebuild a hardware EP runtime.
            ensure_runtime_inner(&fallback_config, true)?;

            {
                let mut guard = write_runtime();
                let state = guard
                    .as_mut()
                    .ok_or_else(|| MlError::Runtime("runtime is not initialized".to_string()))?;
                func(&mut state.runtime)
            }
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
