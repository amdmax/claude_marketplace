# API Gateway + Lambda Pattern

## Overview

This template guides implementing REST APIs with AWS Lambda backend functions, Cognito authorization, and CORS configuration.

## When to Use

- Building REST APIs with serverless backend
- Implementing CRUD operations with Lambda
- User authentication with Cognito User Pools
- Cross-origin resource sharing (CORS) requirements

## Requirements Checklist

Before implementing, confirm:

- [ ] Cognito User Pool exists (if auth required)
- [ ] Lambda function code prepared
- [ ] API endpoints and methods defined
- [ ] CORS origins identified (e.g., `https://app.example.com`)
- [ ] IAM permissions for Lambda identified (DynamoDB, S3, etc.)
- [ ] Error handling strategy defined

## Implementation Pattern

### 1. Import Stateful Resources

```typescript
// Import existing Cognito User Pool (if using authentication)
const userPool = cognito.UserPool.fromUserPoolId(
  this,
  'UserPool',
  'us-east-1_ABC123'  // Replace with actual User Pool ID
);
```

### 2. Create Lambda Function

```typescript
const apiLambda = new lambda.Function(this, 'ApiLambda', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('../lambda/api/dist'),  // Pre-built code
  timeout: cdk.Duration.seconds(10),  // Adjust based on requirements (30s+ for VPC cold starts)
  memorySize: 256,  // Start conservative, profile and adjust
  environment: {
    USER_POOL_ID: userPool.userPoolId,  // ✅ Dynamic reference
    TABLE_NAME: 'my-table',  // Or reference DynamoDB table
    REGION: this.region,
  },
  description: 'API Lambda for handling requests',
});
```

### 3. Add IAM Permissions

**Principle of least privilege:** Grant only required actions on specific resources.

```typescript
// Example: DynamoDB permissions
// Assuming you have a DynamoDB table imported or created:
// const table = dynamodb.Table.fromTableName(this, 'Table', 'my-table');
apiLambda.addToRolePolicy(
  new iam.PolicyStatement({
    actions: [
      'dynamodb:GetItem',
      'dynamodb:PutItem',
      'dynamodb:UpdateItem',
      'dynamodb:DeleteItem',
      'dynamodb:Query',
    ],
    resources: [
      table.tableArn,  // ✅ Dynamic reference
      `${table.tableArn}/index/*`,  // ✅ GSI access
    ],
  })
);

// Example: Cognito permissions
apiLambda.addToRolePolicy(
  new iam.PolicyStatement({
    actions: [
      'cognito-idp:AdminListUsers',
      'cognito-idp:AdminGetUser',
      'cognito-idp:AdminUpdateUserAttributes',
    ],
    resources: [userPool.userPoolArn],
  })
);
```

### 4. Create REST API with CORS

```typescript
const api = new apigateway.RestApi(this, 'Api', {
  restApiName: 'My Application API',
  description: 'REST API for application backend',
  defaultCorsPreflightOptions: {
    allowOrigins: ['https://app.example.com'],  // Replace with actual origin(s)
    allowMethods: apigateway.Cors.ALL_METHODS,  // Or specific: ['GET', 'POST', 'PUT', 'DELETE']
    allowHeaders: ['Content-Type', 'Authorization'],  // Required for Cognito tokens
    allowCredentials: true,  // If using cookies
  },
  deployOptions: {
    stageName: 'prod',  // Or 'dev', 'staging'
    throttlingBurstLimit: 100,  // Max concurrent requests
    throttlingRateLimit: 50,    // Requests per second
    loggingLevel: apigateway.MethodLoggingLevel.INFO,
    dataTraceEnabled: true,  // Log request/response data (disable in prod if sensitive)
  },
});
```

### 5. Create Cognito Authorizer

```typescript
const authorizer = new apigateway.CognitoUserPoolsAuthorizer(this, 'Authorizer', {
  cognitoUserPools: [userPool],
  identitySource: 'method.request.header.Authorization',  // Default: Authorization header
});
```

### 6. Define API Resources and Methods

**Pattern:** Create resource hierarchy, attach Lambda integration to methods

```typescript
// Root resource: /api
const apiResource = api.root.addResource('api');

// /api/users
const users = apiResource.addResource('users');
users.addMethod('GET', new apigateway.LambdaIntegration(apiLambda), {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
  requestParameters: {
    'method.request.querystring.page': false,  // Optional query param
    'method.request.querystring.limit': false,
  },
});

users.addMethod('POST', new apigateway.LambdaIntegration(apiLambda), {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
  requestValidator: new apigateway.RequestValidator(this, 'RequestValidator', {
    restApi: api,
    validateRequestBody: true,
    validateRequestParameters: true,
  }),
  requestModels: {
    'application/json': new apigateway.Model(this, 'CreateUserModel', {
      restApi: api,
      contentType: 'application/json',
      schema: {
        type: apigateway.JsonSchemaType.OBJECT,
        required: ['email', 'name'],
        properties: {
          email: { type: apigateway.JsonSchemaType.STRING },
          name: { type: apigateway.JsonSchemaType.STRING },
        },
      },
    }),
  },
});

// /api/users/{userId}
const user = users.addResource('{userId}');
user.addMethod('GET', new apigateway.LambdaIntegration(apiLambda), {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
  requestParameters: {
    'method.request.path.userId': true,  // Required path param
  },
});

user.addMethod('PUT', new apigateway.LambdaIntegration(apiLambda), {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
});

user.addMethod('DELETE', new apigateway.LambdaIntegration(apiLambda), {
  authorizer,
  authorizationType: apigateway.AuthorizationType.COGNITO,
});

// /api/health (public endpoint, no auth)
const health = api.addResource('health');
health.addMethod('GET', new apigateway.LambdaIntegration(apiLambda), {
  authorizationType: apigateway.AuthorizationType.NONE,
});
```

### 7. Add Stack Outputs

```typescript
new cdk.CfnOutput(this, 'ApiUrl', {
  value: api.url,
  description: 'API Gateway URL',
  exportName: 'ApiUrl',  // For cross-stack references
});

new cdk.CfnOutput(this, 'ApiId', {
  value: api.restApiId,
  description: 'API Gateway ID',
});
```

## Lambda Function Structure

Your Lambda should handle multiple routes:

```typescript
// lambda/api/index.ts
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { httpMethod, resource, pathParameters, body } = event;

  console.log(`${httpMethod} ${resource}`, { pathParameters });

  try {
    // Route to appropriate handler
    if (resource === '/api/users' && httpMethod === 'GET') {
      return await listUsers(event);
    }

    if (resource === '/api/users' && httpMethod === 'POST') {
      return await createUser(event, JSON.parse(body || '{}'));
    }

    if (resource === '/api/users/{userId}' && httpMethod === 'GET') {
      return await getUser(pathParameters?.userId!);
    }

    // ... more routes

    return {
      statusCode: 404,
      body: JSON.stringify({ error: 'Not found' }),
      headers: { 'Content-Type': 'application/json' },
    };
  } catch (error) {
    console.error('Error:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Internal server error' }),
      headers: { 'Content-Type': 'application/json' },
    };
  }
};
```

## Alternative: AWS Solutions Constructs

For common patterns, use pre-built constructs:

```typescript
import * as solutions from '@aws-solutions-constructs/aws-apigateway-lambda';

const api = new solutions.ApiGatewayToLambda(this, 'Api', {
  lambdaFunctionProps: {
    runtime: lambda.Runtime.NODEJS_20_X,
    handler: 'index.handler',
    code: lambda.Code.fromAsset('lambda/api'),
    environment: {
      TABLE_NAME: 'my-table',
    },
  },
  apiGatewayProps: {
    defaultCorsPreflightOptions: {
      allowOrigins: ['https://app.example.com'],
    },
  },
});

// Automatically includes:
// - CloudWatch Logs
// - X-Ray tracing
// - Lambda error alarms
// - API Gateway access logs
```

## Testing Infrastructure

```typescript
import { Template, Match } from 'aws-cdk-lib/assertions';

test('Lambda has DynamoDB read permissions', () => {
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::IAM::Policy', {
    PolicyDocument: {
      Statement: Match.arrayWith([
        Match.objectLike({
          Action: Match.arrayWith(['dynamodb:GetItem']),
          Effect: 'Allow',
          Resource: Match.anyValue(),
        }),
      ]),
    },
  });
});

test('API has CORS configured', () => {
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::ApiGateway::Method', {
    HttpMethod: 'OPTIONS',  // CORS preflight
    AuthorizationType: 'NONE',
  });
});

test('API has Cognito authorizer', () => {
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::ApiGateway::Authorizer', {
    Type: 'COGNITO_USER_POOLS',
    ProviderARNs: Match.anyValue(),
  });
});
```

## Testing Checklist

Before deployment:

- [ ] `npm run cdk synth` passes without errors
- [ ] `npm run cdk diff` shows expected changes
- [ ] Infrastructure tests pass
- [ ] Lambda function builds successfully
- [ ] IAM permissions are least-privilege
- [ ] CORS origins are correct
- [ ] API throttling limits are appropriate

After deployment:

- [ ] Test public endpoints (e.g., /health) → 200 OK
- [ ] Test authenticated endpoints without token → 401 Unauthorized
- [ ] Test authenticated endpoints with valid token → 200 OK
- [ ] Test CORS preflight (OPTIONS request) → correct headers
- [ ] Check CloudWatch Logs for Lambda invocations
- [ ] Verify X-Ray traces (if enabled)
- [ ] Load test API (e.g., with `artillery` or `k6`)

## Common Issues

### Issue: CORS errors in browser console
**Cause:** Missing CORS headers or incorrect origin
**Fix:** Verify `allowOrigins` matches exact origin (including protocol and port)

### Issue: 401 Unauthorized with valid token
**Cause:** Token from wrong User Pool or expired
**Fix:** Verify authorizer uses correct User Pool, check token expiration

### Issue: 403 Forbidden from Lambda
**Cause:** Missing IAM permissions
**Fix:** Add required permissions to Lambda role (check CloudWatch Logs for "AccessDenied")

### Issue: Lambda timeout errors
**Cause:** Cold start, slow dependencies, or database queries
**Fix:** Increase timeout, optimize code, use provisioned concurrency

### Issue: API throttling errors (429 Too Many Requests)
**Cause:** Exceeded burst or rate limits
**Fix:** Increase throttling limits or implement client-side retry with exponential backoff

## Security Best Practices

1. ✅ Use Cognito authorizer for authentication
2. ✅ Validate all input (use request validators)
3. ✅ Implement least-privilege IAM permissions
4. ✅ Enable API Gateway access logs
5. ✅ Use HTTPS only (no HTTP)
6. ✅ Set throttling limits to prevent abuse
7. ✅ Don't log sensitive data (tokens, passwords)
8. ✅ Use WAF for additional protection (optional)

## Performance Optimization

- **Lambda memory:** Profile with CloudWatch Insights, increase if CPU-bound
- **Connection pooling:** Reuse database connections across invocations
- **Provisioned concurrency:** Eliminate cold starts for critical APIs
- **Caching:** Use API Gateway caching for GET requests
- **Compression:** Enable gzip compression for large responses

## Cost Optimization

- **Lambda pricing:** $0.20 per 1M requests + $0.0000166667 per GB-second
- **API Gateway pricing:** $3.50 per million requests (first 333M)
- **Data transfer:** $0.09 per GB out to internet
- **Optimization tips:**
  - Right-size Lambda memory (not too high)
  - Use reserved concurrency sparingly
  - Cache responses when possible
  - Batch operations to reduce API calls

## Further Reading

- Real implementation: `infrastructure/lib/admin-stack.ts`
- CDK core skill: `.claude/skills/cdk-scripting/skill.md`
- AWS Solutions Constructs: https://docs.aws.amazon.com/solutions/latest/constructs/aws-apigateway-lambda.html
