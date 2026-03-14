#!/bin/bash

# Log Rotation Script for GitHub Actions Runner
# Usage: ./rotate_logs.sh <runner-home> [days-to-keep]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <runner-home> [days-to-keep]"
    exit 1
fi

RUNNER_HOME="$1"
DAYS_TO_KEEP="${2:-7}"

# Delete old diagnostic logs
find "$RUNNER_HOME/_diag" -name "*.log" -mtime +"$DAYS_TO_KEEP" -delete 2>/dev/null

# Log the rotation
echo "[$(date)] Log rotation complete - removed files older than $DAYS_TO_KEEP days" >> "$RUNNER_HOME/monitor.log"
