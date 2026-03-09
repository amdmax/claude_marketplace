#!/bin/bash

# Pre-push validation hook
# Runs all build steps locally to catch errors before pushing to GitHub CI/CD
# Mirrors the CI pipeline steps
#
# Output Convention: All output goes to stderr for visibility per Claude Code hooks spec
# https://code.claude.com/docs/en/hooks#hook-input-and-output

echo "🚀 Pre-push validation (mirrors CI/CD pipeline)" >&2
echo "" >&2

cd "$CLAUDE_PROJECT_DIR" || exit 1

# Track failures
FAILURES=()

# Step 1: Content quality
echo "📝 Step 1/6: Checking content quality..." >&2
if npm run test:content >&2 2>&1; then
  echo "  ✅ Passed" >&2
else
  FAILURES+=("Content quality - run: npm run test:content")
  echo "  ❌ Failed" >&2
fi

echo "" >&2

# Step 2: CSS linting
echo "🎨 Step 2/6: Linting CSS..." >&2
if npm run lint:css >&2 2>&1; then
  echo "  ✅ Passed" >&2
else
  FAILURES+=("CSS linting - run: npm run lint:css")
  echo "  ❌ Failed" >&2
fi

echo "" >&2

# Step 3: Main site build
echo "📦 Step 3/6: Building main site..." >&2
if [ -f "package.json" ]; then
  if ! npm run build >&2 2>&1; then
    FAILURES+=("Main site build - run: npm run build")
    echo "  ❌ Failed" >&2
  else
    echo "  ✅ Passed" >&2
  fi
else
  echo "  ⚠️  No package.json found, skipping" >&2
fi

echo "" >&2

# Step 4: Lambda builds
echo "🔧 Step 4/6: Building Lambdas..." >&2
LAMBDA_COUNT=0

# Auto-discover buildable Lambdas (has package.json with build script)
for LAMBDA_DIR in lambda/*/; do
  # Skip if not a directory or is symlink (security)
  if [ ! -d "$LAMBDA_DIR" ] || [ -L "$LAMBDA_DIR" ]; then
    continue
  fi

  # Security: Extract and validate directory name format BEFORE any command execution
  # Use shell parameter expansion instead of basename to avoid executing commands on untrusted input
  LAMBDA_NAME="${LAMBDA_DIR%/}"       # Remove trailing slash
  LAMBDA_NAME="${LAMBDA_NAME##*/}"    # Extract basename (everything after last /)

  # Validate format before any further operations
  if [[ ! "$LAMBDA_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "  ⚠️  Skipping directory with invalid name: $LAMBDA_NAME" >&2
    continue
  fi

  # Check if buildable (has package.json with build script)
  PACKAGE_JSON="${LAMBDA_DIR}package.json"
  if [ ! -f "$PACKAGE_JSON" ]; then
    continue
  fi

  # Verify build script exists
  if ! grep -q '"build"' "$PACKAGE_JSON"; then
    echo "  ⚠️  Skipping $LAMBDA_NAME (no build script)" >&2
    continue
  fi

  LAMBDA_COUNT=$((LAMBDA_COUNT + 1))

  # Use absolute path for security (name already validated above)
  LAMBDA_PATH=$(realpath "$LAMBDA_DIR")
  PROJECT_ROOT=$(pwd)

  # Security: Verify path stays within project (defense in depth)
  if [[ "$LAMBDA_PATH" != "$PROJECT_ROOT"/lambda/* ]]; then
    echo "  ⚠️  Lambda path outside project directory: $LAMBDA_NAME (skipping)" >&2
    continue
  fi

  # Security: Defense-in-depth check for symlinks in resolved path components
  # This prevents attacks via symlinks inside lambda directories (e.g., lambda/evil/node_modules -> /etc)
  # Use lstat to check each path component without following symlinks
  SYMLINK_CHECK_PATH="$LAMBDA_PATH"
  while [[ "$SYMLINK_CHECK_PATH" != "$PROJECT_ROOT" ]] && [[ "$SYMLINK_CHECK_PATH" != "/" ]]; do
    if [ -L "$SYMLINK_CHECK_PATH" ]; then
      echo "  ⚠️  Symlink detected in path for $LAMBDA_NAME (skipping for security)" >&2
      continue 2  # Skip to next lambda directory in outer loop
    fi
    SYMLINK_CHECK_PATH=$(dirname "$SYMLINK_CHECK_PATH")
  done

  echo "  → $LAMBDA_NAME..." >&2
  if ! (cd "$LAMBDA_PATH" && npm run build >&2 2>&1); then
    FAILURES+=("Lambda $LAMBDA_NAME - run: cd lambda/$LAMBDA_NAME && npm run build")
    echo "    ❌ Failed" >&2
  else
    echo "    ✅ Passed" >&2
  fi
done

if [ $LAMBDA_COUNT -eq 0 ]; then
  echo "  ⚠️  No Lambda functions found with buildable package.json" >&2
fi

echo "" >&2

# Step 5: Test Guard validation
echo "🧪 Step 5/6: Checking test count and coverage..." >&2
if npm run test:guard >&2 2>&1; then
  echo "  ✅ Passed" >&2
else
  FAILURES+=("Test guard - run: npm run test:guard")
  echo "  ❌ Failed" >&2
fi

echo "" >&2

# Step 6: Infrastructure validation
echo "☁️  Step 6/6: Validating CDK infrastructure..." >&2
if [ -f "infrastructure/package.json" ]; then
  if ! (cd infrastructure && npx cdk synth --quiet >&2 2>&1); then
    FAILURES+=("CDK synth - run: cd infrastructure && npx cdk synth")
    echo "  ❌ Failed" >&2
  else
    echo "  ✅ Passed" >&2
  fi
else
  echo "  ⚠️  No infrastructure/package.json found, skipping" >&2
fi

echo "" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

# Report results
if [ ${#FAILURES[@]} -gt 0 ]; then
  echo "" >&2
  echo "❌ Pre-push validation FAILED" >&2
  echo "" >&2
  echo "Failures:" >&2
  for failure in "${FAILURES[@]}"; do
    echo "  • $failure" >&2
  done
  echo "" >&2
  echo "Fix these errors and try again." >&2
  echo "" >&2
  exit 2
fi

echo "✅ All validation steps PASSED" >&2
echo "" >&2
echo "Safe to push to remote! 🎉" >&2
exit 0
