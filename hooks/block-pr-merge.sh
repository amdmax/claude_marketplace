#!/bin/bash

# Block PR merge operations - human-only action
# This hook runs before Bash tool executions

# Only check Bash commands
if [[ "$CLAUDE_TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Extract the command being run
COMMAND="$CLAUDE_BASH_COMMAND"

# Check for gh pr merge command
if [[ "$COMMAND" =~ gh[[:space:]]+pr[[:space:]]+merge ]]; then
  echo "❌ ERROR: PR merge operations are not allowed via automation" >&2
  echo "" >&2
  echo "Policy: Pull request merges must be performed by humans only." >&2
  echo "" >&2
  echo "Reason: PR merges are critical decisions that require:" >&2
  echo "  • Human review of all changes" >&2
  echo "  • Verification that CI checks passed" >&2
  echo "  • Consideration of deployment timing" >&2
  echo "  • Approval from code reviewers" >&2
  echo "" >&2
  echo "To merge this PR:" >&2
  echo "  1. Review the PR on GitHub" >&2
  echo "  2. Verify all CI checks pass" >&2
  echo "  3. Merge manually using GitHub UI or:" >&2
  echo "     gh pr merge <number> --merge  (run this yourself)" >&2
  exit 1
fi

# Check for git merge commands (could be merging a PR branch)
if [[ "$COMMAND" =~ git[[:space:]]+merge ]]; then
  # Allow local merges for development (e.g., git merge master)
  # But warn if merging origin/PR branches
  if [[ "$COMMAND" =~ origin/ ]]; then
    echo "⚠️  WARNING: Merging remote branches should be done via PR workflow" >&2
    echo "Consider using GitHub PR merge instead" >&2
    # Don't block - just warn (exit 0)
  fi
fi

# Allow other commands
exit 0
