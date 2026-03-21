# cdk-nag Rules Reference

> **Reference for:** cdk-validate skill
> **Context:** AWS Solutions best practices validation

## Overview

cdk-nag implements **AWS Solutions** best practices for CDK infrastructure. Rules are organized by AWS service and security concern.

**Rule format:** `AwsSolutions-{ServiceCode}{Number}`

**Severity levels:**
- **Error**: Must fix (security/compliance risk)
- **Warning**: Should fix (best practice recommendation)

## Common Rules

### IAM (Identity and Access Management)

#### AwsSolutions-IAM4: AWS Managed Policies

**Severity:** Warning

**Description:** IAM policy uses AWS managed policies instead of custom policies.

**Why it matters:** AWS managed policies may grant broader permissions than needed.

**When acceptable:**
- Lambda execution roles (AWSLambdaBasicExecutionRole)
- Service-linked roles

**Fix:**
```typescript
// If acceptable, suppress:
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM4',
    reason: 'AWS managed policies acceptable for Lambda execution roles',
  },
]);
```

**References:**
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

---

#### AwsSolutions-IAM5: Wildcard Permissions

**Severity:** Error

**Description:** IAM policy grants wildcard (`*`) permissions on actions or resources.

**Why it matters:** Violates least privilege principle, increases blast radius of compromised credentials.

**Fix:**
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

**Acceptable exceptions:**
- CloudWatch Logs (requires wildcard for log stream creation)
- S3 batch operations (specific actions only)

**Suppression (if justified):**
```typescript
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'CloudWatch Logs requires wildcard for dynamic log stream creation',
    appliesTo: ['Resource::*'],
  },
]);
```

**References:**
- [Least Privilege Principle](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)

---

### S3 (Simple Storage Service)

#### AwsSolutions-S1: S3 Access Logs Disabled

**Severity:** Warning

**Description:** S3 bucket does not have server access logging enabled.

**Why it matters:** No audit trail of bucket access for security investigations.

**Fix:**
```typescript
const logBucket = new Bucket(this, 'LogBucket', {
  // ... config
});

const bucket = new Bucket(this, 'MyBucket', {
  serverAccessLogsBucket: logBucket,
  serverAccessLogsPrefix: 'access-logs/',
});
```

**When to suppress:**
- Log buckets themselves (prevent infinite loop)
- Development/test buckets

---

#### AwsSolutions-S2: Public Read Access Blocked

**Severity:** Error

**Description:** S3 bucket allows public read access.

**Why it matters:** Data exposure risk, compliance violations.

**Fix:**
```typescript
const bucket = new Bucket(this, 'MyBucket', {
  publicReadAccess: false,
  blockPublicAccess: BlockPublicAccess.BLOCK_ALL,
});
```

---

### Lambda

#### AwsSolutions-L1: Lambda Runtime Version

**Severity:** Warning

**Description:** Lambda function uses non-latest runtime version.

**Why it matters:** Missing security patches, deprecated features.

**Fix:**
```typescript
// ✅ Good
const fn = new Function(this, 'MyFunction', {
  runtime: Runtime.NODEJS_20_X, // Latest
  // ...
});
```

**When to suppress:**
- Compatibility with existing dependencies
- Planned migration in progress

```typescript
NagSuppressions.addResourceSuppressions(fn, [
  {
    id: 'AwsSolutions-L1',
    reason: 'Using Node 18 for compatibility with legacy dependencies. Migration to Node 20 planned for Q2 2025.',
  },
]);
```

---

### CloudFront

#### AwsSolutions-CFR1: Geo Restrictions

**Severity:** Warning

**Description:** CloudFront distribution does not use geo restrictions.

**Why it matters:** May violate data residency requirements.

**When to suppress:**
- Global content delivery required
- No data residency restrictions

---

#### AwsSolutions-CFR4: Default Viewer Certificate

**Severity:** Error

**Description:** CloudFront distribution uses default viewer certificate instead of custom TLS certificate.

**Why it matters:** Cannot use custom domain, lacks control over TLS settings.

**Fix:**
```typescript
const distribution = new Distribution(this, 'MyDist', {
  certificate: cert,
  domainNames: ['example.com'],
  // ...
});
```

---

### DynamoDB

#### AwsSolutions-DDB3: Point-in-Time Recovery Disabled

**Severity:** Warning

**Description:** DynamoDB table does not have point-in-time recovery enabled.

**Why it matters:** No protection against accidental deletes/updates.

**Fix:**
```typescript
const table = new Table(this, 'MyTable', {
  pointInTimeRecovery: true,
  // ...
});
```

**When to suppress:**
- Development/test tables
- Ephemeral data

---

## Suppression Patterns

### Stack-level Suppressions

Apply to all resources in a stack:

```typescript
import { NagSuppressions } from 'cdk-nag';

NagSuppressions.addStackSuppressions(this, [
  {
    id: 'AwsSolutions-IAM4',
    reason: 'AWS managed policies acceptable for Lambda execution roles',
  },
]);
```

### Resource-level Suppressions

Apply to specific resource:

```typescript
NagSuppressions.addResourceSuppressions(myResource, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'CloudWatch Logs requires wildcard for log stream creation',
    appliesTo: ['Resource::*'],
  },
]);
```

### Conditional Suppressions

Target specific property paths:

```typescript
NagSuppressions.addResourceSuppressions(role, [
  {
    id: 'AwsSolutions-IAM5',
    reason: 'S3 batch operations require wildcard suffix',
    appliesTo: [
      'Action::s3:*Object*',
      'Resource::arn:aws:s3:::my-bucket/*',
    ],
  },
]);
```

---

## Verification

### Check cdk-nag Findings

```bash
cd infrastructure
npx cdk synth --quiet 2>&1 | grep "\[Error\]\|\[Warning\]"
```

### Count Findings by Severity

```bash
# Errors
npx cdk synth --quiet 2>&1 | grep -c "\[Error\]"

# Warnings
npx cdk synth --quiet 2>&1 | grep -c "\[Warning\]"
```

### List Suppressed Rules

```bash
grep -r "NagSuppressions" infrastructure/lib/
```

---

## Best Practices

1. **Fix errors immediately** - Security risks
2. **Review warnings** - Address or suppress with reason
3. **Document suppressions** - Explain why rule doesn't apply
4. **Regular audits** - Review suppressions quarterly
5. **Keep updated** - `npm update cdk-nag`

---

## Resources

- **cdk-nag GitHub:** https://github.com/cdklabs/cdk-nag
- **AWS Solutions Rules:** https://github.com/cdklabs/cdk-nag/blob/main/RULES.md
- **AWS Security Best Practices:** https://aws.amazon.com/architecture/security-identity-compliance/
