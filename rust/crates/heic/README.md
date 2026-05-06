# ente_heic

Pure Rust HEIF/HEIC/AVIF decoder with first-class `image` crate integration.

## What This Crate Provides

- Decode `.heif`, `.heic`, and `.avif` into RGBA buffers (`u8` or `u16`).
- Decode from `bytes`, `Read`, `BufRead`, and file `Path`.
- Keep default decode output aligned with primary-item transforms (`clap`/`irot`/`imir`) for reference-output parity.
- Expose explicit EXIF orientation helpers so callers can apply orientation at the app layer:
  - `exif_orientation_hint`
  - `exif_orientation_hint_from_path`
  - `path_extension_is_heif`
  - `DecodedRgbaImage::apply_exif_orientation`
  - `image_integration::apply_exif_orientation_dynamic`
- Optional guardrails for bounded production use:
  - max input bytes
  - max decoded pixel count
  - max temporary spool bytes for non-seek inputs
  - custom temp spool directory
- Optional `image` integration feature that registers decoder hooks so `image::ImageReader` can open HEIF/HEIC/AVIF directly.

## API Docs

- Detailed API guide: [`API.md`](API.md)

## Install

`Cargo.toml` (local path dependency):

```toml
[dependencies]
ente_heic = { path = "../heic" }
```

With `image` integration:

```toml
[dependencies]
ente_heic = { path = "../heic", features = ["image-integration"] }
image = { version = "0.25", default-features = false, features = ["png"] }
```

## Decode Example

```rust
use ente_heic::{decode_path_to_rgba_with_guardrails, DecodeGuardrails};
use std::path::Path;

fn decode_file(path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let guardrails = DecodeGuardrails {
        max_input_bytes: Some(128 * 1024 * 1024),
        max_pixels: Some(64_000_000),
        max_temp_spool_bytes: Some(128 * 1024 * 1024),
        temp_spool_directory: None,
    };

    let decoded = decode_path_to_rgba_with_guardrails(path, guardrails)?;
    println!(
        "decoded {}x{} (storage={}bit)",
        decoded.width,
        decoded.height,
        decoded.storage_bit_depth()
    );

    Ok(())
}
```

## EXIF Orientation Policy

- `ente_heic` does **not** implicitly apply EXIF orientation to decoded output.
- This keeps default output behavior stable and suitable for reference-output comparisons.
- If your app wants display-oriented output, apply EXIF orientation explicitly:

```rust
use ente_heic::{decode_path_to_rgba, exif_orientation_hint};
use std::path::Path;

fn decode_with_explicit_orientation(path: &Path) -> Result<(), Box<dyn std::error::Error>> {
    let input = std::fs::read(path)?;
    let hint = exif_orientation_hint(&input);

    let decoded = decode_path_to_rgba(path)?;
    let decoded = if let Some(orientation) = hint.orientation_to_apply() {
        decoded.apply_exif_orientation(orientation)?
    } else {
        decoded
    };

    println!("final dimensions: {}x{}", decoded.width, decoded.height);
    Ok(())
}
```

Path-based (no full file read, no pixel decode) orientation hint:

```rust
use ente_heic::{exif_orientation_hint_from_path, path_extension_is_heif};
use std::path::Path;

fn orientation_from_path(path: &Path) -> Result<Option<u8>, ente_heic::DecodeError> {
    if !path_extension_is_heif(path) {
        return Ok(None);
    }
    let hint = exif_orientation_hint_from_path(path)?;
    Ok(hint.orientation_to_apply())
}
```

## Hook Into The `image` Crate

```rust
use image::ImageReader;
use ente_heic::image_integration::{
    apply_exif_orientation_dynamic,
    register_image_decoder_hooks_with_guardrails,
};
use ente_heic::{exif_orientation_hint, DecodeGuardrails};

fn init_image_hooks() {
    let guardrails = DecodeGuardrails {
        max_input_bytes: Some(128 * 1024 * 1024),
        max_pixels: Some(64_000_000),
        max_temp_spool_bytes: Some(128 * 1024 * 1024),
        temp_spool_directory: None,
    };

    let registered = register_image_decoder_hooks_with_guardrails(guardrails);
    assert!(registered.any_decoder_hook_registered());
}

fn decode_with_image(path: &str) -> image::ImageResult<image::DynamicImage> {
    let bytes = std::fs::read(path).map_err(image::ImageError::IoError)?;
    let hint = exif_orientation_hint(&bytes);

    let image = ImageReader::new(std::io::Cursor::new(&bytes))
        .with_guessed_format()?
        .decode()?;

    let image = if let Some(orientation) = hint.orientation_to_apply() {
        apply_exif_orientation_dynamic(image, orientation)
    } else {
        image
    };

    Ok(image)
}
```

## CLI

Build:

```bash
cargo build --manifest-path ente_heic/Cargo.toml --release --bin heif-decode
```

Usage:

```bash
ente_heic/target/release/heif-decode \
  --max-input-bytes 134217728 \
  --max-pixels 64000000 \
  --max-temp-spool-bytes 134217728 \
  <input.heif|.heic|.avif> <output.png>
```

## Correctness and Performance Testing

See `TESTING.md` for the correctness and performance test harness. It keeps
image corpora, external validator builds, and generated helper binaries out of
git by using `.heic-test-assets/` and `.heic-test-runs/`. Point the harness at
an external libheif checkout with `HEIC_LIBHEIF_SOURCE_DIR`, or place a checkout
or symlink at `.heic-test-assets/libheif`. A libheif checkout directly at
`.heic-test-assets` is accepted too.

## License

This crate is maintained inside the Ente monorepo.
