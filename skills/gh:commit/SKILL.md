---
name: gh:commit
description: Create git commits with issue-based AIGCODE numbering (AIGCODE-{issueNumber}). Analyzes staged changes and generates commit messages following project conventions. Creates GitHub issues if no active story exists.
hooks:
  Stop:
    - hooks:
        - type: command
          command: |
            #!/bin/bash
            # Skip validation for merge commits
            if git log -1 --pretty=%B | grep -q "^Merge"; then
              echo "✓ Merge commit - skipping AIGCODE validation"
              exit 0
            fi

            # Verify commit format - accept both issue-based and sequential
            if ! git log -1 --pretty=%B | grep -E '^AIGCODE-[0-9]+[a-z]?:'; then
              echo "Error: Commit must follow 'AIGCODE-###:' format" >&2
              echo "  Valid: AIGCODE-157: description (issue-based)" >&2
              echo "  Valid: AIGCODE-124: description (sequential)" >&2
              echo "  Valid: AIGCODE-157a: description (with suffix)" >&2
              exit 2
            fi
            echo "✓ Commit format validated (AIGCODE)"
          timeout: 10
---

# AIGCODE Commit Automation

## Overview

This skill automates git commits with **issue-based numbering** using AIGCODE prefix. It:

1. **Detects open PR** - Groups code review fixes under PR's base issue number
2. **Checks for active story** - Reads `.agile-dev-team/active-story.json` for issue number
3. **Creates issue if needed** - Calls `/create-story` when no active story exists
4. **Analyzes staged changes** - Understands what's being committed
5. **Generates commit message** - Clear, concise, explains WHY
6. **Follows conventions** - Co-author attribution, AIGCODE-### format

**Configuration:** Customize via [config.yaml](config.yaml) and @references
- Numbering mode (issue-based, sequential)
- Issue creation behavior (create_if_missing)
- Grouping detection
- Message formatting

## Quick Start

```bash
# Stage your changes
git add file1.ts file2.ts

# Run the skill
/commit

# Skill will:
# 1. Check for active story (or create one)
# 2. Use issue number (e.g., AIGCODE-157)
# 3. Analyze your changes
# 4. Generate descriptive message
# 5. Create commit with co-author attribution
```

## PR-Based Grouping (Code Review Fixes)

**Problem:** Code review provides feedback on an open PR. You fix issues and commit. New commits get different AIGCODE numbers, fragmenting the PR's traceability.

**Solution:** When a PR exists for your branch, all commits automatically group under the PR's base AIGCODE number.

### How It Works

```bash
# 1. Create PR for your work
git checkout -b feature/auth-improvements
git add auth.ts
/commit  # → AIGCODE-245: Add user authentication

/mr  # Creates PR #42

# 2. Code review finds issues
# Reviewer comments: "Add timeout to token exchange"

# 3. Fix issues and commit
git add auth.ts
/commit
# → 🔀 Open PR #42 detected
# → ✓ Grouping under AIGCODE-245 (code review fixes)
# → AIGCODE-245a: Add timeout protection to token exchange

# 4. More review feedback
git add auth.ts tests.ts
/commit
# → AIGCODE-245b: Fix memory leak in timeout handler

# 5. Final review pass
git add docs.md
/commit
# → AIGCODE-245c: Update documentation for timeout behavior
```

### Benefits

- **Single issue traceability**: All PR work (original + fixes) under one AIGCODE
- **Clear intent**: Suffixes (a, b, c) show iterative improvements
- **No number inflation**: Doesn't create new issues for review fixes
- **Automatic**: No manual intervention needed

### When PR Grouping Applies

✅ **Uses PR base number when:**
- Open PR exists for current branch
- PR has commits with AIGCODE numbers
- You're committing on the PR branch

❌ **Falls back to active story/sequential when:**
- No open PR for current branch
- PR exists but branch has diverged
- Explicitly working on different issue

## Workflow

### Step 1: Verify Staged Changes

```bash
git diff --cached --stat
```

- If no changes: Error and prompt to stage files
- If changes exist: Proceed to numbering

### Step 2: Determine Commit Number

**See:** @references/issue-numbering.md for detailed algorithm

**Priority order:**
1. **Open PR for current branch** → Use PR's base AIGCODE (groups code review fixes)
2. **Active story** → Use issue number from .agile-dev-team/active-story.json
3. **Sequential fallback** → Auto-increment from git history

Checks for active story and determines numbering mode:

```bash
# Read numbering mode from config
MODE=$(yq e '.numbering.mode' config.yaml)
STORY_FILE=".agile-dev-team/active-story.json"
STORY_EXISTS=false
PR_BASE_AIGCODE=""

# PRIORITY 1: Check for open PR on current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PR_NUMBER=$(gh pr list --head "$CURRENT_BRANCH" --state open --json number --jq '.[0].number' 2>/dev/null)

if [ -n "$PR_NUMBER" ]; then
  # Get commits from this PR and extract base AIGCODE number
  PR_COMMITS=$(gh pr view "$PR_NUMBER" --json commits --jq '.commits[].messageHeadline')

  # Find first AIGCODE-### (without suffix) or AIGCODE-###a/b/c
  PR_BASE_AIGCODE=$(echo "$PR_COMMITS" | grep -oE 'AIGCODE-[0-9]+' | head -1)

  if [ -n "$PR_BASE_AIGCODE" ]; then
    echo "🔀 Open PR #${PR_NUMBER} detected"
    echo "✓ Grouping under $PR_BASE_AIGCODE (code review fixes)"
    COMMIT_PREFIX="$PR_BASE_AIGCODE"
    STORY_EXISTS=true
  fi
fi

# PRIORITY 2: Try to read active story (if no PR base found)
if [ "$STORY_EXISTS" = false ] && [ -f "$STORY_FILE" ]; then
  ISSUE_NUMBER=$(jq -r '.issueNumber' "$STORY_FILE")

  if [ "$ISSUE_NUMBER" != "null" ] && [ -n "$ISSUE_NUMBER" ]; then
    STORY_EXISTS=true
    COMMIT_PREFIX="AIGCODE-${ISSUE_NUMBER}"
    echo "✓ Using issue #${ISSUE_NUMBER}: $(jq -r '.title' "$STORY_FILE")"
  fi
fi

# If no active story and auto-create enabled
if [ "$STORY_EXISTS" = false ] && [ "$MODE" = "issue-based" ]; then
  CREATE_IF_MISSING=$(yq e '.numbering.issue.create_if_missing' config.yaml)

  if [ "$CREATE_IF_MISSING" = "true" ]; then
    echo "📋 No active story. Creating one..."

    # Invoke /create-story skill
    if /create-story; then
      # Re-read active story file
      ISSUE_NUMBER=$(jq -r '.issueNumber' "$STORY_FILE")
      COMMIT_PREFIX="AIGCODE-${ISSUE_NUMBER}"
      echo "✓ Created issue #${ISSUE_NUMBER}"
      STORY_EXISTS=true
    else
      echo "⚠️  Issue creation failed. Using sequential numbering..."
    fi
  fi
fi

# Fall back to sequential if needed
if [ "$STORY_EXISTS" = false ]; then
  # Use sequential counter (find highest AIGCODE-### and increment)
  # See @references/aigcode-counter.md for details
  HIGHEST=$(git log --oneline --all --grep="AIGCODE-" | \
    grep -o "AIGCODE-[0-9]*" | \
    sort -u | \
    sort -t- -k2 -n | \
    tail -1)

  if [ -n "$HIGHEST" ]; then
    CURRENT_NUM=$(echo "$HIGHEST" | sed 's/AIGCODE-//')
    NEXT_NUM=$((CURRENT_NUM + 1))
  else
    NEXT_NUM=1
  fi

  COMMIT_PREFIX=$(printf "AIGCODE-%03d" "$NEXT_NUM")
  echo "Using sequential: $COMMIT_PREFIX"
fi
```

**Why issue-based?**
- Direct traceability to GitHub issues
- Clear context for what's being worked on
- Integrates with `/fetch-story` and `/play-story` workflows

**Fallback to sequential:**
- When issue creation fails (network, auth)
- When `mode: "sequential"` in config
- Maintains backward compatibility

### Step 2b: Detect Related Commits (Optional)

If changes affect recently modified files:
- Checks last 4 hours of commits (configurable)
- Calculates file overlap percentage
- Offers grouping with suffix (e.g., AIGCODE-157b)

```bash
# Check recent commits for same AIGCODE prefix (works for both issue and sequential)
if [ -n "$COMMIT_PREFIX" ]; then
  # Look for AIGCODE-157, AIGCODE-157a, AIGCODE-157b, etc.
  TIME_WINDOW=$(yq e '.grouping.time_window' config.yaml)
  RECENT_COMMITS=$(git log --since="$TIME_WINDOW" \
    --format="%H|%s" | grep "$COMMIT_PREFIX")

  # Extract suffix from most recent commit with same prefix
  LAST_SUFFIX=$(echo "$RECENT_COMMITS" | head -1 | \
    grep -o "${COMMIT_PREFIX}[a-z]*" | sed "s/${COMMIT_PREFIX}//")

  if [ -n "$LAST_SUFFIX" ]; then
    # Increment suffix: a→b, b→c, etc.
    NEXT_SUFFIX=$(echo "$LAST_SUFFIX" | tr 'a-y' 'b-z')
    SUGGESTED_NUMBER="${COMMIT_PREFIX}${NEXT_SUFFIX}"
  else
    # First grouped commit - suggest 'a' suffix
    SUGGESTED_NUMBER="${COMMIT_PREFIX}a"
  fi

  # Calculate file overlap and present options
  # [1] AIGCODE-157a (grouped) - Recommended
  # [2] AIGCODE-157 (new independent commit)
fi
```

**Confidence levels:**
- **HIGH (≥80%)**: Same files, <1 hour
- **MEDIUM (60-79%)**: >50% overlap, <4 hours
- **LOW (<60%)**: Skip, use new number

**Note:** Grouping works identically for both issue-based (AIGCODE-157) and sequential (AIGCODE-124) formats.

### Step 3: Analyze Changes

```bash
# Get recent commits on current branch (last 4 hours, max 10 commits)
git log --since="4 hours ago" -10 --format="%H|%s|%ar"

# For each recent commit:
#   1. Get files changed in that commit: git diff-tree --no-commit-id --name-only -r <commit>
#   2. Get currently staged files: git diff --cached --name-only
#   3. Calculate file overlap
```

**Overlap calculation:**

```bash
# Get staged files
STAGED_FILES=$(git diff --cached --name-only)
STAGED_COUNT=$(echo "$STAGED_FILES" | wc -l | tr -d ' ')

# Guard against division by zero
if [ "$STAGED_COUNT" -eq 0 ]; then
  echo "No staged files"
  exit 1
fi

# For each recent commit
for COMMIT in $(git log --since="4 hours ago" -10 --format="%H|%s|%ar"); do
  COMMIT_HASH=$(echo "$COMMIT" | cut -d'|' -f1)
  COMMIT_MSG=$(echo "$COMMIT" | cut -d'|' -f2)
  COMMIT_AGE=$(echo "$COMMIT" | cut -d'|' -f3)

  # Get files from that commit
  COMMIT_FILES=$(git diff-tree --no-commit-id --name-only -r "$COMMIT_HASH")

  # Find overlapping files
  OVERLAPPING=$(comm -12 <(echo "$STAGED_FILES" | sort) <(echo "$COMMIT_FILES" | sort))

  # Handle empty overlapping files
  if [ -z "$OVERLAPPING" ]; then
    OVERLAP_COUNT=0
  else
    # Count lines with content (file paths). Pattern . matches any character.
    # More reliable than wc -l for strings without trailing newlines.
    OVERLAP_COUNT=$(echo "$OVERLAPPING" | grep -c .)
  fi

  # Calculate overlap percentage
  OVERLAP_PCT=$((100 * $OVERLAP_COUNT / $STAGED_COUNT))

  # Determine confidence level
done
```

**Confidence scoring:**

| Condition | Confidence Level | Action |
|-----------|------------------|---------|
| Same file(s) AND <1 hour | **HIGH (≥80%)** | Prompt user to group |
| Same file(s) AND <4 hours | **MEDIUM (60-79%)** | Prompt user to group |
| >50% file overlap AND <1 hour | **HIGH (≥80%)** | Prompt user to group |
| >30% file overlap AND <4 hours | **MEDIUM (60-79%)** | Prompt user to group |
| Message indicates refinement ("fix", "gap", "improve") | **+10% bonus** | |
| <30% overlap OR >4 hours | **LOW (<60%)** | Skip detection, use new number |

**User prompt when confidence ≥60%:**

```
🔍 Related Commit Detected

These changes appear related to AIGCODE-067:
  • Same file: scripts/test-guard.ts
  • Committed: 22 minutes ago
  • Message: "Add test count and coverage guard"

Your staged changes:
  • scripts/test-guard.ts (validation and fail-fast logic)

Options:
  [1] Use AIGCODE-067b (group with related work) - Recommended
  [2] Use AIGCODE-070 (new independent change)
  [3] Show diff comparison

Choice:
```

**Diff comparison (option 3):**

```bash
# Show side-by-side comparison
echo "=== Previous commit (AIGCODE-067) ==="
git show COMMIT_HASH --stat

echo "=== Current staged changes ==="
git diff --cached --stat

# Understand impact
git diff --cached
```

Analyzes:
- Files changed (count, types)
- Nature of changes (new feature, fix, refactor, docs, etc.)
- Scope (localized vs broad)

### Step 4: Generate Commit Message

**Format:**
```
AIGCODE-###: Brief summary (max 72 chars)

Optional detailed explanation of WHY (not WHAT).
Max 100 chars per line.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Examples:** See [Commit Message Examples](references/examples.md)

### Step 5: Create Commit

```bash
git commit -m "$(cat <<'EOF'
AIGCODE-019: Add validation hooks to skill frontmatter

Skills now self-validate using hooks in YAML frontmatter instead of
external validation scripts. Simpler, self-contained, auto-cleanup.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Verification:**
```bash
# Check commit was created
git log -1 --pretty=format:"%h %s"

# Verify format (runs automatically via Stop hook)
git log -1 --pretty=%B | grep -E '^AIGCODE-[0-9]{3}:'
```

## Configuration

Load settings from `config.yaml`:

```yaml
numbering:
  mode: "issue-based"  # or "sequential"
  prefix: AIGCODE
  issue:
    create_if_missing: true
  sequential:
    digits: 3

grouping:
  enabled: true
  time_window: "4 hours ago"
  confidence_threshold: 60

message:
  max_summary_length: 72
  include_co_author: true
```

**Customize for your project:**
```bash
# Switch to sequential mode
yq e '.numbering.mode = "sequential"' -i config.yaml

# Disable auto-create issues
yq e '.numbering.issue.create_if_missing = false' -i config.yaml

# Disable grouping
yq e '.grouping.enabled = false' -i config.yaml

# Adjust time window
yq e '.grouping.time_window = "2 hours ago"' -i config.yaml
```

## Error Handling

Common issues and solutions:

**Error: No staged changes**
- **Fix:** `git add <files>` before running skill
- **Why:** Skill needs changes to analyze

**Error: Commit format invalid**
- **Fix:** Check AIGCODE-### prefix exists
- **Why:** Stop hook validates format

**Error: Duplicate AIGCODE number**
- **Fix:** Pull latest from all branches
- **Why:** Someone else used that number

**More errors:** See [Error Handling Guide](references/error-handling.md)

## Best Practices

1. **Stage intentionally** - Only commit related changes
2. **Write descriptive summaries** - Explain WHY, not WHAT
3. **Keep commits focused** - One logical change per commit
4. **Use grouping wisely** - Related iterative work
5. **Review before commit** - Check diff makes sense

**Detailed guidelines:** See [Best Practices](references/best-practices.md)

## Examples

**Example 1: Issue-based commit (active story exists)**
```bash
# Active story: #157 - Add LSP section
git add content/week_2/lsp.md
/commit
# → ✓ Using issue #157: Add LSP section to course content
# → AIGCODE-157: Add LSP section to course content
```

**Example 2: Auto-create issue (no active story)**
```bash
# No .agile-dev-team/active-story.json exists
git add lambda/auth.ts
/commit
# → 📋 No active story. Creating one...
# → Enter issue title: Fix token expiration check
# → Creating GitHub issue...
# → ✓ Created issue #158
# → AIGCODE-158: Fix token expiration check in auth lambda
```

**Example 3: Grouped commits with issue**
```bash
# First commit
git add content/week_2/lsp.md
/commit  # → AIGCODE-157: Add LSP section

# Related work 30 mins later
echo "more content" >> content/week_2/lsp.md
git add content/week_2/lsp.md
/commit
# Detects relationship, offers:
# [1] AIGCODE-157a (group with related work) - Recommended (HIGH confidence)
# [2] AIGCODE-157 (new independent commit)
# User selects [1]
# → AIGCODE-157a: Add LSP architecture diagrams
```

**Example 4: PR-based grouping (code review fixes)**
```bash
# Initial work
git checkout -b feature/auth-improvements
git add auth.ts
/commit  # → AIGCODE-245: Add user authentication

# Create PR
/mr  # → Created PR #42

# Code review provides feedback: "Add timeout protection"
git add auth.ts
/commit
# → 🔀 Open PR #42 detected
# → ✓ Grouping under AIGCODE-245 (code review fixes)
# → AIGCODE-245a: Add timeout protection to token exchange

# More review feedback: "Fix memory leak"
git add auth.ts
/commit
# → 🔀 Open PR #42 detected
# → ✓ Grouping under AIGCODE-245 (code review fixes)
# → AIGCODE-245b: Fix memory leak in timeout handler

# All commits in PR now share AIGCODE-245 for clear traceability
```

**Example 5: Sequential fallback (issue creation failed)**
```bash
# Issue creation fails (network issue, auth failure)
git add test.txt
/commit
# → 📋 No active story. Creating one...
# → ❌ Failed to create issue. Falling back to sequential numbering...
# → AIGCODE-124: Add test file  (uses sequential counter)
```

**More examples:** See [Complete Example Flows](references/example-flows.md)

## Troubleshooting

**Issue: Wrong AIGCODE number used**
- Check: `git log --all --grep="AIGCODE-" | grep <number>`
- Fix: Amend commit if not pushed
- Prevention: Always use `--all` flag

**Issue: Grouping not detected**
- Check: File overlap and time window in config.yaml
- Adjust: Increase confidence_threshold or time_window
- Debug: Review recent commit history

**More issues:** See [Troubleshooting Guide](references/troubleshooting.md)

## Advanced Usage

- **Custom numbering schemes** - PROJ-###, TICKET-###
- **Skip grouping detection** - `grouping.enabled: false`
- **Auto-commit without prompt** - `behavior.prompt_before_commit: false`
- **Multiple prefixes** - Different prefixes for feature vs fix branches

**Details:** See [Advanced Usage](references/advanced-usage.md)

## Integration

Works seamlessly with:
- **/mr skill** - Create PRs after commit
- **Pre-commit hooks** - Linting, formatting
- **CI/CD pipelines** - Automated builds
- **Issue tracking** - Link commits to issues

## Validation

Automatic validation via Stop hook:
- ✓ Verifies AIGCODE-### format
- ✓ Blocks invalid commits (exit code 2)
- ✓ Shows clear error messages

## Resources

- **Counter Algorithm:** [aigcode-counter.md](references/aigcode-counter.md)
- **Message Examples:** [examples.md](references/examples.md)
- **Error Handling:** [error-handling.md](references/error-handling.md)
- **Best Practices:** [best-practices.md](references/best-practices.md)
- **Example Flows:** [example-flows.md](references/example-flows.md)
- **Troubleshooting:** [troubleshooting.md](references/troubleshooting.md)
- **Advanced Usage:** [advanced-usage.md](references/advanced-usage.md)
