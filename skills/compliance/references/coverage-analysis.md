# Test Coverage Analysis

> **Reference for:** compliance skill - Phase 3
> **Context:** Analyzing coverage gaps and generating missing tests

## Overview

This phase identifies untested code paths and generates comprehensive test suites to meet coverage thresholds.

**Input:** Lambda source code + existing tests
**Output:** Generated tests + coverage report

## Process

### Step 1: Run Coverage Analysis

Execute Jest with coverage enabled:

```bash
cd lambda/admin
npm test -- --coverage --coverageReporters=json-summary,text,lcov

# Coverage thresholds from config.yaml:
# - Lambda: 80%
# - Infrastructure: 70%
# - Utilities: 90%
```

**Output files:**
- `coverage/coverage-summary.json` - Machine-readable summary
- `coverage/lcov.info` - Line-by-line coverage data
- Terminal output - Human-readable summary

### Step 2: Parse Coverage Report

Read and analyze the coverage summary:

```typescript
import fs from 'fs';

const coverageSummary = JSON.parse(
  fs.readFileSync('coverage/coverage-summary.json', 'utf8')
);

// Example structure:
{
  "total": {
    "lines": { "total": 120, "covered": 54, "pct": 45 },
    "statements": { "total": 125, "covered": 56, "pct": 44.8 },
    "functions": { "total": 15, "covered": 6, "pct": 40 },
    "branches": { "total": 40, "covered": 12, "pct": 30 }
  },
  "/path/to/lambda/admin/index.ts": {
    "lines": { "total": 120, "covered": 54, "pct": 45 },
    // ... per-file metrics
  }
}
```

**Identify:**
- Files below threshold (e.g., < 80%)
- Untested functions (0% function coverage)
- Untested branches (if/else paths not covered)

### Step 3: Identify Untested Functions

Parse the source code to find untested functions:

```typescript
// Read source file
const sourceCode = fs.readFileSync('lambda/admin/index.ts', 'utf8');

// Extract function definitions
const functionPattern = /(?:export\s+)?(?:async\s+)?function\s+(\w+)/g;
const functions = [...sourceCode.matchAll(functionPattern)].map(m => m[1]);

// Cross-reference with lcov data
const lcov = fs.readFileSync('coverage/lcov.info', 'utf8');
const uncoveredFunctions = functions.filter(fn => {
  return !lcov.includes(`FN:${fn}`) || lcov.includes(`FNDA:0,${fn}`);
});

console.log('Untested functions:', uncoveredFunctions);
// → ['validateToken', 'refreshTokenIfExpired', 'extractUserFromClaims']
```

### Step 4: Generate Test Cases

For each untested function, generate comprehensive tests:

**Test categories:**
1. **Happy path** - Normal execution, valid inputs
2. **Edge cases** - Boundary conditions, empty inputs, null values
3. **Error cases** - Invalid inputs, exceptions, AWS service failures

**Example generation:**

```typescript
// lambda/admin/__tests__/index.test.ts
import { handler, validateToken, extractUserFromClaims } from '../index';
import { APIGatewayProxyEvent, Context } from 'aws-lambda';
import { mockClient } from 'aws-sdk-client-mock';
import {
  CognitoIdentityProviderClient,
  ListUsersCommand,
  AdminGetUserCommand,
} from '@aws-sdk/client-cognito-identity-provider';

const cognitoMock = mockClient(CognitoIdentityProviderClient);

describe('Admin Lambda Handler', () => {
  beforeEach(() => {
    cognitoMock.reset();
  });

  describe('validateToken', () => {
    // Happy path
    it('returns true for valid token', () => {
      const token = 'valid-jwt-token';
      const result = validateToken(token);
      expect(result).toBe(true);
    });

    // Edge cases
    it('returns false for empty token', () => {
      const result = validateToken('');
      expect(result).toBe(false);
    });

    it('returns false for null token', () => {
      const result = validateToken(null as any);
      expect(result).toBe(false);
    });

    it('returns false for undefined token', () => {
      const result = validateToken(undefined as any);
      expect(result).toBe(false);
    });

    // Error cases
    it('returns false for malformed token', () => {
      const token = 'not-a-jwt';
      const result = validateToken(token);
      expect(result).toBe(false);
    });

    it('returns false for expired token', () => {
      const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2MDAwMDAwMDB9.signature';
      const result = validateToken(token);
      expect(result).toBe(false);
    });
  });

  describe('extractUserFromClaims', () => {
    // Happy path
    it('extracts user from valid claims', () => {
      const claims = {
        sub: 'user-123',
        email: 'user@example.com',
        'custom:role': 'student',
      };

      const user = extractUserFromClaims(claims);

      expect(user).toEqual({
        userId: 'user-123',
        email: 'user@example.com',
        role: 'student',
      });
    });

    // Edge cases
    it('returns null when email missing', () => {
      const claims = {
        sub: 'user-123',
        'custom:role': 'student',
      };

      const user = extractUserFromClaims(claims);
      expect(user).toBeNull();
    });

    it('returns null when sub missing', () => {
      const claims = {
        email: 'user@example.com',
        'custom:role': 'student',
      };

      const user = extractUserFromClaims(claims);
      expect(user).toBeNull();
    });

    // Error cases
    it('handles empty claims object', () => {
      const user = extractUserFromClaims({});
      expect(user).toBeNull();
    });

    it('handles null claims', () => {
      const user = extractUserFromClaims(null as any);
      expect(user).toBeNull();
    });
  });

  describe('GET /api/admin/users', () => {
    // Happy path
    it('returns users list on success', async () => {
      cognitoMock.on(ListUsersCommand).resolves({
        Users: [
          {
            Username: 'user-123',
            Attributes: [
              { Name: 'email', Value: 'user@example.com' },
              { Name: 'custom:role', Value: 'student' },
            ],
          },
        ],
      });

      const event = {
        httpMethod: 'GET',
        path: '/api/admin/users',
        headers: { Authorization: 'Bearer valid-token' },
        // ... other required fields
      } as APIGatewayProxyEvent;

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.users).toHaveLength(1);
      expect(body.users[0].email).toBe('user@example.com');
    });

    // Edge cases
    it('returns empty list when no users', async () => {
      cognitoMock.on(ListUsersCommand).resolves({
        Users: [],
      });

      const event = {
        httpMethod: 'GET',
        path: '/api/admin/users',
        headers: { Authorization: 'Bearer valid-token' },
      } as APIGatewayProxyEvent;

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.users).toEqual([]);
    });

    it('handles pagination with nextToken', async () => {
      cognitoMock.on(ListUsersCommand).resolves({
        Users: [
          /* ... users ... */
        ],
        PaginationToken: 'next-page-token',
      });

      const event = {
        httpMethod: 'GET',
        path: '/api/admin/users',
        headers: { Authorization: 'Bearer valid-token' },
      } as APIGatewayProxyEvent;

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.nextToken).toBe('next-page-token');
    });

    // Error cases
    it('returns 401 when missing authorization', async () => {
      const event = {
        httpMethod: 'GET',
        path: '/api/admin/users',
        headers: {},
      } as APIGatewayProxyEvent;

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(401);
      expect(JSON.parse(response.body).error).toBe('Unauthorized');
    });

    it('returns 500 when Cognito call fails', async () => {
      cognitoMock.on(ListUsersCommand).rejects(new Error('Service unavailable'));

      const event = {
        httpMethod: 'GET',
        path: '/api/admin/users',
        headers: { Authorization: 'Bearer valid-token' },
      } as APIGatewayProxyEvent;

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(500);
      expect(JSON.parse(response.body).error).toBe('Internal server error');
    });
  });
});
```

### Step 5: Verify Coverage Improvement

Re-run coverage with new tests:

```bash
npm test -- --coverage

# Before:
# Statements   : 44.8% ( 56/125 )
# Branches     : 30.0% ( 12/40 )
# Functions    : 40.0% ( 6/15 )
# Lines        : 45.0% ( 54/120 )

# After:
# Statements   : 82.4% ( 103/125 )
# Branches     : 75.0% ( 30/40 )
# Functions    : 80.0% ( 12/15 )
# Lines        : 81.7% ( 98/120 )
```

**Report:**
- Previous coverage: 45%
- New coverage: 82%
- Tests generated: 23
- Coverage threshold met: ✅ (80%)

## AWS SDK Mocking

Use `aws-sdk-client-mock` for mocking AWS services:

```typescript
import { mockClient } from 'aws-sdk-client-mock';
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';

const s3Mock = mockClient(S3Client);
const dynamoMock = mockClient(DynamoDBClient);

beforeEach(() => {
  s3Mock.reset();
  dynamoMock.reset();
});

it('retrieves file from S3', async () => {
  s3Mock.on(GetObjectCommand).resolves({
    Body: Buffer.from('file contents'),
  });

  // Test proceeds with mocked S3
});

it('handles DynamoDB errors', async () => {
  dynamoMock.on(GetItemCommand).rejects(new Error('Table not found'));

  // Test error handling
});
```

## Tips

**1. Prioritize critical paths**
- Authentication/authorization
- Data mutations (create, update, delete)
- Payment processing
- Security-sensitive operations

**2. Mock external dependencies**
- AWS SDK calls
- HTTP requests
- Database queries
- Third-party APIs

**3. Test error handling**
- Network failures
- Service unavailable
- Invalid data
- Timeouts

**4. Use descriptive test names**
- Good: `it('returns 401 when token is expired')`
- Bad: `it('test1')`

**5. Group related tests**
- Use `describe` blocks for endpoints
- Group by function or feature area

## Troubleshooting

**Issue: Coverage still below threshold after generation**
- **Cause:** Complex logic paths not covered
- **Fix:** Manually add tests for complex branches

**Issue: Mocks not working**
- **Cause:** Mock setup incorrect or reset not called
- **Fix:** Call `mock.reset()` in `beforeEach`

**Issue: Tests fail with "Module not found"**
- **Cause:** Import paths incorrect
- **Fix:** Check relative paths match file structure

## Next Steps

After achieving coverage targets:

1. Review generated tests for quality
2. Manually add tests for complex logic
3. Proceed to **Phase 4: Acceptance Criteria Validation**
4. Add coverage checks to CI/CD
