#[allow(dead_code)]
mod support;

use std::{
    io::Write,
    path::{Path, PathBuf},
    process::{Command, Output, Stdio},
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

    full_link_roundtrip(&cli_bin, config_dir.path(), &endpoint, &paste_origin);
    token_and_key_roundtrip(&cli_bin, config_dir.path(), &endpoint, &paste_origin);
    stdin_roundtrip(&cli_bin, config_dir.path(), &endpoint, &paste_origin);
}

fn full_link_roundtrip(cli_bin: &Path, config_dir: &Path, endpoint: &str, paste_origin: &str) {
    let text = unique_text("full-link");
    let link = create_paste(cli_bin, config_dir, endpoint, paste_origin, &text);

    let consumed = run_cli_success(
        cli_bin,
        config_dir,
        &["paste", "consume", "--endpoint", endpoint, &link.raw],
    );
    assert_eq!(consumed, text);

    let second_consume = run_cli(
        cli_bin,
        config_dir,
        &["paste", "consume", "--endpoint", endpoint, &link.raw],
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

fn token_and_key_roundtrip(cli_bin: &Path, config_dir: &Path, endpoint: &str, paste_origin: &str) {
    let text = unique_text("token-key");
    let link = create_paste(cli_bin, config_dir, endpoint, paste_origin, &text);

    let consumed = run_cli_success(
        cli_bin,
        config_dir,
        &[
            "paste",
            "consume",
            "--endpoint",
            endpoint,
            "--key",
            &link.key,
            &link.token,
        ],
    );
    assert_eq!(consumed, text);
}

fn stdin_roundtrip(cli_bin: &Path, config_dir: &Path, endpoint: &str, paste_origin: &str) {
    let text = format!(
        "paste stdin scenario {}\n\nsecond line stays intact\n",
        Uuid::new_v4()
    );
    let link = run_cli_with_stdin_success(
        cli_bin,
        config_dir,
        &[
            "paste",
            "create",
            "--endpoint",
            endpoint,
            "--paste-origin",
            paste_origin,
        ],
        &text,
    );
    let link = PasteLink::parse(link.trim(), paste_origin);

    let consumed = run_cli_success(
        cli_bin,
        config_dir,
        &["paste", "consume", "--endpoint", endpoint, &link.raw],
    );
    assert_eq!(consumed, text);
}

fn create_paste(
    cli_bin: &Path,
    config_dir: &Path,
    endpoint: &str,
    paste_origin: &str,
    text: &str,
) -> PasteLink {
    let link = run_cli_success(
        cli_bin,
        config_dir,
        &[
            "paste",
            "create",
            "--endpoint",
            endpoint,
            "--paste-origin",
            paste_origin,
            text,
        ],
    );
    PasteLink::parse(link.trim(), paste_origin)
}

fn unique_text(scope: &str) -> String {
    format!("paste cli {scope} scenario {}", Uuid::new_v4())
}

struct PasteLink {
    raw: String,
    token: String,
    key: String,
}

impl PasteLink {
    fn parse(raw: &str, expected_origin: &str) -> Self {
        let url = reqwest::Url::parse(raw).unwrap_or_else(|error| {
            panic!("invalid paste link {raw}: {error}");
        });
        let actual_origin = url.origin().ascii_serialization();
        let expected_origin = reqwest::Url::parse(expected_origin)
            .expect("expected paste origin should be a URL")
            .origin()
            .ascii_serialization();
        let token = url
            .path_segments()
            .and_then(|mut segments| segments.rfind(|segment| !segment.is_empty()))
            .expect("paste link should include an access token")
            .to_string();
        let key = url
            .fragment()
            .expect("paste link should include a decryption key fragment")
            .to_string();

        assert_eq!(
            actual_origin, expected_origin,
            "paste link used unexpected origin: {raw}",
        );
        assert!(
            key.len() == 12 && key.bytes().all(|byte| byte.is_ascii_alphanumeric()),
            "paste link key has unexpected format: {key}",
        );
        assert!(!token.is_empty(), "paste link token is empty: {raw}");

        Self {
            raw: raw.to_string(),
            token,
            key,
        }
    }
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

fn run_cli_with_stdin_success(
    cli_bin: &Path,
    config_dir: &Path,
    args: &[&str],
    stdin: &str,
) -> String {
    let output = run_cli_with_stdin(cli_bin, config_dir, args, stdin);
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

fn run_cli_with_stdin(cli_bin: &Path, config_dir: &Path, args: &[&str], stdin: &str) -> Output {
    let mut child = Command::new(cli_bin)
        .args(args)
        .env("ENTE_CLI_CONFIG_DIR", config_dir)
        .env("NO_PROXY", "127.0.0.1,localhost")
        .env("no_proxy", "127.0.0.1,localhost")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("failed to spawn ente-rs");

    child
        .stdin
        .take()
        .expect("ente-rs stdin should be piped")
        .write_all(stdin.as_bytes())
        .expect("failed to write ente-rs stdin");
    child
        .wait_with_output()
        .expect("failed to wait for ente-rs")
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
