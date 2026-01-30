#!/bin/bash

# GitHub Actions Runner Monitoring Script
# Usage: ./monitor_runner.sh <runner-home> <org-or-repo> <runner-name>

if [ $# -lt 3 ]; then
    echo "Usage: $0 <runner-home> <org-or-repo> <runner-name>"
    exit 1
fi

RUNNER_HOME="$1"
ORG_OR_REPO="$2"
RUNNER_NAME="$3"
LOG_FILE="$RUNNER_HOME/monitor.log"

# Determine if organization or repository
if [[ "$ORG_OR_REPO" == *"/"* ]]; then
    API_PATH="/repos/${ORG_OR_REPO}"
else
    API_PATH="/orgs/${ORG_OR_REPO}"
fi

echo "[$(date)] Checking runner status..." >> "$LOG_FILE"

# Check service running
if ! launchctl list | grep -q "actions.runner"; then
    echo "[$(date)] Runner STOPPED - Restarting" >> "$LOG_FILE"
    cd "$RUNNER_HOME" && ./svc.sh start
fi

# Check GitHub status
RUNNER_STATUS=$(gh api "${API_PATH}/actions/runners" \
    --jq ".runners[] | select(.name==\"$RUNNER_NAME\") | .status" 2>/dev/null)

if [ -z "$RUNNER_STATUS" ]; then
    echo "[$(date)] WARNING: Runner not found in GitHub" >> "$LOG_FILE"
elif [ "$RUNNER_STATUS" != "online" ]; then
    echo "[$(date)] WARNING: Runner status: $RUNNER_STATUS" >> "$LOG_FILE"
else
    echo "[$(date)] GitHub status: $RUNNER_STATUS" >> "$LOG_FILE"
fi

# Check disk space
DISK_USAGE=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "[$(date)] WARNING: Disk usage ${DISK_USAGE}%" >> "$LOG_FILE"
fi

# Keep only last 1000 lines
tail -1000 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
