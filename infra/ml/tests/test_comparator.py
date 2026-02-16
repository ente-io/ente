from __future__ import annotations

import math

from comparator.compare import (
    ThresholdConfig,
    compare_platform_matrix,
    compare_result_sets,
)
from ground_truth.schema import ClipResult, FaceResult, ParityResult, RunnerMetadata


def _unit_vector(length: int, seed: int) -> tuple[float, ...]:
    values = [(((index + 5) * (seed + 13)) % 67) - 33 for index in range(length)]
    norm = math.sqrt(sum(value * value for value in values))
    return tuple(value / norm for value in values)


def _jittered_vector(vector: tuple[float, ...], *, index: int, delta: float) -> tuple[float, ...]:
    mutable = list(vector)
    mutable[index] += delta
    norm = math.sqrt(sum(value * value for value in mutable))
    return tuple(value / norm for value in mutable)


def _metadata(platform: str) -> RunnerMetadata:
    return RunnerMetadata(
        platform=platform,
        runtime="pytest",
        models={
            "clip": "clip-hash",
            "face_detection": "fd-hash",
            "face_embedding": "fe-hash",
        },
        code_revision="deadbee",
    )


def _face(seed: int, *, x: float, y: float, score: float) -> FaceResult:
    return FaceResult(
        box=(x, y, 0.22, 0.24),
        landmarks=(
            (x + 0.06, y + 0.09),
            (x + 0.16, y + 0.09),
            (x + 0.11, y + 0.14),
            (x + 0.07, y + 0.20),
            (x + 0.15, y + 0.20),
        ),
        score=score,
        embedding=_unit_vector(192, seed=seed),
    )


def _result(
    *,
    file_id: str,
    platform: str,
    clip_seed: int,
    faces: tuple[FaceResult, ...],
) -> ParityResult:
    return ParityResult(
        file_id=file_id,
        clip=ClipResult(embedding=_unit_vector(512, seed=clip_seed)),
        faces=faces,
        runner_metadata=_metadata(platform),
    )


def test_compare_result_sets_passes_when_within_thresholds() -> None:
    reference_faces = (_face(100, x=0.22, y=0.10, score=0.95),)
    reference = _result(
        file_id="man.jpeg",
        platform="python",
        clip_seed=10,
        faces=reference_faces,
    )

    candidate_face = FaceResult(
        box=(0.2205, 0.101, 0.22, 0.24),
        landmarks=(
            (0.279, 0.188),
            (0.381, 0.188),
            (0.331, 0.241),
            (0.292, 0.300),
            (0.367, 0.300),
        ),
        score=0.952,
        embedding=_jittered_vector(reference_faces[0].embedding, index=0, delta=0.001),
    )
    candidate = ParityResult(
        file_id="man.jpeg",
        clip=ClipResult(
            embedding=_jittered_vector(reference.clip.embedding, index=0, delta=0.001)
        ),
        faces=(candidate_face,),
        runner_metadata=_metadata("android"),
    )

    report = compare_result_sets(
        reference_platform="python",
        candidate_platform="android",
        reference_results={reference.file_id: reference},
        candidate_results={candidate.file_id: candidate},
    )

    assert report.passed is True
    assert report.findings == ()
    assert report.aggregates["clip_cosine_distance"].count == 1


def test_compare_result_sets_fails_on_clip_drift() -> None:
    reference = _result(
        file_id="people.jpeg",
        platform="python",
        clip_seed=1,
        faces=(_face(200, x=0.2, y=0.1, score=0.91),),
    )
    candidate = _result(
        file_id="people.jpeg",
        platform="ios",
        clip_seed=999,
        faces=(_face(200, x=0.2, y=0.1, score=0.91),),
    )

    report = compare_result_sets(
        reference_platform="python",
        candidate_platform="ios",
        reference_results={reference.file_id: reference},
        candidate_results={candidate.file_id: candidate},
    )

    assert report.passed is False
    assert any(finding.metric == "clip_cosine_distance" for finding in report.findings)


def test_compare_result_sets_fails_on_face_count_mismatch() -> None:
    reference = _result(
        file_id="people.jpeg",
        platform="python",
        clip_seed=4,
        faces=(
            _face(10, x=0.2, y=0.1, score=0.9),
            _face(11, x=0.5, y=0.2, score=0.87),
        ),
    )
    candidate = _result(
        file_id="people.jpeg",
        platform="desktop",
        clip_seed=4,
        faces=(_face(10, x=0.2, y=0.1, score=0.9),),
    )

    report = compare_result_sets(
        reference_platform="python",
        candidate_platform="desktop",
        reference_results={reference.file_id: reference},
        candidate_results={candidate.file_id: candidate},
    )

    assert report.passed is False
    assert any(finding.metric == "face_count" for finding in report.findings)


def test_aggregate_gate_failure_is_reported() -> None:
    reference_results = {}
    candidate_results = {}
    for index, delta in enumerate((0.0, 0.001, 0.04)):
        file_id = f"file-{index}.jpeg"
        reference = _result(
            file_id=file_id,
            platform="python",
            clip_seed=33 + index,
            faces=(_face(50 + index, x=0.2, y=0.2, score=0.95),),
        )
        if index == 2:
            candidate_clip = tuple(-value for value in reference.clip.embedding)
        else:
            candidate_clip = _jittered_vector(reference.clip.embedding, index=0, delta=delta)
        candidate = ParityResult(
            file_id=file_id,
            clip=ClipResult(embedding=candidate_clip),
            faces=reference.faces,
            runner_metadata=_metadata("android"),
        )
        reference_results[file_id] = reference
        candidate_results[file_id] = candidate

    report = compare_result_sets(
        reference_platform="python",
        candidate_platform="android",
        reference_results=reference_results,
        candidate_results=candidate_results,
        thresholds=ThresholdConfig(clip_cosine_distance=0.01),
    )

    assert report.passed is False
    assert any(finding.file_id == "*aggregate*" for finding in report.findings)


def test_compare_platform_matrix_includes_pairwise_reports() -> None:
    reference = _result(
        file_id="man.jpeg",
        platform="python",
        clip_seed=6,
        faces=(_face(200, x=0.25, y=0.12, score=0.9),),
    )
    android = ParityResult(
        file_id=reference.file_id,
        clip=ClipResult(embedding=_jittered_vector(reference.clip.embedding, index=0, delta=0.001)),
        faces=reference.faces,
        runner_metadata=_metadata("android"),
    )
    ios = ParityResult(
        file_id=reference.file_id,
        clip=ClipResult(embedding=_jittered_vector(reference.clip.embedding, index=1, delta=0.001)),
        faces=reference.faces,
        runner_metadata=_metadata("ios"),
    )
    desktop = ParityResult(
        file_id=reference.file_id,
        clip=ClipResult(embedding=_jittered_vector(reference.clip.embedding, index=2, delta=0.001)),
        faces=reference.faces,
        runner_metadata=_metadata("desktop"),
    )

    reports = compare_platform_matrix(
        {
            "python": (reference,),
            "android": (android,),
            "ios": (ios,),
            "desktop": (desktop,),
        }
    )

    assert len(reports) == 6
    assert all(report.passed for report in reports)
