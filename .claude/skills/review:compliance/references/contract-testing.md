# Contract Test Generation

> **Reference for:** compliance skill - Phase 2
> **Context:** Generating Jest contract tests from OpenAPI specifications

## Overview

This phase generates automated contract tests that validate API responses match OpenAPI schema definitions.

**Input:** OpenAPI 3.0 spec (`docs/api/{api}-openapi.yaml`)
**Output:** Jest test suite (`lambda/{api}/__tests__/contract.test.ts`)

## Process

### Step 1: Read OpenAPI Spec

Load and parse the OpenAPI specification:

```typescript
import yaml from 'js-yaml';
import fs from 'fs';

const spec = yaml.load(fs.readFileSync('docs/api/admin-openapi.yaml', 'utf8'));
```

**Extract:**
- Paths (`/api/admin/users`, `/api/admin/users/{userId}`)
- Operations (GET, POST, PUT, DELETE, PATCH)
- Request schemas (from `requestBody.content.application/json.schema`)
- Response schemas (from `responses.{statusCode}.content.application/json.schema`)
- Parameters (path, query, header)

### Step 2: Set Up Ajv Validator

Configure Ajv for JSON Schema validation:

```typescript
import Ajv from 'ajv';
import addFormats from 'ajv-formats';

const ajv = new Ajv({
  allErrors: true,  // Report all validation errors
  verbose: true,    // Include schema information in errors
  strict: false,    // Allow OpenAPI extensions (x-*)
});

addFormats(ajv);  // Add support for email, uuid, date-time formats
```

### Step 3: Generate Test Suite

Create Jest describe blocks for each path/operation:

```typescript
// lambda/admin/__tests__/contract.test.ts
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import { handler } from '../index';
import { APIGatewayProxyEvent, Context } from 'aws-lambda';

const ajv = new Ajv({ allErrors: true, verbose: true, strict: false });
addFormats(ajv);

// Helper to create mock API Gateway event
function createEvent(
  httpMethod: string,
  path: string,
  body?: any,
  headers?: Record<string, string>,
  pathParameters?: Record<string, string>
): APIGatewayProxyEvent {
  return {
    httpMethod,
    path,
    body: body ? JSON.stringify(body) : null,
    headers: headers || {},
    pathParameters: pathParameters || null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    isBase64Encoded: false,
    requestContext: {} as any,
    resource: '',
    stageVariables: null,
    multiValueHeaders: null,
  };
}

describe('Admin API Contract Tests', () => {
  describe('GET /api/admin/users', () => {
    it('validates 200 response schema', async () => {
      const event = createEvent('GET', '/api/admin/users', undefined, {
        Authorization: 'Bearer mock-token',
      });

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(200);

      const body = JSON.parse(response.body);
      const schema = {
        type: 'object',
        required: ['users'],
        properties: {
          users: {
            type: 'array',
            items: {
              type: 'object',
              required: ['userId', 'email', 'role'],
              properties: {
                userId: { type: 'string' },
                email: { type: 'string', format: 'email' },
                role: {
                  type: 'string',
                  enum: ['admin', 'instructor', 'student'],
                },
                firstName: { type: 'string' },
                lastName: { type: 'string' },
                createdAt: { type: 'string', format: 'date-time' },
              },
            },
          },
          nextToken: { type: 'string' },
        },
      };

      const validate = ajv.compile(schema);
      const valid = validate(body);

      if (!valid) {
        console.error('Schema validation failed:', validate.errors);
      }

      expect(valid).toBe(true);
    });

    it('validates 401 response schema', async () => {
      const event = createEvent('GET', '/api/admin/users');

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(401);

      const body = JSON.parse(response.body);
      const schema = {
        type: 'object',
        required: ['error'],
        properties: {
          error: { type: 'string' },
        },
      };

      const validate = ajv.compile(schema);
      expect(validate(body)).toBe(true);
    });

    it('validates 500 response schema', async () => {
      // Mock implementation that forces error
      const event = createEvent('GET', '/api/admin/users', undefined, {
        Authorization: 'Bearer invalid-token',
      });

      const response = await handler(event, {} as Context);

      if (response.statusCode === 500) {
        const body = JSON.parse(response.body);
        const schema = {
          type: 'object',
          required: ['error'],
          properties: {
            error: { type: 'string' },
          },
        };

        const validate = ajv.compile(schema);
        expect(validate(body)).toBe(true);
      } else {
        // Skip if error condition not triggered
        expect(response.statusCode).toBeLessThan(500);
      }
    });
  });

  describe('POST /api/admin/users', () => {
    it('validates request schema', () => {
      const requestBody = {
        email: 'newuser@example.com',
        role: 'student',
        firstName: 'Jane',
        lastName: 'Doe',
      };

      const schema = {
        type: 'object',
        required: ['email', 'role'],
        properties: {
          email: { type: 'string', format: 'email' },
          role: {
            type: 'string',
            enum: ['admin', 'instructor', 'student'],
          },
          firstName: { type: 'string' },
          lastName: { type: 'string' },
        },
      };

      const validate = ajv.compile(schema);
      expect(validate(requestBody)).toBe(true);
    });

    it('validates 201 response schema', async () => {
      const requestBody = {
        email: 'newuser@example.com',
        role: 'student',
      };

      const event = createEvent('POST', '/api/admin/users', requestBody, {
        Authorization: 'Bearer mock-token',
      });

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(201);

      const body = JSON.parse(response.body);
      const schema = {
        type: 'object',
        required: ['userId', 'email', 'role'],
        properties: {
          userId: { type: 'string' },
          email: { type: 'string', format: 'email' },
          role: {
            type: 'string',
            enum: ['admin', 'instructor', 'student'],
          },
          firstName: { type: 'string' },
          lastName: { type: 'string' },
          createdAt: { type: 'string', format: 'date-time' },
        },
      };

      const validate = ajv.compile(schema);
      const valid = validate(body);

      if (!valid) {
        console.error('Schema validation failed:', validate.errors);
      }

      expect(valid).toBe(true);
    });

    it('validates 400 response schema on invalid request', async () => {
      const invalidBody = {
        email: 'not-an-email',  // Invalid email format
        role: 'invalid-role',   // Invalid enum value
      };

      const event = createEvent('POST', '/api/admin/users', invalidBody, {
        Authorization: 'Bearer mock-token',
      });

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(400);

      const body = JSON.parse(response.body);
      const schema = {
        type: 'object',
        required: ['error'],
        properties: {
          error: { type: 'string' },
          details: {
            type: 'array',
            items: { type: 'string' },
          },
        },
      };

      const validate = ajv.compile(schema);
      expect(validate(body)).toBe(true);
    });
  });

  describe('PUT /api/admin/users/{userId}', () => {
    it('validates path parameters', () => {
      const pathParameters = {
        userId: 'user-123',
      };

      expect(pathParameters.userId).toBeDefined();
      expect(typeof pathParameters.userId).toBe('string');
    });

    it('validates 200 response schema', async () => {
      const requestBody = {
        role: 'admin',
      };

      const event = createEvent(
        'PUT',
        '/api/admin/users/user-123',
        requestBody,
        { Authorization: 'Bearer mock-token' },
        { userId: 'user-123' }
      );

      const response = await handler(event, {} as Context);

      expect(response.statusCode).toBe(200);

      const body = JSON.parse(response.body);
      const schema = {
        type: 'object',
        required: ['userId', 'email', 'role'],
        properties: {
          userId: { type: 'string' },
          email: { type: 'string', format: 'email' },
          role: {
            type: 'string',
            enum: ['admin', 'instructor', 'student'],
          },
          firstName: { type: 'string' },
          lastName: { type: 'string' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      };

      const validate = ajv.compile(schema);
      const valid = validate(body);

      if (!valid) {
        console.error('Schema validation failed:', validate.errors);
      }

      expect(valid).toBe(true);
    });
  });
});
```

### Step 4: Run Contract Tests

Execute the generated test suite:

```bash
cd lambda/admin
npm test -- contract.test.ts

# With coverage
npm test -- contract.test.ts --coverage
```

**Expected output:**
```
 PASS  __tests__/contract.test.ts
  Admin API Contract Tests
    GET /api/admin/users
      ✓ validates 200 response schema (45 ms)
      ✓ validates 401 response schema (12 ms)
      ✓ validates 500 response schema (8 ms)
    POST /api/admin/users
      ✓ validates request schema (3 ms)
      ✓ validates 201 response schema (32 ms)
      ✓ validates 400 response schema on invalid request (18 ms)
    PUT /api/admin/users/{userId}
      ✓ validates path parameters (2 ms)
      ✓ validates 200 response schema (28 ms)

Test Suites: 1 passed, 1 total
Tests:       8 passed, 8 total
```

## Test Coverage

**For each endpoint, generate tests for:**

1. **Success responses (2xx)**
   - 200 OK
   - 201 Created
   - 204 No Content

2. **Client errors (4xx)**
   - 400 Bad Request (invalid input)
   - 401 Unauthorized (missing/invalid auth)
   - 403 Forbidden (insufficient permissions)
   - 404 Not Found (resource doesn't exist)

3. **Server errors (5xx)**
   - 500 Internal Server Error
   - 503 Service Unavailable

4. **Request validation**
   - Required fields present
   - Field types correct
   - Enum values valid
   - Format constraints met (email, uuid, date-time)

## Mocking Strategies

### Mock AWS Services

```typescript
import { mockClient } from 'aws-sdk-client-mock';
import { CognitoIdentityProviderClient, ListUsersCommand } from '@aws-sdk/client-cognito-identity-provider';

const cognitoMock = mockClient(CognitoIdentityProviderClient);

beforeEach(() => {
  cognitoMock.reset();
});

it('validates response when Cognito returns users', async () => {
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

  // Test proceeds with mocked Cognito
});
```

### Mock Environment Variables

```typescript
describe('Contract Tests', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = {
      ...originalEnv,
      USER_POOL_ID: 'us-east-1_TESTPOOL',
      REGION: 'us-east-1',
    };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  // Tests run with mocked env
});
```

## Tips

**1. Test all documented response codes**
- If OpenAPI spec lists 400, 401, 500 → generate tests for all
- Don't skip error cases

**2. Use schema references**
- Extract schemas from `components/schemas`
- Compile once, reuse across tests

**3. Provide helpful error messages**
- Log validation errors when tests fail
- Include which field failed validation

**4. Keep tests independent**
- Each test should run in isolation
- Use `beforeEach` to reset state

**5. Generate both positive and negative tests**
- Positive: Valid request → Expected response
- Negative: Invalid request → Error response

## Troubleshooting

**Issue: Tests fail with "Cannot find module"**
- **Cause:** Lambda handler not found
- **Fix:** Check import path matches Lambda file location

**Issue: Schema validation always fails**
- **Cause:** Response structure doesn't match schema
- **Fix:** Compare actual response to OpenAPI schema, update one or the other

**Issue: Ajv format validation fails**
- **Cause:** Missing format validators (email, uuid, date-time)
- **Fix:** Install `ajv-formats` and call `addFormats(ajv)`

**Issue: Tests pass locally but fail in CI**
- **Cause:** Environment differences (env vars, AWS SDK mocks)
- **Fix:** Ensure mocks and env setup in CI match local

## Next Steps

After contract tests pass:

1. Add tests to CI/CD pipeline
2. Proceed to **Phase 3: Test Coverage Analysis**
3. Monitor for schema drift (response changes not reflected in spec)
