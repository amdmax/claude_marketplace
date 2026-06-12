---
name: factory:architecture
description: Stage 30 of the dark factory (experimental). Architect agent work - feature design doc, C4 component diagram, ERD, ADRs (incl. stack decision), API contracts, NFRs, implementation plan, all indexed in a design manifest. Reuses the architect plugin skills. Invoked by /factory:run after BA (and UX if applicable) PRs are merged.
argument-hint: "<story-id>"
---

# Purpose
Decide HOW we build it: stack ADR, component design, data model, contracts, phased implementation plan - every AC mapped to a design element.

# Config
Read `.factory/factory.yaml`. If missing: STOP, tell the user to run `/factory:init`. This skill's stage = the `stages[]` entry whose `skill` is `factory:architecture` (`<stage>`, default `30-architecture`). Upstream = ALL preceding stages since the last validated gate, skipping `skipped` ones (defaults `10-ba` + `20-ux`). Artefacts/schemas per the stage's config entry; branch per `paths.branch_pattern`. Branch/pickup are done by this stage's `hooks.pre_stage` before this skill runs (this stage's `factory:pickup` is configured via `args` to validate ALL upstream stages); standalone invocation: run them yourself first, and run `hooks.post_stage` after step 4.

# Workflow
1. Confirm you are inside the stage worktree on the rendered branch with the pickup commit present; if not, STOP.
2. Plugin shim so `arch:*` skills resolve story context:
   - `.agile-dev-team/active-story.yaml`: `{issueNumber: <story-id>, title, context: <paths.stories_dir>/<story-id>/}` (gitignored working file; do not commit).
   - `<paths.stories_dir>/<story-id>/scout.yaml`: tasks derived from ACs, dependencies (mention SQS/SNS/Kafka only if real - drives asyncapi skip).
3. Produce the stage's config `artefacts` under `<paths.stories_dir>/<story-id>/` (delegate heavy analysis to the stage's config `agent`, default `factory-architect`); defaults under `design/`:
   - `feature-design.md`: components, responsibilities, decisions, alternatives (frontmatter).
   - `c4-component.mmd` (C4Component) and `erd.mmd` (erDiagram) - only if data model touched.
   - Stack/technology ADRs via `/arch:adr-yaml` + `/arch:adr-render` (writes docs/adr/NNNN-*.adr.yaml). At minimum ONE ADR deciding the stack for this story if not already covered by an existing ADR - cite it either way.
   - NFRs: `/arch:gather-nfr` or seed `design/nfr.yaml` from requirement KPIs.
   - Contracts: `/arch:openapi-contract` and `/arch:asyncapi-contract` (both skip cleanly when N/A).
   - `/arch:implementation-plan` -> `design/implementation-plan.yaml`.
   - `design/design-manifest.yaml`: index of all artefacts {path, kind} + `ac_mapping` (every AC -> design elements) + `stack_adr` path (schema per config entry).
4. Update story.yaml (artefacts, producer_validation; status stays `in-progress` - the `factory:create-pr` hook flips it) + traceability untouched (no new ids this stage). Producer validation: `uv run --project ${CLAUDE_PLUGIN_ROOT} factory validate-stage <story-id> <stage>` exit 0. Prepare the stage summary (future PR body): design summary, diagrams, ADR list, AC->design coverage table, validation output. Report it and STOP - commit/push/PR are performed by this stage's `hooks.post_stage`.

# Validation
- design-manifest ac_mapping covers EVERY AC (uncovered ACs = fail; fix or escalate in the stage summary).
- Mermaid diagrams parse (validate_stage mermaid check).
- ADR/OpenAPI artefacts pass the plugin's own validators (its PostToolUse hooks fire on write).
- Respect repo constraints: architect authority rules in CLAUDE.md; check `docs/architect/decisions/` before minting a contradicting ADR.

# Exceptions
- Do NOT use `arch:design-review` (GitHub-comment gate) - the factory gate is the PR merge.
- Design needs a requirement change: stop, write the conflict in the stage summary under "Escalations"; never silently edit requirement.yaml (that is an intake-stage artefact owned by an approved PR).
