#!/bin/bash
set -e

# GitHub Actions Runner Update Script
# Usage: ./update_runner.sh <runner-home>

if [ $# -lt 1 ]; then
    echo "Usage: $0 <runner-home>"
    exit 1
fi

RUNNER_HOME="$1"

if [ ! -d "$RUNNER_HOME" ]; then
    echo "ERROR: Runner home not found: $RUNNER_HOME"
    exit 1
fi

cd "$RUNNER_HOME"

echo "=== Updating GitHub Actions Runner ==="

# Stop service
echo "Stopping runner service..."
./svc.sh stop

# Get latest version
CURRENT_VERSION=$(grep -A1 "RunnerEvent: Runner is built" _diag/Runner_*.log 2>/dev/null | tail -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
LATEST_VERSION=$(gh api /repos/actions/runner/releases/latest --jq '.tag_name' | sed 's/v//')

echo "Current version: $CURRENT_VERSION"
echo "Latest version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Runner is already up to date"
    ./svc.sh start
    exit 0
fi

# Download latest version
echo "Downloading version $LATEST_VERSION..."
curl -o actions-runner-osx-arm64.tar.gz -L \
    "https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/actions-runner-osx-arm64-${LATEST_VERSION}.tar.gz"

# Extract (preserves configuration)
echo "Extracting..."
tar xzf actions-runner-osx-arm64.tar.gz
rm actions-runner-osx-arm64.tar.gz

# Start service
echo "Starting runner service..."
./svc.sh start

# Verify
echo ""
./svc.sh status

echo ""
echo "=== Update Complete ==="
echo "Updated from $CURRENT_VERSION to $LATEST_VERSION"
