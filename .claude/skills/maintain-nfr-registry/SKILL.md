---
name: maintain-nfr-registry
author: "@amdmax"
description: Read or update the non-functional requirements registry at {{REGISTRY_DIR}}/nfr-registry.yaml. Use when the architect maps NFRs to a story's implementation brief, when new project-wide NFRs are established, or when an agent needs to query which NFRs apply to a given story or category. Distinguishes project-level NFRs (permanent, all stories) from story-level NFRs (scoped to one issue).
---

# Maintain NFR Registry

Registry file: `{{REGISTRY_DIR}}/nfr-registry.yaml`

For schema, categories, and examples: see @.claude/skills/maintain-nfr-registry/references/schema.md

## Operations

### Read: List NFRs

```bash
cat {{REGISTRY_DIR}}/nfr-registry.yaml
```

To list only project-level NFRs:
```bash
grep -B 1 'scope: project' {{REGISTRY_DIR}}/nfr-registry.yaml
```

To list NFRs for a specific story:
```bash
grep -B 1 "storyRef: <ISSUE-NNN>" {{REGISTRY_DIR}}/nfr-registry.yaml
```

### Write: Add a new NFR

1. Read `{{REGISTRY_DIR}}/nfr-registry.yaml` (create from template in schema.md if it doesn't exist)
2. Find the highest existing `NFR-NNN` id and increment by 1
3. Append the new entry under `nfrs:` using the schema fields
4. Set `scope: project` for permanent requirements; `scope: story` + `storyRef: <ISSUE-NNN>` for story-scoped

### Update: Refine an existing NFR

Edit the `requirement` or `rationale` field in place. Do not change the id.

## Rules

- Project-level NFRs are never deleted — only updated
- Story-level NFRs may only be added, not retroactively changed after a story closes
- `storyRef` is required when `scope: story`; set to `null` for project-level
- `requirement` must be a testable, unambiguous statement
