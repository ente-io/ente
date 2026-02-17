from __future__ import annotations

from dataclasses import dataclass
import itertools
import math
from typing import Any, Mapping, Sequence

from ground_truth.schema import FaceResult, ParityResult


def _l2_norm(values: Sequence[float]) -> float:
    return math.sqrt(sum(value * value for value in values))


def cosine_distance(left: Sequence[float], right: Sequence[float]) -> float:
    if len(left) != len(right):
        raise ValueError("cosine distance vectors must have equal dimensions")
    dot = sum(x * y for x, y in zip(left, right, strict=True))
    denominator = _l2_norm(left) * _l2_norm(right)
    if denominator == 0:
        raise ValueError("cosine distance cannot be computed for zero vectors")
    similarity = dot / denominator
    similarity = max(-1.0, min(1.0, similarity))
    return 1.0 - similarity


def _box_iou(left: Sequence[float], right: Sequence[float]) -> float:
    lx, ly, lw, lh = left
    rx, ry, rw, rh = right

    left_x2 = lx + lw
    left_y2 = ly + lh
    right_x2 = rx + rw
    right_y2 = ry + rh

    inter_x1 = max(lx, rx)
    inter_y1 = max(ly, ry)
    inter_x2 = min(left_x2, right_x2)
    inter_y2 = min(left_y2, right_y2)

    inter_w = max(0.0, inter_x2 - inter_x1)
    inter_h = max(0.0, inter_y2 - inter_y1)
    inter_area = inter_w * inter_h
    left_area = max(0.0, lw * lh)
    right_area = max(0.0, rw * rh)

    denominator = left_area + right_area - inter_area
    if denominator <= 0:
        return 0.0

    return inter_area / denominator


def _landmark_error(left: Sequence[Sequence[float]], right: Sequence[Sequence[float]]) -> float:
    if len(left) != len(right):
        raise ValueError("landmark count mismatch")
    if not left:
        return 0.0

    distances = []
    for left_point, right_point in zip(left, right, strict=True):
        dx = left_point[0] - right_point[0]
        dy = left_point[1] - right_point[1]
        distances.append(math.sqrt(dx * dx + dy * dy))

    return sum(distances) / len(distances)


def _percentile(values: Sequence[float], percentile: float) -> float:
    if not values:
        return 0.0

    sorted_values = sorted(values)
    if len(sorted_values) == 1:
        return sorted_values[0]

    rank = (len(sorted_values) - 1) * (percentile / 100.0)
    lower_index = math.floor(rank)
    upper_index = math.ceil(rank)
    if lower_index == upper_index:
        return sorted_values[lower_index]

    lower_value = sorted_values[lower_index]
    upper_value = sorted_values[upper_index]
    weight = rank - lower_index
    return lower_value + (upper_value - lower_value) * weight


@dataclass(frozen=True)
class ThresholdConfig:
    clip_cosine_distance: float = 0.010
    cross_platform_clip_cosine_distance: float = 0.010
    face_embedding_cosine_distance: float = 0.015
    box_iou_threshold: float = 0.98
    landmark_error_threshold: float = 0.03
    score_delta_threshold: float = 0.10

    def to_dict(self) -> dict[str, float]:
        return {
            "clip_cosine_distance": self.clip_cosine_distance,
            "cross_platform_clip_cosine_distance": self.cross_platform_clip_cosine_distance,
            "face_embedding_cosine_distance": self.face_embedding_cosine_distance,
            "box_iou_threshold": self.box_iou_threshold,
            "landmark_error_threshold": self.landmark_error_threshold,
            "score_delta_threshold": self.score_delta_threshold,
        }


@dataclass(frozen=True)
class AggregateMetric:
    count: int
    p95: float
    p99: float
    max: float
    threshold: float
    passed: bool

    def to_dict(self) -> dict[str, float | int | bool]:
        return {
            "count": self.count,
            "p95": self.p95,
            "p99": self.p99,
            "max": self.max,
            "threshold": self.threshold,
            "passed": self.passed,
        }


@dataclass(frozen=True)
class ComparisonFinding:
    file_id: str
    metric: str
    message: str
    value: float | None = None
    threshold: float | None = None

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "file_id": self.file_id,
            "metric": self.metric,
            "message": self.message,
        }
        if self.value is not None:
            payload["value"] = self.value
        if self.threshold is not None:
            payload["threshold"] = self.threshold
        return payload


@dataclass(frozen=True)
class FileComparisonStatus:
    file_id: str
    passed: bool
    failures: tuple[ComparisonFinding, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "file_id": self.file_id,
            "passed": self.passed,
            "failure_count": len(self.failures),
            "failures": [failure.to_dict() for failure in self.failures],
        }


@dataclass(frozen=True)
class ComparisonReport:
    reference_platform: str
    candidate_platform: str
    total_reference_files: int
    checked_files: int
    missing_files: tuple[str, ...]
    extra_files: tuple[str, ...]
    aggregates: Mapping[str, AggregateMetric]
    findings: tuple[ComparisonFinding, ...]
    file_statuses: tuple[FileComparisonStatus, ...]
    passing_files: tuple[str, ...]
    failing_files: tuple[str, ...]
    passed: bool

    def to_dict(self) -> dict[str, Any]:
        file_summary = {
            "total_reference_files": self.total_reference_files,
            "checked_files": self.checked_files,
            "pass_count": len(self.passing_files),
            "fail_count": len(self.failing_files),
            "passing_files": list(self.passing_files),
            "failing_files": list(self.failing_files),
        }
        return {
            "reference_platform": self.reference_platform,
            "candidate_platform": self.candidate_platform,
            "total_reference_files": self.total_reference_files,
            "checked_files": self.checked_files,
            "missing_files": list(self.missing_files),
            "extra_files": list(self.extra_files),
            "aggregates": {
                metric_name: metric.to_dict()
                for metric_name, metric in self.aggregates.items()
            },
            "findings": [finding.to_dict() for finding in self.findings],
            "file_summary": file_summary,
            "file_statuses": [file_status.to_dict() for file_status in self.file_statuses],
            "passing_files": list(self.passing_files),
            "failing_files": list(self.failing_files),
            "passed": self.passed,
        }


def _make_aggregate(values: list[float], threshold: float) -> AggregateMetric:
    if not values:
        return AggregateMetric(
            count=0,
            p95=0.0,
            p99=0.0,
            max=0.0,
            threshold=threshold,
            passed=True,
        )

    p95 = _percentile(values, 95.0)
    p99 = _percentile(values, 99.0)
    maximum = max(values)
    passed = p95 <= threshold and p99 <= threshold and maximum <= threshold
    return AggregateMetric(
        count=len(values),
        p95=p95,
        p99=p99,
        max=maximum,
        threshold=threshold,
        passed=passed,
    )


def _index_results(
    results: Sequence[ParityResult],
    *,
    platform: str,
) -> dict[str, ParityResult]:
    indexed: dict[str, ParityResult] = {}
    duplicate_ids: set[str] = set()

    for result in results:
        if result.file_id in indexed:
            duplicate_ids.add(result.file_id)
            continue
        indexed[result.file_id] = result

    if duplicate_ids:
        duplicates = ", ".join(sorted(duplicate_ids))
        raise ValueError(
            f"platform '{platform}' emitted duplicate file_id values: {duplicates}"
        )

    return indexed


def _match_faces(
    reference_faces: Sequence[FaceResult],
    candidate_faces: Sequence[FaceResult],
) -> list[tuple[int, int, float]]:
    pairs: list[tuple[float, int, int]] = []
    for reference_index, reference_face in enumerate(reference_faces):
        for candidate_index, candidate_face in enumerate(candidate_faces):
            iou = _box_iou(reference_face.box, candidate_face.box)
            pairs.append((iou, reference_index, candidate_index))

    pairs.sort(key=lambda entry: (-entry[0], entry[1], entry[2]))
    used_reference: set[int] = set()
    used_candidate: set[int] = set()
    matches: list[tuple[int, int, float]] = []
    for iou, reference_index, candidate_index in pairs:
        if reference_index in used_reference or candidate_index in used_candidate:
            continue
        used_reference.add(reference_index)
        used_candidate.add(candidate_index)
        matches.append((reference_index, candidate_index, iou))

    matches.sort(key=lambda entry: entry[0])
    return matches


def compare_result_sets(
    *,
    reference_platform: str,
    candidate_platform: str,
    reference_results: Mapping[str, ParityResult],
    candidate_results: Mapping[str, ParityResult],
    thresholds: ThresholdConfig | None = None,
    clip_threshold: float | None = None,
) -> ComparisonReport:
    thresholds = thresholds or ThresholdConfig()
    clip_threshold = (
        thresholds.clip_cosine_distance if clip_threshold is None else clip_threshold
    )

    missing_files = tuple(sorted(set(reference_results) - set(candidate_results)))
    extra_files = tuple(sorted(set(candidate_results) - set(reference_results)))
    findings: list[ComparisonFinding] = []
    file_failures: dict[str, list[ComparisonFinding]] = {
        file_id: [] for file_id in reference_results
    }

    def add_finding(finding: ComparisonFinding) -> None:
        findings.append(finding)
        if finding.file_id in file_failures:
            file_failures[finding.file_id].append(finding)

    for missing_file in missing_files:
        add_finding(
            ComparisonFinding(
                file_id=missing_file,
                metric="file_presence",
                message=f"Missing from {candidate_platform}",
            ),
        )
    for extra_file in extra_files:
        add_finding(
            ComparisonFinding(
                file_id=extra_file,
                metric="file_presence",
                message=f"Unexpected file in {candidate_platform}",
            ),
        )

    clip_distances: list[float] = []
    iou_errors: list[float] = []
    landmark_errors: list[float] = []
    score_deltas: list[float] = []
    face_embedding_distances: list[float] = []

    shared_file_ids = sorted(set(reference_results) & set(candidate_results))
    for file_id in shared_file_ids:
        reference = reference_results[file_id]
        candidate = candidate_results[file_id]

        clip_distance = cosine_distance(reference.clip.embedding, candidate.clip.embedding)
        clip_distances.append(clip_distance)
        if clip_distance > clip_threshold:
            add_finding(
                ComparisonFinding(
                    file_id=file_id,
                    metric="clip_cosine_distance",
                    message="CLIP cosine distance exceeded threshold",
                    value=clip_distance,
                    threshold=clip_threshold,
                ),
            )

        if len(reference.faces) != len(candidate.faces):
            add_finding(
                ComparisonFinding(
                    file_id=file_id,
                    metric="face_count",
                    message="Face count mismatch",
                    value=float(abs(len(reference.faces) - len(candidate.faces))),
                ),
            )

        matches = _match_faces(reference.faces, candidate.faces)
        for reference_index, candidate_index, iou in matches:
            reference_face = reference.faces[reference_index]
            candidate_face = candidate.faces[candidate_index]

            iou_error = 1.0 - iou
            iou_errors.append(iou_error)
            if iou < thresholds.box_iou_threshold:
                add_finding(
                    ComparisonFinding(
                        file_id=file_id,
                        metric="face_box_iou",
                        message="Face box IoU below threshold",
                        value=iou,
                        threshold=thresholds.box_iou_threshold,
                    ),
                )

            try:
                landmark_error = _landmark_error(
                    reference_face.landmarks,
                    candidate_face.landmarks,
                )
            except ValueError:
                add_finding(
                    ComparisonFinding(
                        file_id=file_id,
                        metric="landmarks",
                        message="Landmark count mismatch",
                    ),
                )
            else:
                landmark_errors.append(landmark_error)
                if landmark_error > thresholds.landmark_error_threshold:
                    add_finding(
                        ComparisonFinding(
                            file_id=file_id,
                            metric="landmark_error",
                            message="Landmark error exceeded threshold",
                            value=landmark_error,
                            threshold=thresholds.landmark_error_threshold,
                        ),
                    )

            score_delta = abs(reference_face.score - candidate_face.score)
            score_deltas.append(score_delta)
            if score_delta > thresholds.score_delta_threshold:
                add_finding(
                    ComparisonFinding(
                        file_id=file_id,
                        metric="score_delta",
                        message="Face score delta exceeded threshold",
                        value=score_delta,
                        threshold=thresholds.score_delta_threshold,
                    ),
                )

            embedding_distance = cosine_distance(
                reference_face.embedding,
                candidate_face.embedding,
            )
            face_embedding_distances.append(embedding_distance)
            if embedding_distance > thresholds.face_embedding_cosine_distance:
                add_finding(
                    ComparisonFinding(
                        file_id=file_id,
                        metric="face_embedding_cosine_distance",
                        message="Face embedding cosine distance exceeded threshold",
                        value=embedding_distance,
                        threshold=thresholds.face_embedding_cosine_distance,
                    ),
                )

    aggregates = {
        "clip_cosine_distance": _make_aggregate(clip_distances, clip_threshold),
        "face_box_iou_error": _make_aggregate(
            iou_errors,
            1.0 - thresholds.box_iou_threshold,
        ),
        "landmark_error": _make_aggregate(
            landmark_errors,
            thresholds.landmark_error_threshold,
        ),
        "score_delta": _make_aggregate(score_deltas, thresholds.score_delta_threshold),
        "face_embedding_cosine_distance": _make_aggregate(
            face_embedding_distances,
            thresholds.face_embedding_cosine_distance,
        ),
    }

    for metric_name, metric in aggregates.items():
        if metric.passed:
            continue
        add_finding(
            ComparisonFinding(
                file_id="*aggregate*",
                metric=metric_name,
                message="Aggregate threshold gate failed",
                value=metric.max,
                threshold=metric.threshold,
            ),
        )

    report_findings = tuple(findings)
    sorted_reference_files = sorted(reference_results)
    file_statuses = tuple(
        FileComparisonStatus(
            file_id=file_id,
            passed=not file_failures[file_id],
            failures=tuple(file_failures[file_id]),
        )
        for file_id in sorted_reference_files
    )
    passing_files = tuple(
        file_status.file_id for file_status in file_statuses if file_status.passed
    )
    failing_files = tuple(
        file_status.file_id for file_status in file_statuses if not file_status.passed
    )

    return ComparisonReport(
        reference_platform=reference_platform,
        candidate_platform=candidate_platform,
        total_reference_files=len(reference_results),
        checked_files=len(shared_file_ids),
        missing_files=missing_files,
        extra_files=extra_files,
        aggregates=aggregates,
        findings=report_findings,
        file_statuses=file_statuses,
        passing_files=passing_files,
        failing_files=failing_files,
        passed=not report_findings,
    )


def compare_platform_matrix(
    platform_results: Mapping[str, Sequence[ParityResult]],
    *,
    ground_truth_platform: str = "python",
    include_pairwise: bool = True,
    thresholds: ThresholdConfig | None = None,
) -> tuple[ComparisonReport, ...]:
    thresholds = thresholds or ThresholdConfig()

    if ground_truth_platform not in platform_results:
        raise ValueError(f"ground truth platform '{ground_truth_platform}' missing")

    by_platform: dict[str, dict[str, ParityResult]] = {
        platform: _index_results(results, platform=platform)
        for platform, results in platform_results.items()
    }

    reports: list[ComparisonReport] = []
    reference = by_platform[ground_truth_platform]
    non_ground_truth_platforms = [
        platform for platform in by_platform if platform != ground_truth_platform
    ]

    for platform in sorted(non_ground_truth_platforms):
        reports.append(
            compare_result_sets(
                reference_platform=ground_truth_platform,
                candidate_platform=platform,
                reference_results=reference,
                candidate_results=by_platform[platform],
                thresholds=thresholds,
                clip_threshold=thresholds.clip_cosine_distance,
            ),
        )

    if include_pairwise:
        for left_platform, right_platform in itertools.combinations(
            sorted(non_ground_truth_platforms), 2
        ):
            reports.append(
                compare_result_sets(
                    reference_platform=left_platform,
                    candidate_platform=right_platform,
                    reference_results=by_platform[left_platform],
                    candidate_results=by_platform[right_platform],
                    thresholds=thresholds,
                    clip_threshold=thresholds.cross_platform_clip_cosine_distance,
                ),
            )

    return tuple(reports)
