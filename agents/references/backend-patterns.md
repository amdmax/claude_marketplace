# Backend Implementation Patterns

## CDK Resource Patterns

- **Import stateful resources** (User Pools, S3 buckets, certificates) via `fromXxxAttributes()`
  - Example: `UserPool.fromUserPoolId()`, `Bucket.fromBucketName()`
- **Create stateless resources** (Lambda functions, IAM roles, CloudFront distributions)
- Never use `fromLookup()` for User Pools or S3 — use explicit IDs/ARNs
- Exception: Route53 `fromLookup()` is acceptable in this project

## Lambda@Edge Constraints

- **No environment variables** at runtime (Lambda@Edge restriction)
- Bundle config as JSON during CDK build using `local.tryBundle()`
- Size limit: < 1MB for viewer-request/response functions
- All dependencies must be bundled (no external requires)

## Local Bundling

Prefer local bundling to avoid Docker dependency:
- Use `local.tryBundle()` — faster builds, no Docker required
- Include error handling in bundling (try-catch, path verification)
- Fallback to Docker bundling if local fails

## IAM Best Practices

- Least privilege: specific actions, not wildcards
- Resource ARNs explicitly defined
- Source constraints on permissions (sourceArn, sourceAccount)
- Service principals properly scoped

## Integration Test Commands

```bash
cd infrastructure && npm test
cd infrastructure && npm run cdk synth
```

Iterate until integration tests pass. CDK synth must also pass before marking complete.
