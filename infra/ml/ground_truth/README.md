# ML Parity Ground Truth

This directory stores bootstrap assets for the ML indexing parity suite:

- `manifest.json`: corpus definition and per-item metadata.
- `schema.py`: strict shared result schema used by all runners.

Runtime outputs (`goldens/*.json`, `goldens/results.json`, and
`infra/ml/out/parity/**`) are generated on demand and are gitignored.

## Dataset Source

The default corpus is sourced from:

- `https://github.com/ente-io/test-fixtures/tree/main/ml/indexing/v1`
- Canonical fixture metadata:
  `https://raw.githubusercontent.com/ente-io/test-fixtures/main/ml/indexing/v1/manifest.json`

`manifest.json` in this directory uses:

- `source`: local runtime path under `infra/ml/test_data/...`
- `source_url`: remote raw fixture URL used by `run_suite.sh` for download
- `source_sha256`: integrity check value used during download and generation

## Current Scope

The current generator (`tools/generate_goldens.py`) emits deterministic bootstrap
results so we can build and validate the cross-platform comparison harness before
the full ONNX-backed Python pipeline lands.

## Generate Goldens

```bash
uv run --project infra/ml python infra/ml/tools/generate_goldens.py \
  --manifest infra/ml/ground_truth/manifest.json \
  --output-dir infra/ml/out/parity/python
```

`generate_goldens.py` expects fixture files to already be present locally.
`run_suite.sh` is responsible for clearing `infra/ml/test_data/ml-indexing/v1`,
downloading fixtures, and then calling the generator.

## Compare Against Platforms

```bash
uv run --project infra/ml python infra/ml/tools/compare_parity_outputs.py \
  --ground-truth infra/ml/out/parity/python/results.json \
  --platform-result android=infra/ml/out/parity/android/results.json \
  --platform-result ios=infra/ml/out/parity/ios/results.json \
  --platform-result desktop=infra/ml/out/parity/desktop/results.json
```
