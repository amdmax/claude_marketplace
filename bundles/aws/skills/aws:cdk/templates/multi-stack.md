# Multi-Stack Application Pattern

## Overview

This template guides implementing multi-stack CDK applications for organizing infrastructure by lifecycle, separation of concerns, and cross-stack dependencies.

## When to Use

- Separate stateful from stateless resources
- Different deployment frequencies (database vs application)
- Team ownership boundaries
- Environment isolation (dev, staging, prod)
- Shared infrastructure (VPC, DNS) used by multiple applications

## Requirements Checklist

Before implementing, confirm:

- [ ] Stack boundaries defined (stateful vs stateless)
- [ ] Dependencies between stacks identified
- [ ] Deployment order determined
- [ ] Environment strategy planned (single vs multi-account)
- [ ] Naming conventions established

## Implementation Pattern

### Project Structure

```
infrastructure/
├── bin/
│   └── infrastructure.ts       # App entry point
├── lib/
│   ├── network-stack.ts        # VPC, subnets, security groups
│   ├── database-stack.ts       # RDS, DynamoDB (stateful)
│   ├── compute-stack.ts        # Lambda, ECS (stateless)
│   ├── api-stack.ts            # API Gateway
│   └── frontend-stack.ts       # S3, CloudFront
├── cdk.json
└── package.json
```

### 1. Define Stacks

#### Network Stack (Shared Infrastructure)

```typescript
// lib/network-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

export class NetworkStack extends cdk.Stack {
  public readonly vpc: ec2.Vpc;
  public readonly securityGroup: ec2.SecurityGroup;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Create VPC
    this.vpc = new ec2.Vpc(this, 'Vpc', {
      maxAzs: 2,
      natGateways: 1,
      subnetConfiguration: [
        {
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          name: 'Private',
          subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS,
        },
      ],
    });

    // Create security group for Lambda
    this.securityGroup = new ec2.SecurityGroup(this, 'LambdaSG', {
      vpc: this.vpc,
      description: 'Security group for Lambda functions',
      allowAllOutbound: true,
    });

    // Export VPC ID for cross-stack references
    new cdk.CfnOutput(this, 'VpcId', {
      value: this.vpc.vpcId,
      exportName: 'NetworkStack-VpcId',
    });
  }
}
```

#### Database Stack (Stateful)

```typescript
// lib/database-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

interface DatabaseStackProps extends cdk.StackProps {
  vpc: ec2.IVpc;  // Passed from NetworkStack
}

export class DatabaseStack extends cdk.Stack {
  public readonly table: dynamodb.Table;
  public readonly database: rds.DatabaseInstance;

  constructor(scope: Construct, id: string, props: DatabaseStackProps) {
    super(scope, id, props);

    // DynamoDB table (stateful - RETAIN on delete)
    this.table = new dynamodb.Table(this, 'Table', {
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      pointInTimeRecovery: true,  // ✅ Continuous backups
      removalPolicy: cdk.RemovalPolicy.RETAIN,  // ✅ Protect from deletion
    });

    // RDS database (stateful - RETAIN on delete)
    this.database = new rds.DatabaseInstance(this, 'Database', {
      engine: rds.DatabaseInstanceEngine.postgres({ version: rds.PostgresEngineVersion.VER_15 }),
      vpc: props.vpc,
      multiAz: true,
      backupRetention: cdk.Duration.days(7),
      deletionProtection: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,  // ✅ Protect from deletion
    });

    // Export table name for other stacks
    new cdk.CfnOutput(this, 'TableName', {
      value: this.table.tableName,
      exportName: 'DatabaseStack-TableName',
    });
  }
}
```

#### Compute Stack (Stateless)

```typescript
// lib/compute-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

interface ComputeStackProps extends cdk.StackProps {
  vpc: ec2.IVpc;
  securityGroup: ec2.ISecurityGroup;
  table: dynamodb.ITable;
}

export class ComputeStack extends cdk.Stack {
  public readonly apiLambda: lambda.Function;

  constructor(scope: Construct, id: string, props: ComputeStackProps) {
    super(scope, id, props);

    // Lambda function (stateless - can be recreated)
    this.apiLambda = new lambda.Function(this, 'ApiLambda', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('../lambda/api/dist'),
      vpc: props.vpc,
      securityGroups: [props.securityGroup],
      environment: {
        TABLE_NAME: props.table.tableName,  // ✅ Dynamic reference
      },
    });

    // Grant Lambda permissions to DynamoDB
    props.table.grantReadWriteData(this.apiLambda);

    // Export Lambda ARN
    new cdk.CfnOutput(this, 'ApiLambdaArn', {
      value: this.apiLambda.functionArn,
      exportName: 'ComputeStack-ApiLambdaArn',
    });
  }
}
```

#### API Stack

```typescript
// lib/api-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as apigateway from 'aws-cdk-lib/aws-apigateway';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Construct } from 'constructs';

interface ApiStackProps extends cdk.StackProps {
  apiLambda: lambda.IFunction;
}

export class ApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: ApiStackProps) {
    super(scope, id, props);

    // API Gateway
    const api = new apigateway.RestApi(this, 'Api', {
      restApiName: 'My Application API',
      defaultCorsPreflightOptions: {
        allowOrigins: ['https://example.com'],
        allowMethods: apigateway.Cors.ALL_METHODS,
      },
    });

    // Lambda integration
    const integration = new apigateway.LambdaIntegration(props.apiLambda);
    api.root.addResource('api').addMethod('ANY', integration);

    // Export API URL
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: api.url,
      exportName: 'ApiStack-ApiUrl',
    });
  }
}
```

### 2. Compose Stacks in App

```typescript
// bin/infrastructure.ts
import * as cdk from 'aws-cdk-lib';
import { NetworkStack } from '../lib/network-stack';
import { DatabaseStack } from '../lib/database-stack';
import { ComputeStack } from '../lib/compute-stack';
import { ApiStack } from '../lib/api-stack';

const app = new cdk.App();

// Get environment from context
const env = {
  account: process.env.CDK_DEFAULT_ACCOUNT,
  region: process.env.CDK_DEFAULT_REGION,
};

// 1. Network Stack (shared infrastructure)
const networkStack = new NetworkStack(app, 'NetworkStack', { env });

// 2. Database Stack (stateful - depends on network)
const databaseStack = new DatabaseStack(app, 'DatabaseStack', {
  env,
  vpc: networkStack.vpc,
});
databaseStack.addDependency(networkStack);  // Explicit dependency

// 3. Compute Stack (stateless - depends on network and database)
const computeStack = new ComputeStack(app, 'ComputeStack', {
  env,
  vpc: networkStack.vpc,
  securityGroup: networkStack.securityGroup,
  table: databaseStack.table,
});
computeStack.addDependency(databaseStack);  // Explicit dependency

// 4. API Stack (depends on compute)
const apiStack = new ApiStack(app, 'ApiStack', {
  env,
  apiLambda: computeStack.apiLambda,
});
apiStack.addDependency(computeStack);  // Explicit dependency

app.synth();
```

### 3. Cross-Stack References

#### Option A: Direct Property References (Recommended)

```typescript
// Pass resources directly via props (type-safe)
const computeStack = new ComputeStack(app, 'ComputeStack', {
  table: databaseStack.table,  // ✅ Direct reference
});
```

#### Option B: CfnOutput + Fn.importValue

```typescript
// In DatabaseStack
new cdk.CfnOutput(this, 'TableName', {
  value: this.table.tableName,
  exportName: 'DatabaseStack-TableName',
});

// In ComputeStack
const tableName = cdk.Fn.importValue('DatabaseStack-TableName');
const table = dynamodb.Table.fromTableName(this, 'ImportedTable', tableName);
```

### 4. Multi-Environment Setup

```typescript
// bin/infrastructure.ts
const app = new cdk.App();

// Development environment
const devEnv = { account: '111111111111', region: 'us-east-1' };
new NetworkStack(app, 'Dev-NetworkStack', { env: devEnv });
new DatabaseStack(app, 'Dev-DatabaseStack', { env: devEnv, /* ... */ });

// Production environment (separate account)
const prodEnv = { account: '222222222222', region: 'us-east-1' };
new NetworkStack(app, 'Prod-NetworkStack', { env: prodEnv, terminationProtection: true });
new DatabaseStack(app, 'Prod-DatabaseStack', { env: prodEnv, terminationProtection: true, /* ... */ });
```

## Deployment

### Deploy All Stacks

```bash
# Deploy in dependency order (automatic)
cdk deploy --all

# Or deploy specific stacks
cdk deploy NetworkStack DatabaseStack ComputeStack ApiStack
```

### Deploy Single Stack

```bash
# Deploy only compute stack (requires dependencies deployed first)
cdk deploy ComputeStack
```

### Destroy Stacks

```bash
# Destroy in reverse order (CDK handles automatically)
cdk destroy --all

# Or destroy specific stack
cdk destroy ComputeStack
```

## Best Practices

### 1. Stack Boundaries

**Separate by lifecycle:**
- **Stateful stack** (rare changes): VPC, RDS, DynamoDB
- **Stateless stack** (frequent changes): Lambda, API Gateway

**Separate by ownership:**
- **Platform team**: Network, DNS, certificate
- **Application team**: Application resources

### 2. Dependencies

```typescript
// ✅ Explicit dependencies
computeStack.addDependency(databaseStack);

// ✅ Implicit dependencies (via property references)
new ComputeStack(app, 'Compute', {
  table: databaseStack.table,  // Automatic dependency
});
```

### 3. Stack Naming

```typescript
// ✅ Environment prefix
new NetworkStack(app, 'Dev-NetworkStack');
new NetworkStack(app, 'Prod-NetworkStack');

// ✅ Application prefix
new DataStack(app, 'MyApp-DataStack');
new ComputeStack(app, 'MyApp-ComputeStack');
```

### 4. Termination Protection

```typescript
// ✅ Protect production stateful stacks
export class DatabaseStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, {
      ...props,
      terminationProtection: true,  // Prevent accidental deletion
    });
  }
}
```

## Common Issues

### Issue: Circular dependency between stacks
**Cause:** Stack A depends on Stack B, Stack B depends on Stack A
**Fix:** Refactor to remove circular dependency, use intermediate stack

### Issue: Cannot delete stack due to exported outputs
**Cause:** Another stack imports CfnOutput from this stack
**Fix:** Delete dependent stacks first, then delete this stack

### Issue: Resource not found during deployment
**Cause:** Stack deployed before its dependencies
**Fix:** Deploy stacks in correct order or use `cdk deploy --all`

## Testing Multi-Stack Applications

```typescript
// tests/infrastructure.test.ts
import { App } from 'aws-cdk-lib';
import { Template } from 'aws-cdk-lib/assertions';
import { NetworkStack } from '../lib/network-stack';
import { DatabaseStack } from '../lib/database-stack';

describe('Multi-Stack Application', () => {
  let app: App;
  let networkStack: NetworkStack;
  let databaseStack: DatabaseStack;

  beforeEach(() => {
    app = new App();
    networkStack = new NetworkStack(app, 'TestNetwork');
    databaseStack = new DatabaseStack(app, 'TestDatabase', {
      vpc: networkStack.vpc,
    });
  });

  test('Network stack creates VPC', () => {
    const template = Template.fromStack(networkStack);
    template.resourceCountIs('AWS::EC2::VPC', 1);
  });

  test('Database stack has termination protection', () => {
    expect(databaseStack.terminationProtection).toBe(true);
  });

  test('Database table has RETAIN policy', () => {
    const template = Template.fromStack(databaseStack);
    template.hasResource('AWS::DynamoDB::Table', {
      DeletionPolicy: 'Retain',
    });
  });
});
```

## Further Reading

- **Core skill**: `.claude/skills/cdk-scripting/skill.md`
- **Examples**: `.claude/skills/cdk-scripting/examples.md`
- **Tools**: `.claude/skills/cdk-scripting/tools.md`
- **CDK Best Practices**: https://docs.aws.amazon.com/cdk/v2/guide/best-practices.html
