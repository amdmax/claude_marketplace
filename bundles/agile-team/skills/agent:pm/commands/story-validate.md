---
name: "pm:story-validate"
description: "Validate .agile-dev-team/story-extract.yaml against story completeness requirements."
tools:
  - Bash
  - Read
---

# story-validate — Story YAML Validation

## Purpose

Validate `.agile-dev-team/story-extract.yaml` against story requirements. Reports errors and warnings with actionable remediation hints. Also runs automatically as a PostToolUse hook after `story-extract` writes the YAML.

---

## Workflow

### Step 1: Check file exists

```bash
[ -f .agile-dev-team/story-extract.yaml ] || echo "MISSING"
```

If missing: tell the user to run `story-extract` first.

### Step 2: Resolve extract path and run validation script

```bash
if [ -n "$ARGUMENT" ]; then
  ISSUE_NUMBER="$ARGUMENT"
else
  ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json 2>/dev/null)
fi

EXTRACT_FILE="docs/stories/${ISSUE_NUMBER}/extract.yaml"

echo "{\"tool_input\":{\"file_path\":\"${EXTRACT_FILE}\"}}" \
  | python3 "$(dirname "$0")/../scripts/validate-story-yaml.py"
```

### Step 3: Report results

On **errors** — list each failure with remediation hint:

| Error | Remediation |
|---|---|
| `description` empty | Story is missing Summary or Business Context — re-run story-extract after updating the issue |
| `hypothesis` empty | Story is missing User Story or Business Value — update the issue and re-extract |
| `acceptanceCriteria` empty | No ACs found — story is not ready for development; add Given/When/Then criteria to the issue |
| `milestones` empty list | Remove the `milestones` key or populate it |

On **warnings** — note them but do not block:

| Warning | Guidance |
|---|---|
| `hypothesis` missing "As a" / "I want" | Rewrite in user story format for clarity |
| AC items missing Given/When/Then | Rewrite ACs as testable statements |

### Step 4: Apply or remove "ready-for-development" label

If validation produced **zero errors** (warnings are allowed):

```bash
gh issue edit "$ISSUE_NUMBER" --add-label "ready-for-development"
```

If validation produced **one or more errors**:

```bash
gh issue edit "$ISSUE_NUMBER" --remove-label "ready-for-development" 2>/dev/null || true
```

If `ISSUE_NUMBER` is empty or null, skip silently.

---

## Validation Rules

| Field | Requirement | Severity |
|---|---|---|
| `story` | top-level key exists | error |
| `story.description` | non-empty string | error |
| `story.hypothesis` | non-empty string | error |
| `story.hypothesis` | contains "As a" / "I want" | warn |
| `story.acceptanceCriteria` | non-empty list, ≥ 1 item | error |
| `story.acceptanceCriteria[]` | each item contains Given/When/Then | warn |
| `story.milestones` | if present, non-empty list | error |
