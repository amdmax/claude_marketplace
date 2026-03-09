#!/bin/bash

# PostToolUse hook to validate CDK infrastructure after edits
# Non-blocking: warns if CDK synth fails but doesn't revert changes

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# If no file path, skip validation
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Check if file is in infrastructure directory
if [[ "$FILE_PATH" == *"/infrastructure/"* ]]; then
  echo "🔍 Validating CDK infrastructure..." >&2

  cd "$CLAUDE_PROJECT_DIR/infrastructure" || exit 0

  # Check if package.json exists
  if [ ! -f "package.json" ]; then
    echo "⚠️  No package.json found in infrastructure/, skipping CDK validation" >&2
    exit 0
  fi

  # Run CDK synth for validation
  if npx cdk synth --quiet > /dev/null 2>&1; then
    echo "✅ CDK synth validation passed" >&2
  else
    echo "❌ CDK synth validation failed" >&2
    echo "Run 'cd infrastructure && npx cdk synth' to see detailed errors" >&2
    exit 1  # Non-blocking warning
  fi
fi

exit 0
