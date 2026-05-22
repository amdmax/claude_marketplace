# Test Generation (Phase 5)

## Test Requirements

Generate **minimum 3 tests** (`config.yaml` → `tests.min_test_count`):

1. **Bug Reproduction Test** - MUST fail before fix, pass after
2. **Edge Case Tests** - Boundary conditions
3. **Regression Protection** - Non-buggy paths still work

See `@references/test-generation-guide.md` for general patterns.

## Test Location

```bash
# Check for existing test file
find . -path "*<module>*" -name "*.test.ts"
find . -path "*<module>*" -path "*__tests__*"

# Read jest.config.js or vitest.config.ts for patterns
```

**Naming convention:**
- `src/auth/token.ts` → `src/auth/__tests__/token.test.ts`
- `src/auth/token.ts` → `src/auth/token.test.ts`

## Test Structure

```typescript
describe('Bug #<issue>: <title>', () => {
  // 1. REPRODUCTION TEST (CRITICAL)
  it('should <expected-behavior> <specific-scenario>', () => {
    const input = <bug-triggering-input>;
    const result = functionUnderTest(input);
    expect(result).toBe(<correct-value>);
  });

  // 2. EDGE CASES
  describe('Edge cases', () => {
    it('should handle boundary condition 1', () => { ... });
    it('should handle boundary condition 2', () => { ... });
  });

  // 3. REGRESSION PROTECTION
  describe('Regression protection', () => {
    it('should maintain working behavior 1', () => { ... });
    it('should maintain working behavior 2', () => { ... });
  });
});
```

**Example (token expiration):**
```typescript
describe('Bug #123: Token expiration off-by-one error', () => {
  it('should reject token at exact expiration time', () => {
    const now = Date.now();
    const token = createToken({ exp: now });
    expect(validateToken(token)).toBe(false);
  });

  describe('Edge cases', () => {
    it('should reject token 1ms after expiration', () => {
      expect(validateToken(createToken({ exp: Date.now() - 1 }))).toBe(false);
    });
    it('should accept token 1ms before expiration', () => {
      expect(validateToken(createToken({ exp: Date.now() + 1 }))).toBe(true);
    });
  });

  describe('Regression protection', () => {
    it('should accept valid future token', () => {
      expect(validateToken(createToken({ exp: Date.now() + 3600000 }))).toBe(true);
    });
  });
});
```

## Test Validation (CRITICAL)

**MANDATORY:** Tests must be validated fail-before/pass-after (`config.yaml` → `tests.validate_before_after: true`).

```bash
git stash                                          # stash fix
git checkout HEAD~1                                # pre-fix state
npm test -- path/to/test-file.test.ts             # MUST FAIL
git checkout - && git stash pop                    # restore fix
npm test -- path/to/test-file.test.ts             # MUST PASS
npm test                                           # no regressions
```

### Recording Tests

```bash
hypothesis-tracker.py set-tests \
  "<test-file-paths>" \
  "<description>" \
  <test-count>

hypothesis-tracker.py mark-tests-validated
```

Sets `validated: true`, transitions phase to `commit_and_pr`, status to `fixed`.

### Validation Failure

If tests **pass before fix** (don't reproduce bug):

```
🛑 BLOCKED: Cannot proceed without validated regression tests
```

Review: reproduction test logic, exact bug conditions, assertion tests CORRECT behavior. **DO NOT PROCEED** until resolved.
