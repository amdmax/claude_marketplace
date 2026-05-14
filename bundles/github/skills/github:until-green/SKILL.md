---
name: github:until-green
description: "Implement a scope of work end-to-end — writes code, commits, creates a PR, then loops fixing CI failures until all checks pass. Invoke with a natural language description of the work to do. Example: /until-green add validation to the email field in the signup form."
---

# Until Green

## Overview

`/until-green <scope>` is a full-lifecycle orchestrator. Give it a description of what needs to be done — it implements the code, commits, opens a PR, and then loops: reading CI failure logs, fixing the code, and re-committing until every check is green.

## Quick Start

```bash
/until-green fix the failing unit tests in src/build-html.ts
/until-green add input validation to the referral lambda handler
/until-green implement the pagefind search index generation step
```

## Workflow

### Phase 1 — Implement the scope

1. Read and understand the scope argument
2. Explore the relevant files in the codebase
3. Implement the required changes (minimal, focused)
4. Stage changed files: `git add <files>`

### Phase 2 — Commit

Invoke `/commit`:
- Auto-links to active story (reads `.agile-dev-team/active-story.yaml`)
- Creates a GitHub issue if no active story exists
- Produces `AIGCODE-###: <description>` formatted commit

### Phase 3 — Create PR

Invoke `/github:pull-request`:
- Verifies commits exist ahead of master
- Creates PR with `--base master`
- Stores PR number for the CI loop

```bash
PR_NUMBER=$(gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" \
  --state open --json number --jq '.[0].number')
```

Save loop state:
```json
{
  "scope": "<the original scope argument>",
  "prNumber": 123,
  "prUrl": "https://github.com/.../pull/123",
  "iteration": 0,
  "startedAt": "2026-03-15T10:00:00Z"
}
```
Write to `.agile-dev-team/until-green.json`.

### Phase 4 — CI loop

Load config:
```bash
MAX_ITER=$(yq e '.ci.max_fix_iterations' config.yaml)      # default: 5
TIMEOUT_MIN=$(yq e '.ci.check_timeout_minutes' config.yaml) # default: 15
POLL_SEC=$(yq e '.ci.poll_interval_seconds' config.yaml)    # default: 30
```

Loop:
```
FOR iteration IN 1..MAX_ITER:

  1. Wait for checks to start (push triggers CI with a brief delay)
     sleep $POLL_SEC

  2. Poll check status
     STATUS=$(gh pr checks $PR_NUMBER --json name,state,conclusion \
       --jq '[.[] | select(.state == "COMPLETED")] | length')

     Wait up to TIMEOUT_MIN for all checks to complete.

  3. Read conclusions
     FAILURES=$(gh pr checks $PR_NUMBER --json name,conclusion \
       --jq '[.[] | select(.conclusion == "FAILURE" or .conclusion == "TIMED_OUT")]')

  4. If FAILURES is empty → all green ✅ → exit loop

  5. For each failing check:
     a. Get the run ID
        RUN_ID=$(gh run list --branch "$(git branch --show-current)" \
          --json databaseId,status --jq '[.[] | select(.status=="completed")][0].databaseId')

     b. Fetch failure logs
        gh run view $RUN_ID --log-failed

     c. Analyze: understand WHY the check failed (build error, test assertion,
        lint violation, CDK synth failure, etc.)

     d. Fix the code — minimal targeted changes only

     e. Stage and commit:
        git add <changed files>
        /commit
        # /commit auto-detects the open PR and groups under AIGCODE-XXXa, XXXb, etc.

     f. Push:
        git push

  6. Increment iteration counter in .agile-dev-team/until-green.json

ENDLOOP

If MAX_ITER exceeded without green:
  → Report final status
  → List remaining failures with log excerpts
  → Stop (do not attempt further fixes — surface to user)
```

### Phase 5 — Done

```
✅ PR #123 is green: <PR URL>
   All checks passed after N iteration(s).
```

Invoke `/finalize-story <prUrl>` to close the loop: update the issue body, add PR cross-reference, apply labels, assign, and add to the project board.

---

## State File

`.agile-dev-team/until-green.json` — persists loop state across interruptions:

```json
{
  "scope": "fix the failing unit tests in src/build-html.ts",
  "prNumber": 123,
  "prUrl": "https://github.com/aigensa/academy/pull/123",
  "iteration": 2,
  "startedAt": "2026-03-15T10:00:00Z"
}
```

To resume after an interruption, re-run `/until-green` — if this file exists and the PR is still open, the skill picks up from the CI loop (skips phases 1-3).

---

## How Fix Commits Are Grouped

The `/commit` skill automatically detects the open PR on the current branch and groups all fix commits under the original AIGCODE number:

```
AIGCODE-157:  Add validation to email field       ← original commit
AIGCODE-157a: Fix TypeScript error in validator   ← first CI fix
AIGCODE-157b: Fix eslint no-unused-vars warning   ← second CI fix
```

No manual configuration needed — this is handled by `/commit`'s PR-based grouping.

---

## Examples

**Simple feature, passes CI first try:**
```bash
/until-green add a console.log for debug output in auth-edge

# → Phase 1: Implement — edits lambda/auth-edge/index.ts
# → Phase 2: Commit — AIGCODE-160: Add debug logging to auth-edge
# → Phase 3: PR — #94 created
# → Phase 4: Poll — all checks pass on first poll
# → ✅ PR #94 is green: https://github.com/.../pull/94
```

**Fix with one CI failure:**
```bash
/until-green fix the chart rendering test

# → Phase 1-3: commit + PR created
# → Phase 4 iteration 1:
#     Fetching CI logs...
#     ❌ test:unit failed — Expected 3 charts, got 2
#     Analyzing... fixing src/charts.ts
#     Committing fix → AIGCODE-161a: Fix chart count assertion in renderer
#     Pushing...
# → Phase 4 iteration 2:
#     ✅ All checks passed
# → ✅ PR #95 is green
```

**Scope that requires iterative fixes:**
```bash
/until-green add CDK construct for new Lambda function

# → Phase 1-3: CDK code written, committed, PR opened
# → Iteration 1: CDK synth fails — missing IAM policy → fix → AIGCODE-162a
# → Iteration 2: cfn-lint warning on resource naming → fix → AIGCODE-162b
# → Iteration 3: ✅ All checks green
# → ✅ PR #96 is green after 2 fix iterations
```

---

## Error Handling

| Situation | Behavior |
|-----------|----------|
| No changes after implement | Prompt user — nothing to commit |
| PR already open for branch | Skip to Phase 4 (reuse existing PR) |
| CI checks never start | Warn after 2× poll_interval, continue polling |
| Timeout exceeded | Report status + remaining failures, stop |
| Max iterations exceeded | Report final failures, stop |
| Push fails (branch protected) | Surface error, stop |
| `/commit` fails | Surface error, stop |

---

## Integration

- **`/commit`** — invoked in Phase 2 and after each fix in Phase 4
- **`/github:pull-request`** — invoked in Phase 3
- **`/finalize-story`** — always invoked post-green to close the issue loop
- **`gh pr checks`** — native gh CLI for polling CI status
- **`gh run view --log-failed`** — native gh CLI for fetching failure logs
