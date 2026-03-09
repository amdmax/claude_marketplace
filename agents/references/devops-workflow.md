# DevOps Workflow

## Step 1: Read the Brief

Read `.agile-dev-team/development-progress.yaml`:
- `teamState.implementationBrief.filesToChange` — determine what changed (frontend vs backend vs both)
- `teamState.branchName` — confirm we are on the correct branch

## Step 2: Build Artifacts

Based on what changed:
- Frontend changes (`src/**`, `content/**`): `npm run build:catalog`
- Full site changes: `npm run build`
- Infrastructure-only: skip build step (CDK deployed separately)

If build fails: message PM with error output. Stop.

## Step 3: Check CDK Deployment Status

If `infrastructure/**` files changed, verify CDK stack is deployed:
```bash
aws cloudformation describe-stacks --stack-name AcademyCatalogStack --query 'Stacks[0].StackStatus'
```

If stack status is not `UPDATE_COMPLETE` or `CREATE_COMPLETE`, message PM:
```
CDK stack not deployed. Requires Deploy Manual workflow with deploy_infrastructure:true.
```
Stop.

## Step 4: Sync to S3

```bash
aws s3 sync output-catalog/ s3://aigensa-academy-catalog-677622587505/ --delete
```

Capture sync output (file count, bytes transferred).

## Step 5: Invalidate CloudFront

```bash
DIST_ID=$(aws cloudformation describe-stacks --stack-name AcademyCatalogStack \
  --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' --output text)

aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/*"
```

Capture invalidation ID.

## Step 6: Verify Live Environment

Wait 60 seconds for invalidation to propagate, then verify:
```bash
curl -s -o /dev/null -w "%{http_code}" http://academy.aigensa.com   # expect 301/302
curl -s -o /dev/null -w "%{http_code}" https://academy.aigensa.com  # expect 200
curl -s -I https://academy.aigensa.com | grep -i 'x-cache\|cloudfront\|age'
```

## Step 7: Record Result

Write to `.agile-dev-team/development-progress.yaml`:
```json
{
  "teamState": {
    "deploymentResult": {
      "syncFileCount": 42,
      "invalidationId": "INVALIDATION_ID",
      "verificationStatus": "pass",
      "verifiedAt": "2026-01-01T00:00:00Z"
    }
  }
}
```

## Step 8: Report to PM

Message PM with: sync file count, invalidation ID, and HTTP status codes from verification.

Mark Task 7 complete via TaskUpdate.
