# Refactoring validate.yml Workflow

> **Reference for:** gh-actions skill
> **Context:** Step-by-step guide to breaking down validate.yml into composite actions

## Current State

The `.github/workflows/validate.yml` workflow is a comprehensive validation pipeline that runs:
- Build steps
- Linting and security audits
- CDK validation
- Tests for multiple modules

Breaking this into composite actions will:
- Reduce duplication with other workflows
- Make individual steps testable
- Improve maintainability
- Enable reuse in deploy workflows

## Recommended Extraction Order

Extract actions in dependency order (foundational → specific):

1. **setup-node** - Node.js + npm cache + dependencies
2. **run-lint** - ESLint checks
3. **run-security-audit** - npm audit for vulnerabilities
4. **build-site** - Build static site + upload artifact
5. **validate-cdk** - CDK synth + cdk-nag + cfn-lint
6. **run-tests** - Module-specific test execution

## Step-by-Step Refactoring

### Step 1: Extract setup-node Action

**Create:** `.github/actions/setup-node/action.yml`

```yaml
name: Setup Node.js
description: Install Node.js and project dependencies

inputs:
  node-version:
    description: Node.js version to install
    required: false
    default: '20'
  working-directory:
    description: Directory containing package.json
    required: false
    default: '.'

runs:
  using: composite
  steps:
    - name: Setup Node.js ${{ inputs.node-version }}
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

**Update validate.yml:**

```yaml
# Before
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci

# After
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
        with:
          node-version: '20'
```

### Step 2: Extract run-lint Action

**Create:** `.github/actions/run-lint/action.yml`

```yaml
name: Run linting
description: Execute ESLint checks

inputs:
  fix:
    description: Automatically fix linting issues
    required: false
    default: 'false'
  working-directory:
    description: Directory to run lint in
    required: false
    default: '.'

runs:
  using: composite
  steps:
    - name: Run ESLint
      run: |
        if [ "${{ inputs.fix }}" = "true" ]; then
          npm run lint:fix
        else
          npm run lint
        fi
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

**Update validate.yml:**

```yaml
jobs:
  lint:
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/run-lint
```

### Step 3: Extract run-security-audit Action

**Create:** `.github/actions/run-security-audit/action.yml`

```yaml
name: Run security audit
description: Execute npm audit for vulnerabilities

inputs:
  audit-level:
    description: Minimum severity level (low, moderate, high, critical)
    required: false
    default: 'moderate'
  working-directory:
    description: Directory to audit
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

**Update validate.yml:**

```yaml
jobs:
  security:
    strategy:
      matrix:
        module:
          - { dir: '.', name: 'root' }
          - { dir: 'infrastructure', name: 'infrastructure' }
          - { dir: 'lambda/auth-edge', name: 'lambda-auth' }
          - { dir: 'lambda/custom-message', name: 'lambda-custom-message' }
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
        with:
          working-directory: ${{ matrix.module.dir }}
      - uses: ./.github/actions/run-security-audit
        with:
          working-directory: ${{ matrix.module.dir }}
```

### Step 4: Extract build-site Action

**Create:** `.github/actions/build-site/action.yml`

```yaml
name: Build site
description: Build static HTML site and upload artifact

inputs:
  artifact-name:
    description: Name for build artifact
    required: false
    default: 'site-build'
  retention-days:
    description: Days to retain artifact
    required: false
    default: '7'

runs:
  using: composite
  steps:
    - name: Build site
      run: npm run build
      shell: bash

    - name: Upload build artifact
      uses: actions/upload-artifact@v4
      with:
        name: ${{ inputs.artifact-name }}
        path: output/
        retention-days: ${{ inputs.retention-days }}
```

**Update validate.yml:**

```yaml
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/build-site
```

### Step 5: Extract validate-cdk Action

**Create:** `.github/actions/validate-cdk/action.yml`

```yaml
name: Validate CDK infrastructure
description: Run CDK synth, cdk-nag, and CloudFormation validation

inputs:
  working-directory:
    description: Directory containing CDK application
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

    - name: Validate CloudFormation templates
      run: |
        for template in cdk.out/*.template.json; do
          if [ -f "$template" ]; then
            echo "Validating: $template"
            npx cfn-lint "$template"
          fi
        done
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

**Update validate.yml:**

```yaml
jobs:
  cdk-validate:
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
        with:
          working-directory: infrastructure
      - uses: ./.github/actions/validate-cdk
        with:
          working-directory: infrastructure
```

### Step 6: Extract run-tests Action

**Create:** `.github/actions/run-tests/action.yml`

```yaml
name: Run tests
description: Execute tests for a specific module

inputs:
  module:
    description: Module to test (src, infrastructure, lambda-auth, lambda-custom-message, lambda-referral)
    required: true
  working-directory:
    description: Base working directory
    required: false
    default: '.'

runs:
  using: composite
  steps:
    - name: Run ${{ inputs.module }} tests
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
          lambda-custom-message)
            cd lambda/custom-message && npm test
            ;;
          lambda-referral)
            cd lambda/referral && npm test
            ;;
          *)
            echo "❌ Unknown module: ${{ inputs.module }}"
            exit 1
            ;;
        esac
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

**Update validate.yml:**

```yaml
jobs:
  test:
    strategy:
      matrix:
        module: [src, infrastructure, lambda-auth, lambda-custom-message, lambda-referral]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/run-tests
        with:
          module: ${{ matrix.module }}
```

## Final validate.yml Structure

After refactoring:

```yaml
name: Validate

on:
  pull_request:
  push:
    branches: [master]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/run-lint

  security:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        module:
          - { dir: '.', name: 'root' }
          - { dir: 'infrastructure', name: 'infrastructure' }
          - { dir: 'lambda/auth-edge', name: 'lambda-auth' }
          - { dir: 'lambda/custom-message', name: 'lambda-custom-message' }
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
        with:
          working-directory: ${{ matrix.module.dir }}
      - uses: ./.github/actions/run-security-audit
        with:
          working-directory: ${{ matrix.module.dir }}

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/build-site

  cdk-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
        with:
          working-directory: infrastructure
      - uses: ./.github/actions/validate-cdk

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        module: [src, infrastructure, lambda-auth, lambda-custom-message, lambda-referral]
    steps:
      - uses: actions/checkout@v4
      - uses: ./.github/actions/setup-node
      - uses: ./.github/actions/run-tests
        with:
          module: ${{ matrix.module }}
```

## Benefits After Refactoring

**Before:**
- ~300+ lines in single file
- Duplication across jobs
- Hard to test individual steps
- Changes require editing large file

**After:**
- ~80 lines in validate.yml
- 6 reusable composite actions
- Each action testable independently
- Changes localized to specific action
- Actions reusable in deploy.yml and other workflows

## Testing Strategy

**After each extraction:**

1. **Syntax check:**
   ```bash
   npx tsx .claude/skills/gh-actions/validate-action.ts .github/actions/{action-name}/action.yml
   ```

2. **Local test:**
   ```bash
   act -j {job-name}  # Using nektos/act
   ```

3. **PR test:**
   - Create branch
   - Commit action + workflow changes
   - Open PR to trigger validate.yml

4. **Verify:**
   - All jobs pass
   - Actions execute correctly
   - No regressions

## Commit Strategy

Use `/gh:commit` skill with issue-based numbering:

```bash
# Extract setup-node
git add .github/actions/setup-node/
git add .github/workflows/validate.yml
/gh:commit
# → AIGCODE-{issue}: Extract setup-node composite action

# Extract run-lint
git add .github/actions/run-lint/
git add .github/workflows/validate.yml
/gh:commit
# → AIGCODE-{issue}a: Extract run-lint composite action

# Continue pattern for remaining actions
```

## Rollback Plan

If issues arise:

1. **Revert specific action:**
   ```bash
   git revert <commit-hash>
   ```

2. **Restore original validate.yml:**
   ```bash
   git checkout HEAD~1 .github/workflows/validate.yml
   ```

3. **Test restored version:**
   ```bash
   git commit -m "Revert action extraction"
   git push
   ```

## Next Steps After validate.yml

Once validate.yml is refactored:

1. **Apply to deploy.yml** - Reuse setup-node, build-site
2. **Create deployment actions** - deploy-to-s3, invalidate-cloudfront
3. **Add environment-specific actions** - deploy-staging, deploy-prod
4. **Document patterns** - Update team playbooks
