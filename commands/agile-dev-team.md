# Agile Dev Team

## Overview

Spin up a coordinated 7-agent TDD team:

```
PM (fetch + enrich) → Architect (design) → Test Architect (failing tests) → Developers (implement) → Scope Guard (review) → DevOps (deploy) → PM (verify + PR)
```

## Prerequisites

Before running, verify these exist:
- `.claude/agents/pm.md`
- `.claude/agents/architect.md`
- `.claude/agents/test-architect.md`
- `.claude/agents/backend-dev.md`
- `.claude/agents/frontend-dev.md`
- `.claude/agents/scope-guard.md`
- `.claude/agents/devops.md`
- `.claude/story-workflow-config.json` (for `/fetch-story`)

If any agent file is missing, stop and tell the user.

## Execution Steps

### Step 1: Verify Agent Definitions

Read each file in `.claude/agents/` and confirm all 7 exist:
- `pm.md`, `architect.md`, `test-architect.md`, `backend-dev.md`, `frontend-dev.md`, `scope-guard.md`, `devops.md`

If any are missing, stop and report which files are missing.

### Step 2: Create Team

```
TeamCreate(team_name="tdd-story-team", description="TDD-first development team for story implementation")
```

### Step 3: Create Task List

Create 8 tasks with dependencies:

**Task 1:** "Fetch and enrich story"
- Description: "PM fetches the next Ready story via /fetch-story, enriches with NFRs from nfr-registry.json, validates with /check-story-quality, creates feature branch, and initializes teamState in .agile-dev-team/development-progress.yaml."
- activeForm: "Fetching and enriching story"

**Task 2:** "Design implementation approach"
- Description: "Architect reads enriched story, runs /gather-context, maps ACs to files/interfaces, assesses risks, produces implementation brief in .agile-dev-team/development-progress.yaml. Writes requiredAgents array (e.g. [\"backend-dev\", \"frontend-dev\"]) to development-progress.yaml. Creates ADR if needed via /arch:create-adr."
- activeForm: "Designing implementation approach"
- blockedBy: [Task 1]

**Task 3:** "Write failing tests"
- Description: "Test Architect reads implementation brief, writes failing tests (TDD red phase) covering happy path, error paths, and corner cases. Confirms tests fail for the right reasons. Stages test files."
- activeForm: "Writing failing tests"
- blockedBy: [Task 2]

**Task 4:** "Implement backend"
- Description: "Backend Dev reads test contracts and implementation brief, implements Lambda handlers and CDK infrastructure to make integration tests pass. Commits via /commit. Skip if story is frontend-only."
- activeForm: "Implementing backend"
- blockedBy: [Task 3]

**Task 5:** "Implement frontend"
- Description: "Frontend Dev reads test contracts and implementation brief, implements TypeScript/HTML/CSS to make unit and e2e tests pass. Commits via /commit. Skip if story is backend-only."
- activeForm: "Implementing frontend"
- blockedBy: [Task 3]

**Task 6:** "Scope review"
- Description: "Scope-guard reviews all implementation changes against story ACs and NFRs, flags any out-of-scope changes, and approves or blocks progression."
- activeForm: "Reviewing scope"
- blockedBy: [Task 4, Task 5]

**Task 7:** "Deploy and verify"
- Description: "Devops runs CDK synth (if infrastructure changed), deploys to staging, and confirms the feature is accessible end-to-end."
- activeForm: "Deploying and verifying"
- blockedBy: [Task 6]

**Task 8:** "Verify and create PR"
- Description: "PM runs full npm test, verifies all tests pass, creates PR via gh pr create, updates teamState.phase to complete, and shuts down teammates."
- activeForm: "Verifying and creating PR"
- blockedBy: [Task 7]

### Step 4: Spawn PM Agent

Spawn PM — it orchestrates the entire workflow, spawning agents on demand as each phase completes:

```
Task(
  subagent_type="general-purpose",
  team_name="tdd-story-team",
  name="pm",
  prompt="""You are Riley, the PM agent on the tdd-story-team.
Read @.claude/agents/pm.md and follow it exactly.

Claim Task 1 and execute it. Then orchestrate the pipeline by spawning agents on demand:

After Task 1 complete → spawn Architect:
  Task(subagent_type="general-purpose", team_name="tdd-story-team", name="architect",
    prompt="You are Morgan, the Architect on the tdd-story-team. Read @.claude/agents/architect.md and follow it exactly. Claim Task 2.")

After Task 2 complete → spawn Test Architect:
  Task(subagent_type="general-purpose", team_name="tdd-story-team", name="test-architect",
    prompt="You are Jordan, the Test Architect on the tdd-story-team. Read @.claude/agents/test-architect.md and follow it exactly. Claim Task 3.")

After Task 3 complete → read development-progress.yaml requiredAgents, spawn only listed developers in parallel:
  Task(subagent_type="general-purpose", team_name="tdd-story-team", name="backend-dev",
    prompt="You are Alex, the Backend Dev on the tdd-story-team. Read @.claude/agents/backend-dev.md and follow it exactly. Claim Task 4.")
  Task(subagent_type="general-purpose", team_name="tdd-story-team", name="frontend-dev",
    prompt="You are Casey, the Frontend Dev on the tdd-story-team. Read @.claude/agents/frontend-dev.md and follow it exactly. Claim Task 5.")

After Tasks 4+5 complete → spawn Scope Guard:
  Task(subagent_type="general-purpose", team_name="tdd-story-team", name="scope-guard",
    prompt="You are Dana, the Scope Guard on the tdd-story-team. Read @.claude/agents/scope-guard.md and follow it exactly. Claim Task 6.")

After Task 6 approved → spawn DevOps:
  Task(subagent_type="general-purpose", team_name="tdd-story-team", name="devops",
    prompt="You are Sam, the DevOps agent on the tdd-story-team. Read @.claude/agents/devops.md and follow it exactly. Claim Task 7.")

After Task 7 complete → claim Task 8 yourself: run npm test, create PR via gh pr create, send shutdown_request to all teammates.

Communication rules: 2 lines max per message. No fluff."""
)
```

### Step 5: Monitor

After spawning PM, monitor task progress via TaskList:
- PM drives all phase transitions and agent spawning
- Tasks 4 and 5 run in parallel if both developers are required
- PM handles verification (Task 8) and creates the PR
- PM shuts down all teammates after PR creation

Report the PR URL to the user when complete.

## Teardown

After PM sends shutdown requests and all spawned agents confirm:
```
TeamDelete()
```

## Error Handling

- **No Ready stories:** PM reports "No Ready stories found" — command ends, inform user
- **Agent spawn failure:** Report which agent failed and suggest re-running
- **Test failures after implementation:** PM messages the relevant developer with failure output
- **Negotiation deadlock:** PM resolves after 1 round (per protocol)

## Notes

- All agents use `general-purpose` subagent type for full tool access
- File boundaries are enforced by agent instructions, not tooling
- `.agile-dev-team/development-progress.yaml` is the shared teamState file — sequential writes guaranteed by task dependencies; `.agile-dev-team/active-story.json` holds the story data populated by `/fetch-story`
- The team auto-cleans up after PR creation
