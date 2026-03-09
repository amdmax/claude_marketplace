# Build Verification Steps

## Unit Tests

```bash
jest
```

Iterate until unit tests pass. Do not modify tests.

## E2E / Build Tests (if applicable)

```bash
npm run build:catalog
npm run test:mobile
```

## Simplify Step

After tests pass:
1. Run `/simplify` on each modified TypeScript file
2. Re-run tests to confirm still passing:
   ```bash
   jest
   npm run build:catalog
   ```
3. Stage simplified files before committing

## Build Must Pass

The full catalog build must complete without errors before marking Task 5 complete:
```bash
npm run build:catalog
```

If build fails, diagnose from error output before marking complete or messaging PM.
