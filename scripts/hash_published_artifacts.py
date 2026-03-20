#!/usr/bin/env python3
"""
hash_published_artifacts.py — Generate a deterministic manifest of all published artifacts.

Canonical published paths:
  - skills/<name>/          — multi-file skill directories
  - commands/<name>.md      — single-file commands (excludes references/)
  - agents/<name>.md        — single-file agents   (excludes references/)

Output: .claude-plugin/published-artifacts-manifest.json
"""

import argparse
import hashlib
import json
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / "skills"
COMMANDS_DIR = REPO_ROOT / "commands"
AGENTS_DIR = REPO_ROOT / "agents"
DEFAULT_OUTPUT = REPO_ROOT / ".claude-plugin" / "published-artifacts-manifest.json"

REPO_ID = "amdmax/claude_marketplace"

SKIP_DIRS = {"__pycache__", "references"}
SKIP_FILES = {".DS_Store", ".gitkeep"}
SKIP_EXTENSIONS = {".pyc"}


def should_skip(path: Path) -> bool:
    for part in path.parts:
        if part in SKIP_DIRS:
            return True
    if path.name in SKIP_FILES:
        return True
    if path.suffix in SKIP_EXTENSIONS:
        return True
    return False


def _read_content(path: Path) -> str:
    """Read file as UTF-8 text; fall back to hex-encoded bytes for binary files."""
    raw = path.read_bytes()
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.hex()


def _sha256(canonical: str) -> str:
    return "sha256:" + hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def hash_artifact(entry_path: Path, entry_type: str) -> dict:
    if entry_type == "skill":
        # Compute relative path once per file (used for skip check, sort key, and content)
        pairs = []
        for f in entry_path.rglob("*"):
            if f.is_file():
                rel = f.relative_to(entry_path)
                if not should_skip(rel):
                    pairs.append((str(rel), f))
        pairs.sort(key=lambda p: p[0])

        parts = []
        rel_paths = []
        for rel, f in pairs:
            rel_paths.append(rel)
            parts.append(f"{rel}\0{_read_content(f)}")

        return {
            "hash": _sha256("\n".join(parts)),
            "files": rel_paths,
            "file_count": len(rel_paths),
        }

    else:  # command or agent — single file
        canonical = f"{entry_path.name}\0{_read_content(entry_path)}"
        return {"hash": _sha256(canonical), "files": [entry_path.name], "file_count": 1}


def discover_artifacts() -> list[tuple[str, str, Path]]:
    """
    Returns list of (artifact_name, artifact_type, entry_path) tuples, sorted by name.

    Artifact name conventions:
      - skills:   the directory name            e.g. "arch:create-adr"
      - commands: "commands/<filename>"          e.g. "commands/backend-dev.md"
      - agents:   "agents/<filename>"            e.g. "agents/architect.md"
    """
    artifacts = []

    if SKILLS_DIR.is_dir():
        for entry in sorted(SKILLS_DIR.iterdir()):
            if entry.is_dir() and not entry.name.startswith("_"):
                artifacts.append((entry.name, "skill", entry))

    if COMMANDS_DIR.is_dir():
        for entry in sorted(COMMANDS_DIR.glob("*.md")):
            if entry.is_file():
                artifacts.append((f"commands/{entry.name}", "command", entry))

    if AGENTS_DIR.is_dir():
        for entry in sorted(AGENTS_DIR.glob("*.md")):
            if entry.is_file():
                artifacts.append((f"agents/{entry.name}", "agent", entry))

    return artifacts


def generate_manifest(output_path: Path) -> dict:
    artifacts_list = discover_artifacts()

    if not artifacts_list:
        print(
            "ERROR: no artifacts found — check that skills/, commands/, agents/ exist",
            file=sys.stderr,
        )
        sys.exit(1)

    artifacts = {}
    for name, artifact_type, entry_path in artifacts_list:
        result = hash_artifact(entry_path, artifact_type)

        # Canonical path field: skills use "skills/<name>/SKILL.md" anchor,
        # commands/agents use their direct file path relative to repo root
        if artifact_type == "skill":
            canonical_path = f"skills/{entry_path.name}/SKILL.md"
        else:
            canonical_path = str(entry_path.relative_to(REPO_ROOT))

        artifacts[name] = {
            "type": artifact_type,
            "path": canonical_path,
            **result,
        }
        print(f"  {artifact_type:8s}  {name}  ({result['file_count']} file(s))")

    counts = Counter(v["type"] for v in artifacts.values())

    manifest = {
        "schema_version": "1",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "repo": REPO_ID,
        "artifacts": artifacts,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    print(f"\nManifest written to: {output_path}")
    print(
        f"Total artifacts: {len(artifacts)}"
        f"  (skills: {counts['skill']}, commands: {counts['command']}, agents: {counts['agent']})"
    )
    return manifest


def main():
    parser = argparse.ArgumentParser(
        description="Generate deterministic manifest of published artifacts"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Output path (default: {DEFAULT_OUTPUT})",
    )
    args = parser.parse_args()
    generate_manifest(args.output)


if __name__ == "__main__":
    main()
