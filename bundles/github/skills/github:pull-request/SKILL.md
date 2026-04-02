---
name: github:pull-request
description: >
  Create or update a PR coupled to the active story in .agile-dev-team/active-story.yaml.
  Auto-commits uncommitted changes via /git:commit. Checks for an existing open PR on
  the current branch — creates one if absent, updates it if present. Mirrors labels,
  assignees, and project from the linked GitHub issue. PR body is minimal: Closes #N
  plus changed domains only. Auto-resolves merge conflicts after creation.
---

# Pull Request — Story-Coupled Workflow

## Purpose

Create or update a PR for the current branch, coupled to the active story.
All PR fields (title, labels, assignees, project) are sourced from the linked GitHub issue.

## Workflow

### Step 1 — Read active story

```bash
STORY_FILE=".agile-dev-team/active-story.yaml"
if [ ! -f "$STORY_FILE" ]; then
  echo "❌ No active story found at $STORY_FILE"
  echo "Run /fetch-story or /play-story first."
  exit 1
fi

ISSUE_NUMBER=$(yq e '.issueNumber' "$STORY_FILE")
ISSUE_TITLE=$(yq e '.title' "$STORY_FILE")
```

### Step 2 — Auto-commit uncommitted changes

If uncommitted changes exist, invoke `/git:commit`. Then verify commits exist ahead of the default branch.

```bash
if [ -n "$(git status --short)" ]; then
  /git:commit || { echo "❌ Commit failed. Cannot create PR."; exit 1; }
fi

DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')
COMMITS_AHEAD=$(git rev-list --count "origin/${DEFAULT_BRANCH}..HEAD")

if [ "$COMMITS_AHEAD" -eq 0 ]; then
  echo "❌ No commits ahead of $DEFAULT_BRANCH. Nothing to PR."
  exit 1
fi
```

### Step 3 — Check for existing open PR

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
PR_DATA=$(gh pr list --head "$CURRENT_BRANCH" --state open \
  --json number,url --jq '.[0]')
PR_NUMBER=$(echo "$PR_DATA" | jq -r '.number // empty')
PR_URL=$(echo "$PR_DATA" | jq -r '.url // empty')
```

- Non-empty `PR_NUMBER` → go to Step 4b (update)
- Empty → go to Step 4a (create)

### Step 4a — Create PR

Build the PR body (Step 5), then:

```bash
PR_URL=$(gh pr create \
  --title "$ISSUE_TITLE" \
  --body "$PR_BODY" \
  --base "$DEFAULT_BRANCH")

PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
echo "✓ PR created: #$PR_NUMBER — $PR_URL"
```

### Step 4b — Update existing PR

Build the PR body (Step 5), then:

```bash
gh pr edit "$PR_NUMBER" \
  --title "$ISSUE_TITLE" \
  --body "$PR_BODY"

echo "✓ PR updated: #$PR_NUMBER — $PR_URL"
```

### Step 5 — Build minimal PR body

Detect changed domains from the diff. One bullet per domain — nothing else.

```bash
CHANGED_FILES=$(git diff --name-only "origin/${DEFAULT_BRANCH}..HEAD")

DOMAIN_LINES=""
echo "$CHANGED_FILES" | grep -q '^src/'            && DOMAIN_LINES="${DOMAIN_LINES}- **src/**: Frontend changes\n"
echo "$CHANGED_FILES" | grep -q '^infrastructure/' && DOMAIN_LINES="${DOMAIN_LINES}- **infrastructure/**: CDK changes\n"
echo "$CHANGED_FILES" | grep -q '^lambda/'         && DOMAIN_LINES="${DOMAIN_LINES}- **lambda/**: Lambda changes\n"
echo "$CHANGED_FILES" | grep -q '^\.github/'       && DOMAIN_LINES="${DOMAIN_LINES}- **.github/**: CI/CD changes\n"
echo "$CHANGED_FILES" | grep -q '^content/'        && DOMAIN_LINES="${DOMAIN_LINES}- **content/**: Course content changes\n"
echo "$CHANGED_FILES" | grep -q '^docs/'           && DOMAIN_LINES="${DOMAIN_LINES}- **docs/**: Documentation changes\n"
echo "$CHANGED_FILES" | grep -qE '^[^/]+\.(json|ts|js|yaml|yml|md)$' \
                                                   && DOMAIN_LINES="${DOMAIN_LINES}- **root**: Config/build file changes\n"

PR_BODY=$(printf "Closes #%s\n\n%s\n---\n🤖 Generated with [Claude Code](https://claude.com/claude-code)" \
  "$ISSUE_NUMBER" "$DOMAIN_LINES")
```

### Step 6 — Mirror issue fields onto PR

Read labels, assignees, and project from the linked issue and apply them to the PR.

```bash
ISSUE_DATA=$(gh issue view "$ISSUE_NUMBER" \
  --json labels,assignees,projectItems)

LABELS=$(echo "$ISSUE_DATA" | jq -r '[.labels[].name] | join(",")')
ASSIGNEES=$(echo "$ISSUE_DATA" | jq -r '[.assignees[].login] | join(",")')
PROJECT_TITLE=$(echo "$ISSUE_DATA" | jq -r '.projectItems[0].project.title // empty')

[ -n "$LABELS" ]        && gh pr edit "$PR_NUMBER" --add-label "$LABELS"
[ -n "$ASSIGNEES" ]     && gh pr edit "$PR_NUMBER" --add-assignee "$ASSIGNEES"
[ -n "$PROJECT_TITLE" ] && gh pr edit "$PR_NUMBER" --project "$PROJECT_TITLE"
```

### Step 7 — Resolve merge conflicts

Poll GitHub mergeability up to 3 times (5 s apart). Auto-resolve with `--theirs` if conflicting.

```bash
for i in 1 2 3; do
  sleep 5
  MERGEABLE=$(gh pr view "$PR_NUMBER" --json mergeable --jq '.mergeable')

  [ "$MERGEABLE" = "MERGEABLE" ] && echo "✓ PR is clean — no conflicts" && break

  if [ "$MERGEABLE" = "CONFLICTING" ]; then
    echo "⚠️  Conflicts detected. Resolving automatically..."

    git fetch origin "$DEFAULT_BRANCH"
    git merge "origin/${DEFAULT_BRANCH}" --no-edit || true

    for FILE in $(git diff --name-only --diff-filter=U); do
      git checkout --theirs "$FILE"
      git add "$FILE"
    done

    git commit --no-verify -m "chore: resolve merge conflicts with ${DEFAULT_BRANCH}"
    git push

    echo "✓ Conflicts resolved and pushed"
    break
  fi
done
```

## Exceptions

- **No active story** → exit with instructions to run `/fetch-story`
- **Commit fails** → exit; user must fix commit errors before retrying
- **No commits ahead of default branch** → exit; nothing to PR
- **Merge conflicts with overlapping lines** → `--theirs` resolves in favor of incoming default branch changes; review manually if your changes and default branch both modified the same lines
