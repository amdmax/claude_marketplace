# Updating Workflows for Self-Hosted Runners

## Phased Rollout Strategy

Test workflows gradually, starting with lowest risk:

### Phase 1: Low-Risk Testing
Start with workflows that:
- Have no secrets
- Don't deploy to production
- Are easy to roll back

Examples:
- Code quality checks
- Linting
- Unit tests
- I18n validation

### Phase 2: Medium Risk
Progress to workflows that:
- Use organization secrets
- Run integration tests
- Generate artifacts

Examples:
- Claude Code reviews (needs `CLAUDE_CODE_OAUTH_TOKEN`)
- Build processes
- Docker image creation

### Phase 3: High Risk
Finally migrate workflows that:
- Deploy to production
- Require AWS credentials
- Affect live services

Examples:
- Production deployments
- Infrastructure updates
- Database migrations

## Updating `runs-on` Directive

### Basic Change Pattern

**Before:**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: npm run build
```

**After:**
```yaml
jobs:
  build:
    runs-on: [self-hosted, macos-arm64, node-22]
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: npm run build
```

### Using Multiple Labels for Specific Capabilities

**For deployment jobs:**
```yaml
jobs:
  deploy:
    runs-on: [self-hosted, macos-arm64, node-22, aws-deployment, aigensa-prod]
```

**For Claude Code reviews:**
```yaml
jobs:
  review:
    runs-on: [self-hosted, macos-arm64, node-22, claude-code]
```

## Label Strategy

### Standard Labels (Automatic)
- `self-hosted` - Always present on self-hosted runners
- `macOS` - OS detection
- `ARM64` - Architecture detection

### Custom Labels (Configure during setup)

**Architecture/Platform:**
- `macos-arm64` - Specific platform identifier
- `macos-x64` - For Intel Macs

**Runtime Environments:**
- `node-20` - Node.js 20.x installed
- `node-22` - Node.js 22.x installed
- `python-3.12` - Python 3.12 installed

**Capabilities:**
- `aws-deployment` - AWS CLI configured
- `claude-code` - Claude Code OAuth available
- `docker` - Docker available

**Environment:**
- `<org>-prod` - Production deployment capability
- `<org>-staging` - Staging environment

## Testing Workflow Changes

### 1. Create Test Branch
```bash
git checkout -b test/runner-<workflow-name>
```

### 2. Update Single Workflow
Start with one workflow file, one job at a time.

### 3. Push and Create PR
```bash
git add .github/workflows/<workflow-file>.yml
git commit -m "AIGWS-XXX: Test self-hosted runner for <workflow-name>"
git push -u origin test/runner-<workflow-name>

gh pr create \
  --title "Test: Self-hosted runner - <workflow-name>" \
  --body "Testing self-hosted runner setup for <workflow-name> workflow" \
  --base master
```

### 4. Monitor Execution
```bash
# Watch workflow run
gh run watch

# Get run details
RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view $RUN_ID --json jobs --jq '.jobs[]'
```

### 5. Verify Runner Usage
```bash
# Check which runner was used
gh run view $RUN_ID --json jobs \
  --jq '.jobs[] | {name, runner_name, status, conclusion}'
```

Expected output should show:
```json
{
  "name": "Build",
  "runner_name": "macos-prod-runner-01",
  "status": "completed",
  "conclusion": "success"
}
```

## Rollback Procedure

If issues occur:

### 1. Quick Rollback
Revert the workflow file change:

```bash
git checkout -b revert/runner-<workflow-name>

# Edit .github/workflows/<workflow-file>.yml
# Change back to: runs-on: ubuntu-latest

git add .github/workflows/<workflow-file>.yml
git commit -m "AIGWS-ROLLBACK: Revert <workflow-name> to GitHub-hosted runner"
git push -u origin revert/runner-<workflow-name>

gh pr create \
  --title "ROLLBACK: <workflow-name> to GitHub-hosted runner" \
  --body "Reverting due to runner issues" \
  --base master
```

### 2. Stop Runner (if needed)
```bash
cd "$RUNNER_HOME"
./svc.sh stop
```

### 3. Investigate Logs
```bash
# Runner logs
tail -100 "$RUNNER_HOME/_diag/Runner_*.log"

# Worker logs
tail -100 "$RUNNER_HOME/_diag/Worker_*.log"

# Monitor logs
tail -100 "$RUNNER_HOME/monitor.log"
```

## Common Workflow Patterns

### Matrix Builds

**Before:**
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
```

**After:**
```yaml
strategy:
  matrix:
    os:
      - ubuntu-latest
      - self-hosted-macos
runs-on: ${{ matrix.os }}
```

### Conditional Runner Selection

```yaml
runs-on: ${{ github.event_name == 'push' && github.ref == 'refs/heads/master' && '[self-hosted, macos-arm64, aigensa-prod]' || 'ubuntu-latest' }}
```

This uses self-hosted for production pushes, GitHub-hosted otherwise.

### Environment-Based Selection

```yaml
jobs:
  deploy-staging:
    runs-on: [self-hosted, macos-arm64, node-22]
    environment: staging

  deploy-production:
    runs-on: [self-hosted, macos-arm64, node-22, aws-deployment, aigensa-prod]
    environment: production
```

## Monitoring After Migration

### Daily Checks (First 30 Days)

```bash
# Runner status
gh api /orgs/<ORG>/actions/runners \
  --jq '.runners[] | select(.name=="<runner-name>")'

# Recent workflow runs
gh run list --repo <OWNER>/<REPO> --limit 10

# Disk usage
df -h /

# Monitor logs
tail -50 "$RUNNER_HOME/monitor.log"
```

### Weekly Checks

```bash
# Check for runner updates
cd "$RUNNER_HOME"
./update_runner.sh "$RUNNER_HOME"

# Review failed runs
gh run list --repo <OWNER>/<REPO> --status failure --limit 20

# Check disk space trends
df -h / >> "$RUNNER_HOME/disk-usage.log"
```
