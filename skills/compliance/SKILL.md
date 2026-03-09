---
name: compliance
description: Validates business requirements compliance - generates OpenAPI specs, creates contract tests, and ensures acceptance criteria alignment
---

# Compliance Validation

## Overview

The compliance skill acts as a **quality architect** that enforces test coverage for acceptance criteria before commits, and validates API compliance:

0. **Validating acceptance criteria** from active story and enforcing quality gates (Phase 0 - NEW)
1. **Generating OpenAPI specs** from TypeScript Lambda handlers
2. **Creating contract tests** from OpenAPI schemas
3. **Analyzing test coverage gaps** and generating missing tests
4. **Extracting acceptance criteria** from PRDs and validating implementation (Legacy mode)

**When to use:**
- After implementing new API endpoints
- Before releasing features to production
- When coverage reports show gaps
- When updating business requirements
- During API design reviews

## Quick Start

```bash
# Full compliance scan
/compliance

# Validate specific API
/compliance --api admin

# Run specific phase
/compliance --phase openapi
/compliance --phase contract
/compliance --phase coverage
/compliance --phase acceptance

# Get help
/compliance --help
```

## Workflow

The skill executes in five phases. **Phase 0 runs first as a pre-commit quality gate:**

```
Phase 0: AC Validation (Quality Gates)
        ↓
Active Story → Extract/Generate ACs → Link to Tests → Validate P0=100% → Block if Gaps
        ↓
Phase 1-4 (API Compliance - Optional)
        ↓
OpenAPI Generation → Contract Tests → Coverage Analysis → PRD Validation
        ↓                  ↓                 ↓                ↓
   docs/api/*.yaml    **/__tests__/    Missing tests    Compliance report
```

**Phase 0 is the primary mode** - it enforces quality standards before commits.
**Phases 1-4 are optional** - run when working with APIs or legacy PRD validation.

### Phase 0: AC Validation (Quality Architect Mode)

**Purpose:** Enforce test coverage for acceptance criteria before commits. Acts as a **quality gate** that blocks commits when P0 ACs aren't fully tested.

**See:** @references/quality-architect-mode.md for detailed guide

**Process:**
1. Read active story from `.agile-dev-team/active-story.json`
2. Extract or generate acceptance criteria (from story body or title + NFRs)
3. Search codebase for implementation (keyword-based Grep)
4. Search test files for AC coverage (keyword + similarity scoring)
5. Calculate per-AC coverage from Jest reports
6. Identify gaps (untested P0 ACs)
7. Generate BDD-style test stubs for gaps
8. Validate quality gates (P0 = 100% tested)
9. Block commit if P0 not met, display compliance summary if passed

**Example:**
```bash
# Run as part of /gh:commit workflow (automatic)
/gh:commit
# → 🔍 Running quality gate checks...
# → ✓ Extracted 3 ACs from story #305
# → ✓ Linked 2/3 ACs to tests
# → ❌ Commit blocked: 1 P0 AC not tested
# → Generated test stub: src/__tests__/ac-002.test.ts

# Or run standalone
/compliance --phase 0
# → Validates ACs and generates report
# → Exits with code 1 if P0 gaps exist
```

**Output:**
- `.claude/compliance/acceptance-criteria.json` - AC data structure with evidence
- `.claude/compliance/story-{issueNumber}-compliance.md` - Quality gate report
- `{module}/__tests__/ac-{id}.test.ts` - Generated test stubs (for P0 gaps)

**When to use:**
- Automatically called by `/gh:commit` before creating commits
- Manually run to check compliance status
- After implementing features to verify test coverage
- Before creating PRs to ensure quality gates pass

**Quality Gates:**
- **P0 (Must Have):** 100% test coverage required - blocks commits
- **P1 (Should Have):** 80% recommended - warns but allows commits
- **P2 (Could Have):** 50% recommended - informational only

**AC Generation Strategy:**
- **Parse from story.body** if "## Acceptance Criteria" section exists
- **Generate from title** if no ACs in body (fallback)
- **Augment with NFRs** always (performance, security, reliability)

**Test Linking Strategy:**
- Extract keywords from AC description (remove stop words)
- Search test files: `Grep(keywords, glob: **/__tests__/**/*.test.ts)`
- Read test files and extract describe/it blocks
- Calculate Jaccard similarity between AC keywords and test names
- Link if similarity ≥ 70% (configurable threshold)

**Test Stub Generation:**
- Infer module from story context or AC keywords
- Generate BDD-style tests with Arrange-Act-Assert structure
- Include TODO comments with implementation guidance
- Performance tests include timing assertions
- Security tests include auth validation
- Add FIXME placeholders for actual assertions

### Phase 1: OpenAPI Spec Generation

**Purpose:** Generate machine-readable API specifications from TypeScript Lambda code.

**See:** @references/openapi-generation.md for detailed guide

**Process:**
1. Analyze Lambda TypeScript handlers (Read lambda/*/index.ts)
2. Extract route patterns, HTTP methods, request/response types
3. Convert TypeScript types to JSON Schema
4. Generate OpenAPI 3.0 YAML documents
5. Validate specs with swagger-parser

**Example:**
```bash
/compliance --phase openapi --api admin
# → Analyzes lambda/admin/index.ts
# → Generates docs/api/admin-openapi.yaml
# → Validates spec syntax
```

**Output:**
- `docs/api/{api}-openapi.yaml` - OpenAPI 3.0 specification
- Validation report (errors, warnings)

**When to use:**
- New API endpoints added
- Request/response schemas changed
- API documentation needed

### Phase 2: Contract Test Generation

**Purpose:** Generate automated tests that validate API contracts against OpenAPI specs.

**See:** @references/contract-testing.md for detailed guide

**Process:**
1. Read OpenAPI spec from Phase 1
2. Extract paths, methods, request/response schemas
3. Generate Jest test suites with Ajv schema validation
4. Create tests for success, client errors, server errors
5. Mock API Gateway events and AWS services

**Example:**
```bash
/compliance --phase contract --api admin
# → Reads docs/api/admin-openapi.yaml
# → Generates lambda/admin/__tests__/contract.test.ts
# → Creates 40+ schema validation tests
```

**Output:**
- `lambda/{api}/__tests__/contract.test.ts` - Jest test suite
- Test execution report (pass/fail counts)

**When to use:**
- After generating OpenAPI specs
- Before deploying API changes
- When adding new endpoints

### Phase 3: Test Coverage Analysis

**Purpose:** Identify untested code paths and generate missing tests.

**See:** @references/coverage-analysis.md for detailed guide

**Process:**
1. Run Jest with --coverage flag
2. Parse coverage reports (lcov, json)
3. Identify functions/branches below threshold
4. Generate test cases (happy path, errors, edge cases)
5. Mock AWS SDK services (Cognito, S3, DynamoDB)

**Example:**
```bash
/compliance --phase coverage --lambda admin
# → Runs: cd lambda/admin && npm test -- --coverage
# → Parses coverage report
# → Identifies 12 untested functions
# → Generates lambda/admin/__tests__/index.test.ts
```

**Output:**
- `lambda/{api}/__tests__/index.test.ts` - Generated unit tests
- Coverage report with before/after percentages
- List of remaining gaps

**When to use:**
- Coverage below threshold (70-90%)
- New Lambda functions added
- Before production deployment

### Phase 4: Acceptance Criteria Validation

**Purpose:** Ensure implementation meets documented business requirements.

**See:** @references/acceptance-criteria.md for detailed guide

**Process:**
1. Parse PRDs for acceptance criteria sections
2. Extract individual criteria (Must Have P0, Should Have P1)
3. Search codebase for implementation (Grep, Glob)
4. Calculate compliance percentage
5. Generate actionable compliance report

**Example:**
```bash
/compliance --phase acceptance --prd PRD-ADMIN-API.md
# → Parses docs/archive/root/PRD-ADMIN-API.md
# → Extracts 15 acceptance criteria
# → Searches codebase for implementation
# → Calculates compliance: 87% (13/15 met)
# → Generates docs/compliance-report.md
```

**Output:**
- `docs/compliance-report.md` - Compliance status and gaps
- GitHub issues for missing criteria (optional)

**When to use:**
- Before feature release
- During requirement reviews
- When PRDs are updated

## Configuration

The skill reads settings from `config.yaml`:

```yaml
# Phase 1: OpenAPI Generation
openapi:
  enabled: true
  output_dir: "docs/api"
  validate: true

  apis:
    - name: admin
      path: lambda/admin/index.ts
    - name: referral
      path: lambda/referral/index.ts

# Phase 2: Contract Tests
contract:
  enabled: true
  output_pattern: "lambda/{api}/__tests__/contract.test.ts"

# Phase 3: Test Coverage
coverage:
  enabled: true
  thresholds:
    lambda: 80
    infrastructure: 70

# Phase 4: Acceptance Criteria
acceptance:
  enabled: true
  sources:
    - docs/archive/root/PRD-*.md
```

**Customize:**
```bash
# Add new API
yq e '.openapi.apis += {"name": "auth", "path": "lambda/auth/index.ts"}' -i config.yaml

# Adjust coverage threshold
yq e '.coverage.thresholds.lambda = 90' -i config.yaml

# Disable phase
yq e '.contract.enabled = false' -i config.yaml
```

## Usage Examples

### Example 1: Full Compliance Scan

```bash
/compliance

# Output:
# ✓ Phase 1: OpenAPI Generation
#   → admin: 8 endpoints documented (docs/api/admin-openapi.yaml)
#   → referral: 6 endpoints documented (docs/api/referrals-openapi.yaml)
#
# ✓ Phase 2: Contract Tests
#   → admin: 48 tests generated, all passing
#   → referral: 36 tests generated, all passing
#
# ✓ Phase 3: Coverage Analysis
#   → admin: 45% → 82% (generated 23 tests)
#   → referral: 91% (no gaps)
#
# ✓ Phase 4: Acceptance Criteria
#   → PRD-ADMIN-API.md: 13/15 criteria met (87%)
#   → PRD-REFERRAL-API.md: 8/8 criteria met (100%)
#
# Compliance Score: 92% (21/23 criteria met)
# See: docs/compliance-report.md for details
```

### Example 2: Single API Validation

```bash
/compliance --api admin

# Output:
# ✓ Analyzing lambda/admin/index.ts
# ✓ Generated docs/api/admin-openapi.yaml (8 endpoints)
# ✓ Validated spec: no errors
# ✓ Generated 48 contract tests
# ✓ Coverage: 45% → 82%
# ✓ Compliance: 87% (13/15 criteria met)
#
# Gaps:
#   - AC-03: Email notifications on user suspension (not implemented)
#   - AC-12: Audit log retention policy (not tested)
```

### Example 3: Phase-Specific Execution

```bash
# Just generate OpenAPI specs
/compliance --phase openapi
# → docs/api/admin-openapi.yaml
# → docs/api/referrals-openapi.yaml

# Just run coverage analysis
/compliance --phase coverage
# → Analyzes all Lambdas
# → Generates missing tests
# → Reports new coverage percentages
```

## Expected Artifacts

After running `/compliance`, these files are created or updated:

**OpenAPI Specifications:**
```
docs/api/
├── admin-openapi.yaml       # Admin API (8 endpoints)
├── referrals-openapi.yaml   # Referral API (6 endpoints)
└── auth-edge-openapi.yaml   # Lambda@Edge auth (3 endpoints)
```

**Contract Tests:**
```
lambda/admin/__tests__/
└── contract.test.ts         # 48 schema validation tests

lambda/referral/__tests__/
└── contract.test.ts         # 36 schema validation tests
```

**Unit Tests:**
```
lambda/admin/__tests__/
└── index.test.ts            # Generated unit tests (coverage gaps)
```

**Reports:**
```
docs/
└── compliance-report.md     # Compliance status, gaps, recommendations
```

## Integration

**With other skills:**
- `/gh:commit` - Reference compliance artifacts in commit messages
- `/mr` - Include compliance report in PR descriptions
- `/code-review` - Validate specs and tests before review

**With CI/CD:**
```yaml
# .github/workflows/compliance.yml
- name: Validate API Compliance
  run: /compliance --api admin
```

## Troubleshooting

**Issue: OpenAPI generation fails with "Cannot find route handlers"**
- Check: Lambda handler uses API Gateway proxy format
- Fix: Ensure handler exports routes with `httpMethod` and `path` properties
- See: @references/openapi-generation.md for supported patterns

**Issue: Contract tests fail with schema validation errors**
- Check: OpenAPI spec matches actual response structure
- Fix: Regenerate spec or update TypeScript types
- Debug: Add `console.log(JSON.stringify(response, null, 2))` to Lambda handler

**Issue: Coverage analysis shows 0% coverage**
- Check: Jest configured correctly (`jest.config.js`)
- Fix: Run `npm test -- --coverage` manually to verify
- See: @references/coverage-analysis.md for Jest setup

**Issue: Acceptance criteria extraction finds 0 criteria**
- Check: PRD uses supported headings ("## Acceptance Criteria", "Must Have (P0)")
- Fix: Update PRD format or adjust `acceptance.sources` in config.yaml
- See: @references/acceptance-criteria.md for supported patterns

**Issue: Compliance report shows false negatives**
- Check: Search patterns in `acceptance-criteria.md` are accurate
- Fix: Adjust Grep patterns to match implementation style
- Debug: Run searches manually to verify results

## Best Practices

**1. Run compliance before PRs**
- Catches missing tests early
- Ensures API contracts are documented
- Validates business requirements

**2. Keep OpenAPI specs in sync**
- Regenerate specs after API changes
- Version specs alongside code
- Use specs for API documentation

**3. Treat contract tests as regression tests**
- Run on every commit (via CI/CD)
- Block PRs if schemas break
- Update tests when specs change

**4. Address coverage gaps incrementally**
- Focus on critical paths first (auth, data mutations)
- Aim for 80%+ on Lambdas, 70%+ on infrastructure
- Document why uncovered code is acceptable (if any)

**5. Link compliance reports to GitHub issues**
- Create issues for missing criteria
- Reference issues in PRs
- Track compliance over time

## Advanced Usage

**Custom API patterns:**
```yaml
# config.yaml
openapi:
  apis:
    - name: custom
      path: lambda/custom/index.ts
      base_path: /api/v2/custom
      auth: cognito
```

**Override thresholds:**
```bash
/compliance --phase coverage --threshold 90
```

**Generate specific test types:**
```bash
/compliance --phase contract --scenarios success,client_errors
```

**Multi-PRD validation:**
```bash
/compliance --phase acceptance --prd "docs/archive/root/PRD-*.md"
```

## Resources

- **OpenAPI Generation Guide:** @references/openapi-generation.md
- **Contract Testing Guide:** @references/contract-testing.md
- **Coverage Analysis Guide:** @references/coverage-analysis.md
- **Acceptance Criteria Guide:** @references/acceptance-criteria.md
- **Example Workflows:** @references/examples.md
- **Configuration:** config.yaml

## Architecture

```
Compliance Skill
├── SKILL.md (this file)
├── config.yaml (settings)
└── references/
    ├── openapi-generation.md (TypeScript → OpenAPI)
    ├── contract-testing.md (OpenAPI → Jest tests)
    ├── coverage-analysis.md (Coverage gaps → Tests)
    ├── acceptance-criteria.md (PRDs → Compliance)
    └── examples.md (Complete workflows)
```

**Design principles:**
- **Modular:** Each phase is independent and optional
- **Incremental:** Run single phases or full scan
- **Automated:** Generates artifacts, not just reports
- **Traceable:** Links commits → issues → PRDs → code

## Validation

The skill self-validates by:
1. Checking OpenAPI specs with swagger-parser
2. Running generated tests with Jest
3. Verifying coverage thresholds
4. Cross-referencing PRD criteria with code

**No manual verification needed** - artifacts are tested during generation.

## Contributing

To extend the skill:

1. Add new API patterns to `openapi-generation.md`
2. Add test generators to `contract-testing.md`
3. Add PRD parsing patterns to `acceptance-criteria.md`
4. Update `config.yaml` with new options
5. Add examples to `examples.md`

Keep reference docs focused (<200 lines each).
