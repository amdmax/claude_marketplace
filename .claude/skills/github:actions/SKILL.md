---
name: github:actions
description: Create and manage GitHub Actions composite actions
tags: [github, workflows, ci-cd, composite-actions]
version: 1.0.0
author: "@thesolutionarchitect"
email: maksym.diabin@gmail.com
hooks:
  PostToolUse:
    command: npx tsx $SKILL_DIR/validate-action.ts
    description: Validate action.yml after write
    timeout: 10000
---

# GitHub Actions Composite Actions


## Overview

This skill helps you create **GitHub Actions composite actions** - reusable workflow components that reduce duplication and improve maintainability in CI/CD pipelines.

**What are composite actions?**
- Reusable workflow steps bundled into a single action
- Stored in `.github/actions/{action-name}/action.yml`
- Called from workflows using `uses: ./.github/actions/{action-name}`
- Support inputs, outputs, and complex logic

**Why use them?**
- **DRY principle** - Define once, use everywhere
- **Modularity** - Break large workflows into logical units
- **Testability** - Test actions in isolation
- **Maintainability** - Update action definition, all workflows benefit

**When to create composite actions:**
- Repeated sequences of steps across workflows (setup, build, test)
- Complex multi-step operations (CDK validation, security audits)
- Workflow refactoring (breaking down 300+ line workflows)

## Quick Start

### Create a Simple Composite Action

```yaml
# .github/actions/setup-node/action.yml
name: Setup Node.js
description: Install Node.js and restore npm cache

inputs:
  node-version:
    description: Node.js version to install
    required: false
    default: '20'

runs:
  using: composite
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci
      shell: bash
```

### Use the Action in a Workflow

```yaml
# .github/workflows/validate.yml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup project
        uses: ./.github/actions/setup-node
        with:
          node-version: '20'

      - name: Run tests
        run: npm test
```

## Common Patterns for This Project

### Setup Pattern (Node + Dependencies)

```yaml
# .github/actions/setup-node/action.yml
name: Setup Node.js with dependencies
description: Install Node.js, restore cache, and install dependencies

inputs:
  node-version:
    description: Node.js version
    required: false
    default: '20'
  working-directory:
    description: Working directory for npm install
    required: false
    default: '.'

runs:
  using: composite
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
        cache-dependency-path: ${{ inputs.working-directory }}/package-lock.json

    - name: Install dependencies
      run: npm ci
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

### Build Pattern (Build + Artifact)

```yaml
# .github/actions/build-site/action.yml
name: Build static site
description: Build site and upload artifact

inputs:
  artifact-name:
    description: Name for build artifact
    required: false
    default: 'site-build'

runs:
  using: composite
  steps:
    - name: Build site
      run: npm run build
      shell: bash

    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: ${{ inputs.artifact-name }}
        path: output/
        retention-days: 7
```

### Test Pattern (Selective Testing)

```yaml
# .github/actions/run-tests/action.yml
name: Run selective tests
description: Run tests for changed modules

inputs:
  module:
    description: Module to test (src, infrastructure, lambda)
    required: true

runs:
  using: composite
  steps:
    - name: Run tests for ${{ inputs.module }}
      run: |
        case "${{ inputs.module }}" in
          src)
            npm run test:unit
            ;;
          infrastructure)
            cd infrastructure && npm test
            ;;
          lambda-auth)
            cd lambda/auth-edge && npm test
            ;;
          *)
            echo "Unknown module: ${{ inputs.module }}"
            exit 1
            ;;
        esac
      shell: bash
```

### Validation Pattern (CDK Synth)

```yaml
# .github/actions/validate-cdk/action.yml
name: Validate CDK infrastructure
description: Run CDK synth and validation checks

inputs:
  working-directory:
    description: Directory containing CDK app
    required: false
    default: 'infrastructure'

runs:
  using: composite
  steps:
    - name: CDK synth
      run: npm run cdk synth
      shell: bash
      working-directory: ${{ inputs.working-directory }}

    - name: Run cdk-nag
      run: npm run cdk:nag
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

## Important Constraints

### 1. Always Specify `shell: bash`

**❌ Invalid:**
```yaml
steps:
  - name: Run command
    run: npm test
```

**✅ Valid:**
```yaml
steps:
  - name: Run command
    run: npm test
    shell: bash
```

**Why:** Composite actions require explicit shell declaration for `run:` steps.

### 2. No Checkout in Composite Actions

**❌ Don't include:**
```yaml
steps:
  - uses: actions/checkout@v4  # ❌ Caller's responsibility
  - run: npm test
    shell: bash
```

**✅ Caller handles checkout:**
```yaml
# Workflow calls action
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/run-tests
```

**Why:** Checkout is done once by the workflow, not by each action.

### 3. Working Directory Handling

**Pattern:**
```yaml
inputs:
  working-directory:
    description: Working directory
    required: false
    default: '.'

runs:
  using: composite
  steps:
    - name: Run command
      run: npm test
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

### 4. Secrets via Environment Variables

**❌ Don't use secrets as inputs:**
```yaml
inputs:
  api-key:  # ❌ Secrets not supported in composite action inputs
    required: true
```

**✅ Use env vars:**
```yaml
# Workflow passes secrets via env
- uses: ./.github/actions/deploy
  env:
    API_KEY: ${{ secrets.API_KEY }}

# Action accesses via $API_KEY
```

## Workflow: Refactor validate.yml

See [@references/validate-workflow-refactor.md](references/validate-workflow-refactor.md) for detailed step-by-step guide to breaking down the project's validate.yml workflow.

**High-level approach:**
1. Identify repeated patterns (setup, build, test)
2. Extract to composite actions
3. Replace in workflow with `uses:` calls
4. Test incrementally
5. Commit with `/commit` skill

## Validation Checklist

Before committing composite actions:

- [ ] Valid YAML syntax
- [ ] All `run:` steps have `shell: bash`
- [ ] No `actions/checkout@v4` in action
- [ ] Inputs have descriptions
- [ ] Outputs documented (if any)
- [ ] Working directory handled correctly
- [ ] Secrets passed via env vars
- [ ] Tested locally or in PR

**Automatic validation:** PostToolUse hook runs `validate-action.sh` on all `action.yml` files.

## Examples

### Multi-Input Action

```yaml
name: Run security audit
description: Run npm audit with configurable severity

inputs:
  audit-level:
    description: Minimum severity level (low, moderate, high, critical)
    required: false
    default: 'moderate'
  working-directory:
    description: Directory to run audit in
    required: false
    default: '.'

runs:
  using: composite
  steps:
    - name: Run npm audit
      run: npm audit --audit-level=${{ inputs.audit-level }}
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

### Action with Outputs

```yaml
name: Get version
description: Extract version from package.json

outputs:
  version:
    description: Version from package.json
    value: ${{ steps.get-version.outputs.version }}

runs:
  using: composite
  steps:
    - name: Get version
      id: get-version
      run: echo "version=$(jq -r .version package.json)" >> $GITHUB_OUTPUT
      shell: bash
```

### Conditional Steps

```yaml
name: Deploy with optional rollback
description: Deploy and optionally rollback on failure

inputs:
  enable-rollback:
    description: Enable automatic rollback
    required: false
    default: 'true'

runs:
  using: composite
  steps:
    - name: Deploy
      id: deploy
      run: ./deploy.sh
      shell: bash

    - name: Rollback on failure
      if: failure() && inputs.enable-rollback == 'true'
      run: ./rollback.sh
      shell: bash
```

## Resources

- **Project patterns:** @references/composite-action-patterns.md
- **Refactoring guide:** @references/validate-workflow-refactor.md
- **Testing guide:** @references/testing-composite-actions.md
- **GitHub docs:** [Creating composite actions](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action)
- **Related skills:** `/gh-edit-workflow`, `/commit`

## Common Issues

**Issue: "Required property is missing: shell"**
- **Fix:** Add `shell: bash` to every `run:` step

**Issue: "Unable to resolve action"**
- **Fix:** Ensure path is `./.github/actions/{name}` (starts with `./`)

**Issue: "Secrets not available in action"**
- **Fix:** Pass secrets via `env:` in workflow, not as inputs

**Issue: "Action tries to checkout"**
- **Fix:** Remove `actions/checkout@v4` from action, caller handles it
