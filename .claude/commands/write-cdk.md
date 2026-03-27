---
description: Review AWS CDK infrastructure code for best practices, Lambda@Edge constraints, and project-specific patterns. Use when reviewing infrastructure/**/*.ts, cdk.json, or *-stack.ts files.
---

# CDK Code Review

## CRITICAL: Review Guidelines

**DO NOT:**
- Try to compile code (LSP diagnostics already checked)
- Generate findings just to produce output
- Report subjective preferences without clear impact
- Duplicate issues already caught by TypeScript compiler

**ONLY REPORT IF:**
- Security vulnerability with concrete attack vector
- Correctness bug with specific failure scenario
- Performance problem with measurable impact
- Architecture violation breaking project patterns
- Missing error handling with real consequence

**REQUIRED FOR EACH FINDING:**
- Specific line numbers
- Concrete impact (what breaks/fails)
- Working code example (for CRITICAL/MAJOR)
- Business/security/reliability consequence

---

You are reviewing AWS CDK infrastructure code for this project. Follow these guidelines to ensure best practices, security, and compliance with project patterns.

## Context

This project uses AWS CDK to manage infrastructure with specific patterns:

- **Import stateful resources** (User Pools, S3 buckets, certificates) via `fromXxxAttributes()`
- **Create stateless resources** (Lambda functions, IAM roles, CloudFront distributions)
- **Lambda@Edge constraints** (no environment variables, must bundle config at build time)
- **Local bundling** to avoid Docker dependency

## Review Process

### 1. Read All Relevant Files

Before providing feedback, read:
- The stack file being reviewed
- Related Lambda code if Lambda@Edge functions are involved
- Reference patterns: `.claude/commands/references/cdk-patterns.md`

### 2. Check Against Project Patterns

Review the code against these key areas:

#### Resource Management
- [ ] Stateful resources imported via `fromXxxAttributes()` (not `fromLookup()`)
- [ ] Stateless resources created with explicit configuration
- [ ] No hardcoded ARNs or IDs (use context, parameters, or outputs)
- [ ] Imported resource limitations handled correctly

#### Lambda@Edge Constraints
- [ ] No environment variables used
- [ ] Config bundled at build time using `local.tryBundle()`
- [ ] Error handling in bundling (try-catch, path verification)
- [ ] Size constraints met (< 1MB for viewer-request/response)

#### IAM & Security
- [ ] Least privilege IAM policies (specific actions, not wildcards)
- [ ] Resource ARNs explicitly defined
- [ ] Source constraints on permissions (sourceArn, sourceAccount)
- [ ] Service principals properly scoped

#### Best Practices
- [ ] Stack outputs defined for important values
- [ ] Comments explain constraints and manual operations
- [ ] Dependencies explicitly declared when order matters
- [ ] Error handling in local bundling with fallback

### 3. Output Findings

**CRITICAL: Use the standardized review output format**

Reference: `.claude/commands/references/review-output-format.md`

All findings MUST include:
- Severity emoji (🔴/🟠/🟡)
- File path with line numbers
- Problem explanation (what, why, impact)
- Fix with code example (REQUIRED for CRITICAL/MAJOR)
- Agent prompt (copy-paste ready, self-contained)
- References to documentation and project patterns

## Common Issues to Check

### 🔴 CRITICAL Issues

1. **Lambda@Edge with environment variables**
   - Lambda@Edge cannot use environment variables at runtime
   - Must bundle config at build time
   - Reference pattern: `cdk-patterns.md` → "Config Bundling Pattern"

2. **Overly permissive IAM policies**
   - Wildcard actions (`s3:*`, `lambda:*`) without resource constraints
   - Missing source ARN conditions for cross-service access
   - Reference pattern: `cdk-patterns.md` → "Least Privilege Policies"

3. **Using `fromLookup()` instead of `fromXxxAttributes()`**
   - Breaks CI/CD pipelines that don't have AWS credentials
   - Use `fromUserPoolId()`, `fromBucketName()`, etc.
   - Exception: Route53 `fromLookup()` is acceptable in this project

4. **Missing error handling in local bundling**
   - Bundling failures should return `false` to fall back to Docker
   - Must verify paths exist before operations
   - Reference pattern: `cdk-patterns.md` → "Local Bundling with Error Handling"

### 🟠 MAJOR Issues

1. **Hardcoded ARNs or resource IDs**
   - Use stack parameters, context, or outputs instead
   - Prevents stack reuse across environments
   - Reference: `cdk-patterns.md` → "No Hardcoded ARNs or IDs"

2. **Missing stack outputs for important values**
   - Stack outputs enable cross-stack references
   - Include descriptions for manual operations
   - Reference pattern: `ai-assisted-coding-stack.ts:278-300`

3. **Command injection in local bundling**
   - Use `fs.copyFileSync()` instead of `cp` commands
   - Validate paths before passing to `execSync()`
   - Reference pattern: `ai-assisted-coding-stack.ts:173-189`

4. **Missing Lambda@Edge config sync warnings**
   - Hardcoded config values can drift from actual resources
   - Add CfnOutput warnings when config must match stack values
   - Reference pattern: `ai-assisted-coding-stack.ts:287-293`

### 🟡 MINOR Issues

1. **Missing comments for constraints**
   - Document Lambda@Edge deletion delays (2-4 hours)
   - Explain manual operations required (CLI commands)
   - Note imported resource limitations

2. **Inconsistent resource naming**
   - Use PascalCase for construct IDs
   - Use descriptive names that explain purpose

3. **Missing descriptions on stack outputs**
   - Outputs should have descriptions for manual steps
   - Include AWS CLI commands when applicable

## Example Review Output

```markdown
## Code Review Findings

### 🔴 CRITICAL: Lambda@Edge uses environment variables

**File:** `infrastructure/lib/auth-stack.ts:86-100`

**Problem:** Lambda@Edge functions do not support environment variables at runtime. This will cause the deployed Lambda to fail when attempting to read `process.env.USER_POOL_ID`. CloudFront will return 502 errors to users.

**Fix:**
```typescript
const authEdgeFunction = new cloudfront.experimental.EdgeFunction(this, 'AuthEdgeFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('../lambda/auth-edge', {
    bundling: {
      image: lambda.Runtime.NODEJS_20_X.bundlingImage,
      command: ['echo', 'This should not run - using local bundling'],
      local: {
        tryBundle(outputDir: string) {
          const { execSync } = require('child_process');
          const fs = require('fs');
          const path = require('path');

          const lambdaDir = path.join(__dirname, '../../lambda/auth-edge');

          // Build Lambda
          execSync('npm install && npm run build', {
            cwd: lambdaDir,
            stdio: 'inherit',
          });

          // Copy bundled output
          const bundledFile = path.join(lambdaDir, 'dist/index.js');
          execSync(`cp ${bundledFile} ${outputDir}/`, { stdio: 'inherit' });

          // Bundle config at build time (replaces environment variables)
          const config = {
            USER_POOL_ID: 'us-east-1_qjoYrEY8I',
            CLIENT_ID: userPoolClient.userPoolClientId,
          };

          fs.writeFileSync(
            path.join(outputDir, 'config.json'),
            JSON.stringify(config)
          );

          return true;
        },
      },
    },
  }),
  // ❌ REMOVE THIS - Lambda@Edge doesn't support environment variables
  // environment: {
  //   USER_POOL_ID: userPool.userPoolId,
  // },
});
```

**Agent Prompt:**
```
Remove the environment property from the Lambda@Edge function definition in infrastructure/lib/auth-stack.ts lines 86-100. Instead, bundle configuration as a JSON file during the CDK build process using the local.tryBundle() pattern. Reference the existing implementation in infrastructure/lib/ai-assisted-coding-stack.ts lines 94-130 which correctly bundles config for Lambda@Edge. The bundled config.json should contain USER_POOL_ID and CLIENT_ID values.
```

**References:**
- [AWS Lambda@Edge Restrictions](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-requirements-limits.html#lambda-requirements-lambda-function-configuration)
- Project pattern: `.claude/commands/references/cdk-patterns.md` → "Config Bundling Pattern"
- Example: `infrastructure/lib/ai-assisted-coding-stack.ts:86-136`

---

### 🟠 MAJOR: IAM policy uses wildcard permissions

**File:** `infrastructure/lib/payment-stack.ts:45-52`

**Problem:** The IAM policy grants `s3:*` on all resources (`*`), violating the principle of least privilege. This allows the Lambda to delete buckets, modify ACLs, and perform other dangerous operations it doesn't need.

**Fix:**
```typescript
// Grant specific permissions on specific resources
paymentFunction.addToRolePolicy(new iam.PolicyStatement({
  actions: [
    's3:GetObject',
    's3:PutObject',
  ],
  resources: [
    `${receiptsBucket.bucketArn}/receipts/*`,
  ],
}));
```

**Agent Prompt:**
```
Replace the wildcard IAM policy in infrastructure/lib/payment-stack.ts lines 45-52 with specific permissions. Grant only s3:GetObject and s3:PutObject actions. Scope the resource to the specific bucket and path prefix: ${receiptsBucket.bucketArn}/receipts/*. Remove the wildcard actions and resources.
```

**References:**
- [IAM Policy Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#grant-least-privilege)
- Project pattern: `.claude/commands/references/cdk-patterns.md` → "Least Privilege Policies"
```

## Tone and Style

- Be specific and technical
- Focus on impact and consequences
- Provide complete, working code examples
- Reference project patterns and external documentation
- Use constructive language ("consider", "should", "recommend")
- Explain the "why" behind each finding

## Deliverable

Your review output must:

1. Follow the standardized format exactly (emoji, structure, required sections)
2. Include agent prompts that are self-contained and actionable
3. Reference specific line numbers in files
4. Provide working code examples for CRITICAL and MAJOR issues
5. Link to relevant documentation and project patterns
6. Prioritize findings by severity (🔴 → 🟠 → 🟡)

Begin your review by reading the relevant files, then output your findings in the standardized format.
