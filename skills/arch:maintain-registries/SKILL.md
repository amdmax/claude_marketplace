---
name: arch:maintain-registries
description: Read or update the project constraints, NFR, or risk registries. Use when the architect needs to check or record constraints before proposing a design, map NFRs to a story's implementation brief, identify or mitigate risks during story design, or when any agent needs to validate an approach against existing registry entries.
---

# Maintain Registries

| Registry | File | ID Prefix | Schema |
|----------|------|-----------|--------|
| Constraints | `docs/constraints.yaml` | `CONST-NNN` | @references/constraints-schema.md |
| NFRs | `docs/nfr-registry.yaml` | `NFR-NNN` | @references/nfr-schema.md |
| Risks | `docs/risks.yaml` | `RISK-NNN` | @references/risk-schema.md |

## Common Operations

### Read

```bash
cat docs/constraints.yaml
cat docs/nfr-registry.yaml
cat docs/risks.yaml
```

### Add a new entry

1. Read the registry file (create from the bootstrap template in the schema ref if it doesn't exist)
2. Find the highest existing `PREFIX-NNN` id and increment by 1, zero-padded to 3 digits
3. Append the new entry under the root key (`constraints:` / `nfrs:` / `risks:`)
4. Use schema fields from the relevant `@references/` file

### Update an existing entry

Edit the target field(s) in place. Never change the `id`.

## Common Rules

- Never delete entries — only update in place or change status
- `storyRef` is required when `scope: story`; set to `null` for project-level
- One concern per entry — do not combine multiple items into one id

---

## Constraints — Registry-Specific

**Grep helpers:**
```bash
# Hard (blocking) constraints only
grep -B 3 'enforcement: hard' docs/constraints.yaml

# By category (e.g. licensing)
grep -A 5 'category: licensing' docs/constraints.yaml
```

**Enforcement rules:**
- `hard` — non-negotiable; escalate to PM if a story would violate one, never bypass silently
- `soft` — strong preference; can be overridden with PM approval, document the override in the story's ADR
- Demotion not deletion: if a constraint is relaxed, change `enforcement: hard → soft` with updated rationale

**Write rules:**
- Set `enforcement: hard` for non-negotiable rules; `enforcement: soft` for strong preferences
- `rule` must be one sentence, imperative form, unambiguous, and actionable

---

## NFRs — Registry-Specific

**Grep helpers:**
```bash
# Project-level NFRs (apply to all stories)
grep -B 1 'scope: project' docs/nfr-registry.yaml

# NFRs for a specific story
grep -B 1 "storyRef: AIGWS-NNN" docs/nfr-registry.yaml
```

**Write rules:**
- `requirement` must be testable and unambiguous — if it can't be measured, it's not an NFR
- `scope: project` for permanent requirements; `scope: story` + `storyRef` for story-scoped
- Story-level NFRs may not be retroactively changed after a story closes

---

## Risks — Registry-Specific

**Grep helpers:**
```bash
# Open risks only
grep -A 6 'status: open' docs/risks.yaml
```

**Mark mitigated:**
1. Find the entry by id
2. Change `status: open` → `status: mitigated`
3. Set `mitigation: "How it was resolved (1–2 sentences)"`

**Write rules:**
- `description` must be one line, plain English
- New entries always start as `status: open`, `mitigation: null`
