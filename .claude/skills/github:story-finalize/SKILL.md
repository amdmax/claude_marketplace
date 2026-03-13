---
name: github:story-finalize
description: "Closes the loop on a completed story: updates the issue, links the PR, labels it, assigns it, and adds it to the project board."
argument-hint: "[issue-url] [project-url]"
disable-model-invocation: true
---

Active story context: !`cat .agile-dev-team/active-story.json 2>/dev/null || echo "none"`
Active project: !`cat .agile-dev-team/active-project.json 2>/dev/null || echo "none"`

# Finalize Story

Closes the loop on a completed story: updates the issue, links the PR, labels it, assigns it, and adds it to the project board.

Arguments:
- $ARGUMENTS[0] — issue URL or number (optional; falls back to active-story.json, then asks)
- $ARGUMENTS[1] — GitHub project URL, e.g. https://github.com/orgs/aigensa/projects/2
                  (optional; parse owner + project number from URL; default: owner=aigensa project=1)

**Step 1: Resolve the Issue**
- If $ARGUMENTS[0] is provided, use it as the issue URL or number
- Otherwise extract issue number from active-story.json (shown above) if present
- Otherwise ask the user

**Step 2: Find the PR**
- Get current branch via `git rev-parse --abbrev-ref HEAD`
- Find open PR for that branch via `gh pr list`
- If none found, ask the user for the PR URL

**Step 3: Update Issue Body**
- Ask user: what was built (1-3 bullets), files changed, notable decisions
- Replace issue body using `gh issue edit` with a structured Summary / Changes / PR section

**Step 4: Add PR Link Comment**
- `gh issue comment` with "Implemented in PR #N: URL"
- Creates GitHub cross-reference so PR sidebar shows linked issue

**Step 5: Apply Labels**
- Ask or infer type label (`bug`, `enhancement`, `documentation`) and domain label (`course materials`, `infrastructure`, `lambda`, `platform`)
- Create label if it doesn't exist, then apply with `gh issue edit --add-label`

**Step 6: Assign to Self**
- `gh issue edit --add-assignee "@me"`

**Step 7: Add to GitHub Project**
Resolve the project URL in this order:
1. If $ARGUMENTS[1] is provided, parse OWNER and PROJECT_NUMBER from the URL
   - e.g. `https://github.com/orgs/aigensa/projects/2` → owner=aigensa, project=2
2. Otherwise read `url` from `.agile-dev-team/active-project.json` (shown above) and parse OWNER + PROJECT_NUMBER from it
3. If neither is available, ask the user for the project URL

Once resolved:
- Run: `gh project item-add <PROJECT_NUMBER> --owner <OWNER> --url "$ISSUE_URL"`

**Step 8: Confirm**
- Print a summary of all actions taken
