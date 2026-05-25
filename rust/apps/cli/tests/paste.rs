mod support;

use std::process::Output;

use reqwest::Url;
use support::{Cli, Fixture, TestResult};
use uuid::Uuid;

#[test]
fn paste() -> TestResult {
    let fixture = Fixture::start()?;

    full_link_roundtrip(&fixture)?;
    token_and_key_roundtrip(&fixture)?;
    stdin_roundtrip(&fixture)?;

    Ok(())
}

fn full_link_roundtrip(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli("full-link")?;
    let text = unique_text("full-link");
    let link = create_paste(&cli, fixture, &text)?;

    let consumed = cli_success(cli.run(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        &link.raw,
    ])?);
    assert_eq!(consumed, text);

    let second_consume = cli.run(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        &link.raw,
    ])?;
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

    Ok(())
}

fn token_and_key_roundtrip(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli("token-key")?;
    let text = unique_text("token-key");
    let link = create_paste(&cli, fixture, &text)?;

    let consumed = cli_success(cli.run(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        "--key",
        &link.key,
        &link.token,
    ])?);
    assert_eq!(consumed, text);

    Ok(())
}

fn stdin_roundtrip(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli("stdin")?;
    let text = format!(
        "paste stdin scenario {}\n\nsecond line stays intact\n",
        Uuid::new_v4()
    );
    let link = cli_success(cli.run_with_stdin(
        &[
            "paste",
            "create",
            "--endpoint",
            fixture.endpoint(),
            "--paste-origin",
            fixture.paste_origin(),
        ],
        &text,
    )?);
    let link = PasteLink::parse(link.trim(), fixture.paste_origin());

    let consumed = cli_success(cli.run(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        &link.raw,
    ])?);
    assert_eq!(consumed, text);

    Ok(())
}

fn create_paste(cli: &Cli, fixture: &Fixture, text: &str) -> TestResult<PasteLink> {
    let link = cli_success(cli.run(&[
        "paste",
        "create",
        "--endpoint",
        fixture.endpoint(),
        "--paste-origin",
        fixture.paste_origin(),
        text,
    ])?);
    Ok(PasteLink::parse(link.trim(), fixture.paste_origin()))
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
        let url = Url::parse(raw).unwrap_or_else(|error| {
            panic!("invalid paste link {raw}: {error}");
        });
        let actual_origin = url.origin().ascii_serialization();
        let expected_origin = Url::parse(expected_origin)
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

fn cli_success(output: Output) -> String {
    assert!(
        output.status.success(),
        "ente-rs failed\nstatus: {}\nstdout:\n{}\nstderr:\n{}",
        output.status,
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr),
    );
    String::from_utf8(output.stdout).expect("ente-rs stdout should be UTF-8")
}
