#!/bin/bash

# PreToolUse hook to run linting before modifying infrastructure or lambda code
# Blocks Edit/Write if linting fails

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# If no file path, allow operation
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Check if file is in infrastructure/ or lambda/ directory and is a TypeScript file
if [[ "$FILE_PATH" == *"/infrastructure/"*.ts ]] || [[ "$FILE_PATH" == *"/lambda/"*.ts ]]; then
  echo "🔍 Linting TypeScript file: $FILE_PATH" >&2

  # Determine the directory (infrastructure or lambda subdirectory)
  if [[ "$FILE_PATH" == *"/infrastructure/"* ]]; then
    LINT_DIR="infrastructure"
  else
    # Extract lambda subdirectory (e.g., lambda/auth-edge)
    LINT_DIR=$(echo "$FILE_PATH" | grep -o 'lambda/[^/]*' | head -1)
  fi

  cd "$CLAUDE_PROJECT_DIR/$LINT_DIR" || exit 0

  # Check if package.json exists
  if [ ! -f "package.json" ]; then
    echo "⚠️  No package.json found in $LINT_DIR, skipping lint" >&2
    exit 0
  fi

  # Run TypeScript compiler
  echo "  → Running tsc..." >&2
  if npm run build 2>&1 | grep -i "error"; then
    echo "❌ TypeScript compilation failed. Please fix errors before committing." >&2
    exit 2
  fi

  # Run ESLint if configured
  if npm run lint > /dev/null 2>&1; then
    echo "  → Running ESLint..." >&2
    if ! npm run lint 2>&1; then
      echo "❌ ESLint found issues. Please fix errors before committing." >&2
      exit 2
    fi
  fi

  echo "✅ Linting passed" >&2
fi

exit 0
