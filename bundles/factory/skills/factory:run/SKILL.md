---
name: factory:run
description: Dark factory orchestrator (thin wrapper). Advances a story one stage via the factory CLI - state machine, hooks, sandboxed agentic stage, commit, human-gate PR. Use /factory:run "<new requirement>" to start a story or /factory:run <story-id> to advance one.
argument-hint: "<raw requirement text> | <story-id>"
---

# Purpose
Wrapper around the factory CLI engine. One invocation = one stage advanced = one PR.
The human merging the PR is the approval gate; re-run after merge.

# Workflow
1. From the target repo root run: `uv run --project ${CLAUDE_PLUGIN_ROOT} factory run "<argument>"`
   (argument = story id `NNN-slug`, or the raw requirement text for a new story).
2. Relay the CLI output verbatim: NEW/RECONCILE/NEXT lines, the PR URL on success, or
   WAITING (human gate) / STALE (human decision) / DONE.
3. Exit code 2 = stage failed; the worktree is preserved - relay the failure and the
   preserved worktree path. Do not retry automatically.

# Validation
- Exactly one stage advanced per invocation; never bypass a WAITING gate.

# Exceptions
- `.factory/factory.yaml` missing: tell the user to run /factory:init first.
- Sandboxed stages need the agent image (images/agent/build.sh) and host env vars per
  factory.yaml `defaults.sandbox.env` (e.g. ANTHROPIC_API_KEY). Relay such errors as-is.
