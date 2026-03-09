# Composite Action Patterns

> **Reference for:** gh-actions skill
> **Context:** Common patterns for creating reusable composite actions

## Setup Patterns

### Basic Node.js Setup

```yaml
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

### Node.js with Working Directory

```yaml
name: Setup Node.js with working directory
description: Install Node.js and dependencies in specific directory

inputs:
  node-version:
    description: Node.js version
    required: false
    default: '20'
  working-directory:
    description: Directory containing package.json
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

### Multi-Runtime Setup

```yaml
name: Setup Node.js and Python
description: Install both Node.js and Python with caching

inputs:
  node-version:
    description: Node.js version
    required: false
    default: '20'
  python-version:
    description: Python version
    required: false
    default: '3.11'

runs:
  using: composite
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: ${{ inputs.python-version }}
        cache: 'pip'

    - name: Install Node dependencies
      run: npm ci
      shell: bash

    - name: Install Python dependencies
      run: pip install -r requirements.txt
      shell: bash
```

## Build Patterns

### Build with Artifact Upload

```yaml
name: Build and upload artifact
description: Build project and upload output as artifact

inputs:
  artifact-name:
    description: Name for build artifact
    required: false
    default: 'build-output'
  artifact-path:
    description: Path to upload
    required: false
    default: 'output/'
  retention-days:
    description: Days to retain artifact
    required: false
    default: '7'

runs:
  using: composite
  steps:
    - name: Build
      run: npm run build
      shell: bash

    - name: Upload artifact
      uses: actions/upload-artifact@v4
      with:
        name: ${{ inputs.artifact-name }}
        path: ${{ inputs.artifact-path }}
        retention-days: ${{ inputs.retention-days }}
```

### Build with Caching

```yaml
name: Build with cache
description: Build project with build output caching

inputs:
  cache-key:
    description: Cache key for build outputs
    required: false
    default: 'build-cache'

runs:
  using: composite
  steps:
    - name: Restore build cache
      uses: actions/cache@v4
      with:
        path: |
          output/
          .cache/
        key: ${{ inputs.cache-key }}-${{ hashFiles('src/**/*') }}
        restore-keys: |
          ${{ inputs.cache-key }}-

    - name: Build
      run: npm run build
      shell: bash
```

### Conditional Build (Changed Files)

```yaml
name: Conditional build
description: Only build if source files changed

outputs:
  built:
    description: Whether build was executed
    value: ${{ steps.check.outputs.changed }}

runs:
  using: composite
  steps:
    - name: Check for changes
      id: check
      run: |
        if git diff --quiet HEAD^ HEAD -- src/; then
          echo "changed=false" >> $GITHUB_OUTPUT
        else
          echo "changed=true" >> $GITHUB_OUTPUT
        fi
      shell: bash

    - name: Build
      if: steps.check.outputs.changed == 'true'
      run: npm run build
      shell: bash
```

## Test Patterns

### Module-Based Testing

```yaml
name: Run module tests
description: Run tests for specific module

inputs:
  module:
    description: Module to test (src, infrastructure, lambda)
    required: true
  working-directory:
    description: Working directory
    required: false
    default: '.'

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
          lambda-custom-message)
            cd lambda/custom-message && npm test
            ;;
          *)
            echo "Unknown module: ${{ inputs.module }}"
            exit 1
            ;;
        esac
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

### Tests with Coverage

```yaml
name: Run tests with coverage
description: Execute tests and upload coverage report

inputs:
  coverage-name:
    description: Name for coverage artifact
    required: false
    default: 'coverage'

outputs:
  coverage-percent:
    description: Test coverage percentage
    value: ${{ steps.coverage.outputs.percent }}

runs:
  using: composite
  steps:
    - name: Run tests
      run: npm run test:coverage
      shell: bash

    - name: Extract coverage
      id: coverage
      run: |
        PERCENT=$(jq -r '.total.lines.pct' coverage/coverage-summary.json)
        echo "percent=$PERCENT" >> $GITHUB_OUTPUT
      shell: bash

    - name: Upload coverage
      uses: actions/upload-artifact@v4
      with:
        name: ${{ inputs.coverage-name }}
        path: coverage/
```

### Conditional Testing (Only on PR)

```yaml
name: PR tests
description: Run comprehensive tests only on pull requests

runs:
  using: composite
  steps:
    - name: Run quick tests
      if: github.event_name != 'pull_request'
      run: npm run test:quick
      shell: bash

    - name: Run full test suite
      if: github.event_name == 'pull_request'
      run: npm run test:all
      shell: bash
```

## Validation Patterns

### CDK Validation

```yaml
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

    - name: Validate CloudFormation
      run: |
        for template in cdk.out/*.template.json; do
          cfn-lint "$template"
        done
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

### Security Audit

```yaml
name: Security audit
description: Run npm audit with configurable severity

inputs:
  audit-level:
    description: Minimum severity (low, moderate, high, critical)
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

    - name: Check for known vulnerabilities
      run: npx audit-ci --${{ inputs.audit-level }}
      shell: bash
      working-directory: ${{ inputs.working-directory }}
```

### Lint and Format Check

```yaml
name: Lint and format check
description: Run ESLint and Prettier checks

inputs:
  fix:
    description: Auto-fix issues
    required: false
    default: 'false'

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

    - name: Check formatting
      run: |
        if [ "${{ inputs.fix }}" = "true" ]; then
          npm run format
        else
          npm run format:check
        fi
      shell: bash
```

## Input/Output Patterns

### Action with Outputs

```yaml
name: Get package version
description: Extract version from package.json

outputs:
  version:
    description: Version from package.json
    value: ${{ steps.get-version.outputs.version }}
  major:
    description: Major version number
    value: ${{ steps.parse-version.outputs.major }}

runs:
  using: composite
  steps:
    - name: Get version
      id: get-version
      run: echo "version=$(jq -r .version package.json)" >> $GITHUB_OUTPUT
      shell: bash

    - name: Parse version
      id: parse-version
      run: |
        VERSION="${{ steps.get-version.outputs.version }}"
        echo "major=${VERSION%%.*}" >> $GITHUB_OUTPUT
      shell: bash
```

### Secrets via Environment

```yaml
name: Deploy with secrets
description: Deploy application using secrets

# NOTE: Secrets must be passed via env, not inputs
# Workflow usage:
#   - uses: ./.github/actions/deploy
#     env:
#       API_KEY: ${{ secrets.API_KEY }}
#       DB_PASSWORD: ${{ secrets.DB_PASSWORD }}

runs:
  using: composite
  steps:
    - name: Deploy
      run: ./deploy.sh
      shell: bash
      env:
        API_KEY: ${{ env.API_KEY }}
        DB_PASSWORD: ${{ env.DB_PASSWORD }}
```

### Boolean Inputs

```yaml
name: Deploy with options
description: Deploy with configurable options

inputs:
  enable-rollback:
    description: Enable automatic rollback on failure
    required: false
    default: 'true'
  dry-run:
    description: Perform dry run only
    required: false
    default: 'false'

runs:
  using: composite
  steps:
    - name: Deploy
      if: inputs.dry-run != 'true'
      run: ./deploy.sh
      shell: bash

    - name: Dry run
      if: inputs.dry-run == 'true'
      run: ./deploy.sh --dry-run
      shell: bash

    - name: Rollback on failure
      if: failure() && inputs.enable-rollback == 'true'
      run: ./rollback.sh
      shell: bash
```

## Anti-Patterns

### ❌ Checkout in Composite Action

```yaml
# DON'T DO THIS
runs:
  using: composite
  steps:
    - uses: actions/checkout@v4  # ❌ Caller's responsibility
    - run: npm test
      shell: bash
```

### ❌ Secrets as Inputs

```yaml
# DON'T DO THIS
inputs:
  api-key:  # ❌ Use env vars instead
    description: API key for deployment
    required: true
```

### ❌ Missing Shell

```yaml
# DON'T DO THIS
runs:
  using: composite
  steps:
    - run: npm test  # ❌ Missing shell: bash
```

### ❌ Hardcoded Paths

```yaml
# DON'T DO THIS
runs:
  using: composite
  steps:
    - run: cd /home/runner/work/my-project && npm test  # ❌ Use working-directory input
      shell: bash
```

## Best Practices

✅ **Always specify shell** - Required for composite actions
✅ **Use working-directory input** - Make actions flexible
✅ **Pass secrets via env** - Inputs don't support secrets
✅ **Document all inputs** - Include descriptions
✅ **Use meaningful output names** - Clear and descriptive
✅ **Handle errors gracefully** - Check exit codes
✅ **Test in isolation** - Ensure action works standalone
✅ **Version external actions** - Pin to specific versions (e.g., @v4)
