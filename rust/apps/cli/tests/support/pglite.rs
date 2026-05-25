use std::{
    fs,
    net::TcpStream,
    path::{Path, PathBuf},
    process::Command,
    time::{Duration, Instant},
};

use serde_json::Value;

use super::{LOCAL_HOST, TestResult, process::ChildProcess};

pub fn start(package_dir: &Path, log_dir: &Path, port: u16) -> TestResult<ChildProcess> {
    let bin = pglite_server_bin(package_dir)?;
    let mut command = Command::new(bin);
    command
        .arg("--db=memory://")
        .arg(format!("--host={LOCAL_HOST}"))
        .arg(format!("--port={port}"))
        .arg("--max-connections=20")
        .current_dir(package_dir);
    let mut pglite = ChildProcess::spawn("pglite", &mut command, log_dir)?;
    wait_for_pglite(&mut pglite, port)?;
    Ok(pglite)
}

fn pglite_server_bin(package_dir: &Path) -> TestResult<PathBuf> {
    let expected_version = package_version(package_dir.join("package.json"))?;
    let installed_package = package_dir
        .join("node_modules")
        .join("@electric-sql")
        .join("pglite-socket")
        .join("package.json");
    let installed_version = package_version(installed_package).map_err(|_| install_error())?;
    if installed_version != expected_version {
        return Err(install_error());
    }

    let bin = package_dir
        .join("node_modules")
        .join(".bin")
        .join("pglite-server");
    if bin.is_file() {
        Ok(bin)
    } else {
        Err(install_error())
    }
}

fn package_version(path: impl AsRef<Path>) -> TestResult<String> {
    let package_json: Value = serde_json::from_str(&fs::read_to_string(path)?)?;
    package_json
        .get("version")
        .or_else(|| {
            package_json
                .get("devDependencies")
                .and_then(|deps| deps.get("@electric-sql/pglite-socket"))
        })
        .and_then(Value::as_str)
        .map(|version| version.trim_start_matches('=').to_string())
        .ok_or_else(|| "missing @electric-sql/pglite-socket version".into())
}

fn install_error() -> Box<dyn std::error::Error> {
    "PGlite is not installed. Run `npm ci --prefix rust/apps/cli/tests/pglite` from the repository root.".into()
}

fn wait_for_pglite(process: &mut ChildProcess, port: u16) -> TestResult {
    let deadline = Instant::now() + Duration::from_secs(30);
    loop {
        process.ensure_running()?;
        if TcpStream::connect((LOCAL_HOST, port)).is_ok() {
            return Ok(());
        }
        if Instant::now() >= deadline {
            return Err(format!("PGlite did not start on {LOCAL_HOST}:{port}").into());
        }
        std::thread::sleep(Duration::from_millis(200));
    }
}
