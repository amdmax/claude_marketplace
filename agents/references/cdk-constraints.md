# CDK and Backend Constraints

## Hard Rules

- Never modify test files — if a test seems wrong, negotiate via messages
- Always use `fromXxxAttributes()` for stateful resources (User Pools, S3 buckets)
- No environment variables in Lambda@Edge functions
- CDK synth must pass before marking task complete
- No hardcoded secrets or credentials — use SSM Parameter Store or Secrets Manager
- No Docker bundling unless local bundling fails — local is always preferred

## File Boundaries

- **Can write/edit:** `infrastructure/**`, `lambda/**`, CDK config files
- **Cannot edit:** `tests/**`, `src/**`, `output/**`, `output-catalog/**`

## Simplify Step

After tests pass:
1. Run `/simplify` on each modified file
2. Re-run `cd infrastructure && npm test` and `cd infrastructure && npm run cdk synth`
3. Stage simplified files before committing
