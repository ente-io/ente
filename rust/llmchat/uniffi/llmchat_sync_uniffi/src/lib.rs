#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("llmchat_sync_uniffi");

pub use api::*;
