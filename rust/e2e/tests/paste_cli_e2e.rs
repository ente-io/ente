#[allow(dead_code)]
mod support;

use std::{
    path::{Path, PathBuf},
    process::{Command, Output},
};

use uuid::Uuid;

const STAGE_PASTE_CLI: &str = "paste_cli_e2e";

#[tokio::test]
#[ignore = "requires local Museum at ENTE_E2E_ENDPOINT and ENTE_E2E_CLI_BIN"]
async fn paste_cli_e2e() {
    let endpoint = support::endpoint();
    if !support::assert_stage_enabled_or_skip(STAGE_PASTE_CLI) {
        return;
    }
    let Some(cli_bin) = cli_bin_or_skip(STAGE_PASTE_CLI) else {
        return;
    };
    if !support::assert_server_or_skip(&endpoint, STAGE_PASTE_CLI).await {
        return;
    }

    let paste_origin = paste_origin();
    let config_dir = TempConfigDir::new();
    let text = format!("hello from paste cli e2e {}", Uuid::new_v4());

    let link = run_cli_success(
        &cli_bin,
        config_dir.path(),
        &[
            "paste",
            "create",
            "--endpoint",
            &endpoint,
            "--paste-origin",
            &paste_origin,
            &text,
        ],
    );
    let link = link.trim();

    assert!(
        link.starts_with(&format!("{}/", paste_origin.trim_end_matches('/'))),
        "paste link used unexpected origin: {link}",
    );
    assert!(
        link.contains('#'),
        "paste link should carry its decryption key in the URL fragment: {link}",
    );

    let consumed = run_cli_success(
        &cli_bin,
        config_dir.path(),
        &["paste", "consume", "--endpoint", &endpoint, link],
    );
    assert_eq!(consumed, text);

    let second_consume = run_cli(
        &cli_bin,
        config_dir.path(),
        &["paste", "consume", "--endpoint", &endpoint, link],
    );
    assert!(
        !second_consume.status.success(),
        "second consume unexpectedly succeeded with stdout: {}",
        String::from_utf8_lossy(&second_consume.stdout),
    );
    assert!(
        String::from_utf8_lossy(&second_consume.stderr).contains("API error (410)"),
        "second consume should fail with 410, got stderr: {}",
        String::from_utf8_lossy(&second_consume.stderr),
    );
}

fn cli_bin_or_skip(test_name: &str) -> Option<PathBuf> {
    let path = match std::env::var_os("ENTE_E2E_CLI_BIN") {
        Some(path) => PathBuf::from(path),
        None => {
            eprintln!("skipping {test_name}: ENTE_E2E_CLI_BIN is not set");
            return None;
        }
    };
    if path.is_file() {
        Some(path)
    } else {
        eprintln!(
            "skipping {test_name}: ENTE_E2E_CLI_BIN does not point to a file: {}",
            path.display()
        );
        None
    }
}

fn paste_origin() -> String {
    std::env::var("ENTE_E2E_PASTE_ORIGIN").unwrap_or_else(|_| "http://localhost:3008".to_string())
}

fn run_cli_success(cli_bin: &Path, config_dir: &Path, args: &[&str]) -> String {
    let output = run_cli(cli_bin, config_dir, args);
    assert!(
        output.status.success(),
        "ente-rs {} failed\nstatus: {}\nstdout:\n{}\nstderr:\n{}",
        args.join(" "),
        output.status,
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr),
    );
    String::from_utf8(output.stdout).expect("ente-rs stdout should be UTF-8")
}

fn run_cli(cli_bin: &Path, config_dir: &Path, args: &[&str]) -> Output {
    Command::new(cli_bin)
        .args(args)
        .env("ENTE_CLI_CONFIG_DIR", config_dir)
        .env("NO_PROXY", "127.0.0.1,localhost")
        .env("no_proxy", "127.0.0.1,localhost")
        .output()
        .expect("failed to spawn ente-rs")
}

struct TempConfigDir {
    path: PathBuf,
}

impl TempConfigDir {
    fn new() -> Self {
        let path = std::env::temp_dir().join(format!("ente-rs-paste-cli-e2e-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&path).expect("failed to create temporary CLI config directory");
        Self { path }
    }

    fn path(&self) -> &Path {
        &self.path
    }
}

impl Drop for TempConfigDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.path);
    }
}
