# CDK Project-Specific Examples

This file contains real-world CDK patterns from the AIGENSA Vibe Coding Course infrastructure, demonstrating lessons learned and best practices.

## Table of Contents

1. [S3 Bucket Policy for Imported Buckets](#s3-bucket-policy-for-imported-buckets)
2. [Lambda@Edge with Local Bundling](#lambdaedge-with-local-bundling)
3. [CustomMessage Lambda with Templates Directory](#custommessage-lambda-with-templates-directory)
4. [Stack Outputs with Manual Step Instructions](#stack-outputs-with-manual-step-instructions)
5. [Cognito UI Customization](#cognito-ui-customization)
6. [Testing CDK Stacks](#testing-cdk-stacks)

---

## S3 Bucket Policy for Imported Buckets

### Problem

When using CloudFront Origin Access Control (OAC) with an **imported** S3 bucket, the standard `addToResourcePolicy()` method doesn't work:

```typescript
// ❌ This doesn't work for imported buckets
const bucket = s3.Bucket.fromBucketName(this, 'Bucket', 'my-bucket');
bucket.addToResourcePolicy(new iam.PolicyStatement({
  // ...
}));
// Error: Cannot add resource policy to imported bucket
```

### Solution

Use `CfnBucketPolicy` to create the bucket policy as a separate CloudFormation resource:

```typescript
// ✅ Import the bucket
const courseBucket = s3.Bucket.fromBucketName(
  this,
  'CourseBucket',
  'aigensa-ai-coding-course'
);

// ✅ Create bucket policy using CfnBucketPolicy
new s3.CfnBucketPolicy(this, 'CourseBucketPolicy', {
  bucket: courseBucket.bucketName,
  policyDocument: {
    Version: '2012-10-17',
    Statement: [
      {
        Sid: 'AllowCloudFrontServicePrincipal',
        Effect: 'Allow',
        Principal: {
          Service: 'cloudfront.amazonaws.com',
        },
        Action: 's3:GetObject',
        Resource: `${courseBucket.bucketArn}/*`,
        Condition: {
          StringEquals: {
            'AWS:SourceArn': `arn:aws:cloudfront::${this.account}:distribution/${distribution.distributionId}`,
          },
        },
      },
    ],
  },
});
```

### Key Lessons

- **Imported resources have limited methods** - Can't call `addToResourcePolicy()` on imported buckets
- **Use Cfn resources directly** - `CfnBucketPolicy`, `CfnBucketNotification`, etc. work with imported resources
- **Reference ARN from imported bucket** - `courseBucket.bucketArn` works even on imported buckets
- **Condition on distribution ARN** - Ensures only specific CloudFront distribution can access bucket

**Source:** `infrastructure/lib/ai-assisted-coding-stack.ts:243-264`, `infrastructure/ISSUES_FIXED.md:48-56`

---

## Lambda@Edge with Local Bundling

### Problem

Lambda@Edge has strict requirements:
1. **No environment variables** - Lambda@Edge doesn't support `environment` property
2. **Size limit** - 1MB compressed, 50MB uncompressed (including dependencies)
3. **Docker bundling is slow** - Takes 2-3 minutes per build

### Solution

Use local bundling with build-time config injection:

```typescript
const authEdgeFunction = new cloudfront.experimental.EdgeFunction(this, 'AuthEdgeFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('../lambda/auth-edge', {
    assetHashType: cdk.AssetHashType.OUTPUT,  // ✅ Hash based on output, not source
    bundling: {
      image: lambda.Runtime.NODEJS_20_X.bundlingImage,
      command: ['echo', 'This should not run - using local bundling'],
      local: {
        tryBundle(outputDir: string) {
          const { execSync } = require('child_process');
          const path = require('path');
          const fs = require('fs');

          const lambdaDir = path.join(__dirname, '../../lambda/auth-edge');

          // ✅ Install dependencies and build with esbuild
          // esbuild bundles all dependencies into a single file
          execSync('npm install && npm run build', {
            cwd: lambdaDir,
            stdio: 'inherit',
          });

          // ✅ Copy bundled output (single file with all dependencies)
          const bundledFile = path.join(lambdaDir, 'dist/index.js');
          execSync(`cp ${bundledFile} ${outputDir}/`, { stdio: 'inherit' });

          // ✅ Write config file (injected at build time)
          // Lambda@Edge constraint: Cannot use environment variables, must bundle config
          // IMPORTANT: These values are hardcoded and must be manually updated if Cognito
          // resources are recreated. See stack outputs to verify current values match.
          const config = {
            USER_POOL_ID: 'us-east-1_qjoYrEY8I',  // ✅ Literal string
            CLIENT_ID: '6d7261tcnso7dlj6o9be46r9n3',  // ✅ Literal string
            COGNITO_DOMAIN: 'aigensa-ai-coding',  // ✅ Literal string
          };
          fs.writeFileSync(
            path.join(outputDir, 'config.json'),
            JSON.stringify(config)
          );

          return true;  // ✅ Success - skip Docker bundling
        },
      },
    },
  }),
});
```

### Why CDK Tokens Don't Work

```typescript
// ❌ This doesn't work
const config = {
  CLIENT_ID: userPoolClient.userPoolClientId,  // CDK token, not resolved yet
};

// When CDK runs tryBundle:
// 1. Synthesis time: tryBundle runs, userPoolClientId is "${Token[...]}"
// 2. Deployment time: CloudFormation resolves token to actual value
// 3. Problem: config.json already bundled with token placeholder, not actual value
```

### Solution: Literal Strings + Sync Warnings

```typescript
// ✅ Use literal strings
const hardcodedClientId = '6d7261tcnso7dlj6o9be46r9n3';
const config = {
  CLIENT_ID: hardcodedClientId,  // Literal string, available at synthesis time
};

// ✅ Add output warning to verify sync
new cdk.CfnOutput(this, 'LambdaEdgeConfigSyncRequired', {
  value: 'IMPORTANT: Verify Lambda@Edge config matches these outputs',
  description: `Lambda@Edge bundled config CLIENT_ID (${hardcodedClientId}) must match UserPoolClientId output. Update infrastructure/lib/ai-assisted-coding-stack.ts:122 if they differ.`,
});
```

### Key Lessons

- **Local bundling is 10x faster** - 15 seconds vs 2-3 minutes with Docker
- **AssetHashType.OUTPUT** - Hash based on bundled output, not source files (prevents unnecessary rebuilds)
- **esbuild --bundle** - Bundles all node_modules into single file (solves missing dependencies issue)
- **Build-time config** - Inject config at synthesis time since env vars don't work
- **Sync warnings** - Document when manual updates are required

**Source:** `infrastructure/lib/ai-assisted-coding-stack.ts:84-136`, `infrastructure/ISSUES_FIXED.md:7-10`

---

## CustomMessage Lambda with Templates Directory

### Problem

CustomMessage Lambda needs to include email templates directory in deployment package.

### Solution

Use local bundling with recursive directory copy:

```typescript
const customMessageFunction = new lambda.Function(this, 'CustomMessageFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('../lambda/custom-message', {
    bundling: {
      image: lambda.Runtime.NODEJS_20_X.bundlingImage,
      command: ['echo', 'This should not run - using local bundling'],
      local: {
        tryBundle(outputDir: string) {
          try {
            const { execSync } = require('child_process');
            const fs = require('fs');
            const path = require('path');

            const lambdaDir = path.join(__dirname, '../../lambda/custom-message');

            // ✅ Verify Lambda directory exists
            if (!fs.existsSync(lambdaDir)) {
              console.error(`Lambda directory not found: ${lambdaDir}`);
              return false;
            }

            // ✅ Install dependencies and build
            execSync('npm install && npm run build', {
              cwd: lambdaDir,
              stdio: 'inherit',
            });

            // ✅ Copy bundled output and templates using fs methods (prevents command injection)
            const bundledFile = path.join(lambdaDir, 'dist/index.js');
            const templatesDir = path.join(lambdaDir, 'dist/templates');

            // ✅ Verify build artifacts exist before copying
            if (!fs.existsSync(bundledFile)) {
              console.error(`Build artifact not found: ${bundledFile}`);
              return false;
            }

            if (!fs.existsSync(templatesDir)) {
              console.error(`Templates directory not found: ${templatesDir}`);
              return false;
            }

            // ✅ Copy files safely
            fs.copyFileSync(bundledFile, path.join(outputDir, 'index.js'));
            fs.cpSync(templatesDir, path.join(outputDir, 'templates'), { recursive: true });

            return true;  // ✅ Success
          } catch (error) {
            console.error('Local bundling failed:', error);
            return false;  // ❌ Fall back to Docker bundling
          }
        },
      },
    },
  }),
  timeout: cdk.Duration.seconds(5),
  memorySize: 256,
  description: 'CustomMessage trigger for branded Cognito emails',
});
```

### Key Lessons

- **Verify paths before copying** - Check directory exists to fail fast with helpful error
- **Use fs methods, not shell commands** - `fs.cpSync()` instead of `cp -r` (prevents command injection)
- **Recursive copy** - `fs.cpSync(src, dest, { recursive: true })` for directories
- **Error handling** - Return false to fall back to Docker bundling
- **Build artifacts** - Copy from `dist/` after build, not from `src/`

**Source:** `infrastructure/lib/ai-assisted-coding-stack.ts:143-204`

---

## Stack Outputs with Manual Step Instructions

### Problem

Some operations can't be automated in CDK (e.g., attaching Lambda triggers to imported User Pools).

### Solution

Use `CfnOutput` descriptions to provide AWS CLI commands for manual steps:

```typescript
// ✅ Output with AWS CLI command for manual step
new cdk.CfnOutput(this, 'CustomMessageFunctionArn', {
  value: customMessageFunction.functionArn,
  description: 'CustomMessage Lambda ARN - attach to User Pool via: aws cognito-idp update-user-pool --user-pool-id us-east-1_qjoYrEY8I --lambda-config CustomMessage=<ARN> --region us-east-1',
});

// ✅ Output with sync warning
new cdk.CfnOutput(this, 'LambdaEdgeConfigSyncRequired', {
  value: 'IMPORTANT: Verify Lambda@Edge config matches these outputs',
  description: `Lambda@Edge bundled config CLIENT_ID (6d7261tcnso7dlj6o9be46r9n3) must match UserPoolClientId output. Update infrastructure/lib/ai-assisted-coding-stack.ts:122 if they differ.`,
});

// ✅ Output with deployment notes
new cdk.CfnOutput(this, 'BucketName', {
  value: courseBucket.bucketName,
  description: 'S3 bucket for course content - deploy with: npm run deploy',
});
```

### Key Lessons

- **Document manual steps** - Can't automate everything in CDK
- **Include AWS CLI commands** - Make it easy to copy-paste
- **Reference line numbers** - Help users find code to update
- **Warn about sync requirements** - When hardcoded values must match outputs
- **Explain deployment process** - Help users understand next steps

**Source:** `infrastructure/lib/ai-assisted-coding-stack.ts:287-300`

---

## Cognito UI Customization

### Problem

Customize Cognito hosted UI with CSS (no logo upload in CDK yet).

### Solution

Read CSS file and apply with `CfnUserPoolUICustomizationAttachment`:

```typescript
// ✅ Read CSS file for UI customization
const cognitoCss = fs.readFileSync(
  path.join(__dirname, '../cognito-ui-customization.css'),
  'utf-8'
);

// ✅ Apply CSS customization to Cognito hosted UI
new cognito.CfnUserPoolUICustomizationAttachment(this, 'UserPoolUICustomization', {
  userPoolId: userPool.userPoolId,
  clientId: 'ALL',  // Apply to all clients
  css: cognitoCss,
});
```

### CSS File Structure

```css
/* cognito-ui-customization.css */
.banner-customizable {
  background-color: #4F46E5;  /* Brand color */
}

.submitButton-customizable {
  background-color: #4F46E5;
  font-weight: 600;
}

.submitButton-customizable:hover {
  background-color: #4338CA;
}
```

### Key Lessons

- **CSS only** - CDK doesn't support logo upload yet (use AWS Console for logo)
- **clientId: 'ALL'** - Applies to all User Pool Clients
- **Read file at synthesis** - `fs.readFileSync()` in CDK code
- **Brand consistency** - Use same colors as main application

**Source:** `infrastructure/lib/ai-assisted-coding-stack.ts:63-75`

---

## Testing CDK Stacks

### Unit Testing with aws-cdk-lib/assertions

```typescript
import { Template, Match } from 'aws-cdk-lib/assertions';
import { App } from 'aws-cdk-lib';
import { AiAssistedCodingStack } from '../lib/ai-assisted-coding-stack';

describe('AiAssistedCodingStack', () => {
  let app: App;
  let stack: AiAssistedCodingStack;
  let template: Template;

  beforeEach(() => {
    app = new App();
    stack = new AiAssistedCodingStack(app, 'TestStack');
    template = Template.fromStack(stack);
  });

  test('Creates CloudFront distribution', () => {
    template.resourceCountIs('AWS::CloudFront::Distribution', 1);
  });

  test('Lambda@Edge has correct runtime', () => {
    template.hasResourceProperties('AWS::Lambda::Function', {
      Runtime: 'nodejs20.x',
      Handler: 'index.handler',
    });
  });

  test('S3 bucket policy grants CloudFront access', () => {
    template.hasResourceProperties('AWS::S3::BucketPolicy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({
            Effect: 'Allow',
            Principal: { Service: 'cloudfront.amazonaws.com' },
            Action: 's3:GetObject',
          }),
        ]),
      },
    });
  });

  test('User Pool Client has OAuth configured', () => {
    template.hasResourceProperties('AWS::Cognito::UserPoolClient', {
      AllowedOAuthFlows: ['code'],
      AllowedOAuthScopes: Match.arrayWith(['openid', 'email', 'profile']),
    });
  });

  test('Stack has required outputs', () => {
    template.hasOutput('DistributionId', {});
    template.hasOutput('UserPoolClientId', {});
    template.hasOutput('CourseURL', {});
  });
});
```

### Snapshot Testing

```typescript
test('Stack matches snapshot', () => {
  const template = Template.fromStack(stack);
  expect(template.toJSON()).toMatchSnapshot();
});
```

### Key Lessons

- **Fine-grained assertions** - Test specific properties (runtime, IAM permissions)
- **Snapshot tests** - Detect unintended changes during refactoring
- **Resource counts** - Verify expected number of resources created
- **Match.arrayWith()** - Test array contains specific items (order-independent)
- **Match.objectLike()** - Test object has specific properties (ignores extra properties)

---

## Common Patterns Summary

### Import Stateful, Create Stateless

```typescript
// ✅ Import stateful resources (data/users)
const userPool = cognito.UserPool.fromUserPoolId(this, 'Pool', 'us-east-1_ABC123');
const bucket = s3.Bucket.fromBucketName(this, 'Bucket', 'my-bucket');

// ✅ Create stateless resources (config/code)
const client = new cognito.UserPoolClient(this, 'Client', { userPool });
const lambda = new lambda.Function(this, 'Fn', { code: ... });
```

### Dynamic References

```typescript
// ✅ Reference properties from created resources
const lambda = new lambda.Function(this, 'Fn', {
  environment: {
    USER_POOL_ID: userPool.userPoolId,  // Works for both imported and created
    CLIENT_ID: client.userPoolClientId,  // Auto-updates if client recreated
  },
});
```

### Protection Patterns

```typescript
// ✅ Protect stateful resources
const bucket = new s3.Bucket(this, 'Data', {
  removalPolicy: cdk.RemovalPolicy.RETAIN,
  autoDeleteObjects: false,
});
```

### IAM Least Privilege

```typescript
// ✅ Specific actions, specific resources
lambda.addToRolePolicy(
  new iam.PolicyStatement({
    actions: ['dynamodb:GetItem', 'dynamodb:PutItem'],
    resources: [table.tableArn],
  })
);
```

---

## Further Reading

- **Core skill**: `.claude/skills/cdk-scripting/skill.md`
- **Templates**: `.claude/skills/cdk-scripting/templates/`
- **Tools**: `.claude/skills/cdk-scripting/tools.md`
- **Well-Architected**: `.claude/skills/cdk-scripting/well-architected.md`
- **Project infrastructure**: `infrastructure/lib/`, `infrastructure/ISSUES_FIXED.md`
