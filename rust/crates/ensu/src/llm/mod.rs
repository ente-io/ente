mod context;
mod event;
mod generate;
mod model;
mod model_download;

pub use context::*;
pub use event::*;
pub use generate::*;
pub use model::*;
pub use model_download::*;

use llama_cpp_2::llama_backend::LlamaBackend;
use std::sync::OnceLock;

static BACKEND: OnceLock<Result<LlamaBackend, String>> = OnceLock::new();

fn backend() -> Result<&'static LlamaBackend, String> {
    match BACKEND.get_or_init(|| LlamaBackend::init().map_err(|err| err.to_string())) {
        Ok(backend) => Ok(backend),
        Err(err) => Err(format!("Failed to initialize backend: {err}")),
    }
}

fn format_error(context: &str, err: impl std::fmt::Display) -> String {
    format!("{context}: {err}")
}
