---
description: Review TypeScript code for type safety, production patterns, testing coverage, and Lambda best practices. Use when reviewing **/*.ts files (excluding infrastructure/).
---

# TypeScript Code Review

## CRITICAL: Review Guidelines

**DO NOT:**
- Try to compile code (LSP diagnostics already checked)
- Generate findings just to produce output
- Report subjective preferences without clear impact
- Duplicate issues already caught by TypeScript compiler

**ONLY REPORT IF:**
- Security vulnerability with concrete attack vector
- Correctness bug with specific failure scenario
- Performance problem with measurable impact
- Architecture violation breaking project patterns
- Missing error handling with real consequence

**REQUIRED FOR EACH FINDING:**
- Specific line numbers
- Concrete impact (what breaks/fails)
- Working code example (for CRITICAL/MAJOR)
- Business/security/reliability consequence

---

You are reviewing TypeScript code for production readiness. Follow these guidelines to ensure type safety, proper error handling, testing coverage, and Lambda best practices.

## Context

This project uses TypeScript in strict mode with specific patterns:

- **AWS Lambda handlers** for serverless functions
- **Jest** for testing with 80% coverage target
- **Structured JSON logging** for CloudWatch
- **Type safety** - no `any` types, explicit function signatures
- **Production patterns** - proper error handling, input validation, defensive programming

## Review Process

### 1. Read All Relevant Files

Before providing feedback, read:
- The TypeScript file being reviewed
- Related test files (if they exist)
- Reference patterns: `.claude/commands/references/typescript-patterns.md`

### 2. Check Against Project Patterns

Review the code against these key areas:

#### Type Safety
- [ ] All function parameters have explicit types
- [ ] All function return types are explicit
- [ ] No `any` types (use `unknown` or proper types)
- [ ] Proper use of optional chaining and nullish coalescing
- [ ] Type guards used for narrowing

#### Error Handling
- [ ] Top-level try-catch in all async handlers
- [ ] Early returns for validation failures
- [ ] Proper HTTP status codes (401, 403, 404, 500)
- [ ] Structured error responses with consistent format
- [ ] Errors logged with context

#### Logging
- [ ] Structured JSON logging (not plain strings)
- [ ] Appropriate log levels (log/warn/error)
- [ ] Sensitive data not logged
- [ ] Error context included in logs

#### Lambda Patterns (if applicable)
- [ ] Proper handler type (APIGatewayProxyEvent, etc.)
- [ ] Response includes required headers (Content-Type, CORS)
- [ ] Response body is stringified JSON
- [ ] Authorization checked at handler entry

#### Testing
- [ ] Test file exists (*.test.ts or *.spec.ts)
- [ ] Tests cover: happy path, error cases, edge cases
- [ ] External dependencies mocked
- [ ] Test coverage target met (80%)

#### Input Validation
- [ ] All external input validated (API requests, events)
- [ ] Request body parsed safely (with defaults)
- [ ] Authorization tokens checked
- [ ] No over-engineering for internal functions

### 3. Output Findings

**CRITICAL: Use the standardized review output format**

Reference: `.claude/commands/references/review-output-format.md`

All findings MUST include:
- Severity emoji (🔴/🟠/🟡)
- File path with line numbers
- Problem explanation (what, why, impact)
- Fix with code example (REQUIRED for CRITICAL/MAJOR)
- Agent prompt (copy-paste ready, self-contained)
- References to documentation and project patterns

## Common Issues to Check

### 🔴 CRITICAL Issues

1. **Missing input validation on API endpoints**
   - All user input must be validated
   - Early return with 400 Bad Request
   - Reference pattern: `typescript-patterns.md` → "Validate All External Input"

2. **Missing authorization checks**
   - Check JWT claims from API Gateway authorizer
   - Verify group membership for restricted endpoints
   - Reference pattern: `lambda/admin/index.ts:8-16`

3. **Unhandled promise rejections**
   - All async operations must be in try-catch blocks
   - Handler must catch all errors and return proper response
   - Reference pattern: `typescript-patterns.md` → "Try-Catch for Async Operations"

4. **Missing CORS headers**
   - API Gateway requires CORS headers for browser requests
   - Must include 'Access-Control-Allow-Origin'
   - Reference pattern: `lambda/admin/index.ts:182-202`

### 🟠 MAJOR Issues

1. **Using `any` type**
   - Defeats TypeScript's type safety
   - Use `unknown` or proper types
   - Exception: `error: any` is acceptable in this codebase
   - Reference pattern: `typescript-patterns.md` → "No any Type"

2. **Missing error handling for external services**
   - AWS SDK calls can fail
   - Database queries can timeout
   - Handle errors gracefully, return proper status codes
   - Reference pattern: `typescript-patterns.md` → "Per-Operation Error Handling"

3. **Implicit return types on exported functions**
   - All exported functions must have explicit return types
   - Prevents API breaking changes
   - Reference pattern: `typescript-patterns.md` → "Explicit Typing"

4. **Missing or inadequate test coverage**
   - All exported functions must have tests
   - Coverage target: 80%
   - Must test happy path, errors, edge cases
   - Reference pattern: `lambda/custom-message/__tests__/index.test.ts`

5. **Incorrect HTTP status codes**
   - 401 for missing/invalid authentication
   - 403 for insufficient permissions
   - 404 for resource not found
   - 400 for invalid input
   - 500 for server errors
   - Reference pattern: `lambda/admin/index.ts:10,15,46,49`

### 🟡 MINOR Issues

1. **Unstructured logging**
   - Use JSON.stringify() for objects
   - Include context in log messages
   - Reference pattern: `typescript-patterns.md` → "JSON Logging for Lambda"

2. **Inconsistent error response format**
   - All errors should use the same response helper
   - Include error message in consistent structure
   - Reference pattern: `lambda/admin/index.ts:193-202`

3. **Missing JSDoc comments on public APIs**
   - Complex functions should have documentation
   - Explain parameters and return values

4. **Unused imports or variables**
   - Remove unused code
   - Keeps codebase clean

## Example Review Output

```markdown
## Code Review Findings

### 🔴 CRITICAL: Missing input validation on user creation endpoint

**File:** `lambda/users/create.ts:15-30`

**Problem:** The handler does not validate the request body before creating a user. An attacker could send malformed data causing runtime errors or create users with invalid attributes. This could lead to application crashes or data corruption.

**Fix:**
```typescript
export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
  console.log('Event:', JSON.stringify(event, null, 2));

  try {
    // Validate authorization
    const userId = event.requestContext.authorizer?.claims?.sub;
    if (!userId) {
      return errorResponse(401, 'Unauthorized');
    }

    // Parse and validate request body
    const body = JSON.parse(event.body || '{}');
    const { email, name, role } = body;

    // Validate required fields
    if (!email || typeof email !== 'string' || !email.includes('@')) {
      return errorResponse(400, 'Invalid email address');
    }

    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return errorResponse(400, 'Name is required');
    }

    const validRoles = ['user', 'admin', 'coordinator'];
    if (role && !validRoles.includes(role)) {
      return errorResponse(400, 'Invalid role');
    }

    // Create user with validated input
    const user = await createUser({ email, name, role: role || 'user' });

    return successResponse({ user });
  } catch (error: any) {
    console.error('Handler error:', error);
    return errorResponse(500, error.message || 'Internal Server Error');
  }
}
```

**Agent Prompt:**
```
Add input validation to the handler function in lambda/users/create.ts lines 15-30. Validate the request body fields: email (string with @ symbol), name (non-empty string), role (one of: user, admin, coordinator). Return 400 Bad Request with descriptive error messages for invalid input. Parse the body safely using JSON.parse(event.body || '{}'). Reference the validation pattern in lambda/admin/index.ts lines 127-132.
```

**References:**
- Project pattern: `.claude/commands/references/typescript-patterns.md` → "Validate All External Input"
- Example: `lambda/admin/index.ts:127-132`
- [OWASP Input Validation](https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html)

---

### 🟠 MAJOR: Function uses `any` type for parameters

**File:** `lambda/utils/formatter.ts:12-20`

**Problem:** The `formatUserData` function accepts `data: any`, which defeats TypeScript's type safety. This allows callers to pass invalid data structures, leading to runtime errors that could have been caught at compile time.

**Fix:**
```typescript
interface UserData {
  id: string;
  email: string;
  name: string;
  courses?: Record<string, { cohort: string }>;
}

function formatUserData(data: UserData): FormattedUser {
  return {
    id: data.id,
    email: data.email,
    displayName: data.name,
    courseCount: Object.keys(data.courses || {}).length,
  };
}
```

**Agent Prompt:**
```
Replace the any type with a proper interface in lambda/utils/formatter.ts lines 12-20. Define a UserData interface with properties: id (string), email (string), name (string), courses (optional Record<string, { cohort: string }>). Update the formatUserData function signature to use this interface instead of any.
```

**References:**
- Project pattern: `.claude/commands/references/typescript-patterns.md` → "No any Type"
- [TypeScript Handbook: Interfaces](https://www.typescriptlang.org/docs/handbook/2/objects.html)

---

### 🟡 MINOR: Unstructured logging in handler

**File:** `lambda/payments/process.ts:45`

**Problem:** The log statement uses plain strings instead of structured JSON, making it difficult to parse and analyze logs in CloudWatch Insights. Structured logging enables better filtering and querying.

**Fix:**
```typescript
// Before
console.log('Processing payment for user', userId, 'amount', amount);

// After
console.log('Processing payment:', JSON.stringify({ userId, amount, timestamp: Date.now() }));
```

**Agent Prompt:**
```
Update the console.log statement in lambda/payments/process.ts line 45 to use structured JSON logging. Convert the log message to console.log('Processing payment:', JSON.stringify({ userId, amount, timestamp: Date.now() })). This enables better log parsing in CloudWatch Insights.
```

**References:**
- Project pattern: `.claude/commands/references/typescript-patterns.md` → "JSON Logging for Lambda"
- [AWS Lambda Logging Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/nodejs-logging.html)
```

## Testing Review

When reviewing tests, check for:

### Test Structure
- [ ] Describe blocks group related tests
- [ ] Test names clearly describe what is being tested
- [ ] Arrange-Act-Assert pattern used

### Coverage
- [ ] Happy path tested (successful operations)
- [ ] Error cases tested (exceptions, API failures)
- [ ] Edge cases tested (null, empty, boundary values)
- [ ] Validation tested (input validation errors)

### Mocking
- [ ] External dependencies mocked (AWS SDK, fs, etc.)
- [ ] Mocks return realistic data
- [ ] Mock implementations are clear and maintainable

### Example Test Finding

```markdown
### 🟠 MAJOR: Missing test coverage for error cases

**File:** `lambda/users/__tests__/create.test.ts`

**Problem:** The test suite only covers the happy path (successful user creation). Error cases are not tested, including: invalid input validation, missing authorization, and AWS SDK failures. This leaves critical error handling code untested and prone to bugs.

**Fix:**
```typescript
describe('Error handling', () => {
  it('should return 400 for invalid email', async () => {
    const event = {
      ...baseEvent,
      body: JSON.stringify({ email: 'invalid', name: 'Test User' }),
    };

    const result = await handler(event, mockContext, () => {});

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body).error).toContain('Invalid email');
  });

  it('should return 401 when user is not authenticated', async () => {
    const event = {
      ...baseEvent,
      requestContext: {
        ...baseEvent.requestContext,
        authorizer: undefined,
      },
    };

    const result = await handler(event, mockContext, () => {});

    expect(result.statusCode).toBe(401);
    expect(JSON.parse(result.body).error).toBe('Unauthorized');
  });

  it('should return 500 when AWS SDK call fails', async () => {
    // Mock AWS SDK to throw error
    mockCognitoClient.send.mockRejectedValueOnce(new Error('Service unavailable'));

    const event = {
      ...baseEvent,
      body: JSON.stringify({ email: 'test@example.com', name: 'Test User' }),
    };

    const result = await handler(event, mockContext, () => {});

    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body).error).toContain('Internal Server Error');
  });
});
```

**Agent Prompt:**
```
Add error case tests to lambda/users/__tests__/create.test.ts. Create a new describe block called 'Error handling' with three tests: (1) invalid email returns 400, (2) missing authorization returns 401, (3) AWS SDK failure returns 500. Mock the Cognito client to throw errors for the SDK test. Reference the test structure in lambda/custom-message/__tests__/index.test.ts lines 127-151.
```

**References:**
- Project pattern: `.claude/commands/references/typescript-patterns.md` → "Test Coverage Requirements"
- Example: `lambda/custom-message/__tests__/index.test.ts:127-151`
```

## Tone and Style

- Be specific and technical
- Focus on impact and consequences
- Provide complete, working code examples
- Reference project patterns and external documentation
- Use constructive language ("consider", "should", "recommend")
- Explain the "why" behind each finding

## Deliverable

Your review output must:

1. Follow the standardized format exactly (emoji, structure, required sections)
2. Include agent prompts that are self-contained and actionable
3. Reference specific line numbers in files
4. Provide working code examples for CRITICAL and MAJOR issues
5. Link to relevant documentation and project patterns
6. Prioritize findings by severity (🔴 → 🟠 → 🟡)

Begin your review by reading the relevant files, then output your findings in the standardized format.
