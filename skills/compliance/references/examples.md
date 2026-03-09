# Compliance Skill Examples

> **Reference for:** compliance skill
> **Context:** Complete workflow examples and expected outputs

## Example 1: Full Compliance Scan

**Command:**
```bash
/compliance
```

**Output:**
```
Compliance Validation - Full Scan
==================================

Phase 1: OpenAPI Spec Generation
---------------------------------
✓ Analyzing Admin API (lambda/admin/index.ts)
  → Found 8 endpoints
  → Generated docs/api/admin-openapi.yaml
  → Validation: PASSED

✓ Analyzing Referral API (lambda/referral/index.ts)
  → Found 6 endpoints
  → Generated docs/api/referrals-openapi.yaml
  → Validation: PASSED

Phase 2: Contract Test Generation
----------------------------------
✓ Generating tests for Admin API
  → Created lambda/admin/__tests__/contract.test.ts
  → 48 tests generated (8 endpoints × 6 scenarios)
  → Running tests... 48 passed ✓

✓ Generating tests for Referral API
  → Created lambda/referral/__tests__/contract.test.ts
  → 36 tests generated (6 endpoints × 6 scenarios)
  → Running tests... 36 passed ✓

Phase 3: Test Coverage Analysis
--------------------------------
✓ Admin Lambda
  → Current coverage: 45%
  → Target threshold: 80%
  → Identified 12 untested functions
  → Generated lambda/admin/__tests__/index.test.ts
  → 23 tests added
  → New coverage: 82% ✓

✓ Referral Lambda
  → Current coverage: 91%
  → Target threshold: 80%
  → No gaps found ✓

✓ Custom Message Lambda
  → Current coverage: 90%
  → Target threshold: 70%
  → No gaps found ✓

⚠ Auth Edge Lambda
  → Current coverage: 65%
  → Target threshold: 80%
  → Identified 8 untested functions
  → Generated lambda/auth-edge/__tests__/index.test.ts
  → 15 tests added
  → New coverage: 83% ✓

Phase 4: Acceptance Criteria Validation
----------------------------------------
Analyzing: docs/archive/root/PRD-TYPESCRIPT-CONVERSION.md

✓ Must Have (P0): 8/9 criteria met (89%)
  ✓ TypeScript strict mode enabled
  ✓ All source files converted to TypeScript
  ✓ Build output identical to baseline
  ✓ All tests passing
  ✗ Custom type declarations for all dependencies
  ✓ JSDoc comments on public APIs
  ✓ No runtime type errors
  ✓ API responses match OpenAPI schemas
  ✓ Test coverage ≥80%

✓ Should Have (P1): 15/16 criteria met (94%)
  ✓ ESLint rules enforced
  ✓ Automated type checking in CI
  ✓ Type-safe AWS SDK clients
  ✓ Generic utility types for common patterns
  ✓ Type guards for runtime validation
  ✓ Branded types for IDs
  ✓ Discriminated unions for state
  ✓ Readonly types for immutable data
  ✓ Strict null checks
  ✓ No implicit any
  ✓ Type-safe environment variables
  ✓ Type-safe configuration
  ✓ Type-safe event handlers
  ✓ Type-safe database models
  ✓ Type-safe API responses
  ⚠ Performance benchmarks maintain baseline (partial: cold start +12%)

Overall Compliance Score
========================
Score: 92% (23/25 criteria met)
Status: ✅ COMPLIANT (threshold: 90%)

Report saved to: docs/compliance-report.md

Summary
-------
- OpenAPI specs: 2 APIs documented (14 endpoints)
- Contract tests: 84 tests passing
- Coverage: 4 Lambdas analyzed, all ≥80%
- Acceptance criteria: 23/25 met

Recommendations
---------------
1. Create custom type declarations (2 hours)
2. Optimize Lambda cold start performance (6 hours)
```

**Files created:**
- `docs/api/admin-openapi.yaml`
- `docs/api/referrals-openapi.yaml`
- `lambda/admin/__tests__/contract.test.ts`
- `lambda/admin/__tests__/index.test.ts`
- `lambda/referral/__tests__/contract.test.ts`
- `lambda/auth-edge/__tests__/index.test.ts`
- `docs/compliance-report.md`

---

## Example 2: Single API Validation

**Command:**
```bash
/compliance --api admin
```

**Output:**
```
Compliance Validation - Admin API
==================================

Phase 1: OpenAPI Spec Generation
---------------------------------
✓ Analyzing lambda/admin/index.ts
  → Routes detected:
    - GET /api/admin/users
    - POST /api/admin/users
    - GET /api/admin/users/{userId}
    - PUT /api/admin/users/{userId}
    - DELETE /api/admin/users/{userId}
    - GET /api/admin/courses
    - POST /api/admin/courses
    - PUT /api/admin/courses/{courseId}

  → Extracting TypeScript types:
    - User (5 properties)
    - CreateUserRequest (4 properties)
    - ListUsersResponse (2 properties)
    - Course (8 properties)

  → Generating OpenAPI 3.0 spec
  → Output: docs/api/admin-openapi.yaml
  → Validating with swagger-parser... ✓

Phase 2: Contract Test Generation
----------------------------------
✓ Reading docs/api/admin-openapi.yaml
  → 8 endpoints, 5 schemas

✓ Generating Jest test suite
  → Output: lambda/admin/__tests__/contract.test.ts
  → Tests generated:
    - GET /api/admin/users: 6 tests
    - POST /api/admin/users: 6 tests
    - GET /api/admin/users/{userId}: 6 tests
    - PUT /api/admin/users/{userId}: 6 tests
    - DELETE /api/admin/users/{userId}: 6 tests
    - GET /api/admin/courses: 6 tests
    - POST /api/admin/courses: 6 tests
    - PUT /api/admin/courses/{courseId}: 6 tests
  → Total: 48 tests

✓ Running tests
  → 48 passed ✓

Phase 3: Coverage Analysis
---------------------------
✓ Current coverage: 45% (54/120 lines)
  → Threshold: 80%

✓ Untested functions:
  1. validateToken (0%)
  2. refreshTokenIfExpired (0%)
  3. extractUserFromClaims (0%)
  4. formatUserResponse (0%)
  5. validateCreateUserRequest (0%)
  6. validateUpdateUserRequest (0%)
  7. listCourses (0%)
  8. createCourse (0%)
  9. updateCourse (0%)
  10. validateCourseRequest (0%)
  11. formatCourseResponse (0%)
  12. handleError (0%)

✓ Generating tests
  → lambda/admin/__tests__/index.test.ts
  → 23 test cases generated
  → Happy path: 12 tests
  → Edge cases: 6 tests
  → Error cases: 5 tests

✓ Running tests with coverage
  → New coverage: 82% (98/120 lines)
  → Threshold met ✓

Phase 4: Compliance Check
--------------------------
⚠ Skipped (use --prd flag to specify PRD)

Summary
-------
✅ OpenAPI spec: 8 endpoints documented
✅ Contract tests: 48 tests passing
✅ Coverage: 82% (threshold: 80%)
⚠ Compliance: Not checked

Next steps:
- Review generated tests
- Run: /compliance --phase acceptance --prd PRD-ADMIN-API.md
```

---

## Example 3: OpenAPI Generation Only

**Command:**
```bash
/compliance --phase openapi --api referral
```

**Output:**
```
Phase 1: OpenAPI Spec Generation
=================================

Analyzing: lambda/referral/index.ts

Routes detected:
  1. GET /api/referrals
  2. POST /api/referrals
  3. GET /api/referrals/{referralId}
  4. PUT /api/referrals/{referralId}
  5. DELETE /api/referrals/{referralId}
  6. GET /api/referrals/user/{userId}

TypeScript types extracted:
  - Referral (6 properties)
  - CreateReferralRequest (3 properties)
  - UpdateReferralRequest (2 properties)
  - ListReferralsResponse (2 properties)

Converting to JSON Schema:
  ✓ Referral → components/schemas/Referral
  ✓ CreateReferralRequest → components/schemas/CreateReferralRequest
  ✓ UpdateReferralRequest → components/schemas/UpdateReferralRequest
  ✓ ListReferralsResponse → components/schemas/ListReferralsResponse

Generating OpenAPI 3.0 document:
  ✓ Info section
  ✓ Servers
  ✓ Security (Cognito JWT)
  ✓ Paths (6 endpoints)
  ✓ Components (4 schemas, 3 responses)

Output: docs/api/referrals-openapi.yaml

Validating with swagger-parser...
  ✓ No errors found
  ✓ Spec is valid OpenAPI 3.0.3

Next steps:
- Review spec: docs/api/referrals-openapi.yaml
- Add request/response examples
- Run: /compliance --phase contract --api referral
```

**Generated spec preview:**
```yaml
openapi: 3.0.3
info:
  title: Referral API
  version: 1.0.0
  description: Referral tracking and management

paths:
  /api/referrals:
    get:
      summary: List all referrals
      operationId: listReferrals
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ListReferralsResponse'
    post:
      summary: Create new referral
      operationId: createReferral
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateReferralRequest'
      responses:
        '201':
          description: Referral created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Referral'
# ... more paths ...
```

---

## Example 4: Coverage Analysis Only

**Command:**
```bash
/compliance --phase coverage --lambda auth-edge
```

**Output:**
```
Phase 3: Test Coverage Analysis
================================

Lambda: auth-edge
Path: lambda/auth-edge/index.ts

Running coverage analysis...
  $ cd lambda/auth-edge && npm test -- --coverage

Current Coverage:
  Statements   : 65.0% ( 52/80 )
  Branches     : 50.0% ( 12/24 )
  Functions    : 60.0% ( 6/10 )
  Lines        : 65.0% ( 52/80 )

Threshold: 80% (BELOW THRESHOLD ⚠)

Untested functions:
  1. validateToken (0% coverage)
     - Location: index.ts:45-67
     - Complexity: Medium
     - Recommended tests: 5

  2. refreshTokenIfExpired (0% coverage)
     - Location: index.ts:69-88
     - Complexity: High
     - Recommended tests: 7

  3. extractUserFromClaims (0% coverage)
     - Location: index.ts:90-105
     - Complexity: Low
     - Recommended tests: 3

Generating tests...
  → lambda/auth-edge/__tests__/index.test.ts

  validateToken:
    ✓ Happy path (1 test)
    ✓ Edge cases (2 tests)
    ✓ Error cases (2 tests)

  refreshTokenIfExpired:
    ✓ Happy path (2 tests)
    ✓ Edge cases (3 tests)
    ✓ Error cases (2 tests)

  extractUserFromClaims:
    ✓ Happy path (1 test)
    ✓ Edge cases (1 test)
    ✓ Error cases (1 test)

  Total: 15 tests generated

Running tests with new suite...
  $ npm test -- --coverage

New Coverage:
  Statements   : 83.7% ( 67/80 )
  Branches     : 79.2% ( 19/24 )
  Functions    : 80.0% ( 8/10 )
  Lines        : 83.7% ( 67/80 )

✅ Threshold met (80%)

Summary:
  Before: 65%
  After: 83.7%
  Improvement: +18.7%
  Tests added: 15
```

---

## Example 5: Acceptance Criteria Only

**Command:**
```bash
/compliance --phase acceptance --prd PRD-TYPESCRIPT-CONVERSION.md
```

**Output:**
```
Phase 4: Acceptance Criteria Validation
========================================

Source: docs/archive/root/PRD-TYPESCRIPT-CONVERSION.md

Extracting acceptance criteria...
  ✓ Found section: **Must Have (P0)**
  ✓ Found section: **Should Have (P1)**
  ✓ Total criteria: 25 (9 P0, 16 P1)

Searching codebase for implementation evidence...

Must Have (P0) - 8/9 met
-------------------------

✅ AC-01: All Lambda functions use TypeScript strict mode
  Implementation:
    - tsconfig.json:5 → "strict": true
    - lambda/admin/tsconfig.json:3 → "strict": true
  Tests:
    - infrastructure/__tests__/typescript-config.test.ts:12
  Score: 100% (Met)

✅ AC-02: All source files converted to TypeScript
  Implementation:
    - Found 0 .js files in src/, lambda/, infrastructure/
    - All 142 source files are .ts
  Tests:
    - infrastructure/__tests__/file-extensions.test.ts:8
  Score: 100% (Met)

❌ AC-05: Custom type declarations for all dependencies
  Implementation:
    - Not found
  Missing:
    - @types/markdown-it-anchor
    - @types/markdown-it-toc-done-right
  Score: 0% (Not Met)

Should Have (P1) - 15/16 met
----------------------------

⚠ AC-16: Performance benchmarks maintain baseline
  Implementation:
    - infrastructure/__tests__/performance.test.ts:15
  Gap:
    - Lambda cold start: 612ms (baseline: 500ms, +22%)
  Score: 50% (Partial)

Overall Score
-------------
23/25 criteria met = 92%

Compliance Status: ✅ COMPLIANT (threshold: 90%)

Report saved to: docs/compliance-report.md

Recommendations:
1. HIGH: Create custom type declarations (AC-05)
   - Estimated effort: 2 hours
   - Blocks: P0 compliance (100%)

2. MEDIUM: Optimize Lambda cold start (AC-16)
   - Estimated effort: 6 hours
   - Target: < 550ms
   - Actions: Analyze bundle, enable tree-shaking

Next steps:
- Review: docs/compliance-report.md
- Create GitHub issues for gaps
- Track compliance over time
```

---

## Common Scenarios

### Scenario: New API Endpoint Added

```bash
# 1. Generate updated OpenAPI spec
/compliance --phase openapi --api admin

# 2. Generate contract tests for new endpoint
/compliance --phase contract --api admin

# 3. Verify coverage still meets threshold
/compliance --phase coverage --lambda admin
```

### Scenario: PRD Updated with New Requirements

```bash
# Run acceptance criteria validation
/compliance --phase acceptance --prd PRD-NEW-FEATURE.md

# Create GitHub issues for gaps
gh issue create --title "AC-XX: [description]" --label compliance
```

### Scenario: Before Production Release

```bash
# Full compliance scan
/compliance

# Review report
cat docs/compliance-report.md

# Ensure compliance score ≥90%
# Fix any gaps before release
```

### Scenario: CI/CD Integration

```yaml
# .github/workflows/compliance.yml
- name: Compliance Check
  run: |
    /compliance --api admin --api referral
    if [ $? -ne 0 ]; then
      echo "Compliance check failed"
      exit 1
    fi
```

---

## Expected Artifacts

After running `/compliance`, verify these files exist:

```
docs/api/
├── admin-openapi.yaml
└── referrals-openapi.yaml

lambda/admin/__tests__/
├── contract.test.ts
└── index.test.ts

lambda/referral/__tests__/
└── contract.test.ts

docs/
└── compliance-report.md
```
