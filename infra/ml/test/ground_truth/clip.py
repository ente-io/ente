from __future__ import annotations

from time import perf_counter

import cv2
import numpy as np

from ._runtime import ModelArtifact, create_ort_session, l2_normalize_rows


CLIP_INPUT_WIDTH = 256
CLIP_INPUT_HEIGHT = 256


def preprocess_clip_image(image_rgb: np.ndarray) -> np.ndarray:
    if image_rgb.ndim != 3 or image_rgb.shape[2] != 3:
        raise ValueError("clip preprocessing expects an RGB image with shape [H, W, 3]")

    image_height, image_width = image_rgb.shape[:2]
    if image_height <= 0 or image_width <= 0:
        raise ValueError("clip preprocessing expects a non-empty image")

    scale = max(CLIP_INPUT_WIDTH / image_width, CLIP_INPUT_HEIGHT / image_height)
    scaled_width = int(round(image_width * scale))
    scaled_height = int(round(image_height * scale))

    interpolation = cv2.INTER_AREA if scale < 1.0 else cv2.INTER_LINEAR
    resized = cv2.resize(
        image_rgb,
        (scaled_width, scaled_height),
        interpolation=interpolation,
    )

    x_start = max(0, (scaled_width - CLIP_INPUT_WIDTH) // 2)
    y_start = max(0, (scaled_height - CLIP_INPUT_HEIGHT) // 2)
    x_end = x_start + CLIP_INPUT_WIDTH
    y_end = y_start + CLIP_INPUT_HEIGHT

    cropped = resized[y_start:y_end, x_start:x_end]
    if cropped.shape[:2] != (CLIP_INPUT_HEIGHT, CLIP_INPUT_WIDTH):
        raise ValueError(
            "clip center crop produced an unexpected shape "
            f"{cropped.shape[:2]} for scaled image {resized.shape[:2]}"
        )

    chw = np.transpose(cropped.astype(np.float32) / 255.0, (2, 0, 1))
    return np.ascontiguousarray(chw)


class ClipImageEncoder:
    def __init__(self, artifact: ModelArtifact) -> None:
        self.artifact = artifact
        self._session = create_ort_session(artifact.path)
        self._input_name = self._session.get_inputs()[0].name

    def encode(self, image_rgb: np.ndarray) -> tuple[tuple[float, ...], dict[str, float]]:
        preprocess_start = perf_counter()
        input_tensor = preprocess_clip_image(image_rgb)
        preprocess_ms = (perf_counter() - preprocess_start) * 1000.0

        inference_start = perf_counter()
        outputs = self._session.run(None, {self._input_name: input_tensor[np.newaxis, ...]})
        inference_ms = (perf_counter() - inference_start) * 1000.0

        raw_embedding = np.asarray(outputs[0], dtype=np.float32)[0]
        embedding = l2_normalize_rows(raw_embedding)

        return (
            tuple(float(value) for value in embedding.tolist()),
            {
                "clip_preprocess": preprocess_ms,
                "clip_inference": inference_ms,
                "clip": preprocess_ms + inference_ms,
            },
        )
