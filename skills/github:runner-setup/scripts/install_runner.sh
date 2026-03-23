#!/bin/bash
set -e

# GitHub Actions Self-Hosted Runner Installation Script
# Usage: ./install_runner.sh <org-or-repo> <runner-name> <labels> [runner-group]
#   org-or-repo: Organization name (e.g., "{{REPO_OWNER}}") or full repo path (e.g., "{{REPO_OWNER}}/website")
#   runner-name: Name for this runner (e.g., "macos-prod-runner-01")
#   labels: Comma-separated custom labels (e.g., "macos-arm64,node-22,aws-deployment")
#   runner-group: Optional runner group (default: "Default")

if [ $# -lt 3 ]; then
    echo "Usage: $0 <org-or-repo> <runner-name> <labels> [runner-group]"
    exit 1
fi

ORG_OR_REPO="$1"
RUNNER_NAME="$2"
CUSTOM_LABELS="$3"
RUNNER_GROUP="${4:-Default}"

# Determine if organization or repository
if [[ "$ORG_OR_REPO" == *"/"* ]]; then
    RUNNER_TYPE="repo"
    API_PATH="/repos/${ORG_OR_REPO}"
    URL="https://github.com/${ORG_OR_REPO}"
else
    RUNNER_TYPE="org"
    API_PATH="/orgs/${ORG_OR_REPO}"
    URL="https://github.com/${ORG_OR_REPO}"
fi

echo "=== GitHub Actions Runner Installation ==="
echo "Type: $RUNNER_TYPE"
echo "Target: $ORG_OR_REPO"
echo "Runner Name: $RUNNER_NAME"
echo "Custom Labels: $CUSTOM_LABELS"
echo ""

# Prerequisites Check
echo "=== Checking Prerequisites ==="

# Disk space (need 20GB+)
AVAILABLE_GB=$(df -g / | tail -1 | awk '{print $4}')
if [ "$AVAILABLE_GB" -lt 20 ]; then
    echo "ERROR: Insufficient disk space. Need 20GB+, have ${AVAILABLE_GB}GB"
    exit 1
fi
echo "✓ Disk space: ${AVAILABLE_GB}GB available"

# GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "ERROR: GitHub CLI not installed. Run: brew install gh"
    exit 1
fi
echo "✓ GitHub CLI: $(gh --version | head -1)"

# GitHub CLI authentication
if ! gh auth status &> /dev/null; then
    echo "ERROR: GitHub CLI not authenticated. Run: gh auth login"
    exit 1
fi
echo "✓ GitHub CLI authenticated"

# Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✓ Node.js: $NODE_VERSION"
else
    echo "⚠ Node.js not found (optional)"
fi

# AWS CLI
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    echo "✓ AWS CLI: $AWS_VERSION"
else
    echo "⚠ AWS CLI not found (optional)"
fi

echo ""

# Get runner version
echo "=== Downloading Runner ==="
RUNNER_VERSION=$(gh api /repos/actions/runner/releases/latest --jq '.tag_name' | sed 's/v//')
echo "Latest version: $RUNNER_VERSION"

RUNNER_HOME="$HOME/actions-runner-${ORG_OR_REPO//\//-}"
mkdir -p "$RUNNER_HOME"
cd "$RUNNER_HOME"

# Download runner
curl -o actions-runner-osx-arm64.tar.gz -L \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-arm64-${RUNNER_VERSION}.tar.gz"

tar xzf actions-runner-osx-arm64.tar.gz
rm actions-runner-osx-arm64.tar.gz

echo "✓ Runner downloaded to: $RUNNER_HOME"
echo ""

# Configure runner
echo "=== Configuring Runner ==="

# Check for admin:org scope if organization
if [ "$RUNNER_TYPE" = "org" ]; then
    if ! gh auth status 2>&1 | grep -q "admin:org"; then
        echo "Requesting admin:org scope..."
        gh auth refresh -h github.com -s admin:org
    fi
fi

# Get registration token
REGISTRATION_TOKEN=$(gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "${API_PATH}/actions/runners/registration-token" \
    --jq .token)

# Configure runner
./config.sh \
    --url "$URL" \
    --token "$REGISTRATION_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$CUSTOM_LABELS" \
    --runnergroup "$RUNNER_GROUP" \
    --work _work \
    --replace

echo "✓ Runner configured"
echo ""

# Install as service
echo "=== Installing as macOS Service ==="
./svc.sh install
./svc.sh start

echo "✓ Service installed and started"
echo ""

# Set permissions
echo "=== Setting Security Permissions ==="
chmod 700 "$RUNNER_HOME"
chmod 600 "$RUNNER_HOME/.runner" 2>/dev/null || true
chmod 600 "$RUNNER_HOME/.credentials" 2>/dev/null || true
echo "✓ File permissions set"
echo ""

# Verify runner
echo "=== Verifying Runner ==="
./svc.sh status

if [ "$RUNNER_TYPE" = "org" ]; then
    gh api "/orgs/${ORG_OR_REPO}/actions/runners" \
        --jq ".runners[] | select(.name==\"$RUNNER_NAME\") | {name, status, busy, os, labels: [.labels[].name]}"
else
    gh api "/repos/${ORG_OR_REPO}/actions/runners" \
        --jq ".runners[] | select(.name==\"$RUNNER_NAME\") | {name, status, busy, os, labels: [.labels[].name]}"
fi

echo ""
echo "=== Installation Complete ==="
echo "Runner home: $RUNNER_HOME"
echo "Runner name: $RUNNER_NAME"
echo ""
echo "Next steps:"
echo "1. Configure firewall (requires sudo)"
echo "2. Set up organization/repository secrets"
echo "3. Install monitoring scripts"
echo "4. Update workflow files to use: runs-on: [self-hosted, $CUSTOM_LABELS]"
