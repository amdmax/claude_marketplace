---
name: arch:adr-render
description: >
  Convert a docs/adr/NNNN-slug.adr.yaml file into a MADR-format Markdown file.
  Output path is same as input with .md extension. Use after /arch:adr-yaml.
tags: [architecture, adr, markdown, madr, render]
---

# Render ADR YAML to Markdown

## Overview

Converts a structured `*.adr.yaml` file into a human-readable MADR-format Markdown file. Always run `/arch:adr-yaml` first to produce the YAML source.

**Flow:**
```
docs/adr/NNNN-slug.adr.yaml  →  /arch:adr-render  →  docs/adr/NNNN-slug.md
```

## Workflow

### Step 1: Locate Source YAML

Accept an optional path argument:
- `/arch:adr-render docs/adr/0012-stripe-payment-integration.adr.yaml`
- `/arch:adr-render` (no arg) → find the most-recently-modified `*.adr.yaml` in `docs/adr/`

```bash
# No arg: find most recent
SOURCE=$(ls -t docs/adr/*.adr.yaml 2>/dev/null | head -1)

if [ -z "$SOURCE" ]; then
  echo "❌ No *.adr.yaml files found in docs/adr/"
  exit 1
fi
```

### Step 2: Parse and Validate YAML

Read and parse the YAML file. Verify all required fields are present:

| Field | Required |
|-------|---------|
| `id` | ✅ |
| `title` | ✅ |
| `status` | ✅ |
| `date` | ✅ |
| `context` | ✅ |
| `options` (≥ 2) | ✅ |
| `decision.chosen` | ✅ |
| `decision.rationale` | ✅ |
| `decision.consequences` | ✅ |

If any required field is missing, report all absent fields and exit:

```
❌ Cannot render ADR — missing required fields:
   - decision.rationale
   - options (need ≥ 2, found 1)

Fix docs/adr/0012-stripe-payment-integration.adr.yaml and re-run.
```

### Step 3: Determine Output Path

Replace `.adr.yaml` suffix with `.md`:

```
docs/adr/0012-stripe-payment-integration.adr.yaml
         ↓
docs/adr/0012-stripe-payment-integration.md
```

If the `.md` file already exists, confirm overwrite before proceeding:

```
⚠️  docs/adr/0012-stripe-payment-integration.md already exists.
Overwrite? [y/N]
```

### Step 4: Render MADR Markdown

Produce standard MADR format from all YAML fields.

**MADR output template:**

```markdown
---
status: {status}
date: {date}
decision-makers: [{deciders joined by ", "}]
consulted: [{consulted joined by ", "}]
informed: [{informed joined by ", "}]
---

# {id}: {title}

## Context and Problem Statement

{context}

## Decision Drivers

{decisionDrivers as "* item" list}

## Considered Options

{options[].name as "* Option Name" list}

## Decision Outcome

Chosen option: "{decision.chosen}", because {decision.rationale}

### Consequences

{decision.consequences as "* item" list}

### Confirmation

{decision.confirmation}

## Pros and Cons of the Options

### {option.name}

{option.description}

* Good, because {pros[0]}
* Good, because {pros[N]}
* Bad, because {cons[0]}
* Bad, because {cons[N]}
* Cost: {option.cost}
* Complexity: {option.complexity}

[... repeat for each option ...]

## More Information

{moreInfo}

### Implementation Notes

#### Code Pattern

```
{implementationNotes.codePattern}
```

#### Migration Steps

{implementationNotes.migrationSteps as numbered list}

#### Testing Strategy

{implementationNotes.testingStrategy}

#### Rollback Plan

{implementationNotes.rollbackPlan}
```

**Rendering rules:**
- `deciders`, `consulted`, `informed`: render as comma-separated list in YAML front-matter; omit field if empty array
- `decisionDrivers`: render each as `* driver` bullet
- `options`: render each as a `### Option Name` subsection with bullets for pros/cons, cost, complexity
- `decision.consequences`: render each as `* consequence` bullet (preserve "Good, because / Bad, because" prefix if already present)
- `moreInfo`: render as-is (already markdown with links)
- `implementationNotes`: render only the sub-fields that are non-empty
- Fields not present in YAML: omit the corresponding section entirely

### Step 5: Write Markdown File

Write the rendered content to `docs/adr/NNNN-slug.md`.

### Step 6: Report and Next Steps

```
✅ ADR rendered to Markdown

Source: docs/adr/0012-stripe-payment-integration.adr.yaml
Output: docs/adr/0012-stripe-payment-integration.md

Next steps:
  1. Review the rendered ADR for accuracy
  2. Update status to "accepted" when approved
  3. Link ADR in PR description
  4. Run /git:commit to stage and commit both files
```

## MADR Sections Reference

| Section | Source Field | Required |
|---------|-------------|---------|
| YAML front-matter | `status`, `date`, `deciders`, `consulted`, `informed` | ✅ |
| `# {id}: {title}` heading | `id`, `title` | ✅ |
| Context and Problem Statement | `context` | ✅ |
| Decision Drivers | `decisionDrivers` | ⚠️ warn if empty |
| Considered Options | `options[].name` | ✅ |
| Decision Outcome | `decision.chosen`, `decision.rationale` | ✅ |
| Consequences | `decision.consequences` | ✅ |
| Confirmation | `decision.confirmation` | optional |
| Pros and Cons | all `options[]` fields | ✅ |
| More Information | `moreInfo` | optional |
| Implementation Notes | `implementationNotes.*` | optional |

## Error Handling

### File Not Found
```
❌ File not found: docs/adr/0012-stripe-payment-integration.adr.yaml
   Run /arch:adr-yaml to generate it first.
```

### Invalid YAML
```
❌ Failed to parse YAML: docs/adr/0012-stripe-payment-integration.adr.yaml
   [parse error detail]
```

### Write Failure
```
❌ Failed to write docs/adr/0012-stripe-payment-integration.md
   [error detail]
```

## Integration

Designed to run immediately after `/arch:adr-yaml`:

```
/arch:adr-yaml   → produces docs/adr/NNNN-slug.adr.yaml (validated by hook)
/arch:adr-render → produces docs/adr/NNNN-slug.md
/git:commit      → commits both files
```

The YAML source file is the canonical record. The rendered markdown is the human-readable view.
