---
name: fetch-story
description: >
  Populate $AGENT_DOCS_DIR/active-story.yaml from a GitHub issue.
  Accepts an issue number or URL as an optional argument.
  Falls back to the highest-priority Ready story from GitHub Projects
  when no argument is provided. Invokable with /fetch-story [number|url].
---

# Fetch Story

## Purpose

Write `$AGENT_DOCS_DIR/active-story.yaml` from a GitHub issue so downstream
skills (`/git:commit`, `/github:pull-request`, etc.) have story context.

## Workflow

### Step 1 — Resolve issue number

**With argument** (`/fetch-story 123` or `/fetch-story https://github.com/org/repo/issues/123`):

```bash
if echo "$ARGUMENT" | grep -q 'github.com'; then
  ISSUE_NUMBER=$(echo "$ARGUMENT" | grep -o '[0-9]*$')
else
  ISSUE_NUMBER="$ARGUMENT"
fi
```

**Without argument** — query GitHub Projects for highest-priority Ready story:

```bash
CONFIG="${AGENT_DOCS_DIR:-docs}/story-workflow-config.json"
[ ! -f "$CONFIG" ] && echo "❌ No argument given and no $CONFIG found." && exit 1

PROJECT_ID=$(jq -r '.projectId' "$CONFIG")
STATUS_FIELD_ID=$(jq -r '.fieldIds.status' "$CONFIG")
PRIORITY_FIELD_ID=$(jq -r '.fieldIds.priority' "$CONFIG")
READY_OPTION_ID=$(jq -r '.optionIds.status.ready' "$CONFIG")
P0_OPTION_ID=$(jq -r '.optionIds.priority.p0' "$CONFIG")
P1_OPTION_ID=$(jq -r '.optionIds.priority.p1' "$CONFIG")
P2_OPTION_ID=$(jq -r '.optionIds.priority.p2' "$CONFIG")

gh api graphql -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100) {
          nodes {
            id
            content {
              ... on Issue { number title url }
            }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  field { ... on ProjectV2SingleSelectField { id } }
                  optionId
                }
              }
            }
          }
        }
      }
    }
  }' -f projectId="$PROJECT_ID" > /tmp/project-data.json

ISSUE_NUMBER=$(python3 -c "
import json
data = json.load(open('/tmp/project-data.json'))
items = data['data']['node']['items']['nodes']
priority_order = {'$P0_OPTION_ID': 0, '$P1_OPTION_ID': 1, '$P2_OPTION_ID': 2}
ready = []
for item in items:
    if not item.get('content') or not item['content'].get('number'):
        continue
    fvs = item['fieldValues']['nodes']
    status = next((fv for fv in fvs if fv.get('field', {}).get('id') == '$STATUS_FIELD_ID'), None)
    if not status or status.get('optionId') != '$READY_OPTION_ID':
        continue
    pf = next((fv for fv in fvs if fv.get('field', {}).get('id') == '$PRIORITY_FIELD_ID'), None)
    ready.append({
        'number': item['content']['number'],
        'order': priority_order.get(pf.get('optionId', '') if pf else '', 99)
    })
ready.sort(key=lambda x: x['order'])
print(ready[0]['number'] if ready else '')
")

[ -z "$ISSUE_NUMBER" ] && echo "❌ No Ready stories found in the project." && exit 1
```

### Step 2 — Fetch issue data

```bash
ISSUE_DATA=$(gh issue view "$ISSUE_NUMBER" \
  --json number,title,body,url,labels,assignees)

[ -z "$ISSUE_DATA" ] && echo "❌ Issue #$ISSUE_NUMBER not found." && exit 1
```

### Step 3 — Write active-story.yaml

```bash
mkdir -p "${AGENT_DOCS_DIR:-docs}"

echo "$ISSUE_DATA" | jq '{
  issueNumber: .number,
  title:       .title,
  body:        .body,
  url:         .url,
  labels:      [.labels[].name],
  assignees:   [.assignees[].login]
}' > "${AGENT_DOCS_DIR:-docs}/active-story.yaml"

echo "✓ Active story set: #$(yq e '.issueNumber' "${AGENT_DOCS_DIR:-docs}/active-story.yaml") — $(yq e '.title' "${AGENT_DOCS_DIR:-docs}/active-story.yaml")"
```

## Exceptions

- **No argument + no config** → exit with instructions
- **No Ready stories found** → exit; user must mark a story Ready first
- **Issue not found** → exit; verify issue number and repo permissions
