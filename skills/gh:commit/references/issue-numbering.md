# Issue-Based Commit Numbering

> **Reference for:** commit skill
> **Context:** Using GitHub issue numbers with AIGCODE prefix

## Overview

Issue-based numbering links commits directly to GitHub issues while maintaining the AIGCODE prefix.

**Format**: `AIGCODE-{issueNumber}: {description}`

**Examples**:
- `AIGCODE-157: Add LSP section to course content`
- `AIGCODE-157a: Add architecture diagrams` (grouped)
- `AIGCODE-158: Fix token expiration check`

## Why Use Issue Numbers?

- **Traceability** - Direct link from commit to GitHub issue
- **Context** - Issue number tells you WHAT feature/fix
- **Consistency** - Keeps AIGCODE prefix familiar to project
- **Integration** - Works with `/fetch-story`, `/play-story`, `/mr`

## How It Works

### 1. Active Story Lookup (Primary)

```bash
# Read .agile-dev-team/active-story.json
ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json)
# Result: 157

# Format commit prefix (AIGCODE + issue number)
COMMIT_PREFIX="AIGCODE-${ISSUE_NUMBER}"
# Result: "AIGCODE-157"
```

### 2. Auto-Create When Missing

If `.agile-dev-team/active-story.json` doesn't exist:

1. Commit skill invokes `/create-story`
2. User prompted for issue title (suggested from staged changes)
3. GitHub issue created via `gh issue create` (minimal: title, body)
4. Minimal data written to `.agile-dev-team/active-story.json` (issueNumber, title, body, url)
5. Commit proceeds with AIGCODE-{issueNumber}

**Note**: Does NOT add to Projects, set status, or store complex metadata. Fast path for commits.

### 3. Grouping with Suffixes

Multiple commits for same issue:

```bash
AIGCODE-157: Add LSP section        # First commit
AIGCODE-157a: Add diagrams          # Related work (grouped)
AIGCODE-157b: Fix typos             # More related work
```

**Detection**:
- Checks last 4 hours of commits
- Calculates file overlap percentage
- Suggests suffix if ≥60% overlap

## Fallback to Sequential

If issue creation fails (network issue, auth failure):

```bash
# Attempted issue creation
/create-story
# → Error: GitHub authentication failed

# Commit skill falls back to sequential numbering
AIGCODE-124: Fix test timeout  (sequential: finds highest, increments)

# User can fix and link later
gh auth login
/create-story --title "Fix test timeout"
# → Creates issue #159, link in PR description
```

## Configuration

```yaml
numbering:
  mode: "issue-based"
  prefix: "AIGCODE"  # Required for this project
  issue:
    create_if_missing: true  # Auto-invoke /create-story
  sequential:
    digits: 3  # Fallback format
```

## Best Practices

✅ **Keep active story current** - Run `/fetch-story` when switching work
✅ **Use descriptive issue titles** - They appear in commit history
✅ **Group related commits** - Use suffixes for iterative work
✅ **Prefix consistency** - Always AIGCODE, regardless of mode

❌ **Don't manually edit** `.agile-dev-team/active-story.json` - use skills
❌ **Don't skip issue creation** - Traceability is important
❌ **Don't reuse closed issues** - Fetch/create new ones

## Workflow Comparison

### Issue-Based (Planned Work)
```bash
# Start work on planned story
/fetch-story
# → ✓ Found story #157 from GitHub Projects
# → ✓ Status → In Progress

# Commit using issue number
git add content/week_2/lsp.md
/commit
# → ✓ Using issue #157: Add LSP section to course content
# → AIGCODE-157: Add LSP section
```

### Issue-Based (Ad-hoc Work)
```bash
# Quick fix, no planned story
git add lambda/auth.ts
/commit
# → 📋 No active story. Creating one...
# → ✓ Created issue #158
# → AIGCODE-158: Fix auth bug
```

### Sequential (Fallback)
```bash
# Issue creation fails
/commit
# → ⚠️  Failed to create issue
# → Using sequential: AIGCODE-124
```
