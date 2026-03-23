# OpenAPI Spec Generation

> **Reference for:** compliance skill - Phase 1
> **Context:** Generating OpenAPI 3.0 specifications from TypeScript Lambda handlers

## Overview

This phase analyzes TypeScript Lambda handler code and generates OpenAPI 3.0 specifications that document API contracts.

**Input:** Lambda TypeScript handler (`lambda/*/index.ts`)
**Output:** OpenAPI 3.0 YAML spec (`docs/api/{api}-openapi.yaml`)

## Process

### Step 1: Analyze Lambda Handler

Read the Lambda function code and identify the API Gateway proxy pattern:

```typescript
// lambda/admin/index.ts
export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const { httpMethod, path, body } = event;

  // Route handling
  if (httpMethod === 'GET' && path === '/api/admin/users') {
    return listUsers();
  }

  if (httpMethod === 'POST' && path === '/api/admin/users') {
    return createUser(JSON.parse(body || '{}'));
  }

  // ... more routes
};
```

**Extract:**
- HTTP methods (GET, POST, PUT, DELETE, PATCH)
- Path patterns (`/api/admin/users`, `/api/admin/users/{userId}`)
- Path parameters (`{userId}`, `{courseId}`)
- Query parameters (from `event.queryStringParameters`)
- Request bodies (from `event.body`)
- Response types (return values)

### Step 2: Extract TypeScript Types

Find type definitions for requests and responses:

```typescript
// Request types
interface CreateUserRequest {
  email: string;
  role: 'admin' | 'instructor' | 'student';
  firstName?: string;
  lastName?: string;
}

// Response types
interface User {
  userId: string;
  email: string;
  role: string;
  firstName?: string;
  lastName?: string;
  createdAt: string;
}

interface ListUsersResponse {
  users: User[];
  nextToken?: string;
}
```

**Extract:**
- Interface definitions
- Type aliases
- Enum values
- Optional fields (`?`)
- Required fields
- Array types
- Nested objects

### Step 3: Convert TypeScript to JSON Schema

Map TypeScript types to JSON Schema format:

**TypeScript → JSON Schema mapping:**

| TypeScript | JSON Schema |
|------------|-------------|
| `string` | `{ type: "string" }` |
| `number` | `{ type: "number" }` |
| `boolean` | `{ type: "boolean" }` |
| `string[]` | `{ type: "array", items: { type: "string" } }` |
| `'admin' \| 'student'` | `{ type: "string", enum: ["admin", "student"] }` |
| `field?:` | Not in `required` array |
| `field:` | In `required` array |

**Example conversion:**

```typescript
interface User {
  userId: string;
  email: string;
  role: 'admin' | 'instructor' | 'student';
  firstName?: string;
}
```

Becomes:

```yaml
User:
  type: object
  required:
    - userId
    - email
    - role
  properties:
    userId:
      type: string
      format: uuid
    email:
      type: string
      format: email
    role:
      type: string
      enum:
        - admin
        - instructor
        - student
    firstName:
      type: string
```

### Step 4: Generate OpenAPI Document

Create the OpenAPI 3.0 YAML structure:

```yaml
openapi: 3.0.3
info:
  title: Admin API
  version: 1.0.0
  description: Administrative operations for course management
  contact:
    name: API Support
    email: support@aigensa.com

servers:
  - url: https://api.learn.aigensa.com
    description: Production

security:
  - CognitoAuth: []

paths:
  /api/admin/users:
    get:
      summary: List all users
      operationId: listUsers
      tags:
        - Users
      parameters:
        - name: limit
          in: query
          schema:
            type: integer
            default: 20
            maximum: 100
        - name: nextToken
          in: query
          schema:
            type: string
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ListUsersResponse'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'

    post:
      summary: Create new user
      operationId: createUser
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '500':
          $ref: '#/components/responses/InternalError'

components:
  securitySchemes:
    CognitoAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: AWS Cognito JWT token

  schemas:
    User:
      type: object
      required:
        - userId
        - email
        - role
      properties:
        userId:
          type: string
          format: uuid
        email:
          type: string
          format: email
        role:
          type: string
          enum:
            - admin
            - instructor
            - student
        firstName:
          type: string
        lastName:
          type: string
        createdAt:
          type: string
          format: date-time

    CreateUserRequest:
      type: object
      required:
        - email
        - role
      properties:
        email:
          type: string
          format: email
        role:
          type: string
          enum:
            - admin
            - instructor
            - student
        firstName:
          type: string
        lastName:
          type: string

    ListUsersResponse:
      type: object
      required:
        - users
      properties:
        users:
          type: array
          items:
            $ref: '#/components/schemas/User'
        nextToken:
          type: string

  responses:
    Unauthorized:
      description: Missing or invalid authentication
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: Unauthorized

    BadRequest:
      description: Invalid request parameters
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
              details:
                type: array
                items:
                  type: string

    InternalError:
      description: Internal server error
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: Internal server error
```

### Step 5: Validate Spec

Use swagger-parser to validate the generated spec:

```bash
# Install validator (if not already available)
npm install -g @apidevtools/swagger-parser

# Validate spec
swagger-parser validate docs/api/admin-openapi.yaml
```

**Common validation errors:**
- Missing required fields in schema definitions
- Invalid `$ref` references
- Unsupported OpenAPI features (e.g., OpenAPI 3.1 features in 3.0 spec)
- Invalid enum values
- Circular references

**Fix errors before proceeding to Phase 2.**

## Supported Lambda Patterns

### Pattern 1: Switch Statement Router

```typescript
export const handler = async (event: APIGatewayProxyEvent) => {
  const route = `${event.httpMethod} ${event.path}`;

  switch (route) {
    case 'GET /api/admin/users':
      return listUsers(event);
    case 'POST /api/admin/users':
      return createUser(event);
    default:
      return { statusCode: 404, body: JSON.stringify({ error: 'Not found' }) };
  }
};
```

### Pattern 2: Router Object

```typescript
const routes = {
  'GET /api/admin/users': listUsers,
  'POST /api/admin/users': createUser,
  'GET /api/admin/users/{userId}': getUser,
};

export const handler = async (event: APIGatewayProxyEvent) => {
  const route = `${event.httpMethod} ${event.path}`;
  const handler = routes[route];

  if (!handler) {
    return { statusCode: 404, body: JSON.stringify({ error: 'Not found' }) };
  }

  return handler(event);
};
```

### Pattern 3: Express-like Framework

```typescript
import { Router } from 'lambda-router';

const router = new Router();

router.get('/api/admin/users', listUsers);
router.post('/api/admin/users', createUser);
router.get('/api/admin/users/:userId', getUser);

export const handler = router.handle;
```

## Tips

**1. Use descriptive operation IDs**
- Good: `listUsers`, `createUser`, `updateUserRole`
- Bad: `handler1`, `function2`, `doSomething`

**2. Add examples to schemas**
- Improves API documentation
- Helps contract test generation
- Documents expected formats

**3. Document error responses**
- Include all possible status codes (400, 401, 403, 404, 500)
- Document error payload structure
- Provide example error messages

**4. Use schema references**
- Define schemas once in `components/schemas`
- Reuse with `$ref: '#/components/schemas/User'`
- Avoids duplication and inconsistency

**5. Version your APIs**
- Include version in `info.version`
- Consider versioned paths (`/api/v1/users`, `/api/v2/users`)
- Document breaking changes

## Troubleshooting

**Issue: Cannot extract route patterns**
- **Cause:** Lambda uses complex routing logic
- **Fix:** Simplify to switch/object pattern, or manually document routes

**Issue: TypeScript types not found**
- **Cause:** Types imported from external packages
- **Fix:** Look for type definitions in imported modules or use `any` temporarily

**Issue: Validation fails with "$ref not found"**
- **Cause:** Schema referenced but not defined in `components/schemas`
- **Fix:** Add schema definition or fix reference path

**Issue: Circular reference error**
- **Cause:** Schema A references Schema B which references Schema A
- **Fix:** Use `additionalProperties` or inline one of the schemas

## Next Steps

After generating and validating the OpenAPI spec:

1. Review spec for accuracy
2. Add examples to request/response schemas
3. Proceed to **Phase 2: Contract Test Generation**
4. Use spec for API documentation (Swagger UI, Redoc)
