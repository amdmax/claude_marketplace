# CDK Scripting Best Practices

## Resource Management Strategy

**Stateful Resources** (Import, never recreate):
- User Pools, S3 Buckets, Databases, DynamoDB Tables
- Use: `.fromXxxId()`, `.fromXxxArn()`, `.fromBucketName()`

**Stateless Resources** (Create in CDK):
- Lambda Functions, IAM Roles, User Pool Clients, Domains
- Use: `new Resource()`

## Dynamic Resource References

### Created Resources (Like Terraform)
```typescript
const client = new cognito.UserPoolClient(this, 'Client', { userPool });
const lambda = new lambda.Function(this, 'Fn', {
  environment: {
    CLIENT_ID: client.userPoolClientId,  // ✅ Auto-updates
  }
});
```

### Imported Resources (Limited Properties)
```typescript
const userPool = cognito.UserPool.fromUserPoolId(this, 'Pool', 'us-east-1_ABC');

// ✅ Available: userPool.userPoolId, userPool.userPoolArn
// ❌ Not available: userPool.clients, userPool.domains

// Solution: Create children in CDK
const client = new cognito.UserPoolClient(this, 'Client', { userPool });
client.userPoolClientId;  // ✅ Now works
```

## Common Patterns

### Import Parent, Create Children
```typescript
// Import stateful parent
const userPool = cognito.UserPool.fromUserPoolId(this, 'Pool', 'us-east-1_ABC');

// Create stateless children that reference it
const client = new cognito.UserPoolClient(this, 'Client', { userPool });
const domain = userPool.addDomain('Domain', {
  cognitoDomain: { domainPrefix: 'my-app' }
});

// Reference properties
environment: {
  POOL_ID: userPool.userPoolId,
  CLIENT_ID: client.userPoolClientId,
  DOMAIN: domain.domainName,
}
```

### SSM for Dynamic Lookups
```typescript
// Store: aws ssm put-parameter --name /app/pool-id --value us-east-1_ABC
const poolId = ssm.StringParameter.valueFromLookup(this, '/app/pool-id');
const userPool = cognito.UserPool.fromUserPoolId(this, 'Pool', poolId);
```

### Custom Resource for Complex Lookups
```typescript
const lookup = new cr.AwsCustomResource(this, 'Lookup', {
  onUpdate: {
    service: 'CognitoIdentityServiceProvider',
    action: 'listUserPoolClients',
    parameters: { UserPoolId: userPool.userPoolId, MaxResults: 1 },
    physicalResourceId: cr.PhysicalResourceId.of('Lookup')
  },
  policy: cr.AwsCustomResourcePolicy.fromSdkCalls({
    resources: cr.AwsCustomResourcePolicy.ANY_RESOURCE
  })
});
const clientId = lookup.getResponseField('UserPoolClients.0.ClientId');
```

## Key Anti-Patterns

❌ **Don't hardcode derived IDs** - Create the resource in CDK instead
❌ **Don't import stateless resources** - Create them new
❌ **Don't recreate stateful resources** - Import existing ones

## Quick Reference

| Need to... | Use |
|------------|-----|
| Import User Pool | `UserPool.fromUserPoolId(id)` |
| Import S3 Bucket | `Bucket.fromBucketName(name)` |
| Import Certificate | `Certificate.fromCertificateArn(arn)` |
| Lookup with AWS call | `Vpc.fromLookup()` or Custom Resource |
| Reference property | `resource.property` (like Terraform) |
| Protect from deletion | `removalPolicy: cdk.RemovalPolicy.RETAIN` |
