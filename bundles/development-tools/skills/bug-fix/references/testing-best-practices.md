# Testing Best Practices for Bug Fixes

## Test Structure Patterns

### AAA Pattern (Arrange-Act-Assert)

```typescript
it('should reject expired tokens', () => {
  // Arrange: Set up test data
  const expiredToken = createToken({ exp: Date.now() - 1000 });

  // Act: Execute the code under test
  const result = validateToken(expiredToken);

  // Assert: Verify expected outcome
  expect(result).toBe(false);
});
```

### Given-When-Then (BDD Style)

```typescript
describe('Token validation', () => {
  describe('given an expired token', () => {
    describe('when validating', () => {
      it('then should return false', () => {
        // Test implementation
      });
    });
  });
});
```

## Coverage Requirements for Bug Fixes

### Minimum Coverage

1. **Reproduction case** - Exact scenario from bug report
2. **Edge case before bug** - Boundary just before failure
3. **Edge case after bug** - Boundary just after failure
4. **Happy path** - Ensure fix doesn't break normal operation

### Example: Off-by-One Bug

```typescript
describe('Array indexing bug fix', () => {
  // Reproduction case
  it('should not throw when accessing last element', () => {
    const arr = [1, 2, 3];
    expect(() => arr[arr.length - 1]).not.toThrow();
  });

  // Edge before
  it('should access second-to-last element correctly', () => {
    const arr = [1, 2, 3];
    expect(arr[arr.length - 2]).toBe(2);
  });

  // Edge after
  it('should return undefined for out-of-bounds', () => {
    const arr = [1, 2, 3];
    expect(arr[arr.length]).toBeUndefined();
  });

  // Happy path
  it('should access first element correctly', () => {
    const arr = [1, 2, 3];
    expect(arr[0]).toBe(1);
  });
});
```

## Test Naming Conventions

### Descriptive Names

**Good:**
```typescript
it('should reject tokens with expiration timestamp before current time')
it('should throw ValidationError when email format is invalid')
it('should return empty array when no matching records found')
```

**Bad:**
```typescript
it('works correctly')
it('test expiration')
it('handles errors')
```

### Including Bug Number

```typescript
describe('Bug #123: Token expiration validation', () => {
  // Tests specific to this bug fix
});
```

## Mocking Strategies

### Mock External Dependencies

```typescript
jest.mock('./api', () => ({
  fetchUser: jest.fn()
}));

it('should handle API failure gracefully', async () => {
  const { fetchUser } = require('./api');
  fetchUser.mockRejectedValue(new Error('Network error'));

  const result = await getUserData('123');

  expect(result).toBeNull();
});
```

### Mock Time for Time-Dependent Bugs

```typescript
describe('Bug #156: Date comparison', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2024-01-15T12:00:00Z'));
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('should correctly identify expired items', () => {
    const item = { expiresAt: new Date('2024-01-15T11:59:59Z') };
    expect(isExpired(item)).toBe(true);
  });
});
```

## Async Testing

### Promises

```typescript
it('should resolve with data on success', async () => {
  await expect(fetchData()).resolves.toEqual({ data: 'value' });
});

it('should reject with error on failure', async () => {
  await expect(fetchData()).rejects.toThrow('Not found');
});
```

### Callbacks

```typescript
it('should call callback with result', (done) => {
  processData((err, result) => {
    expect(err).toBeNull();
    expect(result).toBe('success');
    done();
  });
});
```

## Integration Tests for Bug Fixes

### End-to-End Validation

```typescript
describe('Bug #201: Upload flow crash', () => {
  it('should complete full upload flow without crashing', async () => {
    // Simulate complete user flow
    const file = createTestFile();
    const uploadResult = await initiateUpload(file);
    const processResult = await processUpload(uploadResult.id);
    const finalStatus = await checkStatus(processResult.id);

    expect(finalStatus).toBe('completed');
  });
});
```

### Database Integration

```typescript
describe('Bug #178: Duplicate entries', () => {
  beforeEach(async () => {
    await db.clean();
  });

  it('should prevent duplicates in database', async () => {
    const user1 = await createUser({ email: 'test@example.com' });

    await expect(createUser({ email: 'test@example.com' }))
      .rejects.toThrow();

    const users = await db.user.findMany();
    expect(users).toHaveLength(1);
  });
});
```

## Performance Testing for Bug Fixes

### Timing Assertions

```typescript
it('should complete within acceptable time', async () => {
  const start = performance.now();
  await processLargeDataset();
  const duration = performance.now() - start;

  expect(duration).toBeLessThan(1000); // < 1 second
});
```

### Memory Leak Detection

```typescript
it('should not leak memory on repeated calls', async () => {
  const before = process.memoryUsage().heapUsed;

  for (let i = 0; i < 1000; i++) {
    await processItem(i);
  }

  global.gc(); // Requires --expose-gc flag
  const after = process.memoryUsage().heapUsed;
  const increase = after - before;

  expect(increase).toBeLessThan(10 * 1024 * 1024); // < 10MB
});
```

## Test Data Management

### Fixtures

```typescript
// fixtures/users.ts
export const validUser = {
  email: 'valid@example.com',
  name: 'Valid User',
  age: 25
};

export const invalidUser = {
  email: 'not-an-email',
  name: '',
  age: -1
};

// In test
import { validUser, invalidUser } from './fixtures/users';

it('should accept valid user', () => {
  expect(validateUser(validUser)).toBe(true);
});
```

### Factory Functions

```typescript
function createUser(overrides = {}) {
  return {
    id: Math.random().toString(),
    email: 'user@example.com',
    name: 'Test User',
    createdAt: new Date(),
    ...overrides
  };
}

it('should handle user with custom email', () => {
  const user = createUser({ email: 'custom@example.com' });
  expect(user.email).toBe('custom@example.com');
});
```

## Regression Test Maintenance

### Document Test Purpose

```typescript
/**
 * Regression test for Bug #123
 *
 * Issue: Tokens were accepted 1 second after expiration
 * Root cause: Used > instead of >= for comparison
 * Fix: Changed to >= in src/auth.ts:45
 *
 * This test ensures tokens are rejected at exact expiration time.
 */
it('should reject token at exact expiration timestamp', () => {
  const token = createToken({ exp: Date.now() });
  expect(validateToken(token)).toBe(false);
});
```

### Group Related Tests

```typescript
describe('Token Validation - Bug #123', () => {
  describe('expiration edge cases', () => {
    it('should reject at exact expiration');
    it('should reject after expiration');
    it('should accept before expiration');
  });

  describe('timestamp edge cases', () => {
    it('should handle epoch 0');
    it('should handle far future dates');
    it('should handle negative timestamps');
  });
});
```

## Common Pitfalls

### ❌ Testing Implementation Instead of Behavior

```typescript
// Bad - tests internal implementation
it('should call validateEmail function', () => {
  const spy = jest.spyOn(validator, 'validateEmail');
  createUser({ email: 'test@example.com' });
  expect(spy).toHaveBeenCalled();
});

// Good - tests behavior
it('should reject user with invalid email format', () => {
  expect(() => createUser({ email: 'not-an-email' }))
    .toThrow('Invalid email format');
});
```

### ❌ Over-Mocking

```typescript
// Bad - mocks too much, tests nothing real
jest.mock('./database');
jest.mock('./validator');
jest.mock('./logger');
jest.mock('./cache');

// Good - only mock external boundaries
jest.mock('./database'); // External I/O
// Test actual validator, logger, cache logic
```

### ❌ Brittle Assertions

```typescript
// Bad - breaks if message wording changes
expect(error.message).toBe('Invalid email: test@example.com is not valid');

// Good - checks for essential content
expect(error.message).toContain('Invalid email');
expect(error.message).toContain('test@example.com');
```

### ❌ Missing Async/Await

```typescript
// Bad - test passes before async completes
it('should save user', () => {
  saveUser(user); // Missing await
  const saved = getUser(user.id);
  expect(saved).toEqual(user);
});

// Good
it('should save user', async () => {
  await saveUser(user);
  const saved = await getUser(user.id);
  expect(saved).toEqual(user);
});
```
