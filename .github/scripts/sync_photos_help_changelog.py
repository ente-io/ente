#!/usr/bin/env python3

import argparse
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List, Optional, Tuple


TAG_PATTERN = re.compile(r"^photos-v(?P<version>[0-9]+\.[0-9]+\.[0-9]+)$")
BULLET_PATTERN = re.compile(r"^([-*+])\s+(?P<text>.+?)\s*$")
ORDERED_PATTERN = re.compile(r"^\d+[.)]\s+(?P<text>.+?)\s*$")


def set_output(name: str, value: str) -> None:
    output_path = os.getenv("GITHUB_OUTPUT")
    if output_path:
        with open(output_path, "a", encoding="utf-8") as f:
            f.write(f"{name}={value}\n")
    print(f"{name}: {value}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync docs/docs/photos/changelog.md with a photos release entry."
    )
    parser.add_argument("--changelog-path", required=True)
    parser.add_argument("--event-path", default=os.getenv("GITHUB_EVENT_PATH", ""))
    parser.add_argument("--tag-name", default="")
    parser.add_argument("--published-at", default="")
    parser.add_argument("--body", default="")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def read_release_from_event(event_path: str) -> Tuple[str, str, str]:
    if not event_path:
        return "", "", ""

    event_file = Path(event_path)
    if not event_file.exists():
        return "", "", ""

    event = json.loads(event_file.read_text(encoding="utf-8"))
    release = event.get("release", {})
    return (
        str(release.get("tag_name", "")),
        str(release.get("published_at", "")),
        str(release.get("body", "")),
    )


def resolve_release_fields(args: argparse.Namespace) -> Tuple[str, str, str]:
    tag_name = args.tag_name.strip()
    published_at = args.published_at.strip()
    body = args.body

    event_tag, event_published_at, event_body = read_release_from_event(args.event_path)

    if not tag_name:
        tag_name = event_tag.strip()
    if not published_at:
        published_at = event_published_at.strip()
    if not body:
        body = event_body

    if "\\n" in body and "\n" not in body:
        body = body.replace("\\n", "\n")

    return tag_name, published_at, body


def parse_tag(tag_name: str) -> Optional[str]:
    match = TAG_PATTERN.match(tag_name)
    if not match:
        return None
    return match.group("version")


def month_year_label(published_at: str) -> str:
    if not published_at:
        dt = datetime.now(timezone.utc)
        return dt.strftime("%b %Y")

    normalized = published_at.replace("Z", "+00:00")
    dt = datetime.fromisoformat(normalized)
    return dt.strftime("%b %Y")


def dedupe_preserve_order(items: Iterable[str]) -> List[str]:
    seen = set()
    out: List[str] = []
    for item in items:
        trimmed = item.strip()
        if not trimmed or trimmed in seen:
            continue
        seen.add(trimmed)
        out.append(trimmed)
    return out


def extract_bullets(body: str) -> List[str]:
    normalized = body.replace("\r\n", "\n")
    lines = normalized.split("\n")

    bullets: List[str] = []
    fallback: List[str] = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue

        leading_spaces = len(line) - len(line.lstrip(" "))
        if leading_spaces <= 3:
            bullet_match = BULLET_PATTERN.match(line.lstrip())
            if bullet_match:
                bullets.append(bullet_match.group("text").strip())
                continue

            ordered_match = ORDERED_PATTERN.match(line.lstrip())
            if ordered_match:
                bullets.append(ordered_match.group("text").strip())
                continue

        fallback.append(stripped)

    if bullets:
        return dedupe_preserve_order(bullets)

    return dedupe_preserve_order(fallback)


def build_section(version: str, date_label: str, bullets: List[str]) -> str:
    section_lines = [f"## v{version} (mobile) - {date_label}", ""]
    section_lines.extend(f"- {item}" for item in bullets)
    return "\n".join(section_lines).rstrip() + "\n"


def replace_or_insert_section(content: str, version: str, section: str) -> str:
    heading_pattern = re.compile(
        rf"^## v{re.escape(version)} \(mobile\) - .*$", re.MULTILINE
    )
    heading_match = heading_pattern.search(content)

    if heading_match:
        next_section_match = re.search(r"^## ", content[heading_match.end() :], re.MULTILINE)
        section_end = (
            heading_match.end() + next_section_match.start()
            if next_section_match
            else len(content)
        )
        before = content[: heading_match.start()].rstrip("\n")
        after = content[section_end:].lstrip("\n")
        combined = before + "\n\n" + section + "\n" + after
        return combined.rstrip() + "\n"

    first_section_match = re.search(r"^## v", content, re.MULTILINE)
    if not first_section_match:
        raise ValueError("Could not find insertion point in changelog markdown")

    before = content[: first_section_match.start()].rstrip("\n")
    after = content[first_section_match.start() :].lstrip("\n")
    combined = before + "\n\n" + section + "\n" + after
    return combined.rstrip() + "\n"


def main() -> int:
    args = parse_args()
    changelog_path = Path(args.changelog_path)

    tag_name, published_at, body = resolve_release_fields(args)
    version = parse_tag(tag_name)

    if not version:
        print(f"Skipping: unsupported tag '{tag_name}'")
        set_output("changed", "false")
        set_output("reason", "unsupported_tag")
        return 0

    bullets = extract_bullets(body)
    if not bullets:
        print("Skipping: no usable release notes were found")
        set_output("changed", "false")
        set_output("version", version)
        set_output("tag_name", tag_name)
        set_output("reason", "empty_release_notes")
        return 0

    date_label = month_year_label(published_at)
    section = build_section(version, date_label, bullets)

    original = changelog_path.read_text(encoding="utf-8")
    updated = replace_or_insert_section(original, version, section)

    changed = updated != original

    set_output("version", version)
    set_output("tag_name", tag_name)
    set_output("changed", "true" if changed else "false")

    if not changed:
        set_output("reason", "already_up_to_date")
        print("No update needed: changelog already up to date.")
        return 0

    if args.dry_run:
        print("Dry run enabled: not writing changelog file.")
        set_output("reason", "dry_run")
        return 0

    changelog_path.write_text(updated, encoding="utf-8")
    set_output("reason", "updated")
    print(f"Updated {changelog_path} for {tag_name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
