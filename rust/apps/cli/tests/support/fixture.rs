use std::{
    fs,
    net::TcpListener,
    path::{Path, PathBuf},
};

use uuid::Uuid;

use super::{Cli, LOCAL_HOST, TestResult, museum, pglite, process::ChildProcess};

pub struct Fixture {
    _museum: ChildProcess,
    _pglite: ChildProcess,
    temp_dir: TempDir,
    endpoint: String,
    paste_origin: String,
}

impl Fixture {
    pub fn run(test: impl FnOnce(&Self) -> TestResult) -> TestResult {
        let mut fixture = Self::start()?;
        let result = test(&fixture);
        if result.is_err() {
            fixture.retain_temp_dir();
        }
        result
    }

    pub fn start() -> TestResult<Self> {
        let paths = Paths::discover()?;
        let mut temp_dir = TempDir::new("ente-cli-test")?;
        let log_dir = temp_dir.path().join("logs");
        let pglite_port = free_port()?;
        let museum_port = free_port()?;
        let paste_origin = format!("http://{LOCAL_HOST}");
        let endpoint = format!("http://{LOCAL_HOST}:{museum_port}");
        let museum_config_file = temp_dir.path().join("museum.yaml");

        let result = (|| {
            museum::write_config(&museum_config_file, museum_port, pglite_port, &paste_origin)?;
            let pglite = pglite::start(&paths.pglite_dir, &log_dir, pglite_port)?;
            let museum = museum::start(
                &paths.server_dir,
                &log_dir,
                &museum_config_file,
                museum_port,
            )?;
            Ok((pglite, museum))
        })();

        let (pglite, museum) = match result {
            Ok(processes) => processes,
            Err(error) => {
                temp_dir.retain();
                return Err(error);
            }
        };

        Ok(Self {
            _museum: museum,
            _pglite: pglite,
            temp_dir,
            endpoint,
            paste_origin,
        })
    }

    pub fn endpoint(&self) -> &str {
        &self.endpoint
    }

    pub fn paste_origin(&self) -> &str {
        &self.paste_origin
    }

    pub fn cli_session(&self, scenario: &str) -> TestResult<Cli> {
        let config_dir = self.temp_dir.path().join("cli").join(scenario);
        fs::create_dir_all(&config_dir)?;
        Ok(Cli::new(config_dir))
    }

    pub fn retain_temp_dir(&mut self) {
        self.temp_dir.retain();
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
    retained: bool,
}

impl TempDir {
    fn new(prefix: &str) -> TestResult<Self> {
        let path = std::env::temp_dir().join(format!("{prefix}-{}", Uuid::new_v4()));
        fs::create_dir_all(&path)?;
        Ok(Self {
            path,
            retained: false,
        })
    }

    fn path(&self) -> &Path {
        &self.path
    }

    fn retain(&mut self) {
        eprintln!(
            "retaining CLI integration test temp dir: {}",
            self.path.display()
        );
        self.retained = true;
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        if !self.retained {
            let _ = fs::remove_dir_all(&self.path);
        }
    }
}

fn free_port() -> TestResult<u16> {
    Ok(TcpListener::bind((LOCAL_HOST, 0))?.local_addr()?.port())
}
