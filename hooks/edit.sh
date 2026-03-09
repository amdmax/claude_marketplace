#!/bin/bash

# Hook that runs after Edit tool is called
# Check if infrastructure files were modified and validate CDK synth

FILE_PATH="$1"

# Check if the edited file is in the infrastructure directory
if [[ "$FILE_PATH" == *"/infrastructure/"* ]]; then
  echo "🔍 Infrastructure file modified, validating CDK stack..."

  cd "$(git rev-parse --show-toplevel)/infrastructure" || exit 1

  # Run CDK synth for validation
  if npx cdk synth --quiet > /dev/null 2>&1; then
    echo "✅ CDK synth validation passed"
  else
    echo "⚠️  CDK synth validation failed. Run 'cd infrastructure && npx cdk synth' to see errors."
    exit 1
  fi
fi

exit 0
