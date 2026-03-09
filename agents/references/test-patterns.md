# Test Patterns Reference

## Discovering Existing Patterns

Before writing tests:
1. Check `jest.config.ts` for test project structure (unit, integration, e2e project names)
2. Study 2-3 existing test files for mocking patterns, setup/teardown conventions, assertion styles
3. Match the naming convention of existing test files (`{feature-name}.test.ts` or `test-{feature-name}.js`)

## Per-Contract Test Structure

For each interface contract in the implementation brief, write:

1. **Happy path:** Test the expected successful behavior with valid inputs
2. **Error paths:** Test validation failures, service errors, missing required fields
3. **Corner cases:** Null inputs, empty strings, boundary values, concurrent access

## Test Type Guidance

| Test type | Location | When to write |
|-----------|----------|---------------|
| Unit | `tests/unit/` | Pure function logic, TypeScript builders, template output |
| Integration | `tests/integration/` | Lambda handlers with mocked AWS SDK calls |
| E2E / Build | `tests/e2e/` or `npm run test:mobile` | Full site build output, mobile viewport checks |

## Confirming RED

Run the appropriate test suite after writing:
```bash
jest                              # unit tests
cd infrastructure && npm test     # integration tests
npm run test:mobile               # e2e/build tests
```

Tests must fail because the implementation doesn't exist — NOT because of syntax errors or bad imports. Fix test-side issues until they fail cleanly for the right reason.
