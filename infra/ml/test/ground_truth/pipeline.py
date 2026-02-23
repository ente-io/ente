from __future__ import annotations

from pathlib import Path
from time import perf_counter
from typing import Mapping

from ._runtime import DEFAULT_MODEL_BASE_URL, decode_image_rgb, ensure_model
from .clip import ClipImageEncoder
from .face_alignment import FaceAligner
from .face_detection import FaceDetectionModel
from .face_embedding import FaceEmbeddingModel
from .schema import ClipResult, FaceResult, ParityResult, RunnerMetadata


MODEL_FILE_NAMES = {
    "clip": "mobileclip_s2_image.onnx",
    "face_detection": "yolov5s_face_640_640_dynamic.onnx",
    "face_embedding": "mobilefacenet_opset15.onnx",
}


class GroundTruthPipeline:
    def __init__(
        self,
        *,
        model_cache_dir: Path,
        model_base_url: str = DEFAULT_MODEL_BASE_URL,
    ) -> None:
        self._model_cache_dir = model_cache_dir
        self._model_base_url = model_base_url

        self._artifacts = {
            model_name: ensure_model(
                file_name=file_name,
                cache_dir=self._model_cache_dir,
                base_url=self._model_base_url,
            )
            for model_name, file_name in MODEL_FILE_NAMES.items()
        }

        self._clip_encoder = ClipImageEncoder(self._artifacts["clip"])
        self._face_detector = FaceDetectionModel(self._artifacts["face_detection"])
        self._face_aligner = FaceAligner()
        self._face_embedding_model = FaceEmbeddingModel(self._artifacts["face_embedding"])

    @property
    def model_metadata(self) -> Mapping[str, str]:
        return {
            model_name: f"{artifact.file_name}:sha256:{artifact.sha256}"
            for model_name, artifact in self._artifacts.items()
        }

    def analyze_image(
        self,
        *,
        file_id: str,
        source_path: Path,
        code_revision: str,
    ) -> ParityResult:
        timings: dict[str, float] = {}
        total_start = perf_counter()

        decode_start = perf_counter()
        image_rgb = decode_image_rgb(source_path)
        timings["decode"] = (perf_counter() - decode_start) * 1000.0

        detections, detection_timings = self._face_detector.detect(image_rgb)
        timings.update(detection_timings)

        aligned_faces, alignment_timings = self._face_aligner.align(image_rgb, detections)
        timings.update(alignment_timings)

        embeddings, embedding_timings = self._face_embedding_model.embed(aligned_faces)
        timings.update(embedding_timings)

        clip_embedding, clip_timings = self._clip_encoder.encode(image_rgb)
        timings.update(clip_timings)

        if len(embeddings) != len(detections):
            raise ValueError(
                "Face embedding count mismatch: "
                f"detections={len(detections)} embeddings={len(embeddings)}"
            )

        faces = []
        for detection, embedding in zip(detections, embeddings, strict=True):
            x_min, y_min, x_max, y_max = detection.box_xyxy
            faces.append(
                FaceResult(
                    box=(x_min, y_min, max(0.0, x_max - x_min), max(0.0, y_max - y_min)),
                    landmarks=detection.landmarks,
                    score=detection.score,
                    embedding=embedding,
                )
            )

        timings["total"] = (perf_counter() - total_start) * 1000.0

        runner_metadata = RunnerMetadata(
            platform="python",
            runtime="onnxruntime-cpu",
            models=dict(self.model_metadata),
            code_revision=code_revision,
            timing_ms=timings,
        )

        return ParityResult(
            file_id=file_id,
            clip=ClipResult(embedding=clip_embedding),
            faces=tuple(faces),
            runner_metadata=runner_metadata,
        )
