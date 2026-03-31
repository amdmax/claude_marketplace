---
name: "pm:story-extract"
description: "Parse a GitHub story issue body and emit a canonical YAML artifact with acceptance criteria, hypothesis, description, and optional milestones."
tools:
  - Bash
  - Read
  - Write
---

# story-extract — Story YAML Extraction

## Purpose

Parse a GitHub story issue body and emit a canonical YAML artifact with acceptance criteria, hypothesis, description, and optional milestones.

Based on the `feature-story.yml` template (`academy/.github/ISSUE_TEMPLATE/feature-story.yml`).

---

## Input

- **Default:** `.agile-dev-team/active-story.json` → `.body` field
- **Explicit:** issue number passed as argument → `gh issue view <N> --json body -q '.body'`

---

## Workflow

### Step 1: Resolve Issue Number and Story Body

```bash
if [ -n "$ARGUMENT" ]; then
  ISSUE_NUMBER="$ARGUMENT"
  BODY=$(gh issue view "$ARGUMENT" --json body -q '.body')
else
  ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json 2>/dev/null)
  BODY=$(jq -r '.body' .agile-dev-team/active-story.json)
fi

if [ -z "$ISSUE_NUMBER" ] || [ "$ISSUE_NUMBER" = "null" ]; then
  echo "ERROR  No issue number. Pass one or run /github:story-fetch first."
  exit 1
fi
```

### Step 1b: Create Story Branch

Ensure a feature branch exists for this story, branching off `master` (or `main` if `master` does not exist):

```bash
BASE=$(git rev-parse --verify master &>/dev/null && echo master || echo main)
BRANCH="feature/${ISSUE_NUMBER}"

# If branch already exists locally or remotely, check it out; otherwise create it
if git show-ref --verify --quiet "refs/heads/${BRANCH}" || \
   git ls-remote --exit-code origin "${BRANCH}" &>/dev/null; then
  git checkout "${BRANCH}"
else
  git checkout -b "${BRANCH}" "origin/${BASE}"
fi
```

Print the branch name that is now active.

### Step 2: Parse Template Sections

Map GitHub issue body sections (from feature-story template) to YAML fields:

| Section header(s) | YAML field |
|---|---|
| `### Summary` | `description` (prefix) |
| `### Business Context` | `description` (appended) |
| `### User Story` | `hypothesis` (prefix) |
| `### Business Value / Expected Outcome` | `hypothesis` (appended) |
| `### Acceptance Criteria` | `acceptanceCriteria[]` |
| `### In Scope` or `### Milestones` | `milestones[]` (optional) |

**Parsing rules:**
- Match headers case-insensitively
- For `acceptanceCriteria`: include lines starting with `-` or `Given`; strip leading `- ` markers
- For `milestones`: extract list items from `In Scope` or `Milestones` section; **omit the key entirely** if no items found
- For `description`: join summary + business context with `. ` separator, collapsing whitespace
- For `hypothesis`: join user story + business value with `\n` separator

### Step 3: Validate Coverage

Warn (do not fail) if:
- `acceptanceCriteria` is empty → `⚠ No acceptance criteria found`
- `description` is blank → `⚠ Summary or Business Context missing`
- `hypothesis` is blank → `⚠ User Story or Business Value missing`

### Step 4: Write Output

```bash
mkdir -p "docs/stories/${ISSUE_NUMBER}"
OUTPUT="docs/stories/${ISSUE_NUMBER}/extract.yaml"
```

Write to `$OUTPUT`.

---

## Output Schema

```yaml
story:
  description: |
    <summary>. <business_context>
  hypothesis: |
    <user_story>
    <business_value>
  acceptanceCriteria:
    - "Given ... When ... Then ..."
    - "..."
  milestones:        # key omitted entirely when no milestones detected
    - "..."
```

---

## Validation

After writing, confirm:
- File `docs/stories/${ISSUE_NUMBER}/extract.yaml` exists
- `story.acceptanceCriteria` is a non-empty array
- `story.description` and `story.hypothesis` are non-empty strings
- `story.milestones` key is absent (not null) when no milestones were found
