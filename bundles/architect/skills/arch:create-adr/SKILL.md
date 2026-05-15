---
name: arch:create-adr
description: Generate Architecture Decision Records in MADR format with auto-numbering. Analyzes story context, NFRs, and technical context to create comprehensive ADRs. Invokable with /arch:create-adr.
---

# Create Architecture Decision Record

## Overview

Generates Architecture Decision Records (ADRs) in MADR format:

1. Analyzes story context to determine if ADR is needed
2. Auto-numbers ADRs by scanning existing `$ADR_DIR`
3. Extracts decision drivers from NFRs and technical context
4. Identifies options with pros/cons
5. Writes MADR-format file and updates active story

ADRs document **why** decisions were made. Full template: [references/madr-template.md](references/madr-template.md).

## When to Create an ADR

**✅ Create** when the story involves:

| Category | Examples |
|----------|----------|
| New AWS service integration | Adding S3, DynamoDB, SQS for first time |
| Auth/authz changes | New auth flow, SSO, permission model |
| DB schema changes | New tables, major migrations, indexing strategy |
| Breaking API changes | Endpoint deprecation, version upgrades |
| Security-sensitive logic | Payment processing, PII, encryption |
| Technology/library selection | React vs Vue, Stripe vs PayPal |
| Significant performance trade-offs | Caching, pre-computation, denormalization |
| Architecture pattern changes | Monolith → microservices, sync → async |

**❌ Skip** for: simple bug fixes, UI-only changes, documentation updates, following established patterns, small refactors, routine maintenance.

## Workflow

### Step 1: Verify Prerequisites

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.yaml"
[ -f "$STORY_FILE" ] || { echo "❌ No active story found"; exit 1; }
```

Warn if NFRs or context are missing, but continue.

### Step 2: Load Story Data

Read `.agile-dev-team/active-story.yaml`. Extract `issueNumber`, `title`, `body`, `nfrs`, `context`, `labels`.

### Step 3: Determine if ADR is Needed

Skip if: bug fix without security label, docs-only, or following an established pattern with no alternatives. Consult user if unclear. See [decision logic](references/implementation-examples.md#decision-logic).

### Step 4: Auto-Number the ADR

```bash
ADR_DIR="${ADR_DIR:-docs/adr}"
mkdir -p "$ADR_DIR"
HIGHEST=$(ls "$ADR_DIR" 2>/dev/null | grep -o "^[0-9]*" | sort -n | tail -1)
[ -z "$HIGHEST" ] && NEXT="0001" || NEXT=$(printf "%04d" $((10#$HIGHEST + 1)))
```

Format: four zero-padded digits (`0001`, `0002`, ..., `9999`).

### Step 5: Generate Title Slug

Extract key technical terms from title/prompt (lowercase, hyphenated, max 5 words). Strip stop words: `implement add create update fix improve the a an for with`.

Example: "Implement Payment Checkout with Stripe" → `stripe-payment-checkout`

Output path: `$ADR_DIR/{NNNN}-{slug}.md`

### Step 6: Extract Decision Drivers from NFRs

Map each collected NFR to a decision driver string (performance, security, reliability, cost, technical constraints). See [NFR mapping](references/implementation-examples.md#nfr-mapping).

Example output:
```markdown
* Performance: 1000–10000 daily users, <2s max response time
* Security: PII, Payment data, PCI-DSS and GDPR compliance required
* Cost: Standard budget, prefer Lambda, DynamoDB, S3
* Constraint: AWS Lambda timeout (30s max)
```

### Step 7: Identify Options

Use `context.preferredApproach` as Option 1. Generate ≥ 2 alternatives from related ADRs or industry knowledge. Always include a "do-nothing / defer" option when no obvious alternative exists. See [alternatives generation](references/implementation-examples.md#alternatives-generation).

### Step 8: Generate Pros/Cons for Each Option

For each option: analyze against decision drivers, assign Good/Neutral/Bad bullets, estimate Cost and Complexity (Low/Medium/High). See [pros/cons examples](references/implementation-examples.md#proscons-example-stripe-checkout).

### Step 9: Write Decision Outcome

Chosen option + rationale tying back to decision drivers. List consequences. Add optional Confirmation criteria (metrics/tests to validate).

### Step 10: Add Implementation Notes

Include backend code patterns, infrastructure config, testing strategy, migration steps, rollback plan under a `### Implementation Notes` subsection of More Information.

### Step 11: Add More Information

Link story issue, related ADRs, and external docs.

### Step 12: Write ADR File

Assemble all sections per [MADR template](references/madr-template.md) and write to `$ADR_DIR/{NNNN}-{slug}.md`. See [file write example](references/implementation-examples.md#file-write).

### Step 13: Update Active Story

Add ADR reference to `.agile-dev-team/active-story.yaml` with `number`, `filePath`, `title`, `status: proposed`, `createdAt`.

### Step 14: Report Success

```
✓ Architecture Decision Record Created

ADR-{NNNN}: {slug}
Location: $ADR_DIR/{NNNN}-{slug}.md
Decision: {chosen option}
Options:  {N} considered
Status:   proposed

Next Steps:
  1. Review ADR for accuracy and completeness
  2. Update status to "accepted" when approved
  3. Reference ADR in implementation PR
  4. Run /dev-story to begin implementation

✓ ADR reference saved to .agile-dev-team/active-story.yaml
```

## Error Handling

| Error | Response |
|-------|----------|
| No active story | `❌ No active story found. Run /fetch-story first.` |
| NFRs/context missing | Warn — offer to continue, cancel, or run /play-story |
| Directory creation failed | `❌ Failed to create $ADR_DIR. Check permissions.` |
| File write failed | `❌ Failed to write ADR file. Check disk space and permissions.` |
| ADR not needed | `ℹ️ ADR not required. Skipping — run /dev-story to start implementation.` |

## Integration

```
/play-story
  ↓
1. /fetch-story
2. /gather-nfr
3. /gather-context
4. /arch:create-adr  ← this skill (conditional)
5. Summary
```

**Post-implementation:** update ADR status to `accepted`, add actual metrics, link implementation PR.

## Supporting Files

- [references/madr-template.md](references/madr-template.md) — full MADR format template
- [references/implementation-examples.md](references/implementation-examples.md) — decision logic, NFR mapping, pros/cons generation, file write
