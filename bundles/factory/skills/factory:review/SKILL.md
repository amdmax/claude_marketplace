---
name: factory:review
description: Stage 60 of the dark factory (experimental). Reviewer agent work - multi-dimensional review (code/security/performance/compliance) via the architect plugin review skills, aggregated review report, release notes, final PR. Invoked by /factory:run after the implementation PR is merged.
argument-hint: "<story-id>"
---

# Purpose
Independent adversarial pass over the merged implementation + release artefacts. Blockers stop the line.

# Config
Read `.factory/factory.yaml`. If missing: STOP, tell the user to run `/factory:init`. This skill's stage = the `stages[]` entry whose `skill` is `factory:review` (`<stage>`, default `60-review-release`); `<prev>` = nearest preceding non-skipped stage (default `50-implementation`). Artefacts/schemas per the stage's config entry; branch per `paths.branch_pattern`. Branch/pickup are done by this stage's `hooks.pre_stage` before this skill runs; standalone invocation: run them yourself first, and run `hooks.post_stage` after step 7.

# Workflow
1. Confirm you are inside the stage worktree on the rendered branch with the pickup commit present; if not, STOP.
2. Determine review diff: implementation merge commit range on master (`gh pr view <impl-pr> --json mergeCommit`).
3. Run review skills against that diff: `/review:code`, `/review:security`, `/review:performance`, `/review:compliance` (compliance feeds ACs as the requirements source). Delegate orchestration to the stage's config `agent` (default `factory-reviewer`).
4. Aggregate findings into `<paths.stories_dir>/<story-id>/review/review-report.yaml` (schema per config entry): per dimension {passed, findings[severity, title, location, recommendation]}; verdict `approved` only if zero unresolved blockers.
5. Blockers found: fix them in THIS stage branch (they are review-scope fixes, not new design), re-run the dimension, mark findings `resolved: true`. Genuine design flaws: verdict `blocked`, escalate in the stage summary.
6. Write `<paths.stories_dir>/<story-id>/release/release-notes.md` (frontmatter): user-facing summary, REQ/AC ids delivered, KPIs to watch, migration/ops notes.
7. Update story.yaml (artefacts, producer_validation; status stays `in-progress` - the `factory:create-pr` hook flips it; on merge the story is DONE - active_stage: null). Validate: `uv run --project ${CLAUDE_PLUGIN_ROOT} factory validate-stage <story-id> <stage>` exit 0. Prepare the stage summary (future PR body): verdict, findings table, release notes, validation output. Report it and STOP - commit/push/PR are performed by this stage's `hooks.post_stage`.

# Validation
- Every dimension ran (paste skill outputs); report schema-valid.
- verdict `approved` requires zero open blocker/major... blocker strictly; majors listed with explicit accept/fix decision for the human gate.
- Release notes reference only delivered REQ/AC ids (no scope inflation).

# Exceptions
- Verdict `blocked` on design flaw: the post_stage hooks still run (the report IS the artefact; PR still opens); human decides rollback vs new story vs accept-risk.
- Hotfix path (human says "ship now"): record the override in review-report as finding `severity: info, title: human-override`.
