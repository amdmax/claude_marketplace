# Troubleshooting GitHub Actions Self-Hosted Runners

## Runner Service Issues

### Runner Won't Start

**Symptom:** `./svc.sh start` fails or service doesn't stay running

**Check:**
```bash
# View service status
./svc.sh status

# Check launchd logs
tail -100 ~/Library/Logs/actions.runner.*.log

# Check runner diagnostic logs
tail -100 _diag/Runner_*.log
```

**Common causes:**
1. **Permissions issue**: Ensure runner directory is `chmod 700`
2. **Configuration corruption**: Remove and reconfigure
3. **GitHub token expired**: Re-run config.sh with new token

**Fix:**
```bash
# Stop service
./svc.sh stop
./svc.sh uninstall

# Reconfigure
REGISTRATION_TOKEN=$(gh api --method POST /orgs/<ORG>/actions/runners/registration-token --jq .token)
./config.sh --url https://github.com/<ORG> --token "$REGISTRATION_TOKEN" --name "<runner-name>" --labels "<labels>"

# Reinstall service
./svc.sh install
./svc.sh start
```

### Runner Shows Offline in GitHub

**Symptom:** Runner appears offline in GitHub settings but service is running

**Check:**
```bash
# Local service status
./svc.sh status
launchctl list | grep actions.runner

# GitHub status
gh api /orgs/<ORG>/actions/runners --jq '.runners[] | select(.name=="<runner-name>")'
```

**Common causes:**
1. **Network connectivity**: Check internet connection
2. **GitHub outage**: Check https://www.githubstatus.com
3. **Runner version outdated**: Update runner

**Fix:**
```bash
# Restart service
./svc.sh stop
./svc.sh start

# Update runner
./update_runner.sh "$RUNNER_HOME"
```

## Workflow Execution Issues

### Workflow Doesn't Use Self-Hosted Runner

**Symptom:** Workflow runs on GitHub-hosted runner instead of self-hosted

**Check workflow file:**
```yaml
runs-on: [self-hosted, macos-arm64]  # Must match runner labels
```

**Common causes:**
1. **Label mismatch**: Workflow labels don't match runner labels
2. **Runner offline**: Runner not available when workflow triggered
3. **Runner busy**: All matching runners are busy

**Verify runner labels:**
```bash
gh api /orgs/<ORG>/actions/runners \
  --jq '.runners[] | select(.name=="<runner-name>") | .labels[].name'
```

**Fix:**
- Update workflow file with correct labels
- Ensure runner is online before triggering workflow
- Add more runners if capacity is an issue

### Workflow Fails with "Could not find executable"

**Symptom:** Workflow fails with errors like `node: command not found` or `npm: command not found`

**Common causes:**
1. **PATH not set correctly**: Runner service doesn't have user PATH
2. **Tool not installed**: Required tool missing on runner machine
3. **Shell environment**: Different shell environment than expected

**Check environment:**
```bash
# Check what's available in runner context
cat > test-workflow.yml <<EOF
name: Test Environment
on: workflow_dispatch
jobs:
  test:
    runs-on: [self-hosted, macos-arm64]
    steps:
      - run: echo \$PATH
      - run: which node
      - run: which npm
      - run: node --version
EOF
```

**Fix:**
Add PATH to workflow:
```yaml
jobs:
  build:
    runs-on: [self-hosted, macos-arm64]
    env:
      PATH: /usr/local/bin:/usr/bin:/bin:/opt/homebrew/bin:$PATH
    steps:
      - run: npm install
```

Or update runner configuration:
```bash
# Edit run-helper.sh.template before configuring runner
# Add: export PATH="/opt/homebrew/bin:$PATH"
```

### Permission Denied Errors

**Symptom:** Workflow fails with permission denied on file operations

**Common causes:**
1. **Workspace permissions**: Wrong ownership of _work directory
2. **Script permissions**: Script not executable
3. **File system permissions**: Protected directories

**Fix:**
```bash
# Fix workspace permissions
cd "$RUNNER_HOME"
chmod 755 _work
chown -R $(whoami) _work

# Ensure scripts are executable in workflow
- run: chmod +x ./script.sh && ./script.sh
```

## Authentication Issues

### GitHub CLI Not Authenticated

**Symptom:** `gh api` commands fail with authentication errors

**Fix:**
```bash
gh auth login --hostname github.com --git-protocol ssh --web

# For organization runners, also need admin:org scope
gh auth refresh -h github.com -s admin:org
```

### AWS Credentials Not Available

**Symptom:** AWS CLI commands fail in workflow

**Check secrets:**
```bash
# Organization level
gh api /orgs/<ORG>/actions/secrets --jq '.secrets[].name'

# Repository level
gh api /repos/<OWNER>/<REPO>/actions/secrets --jq '.secrets[].name'
```

**Verify in workflow:**
```yaml
- name: Test AWS
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  run: |
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
      echo "AWS_ACCESS_KEY_ID not set"
      exit 1
    fi
    aws sts get-caller-identity
```

## Disk Space Issues

### Runner Running Out of Disk Space

**Symptom:** Workflows fail with disk full errors, or monitoring warns of >80% usage

**Check:**
```bash
# Overall disk usage
df -h /

# Runner directory size
du -sh "$RUNNER_HOME"
du -sh "$RUNNER_HOME/_work"

# Find large files
find "$RUNNER_HOME/_work" -type f -size +100M -exec ls -lh {} \;
```

**Fix:**
```bash
# Clean work directory
cd "$RUNNER_HOME/_work"
rm -rf *

# Clean old diagnostic logs
find "$RUNNER_HOME/_diag" -name "*.log" -mtime +7 -delete

# Clean Docker if used
docker system prune -af --volumes

# Check for cached files
du -sh ~/Library/Caches/*
```

## Performance Issues

### Workflows Running Slowly

**Symptoms:** Workflows take much longer on self-hosted runner than GitHub-hosted

**Check:**
```bash
# CPU usage
top -l 1 | grep "CPU usage"

# Memory usage
top -l 1 | grep PhysMem

# Disk I/O
iostat -w 1 -c 5
```

**Common causes:**
1. **Multiple workflows running**: Runner busy with concurrent jobs
2. **Resource limits**: Insufficient CPU/memory
3. **Network issues**: Slow package downloads
4. **Disk I/O**: Slow disk performance

**Fix:**
- Add more runners for parallel capacity
- Increase runner machine resources
- Use local caching for dependencies
- Enable workflow concurrency limits

## Monitoring Issues

### Monitor Script Not Running

**Symptom:** No entries in monitor.log or logs stopped updating

**Check cron:**
```bash
crontab -l
```

**Check execution:**
```bash
# Manually run monitor script
./monitor-runner.sh "$RUNNER_HOME" "<ORG>" "<runner-name>"

# Check cron logs
tail -100 /var/mail/$USER
```

**Fix:**
```bash
# Re-add cron jobs
echo "*/15 * * * * $RUNNER_HOME/monitor-runner.sh \"$RUNNER_HOME\" \"<ORG>\" \"<runner-name>\"" > /tmp/cron.txt
echo "0 2 * * * $RUNNER_HOME/rotate-logs.sh \"$RUNNER_HOME\"" >> /tmp/cron.txt
crontab /tmp/cron.txt
```

## Complete Removal and Reinstall

If all else fails, completely remove and reinstall:

```bash
# 1. Stop and uninstall service
cd "$RUNNER_HOME"
./svc.sh stop
./svc.sh uninstall

# 2. Remove from GitHub
REMOVE_TOKEN=$(gh api --method POST /orgs/<ORG>/actions/runners/remove-token --jq .token)
./config.sh remove --token "$REMOVE_TOKEN"

# 3. Delete runner directory
cd ~
rm -rf "$RUNNER_HOME"

# 4. Reinstall using install_runner.sh script
./install_runner.sh <ORG> <runner-name> <labels>
```

## Getting Help

### Useful Log Locations

```bash
# Runner logs
$RUNNER_HOME/_diag/Runner_*.log

# Worker logs
$RUNNER_HOME/_diag/Worker_*.log

# Service logs
~/Library/Logs/actions.runner.*.log

# Monitor logs
$RUNNER_HOME/monitor.log
```

### Diagnostic Information to Collect

```bash
# System info
system_profiler SPSoftwareDataType SPHardwareDataType

# Runner status
gh api /orgs/<ORG>/actions/runners --jq '.runners[] | select(.name=="<runner-name>")'

# Service status
launchctl list | grep actions.runner
./svc.sh status

# Recent logs
tail -200 "$RUNNER_HOME/_diag/Runner_*.log"
```

### GitHub Actions Documentation

- [Self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Troubleshooting](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/monitoring-and-troubleshooting-self-hosted-runners)
