---
name: arch:design-implementation
argument-hint: "[issue_number]"
description: >
  Orchestrates the post-scout design phase. Determines required artefacts, generates
  ADRs and diagrams, then delegates to arch:openapi-contract, arch:asyncapi-contract,
  arch:implementation-plan, and arch:design-review. Marks story ready-for-dev once
  all artefacts are approved.
context: fork
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
write-paths:
  - docs/
---

# Architecture Design Implementation

Post-scout design phase. Runs after `/scout:prepare-for-dev`. Synthesises all
context (scout report, GitHub story/comments, NFRs, constraints, risks) and
produces design artefacts optimised for non-functional requirements and long-term
risk mitigation. Posts each artefact to GitHub for reviewer approval, then labels
the story `ready-for-dev` once all artefacts are approved.

**Invocation:**
```
/arch:design-implementation 460    # design for a specific issue
/arch:design-implementation        # uses .agile-dev-team/active-story.yaml
```

## Constraints

- **Write**: `docs/` only (all subdirectories) — declared in frontmatter `write-paths`
- **Read**: everything else (source, tests, infrastructure, config) — read-only
- Do not change issue status to In Progress
- Do not create implementation branches
- Do not modify an accepted ADR — supersede it with a new one if there is strong evidence

---

## Workflow

### Step 1 — Resolve issue number and check resume state

```bash
if [ -n "$ARGUMENT" ]; then
  ISSUE_NUMBER="$ARGUMENT"
else
  ISSUE_NUMBER=$(yq e '.issueNumber' .agile-dev-team/active-story.yaml 2>/dev/null)
fi

if [ -z "$ISSUE_NUMBER" ] || [ "$ISSUE_NUMBER" = "null" ]; then
  echo "ERROR  No issue number found."
  echo "Run /github:story-fetch first, or pass an issue number: /arch:design-implementation 123"
  exit 1
fi

REPOSITORY=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
DESIGN_YAML="docs/stories/${ISSUE_NUMBER}/design.yaml"
```

If `$DESIGN_YAML` already exists, **skip to Step 10** (approval poll — skill is resuming).
If `$DESIGN_YAML` does not exist, proceed to Step 2.

---

### Step 2 — Guard: scout report required

```bash
SCOUT_YAML="docs/stories/${ISSUE_NUMBER}/scout.yaml"
if [ ! -f "$SCOUT_YAML" ]; then
  echo "ERROR  Scout report not found: $SCOUT_YAML"
  echo "Run /scout:prepare-for-dev ${ISSUE_NUMBER} before /arch:design-implementation."
  exit 1
fi
```

---

### Step 3 — Load all inputs

Read in order:

1. `docs/stories/{id}/scout.yaml` — blast radius, dependencies, architecture review, tasks, open questions
2. GitHub issue + all comments:
   ```bash
   gh issue view $ISSUE_NUMBER --repo $REPOSITORY \
     --json title,body,labels,comments \
     --jq '{title,body,labels,comments}'
   ```
3. NFR registry via `/arch:maintain-nfr-registry` (read operation)
4. Constraints registry via `/arch:maintain-constraints-registry` (read operation)
5. Risk registry via `/arch:maintain-risk-registry` (read operation)
6. Each ADR listed under `scout.yaml > architecture.governing_adrs`

Extract from scout:
- `change_list` (files + tiers)
- `dependencies` (services, paths, confidence)
- `architecture.sufficient`, `architecture.new_adr`
- `tasks`
- `open_questions` where `owner: architecture`

Architecture open questions must be resolved in `design.yaml` before artefacts are finalised.

---

### Step 4 — Determine required artefacts

Apply each trigger rule. Log the decision (triggered / skipped + reason) for every type.

| Artefact | Trigger |
|----------|---------|
| **ADR** | `architecture.sufficient: false` OR `architecture.new_adr` is non-null |
| **C4 container diagram** | `change_list` has a file under `infrastructure/` or `cdk.json`, OR a dependency references a new AWS/cloud service not mentioned in any governing ADR |
| **ERD diagram** | `change_list` has a file matching `*schema*`, `*model*`, `*migration*`, `*dynamodb*`, OR story body mentions "data model", "entity", "schema", "table" |
| **Flow diagram** | `tasks` has 4+ sequential steps crossing service boundaries, OR story body mentions "workflow", "multi-step", "state machine", "process flow" |
| **OpenAPI spec** | `change_list` has a handler/route/controller file AND a new or modified HTTP endpoint is detectable (grep for `router.`, `app.get`, `app.post`, `handler`, `@Get`, `@Post`, etc.) |
| **AsyncAPI spec** | `change_list` or `dependencies` mentions SQS, SNS, EventBridge, Kafka, RabbitMQ, or event bus |

**Minimum output rule:** If no triggers fire, still write `design.yaml` with `artefacts: []` and post a summary comment. The skill always completes — never silently exits.

---

### Step 5 — Generate ADR(s) [conditional]

For each ADR warranted by Step 4:

**5a.** Invoke `/arch:adr-yaml`:
- Provide: story title, issue number, decision drivers drawn from NFRs and constraints, options synthesised from scout dependencies and gaps in governing ADRs.
- Do not recreate a decision already covered by an accepted ADR. Supersede only with strong evidence (reference the governing ADR explicitly).

**5b.** Invoke `/arch:adr-render` to convert the YAML to `$ADR_DIR/NNNN-slug.md`.

**5c.** Record in `design.yaml` artefacts list with `type: adr`, both `file` (YAML) and `rendered` (Markdown) paths.

---

### Step 6 — Generate diagrams [conditional]

For each triggered diagram type, invoke `/github:mermaid-diagram`. No inline styles unless emphasising a new or changed node — let the project theme handle colours.

**C4 Container Diagram** → `docs/stories/{id}/design/c4-container.mmd`
- Use `graph TB` with subgraphs per bounded context.
- Show containers only (services, databases, queues) — not components or code.
- Highlight new/changed containers with `stroke-width:3px`.
- Labels: logical names only — no IDs, ARNs, PK/SK patterns, or schema detail.
- Multi-line labels: use `<br/>` not `\n` — `\n` causes a GitHub mermaid parse error in `graph` diagrams.

**ERD Diagram** → `docs/stories/{id}/design/erd.mmd`
- Use `erDiagram` syntax.
- Show only entities directly affected or newly introduced.
- Include attribute types and relationship cardinalities.

**Flow Diagram** → `docs/stories/{id}/design/flow-{slug}.mmd`
- Use `flowchart TD`.
- Capture the new or modified business process end-to-end, including every external service call as a clearly labelled edge.
- `{slug}` = 2–3 word process name, lowercase hyphenated.

---

### Step 7 — Generate OpenAPI contract [conditional]

Triggered when `change_list` has a handler/route/controller file AND an HTTP endpoint
is detectable. Delegate entirely to the sub-skill:

```
invoke /arch:openapi-contract {issue_number}
```

The sub-skill writes `docs/stories/{id}/design/api-{slug}.openapi.yaml` and exits.
If no endpoints are detected it exits 0 silently — the orchestrator continues.

---

### Step 8 — Generate AsyncAPI contract [conditional]

Triggered when `change_list` or `dependencies` reference SQS, SNS, EventBridge,
Kafka, RabbitMQ, or any event bus. Delegate entirely to the sub-skill:

```
invoke /arch:asyncapi-contract {issue_number}
```

The sub-skill writes `docs/stories/{id}/design/async-{slug}.asyncapi.yaml` and exits.
If no event channels are detected it exits 0 silently.

---

### Step 9 — Produce phased implementation plan

Always runs (every story needs a plan). Delegate to the sub-skill:

```
invoke /arch:implementation-plan {issue_number}
```

The sub-skill reads `scout.yaml` tasks plus any design artefacts written in Steps 5–8,
builds the phased plan (multi-phase mandatory when total tasks > 20), and writes
`docs/stories/{id}/design/implementation-plan.yaml`.

---

### Step 10 — Write design.yaml and run design review

**10a.** Create `docs/stories/{id}/design/` if it does not exist.

**10b.** Collect all artefact paths written by Steps 5–9:
- ADRs from Step 5 (YAML + rendered MD paths)
- Diagrams from Step 6 (`.mmd` paths)
- OpenAPI spec from Step 7 (if produced)
- AsyncAPI spec from Step 8 (if produced)
- Implementation plan from Step 9

**10c.** Write `docs/stories/{id}/design.yaml` with all artefacts listed,
`comment_id: null`, `approval_status: pending` for each.

**10d.** Delegate posting, polling, and label management to the sub-skill:

```
invoke /arch:design-review {issue_number}
```

`/arch:design-review` owns the full GitHub approval loop and applies `ready-for-dev`
when all artefacts are approved. Re-invoke `/arch:design-review {id}` directly after
reviewers post approvals — no need to re-run the full orchestrator.

---

## Output Files

| File | Description |
|------|-------------|
| `docs/stories/{id}/design.yaml` | Artefact index + approval state (canonical record) |
| `docs/stories/{id}/design/implementation-plan.yaml` | Phased implementation plan with type annotations |
| `docs/stories/{id}/design/c4-container.mmd` | C4 container diagram (Mermaid) |
| `docs/stories/{id}/design/erd.mmd` | Entity/relationship diagram (Mermaid) |
| `docs/stories/{id}/design/flow-{slug}.mmd` | Business process flow diagram (Mermaid) |
| `docs/stories/{id}/design/api-{slug}.openapi.yaml` | OpenAPI 3.1.0 contract |
| `docs/stories/{id}/design/async-{slug}.asyncapi.yaml` | AsyncAPI 2.6 event contract |
| `$ADR_DIR/NNNN-slug.adr.yaml` | ADR YAML (via `/arch:adr-yaml`) |
| `$ADR_DIR/NNNN-slug.md` | Rendered ADR Markdown (via `/arch:adr-render`) |

---

## design.yaml Schema

```yaml
design:
  issue: <N>
  title: "<issue title>"
  designed: "<YYYY-MM-DD>"
  status: pending_approval | approved | partial_approval
  inputs:
    scout_yaml: docs/stories/<N>/scout.yaml
    governing_adrs: []
  artefacts:
    - id: adr-0014                        # unique slug per artefact
      type: adr                           # adr | diagram_c4 | diagram_erd | diagram_flow | api_openapi | api_asyncapi | implementation_plan
      file: $ADR_DIR/0014-slug.adr.yaml
      rendered: $ADR_DIR/0014-slug.md     # adr type only
      rationale: "why this artefact was produced"
      comment_id: null                    # GitHub comment ID once posted
      approval_status: pending            # pending | approved | rejected
      approved_by: null
      approved_at: null
  open_questions_resolved:
    - id: 1
      question: "..."
      resolution: "..."
  risks_introduced: []
  approval_summary:
    total_artefacts: 0
    approved: 0
    pending: 0
    rejected: 0
    ready_for_dev: false
```

---

## Label State Transitions

```
scouted
  ↓ (set by scout if needed)
architecture-review-needed
  ↓ (set by this skill on Step 8)
architecture-in-review
  ↓ (set by this skill on Step 10 — all approved)
ready-for-dev
```

---

## Error Handling

| Condition | Behaviour |
|-----------|-----------|
| No active story + no argument | Error: run `/github:story-fetch` first |
| `scout.yaml` missing | Error: run `/scout:prepare-for-dev` first |
| `gh` auth unavailable | Print `gh auth login` instructions and exit |
| ADR child skill fails | Log error, continue remaining artefacts, set `approval_status: generation_failed` |
| Comment post fails | Log warning, continue; `comment_id` stays null so next run retries posting |
| All artefacts already approved | Print "already approved" and exit cleanly |

---

## Related Skills

| Skill | Role |
|-------|------|
| `/scout:prepare-for-dev` | Must run before this skill; writes `scout.yaml` |
| `/arch:adr-yaml` | Called in Step 5 to produce ADR YAML |
| `/arch:adr-render` | Called in Step 5 to render ADR to Markdown |
| `/github:mermaid-diagram` | Called in Step 6 to produce diagrams |
| `/arch:openapi-contract` | Called in Step 7 — generates OpenAPI 3.1.0 spec |
| `/arch:asyncapi-contract` | Called in Step 8 — generates AsyncAPI 2.6 spec |
| `/arch:implementation-plan` | Called in Step 9 — produces phased plan |
| `/arch:design-review` | Called in Step 10 — GitHub approval loop; also callable standalone |
| `/arch:maintain-nfr-registry` | Read in Step 3 to get applicable NFRs |
| `/arch:maintain-constraints-registry` | Read in Step 3 to get hard/soft constraints |
| `/arch:maintain-risk-registry` | Read in Step 3 to get open risks |
