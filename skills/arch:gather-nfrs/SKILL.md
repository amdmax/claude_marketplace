---
name: arch:gather-nfrs
description: Collect non-functional requirements through interactive Q&A. Asks targeted questions about performance, scalability, security, reliability, and cost constraints. Invokable with /gather-nfrs.
---

# Gather Non-Functional Requirements

Reads the active story, tailors questions to its context, collects responses across 6 NFR categories, and writes the results to `.agile-dev-team/technical-context.json`.

## Workflow

### Step 1: Verify active story

Read `.agile-dev-team/active-story.json`. If missing → error and exit. See @references/error-handling.md.

### Step 2: Analyze story context

Extract `title`, `labels`, and `body` to determine which NFR categories to ask and which to skip.

**Category applicability:**

| Category | Skip if label/body contains |
|----------|----------------------------|
| Performance | `batch-job` |
| Scalability | `poc`, `prototype` |
| Data & Storage | `read-only` |
| Security | Never skip |
| Reliability | `experimental`, `test` |
| Cost | `existing infrastructure` / `no new services` |

### Step 3–8: Ask category questions

Use AskUserQuestion tool for each applicable category. For question options, defaults, and skip messages per category: see @references/questions.md.

For recommendation logic (how labels influence defaults) and multi vs single-select rules: see @references/question-strategy.md.

If NFRs already exist on the story, prompt the user before overwriting. See @references/error-handling.md.

### Step 9: Write results

Merge collected NFRs into `.agile-dev-team/technical-context.json` under the `nfrs` key. For the exact JSON schema and merge code: see @references/output-schema.md.

Skipped categories are stored as `{ "skipped": true, "reason": "..." }`.

### Step 10: Report summary

Print each collected category with its values, then:

```
✓ NFRs saved to .agile-dev-team/technical-context.json

Next steps:
  Run /gather-context to collect technical context
  Or run /play-story to continue the full workflow
```

## Integration

```
/play-story
  ↓
/fetch-story → /gather-nfrs (this) → /gather-context → /arch:create-adr
```

- **→ /arch:create-adr**: NFRs become Decision Drivers; security compliance informs technology choices
- **→ /gather-context**: Security requirements guide context search (auth patterns, Lambda examples)
