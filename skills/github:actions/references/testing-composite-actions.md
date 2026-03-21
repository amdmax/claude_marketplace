# Testing Composite Actions

> **Reference for:** gh-actions skill
> **Context:** Strategies for testing GitHub Actions composite actions

## Testing Approaches

### 1. Validation (TypeScript)

Automated validation ensures action.yml files are well-formed.

**Run validator:**
```bash
npx tsx .claude/skills/gh-actions/validate-action.ts .github/actions/{action-name}/action.yml
```

**What it checks:**
- ✓ Valid YAML syntax
- ✓ Required fields present (name, description, runs.using)
- ✓ runs.using is "composite"
- ✓ All run: steps have shell: specified
- ✓ Valid shell values (bash, sh, pwsh, python, cmd)
- ⚠️ Inputs have descriptions (warning)
- ⚠️ No actions/checkout in action (warning)

**Integration:**
- Runs automatically via PostToolUse hook when writing action.yml
- Blocks invalid actions from being written
- Exit code 2 = validation failed

### 2. Local Testing with act

[nektos/act](https://github.com/nektos/act) runs GitHub Actions workflows locally.

**Install act:**
```bash
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Test specific job:**
```bash
# Test build job (includes setup-node and build-site actions)
act -j build

# Test with specific event
act pull_request -j lint

# Test all jobs
act
```

**Test with secrets:**
```bash
# Create .secrets file
echo "API_KEY=test-key-123" > .secrets

# Run with secrets
act -j deploy --secret-file .secrets
```

**Debug mode:**
```bash
# Verbose output
act -j build -v

# Step through
act -j build --dryrun
```

**Limitations:**
- Docker required
- May not perfectly match GitHub-hosted runners
- Some actions (e.g., artifact upload) behave differently
- Resource constraints on local machine

### 3. PR-Based Testing (Recommended)

Most reliable: test in actual GitHub Actions environment.

**Workflow:**
1. Create feature branch
2. Add/modify composite action
3. Update workflow to use action
4. Commit and push
5. Open PR
6. Review workflow run results

**Example:**
```bash
# Create branch
git checkout -b feature/add-setup-node-action

# Create action
mkdir -p .github/actions/setup-node
# Write action.yml...

# Update workflow
# Edit .github/workflows/validate.yml...

# Commit
git add .github/actions/setup-node
git add .github/workflows/validate.yml
/commit

# Push and create PR
git push -u origin feature/add-setup-node-action
/mr
```

**PR checks:**
- ✓ Workflow runs successfully
- ✓ Action executes as expected
- ✓ No breaking changes to existing jobs
- ✓ Performance within acceptable range

### 4. Integration Testing

Test actions in realistic scenarios.

**Test matrix:**
```yaml
# .github/workflows/test-actions.yml
name: Test Composite Actions

on:
  push:
    paths:
      - '.github/actions/**'
      - '.github/workflows/test-actions.yml'

jobs:
  test-setup-node:
    strategy:
      matrix:
        node-version: ['18', '20', '22']
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
        with:
          node-version: ${{ matrix.node-version }}
      - run: node --version
        shell: bash
      - run: npm --version
        shell: bash

  test-build-site:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/build-site
      - name: Verify build output
        run: |
          if [ ! -d "output" ]; then
            echo "❌ Build output directory missing"
            exit 1
          fi
          if [ ! -f "output/index.html" ]; then
            echo "❌ index.html not generated"
            exit 1
          fi
          echo "✓ Build successful"
        shell: bash
```

### 5. Smoke Testing

Quick sanity checks after deployment.

**Manual verification:**
```bash
# Check action exists
ls -la .github/actions/setup-node/action.yml

# Validate syntax
npx tsx .claude/skills/gh-actions/validate-action.ts .github/actions/setup-node/action.yml

# Verify workflow references action
grep -r "\./.github/actions/setup-node" .github/workflows/

# Check recent workflow runs
gh run list --workflow=validate.yml --limit 5
```

**Automated checks:**
```bash
# In CI/CD pipeline
- name: Verify composite actions
  run: |
    for action in .github/actions/*/action.yml; do
      echo "Validating: $action"
      npx tsx .claude/skills/gh-actions/validate-action.ts "$action"
    done
```

## Testing Checklist

Before committing new composite action:

**Validation:**
- [ ] Passes TypeScript validator
- [ ] All required fields present
- [ ] All run: steps have shell: bash
- [ ] No actions/checkout in action
- [ ] Inputs documented
- [ ] Outputs documented (if any)

**Functional:**
- [ ] Action executes successfully locally (act or PR)
- [ ] Produces expected outputs
- [ ] Handles errors gracefully
- [ ] Working directory handled correctly

**Integration:**
- [ ] Workflow updated to use action
- [ ] No breaking changes to existing jobs
- [ ] Performance acceptable (execution time)
- [ ] Compatible with matrix strategies (if applicable)

**Documentation:**
- [ ] Action name and description clear
- [ ] Inputs explained with examples
- [ ] Usage example in workflow
- [ ] Edge cases documented

## Common Testing Issues

### Issue: Action not found

**Symptom:**
```
Error: Unable to resolve action `./.github/actions/setup-node`
```

**Causes:**
- Path incorrect (must start with `./`)
- action.yml file missing or misspelled
- Not committed to repository

**Fix:**
```bash
# Verify path
ls -la .github/actions/setup-node/action.yml

# Ensure committed
git add .github/actions/setup-node/action.yml
git commit -m "Add setup-node action"
git push
```

### Issue: Shell not specified

**Symptom:**
```
Error: Required property is missing: shell
```

**Cause:**
- run: step missing shell: bash

**Fix:**
```yaml
# Before (invalid)
- run: npm test

# After (valid)
- run: npm test
  shell: bash
```

### Issue: Working directory not applied

**Symptom:**
- Action runs in wrong directory
- Files not found

**Causes:**
- working-directory input not used
- Workflow doesn't pass working-directory

**Fix:**
```yaml
# Action should support working-directory input
inputs:
  working-directory:
    description: Working directory
    required: false
    default: '.'

# Apply to all steps
steps:
  - run: npm ci
    shell: bash
    working-directory: ${{ inputs.working-directory }}
```

### Issue: Secrets not available

**Symptom:**
```
Error: Input 'api-key' is required but not supplied
```

**Cause:**
- Trying to pass secrets as inputs (not supported)

**Fix:**
```yaml
# Don't use inputs for secrets
# Use env vars instead

# Workflow passes secret via env
- uses: ./.github/actions/deploy
  env:
    API_KEY: ${{ secrets.API_KEY }}

# Action accesses via env
- run: ./deploy.sh
  shell: bash
  env:
    API_KEY: ${{ env.API_KEY }}
```

## Performance Testing

**Measure execution time:**

```yaml
# In workflow
- name: Start timer
  id: timer
  run: echo "start=$(date +%s)" >> $GITHUB_OUTPUT
  shell: bash

- uses: ./.github/actions/setup-node

- name: Calculate duration
  run: |
    START=${{ steps.timer.outputs.start }}
    END=$(date +%s)
    DURATION=$((END - START))
    echo "⏱️  Duration: ${DURATION}s"
  shell: bash
```

**Compare with baseline:**

```bash
# Before refactoring (inline steps): 45s
# After refactoring (composite action): 47s
# Overhead: +2s (acceptable)
```

**Optimization strategies:**
- Use caching (npm cache, build cache)
- Parallelize independent steps
- Skip unnecessary steps (conditionals)
- Reduce artifact sizes

## Regression Testing

**When to run:**
- After modifying existing action
- After changing action dependencies
- After workflow refactoring

**Approach:**
1. Identify workflows using the action
2. Run all affected workflows
3. Compare results with baseline
4. Verify no breaking changes

**Automated regression tests:**
```yaml
# .github/workflows/regression.yml
name: Regression Tests

on:
  pull_request:
    paths:
      - '.github/actions/**'

jobs:
  # Run all workflows that use composite actions
  validate:
    uses: ./.github/workflows/validate.yml

  deploy-test:
    uses: ./.github/workflows/deploy.yml
    with:
      environment: staging
```

## Best Practices

✅ **Test in PR before merging** - Catch issues early
✅ **Use act for quick iteration** - Faster than pushing to GitHub
✅ **Test across OS matrix** - Ensure cross-platform compatibility
✅ **Validate inputs** - Test with various input combinations
✅ **Check error handling** - Verify graceful failure
✅ **Monitor performance** - Watch for execution time increases
✅ **Document test scenarios** - Make testing repeatable
✅ **Automate validation** - Use PostToolUse hooks

## Resources

- **act documentation:** https://github.com/nektos/act
- **GitHub Actions docs:** https://docs.github.com/en/actions/creating-actions/creating-a-composite-action
- **Action testing guide:** https://docs.github.com/en/actions/creating-actions/testing-your-action
- **Project validator:** `.claude/skills/gh-actions/validate-action.ts`
