---
name: github:tidy-board
description: Tidy a GitHub Project board by moving stale "In Progress" items to "Done" when their linked issues are closed or PRs are merged. Use when asked to clean up, tidy, or sync the agile board. Invokable with /tidy-board owner/repo.
---

# github:tidy-board

Move stale "In Progress" project items to "Done" for `$ARGUMENT` (format: `owner/repo`).

## Step 1 — Parse argument

Extract `OWNER` and `REPO` from `$ARGUMENT` (split on `/`).

If `$ARGUMENT` is missing or does not contain `/`:
```
Usage: /tidy-board owner/repo
Example: /tidy-board {{REPO_SLUG}}
```
Stop.

## Step 2 — Discover project

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!) {
  repository(owner: $owner, name: $repo) {
    projectsV2(first: 5) {
      nodes { id title number }
    }
  }
}' -f owner="$OWNER" -f repo="$REPO"
```

- 0 projects → error: "No GitHub Project V2 found for $OWNER/$REPO. Link a project to the repo first."
- 1 project → use it, print: `Using project: <title>`
- Multiple projects → print all titles, use the first, note: "Using first project. Others: <titles>"

Capture `PROJECT_ID`.

## Step 3 — Get Status field ID + option IDs dynamically

```bash
gh api graphql -f query='
query($projectId: ID!) {
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
}' -f projectId="$PROJECT_ID"
```

- Find the field where `name == "Status"` → capture `STATUS_FIELD_ID`
- Find option where `name == "In Progress"` → capture `IN_PROGRESS_OPTION_ID`
- Find option where `name == "Done"` → capture `DONE_OPTION_ID`

If Status field not found → error: "No 'Status' field found in project."
If "In Progress" or "Done" options not found → error with which option is missing.

## Step 4 — Fetch all "In Progress" items with linked issue/PR state

```bash
gh api graphql -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              state
            }
            ... on PullRequest {
              number
              title
              state
              merged
            }
          }
          fieldValues(first: 15) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field {
                  ... on ProjectV2SingleSelectField { id }
                }
                optionId
              }
            }
          }
        }
      }
    }
  }
}' -f projectId="$PROJECT_ID"
```

Filter items where ALL of the following are true:
- `fieldValues` contains a node where `field.id == STATUS_FIELD_ID` AND `optionId == IN_PROGRESS_OPTION_ID`
- `content.state == "CLOSED"` OR `content.merged == true`

Collect matching items as `STALE_ITEMS` (each with `id`, `number`, `title`).

## Step 5 — Move stale items to Done + report

If `STALE_ITEMS` is empty:
```
✓ Board is already tidy. Nothing to do.
```
Stop.

For each item in `STALE_ITEMS`, run:

```bash
gh api graphql -f query='
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId
    itemId: $itemId
    fieldId: $fieldId
    value: { singleSelectOptionId: $optionId }
  }) {
    projectV2Item { id }
  }
}' \
  -f projectId="$PROJECT_ID" \
  -f itemId="<item.id>" \
  -f fieldId="$STATUS_FIELD_ID" \
  -f optionId="$DONE_OPTION_ID"
```

Track success/failure per item.

Print summary table:
```
| # | Title | Result |
|---|-------|--------|
| #123 | Issue title | ✓ Moved to Done |
| #456 | Another issue | ✗ Failed: <error> |
```

Print final count:
```
Moved N item(s) to Done.
```

If any failures occurred, list them at the end:
```
⚠ Failed to move: #456, #789 — check your project permissions.
```
