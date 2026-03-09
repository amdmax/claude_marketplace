# Phase Transitions and Task Management

## Task Table

| Task | Owner | Blocked By |
|------|-------|------------|
| 1. Fetch and enrich story | pm | — |
| 2. Design implementation approach | architect | Task 1 |
| 3. Write failing tests | test-architect | Task 2 |
| 4. Implement backend | backend-dev | Task 3 |
| 5. Implement frontend | frontend-dev | Task 3 |
| 6. Scope review | scope-guard | Tasks 4+5 |
| 7. Deploy and verify | devops | Task 6 |
| 8. Verify and create PR | pm | Task 7 |

## Phase Sequence

`fetch` → `enriching` → `designing` → `testing` → `implementing` → `guarding` → `deploying` → `verifying` → `complete`

## Transition Actions

- After enrichment complete → set `designing`, message architect
- After architect done → read `requiredRoles`; spawn developer agents; set `testing`, message test-architect
- After tests written → set `implementing`; message spawned developers; if `requiredRoles` is empty, mark Tasks 4+5 complete and go directly to `guarding`
- After Tasks 4+5 complete (or skipped) → set `guarding`, message scope-guard
- After scope-guard approves → check `deploymentRequired`; if true, spawn devops and set `deploying`; if false, skip to Task 8
- After devops completes (or skipped) → set `verifying`, claim Task 8

## Spawning Developer Agents (Task 2 → Task 3 Transition)

After architect completes Task 2, read `teamState.requiredRoles` from `.agile-dev-team/development-progress.yaml`:

```bash
REQUIRED_ROLES=$(yq '.teamState.requiredRoles[]' .agile-dev-team/development-progress.yaml 2>/dev/null)
```

For each role in the list, spawn the agent via Agent tool:
- `"backend-dev"` → spawn backend-dev agent with Task 4 instructions (wait for test-architect, implement, commit, mark complete, message PM)
- `"frontend-dev"` → spawn frontend-dev agent with Task 5 instructions (wait for test-architect, implement, commit, mark complete, message PM)

If `requiredRoles` is `[]`: skip Tasks 4 and 5 — mark both complete and message scope-guard directly.

## Spawning DevOps Agent (Task 6 → Task 7 Transition)

After scope-guard approves Task 6, check `teamState.deploymentRequired`:

```bash
DEPLOY_REQUIRED=$(yq '.teamState.deploymentRequired' .agile-dev-team/development-progress.yaml)
```

If `true`: spawn devops agent with Task 7 instructions. Set phase to `deploying`.
If `false`: mark Task 7 complete immediately. Proceed to Task 8.

## Phase 5: Verify and PR (Task 8)

1. Run full test suite: `npm test`
2. If tests pass, update `teamState.testsPassing` to `true` in `.agile-dev-team/development-progress.yaml`
3. Create PR via `/commit` + `gh pr create`
4. Update GitHub Projects card to **In Review**: `updateGitHubStatus "inReview"`
5. Update `teamState.phase` to `complete`
6. Send shutdown requests to all teammates

## User Escalation Protocol

When architect flags a blocking decision:
1. Relay the question verbatim to the human user
2. Stop the pipeline — do not unblock Task 3+ until the user responds
3. Format: Question (1 sentence) | Option A vs B (1 line each) | Recommendation (1 line)
4. Document the decision in `teamState.risks` with `type: "decision"`

## Error Handling

- If `/fetch-story` finds no Ready stories: notify user and stop
- If `npm test` fails after implementation: message relevant developer with failing test output
- If negotiation exceeds 1 round: PM makes the call and messages both parties
