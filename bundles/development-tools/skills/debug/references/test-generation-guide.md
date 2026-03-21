# Test Generation Guide

Comprehensive guide for creating regression tests that prevent bug recurrence, including patterns, validation procedures, and examples.

## Core Principle

**CRITICAL:** Tests are MANDATORY for all bug fixes. They must:
1. **Reproduce the bug** (fail before fix)
2. **Pass after fix** (validate fix works)
3. **Prevent recurrence** (catch if bug reintroduced)

## Test Types Required

### 1. Bug Reproduction Test (MANDATORY)

The most critical test that **must fail** before the fix and **must pass** after.

**Purpose:**
- Proves the bug existed
- Validates the fix works
- Documents the exact failure scenario

**Pattern:**
```typescript
describe('Bug #<issue-number>: <bug-title>', () => {
  it('should <expected-behavior> <specific-scenario>', () => {
    // ARRANGE: Set up the exact conditions that trigger the bug
    const input = <exact-bug-triggering-input>;

    // ACT: Perform the action that exposed the bug
    const result = functionUnderTest(input);

    // ASSERT: Verify expected behavior (not buggy behavior)
    expect(result).toBe(<expected-value>);
  });
});
```

**Example (Token Expiration Bug):**
```typescript
describe('Bug #123: Token expiration off-by-one error', () => {
  it('should reject token at exact expiration time', () => {
    // ARRANGE: Create token that expires at exactly now
    const now = Date.now();
    const token = createToken({ exp: now });

    // ACT: Validate the token
    const isValid = validateToken(token);

    // ASSERT: Should be invalid (rejected)
    expect(isValid).toBe(false);
  });
});
```

### 2. Edge Case Tests

Tests that cover boundary conditions related to the bug.

**Purpose:**
- Ensure fix handles edge cases
- Prevent similar bugs at boundaries
- Document expected behavior at limits

**Pattern:**
```typescript
it('should <expected-behavior> <edge-case-description>', () => {
  // Test boundary conditions:
  // - Minimum values
  // - Maximum values
  // - Zero/empty values
  // - Just before/after threshold
  // - Negative values (if applicable)
});
```

**Example (Token Expiration Edge Cases):**
```typescript
describe('Edge cases', () => {
  it('should reject token 1 millisecond after expiration', () => {
    const now = Date.now();
    const token = createToken({ exp: now - 1 });
    expect(validateToken(token)).toBe(false);
  });

  it('should accept token 1 millisecond before expiration', () => {
    const now = Date.now();
    const token = createToken({ exp: now + 1 });
    expect(validateToken(token)).toBe(true);
  });

  it('should handle expiration at epoch 0', () => {
    const token = createToken({ exp: 0 });
    expect(validateToken(token)).toBe(false);
  });

  it('should handle far future expiration', () => {
    const token = createToken({ exp: Date.now() + 1000000000 });
    expect(validateToken(token)).toBe(true);
  });
});
```

### 3. Regression Protection Tests

Tests that verify non-buggy paths still work correctly after the fix.

**Purpose:**
- Ensure fix didn't break existing functionality
- Document working scenarios
- Catch over-corrections

**Pattern:**
```typescript
describe('Regression protection', () => {
  it('should <maintain-existing-behavior> <normal-scenario>', () => {
    // Test that normal, non-buggy cases still work
  });
});
```

**Example (Token Validation Regression):**
```typescript
describe('Regression protection', () => {
  it('should accept valid token with future expiration', () => {
    const token = createToken({ exp: Date.now() + 3600000 });
    expect(validateToken(token)).toBe(true);
  });

  it('should reject token with past expiration', () => {
    const token = createToken({ exp: Date.now() - 3600000 });
    expect(validateToken(token)).toBe(false);
  });

  it('should handle missing token gracefully', () => {
    expect(validateToken(null)).toBe(false);
    expect(validateToken(undefined)).toBe(false);
  });
});
```

## Test Location Strategy

### Finding Existing Test Files

```bash
# Common test patterns
find . -name "*.test.ts" -o -name "*.spec.ts"
find . -path "*/__tests__/*"
find . -path "*/test/*"

# Check jest/test config for patterns
# Read: jest.config.js, vitest.config.ts, etc.
```

### Naming Conventions

Follow project patterns:
- `<file>.test.ts` - Test file alongside source
- `__tests__/<file>.test.ts` - Tests in __tests__ directory
- `test/<file>.spec.ts` - Tests in test directory

**Example:**
```
src/auth/token.ts          → src/auth/__tests__/token.test.ts
src/auth/token.ts          → src/auth/token.test.ts
lib/validators/email.ts    → lib/validators/__tests__/email.test.ts
```

### Creating New Test Files

If no test file exists:

1. **Check project patterns** - Read existing test files
2. **Follow conventions** - Match directory structure and naming
3. **Include necessary imports** - Copy from similar tests
4. **Set up test environment** - Match existing test setup

**Template:**
```typescript
import { describe, it, expect } from '@jest/globals'; // or 'vitest'
import { functionUnderTest } from '../module-under-test';

describe('ModuleName', () => {
  describe('Bug #<issue>: <title>', () => {
    // Bug reproduction test
    it('should ...', () => {
      // Test implementation
    });

    // Edge cases
    describe('Edge cases', () => {
      // Edge case tests
    });

    // Regression protection
    describe('Regression protection', () => {
      // Regression tests
    });
  });
});
```

## Mock/Spy Patterns

### When to Mock

- **External Dependencies** - APIs, databases, file systems
- **Time-Dependent Code** - Date.now(), setTimeout
- **Random Behavior** - Math.random(), crypto
- **Side Effects** - Logging, network calls

### Common Mocking Patterns

#### Mocking Time
```typescript
describe('Time-dependent tests', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-02-02T12:00:00Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('should handle expiration correctly', () => {
    const now = Date.now(); // Returns mocked time
    const token = createToken({ exp: now });
    expect(validateToken(token)).toBe(false);
  });
});
```

#### Mocking Functions
```typescript
describe('Function mocking', () => {
  it('should call dependency correctly', () => {
    const mockFn = jest.fn().mockReturnValue(true);
    const result = functionUnderTest(mockFn);

    expect(mockFn).toHaveBeenCalledWith(expectedArg);
    expect(result).toBe(expectedValue);
  });
});
```

#### Spying on Methods
```typescript
describe('Method spying', () => {
  it('should call internal method', () => {
    const spy = jest.spyOn(object, 'method');

    object.doSomething();

    expect(spy).toHaveBeenCalled();
    spy.mockRestore();
  });
});
```

## Validation Procedure (CRITICAL)

Tests **must** be validated using fail-before/pass-after verification.

### Step-by-Step Validation

#### 1. Stash Current Changes
```bash
# Save current work including fix
git add .
git stash
```

#### 2. Checkout Pre-Fix State
```bash
# Go back to commit before fix
git checkout HEAD~1

# Or checkout specific commit
git log --oneline -n 5
git checkout <commit-hash>
```

#### 3. Run Tests - MUST FAIL
```bash
# Run only the new test file
npm test -- path/to/test-file.test.ts

# Or run specific test
npm test -- -t "should reject token at exact expiration"
```

**Expected:** Bug reproduction test FAILS (proves bug existed)

**Example Output:**
```
FAIL  src/auth/__tests__/token.test.ts
  ✕ should reject token at exact expiration time (5ms)

  expect(received).toBe(expected)

  Expected: false
  Received: true
```

#### 4. Return to Fixed State
```bash
# Return to fixed code
git checkout -

# Restore stashed changes
git stash pop
```

#### 5. Run Tests - MUST PASS
```bash
# Run the same tests again
npm test -- path/to/test-file.test.ts
```

**Expected:** All tests PASS (proves fix works)

**Example Output:**
```
PASS  src/auth/__tests__/token.test.ts
  ✓ should reject token at exact expiration time (3ms)
  ✓ should reject token 1ms after expiration (2ms)
  ✓ should accept token 1ms before expiration (2ms)
```

#### 6. Run Full Test Suite
```bash
# Ensure no regressions
npm test

# Or full coverage
npm run test:coverage
```

**Expected:** All tests pass, no regressions introduced

### Recording Validation

After successful validation:

```bash
.claude/skills/debug/scripts/hypothesis-tracker.py mark-tests-validated
```

This:
- Sets `validated: true`
- Adds `validatedAt` timestamp
- Transitions phase to `commit_and_pr`

### Validation Failures

If tests **pass before fix**, they don't reproduce the bug:

```
🛑 BLOCKED: Cannot proceed without validated regression tests

Issue: Tests passed before fix (don't reproduce bug)

Possible causes:
- Test doesn't trigger the exact bug condition
- Test assertion is wrong (testing buggy behavior, not correct)
- Fix was applied to wrong location

Action required:
1. Review bug reproduction test
2. Ensure test triggers exact scenario from bug report
3. Verify test expects CORRECT behavior (not buggy)
```

## Test Structure Best Practices

### Arrange-Act-Assert (AAA) Pattern
```typescript
it('should do something', () => {
  // ARRANGE: Set up test data and conditions
  const input = createInput();
  const expected = calculateExpected();

  // ACT: Perform the action being tested
  const result = functionUnderTest(input);

  // ASSERT: Verify the result
  expect(result).toBe(expected);
});
```

### Descriptive Test Names
```typescript
// ❌ Bad: Vague, unclear what's being tested
it('works', () => { ... });
it('test token', () => { ... });

// ✅ Good: Clear, specific, explains expected behavior
it('should reject token at exact expiration time', () => { ... });
it('should accept token 1ms before expiration', () => { ... });
```

### Single Assertion Focus
```typescript
// ❌ Bad: Multiple unrelated assertions
it('validates tokens', () => {
  expect(validateToken(validToken)).toBe(true);
  expect(validateToken(expiredToken)).toBe(false);
  expect(validateToken(null)).toBe(false);
  expect(parseToken(validToken)).toEqual(parsed);
});

// ✅ Good: Each test focuses on one behavior
it('should accept valid token', () => {
  expect(validateToken(validToken)).toBe(true);
});

it('should reject expired token', () => {
  expect(validateToken(expiredToken)).toBe(false);
});

it('should reject null token', () => {
  expect(validateToken(null)).toBe(false);
});
```

### Test Data Clarity
```typescript
// ❌ Bad: Magic numbers, unclear purpose
it('validates expiration', () => {
  const token = { exp: 1234567890 };
  expect(validateToken(token)).toBe(false);
});

// ✅ Good: Clear test data with context
it('should reject token expired 1 hour ago', () => {
  const oneHourAgo = Date.now() - (60 * 60 * 1000);
  const expiredToken = { exp: oneHourAgo };
  expect(validateToken(expiredToken)).toBe(false);
});
```

## Example: Complete Test File

```typescript
import { describe, it, expect, beforeEach } from '@jest/globals';
import { validateToken, createToken } from '../token';

describe('Token Validation', () => {
  describe('Bug #123: Token expiration off-by-one error', () => {
    // Bug reproduction test (CRITICAL)
    it('should reject token at exact expiration time', () => {
      const now = Date.now();
      const token = createToken({ exp: now });

      const isValid = validateToken(token);

      expect(isValid).toBe(false);
    });

    describe('Edge cases', () => {
      it('should reject token 1ms after expiration', () => {
        const now = Date.now();
        const token = createToken({ exp: now - 1 });
        expect(validateToken(token)).toBe(false);
      });

      it('should accept token 1ms before expiration', () => {
        const now = Date.now();
        const token = createToken({ exp: now + 1 });
        expect(validateToken(token)).toBe(true);
      });

      it('should handle expiration at epoch 0', () => {
        const token = createToken({ exp: 0 });
        expect(validateToken(token)).toBe(false);
      });

      it('should handle far future expiration', () => {
        const farFuture = Date.now() + (365 * 24 * 60 * 60 * 1000);
        const token = createToken({ exp: farFuture });
        expect(validateToken(token)).toBe(true);
      });
    });

    describe('Regression protection', () => {
      it('should accept valid token with future expiration', () => {
        const oneHourFromNow = Date.now() + (60 * 60 * 1000);
        const token = createToken({ exp: oneHourFromNow });
        expect(validateToken(token)).toBe(true);
      });

      it('should reject token expired 1 hour ago', () => {
        const oneHourAgo = Date.now() - (60 * 60 * 1000);
        const token = createToken({ exp: oneHourAgo });
        expect(validateToken(token)).toBe(false);
      });

      it('should handle missing expiration field', () => {
        const token = createToken({ exp: undefined });
        expect(validateToken(token)).toBe(false);
      });

      it('should handle null token', () => {
        expect(validateToken(null)).toBe(false);
      });
    });
  });
});
```

## Minimum Test Count

Per `config.yaml`, minimum 3 test cases required:
1. **At least 1** bug reproduction test
2. **At least 1** edge case test
3. **At least 1** regression protection test

**Recommended:** 4-8 tests total for thorough coverage.
