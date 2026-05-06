# ente_heic API Guide

This document is the practical API reference for integrating `ente_heic` in apps and automation.

## Scope

- Decode HEIF/HEIC/AVIF to RGBA (`u8` or `u16` storage).
- Decode from bytes, `Read`, `BufRead`, and file paths.
- Optional `image` crate integration through hook registration.
- Keep default decode output aligned with primary item transforms (`clap`/`irot`/`imir`) and expose explicit EXIF orientation helpers.

## Feature Flags

- `default`: no optional features.
- `image-integration`: enables `ente_heic::image_integration` module and hook APIs.

`Cargo.toml`:

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

## Core Types

- `DecodeGuardrails`
  - `max_input_bytes: Option<u64>`
  - `max_pixels: Option<u64>`
  - `max_temp_spool_bytes: Option<u64>`
  - `temp_spool_directory: Option<PathBuf>`
- `DecodedRgbaImage`
  - `width`, `height`
  - `source_bit_depth`
  - `pixels: DecodedRgbaPixels` (`U8(Vec<u8>)` or `U16(Vec<u16>)`)
  - `icc_profile: Option<Vec<u8>>`
- `ExifOrientationHint`
  - `exif_orientation: Option<u8>`
  - `primary_item_has_orientation_transform: bool`
  - `should_apply_exif_orientation()`
  - `orientation_to_apply()`
- `DecodeError`, `DecodeErrorCategory`, `DecodeGuardrailError`

## Core Decode Entry Points

Return type for RGBA decode functions:

```rust
Result<DecodedRgbaImage, DecodeError>
```

### RGBA output

- `decode_bytes_to_rgba_with_guardrails(input, guardrails)`
- `decode_read_to_rgba_with_guardrails(reader, guardrails)`
- `decode_bufread_to_rgba_with_guardrails(bufread, guardrails)`
- `decode_path_to_rgba_with_guardrails(path, guardrails)`

Non-guardrailed convenience variants also exist (`decode_*_to_rgba`) and use `DecodeGuardrails::default()`.

### PNG output

- `decode_bytes_to_png_with_guardrails(input, output_path, guardrails)`
- `decode_read_to_png_with_guardrails(reader, output_path, guardrails)`
- `decode_bufread_to_png_with_guardrails(bufread, output_path, guardrails)`
- `decode_path_to_png_with_guardrails(input_path, output_path, guardrails)`

Legacy aliases:

- `decode_file_to_rgba` -> `decode_path_to_rgba`
- `decode_file_to_png` -> `decode_path_to_png`

## Advanced Decode APIs

These are useful for tooling and specialized pipelines, but most applications
should use the core entry points above.

- `decode_primary_avif_to_image(input)` -> `Result<DecodedAvifImage, DecodeAvifError>`
- `assemble_primary_heic_hevc_stream(input)` -> `Result<Vec<u8>, DecodeHeicError>`
- `decode_primary_heic_to_image(input)` -> `Result<DecodedHeicImage, DecodeHeicError>`
- `decode_primary_heic_to_metadata(input)` -> `Result<DecodedHeicImageMetadata, DecodeHeicError>`
- `decode_primary_uncompressed_to_image(input)` -> `Result<DecodedUncompressedImage, DecodeUncompressedError>`

Also note:

- `isobmff` and `source` modules are public and available for advanced use.
- These low-level APIs expose more container/codec details and have a larger
  surface for malformed-input handling.

## Input Path Selection

Use this decision order:

1. If you already have `&[u8]`, use `decode_bytes_to_rgba_with_guardrails`.
2. If you have a file path, use `decode_path_to_rgba_with_guardrails`.
3. If you have `Read`/`BufRead` (non-seek stream), use `decode_read_to_rgba_with_guardrails` or `decode_bufread_to_rgba_with_guardrails`.

Important behavior:

- `Read`/`BufRead` inputs are spooled once to a temporary file to enable random-access decode.
- `Path` and seekable decode paths avoid full-file in-memory buffering.

## Guardrail Presets

Use explicit guardrails in production.

Example preset:

```rust
use ente_heic::DecodeGuardrails;

let guardrails = DecodeGuardrails {
    max_input_bytes: Some(128 * 1024 * 1024),
    max_pixels: Some(64_000_000),
    max_temp_spool_bytes: Some(128 * 1024 * 1024),
    temp_spool_directory: None,
};
```

Notes:

- `max_input_bytes` applies to all entry points.
- `max_temp_spool_bytes` protects non-seek `Read`/`BufRead` ingestion.
- `max_pixels` blocks oversized decoded geometry before RGBA materialization.

## Error Handling Contract

Top-level errors are `DecodeError`. Use `category()` for stable handling:

```rust
use ente_heic::{DecodeError, DecodeErrorCategory};

fn classify(err: &DecodeError) -> DecodeErrorCategory {
    err.category()
}
```

Stable categories:

- `Io`
- `Parse`
- `MalformedInput`
- `UnsupportedFeature`
- `ResourceLimit`
- `DecoderBackend`
- `OutputEncoding`

Typical policy mapping:

- `ResourceLimit`: return `413` / reject input.
- `MalformedInput` or `Parse`: return `422`.
- `UnsupportedFeature`: return `415`.
- `Io` or `DecoderBackend`: retry/fallback/log depending on context.

## Working With Decoded Pixels

Inspect storage and branch explicitly:

```rust
use ente_heic::DecodedRgbaPixels;

match &decoded.pixels {
    DecodedRgbaPixels::U8(p) => {
        // p: &[u8], RGBA8 interleaved
    }
    DecodedRgbaPixels::U16(p) => {
        // p: &[u16], RGBA16 interleaved
    }
}
```

Helpers on `DecodedRgbaImage` / `DecodedRgbaPixels`:

- `storage_bit_depth()`
- `as_rgba8()`, `as_rgba16()`
- `into_rgba8()`, `into_rgba16()`
- `apply_exif_orientation(exif_orientation)`

## EXIF Orientation Handling

Default decode behavior:

- Decode applies HEIF primary item transforms from `clap`/`irot`/`imir`.
- Decode does not implicitly apply EXIF orientation.
- This keeps output stable for libheif parity and avoids hidden double-rotation behavior.

Orientation APIs:

- `exif_orientation_hint(input_bytes)` -> `ExifOrientationHint`
- `exif_orientation_hint_from_path(input_path)` -> `Result<ExifOrientationHint, DecodeError>`
- `primary_exif_orientation(input_bytes)` -> `Option<u8>`
- `primary_exif_orientation_from_path(input_path)` -> `Result<Option<u8>, DecodeError>`
- `primary_item_has_orientation_transform(input_bytes)` -> `bool`
- `path_extension_is_heif(path)` -> `bool`
- `path_extension_is_heif_family(path)` -> `bool`
- `DecodedRgbaImage::apply_exif_orientation(exif_orientation)` -> `Result<DecodedRgbaImage, DecodeError>`

Recommended pattern:

```rust
use ente_heic::{decode_path_to_rgba, exif_orientation_hint};
use std::path::Path;

fn decode_with_explicit_orientation(path: &Path) -> Result<(), ente_heic::DecodeError> {
    let input = std::fs::read(path).map_err(ente_heic::DecodeError::Io)?;
    let hint = exif_orientation_hint(&input);

    let decoded = decode_path_to_rgba(path)?;
    let decoded = if let Some(orientation) = hint.orientation_to_apply() {
        decoded.apply_exif_orientation(orientation)?
    } else {
        decoded
    };

    eprintln!("{}x{}", decoded.width, decoded.height);
    Ok(())
}
```

Path-only variant (no full input read, no image decode):

```rust
use ente_heic::{exif_orientation_hint_from_path, path_extension_is_heif};
use std::path::Path;

fn orientation_to_apply(path: &Path) -> Result<Option<u8>, ente_heic::DecodeError> {
    if !path_extension_is_heif(path) {
        return Ok(None);
    }
    Ok(exif_orientation_hint_from_path(path)?.orientation_to_apply())
}
```

## image Integration

Requires `image-integration` feature.

### 1) Register hooks once at startup

```rust
use ente_heic::DecodeGuardrails;
use ente_heic::image_integration::register_image_decoder_hooks_with_guardrails;

let registration = register_image_decoder_hooks_with_guardrails(DecodeGuardrails {
    max_input_bytes: Some(128 * 1024 * 1024),
    max_pixels: Some(64_000_000),
    max_temp_spool_bytes: Some(128 * 1024 * 1024),
    temp_spool_directory: None,
});

assert!(registration.any_decoder_hook_registered());
```

### 2) Decode using `image::ImageReader`

```rust
use image::ImageReader;
use ente_heic::exif_orientation_hint;
use ente_heic::image_integration::apply_exif_orientation_dynamic;

let bytes = std::fs::read("input.heic").map_err(image::ImageError::IoError)?;
let hint = exif_orientation_hint(&bytes);

let img = ImageReader::new(std::io::Cursor::new(&bytes))
    .with_guessed_format()?
    .decode()?;

let img = if let Some(orientation) = hint.orientation_to_apply() {
    apply_exif_orientation_dynamic(img, orientation)
} else {
    img
};
```

### 3) Direct adapter usage (optional)

`HeifImageDecoder` constructors:

- `from_bytes[_with_guardrails]`
- `from_read[_with_guardrails]`
- `from_bufread[_with_guardrails]`
- `from_seekable[_with_guardrails]`
- `from_path[_with_guardrails]`

## Conversion Helpers (image module)

Under `image-integration`, `DecodedRgbaImage` provides conversion helpers:

- `into_image_buffer_with_metadata()`
- `into_image_buffer()`
- `into_dynamic_image_with_metadata()`
- `into_dynamic_image()`

Metadata-preserving wrappers:

- `ImageBufferWithMetadata`
- `DynamicImageWithMetadata`

Possible conversion failures:

- `ImageConversionError::SampleCountOverflow`
- `ImageConversionError::SampleCountMismatch`

Additional helper under `image-integration`:

- `apply_exif_orientation_dynamic(image, exif_orientation)`

## AI/Automation Usage Rules

For reliable agent behavior:

1. Always use `*_with_guardrails` APIs for untrusted input.
2. Treat `Read`/`BufRead` as temp-spooled random-access decode, not progressive decode.
3. Branch on `decoded.storage_bit_depth()` and avoid implicit down-conversion.
4. Match `DecodeError::category()` for stable retry/reject decisions.
5. Register image hooks exactly once during process startup.
6. Keep guardrail values centralized in one config module for consistency.

## Minimal End-to-End Example

```rust
use ente_heic::{decode_path_to_rgba_with_guardrails, DecodeGuardrails};
use std::path::Path;

fn decode(path: &Path) -> Result<(), ente_heic::DecodeError> {
    let guardrails = DecodeGuardrails {
        max_input_bytes: Some(128 * 1024 * 1024),
        max_pixels: Some(64_000_000),
        max_temp_spool_bytes: Some(128 * 1024 * 1024),
        temp_spool_directory: None,
    };

    let decoded = decode_path_to_rgba_with_guardrails(path, guardrails)?;
    eprintln!(
        "decoded {}x{}, storage={}bit, source={}bit",
        decoded.width,
        decoded.height,
        decoded.storage_bit_depth(),
        decoded.source_bit_depth
    );
    Ok(())
}
```
