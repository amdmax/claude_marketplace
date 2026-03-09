---
name: arch:maintain-risk-registry
author: "@amdmax"
description: Read or update the project risk registry at {{REGISTRY_DIR}}/risks.yaml. Use when the architect identifies new risks during story design, when a risk is mitigated and needs a status update, or when any agent needs to review existing open risks. Supports both project-level risks (persistent across stories) and story-level risks (scoped to one issue).
---

# Maintain Risk Registry

Registry file: `{{REGISTRY_DIR}}/risks.yaml`

For schema, examples, and scope rules: see @.claude/skills/arch:maintain-risk-registry/references/schema.md

## Operations

### Read: List risks

```bash
cat {{REGISTRY_DIR}}/risks.yaml
```

To filter open risks only:
```bash
grep -A 6 'status: open' {{REGISTRY_DIR}}/risks.yaml
```

### Write: Add a new risk

1. Read `{{REGISTRY_DIR}}/risks.yaml` (create from template in schema.md if it doesn't exist)
2. Find the highest existing `RISK-NNN` id and increment by 1
3. Append the new entry under `risks:` using the schema fields
4. Set `scope: project` for cross-story risks; `scope: story` + `storyRef: <ISSUE-NNN>` for story-scoped risks
5. Set `status: open`, `mitigation: null`

### Update: Mark a risk mitigated

1. Find the entry by id
2. Change `status: open` → `status: mitigated`
3. Set `mitigation: "How it was resolved (1–2 sentences)"`

## Rules

- Never delete entries — only update status
- `storyRef` is required when `scope: story`; set to `null` for project-level
- One risk per entry — do not combine multiple risks into one id
- Keep `description` to one line
