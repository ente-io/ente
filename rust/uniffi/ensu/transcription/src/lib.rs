#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("transcription");

pub use api::*;
