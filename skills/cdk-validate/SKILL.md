---
name: cdk-validate
description: Validate AWS CDK infrastructure with cdk-nag and cfn-lint
tags: [infrastructure, aws, cdk, validation, security]
hooks:
  PostToolUse:
    - matcher: Edit|Write
      command: $SKILL_DIR/validate-cdk-output.sh
---

# CDK Infrastructure Validator

Validates AWS CDK infrastructure using **cdk-nag** (AWS best practices) and **cfn-lint** (CloudFormation syntax). Runs automatically after infrastructure/ edits via PostToolUse hook.

## Overview

**What it validates:**
- ✅ **cdk-nag**: AWS Solutions best practices, security, IAM least privilege
- ✅ **cfn-lint**: CloudFormation syntax, resource properties
- ✅ **Blocking mode**: Errors block operations, warnings allowed

**Key features:**
- Auto-installs cdk-nag if missing
- Graceful degradation when tools unavailable
- Integrated with `/code-review` Phase 1
- Fast feedback (<60s)

## Usage

### Automatic (PostToolUse Hook)

Hook triggers automatically after editing `infrastructure/**/*.ts` files:

```typescript
// Edit any infrastructure file
// infrastructure/lib/admin-stack.ts
```

**Result:**
```
🔍 Validating CDK infrastructure...
  Running cdk-nag checks...
  ✅ cdk-nag checks passed
  Running cfn-lint...
  ✅ cfn-lint checks passed
✅ CDK validation passed
```

### Manual Invocation

```bash
/cdk-validate
```

**When to use:**
- Pre-commit validation
- After multiple infrastructure edits
- Before creating PR
- When debugging validation failures

## Installation

### cdk-nag (Auto-installed)

The skill automatically installs cdk-nag if missing and `auto_install_cdk_nag: true` in config.yaml.

**Manual installation:**
```bash
cd infrastructure
npm install --save-dev cdk-nag
```

### cfn-lint (Manual)

**macOS:**
```bash
brew install cfn-lint
```

**Linux/pip:**
```bash
pip install cfn-lint
```

**Verify:**
```bash
cfn-lint --version
```

## Configuration

Located at `.claude/skills/cdk-validate/config.yaml`:

```yaml
tools:
  cdk_nag:
    enabled: true
    verbose: false  # Set true for detailed output
  cfn_lint:
    enabled: true
    ignore_rules: []  # Add rule IDs to ignore

behavior:
  blocking: true                  # Block on errors
  blocking_on_errors: true        # Fail fast
  blocking_on_warnings: false     # Allow warnings
  timeout: 60                     # Max validation time (seconds)

files:
  watch_dirs: ["infrastructure/"]
  exclude_patterns: ["*.md", "*.json", "cdk.out/", "node_modules/"]

installation:
  auto_install_cdk_nag: true      # Auto-install if missing
  graceful_degradation: true       # Continue if tools unavailable
```

**Customize:**
```bash
# Disable cfn-lint
yq e '.tools.cfn_lint.enabled = false' -i .claude/skills/cdk-validate/config.yaml

# Add ignored rules
yq e '.tools.cfn_lint.ignore_rules += ["E3001"]' -i .claude/skills/cdk-validate/config.yaml

# Disable blocking
yq e '.behavior.blocking = false' -i .claude/skills/cdk-validate/config.yaml
```

## Validation Output

### Success (No Issues)

```
🔍 Validating CDK infrastructure...
  Running cdk-nag checks...
  ✅ cdk-nag checks passed
  Running cfn-lint...
  ✅ cfn-lint checks passed
✅ CDK validation passed
```

### Warnings Only (Non-blocking)

```
🔍 Validating CDK infrastructure...
  Running cdk-nag checks...
  ⚠️  cdk-nag warnings:
    [Warning] AwsSolutions-S3: The S3 Bucket has server access logs disabled.
    File: infrastructure/lib/admin-stack.ts
  Running cfn-lint...
  ✅ cfn-lint checks passed
⚠️  CDK validation completed with warnings (non-blocking)
💡 Tip: See .claude/skills/cdk-validate/references/suppression-guide.md to suppress warnings
```

### Errors (Blocking)

```
🔍 Validating CDK infrastructure...
  Running cdk-nag checks...
  ❌ cdk-nag errors found:
    [Error] AwsSolutions-IAM5: IAM policy should not allow wildcard permissions
    File: infrastructure/lib/referral-stack.ts
    Resource: ReferralTableAccessRole
    Line: 42
  Running cfn-lint...
  ✅ cfn-lint checks passed
❌ CDK validation failed
Run 'cd infrastructure && npx cdk synth' for details

⚠️  Blocking mode enabled - fix errors before proceeding
```

**Exit code:** 2 (blocks operation)

## Integration with code-review

CDK validation automatically runs as part of `/code-review` Phase 1:

```bash
/code-review

Phase 1: Deterministic Checks
==============================
✅ TypeScript type-check... PASSED
✅ ESLint... PASSED
✅ Stylelint... PASSED
✅ Tests... PASSED
🔍 CDK Infrastructure... CHECKING
  ❌ cdk-nag errors found (IAM wildcard permissions)
❌ CDK Infrastructure... FAILED

❌ Phase 1 Failed
⚠️ Fix CDK validation errors before proceeding.
Phase 2 reviews skipped to save LLM tokens.
```

**Conditional:** Only runs if staged changes include `infrastructure/` files.

## Common Findings

### AwsSolutions-IAM4: AWS Managed Policies

**Finding:**
```
[Warning] AwsSolutions-IAM4: IAM policy uses AWS managed policies
```

**Fix:** Acceptable for Lambda execution roles. Suppress if justified:

```typescript
NagSuppressions.addResourceSuppressions(lambdaFunction, [
  {
    id: 'AwsSolutions-IAM4',
    reason: 'AWS managed policies acceptable for Lambda execution roles',
  },
]);
```

### AwsSolutions-IAM5: Wildcard Permissions

**Finding:**
```
[Error] AwsSolutions-IAM5: IAM policy should not allow wildcard permissions
```

**Fix:** Use specific resource ARNs:

```typescript
// ❌ Bad
role.addToPolicy(new PolicyStatement({
  actions: ['dynamodb:*'],
  resources: ['*'],
}));

// ✅ Good
role.addToPolicy(new PolicyStatement({
  actions: ['dynamodb:GetItem', 'dynamodb:PutItem'],
  resources: [table.tableArn],
}));
```

### AwsSolutions-S3: S3 Access Logs Disabled

**Finding:**
```
[Warning] AwsSolutions-S3: The S3 Bucket has server access logs disabled.
```

**Fix:** Enable access logging or suppress if unnecessary:

```typescript
const bucket = new Bucket(this, 'MyBucket', {
  serverAccessLogsBucket: logBucket,
  serverAccessLogsPrefix: 'access-logs/',
});
```

See @references/cdk-nag-rules.md for complete rule catalog.

## Suppressing Findings

### Project-wide Suppressions

Create `infrastructure/lib/nag-suppressions.ts`:

```typescript
import { NagSuppressions } from 'cdk-nag';
import { Stack } from 'aws-cdk-lib';

export function applyNagSuppressions(stack: Stack) {
  NagSuppressions.addStackSuppressions(stack, [
    {
      id: 'AwsSolutions-IAM4',
      reason: 'AWS managed policies acceptable for Lambda execution roles',
    },
  ]);
}
```

Call in stack constructor:

```typescript
import { applyNagSuppressions } from './nag-suppressions';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // ... resource definitions

    applyNagSuppressions(this);
  }
}
```

### Resource-specific Suppressions

```typescript
import { NagSuppressions } from 'cdk-nag';

const lambdaFunction = new Function(this, 'MyFunction', {
  // ...
});

NagSuppressions.addResourceSuppressions(lambdaFunction, [
  {
    id: 'AwsSolutions-L1',
    reason: 'Using Node 18 for compatibility with existing dependencies',
  },
]);
```

See @references/suppression-guide.md for detailed patterns.

## Error Handling

### Error: cdk-nag not installed

**If auto_install_cdk_nag: true:**
```
📦 Installing cdk-nag...
✅ cdk-nag installed successfully
```

**If auto_install_cdk_nag: false:**
```
⚠️  cdk-nag not installed
💡 Install: cd infrastructure && npm install --save-dev cdk-nag
⚠️  Skipping cdk-nag validation
```

### Error: cfn-lint not installed

```
⚠️  cfn-lint not installed
💡 Install: brew install cfn-lint (macOS) or pip install cfn-lint
⚠️  Skipping cfn-lint validation
```

Validation continues with available tools (graceful degradation).

### Error: cdk synth fails

```
❌ CDK synth failed:
  Error: Cannot find module 'aws-cdk-lib'
  at MyStack (infrastructure/lib/my-stack.ts:5:1)

❌ CDK validation failed
Fix synth errors before proceeding
```

**Exit code:** 2 (blocks operation)

### Error: Validation timeout (>60s)

```
⚠️  Validation timeout (60s exceeded)
⚠️  Skipping validation to prevent disruption
💡 Run 'cd infrastructure && npx cdk synth' manually
```

**Exit code:** 0 (doesn't block)

## File Filtering

Hook only runs on relevant files:

**Watched:**
- `infrastructure/**/*.ts` (stack definitions)
- `infrastructure/bin/app.ts` (CDK app)
- `infrastructure/lib/*.ts` (constructs)

**Excluded:**
- `infrastructure/*.md` (documentation)
- `infrastructure/*.json` (config files)
- `infrastructure/cdk.out/` (generated CloudFormation)
- `infrastructure/node_modules/` (dependencies)

**Other directories:**
- `content/`, `src/`, `lambda/` → Validation skipped

## Verification

### Check cdk-nag Integration

```bash
cd infrastructure
npx cdk synth --quiet
# Should show cdk-nag findings
```

### Check Hook Registration

```bash
grep -A 5 "PostToolUse" .claude/skills/cdk-validate/SKILL.md
# Should show hook configuration
```

### Test Auto-install

```bash
cd infrastructure
rm -rf node_modules/cdk-nag  # Remove if exists
# Edit infrastructure file
# Check if cdk-nag auto-installs
npm list cdk-nag
```

### Test Blocking Behavior

```bash
# Edit file with IAM wildcard (known error)
# Expect: Operation blocked with exit code 2
echo $?  # Should be 2
```

## Troubleshooting

### "Module 'cdk-nag' not found"

```bash
cd infrastructure
npm install --save-dev cdk-nag
```

### "actionlint: command not found" (irrelevant)

This skill validates CDK, not GitHub workflows. Ignore actionlint warnings.

### "cdk synth hangs"

Check timeout in config.yaml. Default is 60s.

### "Too many false positives"

Add suppressions to `nag-suppressions.ts` or adjust rules in config.yaml.

## Performance

- **Typical validation time:** 10-20s
- **Timeout protection:** 60s max
- **File filtering:** Avoids unnecessary validation
- **Token efficiency:** Integrated with code-review Phase 1

## Best Practices

1. **Run before commit** - Catch issues early
2. **Fix errors immediately** - Don't accumulate technical debt
3. **Suppress with reason** - Document why rules don't apply
4. **Review warnings** - Address or suppress with justification
5. **Keep cdk-nag updated** - `npm update cdk-nag`

## References

- **cdk-nag rules:** @references/cdk-nag-rules.md
- **cfn-lint rules:** @references/cfn-lint-rules.md
- **Suppression patterns:** @references/suppression-guide.md

## Related Skills

- `/code-review` - Comprehensive code review (includes CDK validation)
- `/gh:edit-workflow` - GitHub Actions workflow validation
- `/write-cdk` - CDK code review with best practices

---

**Estimated validation time:** 10-20s
**Token savings:** Prevents broken infrastructure from reaching LLM review
**Integration:** Automatic via PostToolUse hook + code-review Phase 1
