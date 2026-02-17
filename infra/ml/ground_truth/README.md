# ML Parity Ground Truth

This directory stores the Python ground-truth assets for the ML indexing parity suite:

- `manifest.json`: corpus definition and per-item metadata.
- `schema.py`: strict shared result schema used by all runners.
- `clip.py`, `face_detection.py`, `face_alignment.py`, `face_embedding.py`, `pipeline.py`:
  ONNX-backed Python reference pipeline that mirrors the mobile `analyzeImageStatic`
  flow using Pillow + OpenCV + ONNX Runtime.

Runtime outputs (`goldens/*.json`, `goldens/results.json`, and
`infra/ml/out/parity/**`) are generated on demand and are gitignored.

## Dataset Source

The default corpus is sourced from:

- `https://github.com/laurenspriem/test-fixtures/tree/ml_more_test_data/ml/indexing/v1`
- Canonical fixture metadata:
  `https://raw.githubusercontent.com/laurenspriem/test-fixtures/ml_more_test_data/ml/indexing/v1/manifest.json`

`manifest.json` in this directory uses:

- `source`: local runtime path under `infra/ml/test_data/...`
- `source_url`: remote raw fixture URL used by `run_suite.sh` for download
- `source_sha256`: integrity check value used during download and generation

## ONNX Models

`generate_goldens.py` downloads and caches the mobile indexing ONNX models under
`infra/ml/.cache/onnx_models/`:

- `mobileclip_s2_image.onnx`
- `yolov5s_face_640_640_dynamic.onnx`
- `mobilefacenet_opset15.onnx`

HEIC/HEIF decoding requires the `pillow-heif` plugin (declared in
`infra/ml/pyproject.toml`).

## Generate Goldens

```bash
uv run --project infra/ml --no-sync --with pillow-heif python infra/ml/tools/generate_goldens.py \
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
