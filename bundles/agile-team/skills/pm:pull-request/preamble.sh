#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE="${AGENT_DOCS_DIR:-docs}/project-config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "issueTracker: github  # default — $CONFIG_FILE not found"
  exit 0
fi

cat "$CONFIG_FILE"
