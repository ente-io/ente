//! Shared fixture for integration tests that need a live Museum.
//!
//! [`Fixture`] spins up a local Museum server backed by an in-memory Postgres
//! using [pglite](https://pglite.dev). See the crate README for requirements
//! and the one-time npm setup.

mod fixture;
mod museum;
mod pglite;
mod process;

pub use fixture::Fixture;

pub type TestResult<T = ()> = Result<T, Box<dyn std::error::Error>>;

const LOCAL_HOST: &str = "127.0.0.1";

/// Museum is configured to accept this OTT for `HARDCODED_OTT_EMAIL_SUFFIX`
/// addresses, letting tests verify emails without an email inbox.
pub const HARDCODED_OTT: &str = "123456";
pub const HARDCODED_OTT_EMAIL_SUFFIX: &str = "@ente-rust-test.org";
