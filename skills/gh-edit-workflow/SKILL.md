---
name: gh:edit-workflow
description: Edit GitHub Actions workflows with automatic validation
tags: [github, workflows, ci-cd, validation]
hooks:
  PostToolUse:
    - matcher: Edit|Write
      command: $SKILL_DIR/validate-workflow-output.sh
---

# GitHub Actions Workflow Editor

Edit GitHub Actions workflows safely with automatic actionlint validation after changes.

## Usage

```bash
/gh:edit-workflow
```

The skill will:
1. Ask which workflow to edit or create
2. Provide context on workflow patterns
3. Guide edits with validation
4. Run actionlint after changes via PostToolUse hook
5. Show validation results

## Workflow Patterns

### Custom Runner Labels
Add custom labels to @.github/actionlint.yaml:
```yaml
self-hosted-runner:
  labels:
    - node-22
    - custom-label
```

### Common Ignore Rules
Avoid false positives with ignore patterns. See validation hook at @.claude/hooks/validate-workflows.sh for examples:
- `SC2086:info` - shellcheck double quote warnings
- `SC2016:info` - expressions in single quotes
- `constant expression "false"` - disabled jobs

### Conditional Steps
Guard AWS/sensitive operations:
```yaml
- name: Configure AWS
  if: github.event_name == 'push'
  uses: aws-actions/configure-aws-credentials@v5
```

### Manual Workflows
Prevent accidental deployments:
```yaml
on:
  workflow_dispatch:
    inputs:
      deploy_infrastructure:
        type: boolean
        default: false
```

## Validation

PostToolUse hook automatically validates edited workflows:
- ✅ Syntax errors caught immediately
- ✅ Invalid action versions detected
- ✅ Missing required fields flagged
- ✅ Custom runner labels verified

See validation logic: @.claude/hooks/utils/check-actionlint.sh

## Installation Check

If actionlint is missing:
```bash
# macOS
brew install actionlint

# Linux
# Download from https://github.com/rhysd/actionlint/releases
```

## Project Workflows

- **@.github/workflows/deploy.yml** - Main deployment workflow
- **@.github/workflows/validate-infrastructure.yml** - CDK validation
- **@.github/actionlint.yaml** - Validation configuration

## Error Handling

**Validation fails after edit:**
1. Hook shows actionlint errors
2. Fix issues in the file
3. Validation re-runs automatically on next edit

**Missing required fields:**
- `runs-on` - Always required for jobs
- `steps` - At least one step per job
- `uses` or `run` - Each step needs an action

**Invalid action versions:**
- Use `@v4` not `@v999`
- Check action repos for latest versions
- Pin to specific commits for stability

## Best Practices

- **Test locally** - Use `act` to test workflows locally
- **Validate early** - Run actionlint before committing
- **Pin versions** - Use specific action versions (@v4, not @latest)
- **Minimal permissions** - Grant least privilege to jobs
- **Conditional AWS** - Guard cloud operations with `if:` conditions
