use std::path::{Path, PathBuf};
use std::sync::{Mutex, OnceLock};

use transcribe_rs::onnx::Quantization;
use transcribe_rs::onnx::parakeet::{ParakeetModel, ParakeetParams, TimestampGranularity};

use crate::audio::extract_speech_from_pcm16;
use crate::model::model_path;
use crate::text::filter_transcription_output;
use crate::{Result, error};

static MANAGER: OnceLock<Mutex<TranscriptionManager>> = OnceLock::new();

struct TranscriptionManager {
    loaded_path: Option<PathBuf>,
    model: Option<ParakeetModel>,
}

impl TranscriptionManager {
    fn new() -> Self {
        Self {
            loaded_path: None,
            model: None,
        }
    }

    fn transcribe(
        &mut self,
        models_dir: impl AsRef<Path>,
        vad_cache_dir: impl AsRef<Path>,
        input_sample_rate: u32,
        pcm_le: Vec<u8>,
    ) -> Result<String> {
        if pcm_le.is_empty() {
            return Ok(String::new());
        }

        let model_dir = model_path(models_dir);
        if !model_dir.is_dir() {
            return Err(error("Transcription model is not downloaded"));
        }

        self.ensure_loaded(&model_dir)?;

        let speech = extract_speech_from_pcm16(vad_cache_dir, input_sample_rate, &pcm_le)?;
        if speech.is_empty() {
            return Ok(String::new());
        }

        let model = self
            .model
            .as_mut()
            .ok_or_else(|| error("Transcription model is not loaded"))?;
        let result = model.transcribe_with(
            &speech,
            &ParakeetParams {
                timestamp_granularity: Some(TimestampGranularity::Segment),
                ..Default::default()
            },
        )?;

        Ok(filter_transcription_output(&result.text))
    }

    fn ensure_loaded(&mut self, model_dir: &Path) -> Result<()> {
        if self.loaded_path.as_deref() == Some(model_dir) && self.model.is_some() {
            return Ok(());
        }

        let model = ParakeetModel::load(model_dir, &Quantization::Int8)?;
        self.loaded_path = Some(model_dir.to_path_buf());
        self.model = Some(model);
        Ok(())
    }

    fn unload(&mut self) {
        self.loaded_path = None;
        self.model = None;
    }
}

fn manager() -> &'static Mutex<TranscriptionManager> {
    MANAGER.get_or_init(|| Mutex::new(TranscriptionManager::new()))
}

pub fn transcribe_pcm16(
    models_dir: impl AsRef<Path>,
    vad_cache_dir: impl AsRef<Path>,
    input_sample_rate: u32,
    pcm_le: Vec<u8>,
) -> Result<String> {
    manager()
        .lock()
        .map_err(|_| error("transcription manager lock poisoned"))?
        .transcribe(models_dir, vad_cache_dir, input_sample_rate, pcm_le)
}

pub fn unload_model() -> Result<()> {
    manager()
        .lock()
        .map_err(|_| error("transcription manager lock poisoned"))?
        .unload();
    Ok(())
}
