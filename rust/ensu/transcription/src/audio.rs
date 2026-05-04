use std::fs;
use std::path::{Path, PathBuf};
use std::time::Duration;

use rubato::{FftFixedIn, Resampler};
use transcribe_rs::vad::{SileroVad, SmoothedVad, Vad};

use crate::{Result, error};

const SILERO_VAD_BYTES: &[u8] = include_bytes!("../assets/silero_vad_v4.onnx");
const SILERO_VAD_FILE_NAME: &str = "silero_vad_v4.onnx";
const TARGET_SAMPLE_RATE: usize = 16_000;
const RESAMPLER_CHUNK_SIZE: usize = 1024;
const VAD_THRESHOLD: f32 = 0.5;
const VAD_PREFILL_FRAMES: usize = 3;
const VAD_HANGOVER_FRAMES: usize = 10;
const VAD_ONSET_FRAMES: usize = 2;

pub fn extract_speech_from_pcm16(
    cache_dir: impl AsRef<Path>,
    input_sample_rate: u32,
    pcm_le: &[u8],
) -> Result<Vec<f32>> {
    if input_sample_rate == 0 {
        return Err(error("input sample rate must be greater than zero"));
    }
    if pcm_le.len() % 2 != 0 {
        return Err(error("PCM16 input must contain an even number of bytes"));
    }

    let samples = pcm_le
        .chunks_exact(2)
        .map(|chunk| i16::from_le_bytes([chunk[0], chunk[1]]) as f32 / 32768.0)
        .collect::<Vec<_>>();

    extract_speech(cache_dir, input_sample_rate, &samples)
}

fn extract_speech(
    cache_dir: impl AsRef<Path>,
    input_sample_rate: u32,
    samples: &[f32],
) -> Result<Vec<f32>> {
    if samples.is_empty() {
        return Ok(Vec::new());
    }

    let vad_model_path = ensure_vad_model(cache_dir)?;
    let silero = SileroVad::new(&vad_model_path, VAD_THRESHOLD)?;
    let mut vad = SmoothedVad::new(
        Box::new(silero),
        VAD_PREFILL_FRAMES,
        VAD_HANGOVER_FRAMES,
        VAD_ONSET_FRAMES,
    );

    let mut resampler = FrameResampler::new(
        input_sample_rate as usize,
        TARGET_SAMPLE_RATE,
        Duration::from_millis(30),
    )?;
    let mut speech = Vec::new();

    resampler.push(samples, |frame| {
        if let Ok(true) = vad.is_speech(frame) {
            let prefill = vad.drain_prefill();
            if !prefill.is_empty() {
                speech.extend_from_slice(&prefill);
            }
            speech.extend_from_slice(frame);
        }
    });
    resampler.finish(|frame| {
        if let Ok(true) = vad.is_speech(frame) {
            let prefill = vad.drain_prefill();
            if !prefill.is_empty() {
                speech.extend_from_slice(&prefill);
            }
            speech.extend_from_slice(frame);
        }
    });
    vad.reset();

    let min_samples = TARGET_SAMPLE_RATE * 5 / 4;
    if speech.len() < TARGET_SAMPLE_RATE && !speech.is_empty() {
        speech.resize(min_samples, 0.0);
    }

    Ok(speech)
}

fn ensure_vad_model(cache_dir: impl AsRef<Path>) -> Result<PathBuf> {
    let cache_dir = cache_dir.as_ref();
    fs::create_dir_all(cache_dir)?;
    let path = cache_dir.join(SILERO_VAD_FILE_NAME);
    let should_write = match fs::metadata(&path) {
        Ok(metadata) => metadata.len() != SILERO_VAD_BYTES.len() as u64,
        Err(_) => true,
    };
    if should_write {
        fs::write(&path, SILERO_VAD_BYTES)?;
    }
    Ok(path)
}

struct FrameResampler {
    resampler: Option<FftFixedIn<f32>>,
    chunk_in: usize,
    in_buf: Vec<f32>,
    frame_samples: usize,
    pending: Vec<f32>,
}

impl FrameResampler {
    fn new(in_hz: usize, out_hz: usize, frame_dur: Duration) -> Result<Self> {
        let frame_samples = ((out_hz as f64 * frame_dur.as_secs_f64()).round()) as usize;
        if frame_samples == 0 {
            return Err(error("frame duration too short"));
        }

        let resampler = if in_hz == out_hz {
            None
        } else {
            Some(FftFixedIn::<f32>::new(
                in_hz,
                out_hz,
                RESAMPLER_CHUNK_SIZE,
                1,
                1,
            )?)
        };

        Ok(Self {
            resampler,
            chunk_in: RESAMPLER_CHUNK_SIZE,
            in_buf: Vec::with_capacity(RESAMPLER_CHUNK_SIZE),
            frame_samples,
            pending: Vec::with_capacity(frame_samples),
        })
    }

    fn push(&mut self, mut src: &[f32], mut emit: impl FnMut(&[f32])) {
        if self.resampler.is_none() {
            self.emit_frames(src, &mut emit);
            return;
        }

        while !src.is_empty() {
            let space = self.chunk_in - self.in_buf.len();
            let take = space.min(src.len());
            self.in_buf.extend_from_slice(&src[..take]);
            src = &src[take..];

            if self.in_buf.len() == self.chunk_in {
                if let Some(resampler) = self.resampler.as_mut() {
                    if let Ok(out) = resampler.process(&[&self.in_buf[..]], None) {
                        self.emit_frames(&out[0], &mut emit);
                    }
                }
                self.in_buf.clear();
            }
        }
    }

    fn finish(&mut self, mut emit: impl FnMut(&[f32])) {
        if let Some(resampler) = self.resampler.as_mut() {
            if !self.in_buf.is_empty() {
                self.in_buf.resize(self.chunk_in, 0.0);
                if let Ok(out) = resampler.process(&[&self.in_buf[..]], None) {
                    self.emit_frames(&out[0], &mut emit);
                }
            }
        }

        if !self.pending.is_empty() {
            self.pending.resize(self.frame_samples, 0.0);
            emit(&self.pending);
            self.pending.clear();
        }
    }

    fn emit_frames(&mut self, mut data: &[f32], emit: &mut impl FnMut(&[f32])) {
        while !data.is_empty() {
            let space = self.frame_samples - self.pending.len();
            let take = space.min(data.len());
            self.pending.extend_from_slice(&data[..take]);
            data = &data[take..];

            if self.pending.len() == self.frame_samples {
                emit(&self.pending);
                self.pending.clear();
            }
        }
    }
}
