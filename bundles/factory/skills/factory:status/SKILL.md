---
name: factory:status
description: Read-only dark factory dashboard (thin wrapper). Shows every story with per-stage state from committed story.yaml, plus the derived next action per story. Makes no changes.
argument-hint: "[story-id]"
---

# Purpose
Answer "where is everything and who is blocking" without mutating state.

# Workflow
1. `uv run --project ${CLAUDE_PLUGIN_ROOT} factory status` (all stories).
2. For a specific story (or per story when asked what's next):
   `uv run --project ${CLAUDE_PLUGIN_ROOT} factory next <story-id>` - relay
   WAITING <pr-url> / NEXT <stage> / STALE / DONE.
3. Render as a compact table; list human actions needed (PRs awaiting merge, stale stages).

# Validation
- Read-only: no writes, no branches, no PR mutations.
