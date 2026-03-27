---
name: github:merge-chores
description: >
  Sequentially merge all open "chore:" PRs one at a time. After each merge,
  waits for CI to go green on the base branch before proceeding to the next.
  If CI fails, resolves conflicts or build issues, commits fixes, and retries
  until green. Never merges multiple PRs simultaneously.
tools:
  - Bash
  - Read
  - Edit
  - Grep
---

# github:merge-chores

## Purpose

Merge all open `chore:` PRs safely — one at a time — with a CI gate between each. Ensures the base branch stays green throughout the entire batch.

**Trigger:** User says "merge chores", "merge all chore PRs", or invokes `/gh:merge-chores`.

---

## Step 1 — Discover chore PRs

List all open PRs, filter by title prefix `chore:` (case-insensitive), sort by PR number ascending (oldest first).

```bash
REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

CHORES=$(gh pr list --state open --limit 100 \
  --json number,title,headRefName,baseRefName,url \
  | jq '[.[] | select(.title | ascii_downcase | startswith("chore:"))] | sort_by(.number)')

COUNT=$(echo "$CHORES" | jq 'length')

if [ "$COUNT" -eq 0 ]; then
  echo "No open chore: PRs found."
  exit 0
fi

echo "Found $COUNT chore PR(s) to merge:"
echo "$CHORES" | jq -r '.[] | "  #\(.number) — \(.title)"'
```

---

## Step 2 — Sequential merge loop

Iterate through the sorted list. Process exactly one PR at a time — never proceed to the next until the current one is fully green.

```bash
echo "$CHORES" | jq -c '.[]' | while IFS= read -r PR; do
  NUMBER=$(echo "$PR" | jq -r '.number')
  TITLE=$(echo "$PR"  | jq -r '.title')
  BASE=$(echo "$PR"   | jq -r '.baseRefName')

  echo ""
  echo "━━━ Merging #$NUMBER: $TITLE"

  # 2a. Merge
  gh pr merge "$NUMBER" --merge --delete-branch

  if [ $? -ne 0 ]; then
    echo "⚠️  Merge failed for #$NUMBER — attempting conflict resolution (see Step 3)"
    # Fall through to CI check; Step 3 handles recovery
  fi

  # 2b. Capture merge commit SHA on base branch
  SHA=$(gh api "repos/$REPO/git/ref/heads/$BASE" --jq '.object.sha')
  echo "  Merge commit: $SHA"

  # 2c. Poll CI
  _poll_ci "$REPO" "$SHA" "$NUMBER" "$TITLE"
done
```

---

## Step 2b — CI polling function

Poll check-runs on the merge commit every 30 seconds.

```bash
_poll_ci() {
  local REPO=$1 SHA=$2 NUMBER=$3 TITLE=$4
  local MAX_WAIT=1800  # 30 min timeout
  local ELAPSED=0

  echo "  Waiting for CI on $SHA..."

  while [ $ELAPSED -lt $MAX_WAIT ]; do
    CHECKS=$(gh api "repos/$REPO/commits/$SHA/check-runs" \
      --jq '.check_runs | map({name, status, conclusion})')

    TOTAL=$(echo "$CHECKS" | jq 'length')
    COMPLETED=$(echo "$CHECKS" | jq '[.[] | select(.status == "completed")] | length')
    FAILED=$(echo "$CHECKS" | jq '[.[] | select(.conclusion == "failure" or .conclusion == "timed_out")] | length')
    SUCCESS=$(echo "$CHECKS" | jq '[.[] | select(.conclusion == "success" or .conclusion == "skipped")] | length')

    echo "  CI: $COMPLETED/$TOTAL complete, $FAILED failed, $SUCCESS passed"

    if [ "$FAILED" -gt 0 ]; then
      echo "  ✗ CI failed — resolving (Step 3)"
      _fix_failures "$REPO" "$SHA" "$NUMBER" "$TITLE" "$BASE"
      # Re-capture SHA after fix push
      SHA=$(gh api "repos/$REPO/git/ref/heads/$BASE" --jq '.object.sha')
      ELAPSED=0  # reset timer for re-poll
      continue
    fi

    if [ "$COMPLETED" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
      echo "  ✓ #$NUMBER green — $TITLE"
      return 0
    fi

    sleep 30
    ELAPSED=$((ELAPSED + 30))
  done

  echo "  ⚠️  CI still pending after 30 minutes for #$NUMBER. Pausing — please investigate."
  echo "  Resume by re-running /gh:merge-chores (already-merged PRs will be skipped)."
  exit 1
}
```

---

## Step 3 — Fix failures

Investigate the failing check, resolve the root cause, commit, and push.

```bash
_fix_failures() {
  local REPO=$1 SHA=$2 NUMBER=$3 TITLE=$4 BASE=$5

  # Get the failing run ID
  RUN_ID=$(gh api "repos/$REPO/commits/$SHA/check-runs" \
    --jq '[.check_runs[] | select(.conclusion == "failure")] | first | .id')

  echo "  Examining failing run $RUN_ID..."
  gh run view "$RUN_ID" --log-failed 2>/dev/null | tail -80

  # Ensure we are on the base branch with latest changes
  git fetch origin "$BASE"
  git checkout "$BASE"
  git pull origin "$BASE"

  echo ""
  echo "  Root cause analysis:"
  echo "  - Check for merge conflicts: git status"
  git status --short

  CONFLICTS=$(git diff --name-only --diff-filter=U)
  if [ -n "$CONFLICTS" ]; then
    echo "  Merge conflicts detected in:"
    echo "$CONFLICTS"
    echo "  Resolving conflicts — accepting incoming changes where safe..."
    for FILE in $CONFLICTS; do
      git checkout --theirs "$FILE"
      git add "$FILE"
    done
  fi

  # Let Claude investigate and fix any remaining build/test failures
  # based on the log output above before committing
  echo ""
  echo "  Apply fixes, then the skill will commit and push."

  # Commit and push the fix
  git add -A
  git commit -m "fix: resolve ci failure after merging chore #$NUMBER"
  git push origin "$BASE"
}
```

**Fix strategy (in order):**
1. Check `git status` for uncommitted conflicts → resolve with `--theirs`, stage
2. Read CI log output → identify failing test / build step
3. Edit failing files to fix the issue
4. `git add -A && git commit -m "fix: resolve ci failure after merging chore #<N>"`
5. `git push origin <base>`
6. Return to polling loop

---

## Step 4 — Summary report

After all PRs processed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Merged 5/5 chore PRs successfully.

  ✓ #291 — chore: bump eslint to 9.x
  ✓ #293 — chore: update lodash 4.17.20 → 4.17.21
  ✓ #295 — chore: bump next.js to 14.2.0
  ✓ #298 — chore: update tailwindcss to 3.4.1
  ✓ #301 — chore: bump typescript to 5.4.0
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Exception Handling

| Scenario | Behaviour |
|---|---|
| No open `chore:` PRs | Exit: "No open chore: PRs found." |
| PR already merged/closed | `gh pr merge` will report it; skip and continue |
| PR not mergeable (draft, review required) | Log warning, skip, continue |
| Merge conflict at merge time | Detect in CI failures → resolve in Step 3 |
| CI permanently stuck > 30 min | Pause loop, print resume instructions |
| Fix pushes don't resolve CI after 3 retries | Escalate: stop, report which PR caused the issue |

---

## Integration

| Skill | Relationship |
|---|---|
| `github:until-green` | Reuses CI polling pattern |
| `github:pull-request` | Reuses conflict resolution approach |
| `git:commit` | Optional: use for fix commits if conventional numbering needed |
