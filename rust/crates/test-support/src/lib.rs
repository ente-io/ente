//! A live Museum for integration tests.
//!
//! [`Museum`] spins up a local Museum server backed by a temporary local
//! Postgres ([postgresql_embedded]). See the crate README for requirements.

mod museum;
mod postgres;
mod process;
mod server;

pub use museum::Museum;

pub type TestResult<T = ()> = Result<T, Box<dyn std::error::Error>>;

const LOCAL_HOST: &str = "127.0.0.1";

/// Museum is configured to accept this OTT for `HARDCODED_OTT_EMAIL_SUFFIX`
/// addresses, letting tests verify emails without an email inbox.
pub const HARDCODED_OTT: &str = "123456";
pub const HARDCODED_OTT_EMAIL_SUFFIX: &str = "@ente-rust-test.org";
