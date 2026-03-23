# Security Hardening Checklist

## File Permissions

```bash
chmod 700 "$RUNNER_HOME"
chmod 600 "$RUNNER_HOME/.runner"
chmod 600 "$RUNNER_HOME/.credentials"
```

## Firewall Configuration (macOS)

**Requires sudo - must be run manually:**

```bash
# Enable firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Enable stealth mode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

# Verify status
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
```

## Organization/Repository Security Settings

### Fork PR Protection (Organization Level)

1. Navigate to: `https://github.com/organizations/<ORG>/settings/actions`
2. Under "Fork pull request workflows from outside collaborators":
   - Select: **"Require approval for first-time contributors"**

### Required Secrets

Configure at organization or repository level:

**For Claude Code reviews:**
- `CLAUDE_CODE_OAUTH_TOKEN`

**For AWS deployments:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**For application-specific features:**
- Any app-specific secrets (e.g., `RECAPTCHA_SECRET_KEY`)

**Check secrets:**
```bash
# Organization level
gh api /orgs/<ORG>/actions/secrets --jq '.secrets[].name'

# Repository level
gh api /repos/<OWNER>/<REPO>/actions/secrets --jq '.secrets[].name'
```

## Runner Security Best Practices

1. **Isolation**: Use dedicated user account for runner
2. **Updates**: Keep runner software updated (use update_runner.sh)
3. **Monitoring**: Enable monitoring scripts with cron
4. **Secrets**: Never log or print secret values
5. **Network**: Restrict network access if possible
6. **Storage**: Encrypt disk if handling sensitive data
7. **Access**: Limit who can add runners to organization/repository
8. **Labels**: Use specific labels to control which workflows run
9. **Environment Protection**: Use GitHub environment protection rules for production

## Verification Commands

```bash
# Check runner status
launchctl list | grep actions.runner

# Check file permissions
ls -la "$RUNNER_HOME" | grep -E '^\.|^d'

# Check GitHub status
gh api /orgs/<ORG>/actions/runners --jq '.runners[]'

# Review runner logs
tail -50 "$RUNNER_HOME/_diag/Runner_*.log"
```
