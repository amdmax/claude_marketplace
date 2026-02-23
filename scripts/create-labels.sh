#!/usr/bin/env bash
# One-time label bootstrap for amdmax/claude_marketplace
# Usage: ./scripts/create-labels.sh
# Requires: gh CLI authenticated with repo access

set -euo pipefail

REPO="amdmax/claude_marketplace"

labels=(
  "skill|#1D76DB|PR touches skills"
  "hook|#0E8A16|PR touches hooks"
  "bundle|#D93F0B|PR touches bundles"
  "skill-request|#5319E7|Issue: skill request"
  "hook-request|#006B75|Issue: hook request"
  "needs-triage|#FBCA04|Awaiting classification"
  "claude-analyzed|#EDEDED|Processed by Claude CI"
)

for entry in "${labels[@]}"; do
  IFS='|' read -r name color description <<< "$entry"
  echo "Creating label: $name"
  gh label create "$name" --repo "$REPO" --color "${color#\#}" --description "$description" --force
done

echo "All labels created."
