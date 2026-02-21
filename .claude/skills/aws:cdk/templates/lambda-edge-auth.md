# Lambda@Edge Authentication Pattern

## Overview

This template guides implementing Lambda@Edge functions for CloudFront authentication using Cognito User Pools with OAuth 2.0 authorization code flow.

## When to Use

- Protecting CloudFront distributions with user authentication
- Implementing OAuth 2.0 flows at edge locations
- Cognito-based authentication for static sites
- Authorization before content delivery

## Requirements Checklist

Before implementing, confirm:

- [ ] Cognito User Pool exists (stateful resource to import)
- [ ] CloudFront distribution domain and certificate ready
- [ ] OAuth callback URLs defined (e.g., `https://domain.com/callback`)
- [ ] Logout URLs defined (e.g., `https://domain.com/`)
- [ ] Lambda function code prepared with esbuild bundling
- [ ] Understanding of Lambda@Edge constraints (no env vars, 1MB limit, replication delays)

## Implementation Pattern

### 1. Import Stateful Resources

```typescript
// Import existing Cognito User Pool
const userPool = cognito.UserPool.fromUserPoolId(
  this,
  'UserPool',
  'us-east-1_ABC123'  // Replace with actual User Pool ID
);

// Import existing S3 bucket for content
const contentBucket = s3.Bucket.fromBucketName(
  this,
  'ContentBucket',
  'my-content-bucket'  // Replace with actual bucket name
);

// Import existing certificate (must be in us-east-1 for CloudFront)
const certificate = acm.Certificate.fromCertificateArn(
  this,
  'Certificate',
  'arn:aws:acm:us-east-1:123456789012:certificate/...'
);
```

### 2. Create User Pool Client for OAuth

```typescript
const userPoolClient = new cognito.UserPoolClient(this, 'UserPoolClient', {
  userPool,
  generateSecret: false,  // Public client for browser-based auth
  authFlows: {
    userPassword: true,
    userSrp: true,
  },
  oAuth: {
    flows: {
      authorizationCodeGrant: true,  // OAuth 2.0 authorization code flow
    },
    scopes: [
      cognito.OAuthScope.OPENID,
      cognito.OAuthScope.EMAIL,
      cognito.OAuthScope.PROFILE,
    ],
    callbackUrls: ['https://your-domain.com/callback'],  // Replace with actual URL
    logoutUrls: ['https://your-domain.com/'],  // Replace with actual URL
  },
});
```

### 3. Create Cognito Domain

```typescript
const cognitoDomain = userPool.addDomain('UserPoolDomain', {
  cognitoDomain: {
    domainPrefix: 'my-app-auth',  // Replace with unique prefix
  },
});
```

### 4. Create Lambda@Edge Function with Build-Time Config

**CRITICAL:** Lambda@Edge does not support environment variables. Use build-time config injection.

```typescript
const authEdgeFunction = new cloudfront.experimental.EdgeFunction(this, 'AuthEdgeFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('../lambda/auth-edge', {
    assetHashType: cdk.AssetHashType.OUTPUT,  // Hash based on output, not source
    bundling: {
      image: lambda.Runtime.NODEJS_20_X.bundlingImage,
      command: ['echo', 'This should not run - using local bundling'],
      local: {
        tryBundle(outputDir: string) {
          const { execSync } = require('child_process');
          const path = require('path');
          const fs = require('fs');

          const lambdaDir = path.join(__dirname, '../../lambda/auth-edge');

          // Install dependencies and build with esbuild (bundles all deps into single file)
          execSync('npm install && npm run build', {
            cwd: lambdaDir,
            stdio: 'inherit',
          });

          // Copy bundled output
          const bundledFile = path.join(lambdaDir, 'dist/index.js');
          execSync(`cp ${bundledFile} ${outputDir}/`, { stdio: 'inherit' });

          // ⚠️ CRITICAL: Use LITERAL STRINGS, not CDK tokens
          // CDK tokens (like userPoolClient.userPoolClientId) won't resolve here
          // because bundling happens at synthesis time, tokens resolve at deployment time
          const config = {
            USER_POOL_ID: 'us-east-1_ABC123',  // ✅ Replace with actual ID (literal string)
            CLIENT_ID: '6d7261tcnso7dlj',      // ✅ Replace with actual ID (literal string)
            COGNITO_DOMAIN: 'my-app-auth',      // ✅ Replace with actual domain prefix
            // CLIENT_ID: userPoolClient.userPoolClientId,  // ❌ Won't work - CDK token!
          };
          fs.writeFileSync(
            path.join(outputDir, 'config.json'),
            JSON.stringify(config)
          );

          return true;  // ✅ Local bundling succeeded
        },
      },
    },
  }),
});
```

### 5. Create CloudFront Distribution

```typescript
const distribution = new cloudfront.Distribution(this, 'Distribution', {
  defaultBehavior: {
    origin: origins.S3BucketOrigin.withOriginAccessControl(contentBucket),
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    edgeLambdas: [
      {
        functionVersion: authEdgeFunction.currentVersion,
        eventType: cloudfront.LambdaEdgeEventType.VIEWER_REQUEST,  // Auth before cache
      },
    ],
  },
  domainNames: ['your-domain.com'],  // Replace with actual domain
  certificate,
});
```

### 6. Grant S3 Access to CloudFront

For **imported buckets**, use `CfnBucketPolicy` (not `addToResourcePolicy()`):

```typescript
new s3.CfnBucketPolicy(this, 'BucketPolicy', {
  bucket: contentBucket.bucketName,
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
        Resource: `${contentBucket.bucketArn}/*`,
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

### 7. Add Stack Outputs with Sync Warnings

```typescript
new cdk.CfnOutput(this, 'UserPoolClientId', {
  value: userPoolClient.userPoolClientId,
  description: 'Cognito User Pool Client ID',
});

new cdk.CfnOutput(this, 'CognitoDomain', {
  value: `my-app-auth.auth.us-east-1.amazoncognito.com`,  // Replace with actual
  description: 'Cognito Domain for OAuth',
});

// IMPORTANT: Warn about config sync requirement
new cdk.CfnOutput(this, 'LambdaEdgeConfigSyncRequired', {
  value: 'IMPORTANT: Verify Lambda@Edge config matches these outputs',
  description: `Lambda@Edge bundled config CLIENT_ID (6d7261tcnso7dlj) must match UserPoolClientId output. Update stack line 122 if they differ.`,
});
```

## Lambda@Edge Code Structure

Your `lambda/auth-edge/index.ts` should:

1. Load config from bundled `config.json` (not env vars)
2. Parse CloudFront viewer request
3. Check for authentication cookies
4. If unauthenticated, redirect to Cognito hosted UI
5. If callback request, exchange code for tokens
6. Set secure HttpOnly cookies
7. Allow authenticated requests through

**Recommended package:** `cognito-at-edge` (27 lines) instead of custom implementation (700+ lines)

```typescript
// lambda/auth-edge/index.ts
import { Authenticator } from 'cognito-at-edge';
import config from './config.json';

const authenticator = new Authenticator({
  region: 'us-east-1',
  userPoolId: config.USER_POOL_ID,
  userPoolAppId: config.CLIENT_ID,
  userPoolDomain: `${config.COGNITO_DOMAIN}.auth.us-east-1.amazoncognito.com`,
});

export const handler = authenticator.handle;
```

## Lambda@Edge esbuild Configuration

Your `lambda/auth-edge/package.json`:

```json
{
  "scripts": {
    "build": "esbuild index.ts --bundle --platform=node --target=node20 --outfile=dist/index.js --external:aws-sdk"
  },
  "dependencies": {
    "cognito-at-edge": "^1.0.0"
  },
  "devDependencies": {
    "esbuild": "^0.19.0"
  }
}
```

## Testing Checklist

Before deployment:

- [ ] `npm run cdk synth` passes without errors
- [ ] `npm run cdk diff` shows expected changes
- [ ] Lambda function size < 1MB (check CloudFormation template)
- [ ] config.json has literal string values (not CDK tokens)
- [ ] Stack outputs match config.json values
- [ ] OAuth callback URLs match CloudFront domain
- [ ] Certificate is in us-east-1 region

After deployment:

- [ ] Visit CloudFront URL → redirects to Cognito login
- [ ] Login with test user → redirects to callback → authenticated
- [ ] Check CloudFront access logs for auth requests
- [ ] Verify cookies are set (HttpOnly, Secure)
- [ ] Test logout flow

## Common Issues

### Issue: Lambda@Edge returns 503
**Cause:** Missing node_modules in deployment package
**Fix:** Use esbuild with `--bundle` flag to include all dependencies

### Issue: Config values are CDK tokens like "${Token[...]}"
**Cause:** Using `userPoolClient.userPoolClientId` in tryBundle closure
**Fix:** Use literal string values in config.json, add sync warning outputs

### Issue: CloudFront returns 403 Access Denied
**Cause:** Missing S3 bucket policy for Origin Access Control
**Fix:** Use `CfnBucketPolicy` for imported buckets (see step 6)

### Issue: Lambda@Edge won't delete during stack rollback
**Cause:** Edge replicas take 2-4 hours to clean up
**Fix:** Add `removalPolicy: cdk.RemovalPolicy.RETAIN`, delete manually later

## Security Best Practices

1. ✅ Use OAuth 2.0 authorization code flow (not implicit flow)
2. ✅ Set `generateSecret: false` for public clients (SPA)
3. ✅ Use HttpOnly, Secure cookies for tokens
4. ✅ Implement CSRF protection
5. ✅ Validate token signatures
6. ✅ Use short-lived access tokens
7. ✅ Don't log sensitive data (tokens, cookies)

## Cost Optimization

- **Lambda@Edge pricing:** $0.60 per 1M requests + $0.00005001 per GB-second
- **CloudFront pricing:** $0.085 per GB transfer + $0.0075 per 10,000 HTTPS requests
- **Consider CloudFront Functions** for URL rewriting (6x cheaper, but no external API calls)

## Further Reading

- Real implementation: `infrastructure/lib/ai-assisted-coding-stack.ts:84-136`
- Lessons learned: `infrastructure/ISSUES_FIXED.md`
- CDK core skill: `.claude/skills/cdk-scripting/skill.md` section 5
