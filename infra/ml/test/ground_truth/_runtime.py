from __future__ import annotations

from dataclasses import dataclass
import hashlib
import os
from pathlib import Path
import sys
import tempfile
from typing import Final
import warnings

import cv2
import numpy as np
import onnxruntime as ort
from PIL import Image, ImageOps
import requests

try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
except Exception:
    # HEIF support is optional at import time; decode errors surface later with context.
    pass


DEFAULT_MODEL_BASE_URL: Final[str] = "https://models.ente.io/"
DEFAULT_PADDING_RGB: Final[tuple[int, int, int]] = (114, 114, 114)
ALLOW_OPENCV_FALLBACK_ENV: Final[str] = "ML_PARITY_ALLOW_OPENCV_DECODE_FALLBACK"


@dataclass(frozen=True)
class ModelArtifact:
    file_name: str
    path: Path
    sha256: str
    etag: str | None


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def ensure_model(
    *,
    file_name: str,
    cache_dir: Path,
    base_url: str = DEFAULT_MODEL_BASE_URL,
) -> ModelArtifact:
    cache_dir.mkdir(parents=True, exist_ok=True)
    model_path = cache_dir / file_name

    if model_path.exists() and model_path.stat().st_size > 0:
        return ModelArtifact(
            file_name=file_name,
            path=model_path,
            sha256=_sha256_file(model_path),
            etag=None,
        )

    model_url = f"{base_url.rstrip('/')}/{file_name}"
    with requests.get(model_url, stream=True, timeout=(10, 300)) as response:
        response.raise_for_status()
        etag = response.headers.get("ETag")

        with tempfile.NamedTemporaryFile(
            dir=cache_dir,
            prefix=f"{file_name}.",
            suffix=".tmp",
            delete=False,
        ) as tmp_file:
            tmp_path = Path(tmp_file.name)
            for chunk in response.iter_content(chunk_size=1024 * 1024):
                if chunk:
                    tmp_file.write(chunk)

    tmp_path.replace(model_path)
    return ModelArtifact(
        file_name=file_name,
        path=model_path,
        sha256=_sha256_file(model_path),
        etag=etag,
    )


def create_ort_session(model_path: Path) -> ort.InferenceSession:
    options = ort.SessionOptions()
    options.inter_op_num_threads = 1
    options.intra_op_num_threads = 1
    options.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

    return ort.InferenceSession(
        str(model_path),
        sess_options=options,
        providers=["CPUExecutionProvider"],
    )


def l2_normalize_rows(values: np.ndarray) -> np.ndarray:
    values = np.asarray(values, dtype=np.float32)
    if values.ndim == 1:
        norm = float(np.linalg.norm(values))
        if norm == 0.0:
            raise ValueError("cannot normalize zero vector")
        return values / norm

    norms = np.linalg.norm(values, axis=1, keepdims=True)
    if np.any(norms == 0.0):
        raise ValueError("cannot normalize zero vector rows")
    return values / norms


def decode_image_rgb(source_path: Path) -> np.ndarray:
    source_path = source_path.expanduser().resolve()

    try:
        with Image.open(source_path) as image:
            image = ImageOps.exif_transpose(image)
            image = image.convert("RGB")
            pixels = np.array(image, dtype=np.uint8, copy=True)
            return np.ascontiguousarray(pixels)
    except Exception as pillow_error:
        fallback_enabled = os.environ.get(ALLOW_OPENCV_FALLBACK_ENV, "").strip().lower() in {
            "1",
            "true",
            "yes",
            "on",
        }
        if not fallback_enabled:
            suffix = source_path.suffix.lower()
            heif_note = (
                " Install pillow-heif to decode HEIC/HEIF files."
                if suffix in {".heic", ".heif"}
                else ""
            )
            raise RuntimeError(
                f"Failed to decode image '{source_path}' with Pillow ({pillow_error}). "
                "OpenCV decode fallback is DISABLED by default because it may diverge from "
                "Pillow EXIF-orientation behavior and can break parity trust."
                f"{heif_note} To force fallback anyway, set {ALLOW_OPENCV_FALLBACK_ENV}=1."
            ) from pillow_error

        warning_message = (
            f"FALLING BACK to OpenCV decode for '{source_path}' after Pillow failure "
            f"({pillow_error}). This can diverge from Pillow EXIF-orientation semantics and "
            "may produce unreliable parity results."
        )
        warnings.warn(warning_message, RuntimeWarning, stacklevel=2)
        print(f"[ml_parity][WARNING] {warning_message}", file=sys.stderr)

        raw = np.fromfile(str(source_path), dtype=np.uint8)
        decoded = cv2.imdecode(raw, cv2.IMREAD_COLOR)
        if decoded is None:
            suffix = source_path.suffix.lower()
            heif_note = (
                " Install pillow-heif to decode HEIC/HEIF files."
                if suffix in {".heic", ".heif"}
                else ""
            )
            raise RuntimeError(
                f"Failed to decode image '{source_path}' with Pillow ({pillow_error})"
                f" and OpenCV.{heif_note}"
            ) from pillow_error

        rgb = cv2.cvtColor(decoded, cv2.COLOR_BGR2RGB)
        return np.ascontiguousarray(rgb)
