#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("sync");

pub use api::*;
