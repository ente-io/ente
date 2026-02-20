from __future__ import annotations

from time import perf_counter

import numpy as np

from ._runtime import ModelArtifact, create_ort_session, l2_normalize_rows


FACE_EMBEDDING_SIZE = 192


class FaceEmbeddingModel:
    def __init__(self, artifact: ModelArtifact) -> None:
        self.artifact = artifact
        self._session = create_ort_session(artifact.path)
        self._input_name = self._session.get_inputs()[0].name

    def embed(self, aligned_faces: np.ndarray) -> tuple[tuple[tuple[float, ...], ...], dict[str, float]]:
        if aligned_faces.size == 0:
            return (), {"face_embedding_inference": 0.0, "face_embedding": 0.0}

        inference_start = perf_counter()
        outputs = self._session.run(
            None,
            {self._input_name: np.asarray(aligned_faces, dtype=np.float32)},
        )
        inference_ms = (perf_counter() - inference_start) * 1000.0

        embeddings = np.asarray(outputs[0], dtype=np.float32)
        if embeddings.ndim != 2 or embeddings.shape[1] != FACE_EMBEDDING_SIZE:
            raise ValueError(
                f"Unexpected face embedding output shape {embeddings.shape}; expected [N, {FACE_EMBEDDING_SIZE}]"
            )

        normalized = l2_normalize_rows(embeddings)
        return (
            tuple(tuple(float(value) for value in row.tolist()) for row in normalized),
            {
                "face_embedding_inference": inference_ms,
                "face_embedding": inference_ms,
            },
        )
