use llama_cpp_2::context::LlamaContext;
use llama_cpp_2::context::params::LlamaContextParams;
use llama_cpp_2::model::LlamaModel;
use llama_cpp_2::mtmd::{MtmdContext, MtmdContextParams, mtmd_default_marker};
use parking_lot::Mutex;
use self_cell::self_cell;
use serde::{Deserialize, Serialize};
use std::ffi::CString;
use std::num::NonZeroU32;
use std::path::Path;
use std::sync::Arc;

use super::model::ModelHandleRef;
use super::{backend, format_error};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextParams {
    pub context_size: Option<i32>,
    pub n_threads: Option<i32>,
    pub n_batch: Option<i32>,
}

self_cell!(
    struct ContextHandleCell {
        owner: ModelHandleRef,

        #[covariant]
        dependent: LlamaContext,
    }
);

#[derive(Debug, Clone, PartialEq, Eq)]
struct MtmdCacheKey {
    mmproj_path: String,
    media_marker: String,
    use_gpu: bool,
    print_timings: bool,
    n_threads: i32,
}

struct CachedMtmdContext {
    key: MtmdCacheKey,
    context: Arc<MtmdContext>,
}

pub struct ContextHandle {
    cell: Mutex<ContextHandleCell>,
    mtmd_context: Mutex<Option<CachedMtmdContext>>,
}

pub type ContextHandleRef = Arc<ContextHandle>;

unsafe impl Send for ContextHandle {}
unsafe impl Sync for ContextHandle {}

impl ContextHandle {
    fn try_new(
        owner: ModelHandleRef,
        builder: impl for<'a> FnOnce(&'a ModelHandleRef) -> Result<LlamaContext<'a>, String>,
    ) -> Result<Self, String> {
        ContextHandleCell::try_new(owner, builder).map(|cell| ContextHandle {
            cell: Mutex::new(cell),
            mtmd_context: Mutex::new(None),
        })
    }

    pub(super) fn with_context_mut<R>(
        &self,
        func: impl for<'a, 'b> FnOnce(&'b mut LlamaContext<'a>) -> R,
    ) -> R {
        let mut guard = self.cell.lock();
        guard.with_dependent_mut(|_owner, context| func(context))
    }

    pub(super) fn cached_mtmd_context(
        &self,
        model: &LlamaModel,
        mmproj_path: &str,
        marker: &str,
    ) -> Result<Arc<MtmdContext>, String> {
        if !Path::new(mmproj_path).exists() {
            return Err(format!("mmproj file not found at {mmproj_path}"));
        }

        let (key, params) = mtmd_cache_key_and_params(mmproj_path, marker)?;
        let mut guard = self.mtmd_context.lock();

        if let Some(cached) = guard.as_ref()
            && cached.key == key
        {
            return Ok(cached.context.clone());
        }

        let mtmd_ctx = Arc::new(
            MtmdContext::init_from_file(mmproj_path, model, &params)
                .map_err(|err| format_error("Failed to initialize mmproj", err))?,
        );

        if !mtmd_ctx.support_vision() {
            return Err("Model does not support vision input".to_string());
        }

        *guard = Some(CachedMtmdContext {
            key,
            context: mtmd_ctx.clone(),
        });
        Ok(mtmd_ctx)
    }
}

fn mtmd_cache_key_and_params(
    mmproj_path: &str,
    marker: &str,
) -> Result<(MtmdCacheKey, MtmdContextParams), String> {
    let media_marker = CString::new(marker.to_string())
        .map_err(|err| format_error("Invalid media marker", err))?;
    let params = MtmdContextParams {
        use_gpu: false,
        print_timings: false,
        media_marker,
        ..Default::default()
    };
    let marker = params
        .media_marker
        .to_str()
        .map_err(|err| format_error("Invalid media marker", err))?
        .to_string();
    let key = MtmdCacheKey {
        mmproj_path: mmproj_path.to_string(),
        media_marker: marker,
        use_gpu: params.use_gpu,
        print_timings: params.print_timings,
        n_threads: params.n_threads,
    };
    Ok((key, params))
}

pub fn create_context(
    model: ModelHandleRef,
    params: ContextParams,
) -> Result<ContextHandleRef, String> {
    let mut context_params = LlamaContextParams::default();

    if let Some(context_size) = params.context_size {
        let context_size =
            u32::try_from(context_size).map_err(|_| "context_size must be > 0".to_string())?;
        let context_size =
            NonZeroU32::new(context_size).ok_or_else(|| "context_size must be > 0".to_string())?;
        context_params = context_params.with_n_ctx(Some(context_size));
    }

    if let Some(n_threads) = params.n_threads {
        if n_threads <= 0 {
            return Err("n_threads must be > 0".to_string());
        }
        context_params = context_params
            .with_n_threads(n_threads)
            .with_n_threads_batch(n_threads);
    }

    if let Some(n_batch) = params.n_batch {
        let n_batch = u32::try_from(n_batch).map_err(|_| "n_batch must be > 0".to_string())?;
        context_params = context_params.with_n_batch(n_batch);
    }

    let context = ContextHandle::try_new(model, |model| {
        let backend = backend()?;
        model
            .model()
            .new_context(backend, context_params)
            .map_err(|err| format_error("Failed to create context", err))
    })?;

    Ok(Arc::new(context))
}

pub fn prewarm_multimodal_context(
    context: &ContextHandle,
    mmproj_path: String,
    media_marker: Option<String>,
) -> Result<(), String> {
    let marker = media_marker.unwrap_or_else(|| mtmd_default_marker().to_string());
    context.with_context_mut(|ctx| {
        context
            .cached_mtmd_context(ctx.model, &mmproj_path, &marker)
            .map(|_| ())
    })
}
