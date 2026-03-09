---
name: gh:pr
description: Create pull requests with automatic commit handling and story integration. Use when user wants to create a PR for current changes. Auto-commits uncommitted changes via /gh:commit skill, prevents duplicate PRs, links to active GitHub issue from .agile-dev-team/active-story.json, and creates new issues if needed.
---

# Pull Request Creation with Story Integration

## Overview

The `/pr` skill streamlines pull request creation by:
- Auto-committing uncommitted changes via `/commit`
- Preventing duplicate PRs
- Linking to active GitHub issues
- Creating issues automatically if none exists
- Handling merged/closed PR scenarios

## Quick Start

```bash
# Make your changes
git add .

# Create PR (auto-commits if needed)
/pr
```

**Expected workflow:**
1. Checks for uncommitted changes → invokes `/commit` if needed
2. Verifies commits exist ahead of master
3. Checks for existing PR → exits if open, creates new branch if merged/closed
4. Gets active story or creates issue from commits
5. Generates PR title and body from issue
6. Creates pull request with proper formatting

## Core Workflow

### Step 1: Auto-commit Uncommitted Changes

Checks for unstaged or uncommitted changes and invokes `/commit` skill if found:

```bash
# Check git status
STATUS=$(git status --short)

if [ -n "$STATUS" ]; then
  echo "📝 Uncommitted changes detected. Running /commit..."

  # Invoke /commit skill
  /commit

  # Wait for completion
  if [ $? -ne 0 ]; then
    echo "❌ Commit failed. Cannot create PR."
    exit 1
  fi

  echo "✓ Changes committed successfully"
fi
```

**Why this matters:**
- Ensures all work is committed before PR creation
- Uses `/commit` skill's automatic numbering and formatting
- Prevents empty PRs

### Step 2: Verify Commits Exist

Ensures there are commits ahead of master branch:

```bash
# Count commits ahead of origin/master
COMMITS_AHEAD=$(git rev-list --count origin/master..HEAD)

if [ "$COMMITS_AHEAD" -eq 0 ]; then
  echo "❌ No commits to create PR for"
  echo "Branch is up to date with master."
  exit 1
fi

echo "✓ Found $COMMITS_AHEAD commit(s) ahead of master"
```

**Edge cases handled:**
- Branch just created (no divergence from master)
- All commits already merged
- Working on master directly (warns user)

### Step 3: Check for Existing PR

Prevents duplicate PRs by checking if one already exists:

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Get PR data for current branch
PR_DATA=$(gh pr list --head "$CURRENT_BRANCH" \
  --json number,state,mergedAt,closedAt,url --jq '.[0]')

if [ -n "$PR_DATA" ]; then
  PR_NUMBER=$(echo "$PR_DATA" | jq -r '.number')
  PR_STATE=$(echo "$PR_DATA" | jq -r '.state')
  PR_URL=$(echo "$PR_DATA" | jq -r '.url')

  if [ "$PR_STATE" = "OPEN" ]; then
    echo "✓ Pull Request already exists: #$PR_NUMBER"
    echo "**URL:** $PR_URL"
    echo ""
    echo "Use 'gh pr view' to see details or push new commits to update."
    exit 0
  fi

  if [ "$PR_STATE" = "MERGED" ] || [ "$PR_STATE" = "CLOSED" ]; then
    echo "⚠️  Previous PR #$PR_NUMBER was $PR_STATE"
    echo "Creating new branch for additional work..."
    # Continue to Step 4
  fi
fi
```

**States handled:**
- **OPEN** → Show info and exit (no duplicate)
- **MERGED/CLOSED** → Continue to Step 4 (new branch needed)
- **None found** → Continue to Step 5 (proceed with PR creation)

### Step 4: Handle Merged/Closed PR

Creates a new branch when previous PR was merged or closed:

```bash
# Extract AIGCODE from most recent commit
AIGCODE=$(git log -1 --format=%s | grep -o 'AIGCODE-[0-9]*')

if [ -z "$AIGCODE" ]; then
  echo "❌ Could not extract AIGCODE from commit. Cannot create new branch."
  exit 1
fi

# Generate new branch name with timestamp
TIMESTAMP=$(date +%s)
NEW_BRANCH="fix/${AIGCODE,,}-${TIMESTAMP}"

echo "Creating new branch: $NEW_BRANCH"

# Create and checkout new branch
git checkout -b "$NEW_BRANCH"

# Push to origin with upstream tracking
git push -u origin "$NEW_BRANCH"

echo "✓ New branch created and pushed: $NEW_BRANCH"

# Update CURRENT_BRANCH for subsequent steps
CURRENT_BRANCH="$NEW_BRANCH"
```

**Why this approach:**
- Preserves original branch with merged PR
- Timestamp prevents naming conflicts
- Keeps AIGCODE for traceability
- Uses lowercase for branch naming convention

### Step 5: Get Active Story or Create Issue

Retrieves story context or creates an issue automatically:

```bash
STORY_FILE=".agile-dev-team/active-story.json"

if [ -f "$STORY_FILE" ]; then
  # Use existing active story
  ISSUE_NUMBER=$(jq -r '.issueNumber' "$STORY_FILE")
  ISSUE_TITLE=$(jq -r '.title' "$STORY_FILE")
  ISSUE_URL=$(jq -r '.url' "$STORY_FILE")
  ISSUE_BODY=$(jq -r '.body // ""' "$STORY_FILE")

  echo "✓ Using active story: #$ISSUE_NUMBER - $ISSUE_TITLE"
else
  # Auto-create issue from commits
  echo "📋 No active story found. Creating issue from commits..."

  # Extract title from first commit (remove AIGCODE prefix)
  TITLE=$(git log --format=%s origin/master..HEAD | head -1 | \
    sed 's/AIGCODE-[0-9]*: //')

  # Generate body from all commit messages
  BODY=$(git log --format='- %s%n%b' origin/master..HEAD | \
    sed '/^$/d')

  # Create GitHub issue
  ISSUE_URL=$(gh issue create \
    --title "$TITLE" \
    --body "$BODY")

  if [ $? -ne 0 ] || [ -z "$ISSUE_URL" ]; then
    echo "❌ Failed to create GitHub issue"
    exit 1
  fi

  # Extract issue number from URL
  ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -o '[0-9]*$')

  # Fetch storyId (node ID) for fuller schema compatibility
  STORY_ID=$(gh issue view "$ISSUE_NUMBER" --json id --jq '.id' 2>/dev/null || echo "")

  # Save to active-story.json with business fields
  cat > "$STORY_FILE" <<EOF
{
  "storyId": "$STORY_ID",
  "issueNumber": $ISSUE_NUMBER,
  "title": "$TITLE",
  "body": $(echo "$BODY" | jq -Rs .),
  "url": "$ISSUE_URL",
  "priority": "Unknown",
  "size": "Unknown",
  "labels": [],
  "projectItemId": "",
  "fetchedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  echo "✓ Created issue #$ISSUE_NUMBER"
fi
```

**Auto-creation logic:**
- Uses first commit summary as issue title
- Aggregates all commit messages as issue body
- Saves minimal data to `.agile-dev-team/active-story.json`
- Works seamlessly with `/commit` skill

### Step 6: Generate PR Title and Body

Creates PR content using issue context and commit history:

```bash
# PR title is issue title
PR_TITLE="$ISSUE_TITLE"

# Generate commit list with AIGCODE numbers
COMMIT_LIST=$(git log --format='- %s' origin/master..HEAD)

# Detect impact areas from changed files
CHANGED_FILES=$(git diff --name-only origin/master..HEAD)

IMPACT=""
if echo "$CHANGED_FILES" | grep -q '^infrastructure/'; then
  IMPACT="${IMPACT}- Infrastructure (CDK stacks)\n"
fi
if echo "$CHANGED_FILES" | grep -q '^lambda/'; then
  IMPACT="${IMPACT}- Lambda functions\n"
fi
if echo "$CHANGED_FILES" | grep -q '^src/'; then
  IMPACT="${IMPACT}- Static site builder\n"
fi
if echo "$CHANGED_FILES" | grep -q '^content/'; then
  IMPACT="${IMPACT}- Course content\n"
fi
if echo "$CHANGED_FILES" | grep -q '^docs/'; then
  IMPACT="${IMPACT}- Documentation\n"
fi

# Generate test plan items based on impact
TEST_PLAN=""
if echo "$IMPACT" | grep -q 'Infrastructure'; then
  TEST_PLAN="${TEST_PLAN}- [ ] CDK synth passes\n"
fi
if echo "$IMPACT" | grep -q 'Static site'; then
  TEST_PLAN="${TEST_PLAN}- [ ] Site builds successfully\n"
fi
if echo "$IMPACT" | grep -q 'Course content'; then
  TEST_PLAN="${TEST_PLAN}- [ ] Content renders correctly\n"
fi
TEST_PLAN="${TEST_PLAN}- [ ] Pre-commit hooks passed\n"
TEST_PLAN="${TEST_PLAN}- [ ] CI/CD validation will run on PR\n"

# Build PR body using template
PR_BODY=$(cat <<EOF
## Summary

$ISSUE_TITLE

${ISSUE_BODY:+$ISSUE_BODY
}

## Related Issue

Closes #${ISSUE_NUMBER}

$ISSUE_URL

## Changes

$COMMIT_LIST

## Test Plan

$TEST_PLAN

## Impact

$IMPACT

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)
```

**Template features:**
- Links to GitHub issue (Closes #...)
- Lists all commits with AIGCODE numbers
- Auto-generates test checklist based on changed files
- Shows impact areas for reviewers
- Claude Code attribution

### Step 7: Create Pull Request

Creates the PR and displays confirmation:

```bash
# Create PR using gh CLI
PR_URL=$(gh pr create \
  --title "$PR_TITLE" \
  --body "$PR_BODY" \
  --base master)

if [ $? -ne 0 ] || [ -z "$PR_URL" ]; then
  echo "❌ Failed to create pull request"
  exit 1
fi

# Extract PR number from URL
PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Pull Request Created: #$PR_NUMBER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "**URL:** $PR_URL"
echo "**Story:** $ISSUE_TITLE (#$ISSUE_NUMBER)"
echo "**Branch:** $CURRENT_BRANCH"
echo "**Commits:** $COMMITS_AHEAD ahead of master"
echo ""
echo "Next steps:"
echo "  • Review PR in GitHub"
echo "  • Wait for CI/CD validation"
echo "  • Request reviews if needed"
echo ""
```

**Output includes:**
- PR number and URL
- Linked issue information
- Branch name
- Commit count
- Next steps guidance

## Examples

### Example 1: With Active Story

```bash
# Start work on planned story
/fetch-story
# → ✓ Found story #157: Add LSP section to course content
# → ✓ Status → In Progress

# Make changes
git add content/week_2/lsp.md

# Create PR
/pr
# → ✓ Using active story: #157 - Add LSP section to course content
# → ✓ Pull Request Created: #89
# → **URL:** https://github.com/aigensa/vibe-coding-course/pull/89
```

### Example 2: Without Active Story (Auto-creates Issue)

```bash
# Quick fix, no active story
git add lambda/auth-edge/index.ts

# Create PR
/pr
# → 📝 Uncommitted changes detected. Running /commit...
# → ✓ Changes committed successfully
# → 📋 No active story found. Creating issue from commits...
# → ✓ Created issue #158
# → ✓ Pull Request Created: #90
```

### Example 3: PR Already Exists

```bash
# Try to create PR again
/pr
# → ✓ Pull Request already exists: #89
# → **URL:** https://github.com/aigensa/vibe-coding-course/pull/89
# →
# → Use 'gh pr view' to see details or push new commits to update.
```

### Example 4: Previous PR Merged

```bash
# Previous PR was merged, now making additional changes
git add content/week_2/lsp.md

/pr
# → ⚠️  Previous PR #89 was MERGED
# → Creating new branch for additional work...
# → Creating new branch: fix/aigcode-157-1738675200
# → ✓ New branch created and pushed
# → ✓ Pull Request Created: #91
```

## Integration with Other Skills

### `/commit` Skill
- **Auto-invoked** by `/pr` if uncommitted changes exist
- Handles AIGCODE numbering
- Formats commit messages
- Links to active story

### `/fetch-story` Skill
- Populates `.agile-dev-team/active-story.json`
- Sets up story context before work begins
- Updates GitHub Projects status

### `/play-story` Skill
- Comprehensive workflow setup
- Includes `/fetch-story` + context gathering + ADRs
- Best for complex feature work


## Troubleshooting

Common issues and solutions:

### Error: No commits ahead of master

**Symptom:**
```
❌ No commits to create PR for
Branch is up to date with master.
```

**Causes:**
- Branch just created without changes
- All commits already merged to master
- Working on master branch directly

**Solutions:**
```bash
# Make sure you're on a feature branch
git checkout -b feature/my-work

# Make changes and commit
git add .
/commit

# Try again
/pr
```

### Error: GitHub authentication failed

**Symptom:**
```
❌ Failed to create pull request
gh: authentication required
```

**Solutions:**
```bash
# Authenticate with GitHub CLI
gh auth login

# Follow prompts to authenticate
# Then try again
/pr
```

### Issue: /commit invoked but changes aren't committed

**Symptom:**
PR creation stops after `/commit` runs but no commit appears.

**Causes:**
- `/commit` skill encountered an error
- Pre-commit hooks failed
- Commit message validation failed

**Solutions:**
```bash
# Check git status
git status

# Check last commit
git log -1

# If no commit, manually run /commit to see error
/commit

# Fix any issues (hooks, format, etc.)
# Then retry /pr
/pr
```

### Error: PR created but story link missing

**Symptom:**
PR created successfully but "Closes #..." link is missing or incorrect.

**Causes:**
- `.agile-dev-team/active-story.json` is malformed
- Issue creation failed silently
- GitHub API issue

**Solutions:**
```bash
# Verify active-story.json
cat .agile-dev-team/active-story.json

# If missing or malformed, fetch a story
/fetch-story

# Or manually create issue
gh issue create --title "My work"

# Update PR description manually
gh pr edit <PR_NUMBER> --body "Closes #<ISSUE_NUMBER>"
```

### Error: Branch already exists

**Symptom:**
```
fatal: A branch named 'fix/aigcode-157-...' already exists.
```

**Causes:**
- Previous PR creation partially failed
- Branch name collision (rare due to timestamp)

**Solutions:**
```bash
# Delete the conflicting branch
git branch -D fix/aigcode-157-...

# Or use a different branch name manually
git checkout -b feature/my-fix

# Then retry
/pr
```

### Issue: Wrong base branch

**Symptom:**
PR created against wrong branch (not master).

**Causes:**
- Local git config has different default branch
- Repository uses `main` instead of `master`

**Solutions:**
```bash
# Check remote default branch
git remote show origin | grep "HEAD branch"

# Update skill to use correct base
# Edit SKILL.md and change --base master to --base main

# Or manually specify when creating
gh pr create --base main
```

### Issue: Test plan items not relevant

**Symptom:**
PR body includes test checklist items that don't apply.

**Causes:**
- Auto-generated test plan too broad
- File changes in multiple areas

**Solutions:**
```bash
# Edit PR description after creation
gh pr edit <PR_NUMBER>

# Or manually create PR with custom body
gh pr create --body "$(cat my-pr-body.md)"
```

**More troubleshooting:** See [Troubleshooting Guide](references/troubleshooting.md)

## Configuration

The `/pr` skill works out of the box but can be customized:

### Active Story File

**Location:** `.agile-dev-team/active-story.json`

**Format:**
```json
{
  "issueNumber": 157,
  "title": "Add LSP section to course content",
  "url": "https://github.com/aigensa/vibe-coding-course/issues/157",
  "body": "Course content needs LSP coverage..."
}
```

**Managed by:**
- `/fetch-story` - Fetches from GitHub Projects
- `/create-story` - Creates new issues
- `/pr` - Creates minimal issue if missing

### Base Branch

Default: `master`

To change:
1. Edit Step 7 in this skill
2. Change `--base master` to `--base main`
3. Update all references to `origin/master` in commit counting logic

### PR Body Template

Located at: [references/pr-body-template.md](references/pr-body-template.md)

Customize sections:
- Summary format
- Test plan items
- Impact categories
- Footer attribution

## Best Practices

1. **Use `/fetch-story` first** - Sets up proper story context
2. **Stage changes intentionally** - Only include related files
3. **Review auto-generated PR body** - Edit if needed via `gh pr edit`
4. **Keep commits focused** - One logical change per commit
5. **Wait for CI/CD** - Don't merge until validation passes

## Resources

- **PR Body Template:** [pr-body-template.md](references/pr-body-template.md)
- **Troubleshooting:** [troubleshooting.md](references/troubleshooting.md)
- **Related Skills:**
  - `/commit` - Commit automation
  - `/fetch-story` - Story management
  - `/mr` - Alternative PR creation
  - `/play-story` - Complete workflow setup
