#!/bin/bash
set -euo pipefail

# Validate single skill file for proper frontmatter and valid options
# Usage: validate-skill.sh <path-to-SKILL.md>

SKILL_FILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERROR_COUNT=0
WARNING_COUNT=0

error() {
  echo -e "${RED}✗ $1${NC}" >&2
  ((ERROR_COUNT++))
}

warning() {
  echo -e "${YELLOW}⚠ $1${NC}" >&2
  ((WARNING_COUNT++))
}

success() {
  echo -e "${GREEN}✓ $1${NC}"
}

# Check file exists
if [[ ! -f "$SKILL_FILE" ]]; then
  error "File not found: $SKILL_FILE"
  exit 2
fi

# Extract frontmatter
FRONTMATTER=$(awk '/^---$/{flag=!flag; next} flag' "$SKILL_FILE")

# Check frontmatter exists
if [[ -z "$FRONTMATTER" ]]; then
  error "Missing frontmatter delimiters (---)"
  exit 1
fi

# Validate YAML syntax
if ! echo "$FRONTMATTER" | yq eval '.' - >/dev/null 2>&1; then
  error "Invalid YAML syntax in frontmatter"
  exit 1
fi

# Check required fields
if ! echo "$FRONTMATTER" | yq eval '.name' - >/dev/null 2>&1 || \
   [[ $(echo "$FRONTMATTER" | yq eval '.name' -) == "null" ]]; then
  error "Required field 'name' not found"
fi

if ! echo "$FRONTMATTER" | yq eval '.description' - >/dev/null 2>&1 || \
   [[ $(echo "$FRONTMATTER" | yq eval '.description' -) == "null" ]]; then
  error "Required field 'description' not found"
fi

# Validate name format (alphanumeric, hyphens, colons)
SKILL_NAME=$(echo "$FRONTMATTER" | yq eval '.name' -)
if [[ ! "$SKILL_NAME" =~ ^[a-zA-Z0-9:_-]+$ ]]; then
  error "Invalid skill name format: $SKILL_NAME (use alphanumeric, hyphens, colons, underscores)"
fi

# Check optional fields
VERSION=$(echo "$FRONTMATTER" | yq eval '.version' -)
if [[ "$VERSION" == "null" ]]; then
  warning "Missing optional field 'version'"
fi

AUTHOR=$(echo "$FRONTMATTER" | yq eval '.author' -)
if [[ "$AUTHOR" == "null" ]]; then
  warning "Missing optional field 'author'"
fi

# Validate hooks if present
HOOKS=$(echo "$FRONTMATTER" | yq eval '.hooks' -)
if [[ "$HOOKS" != "null" ]]; then
  VALID_EVENTS=("Start" "Stop" "PreToolUse" "PostToolUse" "Notification" "SessionStart" "UserPromptSubmit" "SubagentStart" "SubagentStop" "PreCompact" "SessionEnd")

  # Check each hook event
  HOOK_EVENTS=$(echo "$FRONTMATTER" | yq eval '.hooks | keys | .[]' -)
  while IFS= read -r EVENT; do
    if [[ ! " ${VALID_EVENTS[@]} " =~ " ${EVENT} " ]]; then
      error "Invalid hook event type: '$EVENT' (valid: ${VALID_EVENTS[*]})"
    fi

    # Detect hook format: map (flat legacy) or seq (native Claude Code array)
    HOOK_TYPE=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT | type" -)

    if [[ "$HOOK_TYPE" == "!!map" ]]; then
      # Flat format: hooks.<EVENT>.command is a direct string
      COMMAND=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT.command" -)
      if [[ "$COMMAND" == "null" ]]; then
        error "Hook '$EVENT' missing required field 'command'"
      fi
      DESCRIPTION=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT.description" -)
      if [[ "$DESCRIPTION" == "null" ]]; then
        warning "Hook '$EVENT' missing optional field 'description'"
      fi
      TIMEOUT=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT.timeout" -)
      if [[ "$TIMEOUT" != "null" ]] && ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
        error "Hook '$EVENT' timeout must be a number (milliseconds)"
      fi
    elif [[ "$HOOK_TYPE" == "!!seq" ]]; then
      # Native Claude Code array format: [{matcher?, hooks: [{type, command|prompt}]}]
      COUNT=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT | length" -)
      for ((i=0; i<COUNT; i++)); do
        INNER=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT[$i].hooks" -)
        if [[ "$INNER" == "null" ]]; then
          error "Hook '$EVENT'[$i] missing 'hooks' array"
          continue
        fi
        INNER_COUNT=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT[$i].hooks | length" -)
        for ((j=0; j<INNER_COUNT; j++)); do
          TYPE=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT[$i].hooks[$j].type" -)
          CMD=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT[$i].hooks[$j].command" -)
          PROMPT=$(echo "$FRONTMATTER" | yq eval ".hooks.$EVENT[$i].hooks[$j].prompt" -)
          if [[ "$TYPE" == "null" ]]; then
            error "Hook '$EVENT'[$i].hooks[$j] missing 'type'"
          fi
          if [[ "$CMD" == "null" && "$PROMPT" == "null" ]]; then
            error "Hook '$EVENT'[$i].hooks[$j] missing 'command' or 'prompt'"
          fi
        done
      done
    fi
  done <<< "$HOOK_EVENTS"
fi

# Summary
if [[ $ERROR_COUNT -eq 0 ]]; then
  success "$SKILL_FILE - Valid"
  if [[ $WARNING_COUNT -gt 0 ]]; then
    echo "  ($WARNING_COUNT warnings)"
  fi
  exit 0
else
  error "$SKILL_FILE - Invalid ($ERROR_COUNT errors, $WARNING_COUNT warnings)"
  exit 1
fi
