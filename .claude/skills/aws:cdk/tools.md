# CDK Tools Ecosystem

This reference covers essential tools and utilities in the AWS CDK ecosystem for security validation, testing, cross-cutting concerns, and development workflow.

## Table of Contents

1. [cdk-nag: Security Validation](#cdk-nag-security-validation)
2. [CDK Aspects: Cross-Cutting Concerns](#cdk-aspects-cross-cutting-concerns)
3. [CDK CLI Commands](#cdk-cli-commands)
4. [CDK Context](#cdk-context)
5. [CDK Pipelines](#cdk-pipelines)
6. [AWS Solutions Constructs](#aws-solutions-constructs)
7. [IDE Integration](#ide-integration)
8. [Community Tools](#community-tools)

---

## cdk-nag: Security Validation

### Overview

cdk-nag validates your CDK application against security compliance rule packs during synthesis, catching issues before deployment.

### Installation

```bash
npm install cdk-nag
```

### Basic Usage

Apply to entire app:

```typescript
// bin/infrastructure.ts
import { App, Aspects } from 'aws-cdk-lib';
import { AwsSolutionsChecks } from 'cdk-nag';
import { MyStack } from '../lib/my-stack';

const app = new App();
new MyStack(app, 'MyStack');

// ✅ Apply security checks to entire app
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));

app.synth();
```

### Available Rule Packs

1. **AwsSolutionsChecks** - General AWS security best practices (150+ rules)
2. **HIPAASecurityChecks** - HIPAA compliance requirements
3. **NIST800_53_R5Checks** - NIST 800-53 Rev 5 controls
4. **PCIDSSChecks** - PCI DSS 3.2.1 requirements

```typescript
import { AwsSolutionsChecks, HIPAASecurityChecks, NIST800_53_R5Checks, PCIDSSChecks } from 'cdk-nag';

// Apply multiple rule packs
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));
Aspects.of(app).add(new HIPAASecurityChecks({ verbose: true }));
```

### Suppressing Rules

Suppress with justification (documented in CloudFormation):

```typescript
import { NagSuppressions } from 'cdk-nag';

// Suppress on specific resource
NagSuppressions.addResourceSuppressions(
  lambda,
  [
    {
      id: 'AwsSolutions-IAM4',
      reason: 'Using AWS managed policy for Lambda execution is acceptable for this use case',
    },
    {
      id: 'AwsSolutions-L1',
      reason: 'Latest runtime version verified compatible with dependencies',
    },
  ],
  true  // Apply to children (nested constructs)
);

// Suppress on stack
NagSuppressions.addStackSuppressions(stack, [
  {
    id: 'AwsSolutions-S1',
    reason: 'Access logging not required for internal buckets',
    appliesTo: ['Resource::MyBucket'],  // Only specific resources
  },
]);

// Suppress by path
NagSuppressions.addResourceSuppressionsByPath(
  stack,
  '/MyStack/MyBucket/Resource',
  [
    {
      id: 'AwsSolutions-S1',
      reason: 'Access logging handled by centralized bucket',
    },
  ]
);
```

### Common Rules

| Rule ID | Description | Fix |
|---------|-------------|-----|
| AwsSolutions-IAM4 | AWS managed policies | Create custom policies with least privilege |
| AwsSolutions-IAM5 | Wildcard permissions | Specify exact actions and resources |
| AwsSolutions-S1 | S3 access logging | Enable server access logging |
| AwsSolutions-S2 | S3 bucket public read | Remove public read access or justify |
| AwsSolutions-L1 | Lambda runtime | Update to latest supported runtime |
| AwsSolutions-CFR4 | CloudFront SSL/TLS | Use TLSv1.2_2021 or newer |
| AwsSolutions-EC23 | Security group ingress | Restrict to specific IP ranges |
| AwsSolutions-RDS3 | RDS backup | Enable automated backups |

### Integration in CI/CD

```yaml
# .github/workflows/cdk.yml
- name: Synth CDK with security checks
  run: |
    cd "$CLAUDE_PROJECT_DIR/infrastructure" || {
      echo "❌ Failed to change to infrastructure directory"
      exit 1
    }
    npm install
    npm run cdk synth
  # cdk-nag runs automatically during synth
  # Fails if critical security issues found
```

### Viewing Results

```bash
# Verbose output shows all findings
npm run cdk synth > /dev/null

# Sample output:
# [Error at /MyStack/MyLambda/Resource] AwsSolutions-IAM4: The IAM user, role, or group uses AWS managed policies.
# [Warning at /MyStack/MyBucket/Resource] AwsSolutions-S1: The S3 Bucket does not have access logging enabled.
```

---

## CDK Aspects: Cross-Cutting Concerns

### Overview

CDK Aspects allow you to apply operations to all constructs in a scope (app, stack, or construct), implementing cross-cutting concerns like tagging, encryption, and validation.

### Auto-Tagging Resources

```typescript
import { Tags } from 'aws-cdk-lib';

// Apply to entire app
Tags.of(app).add('Environment', 'Production');
Tags.of(app).add('CostCenter', 'Engineering');
Tags.of(app).add('Project', 'MyProject');

// Apply to specific stack
Tags.of(stack).add('Stack', 'DataStack');

// Conditional tags
if (process.env.CI === 'true') {
  Tags.of(app).add('DeployedBy', 'CI/CD');
}
```

### Custom Aspects

Implement `IAspect` interface:

```typescript
import { IAspect, Annotations } from 'aws-cdk-lib';
import { IConstruct } from 'constructs';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as lambda from 'aws-cdk-lib/aws-lambda';

// Enforce encryption on all S3 buckets
class EnforceS3Encryption implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof s3.CfnBucket) {
      if (!node.bucketEncryption) {
        Annotations.of(node).addError('S3 buckets must have encryption enabled');
      }
    }
  }
}

// Enforce latest Lambda runtime
class EnforceLambdaRuntime implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof lambda.CfnFunction) {
      const runtime = node.runtime;
      if (runtime && !runtime.startsWith('nodejs20')) {
        Annotations.of(node).addWarning(`Lambda runtime ${runtime} is not latest (nodejs20.x)`);
      }
    }
  }
}

// Apply aspects
Aspects.of(app).add(new EnforceS3Encryption());
Aspects.of(app).add(new EnforceLambdaRuntime());
```

### Logging Aspect

```typescript
class ResourceLogger implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof cdk.CfnResource) {
      console.log(`Resource: ${node.logicalId}, Type: ${node.cfnResourceType}`);
    }
  }
}

Aspects.of(stack).add(new ResourceLogger());
```

### Dependency Validation Aspect

```typescript
class ValidateDependencies implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof lambda.Function) {
      const env = node.environment;
      if (env?.TABLE_NAME && !node.role?.managedPolicies.some(p => p.managedPolicyArn.includes('DynamoDB'))) {
        Annotations.of(node).addWarning('Lambda references DynamoDB but lacks DynamoDB permissions');
      }
    }
  }
}
```

---

## CDK CLI Commands

### Essential Commands

```bash
# Initialize new CDK project
cdk init app --language typescript

# Install dependencies
npm install

# Synthesize CloudFormation template (run cdk-nag, generate template)
cdk synth

# Preview changes before deployment (CRITICAL - always run)
cdk diff

# Deploy stack to AWS
cdk deploy

# Deploy specific stack
cdk deploy MyStack

# Deploy all stacks
cdk deploy --all

# Deploy with auto-approval (CI/CD)
cdk deploy --require-approval never

# Destroy stack (delete resources)
cdk destroy

# List all stacks
cdk list

# Bootstrap environment (one-time setup per account/region)
cdk bootstrap

# Show metadata about stack
cdk metadata MyStack

# Watch for changes and auto-deploy (dev only)
cdk watch

# Doctor command (troubleshoot issues)
cdk doctor
```

### Advanced Usage

```bash
# Pass context values
cdk synth -c environment=production -c version=1.0.0

# Output to specific directory
cdk synth --output cdk.out

# Deploy with CloudFormation parameters
cdk deploy --parameters MyParam=Value

# Deploy with specific profile
cdk deploy --profile production

# Deploy with role assumption
cdk deploy --role-arn arn:aws:iam::123456789012:role/CdkDeployRole

# Show verbose output
cdk synth --verbose

# Diff against specific stack
cdk diff MyStack --exclusively
```

### cdk diff Output

```bash
$ cdk diff

Stack MyStack
IAM Statement Changes
┌───┬─────────────────┬────────┬─────────────────┬───────────────────┬───────────┐
│   │ Resource        │ Effect │ Action          │ Principal         │ Condition │
├───┼─────────────────┼────────┼─────────────────┼───────────────────┼───────────┤
│ + │ ${MyBucket.Arn} │ Allow  │ s3:GetObject    │ Service:cloudfront│           │
└───┴─────────────────┴────────┴─────────────────┴───────────────────┴───────────┘

Resources
[+] AWS::S3::BucketPolicy MyBucketPolicy
```

---

## CDK Context

### Overview

CDK Context provides runtime configuration values that affect synthesis. Values are cached in `cdk.context.json`.

### Context Priority (Highest to Lowest)

1. CLI flags: `--context key=value`
2. `cdk.context.json` (cached lookups, gitignored)
3. `cdk.json` (project config, checked in)
4. `~/.cdk.json` (user config)
5. AWS account lookups (cached in cdk.context.json)

### Setting Context

```json
// cdk.json
{
  "app": "npx ts-node bin/infrastructure.ts",
  "context": {
    "environment": "production",
    "domain": "example.com",
    "@aws-cdk/core:enableStackNameDuplicates": false,
    "@aws-cdk/core:stackRelativeExports": true
  }
}
```

### Using Context

```typescript
// In stack
const environment = this.node.tryGetContext('environment');
const domain = this.node.tryGetContext('domain');

if (environment === 'production') {
  // Production-specific config
}
```

### Context Caching

```bash
# Clear cached context
cdk context --clear

# Show cached context
cdk context

# Reset specific cached value
cdk context --reset "vpc-provider:account=123456789012:filter.vpc-id=vpc-12345"
```

### Feature Flags

```json
// cdk.json - Enable/disable CDK features
{
  "context": {
    "@aws-cdk/core:newStyleStackSynthesis": true,
    "@aws-cdk/aws-s3:grantWriteWithoutAcl": true,
    "@aws-cdk/aws-iam:minimizePolicies": true,
    "@aws-cdk/core:enableStackNameDuplicates": false
  }
}
```

---

## CDK Pipelines

### Overview

CDK Pipelines create self-mutating CI/CD pipelines that deploy CDK applications across multiple environments and accounts.

### Basic Setup

```typescript
import { Stack, StackProps } from 'aws-cdk-lib';
import { CodePipeline, CodePipelineSource, ShellStep } from 'aws-cdk-lib/pipelines';
import { Construct } from 'constructs';

export class PipelineStack extends Stack {
  constructor(scope: Construct, id: string, props?: StackProps) {
    super(scope, id, props);

    const pipeline = new CodePipeline(this, 'Pipeline', {
      pipelineName: 'MyAppPipeline',
      synth: new ShellStep('Synth', {
        input: CodePipelineSource.gitHub('my-org/my-repo', 'main'),
        commands: [
          'npm ci',
          'npm run build',
          'npx cdk synth',
        ],
      }),
    });

    // Add deployment stages
    pipeline.addStage(new DevStage(this, 'Dev'));
    pipeline.addStage(new ProdStage(this, 'Prod'), {
      pre: [new ManualApprovalStep('PromoteToProd')],
    });
  }
}
```

### Multi-Account Deployment

```typescript
// Deploy to different accounts
pipeline.addStage(new DevStage(this, 'Dev', {
  env: { account: '111111111111', region: 'us-east-1' },
}));

pipeline.addStage(new ProdStage(this, 'Prod', {
  env: { account: '222222222222', region: 'us-east-1' },
}));
```

---

## AWS Solutions Constructs

### Overview

Pre-built, well-architected patterns combining multiple AWS services with security and best practices included.

### Installation

```bash
# Install specific construct
npm install @aws-solutions-constructs/aws-apigateway-lambda

# Or install all constructs
npm install @aws-solutions-constructs/aws-constructs
```

### Common Patterns

```typescript
// API Gateway + Lambda
import * as apigwLambda from '@aws-solutions-constructs/aws-apigateway-lambda';

new apigwLambda.ApiGatewayToLambda(this, 'Api', {
  lambdaFunctionProps: {
    runtime: lambda.Runtime.NODEJS_20_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset('lambda'),
  },
});

// CloudFront + S3
import * as cloudfrontS3 from '@aws-solutions-constructs/aws-cloudfront-s3';

new cloudfrontS3.CloudFrontToS3(this, 'CloudFront', {
  insertHttpSecurityHeaders: true,  // Add security headers
  bucketProps: {
    versioned: true,
  },
});

// Lambda + DynamoDB
import * as lambdaDynamoDB from '@aws-solutions-constructs/aws-lambda-dynamodb';

new lambdaDynamoDB.LambdaToDynamoDB(this, 'LambdaDB', {
  lambdaFunctionProps: {
    runtime: lambda.Runtime.NODEJS_20_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset('lambda'),
  },
  dynamoTableProps: {
    partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  },
});
```

### Browse All Constructs

- **Docs**: https://docs.aws.amazon.com/solutions/latest/constructs/
- **Construct Hub**: https://constructs.dev/packages/@aws-solutions-constructs/

---

## IDE Integration

### AWS Toolkit for VS Code

**Install:** Search "AWS Toolkit" in VS Code extensions

**Features:**
- CDK Explorer (visualize stacks)
- Integrated synth/deploy
- CloudFormation template viewer
- Lambda function testing
- S3 browser

### CDK Extension Pack

**Install:** Search "AWS CDK Extension Pack" in VS Code

**Includes:**
- AWS Toolkit
- CDK snippets
- TypeScript support
- YAML/JSON formatters
- CloudFormation linter

### IntelliSense

Configure TypeScript for better autocomplete:

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "module": "commonjs",
    "target": "ES2020",
    "lib": ["ES2020"],
    "declaration": true,
    "declarationMap": true
  }
}
```

---

## Community Tools

### Useful npm Packages

```bash
# cdk-dia: Generate architecture diagrams
npm install -g cdk-dia
cdk-dia --output architecture.png

# cdk-constants: AWS service constants
npm install cdk-constants

# aws-cdk-lib/assertions: Testing (included in aws-cdk-lib)
# Already available, no install needed

# cdk-notifier: Slack/Email notifications
npm install cdk-notifier
```

### Construct Hub

Browse 1000+ community constructs:
- **URL**: https://constructs.dev/
- **Search** by service, author, or keyword
- **Filter** by language (TypeScript, Python, Java, C#, Go)

### CDK Patterns

Pre-built serverless patterns:
- **URL**: https://cdkpatterns.com/
- **Examples**: The Big Fan, The Destined Lambda, The Saga Stepfunction
- **Architecture diagrams** included

---

## Tool Selection Guide

| Need | Tool | When to Use |
|------|------|-------------|
| Security validation | cdk-nag | Every project |
| Testing | aws-cdk-lib/assertions | Every project |
| Cross-cutting concerns | CDK Aspects | Tagging, encryption, validation |
| Multi-account deployment | CDK Pipelines | Production systems |
| Common patterns | AWS Solutions Constructs | Standard architectures |
| Architecture diagrams | cdk-dia | Documentation |
| IDE support | AWS Toolkit | Local development |
| Community constructs | Construct Hub | Finding reusable patterns |

---

## Further Reading

- **Core skill**: `.claude/skills/cdk-scripting/skill.md`
- **Examples**: `.claude/skills/cdk-scripting/examples.md`
- **Templates**: `.claude/skills/cdk-scripting/templates/`
- **Well-Architected**: `.claude/skills/cdk-scripting/well-architected.md`
