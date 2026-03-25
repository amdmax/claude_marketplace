---
name: test-architect:implement-tests
description: Read the active story's per-story test plan and write all failing test files (TDD red phase) following codebase conventions. Escalates to PM if no test plan exists at .agile-dev-team/testing/{story_id}/test-plan.yaml. Discovers mock patterns, import order, describe structure, and assertion style from existing tests before writing any code.
---

# implement-tests

Read the active story's test plan and write all failing test files (TDD red phase) following codebase conventions.

## Step 1: Resolve story and test plan

1. Read `.agile-dev-team/development-progress.yaml` → extract `storyId`
2. Resolve test plan path: `.agile-dev-team/testing/{storyId}/test-plan.yaml`
3. Check if the file exists:
   - **If missing:** Stop immediately. Send a message to the PM agent:
     ```
     ESCALATION: No test plan found at .agile-dev-team/testing/{storyId}/test-plan.yaml.
     Run /test-architect:test-plan first to generate it, then re-invoke /test-architect:implement-tests.
     ```
     Do not write any test files.
   - **If present:** Continue to Step 2.

## Step 2: Learn codebase conventions

Before writing a single line of test code, read existing test files to extract patterns:

```
tests/unit/**/*.test.ts        → unit conventions
tests/integration/**/*.test.ts → integration + mock conventions
tests/e2e/**/*.test.ts         → e2e/puppeteer conventions
```

Extract and apply:
- **Import style:** named vs default, path aliases, order (mocks before imports for integration)
- **Mock pattern:** `jest.mock()` placement, class-based mock factories, `mockSend`/`jest.fn()` style
- **Env setup:** `process.env.*` set before imports for Lambda tests
- **Describe structure:** top-level `describe` → nested `describe` per concern → `test()`
- **Lifecycle hooks:** `beforeAll` vs `beforeEach`, what belongs in each
- **Assertion style:** `expect(x).toBe()`, `.toEqual()`, `.toContain()`, `.toBeNull()`
- **File naming:** `{feature-name}.test.ts` (kebab-case)
- **Timeouts:** unit/integration 30 000 ms, e2e 60 000 ms (match `jest.config.ts`)
- **E2E specifics:** puppeteer `Browser`/`Page` lifecycle, `BASE` constant, `waitUntil: 'networkidle2'`

## Step 3: Write failing tests

For each entry in `test_plan.levels.*`:

1. Determine the target file path from the plan entry's `file` field
2. If the file already exists, read it first — append missing test cases rather than overwriting
3. Write the test file implementing all `cases` under `describe` blocks that mirror the plan's `scenario` values
4. Each test case maps directly from the plan:
   - `given` → setup / arrange
   - `when` → act (call the subject)
   - `then` → assertion (expect)
5. Tests must fail because **the implementation does not exist yet** — import the expected interface from the brief but do not implement it

### Level-specific rules

| Level | File glob | testEnvironment | Notes |
|-------|-----------|-----------------|-------|
| `unit` | `tests/unit/**/*.test.ts` | `jsdom` | No network calls, no AWS SDK |
| `ui` | `tests/unit/**/*.test.ts` | `jsdom` | Component render tests, DOM assertions |
| `integration` | `tests/integration/**/*.test.ts` | `node` | Mock AWS SDK; set `process.env` before imports |
| `api` | `tests/integration/**/*.test.ts` | `node` | Same as integration; test HTTP contract |
| `e2e` | `tests/e2e/**/*.test.ts` | `node` | Puppeteer; use global setup/teardown; `maxWorkers: 1` |

### What makes a test RED (correct failure)

- Import resolves but the exported function/class does not exist yet → `TypeError: X is not a function`
- Or the function exists but returns wrong shape → assertion fails
- **Not acceptable:** syntax errors, missing imports that can't be resolved, wrong file path

## Step 4: Confirm RED

Run tests scoped to the new files only:

```bash
npx jest --testPathPattern="tests/(unit|integration|e2e)/<feature>"
```

For each test file:
- All tests must **fail**
- Failure reason must be a contract violation, not a syntax/import error
- If a test fails due to a syntax or import error, fix it and re-run

## Step 5: Stage and report

```bash
git add tests/
```

Report back a summary table:

| ID | File | Cases | Failure reason |
|----|------|-------|----------------|
| UT-001 | tests/unit/foo.test.ts | 3 | TypeError: buildFoo is not a function |
| IT-001 | tests/integration/bar.test.ts | 2 | Expected 200, received undefined |
