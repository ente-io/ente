# ML Indexing Parity Test Plan (Android, iOS, Desktop) with Python Ground Truth

## Summary
Build an extensive, automated parity suite that validates full ML indexing outputs across Android, iOS, and desktop, and compares each against Python-generated ground truth.
The immediate goal is robust verification of current behavior (not pipeline convergence yet), so we can iterate safely now and later migrate to a shared Rust implementation with confidence.

## Context and Reference Map (for Implementing Agents)
Use this section as the primary onboarding map before touching code.

### Core mobile indexing flow (Dart/Flutter)
1. Orchestration and lifecycle:
- `mobile/apps/photos/lib/services/machine_learning/ml_service.dart`
2. Isolate model loading + inference dispatch:
- `mobile/apps/photos/lib/services/machine_learning/ml_indexing_isolate.dart`
3. End-to-end image analysis entrypoint (`analyzeImageStatic`):
- `mobile/apps/photos/lib/utils/ml_util.dart`
4. Image decode + preprocessing + alignment helpers:
- `mobile/apps/photos/lib/utils/image_ml_util.dart`
5. Face detection model wrapper:
- `mobile/apps/photos/lib/services/machine_learning/face_ml/face_detection/face_detection_service.dart`
6. Face embedding model wrapper:
- `mobile/apps/photos/lib/services/machine_learning/face_ml/face_embedding/face_embedding_service.dart`
7. Face pipeline runner:
- `mobile/apps/photos/lib/services/machine_learning/face_ml/face_recognition_service.dart`
8. CLIP image embedding wrapper:
- `mobile/apps/photos/lib/services/machine_learning/semantic_search/clip/clip_image_encoder.dart`
9. CLIP image pipeline callsite:
- `mobile/apps/photos/lib/services/machine_learning/semantic_search/semantic_search_service.dart`
10. ML versions:
- `mobile/apps/photos/lib/models/ml/ml_versions.dart`

### Android runtime path for mobile
1. ONNX plugin implementation:
- `mobile/apps/photos/plugins/onnx_dart/android/src/main/kotlin/io/ente/photos/onnx_dart/OnnxDartPlugin.kt`
2. Plugin wiring:
- `mobile/apps/photos/plugins/onnx_dart/pubspec.yaml`
- `mobile/apps/photos/plugins/onnx_dart/lib/onnx_dart_method_channel.dart`

### Desktop + web ML runtime path
1. Electron utility process ONNX runtime:
- `desktop/src/main/services/ml-worker.ts`
2. IPC-exposed ML interface types:
- `web/packages/base/types/ipc.ts`
3. Web worker orchestration used by desktop renderer:
- `web/packages/new/photos/services/ml/worker.ts`
4. CLIP logic in web layer:
- `web/packages/new/photos/services/ml/clip.ts`
5. Face detection/embedding/alignment in web layer:
- `web/packages/new/photos/services/ml/face.ts`
6. Image and math helpers in web layer:
- `web/packages/new/photos/services/ml/image.ts`
- `web/packages/new/photos/services/ml/math.ts`
7. Local ML DB + remote ML data handling:
- `web/packages/new/photos/services/ml/db.ts`
- `web/packages/new/photos/services/ml/ml-data.ts`

### Model/asset references and operational context
1. Mobile old-model cleanup list (useful for model naming/history):
- `mobile/apps/photos/lib/services/remote_assets_service.dart`
2. Desktop dependencies note (runtime choice):
- `desktop/docs/dependencies.md`

### Existing tests status (important baseline)
1. Mobile currently has no dedicated ML parity/inference tests in:
- `mobile/apps/photos/test`
- `mobile/apps/photos/integration_test`
2. Desktop currently has no dedicated ML test suite under:
- `desktop/`
3. Web ML logic lives in:
- `web/packages/new/photos/services/ml/`
  and currently lacks dedicated parity goldens/inference tests.

### CI patterns to mirror
1. Path-filtered workflows convention:
- `.github/workflows/mobile-lint.yml`
- `.github/workflows/web-lint.yml`
- `.github/workflows/desktop-lint.yml`

### Known behavior notes to keep in mind while implementing
1. Current platform implementations are not identical in all internals; parity suite should measure outcomes, not assume identical intermediate steps.
2. Ground truth setup should follow mobile behavior for preprocessing/postprocessing semantics in this phase.

## Agent Notes and Progress Tracker
This section is for implementation agents to keep a running log so handoffs stay low-friction.

### Workstream Checklist
- [x] W1: Define shared output schema (`file_id`, clip vector, detections, face embeddings, metadata)
- [ ] W2: Implement Python ground truth pipeline (`clip.py`, `face_detection.py`, `face_alignment.py`, `face_embedding.py`, `pipeline.py`)
- [x] W3: Add/define corpus manifest and storage layout under `infra/ml/ground_truth`
- [ ] W4: Implement desktop parity runner
- [ ] W5: Implement Android parity runner
- [ ] W6: Implement iOS parity runner
- [x] W7: Implement comparator and report generator
- [ ] W8: Implement one-command local orchestration (`run_suite.sh`)
- [ ] W9: Add selective CI workflow for indexing-related path changes
- [ ] W10: Document usage and maintenance (`README`, golden update instructions)

### Implementation Log
| Date (YYYY-MM-DD) | Agent | Change Summary | Files Touched | Validation Run | Next Step |
|---|---|---|---|---|---|
| 2026-02-13 | Codex (GPT-5) | Implemented shared parity result schema, comparator/report engine, bootstrap corpus manifest + deterministic golden generator, comparator CLI, suite runner scaffold, and pytest coverage for schema/comparator behavior across python/android/ios/desktop fixtures. | `infra/ml/ground_truth/schema.py`, `infra/ml/ground_truth/manifest.json`, `infra/ml/ground_truth/README.md`, `infra/ml/comparator/compare.py`, `infra/ml/tools/generate_goldens.py`, `infra/ml/tools/compare_parity_outputs.py`, `infra/ml/tools/run_suite.sh`, `infra/ml/tests/conftest.py`, `infra/ml/tests/test_schema.py`, `infra/ml/tests/test_comparator.py`, `infra/ml/.gitignore` | `uv run --project infra/ml --no-sync python infra/ml/tools/generate_goldens.py --manifest infra/ml/ground_truth/manifest.json --output-dir infra/ml/ground_truth/goldens`; `uv run --project infra/ml --no-sync --with pytest pytest infra/ml/tests/test_schema.py infra/ml/tests/test_comparator.py`; `uv run --project infra/ml --no-sync python infra/ml/tools/compare_parity_outputs.py --ground-truth infra/ml/ground_truth/goldens/results.json --platform-result desktop=infra/ml/ground_truth/goldens/results.json --output /tmp/ml_parity_compare_report.json`; `infra/ml/tools/run_suite.sh --suite smoke --platforms all --output-dir infra/ml/out/parity` | Implement real ONNX-backed Python pipeline modules (`clip.py`, `face_detection.py`, `face_alignment.py`, `face_embedding.py`, `pipeline.py`) and connect desktop/android/ios runners to emit schema outputs. |

### Decisions and Rationale Log
| Date | Decision | Rationale | Impacted Files |
|---|---|---|---|
| 2026-02-13 | Start with strict schema + comparator + contract tests before platform runner wiring. | Provides immediate, automated parity coverage and a stable JSON contract while platform-specific runner implementations are still pending. | `infra/ml/ground_truth/schema.py`, `infra/ml/comparator/compare.py`, `infra/ml/tests/test_schema.py`, `infra/ml/tests/test_comparator.py` |
| 2026-02-13 | Use deterministic bootstrap golden generation from manifest-defined corpus metadata for initial suite bring-up. | Allows end-to-end tool validation (`generate_goldens` -> comparator -> report) without waiting for full Python model pipeline completion. | `infra/ml/tools/generate_goldens.py`, `infra/ml/ground_truth/manifest.json`, `infra/ml/tools/run_suite.sh` |

### Open Questions / Blockers
| Date | Owner | Blocker | Unblocked By |
|---|---|---|---|
| 2026-02-13 | Codex (GPT-5) | Platform runners are not yet implemented (`desktop/scripts/ml_parity_runner.ts`, mobile integration parity tests), so `run_suite.sh` currently consumes platform outputs only when available. | Implement W4/W5/W6 runner outputs in shared schema and invoke them directly from `run_suite.sh`. |

### Handoff Checklist
- [x] Added brief implementation note to `Implementation Log`
- [x] Updated `Workstream Checklist` states
- [x] Recorded any non-obvious tradeoff in `Decisions and Rationale Log`
- [x] Listed unresolved blockers/questions
- [x] Included exact command(s) used for validation in log

## Goals
1. Verify CLIP image embeddings parity across Android, iOS, desktop, and Python ground truth.
2. Verify face detections parity (count, boxes, landmarks, scores) across platforms and ground truth.
3. Verify face embeddings parity across platforms and ground truth.
4. Cover a broad corpus (formats, content types, edge cases) with deterministic, repeatable checks.
5. Provide a single local command to run the suite and produce a clear report.
6. Run in CI only when indexing-related code changes.

## Non-Goals (Current Phase)
1. No forced mobile/desktop pipeline convergence in this phase.
2. No mandatory model/preprocessing rewrites before testing.
3. No broad always-on CI for all PRs.

## Current-State Strategy
Treat existing platform implementations as systems under test and validate their outputs against:
1. Each other (cross-platform parity).
2. Python ONNX ground truth (mobile behavior used as setup reference).

This gives immediate safety without blocking on architectural alignment work.

## Ground Truth Design (Python)
### Reference Principle
1. Follow current mobile indexing behavior as the reference while defining Python ground truth pipeline logic.
2. Keep implementation credible and production-like using established libraries.

### Python Stack
1. `onnxruntime` for model inference.
2. `opencv-python` (`cv2`) for resizing, interpolation, geometry transforms, warp-affine, and image handling.
3. `Pillow` for robust format decoding and EXIF orientation handling.
4. `numpy` for tensor ops and deterministic numeric handling (if needed).
5. `scipy` optional for matching utilities (if needed).

### Python Components
1. `ground_truth/clip.py`
- Decode + preprocess image according to mobile semantics.
- Run CLIP image encoder.
- L2 normalize output vector.

2. `ground_truth/face_detection.py`
- YOLO preprocess and inference.
- Postprocess including confidence filter, coordinate transforms, and NMS semantics mirroring mobile behavior.
- Deterministic ordering of detections.

3. `ground_truth/face_alignment.py`
- Similarity transform and affine warp for MobileFaceNet input preparation.
- Landmark normalization and blur computation aligned to mobile logic.

4. `ground_truth/face_embedding.py`
- Run MobileFaceNet inference on aligned crops.
- L2 normalize embeddings.

5. `ground_truth/pipeline.py`
- End-to-end orchestration per file:
  - decode -> face detection -> alignment/blur -> face embeddings -> clip embedding
- Emit normalized JSON output schema.

### Determinism Controls
1. Pin Python package versions.
2. Fix ORT provider and thread options where possible.
3. Explicitly control interpolation modes and border behaviors.
4. Canonicalize output ordering and JSON float formatting.

## Corpus and Ground Truth Storage
1. Corpus source: separate dedicated repo (as discussed).
2. Ground truth in main repo:
- `infra/ml/ground_truth/README.md`
- `infra/ml/ground_truth/manifest.json`
- `infra/ml/ground_truth/goldens/*.json`
3. Manifest includes:
- corpus item id, source path/key, file type, tags
- expected face count ranges (optional)
- thresholds per stage and per file class
- exclusions/known exceptions (if any)

## Common Output Interface (All Runners)
All runners emit the same schema:
1. `file_id`
2. `clip.embedding` (float[512], normalized)
3. `faces[]` sorted deterministically
4. `faces[].box` normalized `[x, y, width, height]`
5. `faces[].landmarks` normalized points
6. `faces[].score`
7. `faces[].embedding` (float[192], normalized)
8. `runner_metadata`:
- platform/runtime
- model names + hashes
- code revision
- timing info (optional)

## Platform Runners
1. Android runner (`mobile/apps/photos/integration_test/ml_parity_android_test.dart`)
- Use real app ML path (model loading + analyze pipeline).
- Emit JSON in common schema.

2. iOS runner (`mobile/apps/photos/integration_test/ml_parity_ios_test.dart`)
- Same as Android, using iOS runtime path.
- Emit JSON in common schema.

3. Desktop runner (`desktop/scripts/ml_parity_runner.ts`)
- Use desktop ML worker + web ML pipeline entrypoints.
- Emit JSON in common schema.

4. Python runner (`infra/ml/tools/generate_goldens.py`)
- Process corpus and generate/refresh goldens in common schema.

## Comparator and Acceptance Rules
## Threshold Policy (Dual Threshold)
1. Per-item strict checks.
2. Aggregate distribution checks (p95/p99/max).

### CLIP
1. Per-image cosine distance to ground truth <= `0.010`.
2. Cross-platform pairwise cosine distance <= `0.010`.
3. Aggregate percentile gates must pass.

### Face Detections
1. Match detections with deterministic assignment (IoU-based).
2. Face count mismatch fails.
3. Matched box IoU >= configured threshold (e.g. `0.98`).
4. Landmark normalized error <= configured threshold.
5. Score delta <= configured threshold.
6. Aggregate gates for detection metrics.

### Face Embeddings
1. For matched faces, cosine distance to ground truth <= configured threshold (e.g. `0.015`).
2. Cross-platform pairwise cosine distance <= same threshold.
3. Aggregate percentile gates must pass.

## One-Command Local Execution
Entrypoint: `infra/ml/tools/run_suite.sh`

Default behavior:
1. Ensure corpus present (sync/fetch helper).
2. Run/validate Python ground truth generation.
3. Run desktop, Android, iOS parity runners (attempt all).
4. Compare outputs and print unified report.
5. Clearly mark unavailable/failed platform runs.

Flags:
1. `--suite smoke|full`
2. `--platforms all|desktop|android|ios`
3. `--update-golden`
4. `--fail-on-missing-platform`
5. `--output-dir ...`

Target runtime: 10-20 minutes for full local run (with caching).

## CI Integration (Selective)
Workflow: `.github/workflows/ml-indexing-parity.yml`

Trigger policy:
1. `pull_request` only when indexing-related paths change.
2. `workflow_dispatch` for manual runs.

Jobs:
1. Desktop parity job.
2. Android parity job.
3. iOS parity job.
4. Aggregate compare/report job.

No automatic run for unrelated PRs.

## Test Scenarios
1. File format coverage:
- JPEG, PNG, HEIC/HEIF, WebP, AVIF/JXL (where supported), video thumbnails.
2. Content diversity:
- single face, many faces, no faces, low light, blur, backlit, occlusions.
3. Geometry stress:
- rotation, extreme aspect ratios, border-touching faces, tiny/large faces.
4. Decode/orientation edge cases:
- EXIF orientation variants and conversion fallbacks.
5. Determinism:
- repeated runs on same platform stay within epsilon.
6. Regression:
- model hash changes or substantial drift trigger explicit failures.

## Public Interfaces / Types Added
1. Shared JSON result schema for all runners/comparator.
2. Ground truth manifest schema.
3. Comparator report schema (machine-readable + human summary).

## Rollout
1. Phase 1: Build Python ground truth pipeline + schema + comparator + desktop runner.
2. Phase 2: Add Android/iOS runners and one-command orchestration.
3. Phase 3: Add selective PR CI workflow and threshold tuning on real corpus.
4. Phase 4: Expand corpus continuously and tighten thresholds where stable.

## Assumptions and Defaults
1. Corpus is maintained in a separate repo and fetched by tooling.
2. Ground truth files are committed in this repo and updated intentionally via PR.
3. Mobile behavior is the setup reference for ground-truth implementation details in this phase.
4. Missing local platform support is reported clearly by default, not automatically fatal unless strict mode is enabled.
