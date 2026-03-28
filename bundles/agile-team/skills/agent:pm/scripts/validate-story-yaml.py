#!/usr/bin/env python3
"""
PostToolUse hook: Validate story YAML after Write.

Reads tool_input.file_path from stdin JSON, validates *story-extract.yaml files.
Exit codes: 0 = pass/unrelated, 2 = blocking error.
"""

import json
import re
import sys

# ── stdlib yaml fallback ───────────────────────────────────────────────────────
try:
    import yaml
except ImportError:
    print("⚠️  PyYAML not installed — skipping story YAML validation", file=sys.stderr)
    print("💡 Install: pip install pyyaml", file=sys.stderr)
    sys.exit(0)


GIVEN_WHEN_THEN = re.compile(r"\b(given|when|then)\b", re.IGNORECASE)
USER_STORY_PATTERN = re.compile(r"\bAs a\b|\bI want\b", re.IGNORECASE)


def err(msg: str, errors: list) -> None:
    print(f"  ❌ {msg}", file=sys.stderr)
    errors.append(msg)


def warn(msg: str) -> None:
    print(f"  ⚠️  {msg}", file=sys.stderr)


def validate(data: dict) -> tuple[list, int]:
    errors: list[str] = []
    warnings = 0

    # top-level story key
    story = data.get("story")
    if not isinstance(story, dict):
        err("Missing required top-level key: story", errors)
        return errors, warnings

    # description
    description = story.get("description") or ""
    if not str(description).strip():
        err("story.description is required and must not be empty", errors)

    # hypothesis
    hypothesis = story.get("hypothesis") or ""
    if not str(hypothesis).strip():
        err("story.hypothesis is required and must not be empty", errors)
    elif not USER_STORY_PATTERN.search(str(hypothesis)):
        warn("story.hypothesis does not contain 'As a' / 'I want' — consider using user story format")
        warnings += 1

    # acceptanceCriteria
    acs = story.get("acceptanceCriteria")
    if not isinstance(acs, list) or len(acs) == 0:
        err(
            f"story.acceptanceCriteria must be a non-empty list "
            f"(found: {len(acs) if isinstance(acs, list) else type(acs).__name__})",
            errors,
        )
    else:
        untestable = [
            i for i, ac in enumerate(acs)
            if isinstance(ac, str) and not GIVEN_WHEN_THEN.search(ac)
        ]
        if untestable:
            indices = ", ".join(f"[{i}]" for i in untestable)
            warn(
                f"acceptanceCriteria {indices} do not follow Given/When/Then — "
                "consider testable format"
            )
            warnings += 1

    # milestones: if present must be non-empty list
    if "milestones" in story:
        milestones = story["milestones"]
        if not isinstance(milestones, list) or len(milestones) == 0:
            err(
                "story.milestones is present but empty — either populate it or omit the key",
                errors,
            )

    return errors, warnings


def main() -> None:
    raw = sys.stdin.read()

    try:
        hook_input = json.loads(raw)
    except json.JSONDecodeError:
        sys.exit(0)

    file_path = (hook_input.get("tool_input") or {}).get("file_path", "")
    if not file_path or not file_path.endswith("story-extract.yaml"):
        sys.exit(0)

    try:
        with open(file_path) as f:
            data = yaml.safe_load(f)
    except FileNotFoundError:
        sys.exit(0)
    except yaml.YAMLError as e:
        print(f"❌ Failed to parse YAML: {file_path}", file=sys.stderr)
        print(f"   {e}", file=sys.stderr)
        sys.exit(2)

    if not isinstance(data, dict):
        print("❌ Story YAML must be a mapping at the top level", file=sys.stderr)
        sys.exit(2)

    print(f"🔍 Validating story YAML: {file_path.split('/')[-1]}", file=sys.stderr)

    errors, warnings = validate(data)

    print("", file=sys.stderr)
    if errors:
        print(f"❌ Story YAML validation failed ({len(errors)} error(s), {warnings} warning(s))", file=sys.stderr)
        sys.exit(2)
    elif warnings:
        print(f"⚠️  Story YAML validation passed with {warnings} warning(s)", file=sys.stderr)
    else:
        print("✅ Story YAML validation passed", file=sys.stderr)


if __name__ == "__main__":
    main()
