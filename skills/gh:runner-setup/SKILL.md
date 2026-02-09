---
name: github-runner-setup
description: Configure GitHub Actions self-hosted runners on macOS with automated installation, security hardening, monitoring, and workflow migration. Use when setting up self-hosted runners for GitHub Actions, configuring organization or repository runners, adding macOS runners with custom labels (Node.js versions, AWS deployment, Claude Code), or migrating workflows from GitHub-hosted to self-hosted runners. Handles prerequisites verification, service setup with launchd, security configuration, monitoring scripts, and phased workflow rollout.
---

# GitHub Actions Self-Hosted Runner Setup

Automate the complete setup of GitHub Actions self-hosted runners on macOS, including installation, security hardening, monitoring, and workflow migration.

## Quick Start

### Install Runner

Use the installation script for automated setup:

```bash
./scripts/install_runner.sh <org-or-repo> <runner-name> <labels> [runner-group]
```

**Parameters:**
- `org-or-repo`: Organization name (e.g., `aigensa`) or repository path (e.g., `aigensa/website`)
- `runner-name`: Unique name for this runner (e.g., `macos-prod-runner-01`)
- `labels`: Comma-separated custom labels (e.g., `macos-arm64,node-22,aws-deployment,claude-code`)
- `runner-group` (optional): Runner group name (default: `Default`)

**Example - Organization Runner:**
```bash
./scripts/install_runner.sh aigensa macos-prod-runner-01 "macos-arm64,node-22,aws-deployment,claude-code"
```

**Example - Repository Runner:**
```bash
./scripts/install_runner.sh aigensa/website macos-repo-runner-01 "macos-arm64,node-20"
```

The script automatically:
1. Verifies prerequisites (disk space, gh CLI, Node.js, AWS CLI)
2. Downloads latest runner version
3. Configures runner with custom labels
4. Installs as macOS launchd service
5. Sets security permissions
6. Verifies runner is online

### Setup Monitoring

After installation, configure monitoring scripts:

```bash
cd ~/actions-runner-<org-or-repo>

# Copy monitoring scripts
cp /path/to/skill/scripts/monitor_runner.sh .
cp /path/to/skill/scripts/rotate_logs.sh .
chmod +x monitor_runner.sh rotate_logs.sh

# Add cron jobs
echo "*/15 * * * * $PWD/monitor_runner.sh \"$PWD\" \"<org-or-repo>\" \"<runner-name>\"" > /tmp/cron.txt
echo "0 2 * * * $PWD/rotate_logs.sh \"$PWD\"" >> /tmp/cron.txt
crontab /tmp/cron.txt
```

### Manual Security Configuration

The firewall configuration requires sudo and must be run manually:

```bash
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

## Label Strategy

Choose labels based on runner capabilities:

**Architecture/Platform:**
- `macos-arm64` - Apple Silicon
- `macos-x64` - Intel

**Runtime Environments:**
- `node-20` - Node.js 20.x
- `node-22` - Node.js 22.x
- `python-3.12` - Python 3.12

**Capabilities:**
- `aws-deployment` - AWS CLI configured
- `claude-code` - Claude Code OAuth available
- `docker` - Docker installed

**Environment:**
- `<org>-prod` - Production deployment
- `<org>-staging` - Staging environment

## Workflow Migration

Update workflows gradually using a phased approach. See [references/workflow-updates.md](references/workflow-updates.md) for complete guide.

### Phase 1: Low-Risk Testing

Start with workflows that have no secrets:

```yaml
jobs:
  quality-gates:
    runs-on: [self-hosted, macos-arm64, node-22]
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test
```

### Phase 2: Medium Risk

Progress to workflows using organization secrets:

```yaml
jobs:
  claude-review:
    runs-on: [self-hosted, macos-arm64, node-22, claude-code]
    env:
      CLAUDE_CODE_OAUTH_TOKEN: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

### Phase 3: High Risk

Finally migrate deployment workflows:

```yaml
jobs:
  deploy:
    runs-on: [self-hosted, macos-arm64, node-22, aws-deployment, aigensa-prod]
    environment: production
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

## Maintenance

### Check Runner Status

```bash
# Local service status
cd ~/actions-runner-<org-or-repo>
./svc.sh status

# GitHub status
gh api /orgs/<ORG>/actions/runners --jq '.runners[] | select(.name=="<runner-name>")'

# View logs
tail -50 _diag/Runner_*.log
tail -50 monitor.log
```

### Update Runner

Use the update script to install latest runner version:

```bash
./scripts/update_runner.sh ~/actions-runner-<org-or-repo>
```

### Monitor Disk Space

```bash
# Check disk usage
df -h /

# Clean work directory if needed
cd ~/actions-runner-<org-or-repo>
rm -rf _work/*

# Rotate old logs
find _diag -name "*.log" -mtime +7 -delete
```

## Security Checklist

Before production use, complete these manual steps:

1. **Firewall Configuration** - Enable macOS firewall and stealth mode (requires sudo)
2. **Organization Secrets** - Configure required secrets in GitHub organization settings
3. **Fork PR Protection** - Require approval for first-time contributors
4. **File Permissions** - Verify runner directory is chmod 700
5. **Monitoring** - Confirm cron jobs are active
6. **Test Workflow** - Verify runner works with low-risk workflow first

See [references/security-checklist.md](references/security-checklist.md) for complete checklist.

## Troubleshooting

See [references/troubleshooting.md](references/troubleshooting.md) for solutions to common issues:

- Runner service won't start
- Runner shows offline in GitHub
- Workflows don't use self-hosted runner
- Permission denied errors
- Authentication issues
- Disk space problems
- Performance issues

## Complete Removal

To completely remove a runner:

```bash
cd ~/actions-runner-<org-or-repo>

# Stop and uninstall service
./svc.sh stop
./svc.sh uninstall

# Remove from GitHub
REMOVE_TOKEN=$(gh api --method POST /orgs/<ORG>/actions/runners/remove-token --jq .token)
./config.sh remove --token "$REMOVE_TOKEN"

# Delete directory
cd ~
rm -rf actions-runner-<org-or-repo>

# Remove cron jobs
crontab -l | grep -v "actions-runner-<org-or-repo>" | crontab -
```

## Prerequisites

Before running the installation script, ensure:

- **Disk Space**: 20GB+ available
- **GitHub CLI**: Installed and authenticated (`gh auth login`)
- **Organization Access**: Admin permissions for organization runners
- **Node.js**: Installed if using node-* labels (optional)
- **AWS CLI**: Installed if using aws-deployment label (optional)
- **macOS**: Darwin 25.x+ with ARM64 or x64 architecture

## Organization vs Repository Runners

**Organization-level runners:**
- Available to all repositories in the organization
- Centralized management
- Requires organization admin permissions
- Best for shared infrastructure

**Repository-level runners:**
- Scoped to single repository
- Requires repository admin permissions
- Best for repository-specific requirements

Choose based on your access level and use case.

## Useful Links

- [Runner Status](https://github.com/organizations/<ORG>/settings/actions/runners)
- [Organization Secrets](https://github.com/organizations/<ORG>/settings/secrets/actions)
- [Actions Settings](https://github.com/organizations/<ORG>/settings/actions)
- [GitHub Actions Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
