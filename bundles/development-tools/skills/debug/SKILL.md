---
name: debug
description: Hypothesis-driven bug investigation with mandatory regression tests
version: 1.0.0
invocations:
  - /debug
  - /debug <issue-number>
category: development-tools
---

# Debug Skill - Hypothesis-Driven Bug Investigation

Systematic bug investigation using the scientific method: generate hypotheses, test them through research, implement fixes with user approval, and create mandatory regression tests to prevent recurrence.

## Quick Start

```bash
# Start debugging (prompts for issue selection or creation)
/debug

# Debug specific issue
/debug 123
```

## Core Workflow

```
1. Issue Selection/Creation
   ↓
2. Hypothesis Generation (3-5 hypotheses)
   ↓
3. Research Loop (autonomous)
   ↓
4. Fix Implementation (requires user approval)
   ↓
5. Test Generation (mandatory, validated)
   ↓
6. Commit & Pull Request
```

## Configuration

User-configurable options in `@config.yaml`:
- Hypothesis count and types
- Research depth (quick/thorough/exhaustive)
- Test validation requirements
- Commit/PR behavior

## Reference Documentation

- **Hypotheses**: `@references/hypotheses.md`
- **Research Loop**: `@references/research-loop.md`
- **Fix Implementation**: `@references/fix-implementation.md`
- **Testing**: `@references/testing.md`
- **Commit & PR**: `@references/commit-and-pr.md`
- **State Management**: `@references/hypothesis-tracking.md`
- **Research Strategies**: `@references/research-strategies.md`
- **Test Patterns**: `@references/test-generation-guide.md`
- **Examples**: `@references/examples.md`

---

# Phase 1: Issue Creation & Selection

## Invocation Patterns

### Without Issue Number
```bash
/debug
```

**Process:**
1. Check for existing session (`.claude/active-debug.json`)
2. If session exists → Offer to resume or archive
3. List open bugs: `gh issue list --label "bug" --state open`
4. User selects from list OR creates new issue

### With Issue Number
```bash
/debug 123
```

**Process:**
1. Check for existing session
2. Fetch issue: `gh issue view 123 --json number,title,body,url`
3. Verify issue has "bug" label
4. Initialize debug session

## Issue Creation

If user doesn't provide an issue number and wants to create one:

```bash
/create-story
```

**Required Information:**
- Title (brief description of bug)
- Label "bug" (automatically added)
- Optional: reproduction steps, error messages

**Example:**
```
Title: Authentication fails with expired tokens
Label: bug
Body: Users with expired tokens can still authenticate.
      Expected: Reject expired tokens
      Actual: Accepts tokens at exact expiration time
```

## Session Initialization

After issue selected/created:

```bash
.claude/skills/debug/scripts/hypothesis-tracker.py init \
  <issue-number> \
  "<title>" \
  "<url>"
```

**Creates:** `.claude/active-debug.json`
```json
{
  "issueNumber": 123,
  "title": "Authentication fails with expired tokens",
  "url": "https://github.com/owner/repo/issues/123",
  "sessionId": "debug-123-20260202-143022",
  "status": "investigating",
  "currentPhase": "hypothesis_generation",
  "hypotheses": [],
  "fix": null,
  "tests": null
}
```

**Also Creates:** `.agile-dev-team/active-story.yaml` (for `/gh:commit` integration)

---

# Phase 2: Hypothesis Generation

Generate 3-5 hypotheses ranked by confidence. See `@references/hypotheses.md` for types, commands, and confidence criteria.

---

# Phase 3: Research Loop (Autonomous)

Investigate hypotheses from highest confidence first; collect evidence; mark CONFIRMED/REJECTED/NEEDS_INFO. See `@references/research-loop.md` for process, commands, and depth settings.

---

# Phase 4: Fix Implementation

**IMPORTANT:** User must approve fix before implementation. See `@references/fix-implementation.md` for proposal format, user responses, and recording the fix.

---

# Phase 5: Test Generation (Mandatory)

**CANNOT SKIP** — regression tests required for all bug fixes (`tests.required: true`).

Generate minimum 3 tests: reproduction (must fail before fix), edge cases, regression protection. See `@references/testing.md` for structure, location, validation steps, and blocking criteria.

---

# Phase 6: Commit & Pull Request

Two separate commits (fix + tests), then `/mr`. See `@references/commit-and-pr.md` for commit format, PR description, and session archive.

---

# Error Handling

### No Active Session
```
Error: No active debug session
```
**Solution:** Run `/debug` to start new session.

### Session Already Exists
**Solution:**
```bash
hypothesis-tracker.py status   # check current session
hypothesis-tracker.py archive  # archive if done
/debug                         # or resume
```

### Invalid Hypothesis Type
Use valid type: `logic_error`, `missing_validation`, `race_condition`, `configuration`, `dependency`

### Tests Not Validated
Run fail-before/pass-after validation. See `@references/testing.md`.

### Test Validation Failed
```
🛑 BLOCKED: Cannot proceed without validated regression tests
```
Review reproduction test: exact bug conditions, correct behavior assertion, proper mocks.

## Resuming Interrupted Sessions

```bash
hypothesis-tracker.py status
/debug
```

State preserved in `.claude/active-debug.json` — continues from current phase.

---

# Integration Points

## With /create-story
Invoked when user wants to create a new bug report without an issue number.

## With /gh:commit
Reads `.agile-dev-team/active-story.yaml` for issue number, grouping (AIGCODE-###a), and "Fixes #123" reference.

## With /mr
Creates PR with investigation summary, hypothesis outcomes, test validation results, and issue links.

---

# Tips & Best Practices

**Hypothesis Generation:** Start with most obvious causes. Use error messages as primary evidence. Consider recent git changes.

**Research:** Collect evidence systematically (file:line:note). Know when to stop. Use git history for context.

**Fix Design:** Keep changes minimal. Consider edge cases and backwards compatibility.

**Testing:** Focus on reproduction first. Ensure tests are deterministic. Use clear test names.

**Validation:** NEVER skip. Verify fail-before/pass-after. Run full suite to catch regressions.

---

# Configuration Reference

See `@config.yaml` for all options:

```yaml
hypothesis_generation:
  initial_count: 5
  types_to_consider: [...]

research:
  max_rounds: 3
  depth: "thorough"
  include_git_history: true

tests:
  required: true              # CANNOT be false
  validate_before_after: true # CANNOT be false
  min_test_count: 3

commit:
  use_skill: true
  separate_fix_and_tests: true

pull_request:
  use_skill: true
  include_investigation_summary: true
  include_hypothesis_outcomes: true
  include_test_validation: true
```

---

# Troubleshooting

**Script not found:** `chmod +x .claude/skills/debug/scripts/hypothesis-tracker.py`

**Python not found:** `python3 --version` — update shebang if needed.

**State file corrupted:** `cp .claude/active-debug.json .claude/active-debug.json.bak` then edit or delete.

**Tests won't fail before fix:** Verify test triggers exact bug condition, assertion tests CORRECT behavior, proper mocks/fixtures.

**Can't find test location:**
```bash
find . -name "*.test.*" -o -name "*.spec.*"
grep -r "testMatch" jest.config.js
```
