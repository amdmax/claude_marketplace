---
name: finalize-story
description: Wrap up a completed story by updating the GitHub issue with actual work done, linking the PR, applying labels, assigning to self, and adding to the GitHub Project. Use after implementation is done and a PR exists. Reads from .agile-dev-team/active-story.json if available; accepts a GitHub issue URL as an argument otherwise. Invokable with /finalize-story.
---

# Finalize Story

Closes the loop on a completed story: updates the issue, links the PR, labels it, assigns it, and adds it to the project board.

## Step 1: Resolve the Issue

**From active story file (preferred):**
```bash
STORY_FILE=".agile-dev-team/active-story.json"
if [ -f "$STORY_FILE" ]; then
  ISSUE_NUMBER=$(jq -r '.issueNumber' "$STORY_FILE")
  ISSUE_URL=$(jq -r '.url' "$STORY_FILE")
fi
```

**From argument:** If a GitHub issue URL was passed (e.g. `https://github.com/org/repo/issues/384`), extract the issue number from it.

If neither is available, ask the user for the issue URL before proceeding.

## Step 2: Find the PR

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PR_DATA=$(gh pr list --head "$CURRENT_BRANCH" --state open --json number,url --jq '.[0]')
PR_NUMBER=$(echo "$PR_DATA" | jq -r '.number')
PR_URL=$(echo "$PR_DATA" | jq -r '.url')
```

If no open PR exists on the current branch, ask the user for the PR URL.

## Step 3: Update Issue Body

Replace the issue body with a summary of actual work done. Ask the user:
- What was built (1-3 bullet points)
- What files changed
- Any notable decisions made

Then update:
```bash
gh issue edit "$ISSUE_NUMBER" --body "$(cat <<'EOF'
## Summary
[user-provided summary]

## Changes
[files changed, decisions made]

## PR
Delivered in [PR_URL]
EOF
)"
```

## Step 4: Add PR Link Comment

```bash
gh issue comment "$ISSUE_NUMBER" --body "Implemented in PR #${PR_NUMBER}: ${PR_URL}"
```

This creates a GitHub cross-reference so the PR sidebar shows the linked issue automatically.

## Step 5: Apply Labels

Ask the user (or infer from context) for:
- **Type label**: `bug`, `enhancement`, `documentation`, or other
- **Domain label**: e.g. `course materials`, `infrastructure`, `lambda`, `platform`

For each label, create it if it doesn't exist:
```bash
# Check if label exists; create if not
gh label list --repo "$REPO" | grep -q "course materials" || \
  gh label create "course materials" \
    --color "0075ca" \
    --description "Changes to course content, markdown, or educational materials" \
    --repo "$REPO"

# Apply labels
gh issue edit "$ISSUE_NUMBER" \
  --add-label "enhancement" \
  --add-label "course materials" \
  --repo "$REPO"
```

**Default label colors by domain:**
| Domain | Color |
|--------|-------|
| course materials | `0075ca` (blue) |
| infrastructure | `e4e669` (yellow) |
| lambda | `d93f0b` (orange) |
| platform | `0e8a16` (green) |

## Step 6: Assign to Self

```bash
gh issue edit "$ISSUE_NUMBER" --add-assignee "@me" --repo "$REPO"
```

## Step 7: Add to GitHub Project

```bash
# Project number 1 = "Vibe Coding Course"
gh project item-add 1 --owner aigensa --url "$ISSUE_URL"
```

If the user specifies a different project, use that project number. Run `gh project list --owner aigensa` to show available projects.

## Step 8: Confirm

Show a summary of what was done:
```
✓ Issue #384 updated with work summary
✓ PR #505 linked (comment + body)
✓ Labels applied: enhancement, course materials
✓ Assigned to @me
✓ Added to Vibe Coding Course project
```

## Configuration

**Repo:** Infer from `gh repo view --json nameWithOwner --jq '.nameWithOwner'`

**Project number:** Default is `1` (Vibe Coding Course). Override by passing `--project 2` or asking the user which project applies.

## Common Patterns

**Content work:** labels `enhancement` + `course materials`, project `1`

**Infrastructure work:** labels `enhancement` + `infrastructure`, project `1`

**Bug fix:** labels `bug` + relevant domain, project `1`
