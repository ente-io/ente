# ML Parity Ground Truth

This directory stores bootstrap assets for the ML indexing parity suite:

- `manifest.json`: corpus definition and per-item metadata.
- `goldens/*.json`: per-item parity outputs in the shared schema.
- `goldens/results.json`: combined output used by the comparator.
- `schema.py`: strict shared result schema used by all runners.

## Current Scope

The current generator (`tools/generate_goldens.py`) emits deterministic bootstrap
results so we can build and validate the cross-platform comparison harness before
the full ONNX-backed Python pipeline lands.

## Generate Goldens

```bash
uv run --project infra/ml python infra/ml/tools/generate_goldens.py \
  --manifest infra/ml/ground_truth/manifest.json \
  --output-dir infra/ml/ground_truth/goldens
```

## Compare Against Platforms

```bash
uv run --project infra/ml python infra/ml/tools/compare_parity_outputs.py \
  --ground-truth infra/ml/ground_truth/goldens/results.json \
  --platform-result android=infra/ml/out/parity/android/results.json \
  --platform-result ios=infra/ml/out/parity/ios/results.json \
  --platform-result desktop=infra/ml/out/parity/desktop/results.json
```
