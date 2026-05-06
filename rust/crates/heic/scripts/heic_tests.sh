#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="${HEIC_TEST_ROOT:-$ROOT_DIR/.heic-test-runs}"
ASSET_ROOT="${HEIC_TEST_ASSET_ROOT:-$ROOT_DIR/.heic-test-assets}"
HELPER_DIR="${HEIC_TEST_HELPER_DIR:-$TEST_ROOT/helper}"
HELPER_BIN_DIR="$HELPER_DIR/target/release"

LIBHEIF_SOURCE_EXPLICIT="${HEIC_LIBHEIF_SOURCE_DIR+x}"
LIBHEIF_DEC_BIN_EXPLICIT="${LIBHEIF_DEC_BIN+x}"
LIBHEIF_SOURCE_DIR="${HEIC_LIBHEIF_SOURCE_DIR:-$ASSET_ROOT/libheif}"
LIBHEIF_BUILD_DIR="${LIBHEIF_BUILD_DIR:-$TEST_ROOT/validator-build}"
LIBHEIF_DEC_BIN="${LIBHEIF_DEC_BIN:-$LIBHEIF_BUILD_DIR/examples/heif-dec}"
LIBHEIF_RECONFIGURE="${LIBHEIF_RECONFIGURE:-0}"
LIBHEIF_REQUIRE_ORACLE_DECODERS="${LIBHEIF_REQUIRE_ORACLE_DECODERS:-1}"
LIBHEIF_PATHS_RESOLVED=0

usage() {
  cat <<'EOF'
Usage: scripts/heic_tests.sh <command> [options]

Commands:
  verify           Compare ente_heic PNG output against an external validator
  bench-decode     Benchmark ente_heic decode CLI against the validator
  bench-ingestion  Benchmark bytes vs path ingestion
  bench-image      Benchmark image adapter vs direct decode
  bench-stream     Benchmark path/read decode under concurrency
  all              Run full verify plus the standard benchmark set
  build-helper     Generate and build the local helper binaries only

Common environment:
  HEIC_LIBHEIF_SOURCE_DIR  external validator checkout with examples/tests/fuzz corpus
                           default: .heic-test-assets/libheif
  HEIC_TEST_ROOT           generated outputs/cache root
                           default: .heic-test-runs
  LIBHEIF_BUILD_DIR        validator CMake build dir
                           default: $HEIC_TEST_ROOT/validator-build
  LIBHEIF_DEC_BIN          existing heif-dec binary to reuse
  LIBHEIF_RECONFIGURE      set to 1 to force validator CMake reconfigure
  LIBHEIF_CMAKE_ARGS       extra CMake args appended to the validator build

If .heic-test-assets itself is a libheif checkout, the script accepts that too.

Use --help after a command for command-specific options.
EOF
}

log() {
  echo "[$1] ${*:2}"
}

fail() {
  echo "[heic-tests] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || fail "Missing command: $cmd"
}

is_libheif_source_dir() {
  local dir="$1"
  [[ -f "$dir/CMakeLists.txt" && -d "$dir/examples" && -d "$dir/tests/data" && -d "$dir/fuzzing/data/corpus" ]]
}

first_existing_libheif_source_dir() {
  local candidate
  for candidate in \
    "$LIBHEIF_SOURCE_DIR" \
    "$ASSET_ROOT/libheif" \
    "$ASSET_ROOT"
  do
    if is_libheif_source_dir "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

first_existing_heif_dec_bin() {
  local candidate
  for candidate in \
    "$LIBHEIF_DEC_BIN" \
    "$LIBHEIF_BUILD_DIR/examples/heif-dec" \
    "$ASSET_ROOT/libheif-build/examples/heif-dec"
  do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_libheif_paths() {
  [[ "$LIBHEIF_PATHS_RESOLVED" -eq 1 ]] && return

  local detected_source
  if [[ -z "$LIBHEIF_SOURCE_EXPLICIT" ]] && ! is_libheif_source_dir "$LIBHEIF_SOURCE_DIR"; then
    if detected_source="$(first_existing_libheif_source_dir)"; then
      LIBHEIF_SOURCE_DIR="$detected_source"
      log setup "Using validator source: $LIBHEIF_SOURCE_DIR"
    fi
  fi

  local detected_bin
  if [[ -z "$LIBHEIF_DEC_BIN_EXPLICIT" ]] && [[ ! -x "$LIBHEIF_DEC_BIN" ]]; then
    if detected_bin="$(first_existing_heif_dec_bin)"; then
      LIBHEIF_DEC_BIN="$detected_bin"
      log setup "Using validator binary: $LIBHEIF_DEC_BIN"
    fi
  fi

  LIBHEIF_PATHS_RESOLVED=1
}

toml_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

ensure_helper_sources() {
  local root_toml
  root_toml="$(toml_escape "$ROOT_DIR")"
  mkdir -p "$HELPER_DIR/src/bin"

  cat > "$HELPER_DIR/Cargo.toml" <<EOF
[workspace]

[package]
name = "ente_heic_test_helper"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
ente_heic = { path = "$root_toml", features = ["image-integration"] }
image = { version = "0.25", default-features = false, features = ["png"] }
EOF

  cat > "$HELPER_DIR/src/bin/heif-decode.rs" <<'RS'
use ente_heic::DecodeGuardrails;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum OrientationMode {
    Auto,
    Preserve,
}

fn usage(program: &str) {
    eprintln!(
        "Usage: {program} [--orientation <auto|preserve>] [--max-input-bytes <bytes>] [--max-pixels <pixels>] [--max-temp-spool-bytes <bytes>] [--temp-spool-directory <path>] <input.heif|.heic|.avif> <output.png>"
    );
}

fn parse_u64(flag: &str, value: String) -> Result<u64, String> {
    value
        .parse::<u64>()
        .map_err(|_| format!("{flag} expects a u64 value, got '{value}'"))
}

fn main() -> ExitCode {
    let mut args = std::env::args();
    let program = args.next().unwrap_or_else(|| "heif-decode".to_string());
    let mut positional = Vec::new();
    let mut guardrails = DecodeGuardrails::default();
    let mut orientation = OrientationMode::Auto;

    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--help" | "-h" => {
                usage(&program);
                return ExitCode::SUCCESS;
            }
            "--orientation" => {
                let Some(value) = args.next() else {
                    eprintln!("missing value for --orientation");
                    usage(&program);
                    return ExitCode::from(2);
                };
                orientation = match value.as_str() {
                    "auto" => OrientationMode::Auto,
                    "preserve" => OrientationMode::Preserve,
                    _ => {
                        eprintln!("--orientation expects auto or preserve, got '{value}'");
                        usage(&program);
                        return ExitCode::from(2);
                    }
                };
            }
            "--max-input-bytes" => {
                let Some(value) = args.next() else {
                    eprintln!("missing value for --max-input-bytes");
                    usage(&program);
                    return ExitCode::from(2);
                };
                guardrails.max_input_bytes = match parse_u64("--max-input-bytes", value) {
                    Ok(value) => Some(value),
                    Err(message) => {
                        eprintln!("{message}");
                        return ExitCode::from(2);
                    }
                };
            }
            "--max-pixels" => {
                let Some(value) = args.next() else {
                    eprintln!("missing value for --max-pixels");
                    usage(&program);
                    return ExitCode::from(2);
                };
                guardrails.max_pixels = match parse_u64("--max-pixels", value) {
                    Ok(value) => Some(value),
                    Err(message) => {
                        eprintln!("{message}");
                        return ExitCode::from(2);
                    }
                };
            }
            "--max-temp-spool-bytes" => {
                let Some(value) = args.next() else {
                    eprintln!("missing value for --max-temp-spool-bytes");
                    usage(&program);
                    return ExitCode::from(2);
                };
                guardrails.max_temp_spool_bytes =
                    match parse_u64("--max-temp-spool-bytes", value) {
                        Ok(value) => Some(value),
                        Err(message) => {
                            eprintln!("{message}");
                            return ExitCode::from(2);
                        }
                    };
            }
            "--temp-spool-directory" => {
                let Some(value) = args.next() else {
                    eprintln!("missing value for --temp-spool-directory");
                    usage(&program);
                    return ExitCode::from(2);
                };
                guardrails.temp_spool_directory = Some(PathBuf::from(value));
            }
            _ if arg.starts_with('-') => {
                eprintln!("unknown option '{arg}'");
                usage(&program);
                return ExitCode::from(2);
            }
            _ => positional.push(arg),
        }
    }

    if positional.len() != 2 {
        eprintln!("expected <input> and <output>");
        usage(&program);
        return ExitCode::from(2);
    }

    let input = Path::new(&positional[0]);
    let output = Path::new(&positional[1]);
    let mut decoded = match ente_heic::decode_path_to_rgba_with_guardrails(input, guardrails) {
        Ok(decoded) => decoded,
        Err(error) => {
            eprintln!(
                "Decode failed [category={}]: {error}",
                error.category().as_str()
            );
            return ExitCode::from(1);
        }
    };

    if orientation == OrientationMode::Auto && ente_heic::path_extension_is_heif(input) {
        if let Ok(hint) = ente_heic::exif_orientation_hint_from_path(input)
            && let Some(orientation) = hint.orientation_to_apply()
        {
            match decoded.apply_exif_orientation(orientation) {
                Ok(oriented) => decoded = oriented,
                Err(error) => {
                    eprintln!(
                        "Decode failed [category={}]: {error}",
                        error.category().as_str()
                    );
                    return ExitCode::from(1);
                }
            }
        }
    }

    match ente_heic::write_decoded_rgba_to_png(&decoded, output) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!(
                "Decode failed [category={}]: {error}",
                error.category().as_str()
            );
            ExitCode::from(1)
        }
    }
}
RS

  cat > "$HELPER_DIR/src/bin/heif-ingestion-bench.rs" <<'RS'
use ente_heic::{DecodedRgbaImage, DecodedRgbaPixels, decode_bytes_to_rgba, decode_path_to_rgba};
use std::error::Error;
use std::fs;
use std::path::Path;

fn checksum(samples: &[u8]) -> u64 {
    if samples.is_empty() {
        return 0;
    }
    ((samples[0] as u64) << 16)
        ^ ((samples[samples.len() / 2] as u64) << 8)
        ^ samples[samples.len() - 1] as u64
        ^ samples.len() as u64
}

fn checksum_u16(samples: &[u16]) -> u64 {
    if samples.is_empty() {
        return 0;
    }
    ((samples[0] as u64) << 32)
        ^ ((samples[samples.len() / 2] as u64) << 16)
        ^ samples[samples.len() - 1] as u64
        ^ samples.len() as u64
}

fn image_checksum(image: &DecodedRgbaImage) -> u64 {
    let pixels = match &image.pixels {
        DecodedRgbaPixels::U8(samples) => checksum(samples),
        DecodedRgbaPixels::U16(samples) => checksum_u16(samples),
    };
    ((image.width as u64) << 32) ^ image.height as u64 ^ pixels
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        return Err("Usage: heif-ingestion-bench <path|bytes> <input.heic|.heif|.avif>".into());
    }
    let input = Path::new(&args[2]);
    let decoded = match args[1].as_str() {
        "path" => decode_path_to_rgba(input)?,
        "bytes" => {
            let bytes = fs::read(input)?;
            decode_bytes_to_rgba(&bytes)?
        }
        other => return Err(format!("unsupported mode '{other}'").into()),
    };
    println!("{}", image_checksum(&decoded));
    Ok(())
}
RS

  cat > "$HELPER_DIR/src/bin/heif-image-adapter-bench.rs" <<'RS'
use ente_heic::image_integration::register_image_decoder_hooks;
use ente_heic::{DecodedRgbaImage, DecodedRgbaPixels, decode_path_to_rgba};
use image::{DynamicImage, ImageReader};
use std::error::Error;
use std::path::Path;

fn checksum(samples: &[u8]) -> u64 {
    if samples.is_empty() {
        return 0;
    }
    ((samples[0] as u64) << 16)
        ^ ((samples[samples.len() / 2] as u64) << 8)
        ^ samples[samples.len() - 1] as u64
        ^ samples.len() as u64
}

fn checksum_u16(samples: &[u16]) -> u64 {
    if samples.is_empty() {
        return 0;
    }
    ((samples[0] as u64) << 32)
        ^ ((samples[samples.len() / 2] as u64) << 16)
        ^ samples[samples.len() - 1] as u64
        ^ samples.len() as u64
}

fn direct_checksum(image: &DecodedRgbaImage) -> u64 {
    let pixels = match &image.pixels {
        DecodedRgbaPixels::U8(samples) => checksum(samples),
        DecodedRgbaPixels::U16(samples) => checksum_u16(samples),
    };
    ((image.width as u64) << 32) ^ image.height as u64 ^ pixels
}

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 3 {
        return Err("Usage: heif-image-adapter-bench <direct|adapter> <input.heic|.heif|.avif>".into());
    }
    let input = Path::new(&args[2]);
    let value = match args[1].as_str() {
        "direct" => direct_checksum(&decode_path_to_rgba(input)?),
        "adapter" => {
            let _ = register_image_decoder_hooks();
            let decoded = ImageReader::open(input)?.decode()?;
            let (width, height) = (decoded.width(), decoded.height());
            let pixels = match decoded {
                DynamicImage::ImageRgba8(buffer) => checksum(buffer.as_raw()),
                DynamicImage::ImageRgba16(buffer) => checksum_u16(buffer.as_raw()),
                other => return Err(format!("unsupported adapter output {:?}", other.color()).into()),
            };
            ((width as u64) << 32) ^ height as u64 ^ pixels
        }
        other => return Err(format!("unsupported mode '{other}'").into()),
    };
    println!("{value}");
    Ok(())
}
RS

  cat > "$HELPER_DIR/src/bin/heif-stream-concurrency-bench.rs" <<'RS'
use ente_heic::{DecodedRgbaImage, DecodedRgbaPixels, decode_path_to_rgba, decode_read_to_rgba};
use std::error::Error;
use std::fs::File;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::thread;

#[derive(Clone, Copy, Debug)]
enum Mode {
    Path,
    Read,
}

fn checksum(samples: &[u8]) -> u64 {
    if samples.is_empty() {
        return 0;
    }
    ((samples[0] as u64) << 16)
        ^ ((samples[samples.len() / 2] as u64) << 8)
        ^ samples[samples.len() - 1] as u64
        ^ samples.len() as u64
}

fn checksum_u16(samples: &[u16]) -> u64 {
    if samples.is_empty() {
        return 0;
    }
    ((samples[0] as u64) << 32)
        ^ ((samples[samples.len() / 2] as u64) << 16)
        ^ samples[samples.len() - 1] as u64
        ^ samples.len() as u64
}

fn image_checksum(image: &DecodedRgbaImage) -> u64 {
    let pixels = match &image.pixels {
        DecodedRgbaPixels::U8(samples) => checksum(samples),
        DecodedRgbaPixels::U16(samples) => checksum_u16(samples),
    };
    ((image.width as u64) << 32) ^ image.height as u64 ^ pixels
}

fn decode_checksum(mode: Mode, input: &Path) -> Result<u64, Box<dyn Error + Send + Sync>> {
    let decoded = match mode {
        Mode::Path => decode_path_to_rgba(input)?,
        Mode::Read => decode_read_to_rgba(File::open(input)?)?,
    };
    Ok(image_checksum(&decoded))
}

fn main() -> Result<(), Box<dyn Error + Send + Sync>> {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 5 {
        return Err("Usage: heif-stream-concurrency-bench <path|read> <workers> <iterations-per-worker> <input.heic|.avif> [more inputs...]".into());
    }
    let mode = match args[1].as_str() {
        "path" => Mode::Path,
        "read" => Mode::Read,
        other => return Err(format!("unsupported mode '{other}'").into()),
    };
    let workers = args[2].parse::<usize>()?;
    let iterations = args[3].parse::<usize>()?;
    if workers == 0 || iterations == 0 {
        return Err("workers and iterations must be greater than zero".into());
    }
    let inputs = Arc::new(args[4..].iter().map(PathBuf::from).collect::<Vec<_>>());
    let expected = Arc::new(
        inputs
            .iter()
            .map(|input| decode_checksum(Mode::Path, input))
            .collect::<Result<Vec<_>, _>>()?,
    );

    let mut handles = Vec::with_capacity(workers);
    for worker_id in 0..workers {
        let inputs = Arc::clone(&inputs);
        let expected = Arc::clone(&expected);
        handles.push(thread::spawn(move || {
            let mut aggregate = 0_u64;
            for iteration in 0..iterations {
                let index = (worker_id + iteration) % inputs.len();
                let actual = decode_checksum(mode, &inputs[index])?;
                if actual != expected[index] {
                    return Err(format!(
                        "checksum mismatch for {}: expected={} actual={}",
                        inputs[index].display(),
                        expected[index],
                        actual
                    )
                    .into());
                }
                aggregate ^= actual.rotate_left(((worker_id + iteration) % 63 + 1) as u32);
            }
            Ok::<u64, Box<dyn Error + Send + Sync>>(aggregate)
        }));
    }

    let mut aggregate = 0_u64;
    for handle in handles {
        aggregate ^= handle.join().map_err(|_| "worker panicked")??;
    }
    println!("ops={} checksum={aggregate}", workers * iterations);
    Ok(())
}
RS
}

build_helper() {
  require_cmd cargo
  ensure_helper_sources
  log helper "Building generated helper binaries at $HELPER_DIR"
  cargo build --manifest-path "$HELPER_DIR/Cargo.toml" --release --bins
}

libheif_oracle_ready() {
  local listing
  listing="$("$LIBHEIF_DEC_BIN" --list-decoders 2>/dev/null || true)"
  [[ -n "$listing" ]] || return 1

  has_decoder_in_section() {
    local section="$1"
    awk -v section="$section" '
      $0 == section ":" { in_section=1; next }
      in_section && $0 ~ /^[^[:space:]].*:$/ { in_section=0 }
      in_section && $0 ~ /^- / { has_decoder=1 }
      END { exit(has_decoder ? 0 : 1) }
    ' <<<"$listing"
  }

  has_decoder_in_section "AVIF decoders" &&
    has_decoder_in_section "HEIC decoders" &&
    has_decoder_in_section "JPEG decoders" &&
    has_decoder_in_section "JPEG 2000 decoders" &&
    has_decoder_in_section "uncompressed"
}

build_libheif_decoder() {
  resolve_libheif_paths

  local source_available=0
  is_libheif_source_dir "$LIBHEIF_SOURCE_DIR" && source_available=1

  local rebuild_reason=""
  if [[ "$LIBHEIF_RECONFIGURE" == "1" ]]; then
    rebuild_reason="forced by LIBHEIF_RECONFIGURE=1"
  elif [[ ! -x "$LIBHEIF_DEC_BIN" ]]; then
    rebuild_reason="decoder binary missing"
  elif [[ "$LIBHEIF_REQUIRE_ORACLE_DECODERS" == "1" ]] && ! libheif_oracle_ready; then
    rebuild_reason="existing build missing required validator decoders"
  fi

  if [[ -z "$rebuild_reason" ]]; then
    return
  fi

  if [[ "$source_available" -eq 0 ]]; then
    fail "Could not find a libheif validator checkout. Set HEIC_LIBHEIF_SOURCE_DIR, clone/symlink it into .heic-test-assets/libheif, or clone it directly into .heic-test-assets. The source checkout is needed to build heif-dec and to provide the default corpus."
  fi

  if [[ -z "$LIBHEIF_DEC_BIN_EXPLICIT" ]]; then
    LIBHEIF_DEC_BIN="$LIBHEIF_BUILD_DIR/examples/heif-dec"
  fi

  require_cmd cmake

  local cmake_args=(
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBUILD_TESTING=OFF"
    "-DWITH_EXAMPLES=ON"
    "-DENABLE_PLUGIN_LOADING=OFF"
    "-DWITH_LIBDE265=ON"
    "-DWITH_AOM_DECODER=ON"
    "-DWITH_DAV1D=ON"
    "-DWITH_UNCOMPRESSED_CODEC=ON"
    "-DWITH_OpenJPEG_DECODER=ON"
    "-DWITH_JPEG_DECODER=ON"
    "-DWITH_HEADER_COMPRESSION=ON"
  )

  if [[ -n "${LIBHEIF_CMAKE_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    local extra_cmake_args=( ${LIBHEIF_CMAKE_ARGS} )
    cmake_args+=("${extra_cmake_args[@]}")
  fi

  log validator "Building validator at $LIBHEIF_BUILD_DIR ($rebuild_reason)"
  cmake -S "$LIBHEIF_SOURCE_DIR" -B "$LIBHEIF_BUILD_DIR" "${cmake_args[@]}" >/dev/null
  cmake --build "$LIBHEIF_BUILD_DIR" --target heif-dec heif-info --parallel >/dev/null

  [[ -x "$LIBHEIF_DEC_BIN" ]] || fail "Could not build heif-dec at $LIBHEIF_DEC_BIN"
  if [[ "$LIBHEIF_REQUIRE_ORACLE_DECODERS" == "1" ]] && ! libheif_oracle_ready; then
    fail "Built validator is missing required decoders."
  fi
}

default_corpus_dirs() {
  resolve_libheif_paths

  if ! is_libheif_source_dir "$LIBHEIF_SOURCE_DIR"; then
    fail "No --corpus-dir provided and validator source not found. Set HEIC_LIBHEIF_SOURCE_DIR, clone/symlink it into .heic-test-assets/libheif, or clone it directly into .heic-test-assets."
  fi
  printf '%s\n' \
    "$LIBHEIF_SOURCE_DIR/examples" \
    "$LIBHEIF_SOURCE_DIR/tests/data" \
    "$LIBHEIF_SOURCE_DIR/fuzzing/data/corpus"
}

gather_files() {
  local dir
  for dir in "$@"; do
    if [[ -d "$dir" ]]; then
      find "$dir" -type f \( -iname '*.heif' -o -iname '*.heic' -o -iname '*.avif' \)
    fi
  done | sort -u
}

display_path() {
  local path="$1"
  case "$path" in
    "$ROOT_DIR"/*) echo "${path#$ROOT_DIR/}" ;;
    "$LIBHEIF_SOURCE_DIR"/*) echo "libheif/${path#$LIBHEIF_SOURCE_DIR/}" ;;
    *) echo "$path" ;;
  esac
}

file_id() {
  printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
}

clean_output_variants() {
  local requested="$1"
  local dir filename stem ext
  dir="${requested%/*}"
  filename="${requested##*/}"
  [[ "$dir" == "$requested" ]] && dir="."
  stem="${filename%.*}"
  ext="${filename##*.}"
  rm -f "$requested"
  find "$dir" -maxdepth 1 -type f -name "${stem}-*.${ext}" -delete
}

resolve_output_file() {
  local requested="$1"
  local dir filename stem ext candidate
  if [[ -f "$requested" ]]; then
    echo "$requested"
    return 0
  fi
  dir="${requested%/*}"
  filename="${requested##*/}"
  [[ "$dir" == "$requested" ]] && dir="."
  stem="${filename%.*}"
  ext="${filename##*.}"
  candidate="$(find "$dir" -maxdepth 1 -type f -name "${stem}-*.${ext}" | sort | head -n 1)"
  [[ -n "$candidate" ]] || return 1
  echo "$candidate"
}

decode_with_helper() {
  "$HELPER_BIN_DIR/heif-decode" --orientation preserve "$1" "$2"
}

decode_failure_category_from_log() {
  sed -nE 's/^Decode failed \[category=([^]]+)\]:.*/\1/p' "$1" | head -n 1
}

image_dim() {
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$1"
}

png_to_rgba() {
  ffmpeg -v error -y -i "$1" -map 0:v:0 -f rawvideo -pix_fmt rgba "$2"
}

float_add() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.8f", a + b }'
}

float_mul() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.8f", a * b }'
}

float_div() {
  awk -v a="$1" -v b="$2" 'BEGIN { if (b == 0) { print "inf" } else { printf "%.8f", a / b } }'
}

float_floor_time() {
  awk -v value="$1" 'BEGIN { if (value <= 0) printf "%.8f", 0.000001; else printf "%.8f", value }'
}

float_leq() {
  awk -v a="$1" -v b="$2" 'BEGIN { if (a <= b) print 1; else print 0 }'
}

float_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN { if (a > b) print 1; else print 0 }'
}

bytes_to_mib() {
  awk -v bytes="$1" 'BEGIN { printf "%.8f", bytes / 1048576 }'
}

file_size() {
  stat -f '%z' "$1" 2>/dev/null || stat -c '%s' "$1" 2>/dev/null || echo 0
}

LOADED_FILES=()

load_corpus() {
  local mode="$1"
  local quick_limit="$2"
  shift 2
  local corpus_dirs=("$@")

  if [[ ${#corpus_dirs[@]} -eq 0 ]]; then
    corpus_dirs=()
    while IFS= read -r line; do
      corpus_dirs+=("$line")
    done < <(default_corpus_dirs)
  fi

  LOADED_FILES=()
  while IFS= read -r line; do
    LOADED_FILES+=("$line")
  done < <(gather_files "${corpus_dirs[@]}")
  [[ ${#LOADED_FILES[@]} -gt 0 ]] || fail "No input files found in corpus dirs: ${corpus_dirs[*]}"

  if [[ "$mode" == "quick" && "${#LOADED_FILES[@]}" -gt "$quick_limit" ]]; then
    local selected=()
    local total_files="${#LOADED_FILES[@]}"
    local step=$((total_files / quick_limit))
    [[ "$step" -lt 1 ]] && step=1
    local idx=0
    while [[ "$idx" -lt "$total_files" && "${#selected[@]}" -lt "$quick_limit" ]]; do
      selected+=("${LOADED_FILES[$idx]}")
      idx=$((idx + step))
    done
    idx=0
    while [[ "$idx" -lt "$total_files" && "${#selected[@]}" -lt "$quick_limit" ]]; do
      selected+=("${LOADED_FILES[$idx]}")
      idx=$((idx + 1))
    done
    LOADED_FILES=("${selected[@]}")
  fi
}

cmd_verify() {
  local mode="quick"
  local quick_limit="${QUICK_LIMIT:-60}"
  local keep_artifacts=0
  local require_exts="${REQUIRE_EXTS:-}"
  local corpus_dirs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick) mode="quick"; shift ;;
      --full) mode="full"; shift ;;
      --quick-limit) quick_limit="$2"; shift 2 ;;
      --corpus-dir) corpus_dirs+=("$2"); shift 2 ;;
      --keep-artifacts) keep_artifacts=1; shift ;;
      --require-exts) require_exts="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'
Usage: scripts/heic_tests.sh verify [--quick|--full] [--quick-limit n]
       [--corpus-dir dir ...] [--keep-artifacts] [--require-exts heic,avif]
EOF
        return 0
        ;;
      *) fail "Unknown verify option: $1" ;;
    esac
  done

  require_cmd bash
  require_cmd ffmpeg
  require_cmd ffprobe
  require_cmd find
  require_cmd shasum
  require_cmd sort
  require_cmd awk
  require_cmd head
  require_cmd cmp
  require_cmd sed
  require_cmd tr

  build_libheif_decoder
  build_helper

  if [[ ${#corpus_dirs[@]} -gt 0 ]]; then
    load_corpus "$mode" "$quick_limit" "${corpus_dirs[@]}"
  else
    load_corpus "$mode" "$quick_limit"
  fi
  local files=("${LOADED_FILES[@]}")

  local run_dir="$TEST_ROOT/verify/run"
  local ref_dir="$run_dir/ref"
  local rust_dir="$run_dir/rust"
  local tmp_dir="$run_dir/tmp"
  local report_file="$run_dir/report.txt"
  rm -rf "$run_dir"
  mkdir -p "$ref_dir" "$rust_dir" "$tmp_dir"

  echo "mode=$mode files=${#files[@]}" > "$report_file"
  local total=0 skipped=0 passed=0 failed=0
  local comparable_heif=0 comparable_heic=0 comparable_avif=0
  local failures=()

  local input_file rel_path id ref_png rust_png ref_raw rust_raw ref_actual rust_actual
  for input_file in "${files[@]}"; do
    total=$((total + 1))
    rel_path="$(display_path "$input_file")"
    id="$(file_id "$rel_path")"
    ref_png="$ref_dir/$id.png"
    rust_png="$rust_dir/$id.png"
    ref_raw="$tmp_dir/$id.ref.rgba"
    rust_raw="$tmp_dir/$id.rust.rgba"

    if ! "$LIBHEIF_DEC_BIN" --quiet "$input_file" "$ref_png" >/dev/null 2>&1; then
      skipped=$((skipped + 1))
      echo "SKIP $rel_path (validator decode failed)" >> "$report_file"
      continue
    fi
    if ! ref_actual="$(resolve_output_file "$ref_png")"; then
      failed=$((failed + 1))
      failures+=("$rel_path :: validator output file not found")
      echo "FAIL $rel_path (validator output file not found)" >> "$report_file"
      continue
    fi

    case "${input_file##*.}" in
      heif|HEIF) comparable_heif=$((comparable_heif + 1)) ;;
      heic|HEIC) comparable_heic=$((comparable_heic + 1)) ;;
      avif|AVIF) comparable_avif=$((comparable_avif + 1)) ;;
    esac

    local rust_log="$tmp_dir/$id.rust.decode.stderr.log"
    if ! decode_with_helper "$input_file" "$rust_png" >/dev/null 2>"$rust_log"; then
      failed=$((failed + 1))
      local category
      category="$(decode_failure_category_from_log "$rust_log")"
      if [[ -n "$category" ]]; then
        failures+=("$rel_path :: rust decoder failed (category=$category)")
        echo "FAIL $rel_path (rust decode failed category=$category)" >> "$report_file"
      else
        failures+=("$rel_path :: rust decoder failed")
        echo "FAIL $rel_path (rust decode failed)" >> "$report_file"
      fi
      continue
    fi
    if ! rust_actual="$(resolve_output_file "$rust_png")"; then
      failed=$((failed + 1))
      failures+=("$rel_path :: rust output file not found")
      echo "FAIL $rel_path (rust output file not found)" >> "$report_file"
      continue
    fi

    local ref_dim rust_dim
    ref_dim="$(image_dim "$ref_actual" || true)"
    rust_dim="$(image_dim "$rust_actual" || true)"
    if [[ -z "$ref_dim" || -z "$rust_dim" || "$ref_dim" != "$rust_dim" ]]; then
      failed=$((failed + 1))
      failures+=("$rel_path :: dimension mismatch ref=$ref_dim rust=$rust_dim")
      echo "FAIL $rel_path (dimension mismatch ref=$ref_dim rust=$rust_dim)" >> "$report_file"
      continue
    fi

    if ! png_to_rgba "$ref_actual" "$ref_raw" >/dev/null 2>&1; then
      failed=$((failed + 1))
      failures+=("$rel_path :: could not convert validator output PNG")
      echo "FAIL $rel_path (validator PNG conversion failed)" >> "$report_file"
      continue
    fi
    if ! png_to_rgba "$rust_actual" "$rust_raw" >/dev/null 2>&1; then
      failed=$((failed + 1))
      failures+=("$rel_path :: could not convert Rust output PNG")
      echo "FAIL $rel_path (rust PNG conversion failed)" >> "$report_file"
      continue
    fi

    if cmp -s "$ref_raw" "$rust_raw"; then
      passed=$((passed + 1))
      echo "PASS $rel_path" >> "$report_file"
    else
      failed=$((failed + 1))
      local ref_hash rust_hash
      ref_hash="$(shasum -a 256 "$ref_raw" | awk '{print $1}')"
      rust_hash="$(shasum -a 256 "$rust_raw" | awk '{print $1}')"
      failures+=("$rel_path :: pixel mismatch ref=$ref_hash rust=$rust_hash")
      echo "FAIL $rel_path (pixel mismatch ref=$ref_hash rust=$rust_hash)" >> "$report_file"
    fi

    if [[ "$keep_artifacts" -eq 0 ]]; then
      rm -f "$ref_raw" "$rust_raw"
    fi
  done

  [[ "$keep_artifacts" -eq 1 ]] || rm -rf "$tmp_dir"
  log verify "Summary: total=$total skipped=$skipped passed=$passed failed=$failed"
  log verify "Report: $report_file"

  if [[ "$failed" -gt 0 ]]; then
    log verify "Failures:"
    printf '  - %s\n' "${failures[@]}"
    return 1
  fi

  if [[ -n "$require_exts" ]]; then
    IFS=',' read -r -a required_list <<< "$require_exts"
    local required_ext normalized
    for required_ext in "${required_list[@]}"; do
      normalized="$(echo "$required_ext" | tr '[:upper:]' '[:lower:]' | sed 's/^\.//')"
      case "$normalized" in
        heif) [[ "$comparable_heif" -gt 0 ]] || fail "Required .heif has no comparable files." ;;
        heic) [[ "$comparable_heic" -gt 0 ]] || fail "Required .heic has no comparable files." ;;
        avif) [[ "$comparable_avif" -gt 0 ]] || fail "Required .avif has no comparable files." ;;
        '') ;;
        *) fail "Unknown required extension: $required_ext" ;;
      esac
    done
  fi

  [[ "$passed" -gt 0 ]] || fail "No comparable files passed."
}

timed_command() {
  local timer_output real rss
  timer_output="$({ /usr/bin/time -lp "$@" >/dev/null; } 2>&1)"
  real="$(awk '/^real /{print $2}' <<<"$timer_output" | tail -n 1)"
  rss="$(awk '/maximum resident set size/{print $1}' <<<"$timer_output" | tail -n 1)"
  [[ -n "$real" && -n "$rss" ]] || return 1
  real="$(float_floor_time "$real")"
  printf '%s %s\n' "$real" "$rss"
}

timed_decode_libheif() {
  clean_output_variants "$2"
  timed_command "$LIBHEIF_DEC_BIN" --quiet "$1" "$2" || return 1
  resolve_output_file "$2" >/dev/null
}

timed_decode_helper() {
  clean_output_variants "$2"
  timed_command "$HELPER_BIN_DIR/heif-decode" --orientation preserve "$1" "$2" || return 1
  resolve_output_file "$2" >/dev/null
}

BENCH_MODE="quick"
BENCH_FILES=10
BENCH_RUNS=3
BENCH_ENFORCE=0
BENCH_CORPUS_DIRS=()

parse_bench_options() {
  BENCH_MODE="$1"
  BENCH_FILES="$2"
  BENCH_RUNS="$3"
  BENCH_ENFORCE=0
  BENCH_CORPUS_DIRS=()
  shift 3
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick) BENCH_MODE="quick"; shift ;;
      --full) BENCH_MODE="full"; shift ;;
      --files) BENCH_FILES="$2"; shift 2 ;;
      --runs) BENCH_RUNS="$2"; shift 2 ;;
      --enforce) BENCH_ENFORCE=1; shift ;;
      --corpus-dir) BENCH_CORPUS_DIRS+=("$2"); shift 2 ;;
      -h|--help) return 2 ;;
      *) fail "Unknown benchmark option: $1" ;;
    esac
  done
}

cmd_bench_decode() {
  if ! parse_bench_options quick 10 3 "$@"; then
    cat <<'EOF'
Usage: scripts/heic_tests.sh bench-decode [--quick|--full] [--files n] [--runs n]
       [--enforce] [--corpus-dir dir ...]
EOF
    return 0
  fi
  local mode="$BENCH_MODE" bench_files="$BENCH_FILES" runs="$BENCH_RUNS" enforce="$BENCH_ENFORCE"
  local corpus_dirs=()
  if [[ ${#BENCH_CORPUS_DIRS[@]} -gt 0 ]]; then
    corpus_dirs=("${BENCH_CORPUS_DIRS[@]}")
  fi

  require_cmd bash
  require_cmd find
  require_cmd sort
  require_cmd awk
  require_cmd head
  require_cmd stat
  require_cmd /usr/bin/time
  build_libheif_decoder
  build_helper

  if [[ ${#corpus_dirs[@]} -gt 0 ]]; then
    load_corpus "$mode" 120 "${corpus_dirs[@]}"
  else
    load_corpus "$mode" 120
  fi
  local files=("${LOADED_FILES[@]}")

  local tmp_dir="$TEST_ROOT/bench-decode/tmp"
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"

  local candidates=()
  local input_file ref_out rust_out
  for input_file in "${files[@]}"; do
    ref_out="$tmp_dir/probe.ref.png"
    rust_out="$tmp_dir/probe.rust.png"
    clean_output_variants "$ref_out"
    clean_output_variants "$rust_out"
    "$LIBHEIF_DEC_BIN" --quiet "$input_file" "$ref_out" >/dev/null 2>&1 || continue
    resolve_output_file "$ref_out" >/dev/null || continue
    decode_with_helper "$input_file" "$rust_out" >/dev/null 2>&1 || continue
    resolve_output_file "$rust_out" >/dev/null || continue
    candidates+=("$(file_size "$input_file")::$input_file")
  done
  [[ ${#candidates[@]} -gt 0 ]] || fail "No benchmark candidates could be decoded by both decoders."

  local selected=()
  while IFS= read -r line; do
    selected+=("$line")
  done < <(printf '%s\n' "${candidates[@]}" | sort -rn | head -n "$bench_files")

  local total_lib_time="0" total_rust_time="0" peak_lib_rss=0 peak_rust_rss=0
  log bench "Benchmarking ${#selected[@]} file(s), runs=$runs"

  local entry rel_path lib_sum rust_sum lib_peak rust_peak i lib_time lib_rss rust_time rust_rss
  for entry in "${selected[@]}"; do
    input_file="${entry#*::}"
    rel_path="$(display_path "$input_file")"
    lib_sum="0"
    rust_sum="0"
    lib_peak=0
    rust_peak=0
    for ((i=1; i<=runs; i++)); do
      read -r lib_time lib_rss < <(timed_decode_libheif "$input_file" "$tmp_dir/validator.$i.png")
      read -r rust_time rust_rss < <(timed_decode_helper "$input_file" "$tmp_dir/rust.$i.png")
      lib_sum="$(float_add "$lib_sum" "$lib_time")"
      rust_sum="$(float_add "$rust_sum" "$rust_time")"
      (( lib_rss > lib_peak )) && lib_peak=$lib_rss
      (( rust_rss > rust_peak )) && rust_peak=$rust_rss
    done
    local lib_avg rust_avg ratio
    lib_avg="$(float_div "$lib_sum" "$runs")"
    rust_avg="$(float_div "$rust_sum" "$runs")"
    ratio="$(float_div "$rust_avg" "$lib_avg")"
    total_lib_time="$(float_add "$total_lib_time" "$lib_avg")"
    total_rust_time="$(float_add "$total_rust_time" "$rust_avg")"
    (( lib_peak > peak_lib_rss )) && peak_lib_rss=$lib_peak
    (( rust_peak > peak_rust_rss )) && peak_rust_rss=$rust_peak
    log bench "file=$rel_path validator_avg=${lib_avg}s rust_avg=${rust_avg}s ratio=${ratio}x validator_peak_rss=${lib_peak} rust_peak_rss=${rust_peak}"
  done

  local time_ratio rss_ratio max_slowdown max_rss_multiplier
  max_slowdown="${MAX_SLOWDOWN:-2.5}"
  max_rss_multiplier="${MAX_RSS_MULTIPLIER:-3.0}"
  time_ratio="$(float_div "$total_rust_time" "$total_lib_time")"
  rss_ratio="$(float_div "$peak_rust_rss" "$peak_lib_rss")"
  log bench "Aggregate: rust/validator time ratio=${time_ratio}x peak_rss_ratio=${rss_ratio}x"
  log bench "Thresholds: time<=${max_slowdown}x peak_rss<=${max_rss_multiplier}x"
  if [[ "$enforce" -eq 1 ]]; then
    [[ "$(float_leq "$time_ratio" "$max_slowdown")" -eq 1 && "$(float_leq "$rss_ratio" "$max_rss_multiplier")" -eq 1 ]] ||
      fail "Performance thresholds exceeded (time_ratio=${time_ratio} rss_ratio=${rss_ratio})"
  fi
}

cmd_pair_bench() {
  local label="$1" bin_name="$2" mode_a="$3" mode_b="$4" env_time="$5" env_rss="$6"
  shift 6
  if ! parse_bench_options quick 10 3 "$@"; then
    cat <<EOF
Usage: scripts/heic_tests.sh $label [--quick|--full] [--files n] [--runs n]
       [--enforce] [--corpus-dir dir ...]
EOF
    return 0
  fi
  local mode="$BENCH_MODE" bench_files="$BENCH_FILES" runs="$BENCH_RUNS" enforce="$BENCH_ENFORCE"
  local corpus_dirs=()
  if [[ ${#BENCH_CORPUS_DIRS[@]} -gt 0 ]]; then
    corpus_dirs=("${BENCH_CORPUS_DIRS[@]}")
  fi

  require_cmd find
  require_cmd sort
  require_cmd awk
  require_cmd head
  require_cmd stat
  require_cmd /usr/bin/time
  build_helper

  if [[ ${#corpus_dirs[@]} -gt 0 ]]; then
    load_corpus "$mode" 120 "${corpus_dirs[@]}"
  else
    load_corpus "$mode" 120
  fi
  local files=("${LOADED_FILES[@]}")
  local bin="$HELPER_BIN_DIR/$bin_name"

  local candidates=()
  local input_file
  for input_file in "${files[@]}"; do
    "$bin" "$mode_a" "$input_file" >/dev/null 2>&1 || continue
    "$bin" "$mode_b" "$input_file" >/dev/null 2>&1 || continue
    candidates+=("$(file_size "$input_file")::$input_file")
  done
  [[ ${#candidates[@]} -gt 0 ]] || fail "No benchmark candidates could be decoded by both modes."

  local selected=()
  while IFS= read -r line; do
    selected+=("$line")
  done < <(printf '%s\n' "${candidates[@]}" | sort -rn | head -n "$bench_files")

  local total_a="0" total_b="0" peak_a=0 peak_b=0
  log "$label" "Benchmarking ${#selected[@]} file(s), runs=$runs"
  local entry rel_path sum_a sum_b run time_a rss_a time_b rss_b
  for entry in "${selected[@]}"; do
    input_file="${entry#*::}"
    rel_path="$(display_path "$input_file")"
    sum_a="0"
    sum_b="0"
    local file_peak_a=0 file_peak_b=0
    for ((run=1; run<=runs; run++)); do
      read -r time_a rss_a < <(timed_command "$bin" "$mode_a" "$input_file")
      read -r time_b rss_b < <(timed_command "$bin" "$mode_b" "$input_file")
      sum_a="$(float_add "$sum_a" "$time_a")"
      sum_b="$(float_add "$sum_b" "$time_b")"
      (( rss_a > file_peak_a )) && file_peak_a=$rss_a
      (( rss_b > file_peak_b )) && file_peak_b=$rss_b
    done
    local avg_a avg_b ratio
    avg_a="$(float_div "$sum_a" "$runs")"
    avg_b="$(float_div "$sum_b" "$runs")"
    ratio="$(float_div "$avg_b" "$avg_a")"
    total_a="$(float_add "$total_a" "$avg_a")"
    total_b="$(float_add "$total_b" "$avg_b")"
    (( file_peak_a > peak_a )) && peak_a=$file_peak_a
    (( file_peak_b > peak_b )) && peak_b=$file_peak_b
    log "$label" "file=$rel_path ${mode_a}_avg=${avg_a}s ${mode_b}_avg=${avg_b}s ratio=${ratio}x ${mode_a}_peak_rss=${file_peak_a} ${mode_b}_peak_rss=${file_peak_b}"
  done

  local time_ratio rss_ratio max_time max_rss
  max_time="${!env_time:-2.0}"
  max_rss="${!env_rss:-2.0}"
  time_ratio="$(float_div "$total_b" "$total_a")"
  rss_ratio="$(float_div "$peak_b" "$peak_a")"
  log "$label" "Aggregate: ${mode_b}/${mode_a} time ratio=${time_ratio}x peak_rss_ratio=${rss_ratio}x"
  log "$label" "Thresholds: time<=${max_time}x peak_rss<=${max_rss}x"
  if [[ "$enforce" -eq 1 ]]; then
    [[ "$(float_leq "$time_ratio" "$max_time")" -eq 1 && "$(float_leq "$rss_ratio" "$max_rss")" -eq 1 ]] ||
      fail "$label thresholds exceeded (time_ratio=${time_ratio} rss_ratio=${rss_ratio})"
  fi
}

cmd_bench_stream() {
  local mode="quick" bench_files=6 runs=2 enforce=0 corpus_dirs=()
  local workers="${STREAM_BENCH_WORKERS:-10}" iterations=4
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --quick) mode="quick"; shift ;;
      --full) mode="full"; shift ;;
      --files) bench_files="$2"; shift 2 ;;
      --runs) runs="$2"; shift 2 ;;
      --workers) workers="$2"; shift 2 ;;
      --iterations) iterations="$2"; shift 2 ;;
      --enforce) enforce=1; shift ;;
      --corpus-dir) corpus_dirs+=("$2"); shift 2 ;;
      -h|--help)
        cat <<'EOF'
Usage: scripts/heic_tests.sh bench-stream [--quick|--full] [--files n]
       [--runs n] [--workers n] [--iterations n] [--enforce] [--corpus-dir dir ...]
EOF
        return 0
        ;;
      *) fail "Unknown bench-stream option: $1" ;;
    esac
  done

  require_cmd find
  require_cmd sort
  require_cmd awk
  require_cmd head
  require_cmd stat
  require_cmd /usr/bin/time
  build_helper

  if [[ ${#corpus_dirs[@]} -gt 0 ]]; then
    load_corpus "$mode" 120 "${corpus_dirs[@]}"
  else
    load_corpus "$mode" 120
  fi
  local files=("${LOADED_FILES[@]}")
  local bin="$HELPER_BIN_DIR/heif-stream-concurrency-bench"
  local candidates=()
  local input_file ext
  for input_file in "${files[@]}"; do
    ext="${input_file##*.}"
    [[ "$ext" == "heic" || "$ext" == "HEIC" || "$ext" == "avif" || "$ext" == "AVIF" ]] || continue
    "$bin" path 1 1 "$input_file" >/dev/null 2>&1 || continue
    "$bin" read 1 1 "$input_file" >/dev/null 2>&1 || continue
    candidates+=("$(file_size "$input_file")::$input_file")
  done
  [[ ${#candidates[@]} -gt 0 ]] || fail "No stream benchmark candidates could be decoded by both modes."

  local selected_entries=()
  while IFS= read -r line; do
    selected_entries+=("$line")
  done < <(printf '%s\n' "${candidates[@]}" | sort -rn | head -n "$bench_files")
  local selected_files=()
  local entry
  for entry in "${selected_entries[@]}"; do
    selected_files+=("${entry#*::}")
  done

  log stream "Selected ${#selected_files[@]} file(s):"
  for input_file in "${selected_files[@]}"; do
    log stream "  - $(display_path "$input_file")"
  done

  local overall_peak_rss=0 overall_worst_slowdown="0"
  local stream_mode baseline_sum concurrent_sum baseline_peak concurrent_peak run
  for stream_mode in path read; do
    baseline_sum="0"
    concurrent_sum="0"
    baseline_peak=0
    concurrent_peak=0
    for ((run=1; run<=runs; run++)); do
      read -r baseline_time baseline_rss < <(timed_command "$bin" "$stream_mode" 1 "$iterations" "${selected_files[@]}")
      read -r concurrent_time concurrent_rss < <(timed_command "$bin" "$stream_mode" "$workers" "$iterations" "${selected_files[@]}")
      baseline_sum="$(float_add "$baseline_sum" "$baseline_time")"
      concurrent_sum="$(float_add "$concurrent_sum" "$concurrent_time")"
      (( baseline_rss > baseline_peak )) && baseline_peak=$baseline_rss
      (( concurrent_rss > concurrent_peak )) && concurrent_peak=$concurrent_rss
    done
    local baseline_avg concurrent_avg slowdown baseline_ops concurrent_ops
    baseline_avg="$(float_div "$baseline_sum" "$runs")"
    concurrent_avg="$(float_div "$concurrent_sum" "$runs")"
    slowdown="$(float_div "$concurrent_avg" "$(float_mul "$baseline_avg" "$workers")")"
    baseline_ops="$(float_div "$iterations" "$baseline_avg")"
    concurrent_ops="$(float_div "$((workers * iterations))" "$concurrent_avg")"
    (( concurrent_peak > overall_peak_rss )) && overall_peak_rss=$concurrent_peak
    [[ "$(float_gt "$slowdown" "$overall_worst_slowdown")" -eq 1 ]] && overall_worst_slowdown="$slowdown"
    log stream "mode=$stream_mode baseline_avg=${baseline_avg}s concurrent_avg=${concurrent_avg}s slowdown=${slowdown}x baseline_ops_per_sec=${baseline_ops} concurrent_ops_per_sec=${concurrent_ops} baseline_peak_rss=${baseline_peak} concurrent_peak_rss=${concurrent_peak}"
    echo "METRIC mode=${stream_mode} baseline_avg_s=${baseline_avg} concurrent_avg_s=${concurrent_avg} slowdown_x=${slowdown} baseline_ops_per_sec=${baseline_ops} concurrent_ops_per_sec=${concurrent_ops} baseline_peak_rss=${baseline_peak} concurrent_peak_rss=${concurrent_peak}"
  done

  local peak_mib max_rss_mib max_slowdown
  peak_mib="$(bytes_to_mib "$overall_peak_rss")"
  max_rss_mib="${MAX_STREAM_CONCURRENT_RSS_MIB:-1536}"
  max_slowdown="${MAX_STREAM_CONCURRENT_SLOWDOWN:-2.5}"
  log stream "Aggregate: workers=${workers} iterations=${iterations} runs=${runs} files=${#selected_files[@]} worst_slowdown=${overall_worst_slowdown}x peak_concurrent_rss=${overall_peak_rss}"
  log stream "Thresholds: worst_slowdown<=${max_slowdown}x peak_concurrent_rss<=${max_rss_mib}MiB"
  echo "METRIC aggregate workers=${workers} iterations=${iterations} runs=${runs} files=${#selected_files[@]} worst_slowdown_x=${overall_worst_slowdown} peak_concurrent_rss=${overall_peak_rss} peak_concurrent_rss_mib=${peak_mib}"
  if [[ "$enforce" -eq 1 ]]; then
    [[ "$(float_leq "$overall_worst_slowdown" "$max_slowdown")" -eq 1 && "$(float_leq "$peak_mib" "$max_rss_mib")" -eq 1 ]] ||
      fail "stream thresholds exceeded (worst_slowdown=${overall_worst_slowdown} peak_concurrent_rss_mib=${peak_mib})"
  fi
}

cmd_all() {
  cmd_verify --full --require-exts heic,avif
  cmd_bench_decode --full --files 12 --runs 5
  cmd_pair_bench bench-ingestion heif-ingestion-bench bytes path MAX_INGEST_PATH_SLOWDOWN MAX_INGEST_PATH_RSS_MULTIPLIER --full --files 12 --runs 5
  cmd_pair_bench bench-image heif-image-adapter-bench direct adapter MAX_IMAGE_ADAPTER_SLOWDOWN MAX_IMAGE_ADAPTER_RSS_MULTIPLIER --full --files 12 --runs 5
  cmd_bench_stream --full --files 6 --runs 2 --workers 10 --iterations 4
}

main() {
  local command="${1:-}"
  if [[ -z "$command" || "$command" == "-h" || "$command" == "--help" ]]; then
    usage
    return 0
  fi
  shift
  mkdir -p "$TEST_ROOT"

  case "$command" in
    verify) cmd_verify "$@" ;;
    bench-decode) cmd_bench_decode "$@" ;;
    bench-ingestion) cmd_pair_bench bench-ingestion heif-ingestion-bench bytes path MAX_INGEST_PATH_SLOWDOWN MAX_INGEST_PATH_RSS_MULTIPLIER "$@" ;;
    bench-image) cmd_pair_bench bench-image heif-image-adapter-bench direct adapter MAX_IMAGE_ADAPTER_SLOWDOWN MAX_IMAGE_ADAPTER_RSS_MULTIPLIER "$@" ;;
    bench-stream) cmd_bench_stream "$@" ;;
    all) cmd_all "$@" ;;
    build-helper) build_helper ;;
    *) fail "Unknown command: $command" ;;
  esac
}

main "$@"
