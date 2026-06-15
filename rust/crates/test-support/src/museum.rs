use std::{
    fs,
    net::TcpListener,
    path::{Path, PathBuf},
};

use uuid::Uuid;

use crate::{LOCAL_HOST, TestResult, postgres, process::ChildProcess, server};

pub struct Museum {
    _museum: ChildProcess,
    _postgres: postgres::Postgres,
    temp_dir: TempDir,
    endpoint: String,
    paste_origin: String,
}

impl Museum {
    pub fn run(test: impl FnOnce(&Self) -> TestResult) -> TestResult {
        let mut museum = Self::start()?;
        let result = test(&museum);
        if result.is_err() {
            museum.retain_temp_dir();
        }
        result
    }

    pub fn start() -> TestResult<Self> {
        let paths = Paths::discover()?;
        let mut temp_dir = TempDir::new("ente-test")?;
        let log_dir = temp_dir.path().join("logs");
        let museum_port = free_port()?;
        let paste_origin = format!("http://{LOCAL_HOST}");
        let endpoint = format!("http://{LOCAL_HOST}:{museum_port}");
        let museum_config_file = temp_dir.path().join("museum.yaml");

        let result = (|| {
            server::write_config(&museum_config_file, museum_port, &paste_origin)?;
            let postgres = postgres::start()?;
            let museum = server::start(
                &paths.server_dir,
                &log_dir,
                &museum_config_file,
                museum_port,
                &postgres,
            )?;
            Ok((postgres, museum))
        })();

        let (postgres, museum) = match result {
            Ok(processes) => processes,
            Err(error) => {
                temp_dir.retain();
                return Err(error);
            }
        };

        Ok(Self {
            _museum: museum,
            _postgres: postgres,
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

    pub fn temp_dir(&self) -> &Path {
        self.temp_dir.path()
    }

    pub fn retain_temp_dir(&mut self) {
        self.temp_dir.retain();
    }
}

struct Paths {
    server_dir: PathBuf,
}

impl Paths {
    fn discover() -> TestResult<Self> {
        let crate_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let repo_dir = crate_dir
            .parent()
            .and_then(Path::parent)
            .and_then(Path::parent)
            .ok_or("failed to resolve repository directory")?;

        Ok(Self {
            server_dir: repo_dir.join("server"),
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
            "retaining integration test temp dir: {}",
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
