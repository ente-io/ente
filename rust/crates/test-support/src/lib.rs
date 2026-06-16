//! A live Museum for integration tests.
//!
//! [`Museum`] spins up a local Museum server backed by a temporary local
//! Postgres ([postgresql_embedded]). See the crate README for requirements.
//!
//! [postgresql_embedded]: https://crates.io/crates/postgresql_embedded

mod museum;
mod postgres;
mod process;
mod server;

pub use museum::Museum;

pub type TestResult<T = ()> = Result<T, Box<dyn std::error::Error>>;

const LOCAL_HOST: &str = "127.0.0.1";

/// Museum accepts [`HARDCODED_OTT`] as the email verification code for any
/// address ending in [`HARDCODED_OTT_EMAIL_SUFFIX`], so tests can sign up and
/// log in without an email inbox.
pub const HARDCODED_OTT: &str = "123456";

/// See [`HARDCODED_OTT`].
pub const HARDCODED_OTT_EMAIL_SUFFIX: &str = "@example.org";

fn free_port() -> TestResult<u16> {
    Ok(std::net::TcpListener::bind((LOCAL_HOST, 0))?
        .local_addr()?
        .port())
}
