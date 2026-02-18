# ML Indexing Parity Test Suite

This directory contains the ML indexing parity framework for Android, iOS, desktop, and Python ground truth.

## Layout

- `ml-indexing-parity-test-plan.md`: rollout plan and progress tracker.
- `ground_truth/`: schema, manifest, and ONNX-backed Python pipeline.
- `comparator/`: parity comparison engine and threshold checks.
- `tools/`: suite orchestration and CLI entrypoints.
- `tests/`: pytest coverage for schema/comparator behavior.
- Runtime-only artifacts (gitignored): `test_data/`, `out/`, `.cache/`.

## Prerequisites

- Python + `uv`
- Node/Yarn (desktop parity)
- Flutter SDK (Android/iOS parity)
- Android emulator/device and iOS simulator/device when running mobile parity

## Local Run (One Command)

```bash
bash infra/ml/test/tools/run_suite.sh --suite smoke --platforms all
```

Common flags:

- `--suite smoke|full`
- `--platforms all|desktop|android|ios`
- `--fail-on-missing-platform`
- `--allow-empty-comparison`
- `--output-dir <path>`
- `--verbose` (stream full runner/comparator logs to terminal)

Outputs go to `infra/ml/test/out/parity/` by default, including:

- `comparison_report.json` (machine-readable comparison output)
- `parity_report.html` (readable HTML report with per-file metrics for both pass and fail files)

`run_suite.sh` compares each available platform against Python ground truth (`python -> <platform>`); non-ground-truth pairwise comparisons are excluded by default.

## Manual CI Run

Workflow: `.github/workflows/ml-indexing-parity.yml`

Run via `workflow_dispatch` and choose:

- `suite`
- `platforms`
- strictness flags
- optional explicit Android/iOS device IDs

CI uploads artifacts from `infra/ml/test/out/parity/**`.

## Golden Update / Maintenance

Goldens are runtime artifacts and are not committed.

Use this process when corpus/threshold/model behavior changes intentionally:

1. Update corpus metadata or thresholds in `infra/ml/test/ground_truth/manifest.json` (and comparator logic if needed).
2. Regenerate and compare with a real run:

```bash
bash infra/ml/test/tools/run_suite.sh --suite full --platforms all --output-dir infra/ml/test/out/parity
```

3. Review `infra/ml/test/out/parity/parity_report.html`, `comparison_report.json`, and per-platform `results.json` files.
4. If drift is expected, adjust thresholds/known exceptions and rerun until stable.
5. Commit code/config/docs updates only; do not commit generated `out/`, `test_data/`, or cache artifacts.
