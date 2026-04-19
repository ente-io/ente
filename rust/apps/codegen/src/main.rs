use std::env;
use std::error::Error;
use std::ffi::OsStr;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use camino::Utf8PathBuf;
use uniffi_bindgen::bindings::{self, GenerateOptions, TargetLanguage};

type DynError = Box<dyn Error>;

struct UniffiCrate<'a> {
    crate_name: &'a str,
    crate_dir: PathBuf,
    dylib_name: &'a str,
}

fn main() {
    if let Err(error) = run() {
        eprintln!("{error}");
        std::process::exit(1);
    }
}

fn run() -> Result<(), DynError> {
    let mut args = env::args().skip(1);
    match (args.next().as_deref(), args.next()) {
        (Some("ensu-ios"), None) => generate_ensu_ios(),
        _ => Err("usage: cargo codegen ensu-ios".into()),
    }
}

fn generate_ensu_ios() -> Result<(), DynError> {
    let rust_root = rust_root()?;
    let repo_root = rust_root
        .parent()
        .ok_or("failed to resolve repo root from rust/apps/codegen")?;
    let generated_dir = repo_root.join("mobile/native/darwin/Apps/Ensu/Ensu/Generated");

    fs::create_dir_all(&generated_dir)?;

    let crates = [
        UniffiCrate {
            crate_name: "core",
            crate_dir: rust_root.join("uniffi/core"),
            dylib_name: "libcore.dylib",
        },
        UniffiCrate {
            crate_name: "db",
            crate_dir: rust_root.join("uniffi/ensu/db"),
            dylib_name: "libdb.dylib",
        },
        UniffiCrate {
            crate_name: "sync",
            crate_dir: rust_root.join("uniffi/ensu/sync"),
            dylib_name: "libsync.dylib",
        },
        UniffiCrate {
            crate_name: "inference",
            crate_dir: rust_root.join("uniffi/ensu/inference"),
            dylib_name: "libinference.dylib",
        },
    ];

    for uniffi_crate in crates {
        build_host_dylib(&uniffi_crate.crate_dir)?;
        remove_generated_bindings(&generated_dir, uniffi_crate.crate_name)?;
        generate_swift_bindings(&generated_dir, &uniffi_crate)?;
    }

    sanitize_generated_swift_bindings(&generated_dir.join("db.swift"), "db")?;
    sanitize_generated_swift_bindings(&generated_dir.join("sync.swift"), "sync")?;

    Ok(())
}

fn rust_root() -> Result<PathBuf, DynError> {
    let manifest_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    manifest_dir
        .parent()
        .and_then(Path::parent)
        .map(Path::to_path_buf)
        .ok_or_else(|| "failed to resolve rust workspace root".into())
}

fn build_host_dylib(crate_dir: &Path) -> Result<(), DynError> {
    run_command(
        Command::new("cargo")
            .arg("build")
            .arg("--locked")
            .arg("--release")
            .current_dir(crate_dir),
        format!("failed to build {}", crate_dir.display()),
    )
}

fn remove_generated_bindings(generated_dir: &Path, crate_name: &str) -> Result<(), DynError> {
    for suffix in [".swift", "FFI.h", "FFI.modulemap"] {
        let path = generated_dir.join(format!("{crate_name}{suffix}"));
        match fs::remove_file(&path) {
            Ok(()) => {}
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => {
                return Err(format!("failed to remove {}: {error}", path.display()).into());
            }
        }
    }

    Ok(())
}

fn generate_swift_bindings(
    generated_dir: &Path,
    uniffi_crate: &UniffiCrate<'_>,
) -> Result<(), DynError> {
    let source = uniffi_crate
        .crate_dir
        .join("target/release")
        .join(uniffi_crate.dylib_name);
    let source = utf8_path(&source)?;
    let out_dir = utf8_path(generated_dir)?;
    let previous_dir = env::current_dir().map_err(|error| {
        format!(
            "failed to capture current directory before generating {} bindings: {error}",
            uniffi_crate.crate_name
        )
    })?;

    env::set_current_dir(&uniffi_crate.crate_dir).map_err(|error| {
        format!(
            "failed to enter {} before generating bindings: {error}",
            uniffi_crate.crate_dir.display()
        )
    })?;

    let result = bindings::generate(GenerateOptions {
        languages: vec![TargetLanguage::Swift],
        source,
        out_dir,
        config_override: None,
        format: false,
        crate_filter: Some(uniffi_crate.crate_name.to_owned()),
        metadata_no_deps: false,
    });

    env::set_current_dir(&previous_dir).map_err(|error| {
        format!(
            "failed to restore current directory to {}: {error}",
            previous_dir.display()
        )
    })?;

    result?;

    Ok(())
}

fn sanitize_generated_swift_bindings(swift_file: &Path, crate_name: &str) -> Result<(), DynError> {
    let original = fs::read_to_string(swift_file)
        .map_err(|error| format!("failed to read {}: {error}", swift_file.display()))?;
    let free_call_prefix = format!("try! rustCall {{ uniffi_{crate_name}_fn_free_");

    let mut rewritten = String::with_capacity(original.len());
    let mut replaced = false;

    for segment in original.split_inclusive('\n') {
        let line = segment.strip_suffix('\n').unwrap_or(segment);
        let trimmed = line.trim_start();

        if trimmed.starts_with(&free_call_prefix) && trimmed.ends_with("(handle, $0) }") {
            let indent = &line[..line.len() - trimmed.len()];
            rewritten.push_str(indent);
            rewritten.push_str("// Avoid aborting the host app if Rust-side teardown fails during process shutdown.\n");
            rewritten.push_str(indent);
            rewritten.push_str(&line.replacen("try!", "try?", 1));
            if segment.ends_with('\n') {
                rewritten.push('\n');
            }
            replaced = true;
        } else {
            rewritten.push_str(segment);
        }
    }

    if replaced {
        fs::write(swift_file, rewritten)
            .map_err(|error| format!("failed to write {}: {error}", swift_file.display()))?;
    }

    Ok(())
}

fn utf8_path(path: &Path) -> Result<Utf8PathBuf, DynError> {
    Utf8PathBuf::from_path_buf(path.to_path_buf())
        .map_err(|path| format!("path is not valid UTF-8: {}", path.display()).into())
}

fn run_command(command: &mut Command, error_context: String) -> Result<(), DynError> {
    let program = command.get_program().to_os_string();
    let args = command
        .get_args()
        .map(OsStr::to_os_string)
        .collect::<Vec<_>>();
    let status = command.status().map_err(|error| {
        format!(
            "{error_context}: failed to start {}: {error}",
            render_command(&program, &args)
        )
    })?;

    if status.success() {
        return Ok(());
    }

    Err(format!(
        "{error_context}: {} exited with status {status}",
        render_command(&program, &args)
    )
    .into())
}

fn render_command(program: &OsStr, args: &[std::ffi::OsString]) -> String {
    let mut parts = Vec::with_capacity(args.len() + 1);
    parts.push(program.to_string_lossy().into_owned());
    parts.extend(args.iter().map(|arg| arg.to_string_lossy().into_owned()));
    parts.join(" ")
}
