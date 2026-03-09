# Status Management

## Phase 0: Status Bootstrap

Run this once before Phase 1 if `story-workflow-config.json` has 3 or fewer status entries.

```bash
CONFIG=".claude/story-workflow-config.json"
STATUS_COUNT=$(jq '.optionIds.status | length' "$CONFIG")

if [ "$STATUS_COUNT" -le 3 ]; then
  echo "Bootstrapping GitHub Projects status options..."

  RESPONSE=$(gh api graphql -f query='
    query {
      node(id: "PVT_kwDODvZ3Zc4BM9rk") {
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
    }')

  echo "$RESPONSE" | jq -r '
    .data.node.fields.nodes[]
    | select(.name == "Status")
    | .options[]
    | [.name, .id]
    | @tsv' | while IFS=$'\t' read -r NAME ID; do
      KEY=$(echo "$NAME" | sed "s/ \(.\)/\U\1/g" | sed 's/^\(.\)/\l\1/')
      jq --arg key "$KEY" --arg id "$ID" \
        '.optionIds.status[$key] = $id' "$CONFIG" > /tmp/config-tmp.json && mv /tmp/config-tmp.json "$CONFIG"
      echo "  Added status: $KEY = $ID"
    done

  echo "Bootstrap complete. Status options now in $CONFIG"
fi
```

## updateGitHubStatus

Define this bash function before any phase that calls it:

```bash
updateGitHubStatus() {
  local STATUS_KEY=$1
  local CONFIG=".claude/story-workflow-config.json"
  local OPTION_ID=$(jq -r ".optionIds.status.$STATUS_KEY" "$CONFIG")

  if [ "$OPTION_ID" = "null" ] || [ -z "$OPTION_ID" ]; then
    _trackUnknownStatus "$STATUS_KEY"
    return 1
  fi

  local PROJECT_ID=$(jq -r '.projectId' "$CONFIG")
  local FIELD_ID=$(jq -r '.fieldIds.status' "$CONFIG")
  local ITEM_ID=$(jq -r '.projectItemId' ".agile-dev-team/active-story.json")

  gh api graphql -f query="mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: \"$PROJECT_ID\"
      itemId: \"$ITEM_ID\"
      fieldId: \"$FIELD_ID\"
      value: { singleSelectOptionId: \"$OPTION_ID\" }
    }) { projectV2Item { id } }
  }"
}
```

## _trackUnknownStatus

```bash
_trackUnknownStatus() {
  local STATUS_KEY=$1
  local STATE_FILE=".agile-dev-team/development-progress.yaml"

  local CURRENT=$(jq -r ".teamState.unknownStatusRequests[\"$STATUS_KEY\"] // 0" "$STATE_FILE")
  local NEXT=$((CURRENT + 1))
  local UPDATED=$(jq ".teamState.unknownStatusRequests[\"$STATUS_KEY\"] = $NEXT" "$STATE_FILE")
  echo "$UPDATED" > "$STATE_FILE"

  if [ "$NEXT" -ge 4 ]; then
    echo "⚠️  Status \"$STATUS_KEY\" has been requested $NEXT times but is not in story-workflow-config.json."
    echo "Run Phase 0 status bootstrap again or add it manually."
    echo "Option IDs can be found by querying the GitHub Projects API (see Phase 0)."
  fi
}
```
