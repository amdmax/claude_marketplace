---
name: arch:adr-yaml
description: >
  Generate a structured YAML Architecture Decision Record (MADR format) at
  $ADR_DIR/NNNN-slug.adr.yaml. Validates schema automatically via PostToolUse hook.
  Use /arch:adr-yaml to produce machine-readable ADR data before rendering with /arch:adr-render.
tags: [architecture, adr, yaml, decision-records, madr]
hooks:
  PostToolUse:
    - matcher: Write
      hooks:
        - type: command
          command: python3 $SKILL_DIR/scripts/validate-adr-yaml.py
---

# Generate ADR YAML

## Overview

This skill produces machine-readable Architecture Decision Records as YAML files (`$ADR_DIR/NNNN-slug.adr.yaml`). A PostToolUse hook automatically validates the output against the ADR schema on every write.

**Flow:**
```
/arch:adr-yaml  →  $ADR_DIR/NNNN-slug.adr.yaml  →  [hook validates]
/arch:adr-render →  $ADR_DIR/NNNN-slug.md
```

## Workflow

### Step 1: Check Active Story

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/${AGENT_DOCS_DIR:-docs}/active-story.yaml"
if [ ! -f "$STORY_FILE" ]; then
  echo "⚠️  No active story found at $STORY_FILE"
  echo "   Continuing without story context..."
fi
```

Warn if absent but continue. Extract `issueNumber`, `title`, `nfrs`, and `context` if available.

### Step 2: Auto-Number the ADR

Scan `$ADR_DIR` for files matching `^[0-9]{4}-` (both `*.adr.yaml` and `*.md`):

```bash
ADR_DIR="${ADR_DIR:-docs/adr}"
mkdir -p "$ADR_DIR"

HIGHEST=$(ls "$ADR_DIR" 2>/dev/null | grep -oE "^[0-9]{4}" | sort -n | tail -1)

if [ -z "$HIGHEST" ]; then
  NEXT="0001"
else
  NEXT=$(printf "%04d" $((10#$HIGHEST + 1)))
fi
```

Format: four zero-padded digits (`0001`, `0002`, ..., `9999`).

### Step 3: Generate Slug

Extract key technical terms from story title or user prompt (lowercase, hyphenated, max 5 words). Strip stop words: `implement`, `add`, `create`, `update`, `fix`, `improve`, `integrate`, `the`, `a`, `an`, `for`, `with`.

Examples:
- "Implement Payment Checkout with Stripe" → `stripe-payment-checkout`
- "Add DynamoDB caching layer" → `dynamodb-caching-layer`

### Step 4: Determine Output Path

```
$ADR_DIR/NNNN-slug.adr.yaml

Example: $ADR_DIR/0012-stripe-payment-integration.adr.yaml
```

Create `$ADR_DIR` if it does not exist.

### Step 5: Map Decision Drivers

Pull from `nfrs` in active story (performance, scalability, security, reliability, cost) and any technical constraints from `context`. Format as descriptive strings, e.g.:

```yaml
decisionDrivers:
  - "Performance: <2s response time, 1000 DAU"
  - "Security: PCI-DSS compliance required"
  - "Cost: Standard budget, prefer serverless"
```

### Step 6: Identify Options

Gather at least 2 options from:
1. Preferred approach from `context.preferredApproach` (if set)
2. Industry alternatives for the domain/technology
3. Always include a "do-nothing / defer" option if no obvious alternatives exist

For each option generate:
- `pros`: list of specific advantages tied to decision drivers
- `cons`: list of specific disadvantages
- `cost`: estimated cost (AWS pricing, licensing, etc.)
- `complexity`: `Low`, `Medium`, or `High`

### Step 7: Write YAML File

Write the complete YAML with all MADR sections (see structure below). The PostToolUse hook fires automatically after the Write and runs `validate-adr-yaml.sh`.

**YAML output structure:**

```yaml
adrVersion: "1.0"
id: "ADR-NNNN"
title: "kebab-case-slug"
status: proposed
date: "YYYY-MM-DD"
deciders: []
consulted: []
informed: []

context: |
  Problem statement and background.

decisionDrivers:
  - "Performance: <2s response time"

options:
  - name: "Option A"
    description: "Description of option A."
    pros:
      - "Advantage 1"
    cons:
      - "Disadvantage 1"
    cost: "$0 + 2.9%/txn"
    complexity: Low

  - name: "Option B"
    description: "Description of option B."
    pros:
      - "Advantage 1"
    cons:
      - "Disadvantage 1"
    cost: "$X/month"
    complexity: Medium

decision:
  chosen: "Option A"
  rationale: |
    Rationale text explaining why this option best satisfies the decision drivers.
  consequences:
    - "Good, because ..."
    - "Bad, because ..."
  confirmation: |
    Validation criteria and success metrics.

moreInfo: |
  * [Story Issue #NNN](https://github.com/owner/repo/issues/NNN)
  * [External Documentation](https://example.com)

implementationNotes:
  codePattern: |
    # key code snippet or pseudocode
  migrationSteps:
    - "Step 1"
    - "Step 2"
  testingStrategy: |
    Unit/integration/e2e approach.
  rollbackPlan: |
    Rollback procedure if the decision fails.
```

### Step 8: Hook Fires Automatically

After Write, the PostToolUse hook runs `validate-adr-yaml.sh` which checks:
- Required fields present
- `status` ∈ {proposed, accepted, deprecated, superseded, rejected}
- `id` matches `ADR-NNNN` pattern
- `date` matches `YYYY-MM-DD`
- `options` has ≥ 2 entries with required sub-fields
- `decision.chosen` cross-references an entry in `options[].name`

Exit code 2 = blocking error. Exit code 0 = pass.

### Step 9: Update Active Story + Report

```javascript
story.adr = {
  number: adrNumber,        // "0012"
  filePath: "$ADR_DIR/0012-stripe-payment-integration.adr.yaml",
  status: "proposed",
  createdAt: new Date().toISOString()
};
```

**Report:**
```
✅ ADR YAML created

ADR-0012: stripe-payment-integration
Location: $ADR_DIR/0012-stripe-payment-integration.adr.yaml
Status:   proposed
Options:  3 considered

Decision Drivers:
  • Security: PCI-DSS compliance required
  • Performance: <2s response time
  • Cost: Standard budget

✅ Schema validation passed
✅ Active story updated

Next step: /arch:adr-render → $ADR_DIR/0012-stripe-payment-integration.md
```

## Error Handling

### No Active Story
Warn and continue — use user's current prompt as context source.

### Fewer Than 2 Options
Do not write file. Report:
```
❌ ADR requires at least 2 options. Please provide alternatives.
```

### Hook Validation Failure (exit 2)
```
❌ ADR YAML validation failed
   [field]: [error detail]
Fix the YAML and re-run /arch:adr-yaml.
```

### File Already Exists
Check before writing — if `NNNN-slug.adr.yaml` already exists for the same number, increment to next available number.

## Status Values

| Status | Meaning |
|--------|---------|
| `proposed` | Drafted, not yet approved |
| `accepted` | Approved and active |
| `superseded` | Replaced by a newer ADR |
| `deprecated` | No longer recommended |
| `rejected` | Considered but not chosen |

## Complexity Values

| Value | Meaning |
|-------|---------|
| `Low` | < 1 day, minimal moving parts |
| `Medium` | 1–5 days, moderate complexity |
| `High` | > 5 days, significant risk/effort |

## Integration

```
/play-story
  ↓
1. /fetch-story
2. /gather-nfr
3. /gather-context
4. /arch:adr-yaml     ← this skill (YAML data)
5. /arch:adr-render   ← renders to MADR markdown
```

## Schema Reference

Full JSON Schema: `$SKILL_DIR/schemas/adr.schema.json`
Validation script: `$SKILL_DIR/scripts/validate-adr-yaml.py`
