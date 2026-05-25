use std::{
    io::Write,
    path::{Path, PathBuf},
    process::{Command, Output, Stdio},
};

use super::TestResult;

pub struct Cli {
    bin: PathBuf,
    config_dir: PathBuf,
}

impl Cli {
    pub fn new(config_dir: PathBuf) -> Self {
        Self {
            bin: PathBuf::from(env!("CARGO_BIN_EXE_ente-rs")),
            config_dir,
        }
    }

    pub fn run(&self, args: &[&str]) -> TestResult<Output> {
        Ok(command(&self.bin, &self.config_dir, args).output()?)
    }

    pub fn run_with_stdin(&self, args: &[&str], stdin: &str) -> TestResult<Output> {
        let mut child = command(&self.bin, &self.config_dir, args)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()?;

        child
            .stdin
            .take()
            .expect("ente-rs stdin should be piped")
            .write_all(stdin.as_bytes())?;

        Ok(child.wait_with_output()?)
    }
}

fn command(bin: &Path, config_dir: &Path, args: &[&str]) -> Command {
    let mut command = Command::new(bin);
    command
        .args(args)
        .env("ENTE_CLI_CONFIG_DIR", config_dir)
        .env("NO_PROXY", "127.0.0.1,localhost")
        .env("no_proxy", "127.0.0.1,localhost");
    command
}
