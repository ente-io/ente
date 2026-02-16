#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import sys
from typing import Any, Mapping

ML_DIR = Path(__file__).resolve().parents[1]
if str(ML_DIR) not in sys.path:
    sys.path.insert(0, str(ML_DIR))

from ground_truth.schema import ClipResult, FaceResult, ParityResult, RunnerMetadata


def _stable_bytes(seed: bytes, length: int) -> bytes:
    chunks: list[bytes] = []
    counter = 0
    while sum(len(chunk) for chunk in chunks) < length:
        digest = hashlib.sha256(seed + counter.to_bytes(4, "big")).digest()
        chunks.append(digest)
        counter += 1
    return b"".join(chunks)[:length]


def _stable_unit_vector(seed: bytes, length: int) -> tuple[float, ...]:
    raw = _stable_bytes(seed, length * 4)
    values = []
    for index in range(length):
        start = index * 4
        chunk = raw[start : start + 4]
        integer = int.from_bytes(chunk, "big", signed=False)
        values.append((integer / 2**31) - 1.0)

    norm = math.sqrt(sum(value * value for value in values))
    if norm == 0:
        values[0] = 1.0
        norm = 1.0
    return tuple(value / norm for value in values)


def _stable_float(seed: bytes, *, low: float, high: float, offset: int = 0) -> float:
    digest = hashlib.sha256(seed + offset.to_bytes(4, "big")).digest()
    integer = int.from_bytes(digest[:4], "big", signed=False)
    ratio = integer / 2**32
    return low + (high - low) * ratio


def _default_face(
    *,
    source_seed: bytes,
    face_index: int,
    face_count: int,
) -> dict[str, Any]:
    width = _stable_float(source_seed, low=0.18, high=0.35, offset=100 + face_index)
    height = _stable_float(source_seed, low=0.22, high=0.40, offset=200 + face_index)
    horizontal_step = max(0.02, (1.0 - width - 0.04) / max(face_count, 1))
    x = min(1.0 - width - 0.02, 0.02 + horizontal_step * face_index)
    y = _stable_float(source_seed, low=0.08, high=max(0.09, 1.0 - height - 0.08), offset=300 + face_index)

    # Keep landmark layout stable and human-shaped so downstream tools can test geometry.
    landmarks = [
        [x + width * 0.30, y + height * 0.38],
        [x + width * 0.70, y + height * 0.38],
        [x + width * 0.50, y + height * 0.58],
        [x + width * 0.34, y + height * 0.78],
        [x + width * 0.66, y + height * 0.78],
    ]

    score = _stable_float(source_seed, low=0.85, high=0.995, offset=400 + face_index)
    return {
        "box": [x, y, width, height],
        "landmarks": landmarks,
        "score": score,
    }


def _git_revision(default: str = "local") -> str:
    try:
        completed = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True,
            text=True,
            check=True,
        )
    except (subprocess.SubprocessError, FileNotFoundError):
        return default
    return completed.stdout.strip() or default


def _build_result(item: Mapping[str, Any], *, ml_dir: Path, code_revision: str) -> ParityResult:
    file_id = str(item["file_id"])
    source_relative_path = Path(str(item["source"]))
    source_path = ml_dir / source_relative_path
    source_bytes = source_path.read_bytes()
    source_seed = file_id.encode("utf-8") + source_bytes

    clip_embedding = _stable_unit_vector(source_seed + b":clip", 512)
    clip_result = ClipResult(embedding=clip_embedding)

    configured_faces = item.get("bootstrap_faces")
    if configured_faces is None:
        face_count = int(item.get("bootstrap_face_count", 0))
        configured_faces = [
            _default_face(source_seed=source_seed, face_index=idx, face_count=face_count)
            for idx in range(face_count)
        ]

    faces = []
    for face_index, face_payload in enumerate(configured_faces):
        face_seed = source_seed + f":face:{face_index}".encode("utf-8")
        faces.append(
            FaceResult(
                box=tuple(face_payload["box"]),
                landmarks=tuple(tuple(point) for point in face_payload["landmarks"]),
                score=float(face_payload["score"]),
                embedding=_stable_unit_vector(face_seed + b":embedding", 192),
            )
        )

    metadata = RunnerMetadata(
        platform="python",
        runtime="bootstrap-deterministic",
        models={
            "clip": "bootstrap-mobileclip-sha256:synthetic",
            "face_detection": "bootstrap-yolov5face-sha256:synthetic",
            "face_embedding": "bootstrap-mobilefacenet-sha256:synthetic",
        },
        code_revision=code_revision,
        timing_ms={"total": float(len(source_bytes) % 97)},
    )

    return ParityResult(
        file_id=file_id,
        clip=clip_result,
        faces=tuple(faces),
        runner_metadata=metadata,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate bootstrap parity golden files from manifest entries.",
    )
    parser.add_argument(
        "--manifest",
        default="infra/ml/ground_truth/manifest.json",
        help="Path to manifest.json file.",
    )
    parser.add_argument(
        "--output-dir",
        default="infra/ml/ground_truth/goldens",
        help="Directory where generated golden files are written.",
    )
    args = parser.parse_args()

    ml_dir = Path(__file__).resolve().parents[1]
    repo_root = ml_dir.parents[1]

    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = repo_root / manifest_path

    output_dir = Path(args.output_dir)
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir

    manifest_payload = json.loads(manifest_path.read_text())
    items = manifest_payload.get("items", [])
    if not items:
        raise ValueError("Manifest has no items")

    code_revision = _git_revision()
    results = tuple(_build_result(item, ml_dir=ml_dir, code_revision=code_revision) for item in items)

    output_dir.mkdir(parents=True, exist_ok=True)
    for result in results:
        file_name = result.file_id.replace("/", "__")
        (output_dir / f"{file_name}.json").write_text(
            json.dumps(result.to_dict(), indent=2, sort_keys=True),
        )

    combined_payload = {
        "platform": "python",
        "results": [result.to_dict() for result in results],
    }
    combined_path = output_dir / "results.json"
    combined_path.write_text(json.dumps(combined_payload, indent=2, sort_keys=True))

    print(f"Generated {len(results)} bootstrap golden result(s) at {output_dir}")
    print(f"Combined output: {combined_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
