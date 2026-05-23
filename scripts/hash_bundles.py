#!/usr/bin/env python3
"""
hash_bundles.py — Compute deterministic content hashes for each bundle and update plugin.json.

For each bundles/<name>/:
  1. Walk all files recursively (excluding .claude-plugin/plugin.json to avoid circular hash)
  2. Sort files by relative path for determinism
  3. Build canonical string: "<rel_path>\0<content>" per file, joined with "\n"
  4. SHA-256 → version string "sha256:<first-16-chars>"
  5. Write version into bundles/<name>/.claude-plugin/plugin.json

Usage:
  python scripts/hash_bundles.py           # update all plugin.json files
  python scripts/hash_bundles.py --check   # validate without writing; exit non-zero on mismatch
"""

import argparse
import hashlib
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
BUNDLES_DIR = REPO_ROOT / "bundles"

SKIP_DIRS = {"__pycache__"}
SKIP_FILES = {".DS_Store", ".gitkeep"}
SKIP_EXTENSIONS = {".pyc"}

PLUGIN_JSON_REL = ".claude-plugin/plugin.json"


def should_skip(rel: Path) -> bool:
    for part in rel.parts:
        if part in SKIP_DIRS:
            return True
    if rel.name in SKIP_FILES:
        return True
    if rel.suffix in SKIP_EXTENSIONS:
        return True
    return False


def _read_content(path: Path) -> str:
    raw = path.read_bytes()
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.hex()


def compute_bundle_hash(bundle_dir: Path) -> str:
    plugin_json = bundle_dir / PLUGIN_JSON_REL
    files = []
    for f in bundle_dir.rglob("*"):
        if not f.is_file():
            continue
        rel = f.relative_to(bundle_dir)
        if f == plugin_json:
            continue
        if should_skip(rel):
            continue
        files.append(f)

    files.sort(key=lambda f: str(f.relative_to(bundle_dir)))

    parts = []
    for f in files:
        rel = str(f.relative_to(bundle_dir))
        parts.append(f"{rel}\0{_read_content(f)}")

    canonical = "\n".join(parts)
    digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    return f"sha256:{digest[:16]}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Hash bundle contents and update plugin.json versions")
    parser.add_argument("--check", action="store_true", help="Validate only; exit non-zero if any version mismatches")
    args = parser.parse_args()

    if not BUNDLES_DIR.is_dir():
        print(f"ERROR: bundles directory not found: {BUNDLES_DIR}", file=sys.stderr)
        return 1

    bundle_dirs = sorted(d for d in BUNDLES_DIR.iterdir() if d.is_dir())
    if not bundle_dirs:
        print("No bundles found.", file=sys.stderr)
        return 1

    mismatches = []

    for bundle_dir in bundle_dirs:
        plugin_json = bundle_dir / PLUGIN_JSON_REL
        if not plugin_json.is_file():
            print(f"  SKIP {bundle_dir.name} — no plugin.json found")
            continue

        computed = compute_bundle_hash(bundle_dir)
        data = json.loads(plugin_json.read_text(encoding="utf-8"))
        current = data.get("version", "")

        if args.check:
            status = "OK" if current == computed else "MISMATCH"
            print(f"  {status:8s}  {bundle_dir.name}  ({current} → expected {computed})")
            if current != computed:
                mismatches.append(bundle_dir.name)
        else:
            data["version"] = computed
            plugin_json.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
            changed = "updated" if current != computed else "unchanged"
            print(f"  {changed:9s}  {bundle_dir.name}  {current} → {computed}")

    if args.check:
        if mismatches:
            print(f"\nFAIL: {len(mismatches)} bundle(s) have stale versions: {', '.join(mismatches)}", file=sys.stderr)
            print("Run `python scripts/hash_bundles.py` to regenerate.", file=sys.stderr)
            return 1
        print(f"\nAll {len(bundle_dirs)} bundle versions are up to date.")
        return 0

    print(f"\nDone. {len(bundle_dirs)} bundles processed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
