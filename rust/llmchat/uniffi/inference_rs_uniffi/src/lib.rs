#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("inference_rs_uniffi");

pub use api::*;
