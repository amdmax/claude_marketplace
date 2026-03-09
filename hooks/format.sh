#!/bin/bash

# PostToolUse hook to auto-format files after edits
# Maintains code consistency automatically

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# If no file path, skip formatting
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Format based on file type
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.json)
    if command -v prettier &> /dev/null; then
      prettier --write "$FILE_PATH" --log-level warn 2>&1 | grep -v "unchanged" || true
    else
      echo "⚠️  Prettier not installed, skipping formatting" >&2
    fi
    ;;
  *.md)
    if command -v prettier &> /dev/null; then
      prettier --write "$FILE_PATH" --log-level warn --prose-wrap always 2>&1 | grep -v "unchanged" || true
    fi
    ;;
  *.py)
    if command -v black &> /dev/null; then
      black "$FILE_PATH" --quiet 2>&1 || true
    fi
    ;;
esac

exit 0
