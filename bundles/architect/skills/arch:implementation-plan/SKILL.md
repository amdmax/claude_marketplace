---
name: arch:implementation-plan
argument-hint: "[issue_number]"
description: >
  Produces a phased implementation plan from scout tasks and design artefacts.
  Mandatory multi-phase when total tasks > 20. Each phase annotated
  infrastructure|backend|frontend, independently deployable, with a deployability
  contract. Writes implementation-plan.yaml to docs/stories/{id}/design/.
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

# Phased Implementation Plan

Produces a structured implementation plan partitioned into independently deployable
phases, each annotated by discipline (`infrastructure`, `backend`, `frontend`).
Mandatory multi-phase output when total task count exceeds 20.
Callable standalone or from `/arch:design-implementation`.

**Invocation:**
```
/arch:implementation-plan 460    # for a specific issue
/arch:implementation-plan        # uses .agile-dev-team/active-story.json
```

## Constraints

- **Write**: `docs/` only
- **Read**: everything else — read-only
- Re-running overwrites the existing plan; prior phase approvals in `design.yaml` are preserved

---

## Workflow

### Step 1 — Resolve issue number

```bash
if [ -n "$ARGUMENT" ]; then
  ISSUE_NUMBER="$ARGUMENT"
else
  ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json 2>/dev/null)
fi

if [ -z "$ISSUE_NUMBER" ] || [ "$ISSUE_NUMBER" = "null" ]; then
  echo "ERROR  No issue number. Pass one or run /github:story-fetch first."
  exit 1
fi

SCOUT_YAML="docs/stories/${ISSUE_NUMBER}/scout.yaml"
```

Guard: if `$SCOUT_YAML` does not exist → exit with error pointing to `/scout:prepare-for-dev`.

### Step 2 — Collect all tasks

**From `scout.yaml`:**
Read `scout.tasks[]` — these are the base implementation tasks identified during reconnaissance.

**From `design.yaml`** (read `docs/stories/{id}/design.yaml` if present):
Derive additional design-implied tasks for each artefact type present:

| Artefact type | Implied tasks |
|---------------|--------------|
| `diagram_c4` | infra provisioning task per new container |
| `diagram_erd` | schema migration task per new/changed entity |
| `api_openapi` | API versioning / backward-compatibility task |
| `api_asyncapi` | event channel provisioning task |
| `adr` | implementation verification task for the decision |

Label each task with an inferred discipline:
- `infrastructure`: CDK/IaC changes, resource creation, schema provisioning, DNS, certs
- `backend`: Lambda logic, API handlers, migrations, event processors, background jobs
- `frontend`: UI components, CSS, client-side logic, frontend build changes

### Step 3 — Count and determine phasing

```
total_tasks = len(scout_tasks) + len(design_implied_tasks)
```

- **≤ 20 tasks** → single phase containing all tasks
- **> 20 tasks** → multi-phase mandatory

Splitting all tasks into a single oversized phase is **rejected** — the plan must enforce
the threshold strictly.

### Step 4 — Build phases

**Single-phase:** one phase with `type` derived from the union of all task disciplines.

**Multi-phase — sequencing rules:**
1. Group tasks by discipline first.
2. Infrastructure tasks → earliest phase(s); cannot start until prior infrastructure phases complete.
3. Backend tasks → after any infrastructure phase they depend on.
4. Frontend tasks → after backend API phases they consume.
5. Independent tasks within the same discipline that share no dependencies may be placed in parallel phases (same `depends_on`).
6. Aim for phases of 5–15 tasks each; never exceed 20 tasks in a single phase.

For each phase produce:

```yaml
id: phase-N          # 1-indexed
name: "Short title"
type:                # one or more of: infrastructure | backend | frontend
  - infrastructure
depends_on: []       # list of phase ids; empty for phase-1
tasks:
  - id: <task_id>
    task: "<description>"
    tier: directly_affected | likely_affected | validate_only
    discipline: infrastructure | backend | frontend
deployment_gate: |
  What must be verified before this phase is considered done and the
  next phase can begin. Be specific: test names, CLI checks, smoke tests.
feature_flag: null   # or "flag-name" if partial feature gating is needed
rollback: |
  One-line rollback procedure for this phase.
```

### Step 5 — Apply deployability contract

For each phase, verify and document:

1. **System stays working** — phase end state must pass all existing tests and integrations.
2. **No broken contracts** — existing API consumers must not be affected.
3. **Expand-before-contract** — for schema changes: add columns/tables as nullable first; remove old ones in a later phase only after migration is confirmed.
4. **Backward-compatible API changes** — add new fields/endpoints; never remove or rename in the same phase.
5. **Feature flag** — if a phase delivers infrastructure or backend without a corresponding frontend, gate the incomplete feature with a named flag.

If a phase violates any contract rule, split it further or adjust the task grouping.

### Step 6 — Write implementation-plan.yaml

```bash
mkdir -p "docs/stories/${ISSUE_NUMBER}/design"
OUTPUT="docs/stories/${ISSUE_NUMBER}/design/implementation-plan.yaml"
```

File schema:

```yaml
implementation_plan:
  issue: <N>
  generated: "<YYYY-MM-DD>"
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
          discipline: infrastructure
        - id: 2
          task: "Add OrderCreated SQS queue CDK construct"
          tier: directly_affected
          discipline: infrastructure
      deployment_gate: |
        CDK deploy succeeds; table and queue visible in AWS console;
        CloudFormation stack status UPDATE_COMPLETE.
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
          discipline: backend
        - id: 4
          task: "Wire POST /orders in API Gateway"
          tier: directly_affected
          discipline: backend
      deployment_gate: |
        POST /orders returns 201; unit + integration tests green;
        feature flag orders-api-enabled toggled on in staging.
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
          discipline: frontend
      deployment_gate: |
        E2E test for order list passes; feature flag enabled in production.
      feature_flag: "orders-api-enabled"
      rollback: "disable feature flag"
```

### Step 7 — Print summary

```
arch:implementation-plan: issue #{id}

  Total tasks : {N}
  Phases      : {P}

  phase-1  [infrastructure]  {N} tasks  →  CDK provisioning
  phase-2  [backend]         {N} tasks  →  Lambda + API
  phase-3  [frontend]        {N} tasks  →  UI components

  Wrote: docs/stories/{id}/design/implementation-plan.yaml
```

---

## Output

| File | Description |
|------|-------------|
| `docs/stories/{id}/design/implementation-plan.yaml` | Phased plan with type annotations and deployability contracts |

---

## Related Skills

| Skill | Role |
|-------|------|
| `/arch:design-implementation` | Orchestrator — calls this skill in Step 9 |
| `/arch:design-review` | Posts this file to GitHub for review |
| `/scout:prepare-for-dev` | Must run first; writes `scout.yaml` with base tasks |
