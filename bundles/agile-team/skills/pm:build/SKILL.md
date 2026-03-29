---
name: pm:build
argument-hint: "[issue_number]"
description: >
  Fleet orchestrator. Reads implementation-plan.yaml produced by the architect,
  resolves phase dependencies (topological sort), and spawns specialist agents
  (devops/backend-dev/frontend-dev) — parallel for independent phases, sequential
  when dependencies exist. Tracks build state in build-state.yaml.
tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
  - Skill
  - Agent
  - Task
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
---

# PM: Build — Fleet Orchestrator

Reads `docs/stories/{issue}/design/implementation-plan.yaml`, resolves phase
dependencies, and dispatches specialist agents per execution wave.

**Invocation:**
```
/pm build 460    # build a specific issue
/pm build        # uses .agile-dev-team/active-story.json
```

---

## Type → Agent Mapping

| Phase type     | Agent           |
|----------------|-----------------|
| `infrastructure` | `/agent:devops` |
| `backend`       | `/agent:backend-dev` |
| `frontend`      | `/agent:frontend-dev` |

A phase with multiple types (e.g. `[backend, frontend]`) spawns one agent per type in parallel.

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
  echo "ERROR  No issue number found."
  echo "Pass one directly: /pm build 123"
  echo "Or run /github:story-fetch first."
  exit 1
fi

PLAN_FILE="docs/stories/${ISSUE_NUMBER}/design/implementation-plan.yaml"
STATE_FILE="docs/stories/${ISSUE_NUMBER}/design/build-state.yaml"
```

---

### Step 2 — Guard: implementation-plan.yaml required

```bash
if [ ! -f "$PLAN_FILE" ]; then
  echo "ERROR  Implementation plan not found: $PLAN_FILE"
  echo ""
  echo "The architect must produce this file before building."
  echo "Run: /arch:design-implementation ${ISSUE_NUMBER}"
  exit 1
fi
```

---

### Step 3 — Load plan and read story context

1. Read `$PLAN_FILE` — parse `implementation_plan.phases[]`
2. Read `.agile-dev-team/active-story.json` for story title and branch name (if present)
3. Build a phase map: `id → phase` object

---

### Step 4 — Resolve dependency graph and compute execution waves

Topological sort algorithm:

```
completed = {}
waves = []

while there are unscheduled phases:
  wave = [p for p in unscheduled if all(dep in completed for dep in p.depends_on)]
  if wave is empty and unscheduled is non-empty:
    ERROR: circular dependency detected — list the cycle and stop
  waves.append(wave)
  completed.update(wave)
```

- **Wave 0:** all phases with `depends_on: []`
- **Wave N:** phases whose every `depends_on` entry is in a previous wave
- Phases in the same wave are independent and run in parallel

Print the execution plan before starting:

```
Build plan — issue #<N>

  Wave 1  (parallel)
    phase-1  [infrastructure]  "Provision DynamoDB table and SQS queue"
    phase-2  [infrastructure]  "Deploy API Gateway stage"   ← also no deps

  Wave 2  (parallel after wave 1)
    phase-3  [backend]         "Order creation Lambda"

  Wave 3  (after phase-3)
    phase-4  [frontend]        "Order list UI"
```

---

### Step 5 — Initialise build state

Write `$STATE_FILE` before executing any wave:

```yaml
build_state:
  issue: <N>
  started: "<YYYY-MM-DDTHH:MM:SS>"
  updated: "<YYYY-MM-DDTHH:MM:SS>"
  status: in_progress
  phases:
    - id: phase-1
      status: pending
      agent_type: devops
      started: null
      completed: null
      error: null
    # ... one entry per phase
```

---

### Step 6 — Execute waves

For each wave in order:

#### 6a. Mark phases in_progress

Update `$STATE_FILE`: set `status: in_progress` and `started: <timestamp>` for each phase in the wave.

#### 6b. Build agent context for each phase

For each phase in the wave, for each type in `phase.type`, prepare:

```
AGENT_CONTEXT = """
Story: #{issue} — {story_title}
Branch: {branch_name}

Phase: {phase.id} — {phase.name}
Type: {discipline}
Tasks:
{phase.tasks formatted as numbered list}

Deployment gate:
{phase.deployment_gate}

Rollback:
{phase.rollback}

Feature flag: {phase.feature_flag or 'none'}
"""
```

#### 6c. Spawn agents in parallel

For each (phase, type) pair in the wave, invoke the mapped agent skill passing `AGENT_CONTEXT` as the argument.
All agents in the wave are spawned in a single parallel batch — do not wait for one before starting the next.

```
# Example — wave with 2 independent phases:
Task(agent:devops,  context_for_phase_1_infrastructure, run_in_background=true)
Task(agent:backend-dev, context_for_phase_3_backend,   run_in_background=true)
```

#### 6d. Wait and collect results

Wait for all agents in the wave to complete. For each:
- **Success:** mark phase `status: completed`, set `completed: <timestamp>`, update `$STATE_FILE`
- **Failure:** mark phase `status: failed`, set `error: <summary>`, update `$STATE_FILE`

#### 6e. Failure handling

If any phase in the wave **failed**:
1. Identify all phases in subsequent waves that depend (directly or transitively) on the failed phase
2. Mark those phases `status: skipped` in `$STATE_FILE`
3. Set overall `build_state.status: failed`
4. Print a clear failure report:

```
Build FAILED — issue #<N>

  FAILED:  phase-2  [backend]   "Order creation Lambda"
           Error: <agent error summary>

  SKIPPED (blocked by phase-2):
           phase-3  [frontend]  "Order list UI"

  COMPLETED before failure:
           phase-1  [infrastructure]  ✓
```

5. Stop execution — do not proceed to the next wave.

If all phases in the wave succeeded, continue to the next wave.

---

### Step 7 — Final report

On full success:

```
Build COMPLETE — issue #<N>

  phase-1  [infrastructure]  ✓  Provision DynamoDB table and SQS queue
  phase-2  [backend]         ✓  Order creation Lambda and API handler
  phase-3  [frontend]        ✓  Order list UI

  All {N} phases completed.
  Build state: docs/stories/{N}/design/build-state.yaml
```

Update `$STATE_FILE`: `status: completed`, `updated: <timestamp>`.

---

## build-state.yaml Schema

```yaml
build_state:
  issue: <N>
  started: "<YYYY-MM-DDTHH:MM:SS>"
  updated: "<YYYY-MM-DDTHH:MM:SS>"
  status: in_progress | completed | failed
  phases:
    - id: phase-1
      status: pending | in_progress | completed | failed | skipped
      agent_type: devops | backend-dev | frontend-dev
      started: "<YYYY-MM-DDTHH:MM:SS> | null"
      completed: "<YYYY-MM-DDTHH:MM:SS> | null"
      error: "<summary> | null"
```

---

## Error Handling

| Condition | Behaviour |
|-----------|-----------|
| No issue number | Error: pass one or run `/github:story-fetch` |
| `implementation-plan.yaml` missing | Error: escalate — run `/arch:design-implementation {N}` first |
| Circular dependency in plan | Error: print cycle and stop |
| Agent fails a phase | Mark failed, skip dependents, print report, stop |
| `build-state.yaml` already exists with `status: completed` | Print "already built" and exit cleanly |

---

## Resuming a Failed Build

Re-running `/pm build {N}` when `build-state.yaml` exists:
1. Read existing state
2. Skip phases with `status: completed`
3. Reset `status: failed` phases to `pending` and retry from the earliest incomplete wave
4. Skip phases with `status: skipped` only if their dependency is still `failed`; otherwise reset to `pending`

---

## Related Skills

| Skill | Role |
|-------|------|
| `/arch:design-implementation` | Must run before this skill — produces `implementation-plan.yaml` |
| `/agent:devops` | Executes `infrastructure` phases |
| `/agent:backend-dev` | Executes `backend` phases |
| `/agent:frontend-dev` | Executes `frontend` phases |
| `/github:story-fetch` | Populates `active-story.json` with issue number |
