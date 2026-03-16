---
name: fetch-story
description: Fetch the next Ready story from GitHub Projects by priority. Stores story data in .claude/active-story.json and updates GitHub status to In Progress. Invokable with /fetch-story.
---

# Fetch Story from GitHub Projects

## Overview

This skill fetches the highest-priority "Ready" story from the configured GitHub Project and prepares it for implementation. It:

1. **Queries GitHub Projects** using GraphQL to find stories with Status='Ready'
2. **Sorts by Priority** (P0 > P1 > P2) to select the most important story
3. **Stores story data** in `.claude/active-story.json` for use by other skills
4. **Updates GitHub status** to "In Progress" to reflect work has started

## Configuration

This skill requires configuration in `.claude/story-workflow-config.json`:

```json
{
  "storyWorkflow": {
    "projectId": "{{GITHUB_PROJECT_ID}}",
    "fieldIds": {
      "status": "{{FIELD_ID_STATUS}}",
      "priority": "PVTSSF_lADODvZ3Zc4BM9rkzg8GHB4",
      "size": "PVTSSF_lADODvZ3Zc4BM9rkzg8GHB8",
      "itemType": "PVTSSF_lADODvZ3Zc4BM9rkzg8GOqE",
      "techSpecStatus": "PVTSSF_lADODvZ3Zc4BM9rkzg8GOtI"
    },
    "optionIds": {
      "status": {
        "ready": "61e4505c",
        "inProgress": "47fc9ee4",
        "backlog": "f75ad846"
      },
      "priority": {
        "p0": "79628723",
        "p1": "0a877460",
        "p2": "da944a9c"
      }
    }
  }
}
```

## Schemas

This skill uses JSON Schema validation for data integrity:

- **`.claude/schemas/github-project-response.schema.json`**
  Validates GitHub Projects v2 API response structure before processing.
  Ensures all required fields (id, content, fieldValues) are present and correctly typed.

- **`.claude/schemas/active-story.schema.json`**
  Validates output data before writing to `.claude/active-story.json`.
  Enforces required fields, type constraints, and pattern validation (node IDs, URLs).

**Benefits:**
- Early error detection (fail fast on malformed API responses)
- Data integrity guarantees for downstream skills (gather-nfr, gather-context, create-adr)
- Self-documenting data structures

## Workflow

### Step 1: Verify Configuration

```bash
# Check settings file exists
if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json" ]; then
  echo "❌ Configuration missing"
  echo "   Expected: $CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json"
  echo "   Please create .claude/story-workflow-config.json with storyWorkflow configuration"
  exit 1
fi
```

**Read configuration:**
- Load `.claude/story-workflow-config.json`
- Extract `storyWorkflow.projectId`, `fieldIds`, and `optionIds`
- Validate all required fields are present

### Step 2: Authenticate with GitHub

⚠️ **SECURITY NOTE:** Never hardcode tokens in code or commit them to version control.

```bash
# Get GitHub token (uses gh CLI, does NOT expose token in code)
GITHUB_TOKEN=$(gh auth token)

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ GitHub authentication failed"
  echo "   Please run: gh auth login"
  exit 1
fi
```

**Authentication:**
- Uses GitHub CLI (`gh`) to obtain OAuth token securely
- Token is stored in memory only, never written to files or version control
- Token is used for GraphQL API authentication
- Requires `gh auth login` to be run beforehand

### Step 3: Query GitHub Projects for Ready Stories (Two-Phase Strategy)

**Optimization:** Use two-phase query to reduce data transfer. Phase 1 fetches candidates without the `body` field (saves ~80% bandwidth), then Phase 2 fetches body for selected story only.

**Phase 1: Fetch candidates (lightweight - ~20KB instead of ~100KB):**

```graphql
query GetReadyStories($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 20) {
        nodes {
          id
          content {
            ... on Issue {
              id
              number
              title
              url
              labels(first: 10) {
                nodes {
                  name
                }
              }
            }
          }
          fieldValues(first: 20) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field {
                  ... on ProjectV2SingleSelectField {
                    id
                    name
                  }
                }
                optionId
                name
              }
            }
          }
        }
      }
    }
  }
}
```

**Execute Phase 1 query:**

```bash
gh api graphql -F query=@query.graphql -f projectId="$PROJECT_ID" > /tmp/project-data.json
```

**Validate response schema:**

```bash
# Validate against .claude/schemas/github-project-response.schema.json
# Use ajv-cli or similar: npx ajv validate -s schema.json -d /tmp/project-data.json
```

**Query explanation:**
- `items(first: 20)`: Fetch up to 20 project items (reduced from 50 - most projects have <10 Ready stories)
- `content ... on Issue`: Get issue metadata (number, title, url, labels) **without body field**
- `fieldValues`: Get all custom field values (Status, Priority, Size, etc.)
- `optionId`: The ID used to identify field option values (e.g., "Ready", "P0")

**Phase 2: Fetch body for selected story only:**

After filtering and sorting in Step 4, fetch body for the winning story:

```graphql
query GetIssueBody($issueId: ID!) {
  node(id: $issueId) {
    ... on Issue {
      body
    }
  }
}
```

**Execute Phase 2 query:**

```bash
gh api graphql -f query='...' -f issueId="$SELECTED_STORY_ID" --jq '.data.node.body'
```

**Performance improvement:**
- Before: Single query with all bodies = ~97.6KB
- After: Phase 1 (20KB) + Phase 2 (3KB) = ~23KB
- **Savings: 76% reduction in data transfer**

### Step 4: Filter and Sort Stories

**Filtering logic:**

```javascript
// Pseudo-code for filtering
const readyStories = projectItems.filter(item => {
  // Find Status field value
  const statusField = item.fieldValues.nodes.find(fv =>
    fv.field.id === FIELD_IDS.status
  );

  // Check if status is "Ready"
  return statusField?.optionId === OPTION_IDS.status.ready;
});
```

**Priority extraction:**

```javascript
// For each ready story, extract priority
const storiesWithPriority = readyStories.map(item => {
  const priorityField = item.fieldValues.nodes.find(fv =>
    fv.field.id === FIELD_IDS.priority
  );

  return {
    ...item,
    priorityOptionId: priorityField?.optionId,
    priorityName: priorityField?.name // "P0", "P1", "P2"
  };
});
```

**Sorting by priority:**

```javascript
// Sort: P0 first, then P1, then P2
const priorityOrder = {
  [OPTION_IDS.priority.p0]: 0,  // P0 = highest
  [OPTION_IDS.priority.p1]: 1,
  [OPTION_IDS.priority.p2]: 2
};

const sortedStories = storiesWithPriority.sort((a, b) => {
  const priorityA = priorityOrder[a.priorityOptionId] ?? 999;
  const priorityB = priorityOrder[b.priorityOptionId] ?? 999;
  return priorityA - priorityB;
});

// Return first story (highest priority)
const selectedStory = sortedStories[0];

// Fetch body for selected story only (Phase 2)
const bodyResponse = await gh.api.graphql(queryGetIssueBody, {
  issueId: selectedStory.content.id
});
const issueBody = bodyResponse.data.node.body || "";
```

### Step 5: Extract Story Data

**Parse selected story (with body from Phase 2):**

```javascript
const storyData = {
  storyId: selectedStory.content.id,
  issueNumber: selectedStory.content.number,
  title: selectedStory.content.title,
  body: issueBody,  // From Phase 2 query
  url: selectedStory.content.url,
  priority: selectedStory.priorityName,
  size: extractSize(selectedStory.fieldValues),
  labels: selectedStory.content.labels.nodes.map(l => l.name),
  projectItemId: selectedStory.id,
  nfrs: {},
  context: {},
  adr: null,
  fetchedAt: new Date().toISOString()
};
```

**Size extraction:**

```javascript
function extractSize(fieldValues) {
  const sizeField = fieldValues.nodes.find(fv =>
    fv.field.id === FIELD_IDS.size
  );
  return sizeField?.name || "Unknown"; // "XS", "S", "M", "L", "XL"
}
```

### Step 6: Write Story Data to Local File

**Output file:** `.claude/active-story.json`

**Format:**

```json
{
  "storyId": "I_kwDODvZ3Zc6RAbCd",
  "issueNumber": 123,
  "title": "Implement payment checkout",
  "body": "As a user, I want to securely complete payment...",
  "url": "https://github.com/{{REPO_SLUG}}/issues/123",
  "priority": "P0",
  "size": "M",
  "labels": ["story", "feature", "payment"],
  "projectItemId": "PVTI_lADODvZ3Zc4BM9rkzgY1234",
  "nfrs": {},
  "context": {},
  "adr": null,
  "fetchedAt": "2026-01-21T12:00:00Z"
}
```

**Validate and write:**

```bash
# Validate against schema
npx ajv validate -s .claude/schemas/active-story.schema.json -d /tmp/story-data.json

# If validation passes, write to active story file
# Use Write tool (not bash echo/cat)
# Write JSON content to .claude/active-story.json
```

**Schema validation ensures:**
- All required fields present (storyId, issueNumber, title, url, priority, projectItemId, fetchedAt)
- Field types correct (issueNumber is integer, url is valid URI, etc.)
- Pattern validation (storyId matches `I_kwDO...`, projectItemId matches `PVTI_...`)
- Enum validation (priority is P0/P1/P2/Unknown, size is XS/S/M/L/XL/Unknown)

### Step 7: Update GitHub Status to "In Progress"

**GraphQL Mutation:**

```graphql
mutation UpdateStatus($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(
    input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: { singleSelectOptionId: $optionId }
    }
  ) {
    projectV2Item {
      id
    }
  }
}
```

**Execute mutation:**

```bash
gh api graphql -f query='...' \
  -f projectId="$PROJECT_ID" \
  -f itemId="$STORY_PROJECT_ITEM_ID" \
  -f fieldId="$STATUS_FIELD_ID" \
  -f optionId="$IN_PROGRESS_OPTION_ID"
```

**Parameters:**
- `projectId`: From configuration (`storyWorkflow.projectId`)
- `itemId`: Story's project item ID (`projectItemId` from parsed data)
- `fieldId`: Status field ID (`storyWorkflow.fieldIds.status`)
- `optionId`: "In Progress" option ID (`storyWorkflow.optionIds.status.inProgress`)

### Step 8: Report Success

**Output:**

```
✓ Story Fetched: #123

Title: Implement payment checkout
Priority: P0
Size: M
Labels: story, feature, payment

URL: https://github.com/{{REPO_SLUG}}/issues/123

✓ Story data saved to .claude/active-story.json
✓ GitHub status updated to "In Progress"

Next steps:
  Run /gather-nfr to collect non-functional requirements
  Or run /play-story to execute the full workflow
```

## Error Handling

### No Configuration Found

**Detection:**
```bash
if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json" ]; then
  # Configuration file doesn't exist
fi
```

**Error message:**
```
❌ Configuration file not found

Please create .claude/story-workflow-config.json with the following structure:

{
  "storyWorkflow": {
    "projectId": "PVT_...",
    "fieldIds": { ... },
    "optionIds": { ... }
  }
}

See the skill documentation for the complete configuration schema.
```

### Missing storyWorkflow Configuration

**Detection:**
```javascript
const config = JSON.parse(settingsContent);
if (!config.storyWorkflow) {
  // Missing storyWorkflow key
}
```

**Error message:**
```
❌ storyWorkflow configuration missing

.claude/story-workflow-config.json exists but doesn't contain the storyWorkflow section.

Please add:
{
  "storyWorkflow": {
    "projectId": "{{GITHUB_PROJECT_ID}}",
    "fieldIds": { ... },
    "optionIds": { ... }
  }
}
```

### GitHub Authentication Failed

**Detection:**
```bash
GITHUB_TOKEN=$(gh auth token 2>&1)
if [ $? -ne 0 ]; then
  # gh auth token failed
fi
```

**Error message:**
```
❌ GitHub authentication failed

Please authenticate with GitHub CLI:
  gh auth login

Then try again.
```

### GraphQL Query Failed

**Detection:**
```bash
RESULT=$(gh api graphql -f query='...' 2>&1)
if [ $? -ne 0 ]; then
  # GraphQL query failed
fi
```

**Error message:**
```
❌ Failed to query GitHub Projects

Error: [error output]

Possible causes:
- Invalid project ID in configuration
- Insufficient permissions (need project read access)
- GitHub API rate limit exceeded

Please check your configuration and permissions.
```

### No Ready Stories Found

**Detection:**
```javascript
if (readyStories.length === 0) {
  // No stories with Status='Ready'
}
```

**Error message:**
```
ℹ️  No Ready stories found

There are no stories with Status='Ready' in the project.

Suggestions:
1. Create new stories in GitHub Issues
2. Add them to the project
3. Set their Status to 'Ready'
4. Run /fetch-story again

View project: https://github.com/orgs/aigensa/projects/...
```

### Active Story Already Exists

**Detection:**
```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.claude/active-story.json"
if [ -f "$STORY_FILE" ]; then
  # Active story file exists
fi
```

**Warning message:**
```
⚠️  Active story already exists

Current story: #123 - Implement payment checkout

Options:
  [1] Continue with current story (cancel fetch)
  [2] Fetch new story (overwrite current)
  [3] View current story details

Choice:
```

**If user selects [1]:** Exit without changes

**If user selects [2]:** Continue with fetch, overwrite file

**If user selects [3]:**
```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.claude/active-story.json"
cat "$STORY_FILE" | jq '.'
# Then re-prompt with options [1] and [2]
```

### Failed to Update GitHub Status

**Detection:**
```bash
UPDATE_RESULT=$(gh api graphql -f query='...' 2>&1)
if [ $? -ne 0 ]; then
  # Status update mutation failed
fi
```

**Warning message:**
```
⚠️  Failed to update GitHub status

Story was fetched successfully, but couldn't update status to "In Progress".

Error: [error output]

Story data saved to .claude/active-story.json - you can proceed with workflow.

To update status manually:
1. Visit: https://github.com/{{REPO_SLUG}}/issues/123
2. Change Status to "In Progress" in the project board
```

## Implementation Details

### Bash Implementation

```bash
#!/bin/bash

# Load configuration
CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Configuration file not found"
  echo "   Expected: $CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json"
  exit 1
fi

# Extract configuration using jq
PROJECT_ID=$(jq -r '.storyWorkflow.projectId' "$CONFIG_FILE")
STATUS_FIELD_ID=$(jq -r '.storyWorkflow.fieldIds.status' "$CONFIG_FILE")
PRIORITY_FIELD_ID=$(jq -r '.storyWorkflow.fieldIds.priority' "$CONFIG_FILE")
SIZE_FIELD_ID=$(jq -r '.storyWorkflow.fieldIds.size' "$CONFIG_FILE")

READY_OPTION_ID=$(jq -r '.storyWorkflow.optionIds.status.ready' "$CONFIG_FILE")
IN_PROGRESS_OPTION_ID=$(jq -r '.storyWorkflow.optionIds.status.inProgress' "$CONFIG_FILE")

P0_OPTION_ID=$(jq -r '.storyWorkflow.optionIds.priority.p0' "$CONFIG_FILE")
P1_OPTION_ID=$(jq -r '.storyWorkflow.optionIds.priority.p1' "$CONFIG_FILE")
P2_OPTION_ID=$(jq -r '.storyWorkflow.optionIds.priority.p2' "$CONFIG_FILE")

# Authenticate
GITHUB_TOKEN=$(gh auth token)
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ GitHub authentication failed"
  exit 1
fi

# Query GitHub Projects
QUERY='query GetReadyStories($projectId: ID!) { ... }'

RESULT=$(gh api graphql -f query="$QUERY" -f projectId="$PROJECT_ID" 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ Failed to query GitHub Projects"
  echo "$RESULT"
  exit 1
fi

# Parse and filter stories (use jq)
# Filter for Status='Ready', sort by Priority, select first

# Extract story data
# Write to .claude/active-story.json

# Update GitHub status
# Execute mutation

echo "✓ Story Fetched: #$ISSUE_NUMBER"
```

### Alternative: Node.js/TypeScript Implementation

For more complex JSON processing, consider a TypeScript implementation similar to `scripts/import-epics-to-github.ts`:

```typescript
import { graphql } from '@octokit/graphql';
import { readFileSync, writeFileSync } from 'fs';

// Load config, query GitHub, filter, sort, write output
// Same logic as bash but with better JSON handling
```

**Benefits:**
- Easier JSON manipulation
- Type safety
- Better error handling
- Reusable across skills

## Integration with Other Skills

### Called by /play-story

The master orchestrator skill calls /fetch-story as the first step:

```
/play-story
  ↓
1. Check .claude/active-story.json
2. If empty: Run /fetch-story
3. Proceed with NFR gathering...
```

### Output Used by Other Skills

**By /gather-nfr:**
- Reads story title and labels to tailor NFR questions
- Appends NFRs to the `nfrs` field in active-story.json

**By /gather-context:**
- Uses story title/body to search for related docs and code
- Appends context to the `context` field

**By /create-adr:**
- Uses story data + NFRs + context to generate ADR
- Updates `adr` field with ADR file path

## Best Practices

### When to Call This Skill

**✅ Good times:**
- Starting work on a new story
- Switching to the next priority story
- Part of `/play-story` workflow

**❌ Bad times:**
- Active story already in progress (unless intentionally switching)
- Configuration not set up
- Not authenticated with GitHub

### Priority Guidelines

**P0 (Critical):**
- Blockers for other work
- Security vulnerabilities
- Production bugs

**P1 (High):**
- Important features
- Significant improvements
- Non-critical bugs

**P2 (Low):**
- Nice-to-have features
- Minor improvements
- Tech debt

### Story Status Lifecycle

```
Backlog → Ready → In Progress → In Review → Done
          ↑      ↑
          |      └─ /fetch-story updates status here
          └─ Manual status change before running /fetch-story
```

## Example Output

```bash
$ /fetch-story

🔍 Fetching Ready stories from GitHub Projects...

→ Querying project {{GITHUB_PROJECT_ID}}
  ✓ Found 3 Ready stories

→ Filtering and sorting by priority
  • P0: Implement payment checkout (M)
  • P1: Add user profile editing (S)
  • P2: Improve error messages (XS)

→ Selected story: #123 - Implement payment checkout
  Priority: P0
  Size: M
  Labels: story, feature, payment

→ Saving story data to .claude/active-story.json
  ✓ Story data saved

→ Updating GitHub status to "In Progress"
  ✓ Status updated

✓ Story Fetched: #123

Title: Implement payment checkout
Priority: P0
Size: M
Labels: story, feature, payment

URL: https://github.com/{{REPO_SLUG}}/issues/123

Next steps:
  Run /gather-nfr to collect non-functional requirements
  Or run /play-story to execute the full workflow
```

## Troubleshooting

### Issue: "Field ID not found in query results"

**Cause:** Custom field IDs in configuration don't match actual project fields

**Solution:**
1. Use GitHub API to list project fields:
```bash
gh api graphql -f query='query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2SingleSelectField {
            id
            name
            options { id name }
          }
        }
      }
    }
  }
}' -f projectId="{{GITHUB_PROJECT_ID}}"
```
2. Update `.claude/story-workflow-config.json` with correct IDs

### Issue: "Story has no priority"

**Cause:** Story exists but Priority field is empty in GitHub Project

**Solution:**
- Set Priority in GitHub Project before marking as Ready
- Or modify filtering logic to assign default priority (P2)

### Issue: "Rate limit exceeded"

**Cause:** Too many GitHub API requests

**Solution:**
```bash
# Check rate limit status
gh api rate_limit

# Wait for reset, or authenticate with a different token
```

## Summary

The `/fetch-story` skill automates story selection by:

✅ **Querying GitHub Projects** - Uses GraphQL for efficient data retrieval
✅ **Intelligent prioritization** - Sorts by P0 > P1 > P2 automatically
✅ **Local storage** - Saves story data for use by other skills
✅ **Status updates** - Reflects work in progress on GitHub
✅ **Error handling** - Gracefully handles missing config, auth failures, no stories

Use `/fetch-story` to grab the next story and kick off your implementation workflow!
