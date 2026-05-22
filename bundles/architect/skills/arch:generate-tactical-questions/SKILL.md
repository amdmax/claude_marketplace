---
name: arch:generate-tactical-questions
description: >
  Generates implementation-level questions about conventions and patterns already
  established in the codebase. Covers integration patterns, data schemas, API conventions,
  code conventions, testing strategy, and deployment. Every question includes a
  codebase_hint pointing scout to where the answer likely lives. Writes to
  $STORIES_DIR/{issueNumber}/tactical-questions.yaml (created if absent).
argument-hint: "[issue_number]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
write-paths:
  - $AGENT_DOCS_DIR/
---

# arch:generate-tactical-questions

Surfaces the implementation-level unknowns before the architect maps acceptance criteria
to code. Every question here has a `codebase_hint` — a pointer that tells scout exactly
where in the codebase to look for the answer.

---

## Workflow

### Step 1 — Load context

```bash
STORY_FILE="${AGENT_DOCS_DIR:-docs}/active-story.yaml"
if [ ! -f "$STORY_FILE" ]; then
  echo "ERROR  No active story. Run /github:story-fetch first."
  exit 1
fi
ISSUE_NUMBER=$(grep 'issueNumber:' "$STORY_FILE" | awk '{print $2}')
STORIES_DIR="${STORIES_DIR:-agent-docs/stories}"
OUTPUT_DIR="${STORIES_DIR}/${ISSUE_NUMBER}"
OUTPUT_PATH="${OUTPUT_DIR}/tactical-questions.yaml"
STRATEGIC_PATH="${OUTPUT_DIR}/strategic-questions.yaml"
mkdir -p "$OUTPUT_DIR"
```

Read:
- `$AGENT_DOCS_DIR/active-story.yaml` — story title, issueNumber, ACs, NFRs
- `$STORIES_DIR/{issueNumber}/strategic-questions.yaml` — avoid duplicating strategic answers
- `$ADR_DIR` — skip questions already decided in ADRs

### Step 2 — Analyse story scope

For each AC, identify which tactical domains are touched:

| AC involves… | Category to generate questions for |
|---|---|
| Calling or exposing an API / event / message | `integration_patterns` |
| Reading or writing persistent data | `data_schemas` |
| Exposing a new HTTP endpoint | `api_conventions` |
| Adding new source files or business logic | `code_conventions` |
| Requiring test coverage | `testing` |
| Shipping to an environment | `deployment` |

Skip any category not touched by any AC.

### Step 3 — Generate questions

For each relevant category, generate targeted questions from the catalogue below.
Skip questions whose answers are already in ADRs or strategic-questions.yaml.
Add `codebase_hint` to every question — tell scout where to look.

#### Category: `integration_patterns`

- Is synchronous (REST/GraphQL) or asynchronous (event/queue) integration preferred here?
  - *hint: look for existing event publishers or SQS/SNS producers in the codebase*
- What event schema format is used (JSON Schema, Avro, Protobuf)?
  - *hint: look for schema files or event type definitions*
- What is the retry and dead-letter queue policy for async consumers?
  - *hint: look for existing consumer Lambda or ECS handler configurations*
- Is idempotency enforced? What mechanism is used?
  - *hint: look for idempotency keys or deduplication logic in existing handlers*
- Are there circuit breaker or timeout standards for outbound calls?
  - *hint: look for HTTP client wrappers or middleware*

#### Category: `data_schemas`

- What schema migration toolchain is in use (Flyway, Liquibase, Prisma, TypeORM)?
  - *hint: look for migration files or ORM configuration*
- What is the naming convention for tables, columns, and indexes?
  - *hint: look at existing migration files or entity definitions*
- Is soft-delete (`deletedAt`) or hard-delete the convention?
  - *hint: look for existing entity base classes or repository patterns*
- Is there a schema registry for event schemas?
  - *hint: look for schema registry config or EventBridge schema references*
- What is the convention for audit fields (createdAt, updatedAt, createdBy)?
  - *hint: look for base entity or abstract model classes*

#### Category: `api_conventions`

- What versioning strategy is used for HTTP APIs (URL path, header)?
  - *hint: look at existing route definitions or API Gateway config*
- What authentication mechanism is expected on new endpoints (JWT, API key, Cognito)?
  - *hint: look for auth middleware or Lambda authoriser definitions*
- What is the standard error response envelope format?
  - *hint: look for error handler middleware or existing 4xx/5xx responses*
- What pagination style is used (cursor, offset, page)?
  - *hint: look for existing list/query endpoints*
- Is there a rate limiting or throttling policy to inherit?
  - *hint: look for API Gateway usage plan or middleware config*

#### Category: `code_conventions`

- What dependency injection pattern or container is in use?
  - *hint: look for DI config files or container setup (tsyringe, InversifyJS, NestJS)*
- What is the error handling standard (Result type, exceptions, error codes)?
  - *hint: look for error base classes or service-level try/catch patterns*
- What logging library and format is expected (structured JSON, correlation IDs)?
  - *hint: look for logger instantiation in existing services*
- Is there a domain model or DTO separation pattern to follow?
  - *hint: look for dto/, domain/, or model/ directories*
- What linting / formatting rules are enforced?
  - *hint: look for .eslintrc, .prettierrc, or similar config files*

#### Category: `testing`

- What is the minimum unit test coverage threshold?
  - *hint: look for jest.config.ts coverageThreshold or similar*
- What is the strategy for test data — factories, fixtures, or seeds?
  - *hint: look for test/fixtures/, test/factories/, or seeder files*
- Are mocks preferred over integration tests for external services?
  - *hint: look for existing `__mocks__` directories or nock/msw setups*
- What is the integration test strategy — real DB or in-memory?
  - *hint: look for test database config or testcontainers usage*
- Are contract tests required for new API endpoints?
  - *hint: look for Pact or OpenAPI contract test files*

#### Category: `deployment`

- What are the required CI/CD pipeline stages before production?
  - *hint: look for .github/workflows/ or buildspec.yml*
- What is the environment promotion strategy (dev → staging → prod)?
  - *hint: look for environment-specific config or deploy scripts*
- Is a feature flag required to gate this feature in production?
  - *hint: look for feature flag service config (LaunchDarkly, AWS AppConfig)*
- Is blue/green or canary deployment required for this change?
  - *hint: look for CodeDeploy config or ECS deployment config*
- Are there post-deployment smoke tests or health check gates?
  - *hint: look for post-deploy test scripts or deployment hooks*

### Step 4 — Deduplicate

Before writing, check each question:

```bash
# Check ADRs
grep -r "QUESTION_TOPIC" "${ADR_DIR:-docs/adr}" 2>/dev/null
# Check strategic answers
grep "QUESTION_TOPIC" "${STRATEGIC_PATH}" 2>/dev/null
```

If already answered, set `answer:` to the reference rather than `null`.

### Step 5 — Write output

Write `$STORIES_DIR/{issueNumber}/tactical-questions.yaml`:

```yaml
generated_at: "YYYY-MM-DD"
story: "{issueNumber} — {title}"
questions:
  - id: TQ-001
    category: integration_patterns
    question: "Is synchronous or asynchronous integration preferred for the order event?"
    context: "AC-2 requires publishing an order-placed event"
    codebase_hint: "Look for existing event publishers under src/events/ or src/messaging/"
    answer: null

  - id: TQ-002
    category: data_schemas
    question: "What is the soft-delete convention for order records?"
    context: "AC-4 requires order cancellation without data loss"
    codebase_hint: "Look for deletedAt fields or BaseEntity class in src/entities/"
    answer: null
```

IDs are sequential: `TQ-001`, `TQ-002`, …

If the file already exists, merge: preserve existing `answer:` values, append new questions.

### Step 6 — Report

```
arch:generate-tactical-questions: {N} questions written

  integration_patterns  {n} questions
  data_schemas          {n} questions
  api_conventions       {n} questions
  code_conventions      {n} questions
  testing               {n} questions
  deployment            {n} questions

  {m} already answered (from ADRs / strategic-questions.yaml)

Output: $STORIES_DIR/{issueNumber}/tactical-questions.yaml
Next:   send scout to answer both strategic and tactical question files.
```

---

## Output

| File | Content |
|------|---------|
| `$STORIES_DIR/{issueNumber}/tactical-questions.yaml` | Structured question list with `codebase_hint` on every question |

---

## Error Handling

| Condition | Behaviour |
|-----------|-----------|
| No active story | Error: run `/github:story-fetch` first |
| No ACs in story | Warn and generate only code_conventions + deployment questions |
| File already exists | Merge: preserve answers, append new questions |
