use std::{
    fs,
    net::TcpListener,
    path::{Path, PathBuf},
};

use uuid::Uuid;

use super::{Cli, LOCAL_HOST, TestResult, museum, pglite, process::ChildProcess};

pub struct Fixture {
    temp_dir: TempDir,
    endpoint: String,
    paste_origin: String,
    _pglite: ChildProcess,
    _museum: ChildProcess,
}

impl Fixture {
    pub fn start() -> TestResult<Self> {
        let paths = Paths::discover()?;
        let temp_dir = TempDir::new("ente-cli-paste")?;
        let log_dir = temp_dir.path().join("logs");
        let pglite_port = free_port()?;
        let museum_port = free_port()?;
        let paste_port = free_port()?;
        let paste_origin = format!("http://{LOCAL_HOST}:{paste_port}");
        let endpoint = format!("http://{LOCAL_HOST}:{museum_port}");
        let credentials_file = temp_dir.path().join("credentials.yaml");

        museum::write_credentials(&credentials_file, pglite_port)?;
        let pglite = pglite::start(&paths.pglite_dir, &log_dir, pglite_port)?;
        let museum = museum::start(
            &paths.server_dir,
            &log_dir,
            &credentials_file,
            museum_port,
            pglite_port,
            &paste_origin,
        )?;

        Ok(Self {
            temp_dir,
            endpoint,
            paste_origin,
            _pglite: pglite,
            _museum: museum,
        })
    }

    pub fn endpoint(&self) -> &str {
        &self.endpoint
    }

    pub fn paste_origin(&self) -> &str {
        &self.paste_origin
    }

    pub fn cli(&self, name: &str) -> TestResult<Cli> {
        let config_dir = self.temp_dir.path().join("cli").join(name);
        fs::create_dir_all(&config_dir)?;
        Ok(Cli::new(config_dir))
    }
}

struct Paths {
    server_dir: PathBuf,
    pglite_dir: PathBuf,
}

impl Paths {
    fn discover() -> TestResult<Self> {
        let cli_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let rust_dir = cli_dir
            .parent()
            .and_then(Path::parent)
            .ok_or("failed to resolve rust directory")?;
        let repo_dir = rust_dir
            .parent()
            .ok_or("failed to resolve repository directory")?;

        Ok(Self {
            server_dir: repo_dir.join("server"),
            pglite_dir: cli_dir.join("tests").join("pglite"),
        })
    }
}

struct TempDir {
    path: PathBuf,
}

impl TempDir {
    fn new(prefix: &str) -> TestResult<Self> {
        let path = std::env::temp_dir().join(format!("{prefix}-{}", Uuid::new_v4()));
        fs::create_dir_all(&path)?;
        Ok(Self { path })
    }

    fn path(&self) -> &Path {
        &self.path
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.path);
    }
}

fn free_port() -> TestResult<u16> {
    Ok(TcpListener::bind((LOCAL_HOST, 0))?.local_addr()?.port())
}
