# Commit & Pull Request (Phase 6)

## Commit Workflow

Uses `/gh:commit` skill. From `@config.yaml` → `commit.separate_fix_and_tests: true`.

**Commit 1: Fix**
```bash
git add src/auth/token.ts
/gh:commit
# → AIGCODE-123: Fix token expiration validation off-by-one error
```

**Commit 2: Tests** (grouped with suffix)
```bash
git add src/auth/__tests__/token.test.ts
/gh:commit
# → AIGCODE-123a: Add regression tests for token expiration bug
```

**Commit message format:**
```
AIGCODE-<issue>: <imperative-title>

<detailed-description>

Fixes #<issue>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Pull Request Creation

```bash
/mr
```

**Generated PR includes** (from config):
- Investigation summary
- Hypothesis outcomes (confirmed/rejected)
- Test validation results
- `Fixes #<issue>` reference

**PR description format:**
```markdown
## Summary
<fix description>

## Investigation Summary
**Root Cause:** <confirmed hypothesis>
**Location:** <file>:<line>

**Hypotheses Evaluated:**
✅ Confirmed: <hypothesis>
❌ Rejected: <hypothesis>

## Changes
- <file>: <change>
- <test-file>: Added N regression tests

## Test Validation
✅ Tests fail before fix (reproduced bug)
✅ Tests pass after fix (validates fix)
✅ Full test suite passes (no regressions)

## Fixes
Fixes #<issue>
```

## Session Archive

After PR created:
```bash
hypothesis-tracker.py archive
```

Moves state to `.claude/debug-sessions/debug-<issue>-<timestamp>.json` and removes `.claude/active-debug.json`.
