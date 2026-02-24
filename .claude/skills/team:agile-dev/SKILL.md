---
name: team:agile-dev
description: Spin up a 5-agent TDD team (PM, Architect, Test Architect, Backend Dev, Frontend Dev) that fetches the next Ready story and delivers it through a TDD-first workflow. Invokable with /agile-dev-team.
---

# Agile Dev Team

## Overview

This skill spins up a coordinated 5-agent team that follows a TDD-first workflow:

```
PM (fetch + enrich) → Architect (design) → Test Architect (failing tests) → Developers (implement) → PM (verify + PR)
```

## Prerequisites

Before running, verify these exist:
- `.claude/agents/pm.md`
- `.claude/agents/architect.md`
- `.claude/agents/test-architect.md`
- `.claude/agents/backend-dev.md`
- `.claude/agents/frontend-dev.md`
- `{{NFR_REGISTRY_FILE}}`
- `{{STORY_WORKFLOW_CONFIG}}` (for `/fetch-story`)

If any agent file is missing, stop and tell the user.

## Execution Steps

### Step 1: Verify Agent Definitions

Read each file in `.claude/agents/` and confirm all 5 exist:
- `pm.md`, `architect.md`, `test-architect.md`, `backend-dev.md`, `frontend-dev.md`

If any are missing, stop and report which files are missing.

### Step 2: Create Team

```
TeamCreate(team_name="tdd-story-team", description="TDD-first development team for story implementation")
```

### Step 3: Create Task List

Create 6 tasks with dependencies:

**Task 1:** "Fetch and enrich story"
- Description: "PM fetches the next Ready story via /fetch-story, enriches with NFRs from {{NFR_REGISTRY_FILE}}, validates with /check-story-quality, creates feature branch, and initializes teamState in {{ACTIVE_STORY_FILE}}."
- activeForm: "Fetching and enriching story"

**Task 2:** "Design implementation approach"
- Description: "Architect reads enriched story, runs /gather-context, maps ACs to files/interfaces, assesses risks, produces implementation brief in {{ACTIVE_STORY_FILE}}. Creates ADR if needed via /create-adr."
- activeForm: "Designing implementation approach"
- blockedBy: [Task 1]

**Task 3:** "Write failing tests"
- Description: "Test Architect reads implementation brief, writes failing tests (TDD red phase) covering happy path, error paths, and corner cases. Confirms tests fail for the right reasons. Stages test files."
- activeForm: "Writing failing tests"
- blockedBy: [Task 2]

**Task 4:** "Implement backend"
- Description: "Backend Dev reads test contracts and implementation brief, implements backend code to make integration tests pass. Commits via /commit. Skip if story is frontend-only."
- activeForm: "Implementing backend"
- blockedBy: [Task 3]

**Task 5:** "Implement frontend"
- Description: "Frontend Dev reads test contracts and implementation brief, implements frontend code to make unit and e2e tests pass. Commits via /commit. Skip if story is backend-only."
- activeForm: "Implementing frontend"
- blockedBy: [Task 3]

**Task 6:** "Verify and create PR"
- Description: "PM runs full {{TEST_COMMAND}}, verifies all tests pass, creates PR via /pr, updates teamState.phase to complete, and shuts down teammates."
- activeForm: "Verifying and creating PR"
- blockedBy: [Task 4, Task 5]

### Step 4: Spawn PM Agent

Spawn PM first — it drives the entire workflow:

```
Task(
  subagent_type="general-purpose",
  team_name="tdd-story-team",
  name="pm",
  prompt="""You are the PM agent on the tdd-story-team.

Read your full instructions at .claude/agents/pm.md and follow them exactly.

Your immediate task: claim Task 1 from the task list and execute it.

Steps:
1. Run /fetch-story to get the next Ready story
2. Read {{NFR_REGISTRY_FILE}} and match NFRs to story labels/content
3. Enrich the story with applicable NFRs and refined ACs
4. Run /check-story-quality to validate
5. Create feature branch: feature/{{PROJECT_PREFIX_LOWER}}-{issueNumber}-{slug}
6. Initialize teamState in {{ACTIVE_STORY_FILE}} with phase "enriching"
7. Mark Task 1 complete
8. Update phase to "designing" and message architect to begin Task 2

After Task 1, monitor the team:
- When architect completes Task 2: update phase to "testing", message test-architect
- When test-architect completes Task 3: update phase to "implementing", message both developers
- When developers complete Tasks 4+5: claim Task 6, run {{TEST_COMMAND}}, create PR via /pr
- After PR: send shutdown_request to all teammates

Communication rules: 2 lines max per message. No fluff."""
)
```

### Step 5: Spawn Remaining Agents

Spawn all 4 remaining agents in parallel:

```
Task(
  subagent_type="general-purpose",
  team_name="tdd-story-team",
  name="architect",
  prompt="""You are the Architect agent on the tdd-story-team.

Read your full instructions at .claude/agents/architect.md and follow them exactly.

Wait for PM to assign you Task 2 or message you. Then:
1. Read enriched story from {{ACTIVE_STORY_FILE}}
2. Run /gather-context to find related code and patterns
3. Map ACs and NFRs to files, interfaces, and function signatures
4. Create ADR if architectural decision is needed (/create-adr)
5. Assess risks: business, implementation, security (1 line each)
6. Write implementationBrief and risks to {{ACTIVE_STORY_FILE}} teamState
7. Mark Task 2 complete
8. Message test-architect with 2-line summary of the brief

Communication rules: 2 lines max per expectation. Constraints: 1 line."""
)

Task(
  subagent_type="general-purpose",
  team_name="tdd-story-team",
  name="test-architect",
  prompt="""You are the Test Architect agent on the tdd-story-team.

Read your full instructions at .claude/agents/test-architect.md and follow them exactly.

Wait for Architect or PM to message you. Then:
1. Read {{ACTIVE_STORY_FILE}} for story + implementationBrief
2. Write failing tests covering happy path, error paths, corner cases
3. Follow existing test patterns in the project
4. Run tests to confirm RED — fix test-side issues until they fail cleanly
5. Stage test files with git add {{TEST_DIR}}/
6. Update teamState.testsWritten in {{ACTIVE_STORY_FILE}}
7. Mark Task 3 complete
8. Message backend-dev and frontend-dev with test contracts (2 lines each)

Communication rules: 2 lines max. Assumptions: 1 line. Constraints: 1 line."""
)

Task(
  subagent_type="general-purpose",
  team_name="tdd-story-team",
  name="backend-dev",
  prompt="""You are the Backend Dev agent on the tdd-story-team.

Read your full instructions at .claude/agents/backend-dev.md and follow them exactly.

Wait for test-architect or PM to message you. Then:
1. Read test contracts and implementationBrief from {{ACTIVE_STORY_FILE}}
2. Read failing integration test files
3. Implement backend code to make integration tests pass
4. Run: {{TEST_INTEGRATION_COMMAND}}
5. Commit via /commit
6. Update teamState.commits in {{ACTIVE_STORY_FILE}}
7. Mark Task 4 complete
8. Message PM with status

If story is frontend-only (no backend files in implementationBrief), mark Task 4 complete immediately and message PM.

Negotiation: 1 round with test-architect if test contract seems wrong. Then escalate to PM."""
)

Task(
  subagent_type="general-purpose",
  team_name="tdd-story-team",
  name="frontend-dev",
  prompt="""You are the Frontend Dev agent on the tdd-story-team.

Read your full instructions at .claude/agents/frontend-dev.md and follow them exactly.

Wait for test-architect or PM to message you. Then:
1. Read test contracts and implementationBrief from {{ACTIVE_STORY_FILE}}
2. Read failing unit and e2e test files
3. Implement frontend code to make tests pass
4. Run: {{TEST_UNIT_COMMAND}}
5. Run: {{TEST_E2E_COMMAND}} (if e2e tests exist)
6. Commit via /commit
7. Update teamState.commits in {{ACTIVE_STORY_FILE}}
8. Mark Task 5 complete
9. Message PM with status

If story is backend-only (no frontend files in implementationBrief), mark Task 5 complete immediately and message PM.

Negotiation: 1 round with test-architect if test contract seems wrong. Then escalate to PM."""
)
```

### Step 6: Monitor

After spawning all agents, monitor progress:
- Agents communicate via SendMessage
- PM drives phase transitions and task assignments
- Tasks 4 and 5 run in parallel
- PM handles verification (Task 6) and creates the PR
- PM shuts down all teammates after PR creation

Report the PR URL to the user when complete.

## Teardown

After PM sends shutdown requests and all agents confirm:
```
TeamDelete()
```

## Error Handling

- **No Ready stories:** PM reports "No Ready stories found" — skill ends, inform user
- **Agent spawn failure:** Report which agent failed and suggest re-running
- **Test failures after implementation:** PM messages the relevant developer with failure output
- **Negotiation deadlock:** PM resolves after 1 round (per protocol)

## Notes

- All agents use `general-purpose` subagent type for full tool access
- File boundaries are enforced by agent instructions, not tooling
- `{{ACTIVE_STORY_FILE}}` is the shared state file — sequential writes guaranteed by task dependencies
- The team auto-cleans up after PR creation
