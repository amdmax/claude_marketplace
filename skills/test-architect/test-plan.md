---
name: test-architect:test-plan
description: Generate a structured per-story YAML test plan from the active story's implementation brief. Output path is .agile-dev-team/testing/{story_id}/test-plan.yaml. Clusters tests by level (unit, integration, api, ui, e2e) with Given/When/Then cases. All entries start with status: red.
---

# test-plan

Generate a structured YAML test plan document from the active story's implementation brief.

## Input

Read `.agile-dev-team/development-progress.yaml`:
- `storyId` → `test_plan.story_id`
- `title` or `storyTitle` → `test_plan.title`
- `teamState.implementationBrief` → source of interface contracts, behaviors, and test strategy

## Output

Write `.agile-dev-team/testing/{story_id}/test-plan.yaml` where `{story_id}` is the value read from `development-progress.yaml`. Example: `.agile-dev-team/testing/AIGWS-270/test-plan.yaml`.

Structure:

```yaml
test_plan:
  story_id: "AIGWS-XXX"
  title: "Human-readable story title"
  generated_at: "<ISO-8601 timestamp>"
  levels:
    unit:
      - id: "UT-001"
        description: "what behavior is tested"
        file: "tests/unit/<feature>.test.ts"
        subject: "FunctionName or module"
        cases:
          - scenario: "happy path"
            given: "..."
            when: "..."
            then: "..."
          - scenario: "error path"
            given: "..."
            when: "..."
            then: "..."
        status: red
    integration:
      - id: "IT-001"
        description: "what behavior is tested"
        file: "tests/integration/<feature>.test.ts"
        subject: "FunctionName or module"
        cases:
          - scenario: "happy path"
            given: "..."
            when: "..."
            then: "..."
        status: red
    api:
      - id: "API-001"
        description: "what endpoint behavior is tested"
        file: "tests/integration/<endpoint>.test.ts"
        subject: "HTTP method + path"
        cases:
          - scenario: "success response"
            given: "..."
            when: "..."
            then: "..."
          - scenario: "error response"
            given: "..."
            when: "..."
            then: "..."
        status: red
    ui:
      - id: "UI-001"
        description: "what component behavior is tested"
        file: "tests/unit/<component>.test.ts"
        subject: "ComponentName"
        cases:
          - scenario: "renders correctly"
            given: "..."
            when: "..."
            then: "..."
        status: red
    e2e:
      - id: "E2E-001"
        description: "what user journey is tested"
        file: "tests/e2e/<journey>.test.ts"
        subject: "user flow description"
        cases:
          - scenario: "complete flow"
            given: "..."
            when: "..."
            then: "..."
        status: red
```

## Rules

1. **Only include levels relevant to the story** — omit any level that has no tests (no empty arrays)
2. **`status` is always `red`** at generation time — tests do not exist yet
3. **ID prefixes by level:**
   - Unit → `UT-NNN`
   - Integration → `IT-NNN`
   - API → `API-NNN`
   - UI → `UI-NNN`
   - E2E → `E2E-NNN`
4. **Every test case must follow Given/When/Then format**
5. **File paths must match `jest.config.ts` `testMatch` globs:**
   - `unit` → `tests/unit/**/*.test.ts`
   - `integration` → `tests/integration/**/*.test.ts`
   - `e2e` → `tests/e2e/**/*.test.ts`
   - `api` → `tests/integration/**/*.test.ts` (API tests live in integration project)
   - `ui` → `tests/unit/**/*.test.ts` (uses `testEnvironment: jsdom`)
6. **`generated_at`** must be the current ISO-8601 datetime (UTC)
7. **This file is the source of truth** — the `implement-tests` command must implement exactly the tests listed here, no more, no less
8. **One plan per story** — the output path is always scoped to `{story_id}`. Never overwrite another story's plan.
