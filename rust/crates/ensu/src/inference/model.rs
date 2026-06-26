use llama_cpp_2::model::LlamaModel;
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::Arc;

use super::{backend, format_error};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelLoadParams {
    pub model_path: String,
    pub n_gpu_layers: Option<i32>,
    pub use_mmap: Option<bool>,
    pub use_mlock: Option<bool>,
}

pub struct ModelHandle {
    model: LlamaModel,
}

pub type ModelHandleRef = Arc<ModelHandle>;

impl ModelHandle {
    pub(super) fn model(&self) -> &LlamaModel {
        &self.model
    }
}

pub fn init_backend() -> Result<(), String> {
    backend().map(|_| ())
}

pub fn load_model(params: ModelLoadParams) -> Result<ModelHandleRef, String> {
    let backend = backend()?;
    let mut model_params = llama_cpp_2::model::params::LlamaModelParams::default();

    if let Some(n_gpu_layers) = params.n_gpu_layers {
        let layers =
            u32::try_from(n_gpu_layers).map_err(|_| "n_gpu_layers must be >= 0".to_string())?;
        model_params = model_params.with_n_gpu_layers(layers);
    }

    if let Some(use_mlock) = params.use_mlock {
        model_params = model_params.with_use_mlock(use_mlock);
    }

    let model = LlamaModel::load_from_file(backend, Path::new(&params.model_path), &model_params)
        .map_err(|err| format_error("Failed to load model", err))?;

    Ok(Arc::new(ModelHandle { model }))
}
