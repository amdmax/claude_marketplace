---
name: arch:design-implementation
argument-hint: "[issue_number]"
description: >
  Post-scout design phase. Reads scout.yaml, story, NFRs, constraints, risks.
  Produces ADRs, C4/ERD/flow diagrams, OpenAPI/AsyncAPI contracts. Posts each
  to GitHub for reviewer approval, then marks story ready-for-dev.
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
/arch:design-implementation        # uses .agile-dev-team/active-story.json
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
  ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json 2>/dev/null)
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

**5b.** Invoke `/arch:adr-render` to convert the YAML to `docs/adr/NNNN-slug.md`.

**5c.** Record in `design.yaml` artefacts list with `type: adr`, both `file` (YAML) and `rendered` (Markdown) paths.

---

### Step 6 — Generate diagrams [conditional]

For each triggered diagram type, invoke `/arch:mermaid-diagram`. No inline styles unless emphasising a new or changed node — let the project theme handle colours.

**C4 Container Diagram** → `docs/stories/{id}/design/c4-container.mmd`
- Use `graph TB` with subgraphs per bounded context.
- Show containers only (services, databases, queues) — not components or code.
- Highlight new/changed containers with `stroke-width:3px`.

**ERD Diagram** → `docs/stories/{id}/design/erd.mmd`
- Use `erDiagram` syntax.
- Show only entities directly affected or newly introduced.
- Include attribute types and relationship cardinalities.

**Flow Diagram** → `docs/stories/{id}/design/flow-{slug}.mmd`
- Use `flowchart TD`.
- Capture the new or modified business process end-to-end, including every external service call as a clearly labelled edge.
- `{slug}` = 2–3 word process name, lowercase hyphenated.

---

### Step 7 — Generate API contracts [conditional]

**OpenAPI 3.1.0** → `docs/stories/{id}/design/api-{slug}.openapi.yaml`

Produce a minimal but complete spec covering only new/changed endpoints:
- `info.title`, `info.version` (`0.1.0-design`), `info.description`
- `paths` for each affected endpoint with full request/response schemas
- `components.schemas` for all request/response bodies
- `components.securitySchemes` if auth is required
- Explicit error responses: 400, 401, 403, 404, 500

**AsyncAPI 2.6** → `docs/stories/{id}/design/async-{slug}.asyncapi.yaml`

Produce a minimal spec covering only new/changed channels:
- `info`, `channels`, `components.messages`, `components.schemas`
- Channel bindings for the specific broker (SQS, SNS, EventBridge, etc.)

---

### Step 8 — Produce phased implementation plan

Count the total implementation tasks: all tasks in `scout.yaml > tasks` plus any new tasks implied by the design artefacts (schema migrations, API versioning, feature flag wiring, infra provisioning).

**If total tasks ≤ 20:** produce a single-phase plan.
**If total tasks > 20:** mandatory multi-phase plan. Splitting into a single oversized phase is not acceptable.

#### Phase rules

**Annotation** — every phase must be labelled with one or more of:
- `infrastructure` — IaC, resource provisioning (CDK/Terraform), schema provisioning, DNS, certs
- `backend` — Lambda/service logic, API handlers, migrations, event processors, background jobs
- `frontend` — UI components, client-side logic, CSS, frontend build changes

**Sequencing constraints:**
- Infrastructure phases precede backend phases that depend on the provisioned resources.
- Backend API phases precede frontend phases that consume those APIs.
- Independent phases within the same layer may be executed in parallel by different developers.

**Deployability contract — each phase must:**
1. Leave the system in a fully working state at the end (no half-built features in production).
2. Not break existing behaviour: all current tests and integrations must still pass after deploying the phase.
3. Use expand-before-contract for schema changes: add new columns/tables as nullable before removing old ones.
4. Use backward-compatible API changes within a phase: add new fields/endpoints; deprecate don't delete.
5. Gate partially-complete features with a feature flag if a phase delivers infrastructure or backend without a frontend.

#### Plan structure

For each phase:
- `id`: `phase-N` (1-indexed)
- `name`: short descriptive title
- `type`: one or more of `infrastructure | backend | frontend`
- `depends_on`: list of phase ids that must be deployed first (empty for first phase)
- `tasks`: list of task objects (from scout tasks + design-derived tasks)
- `deployment_gate`: what to verify before marking the phase done and deploying the next
- `feature_flag`: name of flag if partial feature gating is needed (null if not needed)
- `rollback`: one-line rollback procedure

Write the plan to `docs/stories/{id}/design/implementation-plan.yaml`.
Add it to `design.yaml` artefacts list with `type: implementation_plan`.

#### Phase schema

```yaml
implementation_plan:
  issue: <N>
  total_tasks: <count>
  multi_phase: true|false
  phases:
    - id: phase-1
      name: "Provision DynamoDB table and SQS queue"
      type: [infrastructure]
      depends_on: []
      tasks:
        - id: 1
          task: "Add OrderTable CDK construct"
          tier: directly_affected
        - id: 2
          task: "Add OrderCreated SQS queue CDK construct"
          tier: directly_affected
      deployment_gate: "CDK deploy succeeds; table and queue visible in AWS console"
      feature_flag: null
      rollback: "cdk destroy OrderTable OrderCreatedQueue"
    - id: phase-2
      name: "Order creation Lambda and API handler"
      type: [backend]
      depends_on: [phase-1]
      tasks:
        - id: 3
          task: "Implement createOrder Lambda"
          tier: directly_affected
        - id: 4
          task: "Wire POST /orders endpoint in API Gateway"
          tier: directly_affected
      deployment_gate: "POST /orders returns 201; unit + integration tests green"
      feature_flag: "orders-api-enabled"
      rollback: "disable feature flag; redeploy previous Lambda version"
    - id: phase-3
      name: "Order list UI"
      type: [frontend]
      depends_on: [phase-2]
      tasks:
        - id: 5
          task: "Add OrderList component"
          tier: directly_affected
      deployment_gate: "E2E test for order list passes; feature flag enabled in staging"
      feature_flag: "orders-api-enabled"
      rollback: "disable feature flag"
```

---

### Step 9 — Write design.yaml and post GitHub comments

**9a.** Create `docs/stories/{id}/design/` if it does not exist.

**9b.** Write `design.yaml` with all artefacts listed (including `implementation_plan`), `comment_id: null`, `approval_status: pending` for each.

**9c.** For each artefact, post a GitHub comment in this format, then update `design.yaml` with the returned `comment_id`:

```bash
COMMENT_URL=$(gh issue comment $ISSUE_NUMBER \
  --repo $REPOSITORY \
  --body "COMMENT_BODY_HERE" \
  --json url --jq '.url')
# Extract numeric ID from URL: echo $COMMENT_URL | grep -oE '[0-9]+$'
```

Comment template:
```
<!-- design-approval-{artefact_id} -->
## Design Review: {type} — {artefact_id}

**Story:** #{issue_number} | **File:** `{file_path}`
**Rationale:** {why this artefact was produced}

---

{full file content inline:
  - Mermaid fence block for diagrams
  - YAML code block for API specs and ADR YAML
  - Link + key decisions summary for rendered ADR markdown}

---

Reply **`approved`** to approve, or **`rejected: <reason>`** to request changes.

_Generated by /arch:design-implementation on {YYYY-MM-DD}_
```

**9d.** Post a summary comment listing all artefacts and review instructions:

```
<!-- design-implementation-summary -->
## Architecture Design Summary — Issue #{issue_number}

**{N} artefact(s) require approval before development can start.**

| # | Type | File | Status |
|---|------|------|--------|
| 1 | ADR | docs/adr/NNNN-slug.md | Pending |
| 2 | C4 Diagram | docs/stories/{id}/design/c4-container.mmd | Pending |
| 3 | Implementation Plan | docs/stories/{id}/design/implementation-plan.yaml | Pending |

**Reviewers:** reply `approved` or `rejected: reason` on each artefact comment above.

Re-run `/arch:design-implementation {id}` after posting approvals to check status.
```

**9e.** Apply label `architecture-in-review`:
```bash
gh label create "architecture-in-review" --color "0075ca" --repo $REPOSITORY 2>/dev/null || true
gh issue edit $ISSUE_NUMBER --repo $REPOSITORY --add-label "architecture-in-review"
```

---

### Step 10 — Poll approval state [resume path]

Read `design.yaml`. For each artefact with `approval_status: pending` and non-null `comment_id`:

```bash
COMMENTS=$(gh issue view $ISSUE_NUMBER --repo $REPOSITORY \
  --json comments --jq '.comments')

ISSUE_AUTHOR=$(gh issue view $ISSUE_NUMBER --repo $REPOSITORY \
  --json author --jq '.author.login')

BOT_USER=$(gh api user --jq '.login' 2>/dev/null || echo "")
```

For each pending artefact, scan all comments posted after the artefact comment's timestamp (use `comment_id` to find the artefact comment's `createdAt` first):

**Approval detection:**
Comment body (trimmed) matches `^(approved|lgtm|yes)\b` (case-insensitive), AND author is not `$ISSUE_AUTHOR` or `$BOT_USER`.

**Rejection detection:**
Comment body matches `^(rejected|changes requested|nack|no)[:\s.]` (case-insensitive).

**On approval:** Set `approval_status: approved`, `approved_by`, `approved_at` in `design.yaml`.

**On rejection:** Set `approval_status: rejected`. Post a clarification comment:

```
<!-- design-clarification-{artefact_id} -->
## Design Clarification Needed — {artefact_id}

Feedback received:
> {rejection_reason}

**Next steps:**
1. Revise `{file_path}` based on feedback
2. Re-run `/arch:design-implementation {id}` to repost the updated artefact for re-review
```

---

### Step 11 — Complete or loop

**If all artefacts are `approved`:**

```bash
gh label create "ready-for-dev" --color "0e8a16" --repo $REPOSITORY 2>/dev/null || true
gh issue edit $ISSUE_NUMBER --repo $REPOSITORY \
  --add-label "ready-for-dev" \
  --remove-label "architecture-in-review"
```

Post final summary comment:
```
<!-- design-approved -->
## All Design Artefacts Approved — Issue #{issue_number}

All {N} design artefacts have been approved. Story is ready for development.

| Artefact | Approved By | At |
|----------|-------------|----|
| {id} | {reviewer} | {timestamp} |

Next: assign the story and start implementation.
```

Update `design.yaml`:
```yaml
status: approved
approval_summary:
  ready_for_dev: true
```

**If any artefacts remain pending:** Print a status table and exit with instructions:

```
Architecture Design: Awaiting Approval

Issue #{id} — {title}

  [x] adr-0014        — approved by alice (2026-03-29 14:03)
  [ ] c4-container    — pending (comment posted)
  [ ] api-payments    — pending (comment posted)

Re-run /arch:design-implementation {id} after reviewers respond.
```

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
| `docs/adr/NNNN-slug.adr.yaml` | ADR YAML (via `/arch:adr-yaml`) |
| `docs/adr/NNNN-slug.md` | Rendered ADR Markdown (via `/arch:adr-render`) |

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
      file: docs/adr/0014-slug.adr.yaml
      rendered: docs/adr/0014-slug.md     # adr type only
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
| `/arch:adr-yaml` | Called to produce ADR YAML |
| `/arch:adr-render` | Called to render ADR to Markdown |
| `/arch:mermaid-diagram` | Called to produce diagrams |
| `/arch:maintain-nfr-registry` | Read to get applicable NFRs |
| `/arch:maintain-constraints-registry` | Read to get hard/soft constraints |
| `/arch:maintain-risk-registry` | Read to get open risks; update if new risks found during design |
