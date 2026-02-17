#!/usr/bin/env python3
from __future__ import annotations

import argparse
from datetime import UTC, datetime
import json
from pathlib import Path
import sys
from typing import Any

ML_DIR = Path(__file__).resolve().parents[1]
if str(ML_DIR) not in sys.path:
    sys.path.insert(0, str(ML_DIR))

from comparator.compare import ThresholdConfig, compare_platform_matrix
from ground_truth.schema import load_results_document


def _load_results(path: Path) -> tuple[str | None, tuple[Any, ...]]:
    payload = json.loads(path.read_text())
    platform = payload.get("platform") if isinstance(payload, dict) else None
    return platform, load_results_document(payload)


def _serialize_reports(reports: tuple[Any, ...]) -> list[dict[str, Any]]:
    return [report.to_dict() for report in reports]


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Compare platform ML indexing results against Python ground truth.",
    )
    parser.add_argument(
        "--ground-truth",
        required=True,
        help="Path to a JSON file containing Python ground truth results.",
    )
    parser.add_argument(
        "--platform-result",
        action="append",
        default=[],
        metavar="platform=path",
        help="Platform result to compare, for example android=out/android/results.json.",
    )
    parser.add_argument(
        "--output",
        help="Optional path to write machine-readable comparison JSON.",
    )
    parser.add_argument(
        "--no-pairwise",
        action="store_true",
        help="Skip non-ground-truth pairwise comparisons.",
    )
    args = parser.parse_args()

    ground_truth_path = Path(args.ground_truth)
    ground_truth_platform, ground_truth_results = _load_results(ground_truth_path)
    if not ground_truth_platform:
        ground_truth_platform = "python"

    platform_results = {ground_truth_platform: ground_truth_results}
    for platform_result in args.platform_result:
        if "=" not in platform_result:
            raise ValueError(
                f"Invalid --platform-result value '{platform_result}'. Use platform=path."
            )
        platform, path = platform_result.split("=", 1)
        _, results = _load_results(Path(path))
        platform_results[platform] = results

    thresholds = ThresholdConfig()
    reports = compare_platform_matrix(
        platform_results,
        ground_truth_platform=ground_truth_platform,
        include_pairwise=not args.no_pairwise,
        thresholds=thresholds,
    )

    passed = all(report.passed for report in reports)
    output_payload = {
        "generated_at": datetime.now(UTC).isoformat(),
        "ground_truth_platform": ground_truth_platform,
        "thresholds": thresholds.to_dict(),
        "passed": passed,
        "comparisons": _serialize_reports(reports),
    }

    if args.output:
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(output_payload, indent=2, sort_keys=True))

    failed_reports = [report for report in reports if not report.passed]
    print(f"Comparisons executed: {len(reports)}")
    print(f"Comparison status: {'PASS' if passed else 'FAIL'}")
    if failed_reports:
        print("Failed comparisons:")
        for report in failed_reports:
            print(
                f"  {report.reference_platform} -> {report.candidate_platform} "
                f"({len(report.findings)} findings)"
            )

    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
