use std::{
    fs,
    io::{Read, Write},
    net::TcpStream,
    path::Path,
    process::Command,
    time::{Duration, Instant},
};

use crate::{
    HARDCODED_OTT, HARDCODED_OTT_EMAIL_SUFFIX, LOCAL_HOST, TestResult, postgres::Postgres,
    process::ChildProcess,
};

pub fn start(
    server_dir: &Path,
    log_dir: &Path,
    config_file: &Path,
    museum_port: u16,
    db: &Postgres,
) -> TestResult<ChildProcess> {
    require_go()?;

    let mut command = Command::new("go");
    command
        .arg("run")
        .arg("./cmd/museum")
        .current_dir(server_dir)
        .env("ENTE_CREDENTIALS_FILE", config_file)
        // Point museum at our Postgres through env vars, which outrank every
        // config file. A developer's `server/museum.yaml` is merged after our
        // credentials file and would otherwise redirect the db elsewhere.
        .env("ENTE_DB_HOST", db.host())
        .env("ENTE_DB_PORT", db.port().to_string())
        .env("ENTE_DB_NAME", db.database())
        .env("ENTE_DB_USER", db.username())
        .env("ENTE_DB_PASSWORD", db.password())
        .env("ENTE_DB_SSLMODE", "disable");

    let mut museum = ChildProcess::spawn("museum", &mut command, log_dir)?;
    wait_for_museum(&mut museum, museum_port)?;
    Ok(museum)
}

pub fn write_config(path: &Path, museum_port: u16, paste_origin: &str) -> TestResult {
    fs::write(
        path,
        format!(
            r#"http:
    port: {museum_port}

apps:
    public-paste: "{paste_origin}"

s3:
    are_local_buckets: true
    b2-eu-cen:
        key: changeme
        secret: changeme1234
        endpoint: localhost:3200
        region: eu-central-2
        bucket: b2-eu-cen

internal:
    hardcoded-ott:
        local-domain-suffix: "{HARDCODED_OTT_EMAIL_SUFFIX}"
        local-domain-value: {HARDCODED_OTT}

jobs:
    cron:
        skip: true
"#
        ),
    )?;
    Ok(())
}

fn require_go() -> TestResult {
    match Command::new("go").arg("version").output() {
        Ok(output) if output.status.success() => Ok(()),
        _ => Err("Museum live tests require `go` on PATH".into()),
    }
}

fn wait_for_museum(process: &mut ChildProcess, port: u16) -> TestResult {
    let deadline = Instant::now() + Duration::from_secs(90);
    loop {
        process.ensure_running()?;
        if ping(port)? {
            return Ok(());
        }
        if Instant::now() >= deadline {
            return Err(format!(
                "Museum did not become ready at http://{LOCAL_HOST}:{port}/ping\n{}",
                process.log_summary()
            )
            .into());
        }
        std::thread::sleep(Duration::from_millis(500));
    }
}

fn ping(port: u16) -> TestResult<bool> {
    let mut stream = match TcpStream::connect((LOCAL_HOST, port)) {
        Ok(stream) => stream,
        Err(_) => return Ok(false),
    };
    stream.set_read_timeout(Some(Duration::from_secs(2)))?;
    stream.write_all(b"GET /ping HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n")?;

    let mut response = String::new();
    stream.read_to_string(&mut response)?;
    Ok(response.starts_with("HTTP/1.1 200") || response.starts_with("HTTP/1.0 200"))
}
