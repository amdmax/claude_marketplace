# GitHub API Integration

> **Reference for:** create-story skill
> **Context:** Minimal GitHub issue creation via CLI

## Overview

This skill uses GitHub CLI (`gh`) for simple, fast issue creation. Unlike `/fetch-story` which integrates with GitHub Projects, this skill focuses on the minimal viable issue for commit workflow.

## Authentication Check

```bash
# Check if GitHub CLI is authenticated
if ! gh auth status &>/dev/null; then
  echo "❌ GitHub CLI not authenticated"
  echo "Run: gh auth login"
  exit 1
fi
```

## Create Issue (Minimal)

```bash
# Create issue and capture URL output
ISSUE_URL=$(gh issue create \
  --repo "$(yq e '.repository.slug' config.yaml)" \
  --title "$ISSUE_TITLE" \
  --body "$ISSUE_BODY" 2>&1)

# Check creation success
if [ $? -ne 0 ]; then
  echo "❌ Failed to create GitHub issue"
  echo "$ISSUE_URL"
  exit 1
fi

# Extract issue number from URL
# URL format: https://github.com/owner/repo/issues/NUMBER
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

# Validate extracted data
if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ Failed to extract issue number from URL: $ISSUE_URL"
  exit 1
fi

echo "✓ Issue #${ISSUE_NUMBER} created: $ISSUE_URL"
```

## Why Not Use --json?

The `gh issue create` command does **not** support `--json` flag (unlike `gh issue view` or `gh pr view`).

**What gh issue create returns:**
- On success: Issue URL printed to stdout (e.g., `https://github.com/owner/repo/issues/164`)
- On failure: Error message and non-zero exit code

**Extraction approach:**
- Capture stdout directly into `ISSUE_URL`
- Parse URL with regex to extract issue number: `grep -oE '[0-9]+$'`
- No JSON parsing needed (no jq required)

## Store Minimal Active Story

```bash
# Create minimal active story JSON (only 4 fields)
cat > .claude/active-story.json <<EOF
{
  "issueNumber": ${ISSUE_NUMBER},
  "title": "${ISSUE_TITLE}",
  "body": "${ISSUE_BODY}",
  "url": "${ISSUE_URL}"
}
EOF

echo "✓ Active story saved: .claude/active-story.json"
```

## Why Minimal?

**`/create-story` (this skill)**:
- **4 fields**: issueNumber, title, body, url
- **Purpose**: Quick issue for commits
- **No Projects**: Doesn't add to Projects or set status
- **Fast**: Minimal prompts and API calls

**`/fetch-story` (existing skill)**:
- **15+ fields**: All issue metadata, project fields, status
- **Purpose**: Get next planned work from Projects
- **Projects integration**: Updates status to "In Progress"
- **Comprehensive**: Full story context for development

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `gh: command not found` | GitHub CLI not installed | `brew install gh` |
| `gh auth status: failed` | Not authenticated | `gh auth login` |
| `HTTP 404` | Repository not found | Check config.yaml slug |
| `HTTP 422` | Invalid issue data | Validate title is non-empty |
