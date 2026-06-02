mod support;

use reqwest::Url;
use support::{Cli, Fixture, TestResult};
use uuid::Uuid;

const PASTE_PASSWORD_ENV: &str = "ENTE_PASTE_PASSWORD";

#[test]
fn paste() -> TestResult {
    Fixture::run(|fixture| {
        full_link_roundtrip(fixture)?;
        token_and_key_roundtrip(fixture)?;
        stdin_roundtrip(fixture)?;
        password_protected_roundtrip(fixture)?;
        wrong_password_consumes_password_protected_paste(fixture)?;
        consumed_password_paste_checks_availability_before_password(fixture)
    })
}

fn full_link_roundtrip(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli_session("full-link")?;
    let text = unique_text("full-link");
    let link = create_paste(&cli, fixture, &text)?;

    let consumed = cli.run_ok(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        &link.raw,
    ])?;
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
    let cli = fixture.cli_session("token-key")?;
    let text = unique_text("token-key");
    let link = create_paste(&cli, fixture, &text)?;

    let consumed = cli.run_ok(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        "--key",
        &link.key,
        &link.token,
    ])?;
    assert_eq!(consumed, text);

    Ok(())
}

fn stdin_roundtrip(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli_session("stdin")?;
    let text = format!(
        "paste stdin scenario {}\n\nsecond line stays intact\n",
        Uuid::new_v4()
    );
    let link = cli.run_ok_with_stdin(
        &[
            "paste",
            "create",
            "--endpoint",
            fixture.endpoint(),
            "--paste-origin",
            fixture.paste_origin(),
        ],
        &text,
    )?;
    let link = PasteLink::parse(link.trim(), fixture.paste_origin());

    let consumed = cli.run_ok(&[
        "paste",
        "consume",
        "--endpoint",
        fixture.endpoint(),
        &link.raw,
    ])?;
    assert_eq!(consumed, text);

    Ok(())
}

fn password_protected_roundtrip(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli_session("password-protected")?;
    let text = unique_text("password-protected");
    let password = format!("password {}", Uuid::new_v4());
    let link = create_password_paste(&cli, fixture, &text, &password)?;
    let env = [(PASTE_PASSWORD_ENV, password.as_str())];
    assert!(link.password_required);

    let consumed = cli.run_ok_with_env(
        &[
            "paste",
            "consume",
            "--endpoint",
            fixture.endpoint(),
            &link.raw,
        ],
        &env,
    )?;
    assert_eq!(consumed, text);

    Ok(())
}

fn wrong_password_consumes_password_protected_paste(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli_session("wrong-password")?;
    let text = unique_text("wrong-password");
    let password = format!("password {}", Uuid::new_v4());
    let link = create_password_paste(&cli, fixture, &text, &password)?;

    let wrong_env = [(PASTE_PASSWORD_ENV, "wrong password")];
    let wrong = cli.run_with_env(
        &[
            "paste",
            "consume",
            "--endpoint",
            fixture.endpoint(),
            &link.raw,
        ],
        &wrong_env,
    )?;
    assert!(
        !wrong.status.success(),
        "wrong password unexpectedly succeeded"
    );
    assert!(
        String::from_utf8_lossy(&wrong.stderr).contains("Incorrect paste password"),
        "wrong password should fail locally, got stderr: {}",
        String::from_utf8_lossy(&wrong.stderr),
    );

    let correct_env = [(PASTE_PASSWORD_ENV, password.as_str())];
    let second = cli.run_with_env(
        &[
            "paste",
            "consume",
            "--endpoint",
            fixture.endpoint(),
            &link.raw,
        ],
        &correct_env,
    )?;
    assert!(
        !second.status.success(),
        "second consume unexpectedly succeeded with stdout: {}",
        String::from_utf8_lossy(&second.stdout),
    );
    assert!(
        String::from_utf8_lossy(&second.stderr).contains("API error (410)"),
        "second consume should fail with 410, got stderr: {}",
        String::from_utf8_lossy(&second.stderr),
    );

    Ok(())
}

fn consumed_password_paste_checks_availability_before_password(fixture: &Fixture) -> TestResult {
    let cli = fixture.cli_session("consumed-password")?;
    let text = unique_text("consumed-password");
    let password = format!("password {}", Uuid::new_v4());
    let link = create_password_paste(&cli, fixture, &text, &password)?;
    let env = [(PASTE_PASSWORD_ENV, password.as_str())];

    let consumed = cli.run_ok_with_env(
        &[
            "paste",
            "consume",
            "--endpoint",
            fixture.endpoint(),
            &link.raw,
        ],
        &env,
    )?;
    assert_eq!(consumed, text);

    let invalid_env = [(PASTE_PASSWORD_ENV, "")];
    let second = cli.run_with_env(
        &[
            "paste",
            "consume",
            "--endpoint",
            fixture.endpoint(),
            &link.raw,
        ],
        &invalid_env,
    )?;
    assert!(
        !second.status.success(),
        "second consume unexpectedly succeeded"
    );
    assert!(
        String::from_utf8_lossy(&second.stderr).contains("API error (410)"),
        "consumed paste should fail before password validation, got stderr: {}",
        String::from_utf8_lossy(&second.stderr),
    );
    assert!(
        !String::from_utf8_lossy(&second.stderr).contains("Paste password cannot be empty"),
        "consumed paste validated password before guard: {}",
        String::from_utf8_lossy(&second.stderr),
    );

    Ok(())
}

fn create_paste(cli: &Cli, fixture: &Fixture, text: &str) -> TestResult<PasteLink> {
    let link = cli.run_ok(&[
        "paste",
        "create",
        "--endpoint",
        fixture.endpoint(),
        "--paste-origin",
        fixture.paste_origin(),
        text,
    ])?;
    Ok(PasteLink::parse(link.trim(), fixture.paste_origin()))
}

fn create_password_paste(
    cli: &Cli,
    fixture: &Fixture,
    text: &str,
    password: &str,
) -> TestResult<PasteLink> {
    let env = [(PASTE_PASSWORD_ENV, password)];
    let link = cli.run_ok_with_env(
        &[
            "paste",
            "create",
            "--endpoint",
            fixture.endpoint(),
            "--paste-origin",
            fixture.paste_origin(),
            "--password",
            text,
        ],
        &env,
    )?;
    Ok(PasteLink::parse(link.trim(), fixture.paste_origin()))
}

fn unique_text(scope: &str) -> String {
    format!("paste cli {scope} scenario {}", Uuid::new_v4())
}

struct PasteLink {
    raw: String,
    token: String,
    key: String,
    password_required: bool,
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
        let (password_required, fragment_secret) = match key.strip_prefix("p-") {
            Some(fragment_secret) => (true, fragment_secret),
            None => (false, key.as_str()),
        };

        assert_eq!(
            actual_origin, expected_origin,
            "paste link used unexpected origin: {raw}",
        );
        assert!(
            fragment_secret.len() == 12
                && fragment_secret
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric()),
            "paste link key has unexpected format: {key}",
        );
        assert!(!token.is_empty(), "paste link token is empty: {raw}");

        Self {
            raw: raw.to_string(),
            token,
            key,
            password_required,
        }
    }
}
