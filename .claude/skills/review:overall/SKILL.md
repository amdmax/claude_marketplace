---
name: overall-review
description: Code quality, bug detection, and maintainability review
---

# Overall Code Review

## Overview

Comprehensive code quality analysis covering readability, maintainability, common bugs, test coverage, and best practices. Use this skill before committing to ensure code meets project standards and follows TypeScript/AWS CDK conventions.

**Focus Areas:** Code quality, logic bugs, maintainability, test coverage, TypeScript best practices, project-specific standards (CLAUDE.md).

## Workflow

### 1. Get Changed Files

```bash
git diff --name-only HEAD
# Or for staged files: git diff --cached --name-only
# Or compare branches: git diff --name-only master...HEAD
```

### 2. Analyze Each File

For each changed file:
1. **Read** to understand code structure and logic
2. **Calculate metrics** - function length, complexity, nesting depth
3. **Check patterns** - common bug patterns, anti-patterns, violations
4. **Verify tests** - corresponding test file exists and covers new code
5. **Review standards** - follows CLAUDE.md project guidelines

### 3. Report Findings

**Format (matches CI/CD):**

```
🔴 CRITICAL | 🟠 MAJOR | 🟡 MINOR

File: path/to/file.ts
Line(s): 42-45
Problem: [Issue description with impact on maintainability/correctness]
Fix: [REQUIRED for CRITICAL/MAJOR] - Refactored code example
```

**Severity Assignment:**

- **🔴 CRITICAL**: Logic bugs causing incorrect behavior, data corruption, or crashes
- **🟠 MAJOR**: Maintainability issues, code duplication, missing error handling, no tests for new functionality
- **🟡 MINOR**: Style/readability improvements, minor refactoring opportunities

### 4. Summary

```
Total code quality issues: X (CRITICAL: Y, MAJOR: Z, MINOR: W)
Files reviewed: N
Test coverage: [adequate/gaps identified/missing]
Code complexity: [acceptable/needs refactoring]

⚠️ Critical findings must be fixed before commit.
```

## Code Quality Checklist

### 1. Logic Bugs

#### Null/Undefined Handling

**Pattern Search:**
```
\.\w+\(.*\)(?!.*\?)(?!.*&&)(?!.*null)
\[.*\](?!.*\?)
req\.(query|body|params)\.\w+(?!.*\?)
```

**Check for:**
- [ ] Accessing properties without null checks
- [ ] Array access without bounds checking
- [ ] Optional chaining not used where appropriate
- [ ] Missing default values in destructuring

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: Crash if user undefined
function getUserEmail(userId: number) {
  const user = findUser(userId); // May return undefined
  return user.email.toLowerCase(); // TypeError!
}

// FIX: Proper null handling
function getUserEmail(userId: number): string | null {
  const user = findUser(userId);
  return user?.email.toLowerCase() ?? null;
}
```

#### Off-by-One Errors

**Check for:**
- [ ] Loop conditions with `<=` when should be `<`
- [ ] Array slicing with incorrect indices
- [ ] Pagination calculations (page * limit vs (page-1) * limit)

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: Off-by-one error
function getLastNItems<T>(arr: T[], n: number): T[] {
  return arr.slice(arr.length - n + 1); // Wrong! Skips one item
}

// FIX: Correct slicing
function getLastNItems<T>(arr: T[], n: number): T[] {
  return arr.slice(-n); // Or: arr.slice(arr.length - n)
}
```

#### Type Coercion Issues

**Pattern Search:**
```
==(?!=)
!=(?!=)
\+.*req\.(query|body)
if\s*\(\w+\)(?!.*===)
```

**Check for:**
- [ ] Using `==` instead of `===`
- [ ] Implicit type coercion in comparisons
- [ ] Unintended string concatenation (e.g., `"5" + 5 = "55"`)
- [ ] Truthy/falsy confusion (`0`, `""`, `[]`, `{}` behavior)

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Type coercion bug
function isAdult(age: string) {
  return age >= 18; // "5" >= 18 is false, but "100" >= 18 is TRUE (string comparison!)
}

// FIX: Explicit conversion
function isAdult(age: string): boolean {
  const numAge = parseInt(age, 10);
  return !isNaN(numAge) && numAge >= 18;
}
```

#### Race Conditions

**Pattern Search:**
```
let.*=.*await
async.*for.*await.*{
setTimeout.*async
```

**Check for:**
- [ ] Shared state modified in async operations
- [ ] Missing locks on concurrent access
- [ ] Async operations assuming sequential execution
- [ ] TOCTOU (Time-of-Check-Time-of-Use) bugs

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: Race condition
let balance = 1000;

async function withdraw(amount: number) {
  if (balance >= amount) { // Check
    await delay(100); // Simulate async operation
    balance -= amount; // Use - another withdraw could happen in between!
  }
}

// FIX: Atomic operation or locking
import { Mutex } from 'async-mutex';
const mutex = new Mutex();
let balance = 1000;

async function withdraw(amount: number) {
  const release = await mutex.acquire();
  try {
    if (balance >= amount) {
      await delay(100);
      balance -= amount;
    }
  } finally {
    release();
  }
}
```

### 2. Maintainability

#### Function Length

**Metrics:**
- [ ] Functions over 50 lines (consider splitting)
- [ ] Functions over 100 lines (🟠 MAJOR - definitely split)
- [ ] Single function doing multiple unrelated things

**🟠 MAJOR Pattern:**
```typescript
// TOO LONG: 150+ lines doing validation, DB access, email, logging
function createUser(data: UserInput) {
  // 30 lines of validation
  // 40 lines of database operations
  // 30 lines of email sending
  // 20 lines of logging
  // 30 lines of error handling
}

// FIX: Split into focused functions
function createUser(data: UserInput) {
  validateUserInput(data);
  const user = saveUserToDatabase(data);
  sendWelcomeEmail(user);
  logUserCreation(user);
  return user;
}
```

#### Cyclomatic Complexity

**Metrics:**
- [ ] Functions with 10+ decision points (if/else/switch/ternary/&&/||)
- [ ] Deeply nested conditionals (4+ levels)

**Pattern Search:**
```
if.*if.*if.*if.*{
switch.*case.*case.*case.*case.*case.*case.*case.*case.*case.*case
```

**🟠 MAJOR Example:**
```typescript
// TOO COMPLEX: Cyclomatic complexity = 15+
function calculatePrice(item: Item, user: User, promo?: Promo) {
  if (user.isPremium) {
    if (item.category === 'electronics') {
      if (item.price > 1000) {
        if (promo && promo.type === 'percentage') {
          // Nested 4 levels deep...
        }
      }
    }
  }
  // More nested conditions...
}

// FIX: Early returns and helper functions
function calculatePrice(item: Item, user: User, promo?: Promo): number {
  const basePrice = item.price;
  const userDiscount = getUserDiscount(user, item);
  const promoDiscount = getPromoDiscount(promo, item);
  return basePrice * (1 - userDiscount) * (1 - promoDiscount);
}
```

#### Code Duplication (DRY Violations)

**Check for:**
- [ ] Identical or near-identical code blocks
- [ ] Same logic with different variable names
- [ ] Copy-pasted functions with minor variations

**🟠 MAJOR Example:**
```typescript
// DUPLICATED: Same logic for users and posts
async function getUserById(id: number) {
  const result = await db.query('SELECT * FROM users WHERE id = ?', [id]);
  if (!result) throw new Error('User not found');
  return result;
}

async function getPostById(id: number) {
  const result = await db.query('SELECT * FROM posts WHERE id = ?', [id]);
  if (!result) throw new Error('Post not found');
  return result;
}

// FIX: Generic function
async function getById<T>(table: string, id: number, entityName: string): Promise<T> {
  const result = await db.query(`SELECT * FROM ${table} WHERE id = ?`, [id]);
  if (!result) throw new Error(`${entityName} not found`);
  return result as T;
}

const getUserById = (id: number) => getById<User>('users', id, 'User');
const getPostById = (id: number) => getById<Post>('posts', id, 'Post');
```

#### Magic Numbers and Strings

**Pattern Search:**
```
===\s*['"](?!true|false|null|undefined)['"]\s*\)
[^a-zA-Z_][0-9]{2,}[^0-9.a-zA-Z_]
setTimeout\(.*\d{3,}
```

**Check for:**
- [ ] Hardcoded numbers without explanation
- [ ] String literals used multiple times
- [ ] Configuration values in code instead of constants

**🟡 MINOR Example:**
```typescript
// UNCLEAR: Magic numbers
if (user.age >= 18 && user.accountAge >= 90 && user.posts >= 10) {
  grantBadge(user);
}

// CLEAR: Named constants
const ADULT_AGE = 18;
const VETERAN_ACCOUNT_DAYS = 90;
const MIN_POSTS_FOR_BADGE = 10;

if (user.age >= ADULT_AGE &&
    user.accountAge >= VETERAN_ACCOUNT_DAYS &&
    user.posts >= MIN_POSTS_FOR_BADGE) {
  grantBadge(user);
}
```

### 3. Error Handling

#### Unhandled Promises

**Pattern Search:**
```
async function.*{(?!.*try).*await
\.then\(.*\)(?!.*\.catch)
Promise\.all\((?!.*catch)
```

**Check for:**
- [ ] `async` functions without try-catch
- [ ] Promise chains without `.catch()`
- [ ] Fire-and-forget promises (no await or error handling)

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Unhandled rejection
async function updateUser(id: number, data: UserData) {
  const user = await db.users.findById(id); // May throw
  await user.update(data); // May throw
  return user;
}

// FIX: Proper error handling
async function updateUser(id: number, data: UserData): Promise<User> {
  try {
    const user = await db.users.findById(id);
    if (!user) {
      throw new Error(`User ${id} not found`);
    }
    await user.update(data);
    return user;
  } catch (error) {
    logger.error('Failed to update user', { id, error });
    throw new Error(`Failed to update user: ${error.message}`);
  }
}
```

#### Error Swallowing

**Pattern Search:**
```
catch.*{\s*}
catch.*{.*console\.(log|error).*}(?!.*throw)
catch.*{.*return\s*(null|undefined|false).*}
```

**Check for:**
- [ ] Empty catch blocks
- [ ] Catching and logging but not rethrowing or handling
- [ ] Returning fallback values silently masking errors

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Silent failure
async function getUser(id: number) {
  try {
    return await db.users.findById(id);
  } catch (e) {
    console.log('Error:', e); // Logged but caller doesn't know it failed!
    return null;
  }
}

// FIX: Rethrow or return Result type
async function getUser(id: number): Promise<User> {
  try {
    return await db.users.findById(id);
  } catch (error) {
    logger.error('Database error fetching user', { id, error });
    throw new DatabaseError(`Failed to fetch user ${id}`, { cause: error });
  }
}

// Or use Result type for expected failures
type Result<T, E = Error> = { success: true; value: T } | { success: false; error: E };

async function getUser(id: number): Promise<Result<User>> {
  try {
    const user = await db.users.findById(id);
    return { success: true, value: user };
  } catch (error) {
    logger.error('Database error fetching user', { id, error });
    return { success: false, error: error as Error };
  }
}
```

#### Missing Input Validation

**Check for:**
- [ ] No validation on user input before processing
- [ ] Assuming data from external sources is valid
- [ ] Missing boundary checks (string length, array size, number range)

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: No validation
app.post('/api/users', (req, res) => {
  const user = createUser(req.body); // What if body is malformed?
  res.json(user);
});

// FIX: Validate with schema
import { z } from 'zod';

const UserSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
});

app.post('/api/users', (req, res) => {
  const result = UserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ error: result.error });
  }
  const user = createUser(result.data);
  res.json(user);
});
```

### 4. TypeScript Best Practices

#### Type Safety Issues

**Pattern Search:**
```
as any
@ts-ignore
@ts-expect-error(?!.*TODO)
: any(?!\.\.\.args)
```

**Check for:**
- [ ] Using `any` type (disables type checking)
- [ ] `@ts-ignore` or `@ts-expect-error` without justification
- [ ] Type assertions (`as`) that could hide bugs
- [ ] Loose types when stricter types available

**🟠 MAJOR Example:**
```typescript
// BAD: Disables type safety
function processData(data: any) {
  return data.value.toUpperCase(); // No type checking!
}

// GOOD: Proper typing
interface DataWithValue {
  value: string;
}

function processData(data: DataWithValue): string {
  return data.value.toUpperCase();
}

// Or use generics for flexibility
function processData<T extends { value: string }>(data: T): string {
  return data.value.toUpperCase();
}
```

#### Missing Return Types

**Pattern Search:**
```
function \w+\([^)]*\)\s*{(?!.*:)
const \w+\s*=\s*\([^)]*\)\s*=>(?!.*:)
async function \w+\([^)]*\)\s*{(?!.*Promise)
```

**Check for:**
- [ ] Functions without explicit return types
- [ ] Async functions not returning `Promise<T>`
- [ ] Relying on type inference for public APIs

**🟡 MINOR Example:**
```typescript
// UNCLEAR: Return type inferred
function calculateTotal(items) {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// CLEAR: Explicit types
function calculateTotal(items: Item[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}
```

#### Non-null Assertions

**Pattern Search:**
```
!\.
!\[
!\s*;
```

**Check for:**
- [ ] Non-null assertion operator (`!`) used without justification
- [ ] Could use optional chaining (`?.`) instead

**🟡 MINOR Example:**
```typescript
// RISKY: Assumes user exists
const email = user!.email;

// SAFER: Handle null case
const email = user?.email ?? 'no-email@example.com';

// Or throw explicit error
if (!user) {
  throw new Error('User is required');
}
const email = user.email;
```

### 5. Test Coverage

#### Missing Tests for New Code

**Check for:**
- [ ] New functions without corresponding test file
- [ ] New API endpoints without integration tests
- [ ] Complex logic without unit tests
- [ ] Edge cases not tested (empty arrays, null values, boundary conditions)

**🟠 MAJOR Pattern:**
```typescript
// NEW FUNCTION in src/utils/validator.ts
export function validateEmail(email: string): boolean {
  // Complex regex validation...
}

// MISSING: src/utils/validator.test.ts should exist with:
describe('validateEmail', () => {
  it('accepts valid emails', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('rejects invalid emails', () => {
    expect(validateEmail('invalid')).toBe(false);
    expect(validateEmail('@example.com')).toBe(false);
    expect(validateEmail('user@')).toBe(false);
  });

  it('handles edge cases', () => {
    expect(validateEmail('')).toBe(false);
    expect(validateEmail(null as any)).toBe(false);
  });
});
```

#### Inadequate Test Scenarios

**Check for:**
- [ ] Only testing happy path
- [ ] Not testing error conditions
- [ ] Missing boundary value tests
- [ ] No tests for race conditions or timing issues

**🟡 MINOR Pattern:**
```typescript
// INCOMPLETE: Only tests success case
test('createUser creates user', async () => {
  const user = await createUser({ name: 'Alice', email: 'alice@example.com' });
  expect(user.name).toBe('Alice');
});

// COMPLETE: Tests success, failure, and edge cases
describe('createUser', () => {
  it('creates user with valid data', async () => {
    const user = await createUser({ name: 'Alice', email: 'alice@example.com' });
    expect(user.name).toBe('Alice');
  });

  it('throws error for duplicate email', async () => {
    await createUser({ name: 'Alice', email: 'alice@example.com' });
    await expect(
      createUser({ name: 'Bob', email: 'alice@example.com' })
    ).rejects.toThrow('Email already exists');
  });

  it('validates email format', async () => {
    await expect(
      createUser({ name: 'Bob', email: 'invalid-email' })
    ).rejects.toThrow('Invalid email');
  });

  it('handles empty name', async () => {
    await expect(
      createUser({ name: '', email: 'bob@example.com' })
    ).rejects.toThrow('Name required');
  });
});
```

### 6. Project-Specific Standards (CLAUDE.md)

#### AWS CDK Best Practices

**Check for:**
- [ ] Creating stateful resources instead of importing (User Pools, S3 buckets)
- [ ] Using `fromLookup()` instead of `fromXxxAttributes()` (causes CI/CD failures)
- [ ] Lambda@Edge using environment variables (not supported)
- [ ] Missing stack descriptions or tags

**🟠 MAJOR Example:**
```typescript
// WRONG: Creates new User Pool (stateful resource)
const userPool = new cognito.UserPool(this, 'UserPool', {
  userPoolName: 'my-pool'
});

// RIGHT: Import existing User Pool
const userPool = cognito.UserPool.fromUserPoolAttributes(this, 'UserPool', {
  userPoolId: 'us-east-1_abc123',
  userPoolClientId: 'client-id-123'
});

// WRONG: Lambda@Edge with environment variables
new cloudfront.experimental.EdgeFunction(this, 'AuthFn', {
  code: lambda.Code.fromAsset('lambda'),
  handler: 'auth.handler',
  environment: { // NOT SUPPORTED IN LAMBDA@EDGE!
    USER_POOL_ID: userPool.userPoolId
  }
});

// RIGHT: Bake config into Lambda code at build time
const userPoolId = 'us-east-1_abc123';
new cloudfront.experimental.EdgeFunction(this, 'AuthFn', {
  code: lambda.Code.fromAsset('lambda', {
    bundling: {
      environment: { USER_POOL_ID: userPoolId } // Build-time config
    }
  }),
  handler: 'auth.handler'
});
```

#### Git Commit Standards

**Check for:**
- [ ] Commit messages not semantic (missing: feat, fix, docs, refactor, test)
- [ ] Missing AIGCODE counter
- [ ] Large unfocused commits (multiple unrelated changes)
- [ ] Commented-out code left in commits

**🟡 MINOR Pattern:**
```bash
# BAD COMMITS:
git commit -m "updated stuff"
git commit -m "fix"
git commit -m "changes"

# GOOD COMMITS (check git log for highest AIGCODE number first):
git log --oneline --all --grep="AIGCODE-"
# Highest: AIGCODE-028

git commit -m "AIGCODE-029: feat: add email validation to user registration

Implements RFC 5322 email validation with additional checks for disposable email domains. Updates UserSchema with email validator.

Fixes #123"
```

#### Build System Standards

**Check for:**
- [ ] TypeScript strict mode disabled
- [ ] Missing type declarations for modules
- [ ] Build output committed to repo
- [ ] Dev dependencies in production dependencies

## Examples of Common Findings

### Example 1: Null Pointer Bug (🔴 CRITICAL)

```
File: src/api/users.ts
Line(s): 34
Problem: Accessing user.profile.avatar without null checks. Crashes when user.profile is undefined. Will cause 500 errors in production.
Fix: Use optional chaining:
  const avatar = user?.profile?.avatar ?? '/default-avatar.png';
```

### Example 2: Function Too Long (🟠 MAJOR)

```
File: src/services/order.ts
Line(s): 45-178
Problem: createOrder() function is 133 lines with 8 responsibilities (validation, inventory, payment, shipping, email, logging, analytics, audit). Difficult to test and maintain.
Fix: Split into focused functions:
  - validateOrder()
  - checkInventory()
  - processPayment()
  - scheduleShipping()
  - sendOrderConfirmation()
  Each function 10-20 lines and testable independently.
```

### Example 3: Unhandled Promise Rejection (🟠 MAJOR)

```
File: src/middleware/auth.ts
Line(s): 23-26
Problem: verifyToken() calls async jwt.verify() without try-catch. Unhandled rejections crash Node.js process.
Fix: Add error handling:
  try {
    const decoded = await jwt.verify(token, secret);
    return decoded;
  } catch (error) {
    throw new UnauthorizedError('Invalid token');
  }
```

### Example 4: Type Safety Disabled (🟠 MAJOR)

```
File: src/utils/parser.ts
Line(s): 15
Problem: Function accepts 'any' type, disabling all TypeScript safety. Caller could pass invalid data causing runtime errors.
Fix: Define proper interface:
  interface ParsedData {
    id: number;
    name: string;
    tags: string[];
  }
  function parseData(raw: unknown): ParsedData {
    // Validate and parse with type guards
  }
```

### Example 5: Missing Tests (🟠 MAJOR)

```
File: src/utils/calculate-discount.ts
Line(s): 1-45
Problem: New calculateDiscount() function with complex business logic (tier pricing, promo codes, user roles) has no test file. Risk of bugs in pricing logic.
Fix: Create src/utils/calculate-discount.test.ts with tests for:
  - Regular pricing
  - Tier discounts (bronze/silver/gold)
  - Promo code validation and application
  - Edge cases (negative amounts, expired promos, stacking rules)
```

### Example 6: Code Duplication (🟠 MAJOR)

```
File: src/api/users.ts, src/api/posts.ts
Line(s): users.ts:67-82, posts.ts:45-60
Problem: Identical pagination logic duplicated in both files (16 lines each). Changes must be made in two places.
Fix: Extract to shared utility:
  // src/utils/paginate.ts
  export function paginate<T>(items: T[], page: number, limit: number) {
    const offset = (page - 1) * limit;
    return {
      items: items.slice(offset, offset + limit),
      total: items.length,
      page,
      totalPages: Math.ceil(items.length / limit)
    };
  }
```

### Example 7: Magic Number (🟡 MINOR)

```
File: src/services/cache.ts
Line(s): 23
Problem: Hardcoded 300000 in setTimeout without explanation. Unclear what time period this represents.
Fix: Use named constant:
  const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
  setTimeout(clearCache, CACHE_TTL_MS);
```

## Code Quality Metrics

After analysis, provide:

1. **Complexity Metrics**:
   - Functions over 50 lines: X
   - Functions with cyclomatic complexity > 10: Y
   - Maximum nesting depth: Z

2. **Type Safety**:
   - Uses of `any`: X
   - Type assertions: Y
   - Missing return types: Z

3. **Test Coverage**:
   - New functions without tests: X
   - Untested edge cases: Y
   - Test file exists: Yes/No

4. **Code Health**:
   - Duplicated code blocks: X
   - TODOs/FIXMEs: Y
   - Dead code (unused functions/variables): Z

## References

- **CLAUDE.md** - Project-specific standards (AWS CDK, git workflow, TypeScript config)
- **TypeScript Handbook** - https://www.typescriptlang.org/docs/handbook/
- **Clean Code** - Robert C. Martin principles
- **Effective TypeScript** - 62 Specific Ways to Improve Your TypeScript
- **Google TypeScript Style Guide** - https://google.github.io/styleguide/tsguide.html
