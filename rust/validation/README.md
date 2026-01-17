# ente-validation

Validation and benchmarks for `ente-core` against libsodium.

## Validation suite

```bash
cargo run -p ente-validation --bin ente-validation
```

Covers cross-implementation checks for secretbox, stream, sealed box, KDF,
Argon2id, and full auth flow.

## Benchmarks

```bash
cargo run -p ente-validation --bin bench
cargo run -p ente-validation --bin bench --release
```

Bench cases include secretbox (1 MiB), stream (1 MiB / 50 MiB), Argon2id,
and auth signup/login (interactive parameters).

To write JSON output:

```bash
BENCH_JSON=bench-rust.json cargo run -p ente-validation --bin bench --release
```

## WASM Benchmarks (rust-core vs JS)

Build the wasm bench crate (requires wasm-pack):

```bash
wasm-pack build --target nodejs rust/validation/wasm
```

Install JS dependencies:

```bash
cd rust/validation/js
npm install
```

Run the WASM benchmark (rust-core wasm vs libsodium-wrappers-sumo wasm):

```bash
node rust/validation/js/bench-wasm.mjs
```

To write JSON output:

```bash
BENCH_JSON=bench-wasm.json node rust/validation/js/bench-wasm.mjs
```

## WASM Benchmarks (Browser)

Build the wasm bench crate for the browser:

```bash
wasm-pack build --target web rust/validation/wasm
```

Start a local static server from `rust/validation/` (required for WASM loading):

```bash
cd rust/validation
python3 -m http.server 8000
```

Open the benchmark page in Chrome (results render on the page):

```text
http://localhost:8000/js/bench-wasm-browser.html
```

The page includes warmup/iteration controls and a toggle to run Rust WASM,
libsodium WASM, or both. It loads libsodium from a CDN (no bundler required).

## Requirements

The validation suite uses `libsodium-sys-stable`. Ensure libsodium builds
successfully in your environment (CI toolchain or local install).
