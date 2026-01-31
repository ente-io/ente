#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("llmchat_db_uniffi");

pub use api::*;
