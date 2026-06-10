mod cli;
mod fixture;
mod museum;
mod pglite;
mod process;

pub use cli::Cli;
pub use fixture::Fixture;

pub type TestResult<T = ()> = Result<T, Box<dyn std::error::Error>>;

const LOCAL_HOST: &str = "127.0.0.1";
