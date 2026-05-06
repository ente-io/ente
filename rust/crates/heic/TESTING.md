# HEIC Correctness and Performance Tests

This crate intentionally does not track image corpora, external validator source
trees, validator build products, or helper binaries. The test harness keeps all
generated files under `.heic-test-runs/`, and optional local assets under
`.heic-test-assets/`; both are gitignored.

The harness mirrors the correctness and performance checks used in `libheic-rs`.
It uses libheif only as an external validator and optional corpus source. The
crate does not use libheif source code or link to libheif.

- pixel-for-pixel PNG comparison against an external `heif-dec` validator
- Rust decoder vs external validator decode timing
- bytes vs path ingestion timing
- `image` adapter vs direct decode timing
- path/read concurrent decode timing and RSS

## Setup

Put a libheif checkout or symlink under the ignored asset directory:

```bash
mkdir -p .heic-test-assets
ln -s /path/to/libheif .heic-test-assets/libheif
```

Cloning directly into `.heic-test-assets` is also accepted:

```bash
git clone https://github.com/strukturag/libheif.git .heic-test-assets
```

Or point the script at an existing validator/corpus checkout:

```bash
export HEIC_LIBHEIF_SOURCE_DIR=/path/to/libheif
```

Then run:

```bash
scripts/heic_tests.sh all
```

The scripts can build the external validator into
`.heic-test-runs/validator-build` by default. Set
`LIBHEIF_DEC_BIN=/path/to/heif-dec` to reuse an existing validator binary
instead. The only auto-detected validator paths are under `.heic-test-assets/`
and `.heic-test-runs/`; explicit environment variables are left untouched.

Required command-line tools: `cargo`, `cmake`, `ffmpeg`, `ffprobe`, `shasum`,
`awk`, `find`, `sort`, and `/usr/bin/time`.

## Commands

Quick correctness pass:

```bash
scripts/heic_tests.sh verify --quick --require-exts heic,avif
```

Full correctness pass over the configured corpus:

```bash
scripts/heic_tests.sh verify --full --require-exts heic,avif
```

Performance checks:

```bash
scripts/heic_tests.sh bench-decode --full --files 12 --runs 5
scripts/heic_tests.sh bench-ingestion --full --files 12 --runs 5
scripts/heic_tests.sh bench-image --full --files 12 --runs 5
scripts/heic_tests.sh bench-stream --full --files 6 --runs 2 --workers 10 --iterations 4
```

Everything:

```bash
scripts/heic_tests.sh all
```

Generated reports and PNG artifacts are under `.heic-test-runs/`. Use
`--keep-artifacts` with `verify` when debugging a pixel mismatch.
