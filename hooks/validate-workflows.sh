#!/bin/bash
#
# PreToolUse hook: Validate GitHub Actions workflow files before Write/Edit
#
# Runs actionlint on workflow YAML files to catch syntax errors, security issues,
# and invalid action references before files are written to disk.
#
# Exit codes:
#   0 - Validation passed or skipped (allows operation)
#   2 - Validation failed (blocks operation)

set -euo pipefail

# Get project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Read JSON input from stdin
INPUT=$(cat)

# Extract tool name and file path
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Convert to absolute path if relative
if [[ ! "$FILE_PATH" =~ ^/ ]]; then
  FILE_PATH="$CLAUDE_PROJECT_DIR/$FILE_PATH"
fi

# Only validate files in .github/workflows/
if [[ ! "$FILE_PATH" =~ \.github/workflows/.*\.ya?ml$ ]]; then
  exit 0
fi

# Check if actionlint is installed
if ! "$CLAUDE_PROJECT_DIR/.claude/hooks/utils/check-actionlint.sh" 2>&1; then
  # actionlint not installed - show warning but allow operation (graceful degradation)
  echo "⚠️  Skipping workflow validation (actionlint not installed)" >&2
  exit 0
fi

# Create temp file for validation
TEMP_FILE=""
cleanup() {
  if [ -n "$TEMP_FILE" ] && [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
  fi
}
trap cleanup EXIT

# Handle Write vs Edit tool
if [ "$TOOL_NAME" = "Write" ]; then
  # Write tool: content not yet on disk, extract from JSON
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')

  if [ -z "$CONTENT" ]; then
    echo "⚠️  No content to validate" >&2
    exit 0
  fi

  # Create temp file with content
  TEMP_FILE=$(mktemp)
  echo "$CONTENT" > "$TEMP_FILE"
  VALIDATE_FILE="$TEMP_FILE"
elif [ "$TOOL_NAME" = "Edit" ]; then
  # Edit tool: Cannot validate new content in PreToolUse (only old_string/new_string available)
  # Validation handled by PostToolUse hook at .claude/skills/gh-edit-workflow/validate-workflow-output.sh
  echo "⚠️  Skipping PreToolUse validation for Edit (will validate in PostToolUse)" >&2
  exit 0
else
  # Unknown tool - skip validation
  exit 0
fi

# Run actionlint validation
# Ignore certain checks:
# - shellcheck SC2086 (double quote to prevent globbing) - common in GitHub Actions
# - shellcheck SC2016 (expressions in single quotes) - false positives with GitHub Actions syntax
# - if-cond with constant false - used for temporarily disabling jobs
echo "🔍 Validating workflow: $(basename "$FILE_PATH")" >&2

if ! ACTIONLINT_OUTPUT=$(actionlint \
  -ignore 'SC2086:info' \
  -ignore 'SC2016:info' \
  -ignore 'constant expression "false" in condition' \
  "$VALIDATE_FILE" 2>&1); then
  # Validation failed - format errors and block operation
  cat >&2 <<EOF

❌ Workflow validation failed

File: $FILE_PATH

Errors:
$ACTIONLINT_OUTPUT

Please fix the issues above before committing.
EOF
  exit 2
fi

# Validation passed
echo "✅ Workflow validation passed: $(basename "$FILE_PATH")" >&2
exit 0
