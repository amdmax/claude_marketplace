---
name: factory:init
description: Initialize a repository for the dark factory (thin wrapper). Scaffolds .factory/factory.yaml + .factory/schemas/ from packaged templates, migrates legacy schema locations, self-checks. Run once per repo before any /factory:run.
argument-hint: ""
---

# Purpose
Make a repo factory-ready: the pipeline definition lives in the repo at `.factory/factory.yaml`.

# Workflow
1. From the target repo root run: `uv run --project ${CLAUDE_PLUGIN_ROOT} factory init`
   (idempotent; never overwrites; migrates `docs/factory/schemas/` if present).
2. Relay WARN lines about missing repo-owned schema files - the repo must provide them.
3. Commit `chore: initialize .factory config` on a new branch + PR. NEVER push to master.

# Validation
- `uv run --project ${CLAUDE_PLUGIN_ROOT} factory config-check` prints OK.
