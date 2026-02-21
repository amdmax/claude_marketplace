# AWS Well-Architected Framework for CDK

This reference provides CDK implementation patterns for the five pillars of the AWS Well-Architected Framework.

## Table of Contents

1. [Operational Excellence](#operational-excellence)
2. [Security](#security)
3. [Reliability](#reliability)
4. [Performance Efficiency](#performance-efficiency)
5. [Cost Optimization](#cost-optimization)
6. [Well-Architected Checklist](#well-architected-checklist)

---

## Operational Excellence

**Principles:**
- Operations as code
- Frequent, small, reversible changes
- Refine operations procedures frequently
- Anticipate failure
- Learn from operational failures

### CDK Implementation

#### 1. Infrastructure as Code

```typescript
// ✅ All infrastructure defined in code
export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Infrastructure version controlled in git
    // Changes reviewed via pull requests
    // Deployments repeatable and automated
  }
}
```

#### 2. Automated Testing

```typescript
// tests/app-stack.test.ts
import { Template } from 'aws-cdk-lib/assertions';
import { App } from 'aws-cdk-lib';
import { AppStack } from '../lib/app-stack';

describe('AppStack', () => {
  test('Creates expected resources', () => {
    const app = new App();
    const stack = new AppStack(app, 'TestStack');
    const template = Template.fromStack(stack);

    template.resourceCountIs('AWS::Lambda::Function', 3);
    template.resourceCountIs('AWS::DynamoDB::Table', 1);
  });

  test('Lambda has least privilege IAM', () => {
    const template = Template.fromStack(stack);
    template.hasResourceProperties('AWS::IAM::Policy', {
      PolicyDocument: {
        Statement: Match.arrayWith([
          Match.objectLike({
            Action: ['dynamodb:GetItem', 'dynamodb:PutItem'],
            Effect: 'Allow',
          }),
        ]),
      },
    });
  });
});
```

#### 3. Monitoring and Observability

```typescript
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as actions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as sns from 'aws-cdk-lib/aws-sns';

// Create dashboard
const dashboard = new cloudwatch.Dashboard(this, 'AppDashboard', {
  dashboardName: 'MyAppDashboard',
});

// Add Lambda metrics
dashboard.addWidgets(
  new cloudwatch.GraphWidget({
    title: 'Lambda Invocations',
    left: [lambda.metricInvocations()],
  }),
  new cloudwatch.GraphWidget({
    title: 'Lambda Errors',
    left: [lambda.metricErrors()],
  }),
  new cloudwatch.GraphWidget({
    title: 'Lambda Duration',
    left: [lambda.metricDuration()],
  })
);

// Create alarm
const errorAlarm = lambda.metricErrors().createAlarm(this, 'ErrorAlarm', {
  threshold: 10,
  evaluationPeriods: 1,
  alarmDescription: 'Lambda error rate exceeded threshold',
});

// Send to SNS
const topic = new sns.Topic(this, 'AlarmTopic');
errorAlarm.addAlarmAction(new actions.SnsAction(topic));
```

#### 4. Runbook Automation

```typescript
// Document deployment steps in stack
new cdk.CfnOutput(this, 'DeploymentSteps', {
  value: 'Run: npm run deploy',
  description: 'Deployment command',
});

new cdk.CfnOutput(this, 'RollbackSteps', {
  value: 'Run: cdk deploy --previous-version',
  description: 'Rollback to previous version',
});
```

---

## Security

**Principles:**
- Implement a strong identity foundation
- Enable traceability
- Apply security at all layers
- Automate security best practices
- Protect data in transit and at rest
- Keep people away from data
- Prepare for security events

### CDK Implementation

#### 1. Least Privilege IAM

```typescript
import * as iam from 'aws-cdk-lib/aws-iam';

// ✅ Specific actions, specific resources
lambda.addToRolePolicy(
  new iam.PolicyStatement({
    actions: [
      'dynamodb:GetItem',
      'dynamodb:PutItem',
      'dynamodb:UpdateItem',
    ],
    resources: [
      table.tableArn,
      `${table.tableArn}/index/*`,  // GSI access
    ],
  })
);

// ❌ Avoid wildcard permissions
// actions: ['dynamodb:*'],
// resources: ['*'],
```

#### 2. Encryption at Rest

```typescript
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as kms from 'aws-cdk-lib/aws-kms';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';

// S3 with KMS encryption
const encryptionKey = new kms.Key(this, 'S3Key', {
  enableKeyRotation: true,
});

const bucket = new s3.Bucket(this, 'SecureBucket', {
  encryption: s3.BucketEncryption.KMS,
  encryptionKey: encryptionKey,
  bucketKeyEnabled: true,  // Reduce KMS costs
});

// DynamoDB with encryption
const table = new dynamodb.Table(this, 'SecureTable', {
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  encryption: dynamodb.TableEncryption.AWS_MANAGED,  // Or CUSTOMER_MANAGED with KMS key
});
```

#### 3. Secrets Management

```typescript
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';

// Store secrets in Secrets Manager
const dbPassword = new secretsmanager.Secret(this, 'DBPassword', {
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ username: 'admin' }),
    generateStringKey: 'password',
    excludePunctuation: true,
  },
});

// Lambda fetches at runtime
const lambda = new lambda.Function(this, 'Fn', {
  // ... other props
  environment: {
    SECRET_ARN: dbPassword.secretArn,  // ✅ ARN, not value
  },
});

dbPassword.grantRead(lambda);
```

#### 4. Network Security

```typescript
import * as ec2 from 'aws-cdk-lib/aws-ec2';

// Security group with least privilege
const securityGroup = new ec2.SecurityGroup(this, 'LambdaSG', {
  vpc,
  description: 'Security group for Lambda function',
  allowAllOutbound: false,  // Explicit outbound rules
});

// Allow HTTPS to specific service
securityGroup.addEgressRule(
  ec2.Peer.ipv4('10.0.0.0/16'),
  ec2.Port.tcp(443),
  'Allow HTTPS to internal services'
);

// Lambda in VPC
const lambda = new lambda.Function(this, 'Fn', {
  // ... other props
  vpc,
  securityGroups: [securityGroup],
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
});
```

#### 5. Security Validation with cdk-nag

```typescript
import { Aspects } from 'aws-cdk-lib';
import { AwsSolutionsChecks } from 'cdk-nag';

// Apply security checks
Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));
```

#### 6. CloudTrail Logging

```typescript
import * as cloudtrail from 'aws-cdk-lib/aws-cloudtrail';

const trail = new cloudtrail.Trail(this, 'CloudTrail', {
  isMultiRegionTrail: true,
  includeGlobalServiceEvents: true,
  managementEvents: cloudtrail.ReadWriteType.ALL,
});

// Log data events for S3
trail.addS3EventSelector([{
  bucket: dataBucket,
  objectPrefix: 'sensitive/',
}]);
```

---

## Reliability

**Principles:**
- Automatically recover from failure
- Test recovery procedures
- Scale horizontally
- Stop guessing capacity
- Manage change through automation

### CDK Implementation

#### 1. Multi-AZ Deployment

```typescript
import * as rds from 'aws-cdk-lib/aws-rds';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

// RDS with Multi-AZ
const database = new rds.DatabaseInstance(this, 'Database', {
  engine: rds.DatabaseInstanceEngine.postgres({ version: rds.PostgresEngineVersion.VER_15 }),
  vpc,
  multiAz: true,  // ✅ Automatic failover
  backupRetention: cdk.Duration.days(7),
  deletionProtection: true,
});

// Application Load Balancer across multiple AZs
const alb = new elbv2.ApplicationLoadBalancer(this, 'ALB', {
  vpc,
  internetFacing: true,
  vpcSubnets: {
    subnetType: ec2.SubnetType.PUBLIC,
    onePerAz: true,  // ✅ Spread across AZs
  },
});
```

#### 2. Auto Scaling

```typescript
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as applicationautoscaling from 'aws-cdk-lib/aws-applicationautoscaling';

// EC2 Auto Scaling
const asg = new autoscaling.AutoScalingGroup(this, 'ASG', {
  vpc,
  instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
  machineImage: ec2.MachineImage.latestAmazonLinux2(),
  minCapacity: 2,
  maxCapacity: 10,
  desiredCapacity: 2,
});

asg.scaleOnCpuUtilization('CpuScaling', {
  targetUtilizationPercent: 70,
});

// DynamoDB Auto Scaling
const readScaling = table.autoScaleReadCapacity({
  minCapacity: 5,
  maxCapacity: 100,
});

readScaling.scaleOnUtilization({
  targetUtilizationPercent: 70,
});
```

#### 3. Backups and Disaster Recovery

```typescript
// S3 bucket versioning
const bucket = new s3.Bucket(this, 'DataBucket', {
  versioned: true,  // ✅ Protect against accidental deletion
  lifecycleRules: [
    {
      noncurrentVersionExpiration: cdk.Duration.days(90),
    },
  ],
});

// RDS automated backups
const database = new rds.DatabaseInstance(this, 'Database', {
  // ... other props
  backupRetention: cdk.Duration.days(30),
  preferredBackupWindow: '03:00-04:00',
  deletionProtection: true,
});

// DynamoDB point-in-time recovery
const table = new dynamodb.Table(this, 'Table', {
  // ... other props
  pointInTimeRecovery: true,  // ✅ Continuous backups
});
```

#### 4. Health Checks and Circuit Breakers

```typescript
// Lambda with reserved concurrency (circuit breaker)
const lambda = new lambda.Function(this, 'Fn', {
  // ... other props
  reservedConcurrentExecutions: 10,  // Limit concurrent executions
  retryAttempts: 1,  // Fail fast
});

// ALB health check
const targetGroup = new elbv2.ApplicationTargetGroup(this, 'TG', {
  vpc,
  port: 80,
  healthCheck: {
    path: '/health',
    interval: cdk.Duration.seconds(30),
    timeout: cdk.Duration.seconds(5),
    healthyThresholdCount: 2,
    unhealthyThresholdCount: 3,
  },
});
```

---

## Performance Efficiency

**Principles:**
- Democratize advanced technologies
- Go global in minutes
- Use serverless architectures
- Experiment more often
- Consider mechanical sympathy

### CDK Implementation

#### 1. Right-Sized Lambda

```typescript
// Profile and optimize Lambda memory
const lambda = new lambda.Function(this, 'Processor', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda'),
  memorySize: 1024,  // ✅ Profiled optimal size
  timeout: cdk.Duration.seconds(10),
  architecture: lambda.Architecture.ARM_64,  // ✅ Graviton2 - 20% cheaper, better performance
});

// Enable Lambda Insights for profiling
lambda.addEnvironment('AWS_LAMBDA_EXEC_WRAPPER', '/opt/aws-lambda-insights-wrapper');
```

#### 2. Caching with CloudFront

```typescript
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';

const distribution = new cloudfront.Distribution(this, 'CDN', {
  defaultBehavior: {
    origin: origins.S3BucketOrigin.withOriginAccessControl(bucket),
    cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,  // ✅ Aggressive caching
    compress: true,  // ✅ Gzip compression
  },
  additionalBehaviors: {
    '/api/*': {
      origin: origins.HttpOrigin.fromLoadBalancerOrigin(alb),
      cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,  // API requests not cached
    },
  },
});
```

#### 3. DynamoDB Performance

```typescript
// Use on-demand billing for unpredictable workloads
const table = new dynamodb.Table(this, 'Table', {
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,  // ✅ Automatic scaling
});

// Or provisioned with auto-scaling for predictable workloads
const provisionedTable = new dynamodb.Table(this, 'ProvisionedTable', {
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PROVISIONED,
  readCapacity: 5,
  writeCapacity: 5,
});

provisionedTable.autoScaleReadCapacity({ minCapacity: 5, maxCapacity: 100 });
```

#### 4. Global Acceleration

```typescript
import * as globalaccelerator from 'aws-cdk-lib/aws-globalaccelerator';

const accelerator = new globalaccelerator.Accelerator(this, 'Accelerator', {
  enabled: true,
});

const listener = accelerator.addListener('Listener', {
  portRanges: [{ fromPort: 443 }],
});

listener.addEndpointGroup('Group', {
  endpoints: [
    new globalaccelerator_endpoints.ApplicationLoadBalancerEndpoint(alb),
  ],
});
```

---

## Cost Optimization

**Principles:**
- Implement cloud financial management
- Adopt a consumption model
- Measure overall efficiency
- Stop spending money on undifferentiated heavy lifting
- Analyze and attribute expenditure

### CDK Implementation

#### 1. Resource Tagging for Cost Allocation

```typescript
import { Tags } from 'aws-cdk-lib';

// Tag all resources in app
Tags.of(app).add('CostCenter', 'Engineering');
Tags.of(app).add('Project', 'MyProject');
Tags.of(app).add('Environment', 'Production');

// Custom tagging aspect
class CostAllocationTags implements IAspect {
  visit(node: IConstruct): void {
    if (node instanceof cdk.CfnResource) {
      Tags.of(node).add('ManagedBy', 'CDK');
      Tags.of(node).add('DeployedBy', process.env.USER || 'CI/CD');
    }
  }
}

Aspects.of(app).add(new CostAllocationTags());
```

#### 2. S3 Lifecycle Policies

```typescript
const bucket = new s3.Bucket(this, 'LogsBucket', {
  lifecycleRules: [
    {
      // Transition to cheaper storage classes
      transitions: [
        {
          storageClass: s3.StorageClass.INFREQUENT_ACCESS,
          transitionAfter: cdk.Duration.days(30),
        },
        {
          storageClass: s3.StorageClass.GLACIER,
          transitionAfter: cdk.Duration.days(90),
        },
      ],
      // Delete old logs
      expiration: cdk.Duration.days(365),
    },
    {
      // Clean up incomplete multipart uploads
      abortIncompleteMultipartUploadAfter: cdk.Duration.days(7),
    },
  ],
});
```

#### 3. Lambda Cost Optimization

```typescript
// Use ARM architecture (20% cheaper)
const lambda = new lambda.Function(this, 'Fn', {
  runtime: lambda.Runtime.NODEJS_20_X,
  architecture: lambda.Architecture.ARM_64,  // ✅ Graviton2
  memorySize: 512,  // ✅ Right-sized (not over-provisioned)
  timeout: cdk.Duration.seconds(5),  // ✅ Short timeout (fail fast)
});

// Avoid provisioned concurrency unless required (expensive)
// Only use for latency-sensitive workloads
```

#### 4. DynamoDB Cost Optimization

```typescript
// Use on-demand for low/unpredictable traffic
const onDemandTable = new dynamodb.Table(this, 'OnDemand', {
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
});

// Use provisioned for predictable traffic (cheaper at scale)
const provisionedTable = new dynamodb.Table(this, 'Provisioned', {
  partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PROVISIONED,
  readCapacity: 100,
  writeCapacity: 100,
});

// Enable time-to-live (TTL) to auto-delete expired items
provisionedTable.addGlobalSecondaryIndex({
  indexName: 'expiryIndex',
  partitionKey: { name: 'expiresAt', type: dynamodb.AttributeType.NUMBER },
});
```

#### 5. Remove Unused Resources

```typescript
// Stack termination protection
export class ProductionStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, {
      ...props,
      terminationProtection: true,  // ✅ Prevent accidental deletion
    });
  }
}

// Use cdk destroy to remove dev/test stacks
// Automate cleanup of ephemeral environments
```

---

## Well-Architected Checklist

### Operational Excellence
- [ ] Infrastructure defined as code (CDK)
- [ ] Automated testing (aws-cdk-lib/assertions)
- [ ] CI/CD pipeline (CDK Pipelines or GitHub Actions)
- [ ] Monitoring dashboards (CloudWatch)
- [ ] Alarms for critical metrics (CloudWatch Alarms)
- [ ] Runbooks documented (Stack outputs, README)

### Security
- [ ] cdk-nag security checks enabled
- [ ] Least privilege IAM policies
- [ ] Encryption at rest (KMS)
- [ ] Encryption in transit (TLS/HTTPS)
- [ ] Secrets in Secrets Manager (not env vars)
- [ ] CloudTrail enabled
- [ ] VPC with private subnets
- [ ] Security groups with minimal access

### Reliability
- [ ] Multi-AZ deployments
- [ ] Auto-scaling configured
- [ ] Backups enabled (RDS, DynamoDB PITR)
- [ ] Health checks configured
- [ ] Point-in-time recovery (DynamoDB)
- [ ] S3 versioning enabled
- [ ] Deletion protection on stateful resources

### Performance Efficiency
- [ ] Right-sized Lambda memory (profiled)
- [ ] ARM/Graviton architecture (Lambda, EC2)
- [ ] CloudFront caching configured
- [ ] DynamoDB auto-scaling or on-demand
- [ ] Connection pooling (Lambda)
- [ ] Compression enabled (CloudFront, API Gateway)

### Cost Optimization
- [ ] Resource tagging for cost allocation
- [ ] S3 lifecycle policies
- [ ] DynamoDB TTL enabled
- [ ] Unused resources removed
- [ ] Right-sized instances (not over-provisioned)
- [ ] Reserved capacity for predictable workloads
- [ ] Budget alarms configured

---

## Further Reading

- **Core skill**: `.claude/skills/cdk-scripting/skill.md`
- **Examples**: `.claude/skills/cdk-scripting/examples.md`
- **Tools**: `.claude/skills/cdk-scripting/tools.md`
- **Templates**: `.claude/skills/cdk-scripting/templates/`
- **AWS Well-Architected**: https://aws.amazon.com/architecture/well-architected/
