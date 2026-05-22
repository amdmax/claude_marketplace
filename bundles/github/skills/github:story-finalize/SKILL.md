---
name: github:story-finalize
description: "Close the loop on any completed GitHub issue (story, bug, task, or chore): update the issue body with actual work done, link the PR, apply type and domain labels, assign to self, and add to the GitHub Project board. Use after implementation is merged or verified complete. Accepts a GitHub issue URL or number as argument; falls back to $AGENT_DOCS_DIR/active-story.yaml. Invokable with /gh:story-finalize."
---

# Finalize Story

Closes the loop on a completed story: updates the issue, links the PR, labels it, assigns it, and adds it to the project board.

## Step 1: Resolve the Issue

**From active story file (preferred):**
```bash
STORY_FILE="${AGENT_DOCS_DIR:-docs}/active-story.yaml"
if [ -f "$STORY_FILE" ]; then
  ISSUE_NUMBER=$(yq e '.issueNumber' "$STORY_FILE")
  ISSUE_URL=$(yq e '.url' "$STORY_FILE")
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

## Step 7: Add to GitHub Project and Set Status to In Review

```bash
# Project number 1 = "Vibe Coding Course"
gh project item-add 1 --owner aigensa --url "$ISSUE_URL"

# Get the project node ID and the newly added item node ID
PROJECT_ID=$(gh project view 1 --owner aigensa --format json --jq '.id')
ITEM_ID=$(gh project item-list 1 --owner aigensa --format json --jq \
  ".items[] | select(.content.url == \"$ISSUE_URL\") | .id")

# Get the Status field ID and the "In Review" option ID
STATUS_FIELD_ID=$(gh project field-list 1 --owner aigensa --format json --jq \
  '.fields[] | select(.name == "Status") | .id')
IN_REVIEW_OPTION_ID=$(gh project field-list 1 --owner aigensa --format json --jq \
  '.fields[] | select(.name == "Status") | .options[] | select(.name == "In Review") | .id')

# Update item status to "In Review"
gh project item-edit \
  --project-id "$PROJECT_ID" \
  --id "$ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" \
  --single-select-option-id "$IN_REVIEW_OPTION_ID"
```

If the user specifies a different project, use that project number. Run `gh project list --owner aigensa` to show available projects.

If "In Review" option doesn't exist, check available options:
```bash
gh project field-list 1 --owner aigensa --format json --jq \
  '.fields[] | select(.name == "Status") | .options[].name'
```
Then use the closest equivalent (e.g., "Review", "Ready for Review").

## Step 8: Switch Back to Master

```bash
git checkout master
git pull origin master
echo "✓ Switched to master and pulled latest"
```

## Step 9: Confirm

Show a summary of what was done:
```
✓ Issue #384 updated with work summary
✓ PR #505 linked (comment + body)
✓ Labels applied: enhancement, course materials
✓ Assigned to @me
✓ Added to Vibe Coding Course project → In Review
✓ Switched to master branch
```

## Configuration

**Repo:** Infer from `gh repo view --json nameWithOwner --jq '.nameWithOwner'`

**Project number:** Default is `1` (Vibe Coding Course). Override by passing `--project 2` or asking the user which project applies.

## Common Patterns

**Content work:** labels `enhancement` + `course materials`, project `1`

**Infrastructure work:** labels `enhancement` + `infrastructure`, project `1`

**Bug fix:** labels `bug` + relevant domain, project `1`
