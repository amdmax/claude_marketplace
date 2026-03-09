# cdk-nag Suppression Guide

> **Reference for:** cdk-validate skill
> **Context:** How to suppress cdk-nag findings with proper justification

## Overview

Suppressions allow you to acknowledge cdk-nag findings that don't apply to your use case. **Always include a clear reason** explaining why the rule is suppressed.

## When to Suppress

✅ **Valid reasons:**
- AWS service limitations require pattern
- Business requirements override best practice
- Acceptable risk after security review
- False positive due to context

❌ **Invalid reasons:**
- "Too hard to fix"
- "Don't want to deal with it"
- "Doesn't matter for this project"
- No reason provided

## Suppression Types

### 1. Resource-level Suppression

Apply to a specific resource:

```typescript
import { NagSuppressions } from 'cdk-nag';

const lambdaFunction = new Function(this, 'MyFunction', {
  runtime: Runtime.NODEJS_18_X,
  // ...
});

NagSuppressions.addResourceSuppressions(lambdaFunction, [
  {
    id: 'AwsSolutions-L1',
    reason: 'Using Node 18 for compatibility with legacy dependencies requiring Buffer API. Migration to Node 20 planned for Q2 2025.',
  },
]);
```

**Best for:** Individual resource exceptions.

---

### 2. Stack-level Suppression

Apply to all matching resources in a stack:

```typescript
import { NagSuppressions } from 'cdk-nag';
import { Stack } from 'aws-cdk-lib';

export class MyStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    // ... resource definitions

    // Apply suppressions at end of constructor
    NagSuppressions.addStackSuppressions(this, [
      {
        id: 'AwsSolutions-IAM4',
        reason: 'AWS managed policies acceptable for Lambda execution roles in this stack',
      },
    ]);
  }
}
```

**Best for:** Consistent patterns across a stack (e.g., all Lambdas use AWS managed policies).

---

### 3. Project-wide Suppressions

Create centralized suppression file:

**File:** `infrastructure/lib/nag-suppressions.ts`

```typescript
import { NagSuppressions } from 'cdk-nag';
import { Stack } from 'aws-cdk-lib';

export function applyNagSuppressions(stack: Stack) {
  NagSuppressions.addStackSuppressions(stack, [
    {
      id: 'AwsSolutions-IAM4',
      reason: 'AWS managed policies acceptable for Lambda execution roles',
    },
    {
      id: 'AwsSolutions-S1',
      reason: 'S3 access logs disabled for log buckets to prevent infinite recursion',
    },
  ]);
}
```

**Usage in stacks:**

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

**Best for:** Organization-wide standards.

---

## Conditional Suppressions

### Target Specific Actions/Resources

Use `appliesTo` to limit suppression scope:

```typescript
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'CloudWatch Logs requires wildcard for dynamic log stream creation',
    appliesTo: [
      'Resource::*',  // Only suppress wildcard resource
      'Action::logs:CreateLogStream',  // Only for this action
    ],
  },
]);
```

**Why:** Prevents over-suppression (e.g., only allow wildcard for CloudWatch, not DynamoDB).

---

### Suppress by Path

Target specific L2 construct paths:

```typescript
NagSuppressions.addResourceSuppressionsByPath(
  this,
  '/MyStack/MyFunction/ServiceRole/DefaultPolicy/Resource',
  [
    {
      id: 'AwsSolutions-IAM5',
      reason: 'Lambda execution role requires wildcard for log stream creation',
    },
  ]
);
```

**Best for:** Generated resources with predictable paths.

---

## Common Suppression Patterns

### IAM: AWS Managed Policies (AwsSolutions-IAM4)

```typescript
NagSuppressions.addResourceSuppressions(lambdaFunction, [
  {
    id: 'AwsSolutions-IAM4',
    reason: 'AWS managed policy AWSLambdaBasicExecutionRole provides minimal CloudWatch Logs permissions required for Lambda operation',
  },
]);
```

---

### IAM: Wildcard Permissions (AwsSolutions-IAM5)

```typescript
// CloudWatch Logs
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'CloudWatch Logs requires wildcard for dynamic log stream creation. Scoped to specific log group ARN.',
    appliesTo: [
      'Resource::arn:aws:logs:*:*:log-group:/aws/lambda/my-function:*',
    ],
  },
]);

// S3 Batch Operations
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'S3 batch operations require wildcard suffix for object access. Scoped to specific bucket.',
    appliesTo: [
      'Action::s3:*Object',
      'Resource::arn:aws:s3:::my-bucket/*',
    ],
  },
]);
```

---

### S3: Access Logs (AwsSolutions-S1)

```typescript
NagSuppressions.addResourceSuppressions(logBucket, [
  {
    id: 'AwsSolutions-S1',
    reason: 'This is the log bucket itself. Enabling access logs would create infinite recursion.',
  },
]);
```

---

### Lambda: Runtime Version (AwsSolutions-L1)

```typescript
NagSuppressions.addResourceSuppressions(lambdaFunction, [
  {
    id: 'AwsSolutions-L1',
    reason: 'Using Node 18 for compatibility with existing dependencies (sharp, aws-sdk v2). Migration to Node 20 planned for Q2 2025 after dependency updates.',
  },
]);
```

---

### CloudFront: Geo Restrictions (AwsSolutions-CFR1)

```typescript
NagSuppressions.addResourceSuppressions(distribution, [
  {
    id: 'AwsSolutions-CFR1',
    reason: 'Global content delivery required. No data residency restrictions apply to educational course content.',
  },
]);
```

---

## Suppression Review Process

### 1. Quarterly Audit

Review all suppressions every quarter:

```bash
# Find all suppressions
grep -r "NagSuppressions" infrastructure/lib/

# Check if reasons still valid
# - Are dependencies updated?
# - Are AWS service limitations resolved?
# - Are business requirements changed?
```

---

### 2. Document in ADR

For significant suppressions, create Architecture Decision Record:

**File:** `docs/architecture/decisions/0042-suppress-s3-access-logs.md`

```markdown
# 42. Suppress S3 Access Logs for Log Buckets

## Status

Accepted

## Context

cdk-nag rule AwsSolutions-S1 requires S3 access logs on all buckets. However, enabling access logs on the log bucket itself creates infinite recursion.

## Decision

Suppress AwsSolutions-S1 for log buckets with documented reason.

## Consequences

**Positive:**
- Avoids infinite recursion
- Follows AWS best practice pattern

**Negative:**
- No audit trail for log bucket access
- Mitigation: Enable CloudTrail for S3 data events

**Alternatives considered:**
- Separate log bucket for log bucket logs (increases complexity)
- CloudTrail data events (selected)
```

---

### 3. Track Technical Debt

Add suppression removal to backlog when appropriate:

```yaml
# GitHub Issue: "Remove AwsSolutions-L1 suppression after Node 20 migration"
labels: [technical-debt, infrastructure]
milestone: Q2-2025

Description:
Currently suppressing AwsSolutions-L1 for Lambda functions using Node 18.

**Why suppressed:**
Compatibility with legacy dependencies (sharp@0.31.0 requires Node 18)

**Removal criteria:**
- [ ] Update sharp to latest (Node 20 compatible)
- [ ] Update aws-sdk v2 → v3
- [ ] Test all Lambda functions on Node 20
- [ ] Remove suppressions
- [ ] Deploy and verify
```

---

## Anti-Patterns

### ❌ Vague Reasons

```typescript
// ❌ Bad
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'Needed for the app to work',
  },
]);

// ✅ Good
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'CloudWatch Logs requires wildcard for dynamic log stream creation. Scoped to log group /aws/lambda/my-function.',
  },
]);
```

---

### ❌ Over-Suppression

```typescript
// ❌ Bad (suppresses all IAM5 violations)
NagSuppressions.addStackSuppressions(this, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'Wildcards needed',
  },
]);

// ✅ Good (targeted to specific resource and action)
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'CloudWatch Logs requires wildcard for log streams',
    appliesTo: ['Resource::*', 'Action::logs:CreateLogStream'],
  },
]);
```

---

### ❌ No Follow-up Plan

```typescript
// ❌ Bad (no plan to resolve)
NagSuppressions.addResourceSuppressions(fn, [
  {
    id: 'AwsSolutions-L1',
    reason: 'Using old runtime',
  },
]);

// ✅ Good (includes remediation plan)
NagSuppressions.addResourceSuppressions(fn, [
  {
    id: 'AwsSolutions-L1',
    reason: 'Using Node 18 for dependency compatibility. Migration to Node 20 tracked in issue #123, scheduled for Q2 2025.',
  },
]);
```

---

## Verification

### Check Suppressions Applied

```bash
cd infrastructure
npx cdk synth --quiet 2>&1 | grep "AwsSolutions"
# Should NOT show suppressed rules
```

### Count Active Suppressions

```bash
grep -r "NagSuppressions.add" infrastructure/lib/ | wc -l
```

### Find Suppressions Without Reasons

```bash
grep -r "reason: ''" infrastructure/lib/
# Should return nothing
```

---

## Resources

- **cdk-nag Suppressions:** https://github.com/cdklabs/cdk-nag#suppressing-a-rule
- **Example patterns:** @references/cdk-nag-rules.md
- **Project suppressions:** infrastructure/lib/nag-suppressions.ts
