#!/usr/bin/env bash
set -euo pipefail

CONFIG_FILE=".agile-dev-team/project-config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "issueTracker: github  # default — $CONFIG_FILE not found"
  exit 0
fi

cat "$CONFIG_FILE"
