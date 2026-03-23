# S3 + CloudFront Static Site Pattern

## Overview

This template guides implementing static website hosting using S3 for content storage and CloudFront CDN for global content delivery with HTTPS.

## When to Use

- Static website hosting (HTML, CSS, JS)
- Single-page applications (React, Vue, Angular)
- Documentation sites
- Marketing landing pages

## Requirements Checklist

Before implementing, confirm:

- [ ] Domain name and DNS hosting (Route53 or external)
- [ ] SSL/TLS certificate in us-east-1 (CloudFront requirement)
- [ ] S3 bucket name (unique globally)
- [ ] Content build process defined
- [ ] Deployment mechanism planned (AWS CLI, GitHub Actions, etc.)

## Implementation Pattern

### 1. Import or Create S3 Bucket

```typescript
import * as s3 from 'aws-cdk-lib/aws-s3';

// Option A: Import existing bucket (stateful resource)
const contentBucket = s3.Bucket.fromBucketName(
  this,
  'ContentBucket',
  'my-existing-bucket'
);

// Option B: Create new bucket
const contentBucket = new s3.Bucket(this, 'ContentBucket', {
  bucketName: 'my-website-content',  // Must be globally unique
  versioned: true,  // ✅ Protect against accidental deletion
  removalPolicy: cdk.RemovalPolicy.RETAIN,  // ✅ Don't delete on stack destroy
  autoDeleteObjects: false,  // ✅ Manual cleanup required
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,  // ✅ Use CloudFront OAC instead
  encryption: s3.BucketEncryption.S3_MANAGED,  // ✅ Encrypt at rest
});
```

### 2. Import Certificate (Must be in us-east-1)

```typescript
import * as acm from 'aws-cdk-lib/aws-certificatemanager';

// CloudFront requires certificates in us-east-1
const certificate = acm.Certificate.fromCertificateArn(
  this,
  'Certificate',
  'arn:aws:acm:us-east-1:123456789012:certificate/...'  // Replace with actual ARN
);
```

### 3. Create CloudFront Distribution

```typescript
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';

const distribution = new cloudfront.Distribution(this, 'Distribution', {
  defaultBehavior: {
    origin: origins.S3BucketOrigin.withOriginAccessControl(contentBucket),  // ✅ Use OAC (not OAI)
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,  // ✅ Force HTTPS
    cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,  // ✅ Aggressive caching for static content
    compress: true,  // ✅ Gzip compression
  },
  defaultRootObject: 'index.html',  // Root path → index.html
  domainNames: ['www.example.com'],  // Replace with actual domain
  certificate,
  errorResponses: [
    {
      // SPA routing: redirect 404 to index.html
      httpStatus: 404,
      responseHttpStatus: 200,
      responsePagePath: '/index.html',
      ttl: cdk.Duration.minutes(5),
    },
    {
      // Handle 403 errors (S3 permission denied)
      httpStatus: 403,
      responseHttpStatus: 200,
      responsePagePath: '/index.html',
      ttl: cdk.Duration.minutes(5),
    },
  ],
  priceClass: cloudfront.PriceClass.PRICE_CLASS_100,  // Use only North America and Europe edge locations
  httpVersion: cloudfront.HttpVersion.HTTP2_AND_3,  // ✅ HTTP/2 and HTTP/3 support
  minimumProtocolVersion: cloudfront.SecurityPolicyProtocol.TLS_V1_2_2021,  // ✅ Modern TLS only
});
```

### 4. CloudFront Function for URL Rewriting (Optional)

For nested directory index.html serving (e.g., `/about/` → `/about/index.html`):

```typescript
const urlRewriteFunction = new cloudfront.Function(this, 'UrlRewriteFunction', {
  code: cloudfront.FunctionCode.fromInline(`
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Append index.html to directory paths
      if (uri.endsWith('/')) {
        request.uri += 'index.html';
      } else if (!uri.includes('.')) {
        // Paths without extension (e.g., /about) → /about/index.html
        request.uri += '/index.html';
      }

      return request;
    }
  `),
});

const distribution = new cloudfront.Distribution(this, 'Distribution', {
  defaultBehavior: {
    // ... other props
    functionAssociations: [
      {
        function: urlRewriteFunction,
        eventType: cloudfront.FunctionEventType.VIEWER_REQUEST,
      },
    ],
  },
});
```

### 5. Grant CloudFront Access to S3

**Important:** The method you use depends on whether the bucket is imported or created in CDK.

#### For Imported Buckets (Use CfnBucketPolicy)

**Why:** Imported buckets don't support `addToResourcePolicy()` - it will fail with "Cannot add resource policy to imported bucket."

```typescript
// ✅ REQUIRED for imported buckets (from step 1, Option A)
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

#### For Created Buckets (Use addToResourcePolicy)

**Why:** Buckets created in CDK support the simpler `addToResourcePolicy()` method.

```typescript
// ✅ WORKS for buckets created in CDK (from step 1, Option B)
contentBucket.addToResourcePolicy(
  new iam.PolicyStatement({
    actions: ['s3:GetObject'],
    resources: [`${contentBucket.bucketArn}/*`],
    principals: [new iam.ServicePrincipal('cloudfront.amazonaws.com')],
    conditions: {
      StringEquals: {
        'AWS:SourceArn': `arn:aws:cloudfront::${this.account}:distribution/${distribution.distributionId}`,
      },
    },
  })
);
```

**See also:** `.claude/skills/cdk-scripting/examples.md` section "S3 Bucket Policy for Imported Buckets" for detailed explanation.

### 6. Create Route53 DNS Record

```typescript
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';

// Option A: fromLookup (requires AWS credentials at synth time)
// ⚠️ May fail in CI/CD without proper credentials
// Use for local development or when AWS credentials are available
const hostedZone = route53.HostedZone.fromLookup(this, 'HostedZone', {
  domainName: 'example.com',  // Replace with actual domain
});

// Option B: fromHostedZoneAttributes (recommended for CI/CD)
// ✅ No AWS API calls needed, works in all environments
// const hostedZone = route53.HostedZone.fromHostedZoneAttributes(this, 'HostedZone', {
//   hostedZoneId: 'Z1234567890ABC',  // Get from AWS Console or SSM
//   zoneName: 'example.com',
// });

// Create alias record pointing to CloudFront
new route53.ARecord(this, 'AliasRecord', {
  zone: hostedZone,
  recordName: 'www',  // www.example.com
  target: route53.RecordTarget.fromAlias(new targets.CloudFrontTarget(distribution)),
});
```

### 7. Add Stack Outputs

```typescript
new cdk.CfnOutput(this, 'BucketName', {
  value: contentBucket.bucketName,
  description: 'S3 bucket for website content',
});

new cdk.CfnOutput(this, 'DistributionId', {
  value: distribution.distributionId,
  description: 'CloudFront distribution ID',
});

new cdk.CfnOutput(this, 'DistributionDomainName', {
  value: distribution.distributionDomainName,
  description: 'CloudFront domain name (for testing)',
});

new cdk.CfnOutput(this, 'WebsiteUrl', {
  value: 'https://www.example.com',  // Replace with actual URL
  description: 'Website URL',
});

new cdk.CfnOutput(this, 'DeployCommand', {
  value: `aws s3 sync ./output s3://${contentBucket.bucketName}/ --delete`,
  description: 'Command to deploy content to S3',
});

new cdk.CfnOutput(this, 'InvalidateCacheCommand', {
  value: `aws cloudfront create-invalidation --distribution-id ${distribution.distributionId} --paths "/*"`,
  description: 'Command to invalidate CloudFront cache',
});
```

## Alternative: AWS Solutions Constructs

For pre-configured setup:

```typescript
import * as cloudfrontS3 from '@aws-solutions-constructs/aws-cloudfront-s3';

const site = new cloudfrontS3.CloudFrontToS3(this, 'Site', {
  insertHttpSecurityHeaders: true,  // Add security headers automatically
  bucketProps: {
    versioned: true,
    encryption: s3.BucketEncryption.S3_MANAGED,
  },
  cloudFrontDistributionProps: {
    domainNames: ['www.example.com'],
    certificate,
    priceClass: cloudfront.PriceClass.PRICE_CLASS_100,
  },
});
```

## Deployment Workflow

### Initial Deployment

```bash
# 1. Build website
npm run build  # Output to ./output or ./dist

# 2. Deploy CDK stack
cd "$CLAUDE_PROJECT_DIR/infrastructure" || {
  echo "❌ Failed to change to infrastructure directory"
  exit 1
}
npm run cdk deploy

# 3. Upload content to S3
aws s3 sync ../output s3://my-website-content/ --delete

# 4. (Optional) Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id E1234567890ABC --paths "/*"
```

### CI/CD with GitHub Actions

```yaml
name: Deploy Website

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Build website
        run: npm install && npm run build

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Deploy to S3
        run: |
          aws s3 sync ./output s3://${{ secrets.BUCKET_NAME }}/ --delete

      - name: Invalidate CloudFront cache
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ secrets.DISTRIBUTION_ID }} \
            --paths "/*"
```

## Testing Checklist

Before deployment:

- [ ] `npm run cdk synth` passes without errors
- [ ] `npm run cdk diff` shows expected changes
- [ ] Certificate is in us-east-1 region
- [ ] Bucket name is globally unique
- [ ] Domain matches certificate

After deployment:

- [ ] Visit CloudFront domain → site loads
- [ ] Visit custom domain → site loads
- [ ] Check HTTPS certificate (green padlock)
- [ ] Test nested paths (e.g., /about/)
- [ ] Test SPA routing (if applicable)
- [ ] Check browser DevTools → files served from CloudFront
- [ ] Verify cache headers (Cache-Control, ETag)

## Common Issues

### Issue: 403 Access Denied from CloudFront
**Cause:** Missing S3 bucket policy for CloudFront OAC
**Fix:** Use `CfnBucketPolicy` for imported buckets (see step 5)

### Issue: 404 on nested paths
**Cause:** CloudFront defaultRootObject only works for root path
**Fix:** Use CloudFront Function for URL rewriting (see step 4)

### Issue: SPA routing broken (404 on refresh)
**Cause:** CloudFront returns 404 for non-existent S3 objects
**Fix:** Add error response redirecting 404 → /index.html (see step 3)

### Issue: Certificate validation failed
**Cause:** Certificate not in us-east-1 or domain mismatch
**Fix:** Create certificate in us-east-1, ensure domain matches

### Issue: Changes not appearing
**Cause:** CloudFront cache TTL
**Fix:** Invalidate cache: `aws cloudfront create-invalidation --distribution-id ID --paths "/*"`

## Security Best Practices

1. ✅ Use Origin Access Control (OAC), not Origin Access Identity (OAI) - newer, more secure
2. ✅ Block public access on S3 bucket - CloudFront handles access
3. ✅ Use HTTPS only (no HTTP)
4. ✅ Use modern TLS protocol (TLSv1.2_2021 or newer)
5. ✅ Enable S3 versioning for rollback capability
6. ✅ Add security headers with CloudFront Functions or Lambda@Edge

## Performance Optimization

- **Cache policy:** Use CACHING_OPTIMIZED for static content
- **Compression:** Enable gzip compression
- **HTTP/2 and HTTP/3:** Enable for faster page loads
- **Price class:** Select edge locations closest to users
- **Invalidation strategy:** Invalidate only changed files (not `/*`)

## Cost Optimization

- **CloudFront pricing:** $0.085 per GB transfer (first 10 TB)
- **S3 pricing:** $0.023 per GB storage + $0.0004 per 1K GET requests
- **Price class:** Use PRICE_CLASS_100 (NA + EU) if users primarily in those regions
- **Cache effectively:** Longer TTL = fewer origin requests = lower S3 costs
- **S3 lifecycle:** Archive old versions to Glacier

## Further Reading

- Real implementation: `infrastructure/lib/ai-assisted-coding-stack.ts`
- CDK core skill: `.claude/skills/cdk-scripting/skill.md`
- AWS Solutions Constructs: https://docs.aws.amazon.com/solutions/latest/constructs/aws-cloudfront-s3.html
