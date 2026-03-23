# Issue-Based Commit Numbering

> **Reference for:** commit skill
> **Context:** Using GitHub issue numbers with {{PROJECT_PREFIX}} prefix

## Overview

Issue-based numbering links commits directly to GitHub issues while maintaining the {{PROJECT_PREFIX}} prefix.

**Format**: `{{PROJECT_PREFIX}}-{issueNumber}: {description}`

**Examples**:
- `{{PROJECT_PREFIX}}-157: Add LSP section to course content`
- `{{PROJECT_PREFIX}}-157a: Add architecture diagrams` (grouped)
- `{{PROJECT_PREFIX}}-158: Fix token expiration check`

## Why Use Issue Numbers?

- **Traceability** - Direct link from commit to GitHub issue
- **Context** - Issue number tells you WHAT feature/fix
- **Consistency** - Keeps {{PROJECT_PREFIX}} prefix familiar to project
- **Integration** - Works with `/fetch-story`, `/play-story`, `/mr`

## How It Works

### 1. Active Story Lookup

```bash
# Read .claude/active-story.json
ISSUE_NUMBER=$(jq -r '.issueNumber' .claude/active-story.json)
# Result: 157

# Format commit prefix ({{PROJECT_PREFIX}} + issue number)
COMMIT_PREFIX="{{PROJECT_PREFIX}}-${ISSUE_NUMBER}"
# Result: "{{PROJECT_PREFIX}}-157"
```

### 2. Auto-Create When Missing

If `.claude/active-story.json` doesn't exist:

1. Commit skill invokes `/create-story`
2. User prompted for issue title (suggested from staged changes)
3. GitHub issue created via `gh issue create` (minimal: title, body)
4. Minimal data written to `.claude/active-story.json` (issueNumber, title, body, url)
5. Commit proceeds with {{PROJECT_PREFIX}}-{issueNumber}

**Note**: Does NOT add to Projects, set status, or store complex metadata. Fast path for commits.

### 3. Grouping with Suffixes

Multiple commits for same issue:

```bash
{{PROJECT_PREFIX}}-157: Add LSP section        # First commit
{{PROJECT_PREFIX}}-157a: Add diagrams          # Related work (grouped)
{{PROJECT_PREFIX}}-157b: Fix typos             # More related work
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
{{PROJECT_PREFIX}}-124: Fix test timeout  (sequential: finds highest, increments)

# User can fix and link later
gh auth login
/create-story --title "Fix test timeout"
# → Creates issue #159, link in PR description
```

## Configuration

```yaml
numbering:
  mode: "issue-based"
  prefix: "{{PROJECT_PREFIX}}"  # Required for this project
  issue:
    create_if_missing: true  # Auto-invoke /create-story
  sequential:
    digits: 3  # Fallback format
```

## Best Practices

✅ **Keep active story current** - Run `/fetch-story` when switching work
✅ **Use descriptive issue titles** - They appear in commit history
✅ **Group related commits** - Use suffixes for iterative work
✅ **Prefix consistency** - Always {{PROJECT_PREFIX}}, regardless of mode

❌ **Don't manually edit** `.claude/active-story.json` - use skills
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
# → {{PROJECT_PREFIX}}-157: Add LSP section
```

### Issue-Based (Ad-hoc Work)
```bash
# Quick fix, no planned story
git add lambda/auth.ts
/commit
# → 📋 No active story. Creating one...
# → ✓ Created issue #158
# → {{PROJECT_PREFIX}}-158: Fix auth bug
```

### Sequential (Fallback)
```bash
# Issue creation fails
/commit
# → ⚠️  Failed to create issue
# → Using sequential: {{PROJECT_PREFIX}}-124
```
