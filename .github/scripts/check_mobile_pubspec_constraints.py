#!/usr/bin/env python3

from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ALLOWED_STRUCTURED_KEYS = {"path", "git", "sdk"}
SECTION_NAMES = {"dependencies", "dev_dependencies", "dependency_overrides"}
DISALLOWED_VERSION_MARKERS = ("^", ">", "<", "=", "~")


@dataclass(frozen=True)
class DependencySpec:
    kind: str
    value: str | None = None
    line: int = 0


def _strip_inline_comment(value: str) -> str:
    in_single = False
    in_double = False
    for index, char in enumerate(value):
        if char == "'" and not in_double:
            in_single = not in_single
        elif char == '"' and not in_single:
            in_double = not in_double
        elif char == "#" and not in_single and not in_double:
            return value[:index].rstrip()
    return value.rstrip()


def _normalize_scalar(value: str) -> str:
    cleaned = _strip_inline_comment(value).strip()
    if len(cleaned) >= 2 and cleaned[0] == cleaned[-1] and cleaned[0] in {"'", '"'}:
        cleaned = cleaned[1:-1].strip()
    return cleaned


def parse_pubspec(content: str) -> dict[str, dict[str, DependencySpec]]:
    parsed: dict[str, dict[str, DependencySpec]] = {
        section: {} for section in SECTION_NAMES
    }
    current_section: str | None = None
    current_dep: str | None = None
    current_dep_line = 0
    current_dep_is_structured = False
    current_structured_keys: set[str] = set()
    current_structured_version: str | None = None

    def flush_current_dep() -> None:
        nonlocal current_dep, current_dep_line, current_dep_is_structured
        nonlocal current_structured_keys, current_structured_version
        if not current_section or not current_dep:
            return
        if current_dep_is_structured:
            if current_structured_keys & ALLOWED_STRUCTURED_KEYS:
                kind = next(
                    key for key in ("path", "git", "sdk")
                    if key in current_structured_keys
                )
                parsed[current_section][current_dep] = DependencySpec(
                    kind=kind,
                    line=current_dep_line,
                )
            elif current_structured_version is not None:
                parsed[current_section][current_dep] = DependencySpec(
                    kind="hosted",
                    value=current_structured_version,
                    line=current_dep_line,
                )
            else:
                parsed[current_section][current_dep] = DependencySpec(
                    kind="structured",
                    line=current_dep_line,
                )
        current_dep = None
        current_dep_line = 0
        current_dep_is_structured = False
        current_structured_keys = set()
        current_structured_version = None

    for line_number, raw_line in enumerate(content.splitlines(), start=1):
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue

        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()

        if indent == 0 and stripped.endswith(":"):
            flush_current_dep()
            section = stripped[:-1]
            current_section = section if section in SECTION_NAMES else None
            continue

        if current_section is None:
            continue

        if indent == 2:
            flush_current_dep()
            match = re.match(r"([A-Za-z0-9_]+):(?:\s*(.+))?$", stripped)
            if not match:
                continue
            dep_name = match.group(1)
            remainder = match.group(2)
            if remainder is None or remainder == "":
                current_dep = dep_name
                current_dep_line = line_number
                current_dep_is_structured = True
                current_structured_keys = set()
                current_structured_version = None
            else:
                parsed[current_section][dep_name] = DependencySpec(
                    kind="hosted",
                    value=_normalize_scalar(remainder),
                    line=line_number,
                )
            continue

        if indent >= 4 and current_dep_is_structured:
            key_match = re.match(r"([A-Za-z0-9_]+):(?:\s*(.+))?$", stripped)
            if not key_match:
                continue
            key = key_match.group(1)
            remainder = key_match.group(2)
            current_structured_keys.add(key)
            if key == "version" and remainder:
                current_structured_version = _normalize_scalar(remainder)

    flush_current_dep()
    return parsed


def _read_at_ref(base_ref: str, path: str) -> str | None:
    try:
        result = subprocess.run(
            ["git", "show", f"{base_ref}:{path}"],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError:
        return None
    return result.stdout


def is_exact_hosted_version(version: str) -> bool:
    normalized = version.strip()
    if not normalized or normalized == "any":
        return False
    if any(marker in normalized for marker in DISALLOWED_VERSION_MARKERS):
        return False
    if " " in normalized:
        return False
    return True


def validate_file(base_ref: str, path: str) -> list[str]:
    current_content = Path(path).read_text()
    current_specs = parse_pubspec(current_content)
    base_content = _read_at_ref(base_ref, path)
    base_specs = parse_pubspec(base_content) if base_content is not None else {
        section: {} for section in SECTION_NAMES
    }

    failures: list[str] = []
    for section in SECTION_NAMES:
        current_section = current_specs.get(section, {})
        base_section = base_specs.get(section, {})
        for dep_name, spec in current_section.items():
            if spec.kind != "hosted" or spec.value is None:
                continue
            base_spec = base_section.get(dep_name)
            if (
                base_spec is not None
                and base_spec.kind == spec.kind
                and base_spec.value == spec.value
            ):
                continue
            if not is_exact_hosted_version(spec.value):
                failures.append(
                    f"{path}:{spec.line}: {section}.{dep_name} uses "
                    f"non-frozen version '{spec.value}'. "
                    "Use an exact version for new or changed hosted dependencies."
                )
    return failures


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(
            "Usage: check_mobile_pubspec_constraints.py <base-ref> <pubspec.yaml>...",
            file=sys.stderr,
        )
        return 2

    base_ref = argv[0]
    files = argv[1:]
    failures: list[str] = []
    for path in files:
        failures.extend(validate_file(base_ref, path))

    if failures:
        print("Disallowed mobile pubspec dependency constraints found:")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(f"Verified frozen hosted dependency constraints for {len(files)} pubspec(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
