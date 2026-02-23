#![allow(unexpected_cfgs)]

mod api;

uniffi::setup_scaffolding!("db");

pub use api::*;
