#!/bin/bash
#
# PostToolUse hook: Validate CDK infrastructure after Edit/Write
#
# Runs cdk-nag and cfn-lint validation on infrastructure changes.
# Blocks operations on errors if blocking mode enabled.

set -euo pipefail

# Get project and skill directories
CLAUDE_PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SKILL_DIR/config.yaml"

# Read JSON input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [ -z "$FILE_PATH" ]; then
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

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  Config file not found: $CONFIG_FILE" >&2
  exit 0
fi

# Check if yq is available
if ! command -v yq >/dev/null 2>&1; then
  echo "⚠️  yq not installed - cannot parse config" >&2
  echo "💡 Install: brew install yq (macOS) or see https://github.com/mikefarah/yq" >&2
  exit 0
fi

# Parse config
WATCH_DIRS=$(yq e '.files.watch_dirs[]' "$CONFIG_FILE" 2>/dev/null || echo "infrastructure/")
EXCLUDE_PATTERNS=$(yq e '.files.exclude_patterns[]' "$CONFIG_FILE" 2>/dev/null || echo "")
BLOCKING=$(yq e '.behavior.blocking' "$CONFIG_FILE" 2>/dev/null || echo "true")
BLOCKING_ON_ERRORS=$(yq e '.behavior.blocking_on_errors' "$CONFIG_FILE" 2>/dev/null || echo "true")
BLOCKING_ON_WARNINGS=$(yq e '.behavior.blocking_on_warnings' "$CONFIG_FILE" 2>/dev/null || echo "false")
TIMEOUT=$(yq e '.behavior.timeout' "$CONFIG_FILE" 2>/dev/null || echo "60")
CDK_NAG_ENABLED=$(yq e '.tools.cdk_nag.enabled' "$CONFIG_FILE" 2>/dev/null || echo "true")
CDK_NAG_VERBOSE=$(yq e '.tools.cdk_nag.verbose' "$CONFIG_FILE" 2>/dev/null || echo "false")
CFN_LINT_ENABLED=$(yq e '.tools.cfn_lint.enabled' "$CONFIG_FILE" 2>/dev/null || echo "true")
AUTO_INSTALL_CDK_NAG=$(yq e '.installation.auto_install_cdk_nag' "$CONFIG_FILE" 2>/dev/null || echo "true")

# Check if file is in watched directories
IN_WATCH_DIR=false
for watch_dir in $WATCH_DIRS; do
  if [[ "$FILE_PATH" == *"$watch_dir"* ]]; then
    IN_WATCH_DIR=true
    break
  fi
done

if [ "$IN_WATCH_DIR" = "false" ]; then
  exit 0
fi

# Check if file matches exclude patterns
for pattern in $EXCLUDE_PATTERNS; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    exit 0
  fi
done

# Start validation
echo "🔍 Validating CDK infrastructure..." >&2
echo "" >&2

# Track validation results
HAS_ERRORS=false
HAS_WARNINGS=false
CDK_INFRA_DIR="$CLAUDE_PROJECT_DIR/infrastructure"

# Change to infrastructure directory
if [ ! -d "$CDK_INFRA_DIR" ]; then
  echo "⚠️  Infrastructure directory not found: $CDK_INFRA_DIR" >&2
  exit 0
fi

cd "$CDK_INFRA_DIR"

# Check/install cdk-nag
if [ "$CDK_NAG_ENABLED" = "true" ]; then
  if ! npm list cdk-nag >/dev/null 2>&1; then
    if [ "$AUTO_INSTALL_CDK_NAG" = "true" ]; then
      echo "📦 Installing cdk-nag..." >&2
      if npm install --save-dev cdk-nag >/dev/null 2>&1; then
        echo "✅ cdk-nag installed successfully" >&2
        echo "" >&2
      else
        echo "❌ Failed to install cdk-nag" >&2
        echo "💡 Install manually: cd infrastructure && npm install --save-dev cdk-nag" >&2
        echo "" >&2
        CDK_NAG_ENABLED=false
      fi
    else
      echo "⚠️  cdk-nag not installed" >&2
      echo "💡 Install: cd infrastructure && npm install --save-dev cdk-nag" >&2
      echo "⚠️  Skipping cdk-nag validation" >&2
      echo "" >&2
      CDK_NAG_ENABLED=false
    fi
  fi
fi

# Run cdk-nag via cdk synth
if [ "$CDK_NAG_ENABLED" = "true" ]; then
  echo "  Running cdk-nag checks..." >&2

  # Run cdk synth with timeout
  SYNTH_OUTPUT=$(timeout "$TIMEOUT" npx cdk synth --quiet 2>&1 || true)

  # Check for errors
  if echo "$SYNTH_OUTPUT" | grep -q "\[Error\]"; then
    HAS_ERRORS=true
    echo "  ❌ cdk-nag errors found:" >&2
    echo "$SYNTH_OUTPUT" | grep "\[Error\]" | sed 's/^/    /' >&2
    echo "" >&2
  elif echo "$SYNTH_OUTPUT" | grep -q "Error:"; then
    # CDK synth failed
    HAS_ERRORS=true
    echo "  ❌ CDK synth failed:" >&2
    echo "$SYNTH_OUTPUT" | sed 's/^/    /' >&2
    echo "" >&2
  elif echo "$SYNTH_OUTPUT" | grep -q "\[Warning\]"; then
    HAS_WARNINGS=true
    echo "  ⚠️  cdk-nag warnings:" >&2
    echo "$SYNTH_OUTPUT" | grep "\[Warning\]" | head -5 | sed 's/^/    /' >&2
    WARNING_COUNT=$(echo "$SYNTH_OUTPUT" | grep -c "\[Warning\]" || echo "0")
    if [ "$WARNING_COUNT" -gt 5 ]; then
      echo "    ... and $((WARNING_COUNT - 5)) more warnings" >&2
    fi
    echo "" >&2
  else
    echo "  ✅ cdk-nag checks passed" >&2
  fi
fi

# Run cfn-lint on generated templates
if [ "$CFN_LINT_ENABLED" = "true" ]; then
  if ! command -v cfn-lint >/dev/null 2>&1; then
    echo "  ⚠️  cfn-lint not installed" >&2
    echo "  💡 Install: brew install cfn-lint (macOS) or pip install cfn-lint" >&2
    echo "  ⚠️  Skipping cfn-lint validation" >&2
    echo "" >&2
  else
    echo "  Running cfn-lint..." >&2

    # Find generated templates
    TEMPLATE_COUNT=$(find cdk.out -name "*.template.json" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$TEMPLATE_COUNT" -eq 0 ]; then
      echo "  ⚠️  No CloudFormation templates found (cdk.out/)" >&2
      echo "" >&2
    else
      # Run cfn-lint
      CFN_OUTPUT=$(cfn-lint cdk.out/*.template.json 2>&1 || true)

      if echo "$CFN_OUTPUT" | grep -q "E[0-9]"; then
        HAS_ERRORS=true
        echo "  ❌ cfn-lint errors found:" >&2
        echo "$CFN_OUTPUT" | grep "E[0-9]" | sed 's/^/    /' >&2
        echo "" >&2
      elif echo "$CFN_OUTPUT" | grep -q "W[0-9]"; then
        HAS_WARNINGS=true
        echo "  ⚠️  cfn-lint warnings:" >&2
        echo "$CFN_OUTPUT" | grep "W[0-9]" | sed 's/^/    /' >&2
        echo "" >&2
      else
        echo "  ✅ cfn-lint checks passed" >&2
      fi
    fi
  fi
fi

# Report final status
echo "" >&2
if [ "$HAS_ERRORS" = "true" ]; then
  echo "❌ CDK validation failed" >&2
  echo "Run 'cd infrastructure && npx cdk synth' for details" >&2
  echo "" >&2

  if [ "$BLOCKING" = "true" ] && [ "$BLOCKING_ON_ERRORS" = "true" ]; then
    echo "⚠️  Blocking mode enabled - fix errors before proceeding" >&2
    exit 2
  fi
elif [ "$HAS_WARNINGS" = "true" ]; then
  echo "⚠️  CDK validation completed with warnings (non-blocking)" >&2
  echo "💡 Tip: See .claude/skills/cdk-validate/references/suppression-guide.md to suppress warnings" >&2
  echo "" >&2

  if [ "$BLOCKING" = "true" ] && [ "$BLOCKING_ON_WARNINGS" = "true" ]; then
    echo "⚠️  Blocking on warnings enabled - fix warnings before proceeding" >&2
    exit 2
  fi
else
  echo "✅ CDK validation passed" >&2
fi

exit 0
