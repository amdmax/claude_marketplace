#!/usr/bin/env python3
"""
PostToolUse hook: Validate ADR YAML after Write.

Reads tool_input.file_path from stdin JSON, validates *.adr.yaml files.
Exit codes: 0 = pass/unrelated, 2 = blocking error.
"""

import json
import re
import sys

# ── stdlib yaml fallback ───────────────────────────────────────────────────────
try:
    import yaml
except ImportError:
    print("⚠️  PyYAML not installed — skipping ADR YAML validation", file=sys.stderr)
    print("💡 Install: pip install pyyaml", file=sys.stderr)
    sys.exit(0)


VALID_STATUSES = {"proposed", "accepted", "deprecated", "superseded", "rejected"}
VALID_COMPLEXITIES = {"Low", "Medium", "High"}
REQUIRED_FIELDS = ["adrVersion", "id", "title", "status", "date", "context", "options", "decision"]
REQUIRED_OPTION_FIELDS = ["name", "description", "pros", "cons"]
REQUIRED_DECISION_FIELDS = ["chosen", "rationale", "consequences"]


def err(msg: str, errors: list) -> None:
    print(f"  ❌ {msg}", file=sys.stderr)
    errors.append(msg)


def warn(msg: str) -> None:
    print(f"  ⚠️  {msg}", file=sys.stderr)


def validate(data: dict) -> tuple[list, int]:
    errors: list[str] = []
    warnings = 0

    # Required top-level fields
    for field in REQUIRED_FIELDS:
        if not data.get(field):
            err(f"Missing required field: {field}", errors)

    # status enum
    status = data.get("status")
    if status and status not in VALID_STATUSES:
        err(f"Invalid status: '{status}' — must be one of: {', '.join(sorted(VALID_STATUSES))}", errors)

    # id pattern: ADR-NNNN
    adr_id = data.get("id", "")
    if adr_id and not re.fullmatch(r"ADR-\d{4}", adr_id):
        err(f"Invalid id: '{adr_id}' — must match ADR-NNNN (e.g. ADR-0012)", errors)

    # date pattern: YYYY-MM-DD
    date = data.get("date", "")
    if date and not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(date)):
        err(f"Invalid date: '{date}' — must match YYYY-MM-DD", errors)

    # options: ≥ 2 entries
    options = data.get("options") or []
    if not isinstance(options, list) or len(options) < 2:
        err(f"options must have at least 2 entries (found: {len(options) if isinstance(options, list) else 0})", errors)
    else:
        for i, opt in enumerate(options):
            for field in REQUIRED_OPTION_FIELDS:
                if not opt.get(field):
                    err(f"options[{i}] missing required field: {field}", errors)
            complexity = opt.get("complexity")
            if complexity and complexity not in VALID_COMPLEXITIES:
                err(f"options[{i}].complexity: '{complexity}' — must be Low, Medium, or High", errors)

    # decision sub-fields
    decision = data.get("decision") or {}
    for field in REQUIRED_DECISION_FIELDS:
        if not decision.get(field):
            err(f"Missing required field: decision.{field}", errors)

    # decision.consequences: ≥ 1
    consequences = decision.get("consequences") or []
    if not isinstance(consequences, list) or len(consequences) < 1:
        err("decision.consequences must have at least 1 entry", errors)

    # decision.chosen cross-references an option name
    chosen = decision.get("chosen")
    if chosen and isinstance(options, list) and len(options) >= 2:
        option_names = {opt.get("name") for opt in options}
        if chosen not in option_names:
            err(f"decision.chosen '{chosen}' does not match any options[].name: {sorted(option_names)}", errors)

    # decisionDrivers: warn if empty
    drivers = data.get("decisionDrivers") or []
    if not drivers:
        warn("decisionDrivers is empty — consider adding NFR-driven constraints")
        warnings += 1

    return errors, warnings


def main() -> None:
    raw = sys.stdin.read()

    try:
        hook_input = json.loads(raw)
    except json.JSONDecodeError:
        sys.exit(0)

    file_path = (hook_input.get("tool_input") or {}).get("file_path", "")
    if not file_path or not file_path.endswith(".adr.yaml"):
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
        print("❌ ADR YAML must be a mapping at the top level", file=sys.stderr)
        sys.exit(2)

    print(f"🔍 Validating ADR YAML: {file_path.split('/')[-1]}", file=sys.stderr)

    errors, warnings = validate(data)

    print("", file=sys.stderr)
    if errors:
        print(f"❌ ADR YAML validation failed ({len(errors)} error(s), {warnings} warning(s))", file=sys.stderr)
        sys.exit(2)
    elif warnings:
        print(f"⚠️  ADR YAML validation passed with {warnings} warning(s)", file=sys.stderr)
    else:
        print("✅ ADR YAML validation passed", file=sys.stderr)


if __name__ == "__main__":
    main()
