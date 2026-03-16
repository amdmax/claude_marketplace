#!/bin/bash
#
# PostToolUse hook: Validate GitHub Actions workflow after Edit/Write
#
# This hook runs AFTER the file is written to provide immediate feedback
# on workflow validity. Unlike PreToolUse, it doesn't block - just informs.

set -euo pipefail

# Get project directory
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Read JSON input
INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path or not a workflow
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

if [[ ! "$FILE_PATH" =~ \.github/workflows/.*\.ya?ml$ ]]; then
  exit 0
fi

# Convert to absolute path
if [[ ! "$FILE_PATH" =~ ^/ ]]; then
  FILE_PATH="$CLAUDE_PROJECT_DIR/$FILE_PATH"
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Check actionlint installation
if ! command -v actionlint >/dev/null 2>&1; then
  cat >&2 <<'EOF'
💡 Tip: Install actionlint for workflow validation
   macOS: brew install actionlint
   Linux: https://github.com/rhysd/actionlint/releases
EOF
  exit 0
fi

# Run validation
echo "🔍 Validating $(basename "$FILE_PATH")..." >&2

if actionlint \
  -ignore 'SC2086:info' \
  -ignore 'SC2016:info' \
  -ignore 'constant expression "false"' \
  "$FILE_PATH" 2>&1; then
  echo "✅ Workflow is valid" >&2
else
  echo "" >&2
  echo "⚠️  Validation warnings/errors found above" >&2
  echo "Fix issues before committing to avoid CI failures" >&2
fi

exit 0
