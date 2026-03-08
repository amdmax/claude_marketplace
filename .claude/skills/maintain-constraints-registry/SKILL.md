---
name: maintain-constraints-registry
author: "@amdmax"
description: Read or update the project constraints registry at {{REGISTRY_DIR}}/constraints.yaml. Use when the architect needs to check project-wide constraints before proposing a design, when a new constraint is established (e.g., "only target AWS", "no GPL libraries"), or when any agent needs to validate that a proposed approach doesn't violate a hard constraint. Hard constraints are blocking; soft constraints are advisory.
---

# Maintain Constraints Registry

Registry file: `{{REGISTRY_DIR}}/constraints.yaml`

For schema, categories, enforcement levels, and examples: see @.claude/skills/maintain-constraints-registry/references/schema.md

## Operations

### Read: List constraints

```bash
cat {{REGISTRY_DIR}}/constraints.yaml
```

To check hard constraints only (blocking):
```bash
grep -B 3 'enforcement: hard' {{REGISTRY_DIR}}/constraints.yaml
```

To check by category:
```bash
grep -A 5 'category: licensing' {{REGISTRY_DIR}}/constraints.yaml
```

### Write: Add a new constraint

1. Read `{{REGISTRY_DIR}}/constraints.yaml` (create from template in schema.md if it doesn't exist)
2. Find the highest existing `CONST-NNN` id and increment by 1
3. Append the new entry under `constraints:` using the schema fields
4. Set `enforcement: hard` for non-negotiable rules; `enforcement: soft` for strong preferences
5. Write `rule` in plain English — one sentence, imperative form

### Update: Change enforcement level or rationale

Edit the `enforcement` or `rationale` field in place. Do not change the id.

## Rules

- Hard constraints must be escalated to PM if a story would require violating one — never silently bypass
- Soft constraints can be overridden with PM approval; document the override in the story's ADR
- Never delete entries — demote to `enforcement: soft` with updated rationale if a constraint is relaxed
- `rule` must be one sentence, unambiguous, and actionable
