#!/usr/bin/env python3
"""
hash_skills.py — Generate a deterministic per-skill content manifest.

For each skill directory under .claude/skills/ (excluding _templates):
  1. Walk all files recursively; skip __pycache__/, *.pyc, .DS_Store, .gitkeep
  2. Sort files by relative path (determinism)
  3. Build canonical string: "<rel_path>\0<utf-8 content>" per file, joined with "\n"
  4. SHA-256 the combined string → skill hash (prefix: "sha256:")

Output: .claude-plugin/skills-manifest.json
"""

import argparse
import hashlib
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILLS_DIR = REPO_ROOT / ".claude" / "skills"
DEFAULT_OUTPUT = REPO_ROOT / ".claude-plugin" / "skills-manifest.json"

REPO_ID = "amdmax/claude_marketplace"

SKIP_DIRS = {"__pycache__"}
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


def hash_skill(skill_dir: Path) -> dict:
    """Compute SHA-256 hash for a single skill directory."""
    files = []
    for f in skill_dir.rglob("*"):
        if f.is_file() and not should_skip(f.relative_to(skill_dir)):
            files.append(f)

    # Sort by relative path for determinism
    files.sort(key=lambda f: str(f.relative_to(skill_dir)))

    rel_paths = [str(f.relative_to(skill_dir)) for f in files]

    # Build canonical string
    parts = []
    for f, rel in zip(files, rel_paths):
        try:
            content = f.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            # Binary files: hex-encode
            content = f.read_bytes().hex()
        parts.append(f"{rel}\0{content}")

    canonical = "\n".join(parts)
    digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()

    return {
        "hash": f"sha256:{digest}",
        "files": rel_paths,
        "file_count": len(rel_paths),
    }


def generate_manifest(output_path: Path) -> dict:
    if not SKILLS_DIR.is_dir():
        print(f"ERROR: skills directory not found: {SKILLS_DIR}", file=sys.stderr)
        sys.exit(1)

    skills = {}
    skill_dirs = sorted(
        d for d in SKILLS_DIR.iterdir()
        if d.is_dir() and not d.name.startswith("_")
    )

    for skill_dir in skill_dirs:
        skill_name = skill_dir.name
        skills[skill_name] = hash_skill(skill_dir)
        print(f"  hashed: {skill_name}  ({skills[skill_name]['file_count']} files)")

    manifest = {
        "schema_version": "1",
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "repo": REPO_ID,
        "skills": skills,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"\nManifest written to: {output_path}")
    print(f"Skills hashed: {len(skills)}")
    return manifest


def main():
    parser = argparse.ArgumentParser(description="Generate skill content hashes manifest")
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
