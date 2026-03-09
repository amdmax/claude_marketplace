#!/bin/bash

# Block direct pushes to master/main branches
# This hook runs before Bash tool executions

# Only check git push commands
if [[ "$CLAUDE_TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Extract the command being run
COMMAND="$CLAUDE_BASH_COMMAND"

# Check if this is a git push command
if [[ ! "$COMMAND" =~ git[[:space:]]+push ]]; then
  exit 0
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Block if on master or main
if [[ "$CURRENT_BRANCH" == "master" ]] || [[ "$CURRENT_BRANCH" == "main" ]]; then
  echo "❌ ERROR: Direct push to '$CURRENT_BRANCH' is not allowed" >&2
  echo "" >&2
  echo "Policy: ALL changes must go through pull requests. No exceptions." >&2
  echo "" >&2
  echo "To fix:" >&2
  echo "  1. Create a feature branch: git checkout -b feature/my-change" >&2
  echo "  2. Make your changes and commit" >&2
  echo "  3. Push the feature branch: git push -u origin feature/my-change" >&2
  echo "  4. Create a PR with: /mr" >&2
  exit 1
fi

# Allow push to other branches
exit 0
