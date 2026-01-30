---
name: cdk-scripting
description: Guide for writing AWS CDK infrastructure code following best practices for resource management, stateful/stateless patterns, and dynamic references. Helps scaffold CDK stacks with proper import/create patterns. Invokable with /cdk-scripting or /cdk.
---

# CDK Scripting Assistant

## Overview

This skill guides you through writing AWS CDK TypeScript infrastructure code following best practices for resource management, security validation, testing, and the critical distinction between stateful resources (import) and stateless resources (create).

## Workflow

### 1. Understand Requirements

When the user asks to create or modify CDK infrastructure, first clarify:

```bash
# Questions to ask:
- What AWS resources are needed?
- Which resources already exist in AWS?
- Which resources need to be created new?
- What are the dependencies between resources?
- Are there any dynamic lookups needed?
```

**Gather context:**
- Existing CDK stack files in `infrastructure/lib/`
- Current AWS resource IDs (User Pool IDs, Bucket names, etc.)
- SSM parameters if used for configuration

### 2. Classify Resources

For each resource, determine if it's **stateful** or **stateless**:

#### Stateful Resources (IMPORT - Never Recreate)
Resources that contain data or state that must persist:

- **Cognito User Pools** - Contains user accounts
- **S3 Buckets** - Contains files/data
- **RDS Databases** - Contains application data
- **DynamoDB Tables** - Contains records
- **VPCs** - Networking infrastructure
- **Certificates** - SSL/TLS certificates

**Action:** Import using `.fromXxxId()`, `.fromXxxArn()`, or `.fromXxxName()`

```typescript
// Example: Import existing User Pool
const userPool = cognito.UserPool.fromUserPoolId(
  this,
  'ImportedUserPool',
  'us-east-1_ABC123DEF'
);
```

#### Stateless Resources (CREATE - Recreate as Needed)
Resources that can be safely recreated without data loss:

- **Lambda Functions** - Code is in git
- **IAM Roles/Policies** - Configuration as code
- **CloudFront Distributions** - Configuration only
- **Cognito User Pool Clients** - Configuration only
- **Cognito Domains** - Configuration only
- **API Gateways** - Configuration only
- **Lambda@Edge Functions** - Code is in git

**Action:** Create using `new Resource()`

```typescript
// Example: Create new User Pool Client
const client = new cognito.UserPoolClient(this, 'WebClient', {
  userPool: userPool, // Reference imported pool
  authFlows: {
    userPassword: true,
    userSrp: true,
  },
});
```

### 3. Apply Resource Management Pattern

Follow the **"Import Parent, Create Children"** pattern:

#### Pattern: Import Stateful Parent → Create Stateless Children

```typescript
// 1. Import stateful parent resource
const userPool = cognito.UserPool.fromUserPoolId(
  this,
  'UserPool',
  'us-east-1_ABC123'
);

// 2. Create stateless children that reference parent
const client = new cognito.UserPoolClient(this, 'Client', {
  userPool: userPool,
  generateSecret: false,
});

const domain = userPool.addDomain('Domain', {
  cognitoDomain: {
    domainPrefix: 'my-app-auth',
  },
});

// 3. Reference properties dynamically (like Terraform)
const lambda = new lambda.Function(this, 'AuthFunction', {
  // ... other props
  environment: {
    USER_POOL_ID: userPool.userPoolId,        // ✅ Auto-updates
    CLIENT_ID: client.userPoolClientId,       // ✅ Auto-updates
    COGNITO_DOMAIN: domain.domainName,        // ✅ Auto-updates
  },
});
```

### 4. Handle Dynamic References

#### Option A: Direct Properties (Preferred)

For resources created in CDK, reference properties directly:

```typescript
const bucket = new s3.Bucket(this, 'AssetsBucket');
const lambda = new lambda.Function(this, 'Processor', {
  environment: {
    BUCKET_NAME: bucket.bucketName,  // ✅ Dynamic reference
  },
});
```

#### Option B: SSM Parameter Store

For configuration that changes between environments:

```typescript
// First, store in SSM:
// aws ssm put-parameter --name /app/user-pool-id --value us-east-1_ABC123

// Then, lookup in CDK:
const poolId = ssm.StringParameter.valueFromLookup(
  this,
  '/app/user-pool-id'
);

const userPool = cognito.UserPool.fromUserPoolId(
  this,
  'UserPool',
  poolId
);
```

**When to use SSM:**
- Different values per environment (dev/staging/prod)
- Values that change independently of CDK deployments
- Sensitive configuration (with SecureString)

#### Option C: Custom Resource (Complex Lookups)

For AWS API calls during synthesis:

```typescript
const lookup = new cr.AwsCustomResource(this, 'ClientLookup', {
  onUpdate: {
    service: 'CognitoIdentityServiceProvider',
    action: 'listUserPoolClients',
    parameters: {
      UserPoolId: userPool.userPoolId,
      MaxResults: 1,
    },
    physicalResourceId: cr.PhysicalResourceId.of(Date.now().toString()),
  },
  policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
    resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE,
  }),
});

const clientId = lookup.getResponseField('UserPoolClients.0.ClientId');
```

**When to use Custom Resources:**
- Need to call AWS APIs during deployment
- Information not available via standard CDK constructs
- Dynamic discovery of resource properties

### 5. Lambda@Edge Critical Pattern

**CRITICAL:** Lambda@Edge **DOES NOT** support environment variables.

#### Build-Time Config Injection (Recommended)

```typescript
const authEdgeFunction = new cloudfront.experimental.EdgeFunction(this, 'AuthEdgeFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('../lambda/auth-edge', {
    assetHashType: cdk.AssetHashType.OUTPUT,  // Hash based on output
    bundling: {
      image: lambda.Runtime.NODEJS_20_X.bundlingImage,
      command: ['echo', 'This should not run - using local bundling'],
      local: {
        tryBundle(outputDir: string) {
          const { execSync } = require('child_process');
          const path = require('path');
          const fs = require('fs');

          const lambdaDir = path.join(__dirname, '../../lambda/auth-edge');

          // Build with esbuild
          execSync('npm install && npm run build', {
            cwd: lambdaDir,
            stdio: 'inherit',
          });

          // Copy bundled output
          const bundledFile = path.join(lambdaDir, 'dist/index.js');
          execSync(`cp ${bundledFile} ${outputDir}/`, { stdio: 'inherit' });

          // ⚠️ CRITICAL: Use literal strings, NOT CDK tokens
          const config = {
            USER_POOL_ID: 'us-east-1_ABC123',  // ✅ Literal string
            CLIENT_ID: '6d7261tcnso7dlj',      // ✅ Literal string
            // CLIENT_ID: userPoolClient.userPoolClientId,  // ❌ CDK token won't resolve!
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
});
```

**Why CDK tokens don't work in bundling:**
- `userPoolClient.userPoolClientId` is a CDK token (placeholder)
- Tokens resolve at deployment time, not synthesis time
- Bundling happens at synthesis time
- Token values aren't available in tryBundle closure

**Solution:** Use literal strings and add sync warnings:
```typescript
new cdk.CfnOutput(this, 'ConfigSyncRequired', {
  value: 'IMPORTANT: Verify Lambda@Edge config matches these outputs',
  description: `CLIENT_ID in config.json (${hardcodedClientId}) must match UserPoolClientId output. Update stack line 122 if they differ.`,
});
```

See `.claude/skills/cdk-scripting/templates/lambda-edge-auth.md` for complete pattern.

### 6. Security Validation with cdk-nag

**Install:**
```bash
npm install cdk-nag
```

**Apply to app:**
```typescript
import { Aspects } from 'aws-cdk-lib';
import { AwsSolutionsChecks } from 'cdk-nag';

// In bin/infrastructure.ts
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));
```

**Suppress rules with justification:**
```typescript
import { NagSuppressions } from 'cdk-nag';

NagSuppressions.addResourceSuppressions(
  lambda,
  [
    {
      id: 'AwsSolutions-IAM4',
      reason: 'Using AWS managed policy for Lambda execution is acceptable here',
    },
  ],
  true  // Apply to children
);
```

**Common rules:**
- **AwsSolutions-IAM4**: AWS managed policies (prefer custom)
- **AwsSolutions-S1**: S3 access logging
- **AwsSolutions-L1**: Lambda runtime versions
- **AwsSolutions-CFR4**: CloudFront custom SSL certificate

See `.claude/skills/cdk-scripting/tools.md` for full cdk-nag guide.

### 7. Testing Infrastructure

**Unit test with assertions:**
```typescript
import { Template, Match } from 'aws-cdk-lib/assertions';

test('Lambda has correct IAM permissions', () => {
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::IAM::Policy', {
    PolicyDocument: {
      Statement: Match.arrayWith([
        Match.objectLike({
          Action: ['dynamodb:GetItem'],
          Effect: 'Allow',
          Resource: Match.anyValue(),
        }),
      ]),
    },
  });
});
```

See `.claude/skills/cdk-scripting/examples.md` for complete testing examples.

### 8. AWS Solutions Constructs

Pre-built well-architected patterns:

```typescript
import * as solutions from '@aws-solutions-constructs/aws-apigateway-lambda';

const api = new solutions.ApiGatewayToLambda(this, 'Api', {
  lambdaFunctionProps: {
    runtime: lambda.Runtime.NODEJS_20_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset('lambda'),
  },
});
```

**When to use:**
- ✅ Building common patterns (API + Lambda, S3 + CloudFront)
- ✅ Want security/logging configured automatically
- ❌ Highly customized requirements (use L2 constructs instead)

Browse patterns: https://docs.aws.amazon.com/solutions/latest/constructs/

### 9. CDK Aspects for Cross-Cutting Concerns

Auto-tag all resources:

```typescript
import { Aspects, Tags } from 'aws-cdk-lib';

// Apply to entire app
Tags.of(app).add('CostCenter', 'Engineering');
Tags.of(app).add('Project', 'MyProject');

// Custom aspect for encryption
class EnforceEncryption implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof s3.Bucket) {
      if (!node.encryption || node.encryption === s3.BucketEncryption.UNENCRYPTED) {
        Annotations.of(node).addError('S3 buckets must have encryption enabled');
      }
    }
  }
}

Aspects.of(app).add(new EnforceEncryption());
```

See `.claude/skills/cdk-scripting/tools.md` for more aspect patterns.

### 10. Add Protection for Stateful Resources

If creating stateful resources (rare, but happens), protect from accidental deletion:

```typescript
const bucket = new s3.Bucket(this, 'DataBucket', {
  removalPolicy: cdk.RemovalPolicy.RETAIN,  // ✅ Protect from deletion
  autoDeleteObjects: false,                  // ✅ Don't auto-delete
});

const table = new dynamodb.Table(this, 'DataTable', {
  // ... other props
  removalPolicy: cdk.RemovalPolicy.RETAIN,  // ✅ Protect from deletion
});
```

### 11. Pre-Commit Checklist

Before committing CDK changes:

```bash
# 1. Synthesize CloudFormation template
cd "$CLAUDE_PROJECT_DIR/infrastructure" || {
  echo "❌ Failed to change to infrastructure directory"
  exit 1
}
npm run cdk synth

# 2. Review security findings (if cdk-nag installed)
# Fix critical issues or add documented suppressions

# 3. Run tests
npm test

# 4. Preview changes (CRITICAL - always run)
npm run cdk diff

# 5. Look for:
# ✅ Stateful resources are imported, not created
# ✅ No hardcoded IDs for created resources
# ✅ Environment variables use dynamic references
# ✅ RemovalPolicy.RETAIN on any new stateful resources
# ✅ All imports have valid IDs/ARNs
```

## Decision Tree

Use this flowchart when writing CDK code:

```
Does the resource exist in AWS already?
├─ YES → Does it contain data/state?
│   ├─ YES (User Pool, S3, DB) → IMPORT with .fromXxxId()
│   └─ NO (IAM Role, Lambda) → Still IMPORT (don't recreate)
└─ NO → Does it contain data/state?
    ├─ YES (new S3 bucket) → CREATE with RemovalPolicy.RETAIN
    └─ NO (new Lambda) → CREATE with new Resource()

Need to reference another resource's property?
├─ Created in CDK → Use resource.property directly
├─ Environment-specific → Use SSM Parameter
└─ Complex lookup → Use Custom Resource
```

## Key Anti-Patterns to Avoid

### ❌ Don't Hardcode Derived IDs

**Bad:**
```typescript
const lambda = new lambda.Function(this, 'Fn', {
  environment: {
    CLIENT_ID: 'abc123xyz',  // ❌ Hardcoded - will break if client recreated
  },
});
```

**Good:**
```typescript
const client = new cognito.UserPoolClient(this, 'Client', { userPool });
const lambda = new lambda.Function(this, 'Fn', {
  environment: {
    CLIENT_ID: client.userPoolClientId,  // ✅ Dynamic reference
  },
});
```

### ❌ Don't Import Stateless Resources

**Bad:**
```typescript
// Trying to import a Lambda function
const lambda = lambda.Function.fromFunctionArn(
  this,
  'Imported',
  'arn:aws:lambda:...'
);  // ❌ Just create it in CDK instead
```

**Good:**
```typescript
// Create the Lambda in CDK
const lambda = new lambda.Function(this, 'MyFunction', {
  // ... configuration
});  // ✅ Version controlled, reproducible
```

### ❌ Don't Recreate Stateful Resources

**Bad:**
```typescript
// Creating a new User Pool (will lose all users!)
const userPool = new cognito.UserPool(this, 'Pool', {
  // ...
});  // ❌ Will create new pool, lose existing users
```

**Good:**
```typescript
// Import existing User Pool
const userPool = cognito.UserPool.fromUserPoolId(
  this,
  'Pool',
  'us-east-1_ABC123'
);  // ✅ References existing pool
```

### ❌ Don't Use fromLookup() in CI/CD

**Bad:**
```typescript
const vpc = ec2.Vpc.fromLookup(this, 'VPC', {
  vpcId: 'vpc-123',
});  // ❌ Requires AWS credentials at synth time, fails in CI
```

**Good:**
```typescript
const vpc = ec2.Vpc.fromVpcAttributes(this, 'VPC', {
  vpcId: 'vpc-123',
  availabilityZones: ['us-east-1a', 'us-east-1b'],
});  // ✅ No AWS calls needed
```

### ❌ Don't Use Environment Variables in Lambda@Edge

**Bad:**
```typescript
const edgeFunction = new cloudfront.experimental.EdgeFunction(this, 'Auth', {
  environment: {
    USER_POOL_ID: 'us-east-1_ABC123',  // ❌ Lambda@Edge doesn't support env vars!
  },
});
```

**Good:**
```typescript
// Use build-time config injection (see section 5)
// Or runtime SSM Parameter Store fetch
```

### ❌ Don't Store Secrets in Code

**Bad:**
```typescript
const lambda = new lambda.Function(this, 'Fn', {
  environment: {
    API_KEY: 'sk-abc123xyz',  // ❌ Secret in code!
  },
});
```

**Good:**
```typescript
const secret = secretsmanager.Secret.fromSecretNameV2(this, 'ApiKey', 'prod/api-key');
lambda.addEnvironment('API_SECRET_ARN', secret.secretArn);
secret.grantRead(lambda);
// Lambda fetches at runtime: const secret = await secretsManager.getSecretValue({...})
```

### ❌ Don't Use Single Account for All Environments

**Bad:**
- Deploy dev, staging, prod to same AWS account
- Risk of cross-environment access
- Hard to isolate blast radius

**Good:**
- Use separate AWS accounts per environment
- Use AWS Organizations for management
- Use CDK Pipelines for multi-account deployment

## Quick Reference

### Import Patterns

| Resource Type | Import Method | Example |
|--------------|---------------|---------|
| User Pool | `.fromUserPoolId()` | `cognito.UserPool.fromUserPoolId(this, 'Pool', 'us-east-1_ABC')` |
| S3 Bucket | `.fromBucketName()` | `s3.Bucket.fromBucketName(this, 'Bucket', 'my-bucket')` |
| Certificate | `.fromCertificateArn()` | `acm.Certificate.fromCertificateArn(this, 'Cert', 'arn:...')` |
| VPC | `.fromVpcAttributes()` | `ec2.Vpc.fromVpcAttributes(this, 'VPC', { vpcId, availabilityZones })` |
| DynamoDB Table | `.fromTableName()` | `dynamodb.Table.fromTableName(this, 'Table', 'my-table')` |
| Lambda Function | `.fromFunctionArn()` | `lambda.Function.fromFunctionArn(this, 'Fn', 'arn:...')` |

### Property Access Patterns

| Scenario | Pattern | Example |
|----------|---------|---------|
| CDK-created resource | Direct property access | `bucket.bucketName` |
| Imported resource | Limited properties | `userPool.userPoolId` (works), `userPool.clients` (doesn't work) |
| Environment config | SSM Parameter | `ssm.StringParameter.valueFromLookup(this, '/path')` |
| Complex lookup | Custom Resource | `new cr.AwsCustomResource(...)` |
| Cross-stack reference | CfnOutput + import | Export in stack A, import in stack B |

### Protection Patterns

```typescript
// Protect stateful resources from deletion
removalPolicy: cdk.RemovalPolicy.RETAIN

// Protect from stack deletion
terminationProtection: true

// Prevent accidental object deletion
autoDeleteObjects: false
```

### Imported Bucket Policy Pattern

For imported buckets, use `CfnBucketPolicy` (not `addToResourcePolicy()`):

```typescript
const bucket = s3.Bucket.fromBucketName(this, 'Bucket', 'my-bucket');

new s3.CfnBucketPolicy(this, 'BucketPolicy', {
  bucket: bucket.bucketName,
  policyDocument: {
    Version: '2012-10-17',
    Statement: [
      {
        Effect: 'Allow',
        Principal: { Service: 'cloudfront.amazonaws.com' },
        Action: 's3:GetObject',
        Resource: `${bucket.bucketArn}/*`,
      },
    ],
  },
});
```

## Best Practices Summary

1. ✅ **Import stateful resources** - User Pools, S3 Buckets, Databases
2. ✅ **Create stateless resources** - Lambdas, IAM Roles, Configs
3. ✅ **Use dynamic references** - `resource.property`, not hardcoded strings
4. ✅ **Protect stateful resources** - `RemovalPolicy.RETAIN`
5. ✅ **Use SSM for environment config** - Different values per environment
6. ✅ **fromAttributes() over fromLookup()** - Avoid AWS calls in CI/CD
7. ✅ **Create children in CDK** - Don't import child resources
8. ✅ **Validate with cdk synth** - Catch errors before deployment
9. ✅ **Always run cdk diff** - Preview changes before deployment
10. ✅ **Use cdk-nag for security** - Shift security left in development
11. ✅ **Test infrastructure** - Use aws-cdk-lib/assertions for unit tests
12. ✅ **Lambda@Edge: build-time config** - No environment variables support

## Further Reading

- **Prompt Templates**: See `.claude/skills/cdk-scripting/templates/` for common CDK patterns
- **Project Examples**: See `.claude/skills/cdk-scripting/examples.md` for real-world patterns from this codebase
- **CDK Tools**: See `.claude/skills/cdk-scripting/tools.md` for ecosystem tools (Aspects, Context, Pipelines)
- **Well-Architected Framework**: See `.claude/skills/cdk-scripting/well-architected.md` for 5 pillars with CDK examples

---

**Remember:** When in doubt, think "Would recreating this lose data?" If yes → import. If no → create.
