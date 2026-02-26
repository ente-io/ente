#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("inference");

pub use api::*;
