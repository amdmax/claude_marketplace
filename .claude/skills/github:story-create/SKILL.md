---
name: github:story-create
description: "Quick GitHub issue creation for commit workflow. Creates minimal issues with project prefix and stores in .claude/active-story.json. Different from /fetch-story (planned work from Projects)."
author: "@thesolutionarchitect"
email: maksym.diabin@gmail.com
---

Active project: !`cat .agile-dev-team/active-project.json 2>/dev/null || echo "none"`

# Create Story Skill

> **Quick issue creation for ad-hoc commits**
> Minimal viable issue - no Projects integration, fast path

## Overview

Creates GitHub issues on-the-fly for commit workflow. When `/commit` detects no active story, this skill:

1. **Suggests title** from staged changes analysis
2. **Creates GitHub issue** with minimal fields (title, body, labels)
3. **Stores minimal data** in `.claude/active-story.json` (4 fields only)
4. **Returns to commit** workflow with issue number

**Not a replacement for `/fetch-story`** - use that for planned work from GitHub Projects.

## How It Works

### Step 1: Check Authentication

```bash
# Verify GitHub CLI is authenticated
if ! gh auth status &>/dev/null; then
  echo "❌ GitHub CLI not authenticated"
  echo "Run: gh auth login"
  exit 2
fi
```

**See:** @references/github-api.md for auth patterns

### Step 2: Analyze Staged Changes (Optional)

```bash
# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only)

if [ -n "$STAGED_FILES" ]; then
  # Analyze file types and generate title suggestion
  FILE_COUNT=$(echo "$STAGED_FILES" | wc -l | tr -d ' ')

  # Simple heuristics for title suggestion
  if echo "$STAGED_FILES" | grep -q "\.md$"; then
    SUGGESTED_ACTION="Add"
    SUGGESTED_AREA="documentation"
  elif echo "$STAGED_FILES" | grep -q "lambda/"; then
    SUGGESTED_ACTION="Update"
    SUGGESTED_AREA="Lambda function"
  elif echo "$STAGED_FILES" | grep -q "infrastructure/"; then
    SUGGESTED_ACTION="Update"
    SUGGESTED_AREA="infrastructure"
  elif echo "$STAGED_FILES" | grep -q "test"; then
    SUGGESTED_ACTION="Add"
    SUGGESTED_AREA="tests"
  else
    SUGGESTED_ACTION="Update"
    SUGGESTED_AREA="code"
  fi

  SUGGESTED_TITLE="$SUGGESTED_ACTION $SUGGESTED_AREA"
else
  SUGGESTED_TITLE=""
fi
```

### Step 3: Prompt for Issue Title

```bash
# Show suggestion if available
if [ -n "$SUGGESTED_TITLE" ]; then
  echo "Suggested title: $SUGGESTED_TITLE"
  echo -n "Enter issue title (or press Enter to accept): "
else
  echo -n "Enter issue title: "
fi

read -r ISSUE_TITLE

# Use suggestion if user pressed Enter
if [ -z "$ISSUE_TITLE" ] && [ -n "$SUGGESTED_TITLE" ]; then
  ISSUE_TITLE="$SUGGESTED_TITLE"
fi

# Validate non-empty
if [ -z "$ISSUE_TITLE" ]; then
  echo "❌ Issue title cannot be empty"
  exit 4
fi
```

### Step 4: Generate Issue Body (Optional)

```bash
# Auto-generate body from diff if enabled
if [ "$(yq e '.issue.auto_generate_body' config.yaml)" = "true" ]; then
  DIFF_LINES=$(yq e '.issue.diff_analysis_lines' config.yaml)

  # Get concise diff summary
  DIFF_SUMMARY=$(git diff --cached --stat | head -n "$DIFF_LINES")

  if [ -n "$DIFF_SUMMARY" ]; then
    ISSUE_BODY="Auto-created during commit workflow

Changes:
$DIFF_SUMMARY"
  else
    ISSUE_BODY=$(yq e '.issue.default_body' config.yaml)
  fi
else
  ISSUE_BODY=$(yq e '.issue.default_body' config.yaml)
fi
```

### Step 5: Create GitHub Issue

```bash
# Get repository slug from config
REPO_SLUG=$(yq e '.repository.slug' config.yaml)

# Create issue and capture URL output
# Note: gh issue create outputs the issue URL to stdout
ISSUE_URL=$(gh issue create \
  --repo "$REPO_SLUG" \
  --title "$ISSUE_TITLE" \
  --body "$ISSUE_BODY" 2>&1)

# Check success (gh returns non-zero on failure)
if [ $? -ne 0 ]; then
  echo "❌ Failed to create GitHub issue"
  echo "$ISSUE_URL"
  exit 3
fi

# Extract issue number from URL
# Format: https://github.com/owner/repo/issues/NUMBER
ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

# Validate extraction
if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ Failed to extract issue number from URL: $ISSUE_URL"
  exit 3
fi

echo "✓ Created issue #${ISSUE_NUMBER}: $ISSUE_TITLE"
```

**See:** @references/github-api.md for API details

### Step 6: Save Minimal Active Story

```bash
# Store only 4 fields needed by /commit
cat > .claude/active-story.json <<EOF
{
  "issueNumber": ${ISSUE_NUMBER},
  "title": "${ISSUE_TITLE}",
  "body": $(echo "$ISSUE_BODY" | jq -Rs .),
  "url": "${ISSUE_URL}"
}
EOF

echo "✓ Active story saved: .claude/active-story.json"
echo "$ISSUE_URL"
```

**Why minimal?** `/fetch-story` stores 15+ fields for planned work. This skill stores only what `/commit` needs for fast path.

### Step 7: Add to GitHub Project (if configured)

```bash
# Read active project config (loaded above)
PROJECT=$(cat .agile-dev-team/active-project.json 2>/dev/null)
if [ -n "$PROJECT" ] && [ "$PROJECT" != "none" ]; then
  PROJECT_URL=$(echo "$PROJECT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('url',''))")
  if [ -n "$PROJECT_URL" ]; then
    # Parse owner and number from URL
    # e.g. https://github.com/orgs/aigensa/projects/2 → owner=aigensa, number=2
    OWNER=$(echo "$PROJECT_URL" | sed 's|.*/orgs/\([^/]*\)/projects/.*|\1|')
    NUMBER=$(echo "$PROJECT_URL" | grep -o '[0-9]*$')
    gh project item-add "$NUMBER" --owner "$OWNER" --url "$ISSUE_URL"
    echo "✓ Added to project: $PROJECT_URL"
  fi
fi
```

Skip silently if `active-project.json` is absent or has no valid URL — this step is best-effort for the fast path.

## Configuration

Edit `config.yaml` to customize:

```yaml
repository:
  slug: "owner/repo"  # Your GitHub repository
  default_labels: ["story"]

issue:
  auto_generate_body: true  # Generate from git diff
  diff_analysis_lines: 50   # Max diff lines to analyze

errors:
  no_auth: "prompt"  # Show auth instructions
  network_failure: "fail"  # Exit on API failure
```

## Error Handling

**See:** @references/error-handling.md for comprehensive error scenarios

**Common issues**:
- **No auth**: `gh auth login` required
- **Network failure**: Falls back to sequential numbering in `/commit`
- **Invalid config**: Check `repository.slug` in config.yaml

## Examples

**See:** @references/examples.md for detailed usage patterns

**Quick example**:
```bash
# Stage changes
git add src/new-feature.ts

# Create issue
/create-story
# → Suggested title: Update code
# → Enter issue title: Add user authentication
# → ✓ Created issue #158
```

## vs. /fetch-story

| Feature | `/create-story` | `/fetch-story` |
|---------|----------------|----------------|
| **Purpose** | Ad-hoc commits | Planned work |
| **Data stored** | 4 fields | 15+ fields |
| **Projects** | No | Yes (status updates) |
| **Speed** | Fast (1 prompt) | Slower (full context) |
| **When to use** | Quick fixes | Sprint stories |

## Exit Codes

- `0`: Success - issue created, story saved
- `1`: Configuration error
- `2`: Authentication error
- `3`: GitHub API error
- `4`: User input error (empty title)

**See:** @references/error-handling.md for exit code usage
