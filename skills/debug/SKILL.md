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

- **State Management**: `@references/hypothesis-tracking.md`
- **Research Strategies**: `@references/research-strategies.md`
- **Test Patterns**: `@references/test-generation-guide.md`

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
# Use /create-story skill for issue creation
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

**Also Creates:** `.agile-dev-team/active-story.json` (for `/gh:commit` integration)
```json
{
  "issueNumber": 123,
  "title": "Authentication fails with expired tokens",
  "url": "https://github.com/owner/repo/issues/123"
}
```

---

# Phase 2: Hypothesis Generation

## Generating Hypotheses

Analyze the bug report to generate 3-5 hypotheses ranked by confidence.

**Information Sources:**
1. Issue title and description
2. Error messages or stack traces
3. Reproduction steps
4. Expected vs actual behavior
5. Similar past bugs (search archived sessions)

## Hypothesis Types

Based on `@config.yaml` → `hypothesis_generation.types_to_consider`:

### 1. logic_error
**Indicators:**
- Wrong comparison operators (>, <, >=, <=)
- Off-by-one errors
- Incorrect boolean logic
- Flawed calculations

**Example:**
"Token expiration check uses > instead of >="

### 2. missing_validation
**Indicators:**
- Null/undefined errors
- Missing input checks
- Unhandled edge cases
- No error handling

**Example:**
"Missing null check for token expiration field"

### 3. race_condition
**Indicators:**
- Timing-dependent failures
- Concurrent access issues
- Async/await problems
- Intermittent bugs

**Example:**
"Session Map accessed without synchronization"

### 4. configuration
**Indicators:**
- Environment-specific failures
- Missing env variables
- Wrong defaults
- Config not loaded

**Example:**
"TOKEN_EXPIRY not set in production environment"

### 5. dependency
**Indicators:**
- Recent dependency updates
- Deprecated API usage
- Version mismatches
- Breaking changes

**Example:**
"jwt-decode 4.0 changed decode() signature"

## Creating Hypotheses

```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-hypothesis \
  "<description>" \
  "<type>" \
  "<confidence>"
```

**Parameters:**
- `description`: Clear, specific hypothesis statement
- `type`: One of: logic_error, missing_validation, race_condition, configuration, dependency
- `confidence`: high, medium, or low

**Example Session:**
```bash
# High confidence - matches error pattern
hypothesis-tracker.py add-hypothesis \
  "Token expiration check uses > instead of >=" \
  "logic_error" \
  "high"

# Medium confidence - possible contributing factor
hypothesis-tracker.py add-hypothesis \
  "Missing null check for exp field" \
  "missing_validation" \
  "medium"

# Low confidence - less likely but possible
hypothesis-tracker.py add-hypothesis \
  "Race condition during token refresh" \
  "race_condition" \
  "low"
```

## Confidence Ranking

**High Confidence:**
- Strong evidence from error messages
- Matches known bug patterns
- Clear code location indicated

**Medium Confidence:**
- Plausible based on symptoms
- Similar to past bugs
- Indirect evidence

**Low Confidence:**
- Speculative
- Would explain symptoms but less likely
- Fallback hypothesis

---

# Phase 3: Research Loop (Autonomous)

## Process Overview

```
FOR each hypothesis (highest confidence first):
  1. Mark as "investigating"
  2. Execute research strategy for hypothesis type
  3. Collect evidence
  4. Evaluate outcome:
     - CONFIRMED → Proceed to Phase 4
     - REJECTED → Next hypothesis
     - NEEDS_INFO → Sub-hypotheses or ask user
  5. Repeat until confirmed or all exhausted
```

## Research Strategy Selection

Based on hypothesis type, use strategy from `@references/research-strategies.md`.

### Example: logic_error Research

```bash
# 1. Get next hypothesis
NEXT=$(hypothesis-tracker.py get-next-hypothesis)
H_ID=$(echo $NEXT | jq -r '.id')

# 2. Mark as investigating
hypothesis-tracker.py update-status "$H_ID" "investigating"

# 3. Execute research strategy
# - Grep for function names from error
# - Read code with context
# - Check git blame/log
# - Look for similar patterns

# 4. Collect evidence
hypothesis-tracker.py add-evidence \
  "$H_ID" \
  "src/auth/token.ts" \
  45 \
  "Found: if (exp > now) return true; Expected: if (exp >= now)"

# 5. If confirmed
hypothesis-tracker.py mark-confirmed "$H_ID"
```

## Evidence Collection

Record **every significant finding** with:
- File path (exact location)
- Line number
- Observation note (what was found)

```bash
hypothesis-tracker.py add-evidence \
  <h-id> \
  "<file-path>" \
  <line-number> \
  "<note>"
```

**Good Evidence Notes:**
- ✅ "Found comparison: if (exp > now). RFC 7519 requires >= for expiration"
- ✅ "No null check before accessing token.exp (line 42)"
- ✅ "git blame shows line changed 3 days ago by commit abc123"

**Bad Evidence Notes:**
- ❌ "Looks wrong"
- ❌ "Check this file"
- ❌ "Might be the issue"

## Hypothesis Outcomes

### CONFIRMED
**Criteria:**
- Strong evidence supports hypothesis
- Can explain bug mechanism
- Can design a fix
- Have 2+ pieces of supporting evidence

**Action:**
```bash
hypothesis-tracker.py mark-confirmed <h-id>
# Auto-rejects all other hypotheses
# Transitions to "fix_implementation" phase
```

### REJECTED
**Criteria:**
- Evidence contradicts hypothesis
- Code is correct as written
- Root cause is elsewhere

**Action:**
```bash
hypothesis-tracker.py update-status <h-id> "rejected"
# Move to next hypothesis
```

### NEEDS_INFO
**Criteria:**
- Insufficient information
- Requires user input
- Need to run code/tests
- External dependencies

**Action:**
```bash
hypothesis-tracker.py update-status <h-id> "needs_info"
# Generate sub-hypotheses OR
# Ask user specific questions
```

## Research Depth

From `@config.yaml` → `research.depth`:

**"thorough" (default):**
- Multiple search strategies per hypothesis
- Read related files with context
- Check git history
- Compare with similar code
- 20-30 minutes per hypothesis

Adjust based on config settings.

## Max Iterations

From `@config.yaml` → `research.max_rounds` (default: 3)

If all hypotheses rejected in a round:
1. Generate new hypotheses based on findings
2. Repeat research loop
3. Max 3 rounds total
4. If still no confirmation → Ask user for guidance

---

# Phase 4: Fix Implementation

## User Approval Required

**IMPORTANT:** User must approve fix before implementation.

## Fix Proposal Format

```
🔧 Proposed Fix for Bug #<issue-number>

Root Cause: <confirmed-hypothesis-description>
Location: <file-path>:<line-number>

Fix: <concise-description-of-change>
Rationale: <why-this-fixes-the-bug>

Impact: <effect-on-system>
Risk: <low/medium/high>

Evidence:
- <evidence-1>
- <evidence-2>

Approve? [yes/no/revise]
```

**Example:**
```
🔧 Proposed Fix for Bug #123

Root Cause: Token expiration check uses > instead of >=
Location: src/auth/token.ts:45

Fix: Change if (exp > now) → if (exp >= now)
Rationale: RFC 7519 §4.1.4 requires token rejection AT expiration time,
          not just AFTER expiration.

Impact: Fixes bug, no effect on valid tokens (future expiration)
Risk: Low - single operator change, well-defined behavior

Evidence:
- Line 45: if (exp > now) return true
- RFC 7519 spec requires >= comparison
- Tests confirm tokens accepted at exact expiration

Approve? [yes/no/revise]
```

## User Responses

### "yes" / "approved" / "go ahead"
Proceed with fix implementation.

### "no" / "reject"
- Ask for clarification
- Generate alternative fix approaches
- Re-evaluate hypothesis

### "revise" / "modify"
- Ask what changes are needed
- Adjust fix proposal
- Re-present for approval

## Implementing the Fix

After approval:

1. **Make code changes** using Edit tool
2. **Keep changes minimal** - only what's necessary
3. **Preserve existing functionality**
4. **Record fix:**

```bash
hypothesis-tracker.py set-fix \
  "<file-paths>" \
  "<description>"
```

**Example:**
```bash
hypothesis-tracker.py set-fix \
  "src/auth/token.ts" \
  "Change comparison operator from > to >= on line 45"
```

**Effect:**
- Records fix in state
- Transitions phase to "test_generation"

---

# Phase 5: Test Generation (Mandatory)

## CRITICAL: Tests Are Mandatory

**CANNOT SKIP** - Regression tests are required for all bug fixes.

From `@config.yaml` → `tests.required: true` (cannot be false)

## Test Requirements

Generate **minimum 3 tests** (`config.yaml` → `tests.min_test_count`):

1. **Bug Reproduction Test** - MUST fail before fix, pass after
2. **Edge Case Tests** - Boundary conditions
3. **Regression Protection** - Non-buggy paths still work

See `@references/test-generation-guide.md` for complete patterns.

## Test Location

### Finding Test Files

```bash
# Check for existing test file
find . -path "*auth*" -name "*.test.ts"
find . -path "*auth*" -path "*__tests__*"

# Check test config for patterns
# Read: jest.config.js, vitest.config.ts
```

### Naming Convention

Follow project patterns:
- `src/auth/token.ts` → `src/auth/__tests__/token.test.ts`
- `src/auth/token.ts` → `src/auth/token.test.ts`

## Test Structure

```typescript
describe('Bug #<issue>: <title>', () => {
  // 1. REPRODUCTION TEST (CRITICAL)
  it('should <expected-behavior> <specific-scenario>', () => {
    // ARRANGE: Exact bug conditions
    const input = <bug-triggering-input>;

    // ACT: Perform buggy action
    const result = functionUnderTest(input);

    // ASSERT: Expected behavior (NOT buggy)
    expect(result).toBe(<correct-value>);
  });

  // 2. EDGE CASES
  describe('Edge cases', () => {
    it('should handle boundary condition 1', () => { ... });
    it('should handle boundary condition 2', () => { ... });
  });

  // 3. REGRESSION PROTECTION
  describe('Regression protection', () => {
    it('should maintain working behavior 1', () => { ... });
    it('should maintain working behavior 2', () => { ... });
  });
});
```

## Example: Token Expiration Tests

```typescript
describe('Bug #123: Token expiration off-by-one error', () => {
  // REPRODUCTION TEST
  it('should reject token at exact expiration time', () => {
    const now = Date.now();
    const token = createToken({ exp: now });
    expect(validateToken(token)).toBe(false);
  });

  // EDGE CASES
  describe('Edge cases', () => {
    it('should reject token 1ms after expiration', () => {
      const token = createToken({ exp: Date.now() - 1 });
      expect(validateToken(token)).toBe(false);
    });

    it('should accept token 1ms before expiration', () => {
      const token = createToken({ exp: Date.now() + 1 });
      expect(validateToken(token)).toBe(true);
    });
  });

  // REGRESSION PROTECTION
  describe('Regression protection', () => {
    it('should accept valid future token', () => {
      const token = createToken({ exp: Date.now() + 3600000 });
      expect(validateToken(token)).toBe(true);
    });
  });
});
```

## Test Validation (CRITICAL)

**MANDATORY:** Tests must be validated fail-before/pass-after.

From `@config.yaml` → `tests.validate_before_after: true`

### Validation Steps

```bash
# 1. Stash current changes (includes fix)
git stash

# 2. Checkout pre-fix commit
git checkout HEAD~1

# 3. Run tests - MUST FAIL
npm test -- path/to/test-file.test.ts
# Expected: Bug reproduction test FAILS

# 4. Return to fixed state
git checkout -
git stash pop

# 5. Run tests - MUST PASS
npm test -- path/to/test-file.test.ts
# Expected: All tests PASS

# 6. Run full suite - no regressions
npm test
# Expected: All tests pass
```

### Recording Tests

After successful validation:

```bash
hypothesis-tracker.py set-tests \
  "<test-file-paths>" \
  "<description>" \
  <test-count>

# Then mark as validated
hypothesis-tracker.py mark-tests-validated
```

**Example:**
```bash
hypothesis-tracker.py set-tests \
  "src/auth/__tests__/token.test.ts" \
  "Added 4 test cases covering token expiration scenarios" \
  4

hypothesis-tracker.py mark-tests-validated
```

**Effect:**
- Records tests in state
- Sets `validated: true`
- Transitions phase to "commit_and_pr"
- Changes status to "fixed"

### Validation Failure

If tests **pass before fix**:

```
🛑 BLOCKED: Cannot proceed without validated regression tests

Issue: Tests passed before fix (don't reproduce bug)

Possible causes:
- Test doesn't trigger exact bug condition
- Test assertion is wrong (testing buggy behavior)
- Fix applied to wrong location

Action: Review and fix reproduction test, then re-validate
```

**DO NOT PROCEED** until tests properly validated.

---

# Phase 6: Commit & Pull Request

## Commit Workflow

Uses `/gh:commit` skill with AIGCODE numbering.

From `@config.yaml` → `commit.use_skill: true`

### Separate Commits for Fix and Tests

From `@config.yaml` → `commit.separate_fix_and_tests: true`

**Commit 1: Fix**
```bash
# Stage fix files only
git add src/auth/token.ts

# Use /gh:commit skill (reads .agile-dev-team/active-story.json)
/gh:commit
# Generates: AIGCODE-123: Fix token expiration validation off-by-one error
```

**Commit 2: Tests** (grouped with suffix)
```bash
# Stage test files only
git add src/auth/__tests__/token.test.ts

# Use /gh:commit skill
/gh:commit
# Generates: AIGCODE-123a: Add regression tests for token expiration bug
```

### Commit Message Format

```
AIGCODE-<issue>: <imperative-title>

<detailed-description>

Fixes #<issue>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Pull Request Creation

Uses `/mr` skill.

From `@config.yaml` → `pull_request.use_skill: true`

```bash
/mr
```

### PR Description Format

From config:
- `include_investigation_summary: true`
- `include_hypothesis_outcomes: true`
- `include_test_validation: true`

**Generated PR Description:**
```markdown
## Summary
Fixes token expiration validation off-by-one error that allowed tokens
to be accepted at exact expiration time.

## Investigation Summary

**Root Cause:** Token expiration check used `>` instead of `>=`
**Location:** src/auth/token.ts:45

**Hypotheses Evaluated:**
✅ Confirmed: Token expiration check uses > instead of >=
❌ Rejected: Missing null check for exp field
❌ Rejected: Race condition during token refresh

## Changes
- src/auth/token.ts: Changed comparison operator from > to >=
- src/auth/__tests__/token.test.ts: Added 4 regression tests

## Test Validation
✅ Tests fail before fix (reproduced bug)
✅ Tests pass after fix (validates fix)
✅ Full test suite passes (no regressions)

## Fixes
Fixes #123

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Session Archive

After PR created:

```bash
hypothesis-tracker.py archive
```

**Effect:**
- Moves state to `.claude/debug-sessions/debug-<issue>-<timestamp>.json`
- Removes `.claude/active-debug.json`
- Preserves complete investigation history

---

# Error Handling

## Common Issues

### No Active Session
```
Error: No active debug session
```
**Solution:** Run `/debug` to start new session

### Session Already Exists
```
Error: Active debug session already exists
```
**Solution:**
```bash
# Check current session
hypothesis-tracker.py status

# Archive if done
hypothesis-tracker.py archive

# Or resume if continuing
/debug
```

### Invalid Hypothesis Type
```
Error: Invalid type 'typo_error'
Valid types: logic_error, missing_validation, race_condition, configuration, dependency
```
**Solution:** Use valid type from list

### No Pending Hypotheses
```
No pending hypotheses
```
**Solution:** Generate new hypotheses or mark existing as investigating

### Tests Not Validated
```
⚠️ Tests not yet validated - run validation process
```
**Solution:** Run fail-before/pass-after validation procedure

### Test Validation Failed
```
🛑 BLOCKED: Cannot proceed without validated regression tests
```
**Solution:**
1. Review reproduction test
2. Ensure it triggers exact bug condition
3. Verify assertion tests CORRECT behavior
4. Re-run validation

## Resuming Interrupted Sessions

If session interrupted (connection lost, timeout, etc.):

```bash
# Check for active session
hypothesis-tracker.py status

# Resume with /debug
/debug
```

State is preserved in `.claude/active-debug.json` - workflow continues from current phase.

---

# Integration Points

## With /create-story
Invoked when user doesn't provide issue number and wants to create new bug report.

## With /gh:commit
Reads `.agile-dev-team/active-story.json` for:
- Issue number (AIGCODE-### numbering)
- Automatic grouping (AIGCODE-###, AIGCODE-###a)
- "Fixes #123" reference

## With /mr
Creates PR with:
- Investigation summary
- Hypothesis outcomes
- Test validation results
- Links to issue

---

# Tips & Best Practices

## Hypothesis Generation
- Start with most obvious/likely causes
- Use error messages as primary evidence
- Consider recent code changes (git log)
- Think about similar past bugs

## Research
- Collect evidence systematically
- Record everything (file:line:note)
- Know when to stop (avoid rabbit holes)
- Use git history for context

## Fix Design
- Keep changes minimal
- Test locally if possible
- Consider edge cases
- Think about backwards compatibility

## Test Writing
- Focus on reproduction first
- Cover edge cases thoroughly
- Ensure tests are deterministic
- Use clear test names

## Validation
- NEVER skip test validation
- Verify fail-before/pass-after
- Run full suite to catch regressions
- Check for flaky tests

---

# Configuration Reference

See `@config.yaml` for all user-configurable options:

```yaml
hypothesis_generation:
  initial_count: 5
  types_to_consider: [...]

research:
  max_rounds: 3
  depth: "thorough"
  include_git_history: true
  context_lines: 20

tests:
  required: true              # CANNOT be false
  validate_before_after: true # CANNOT be false
  min_test_count: 3
  types: [...]

commit:
  use_skill: true
  separate_fix_and_tests: true
  include_fixes_reference: true

pull_request:
  use_skill: true
  include_investigation_summary: true
  include_hypothesis_outcomes: true
  include_test_validation: true
```

---

# Examples

## Example 1: Logic Error (Token Validation)

```bash
# Start debugging
/debug 123

# System generates hypotheses
# - h1: Token expiration uses > instead of >= (high)
# - h2: Missing null check (medium)
# - h3: Race condition (low)

# Research h1 (autonomous)
# - Grep for validateToken function
# - Read src/auth/token.ts with context
# - Find: if (exp > now) return true; (line 45)
# - Check RFC 7519 spec: requires >=
# - Confirm hypothesis h1

# Fix proposal (requires user approval)
🔧 Proposed Fix for Bug #123
Root Cause: Token expiration check uses > instead of >=
Location: src/auth/token.ts:45
Fix: Change if (exp > now) → if (exp >= now)
Approve? yes

# Implement fix
# Edit src/auth/token.ts line 45

# Generate tests (mandatory)
# Create src/auth/__tests__/token.test.ts
# - Reproduction: reject at exact expiration
# - Edge: 1ms before/after expiration
# - Regression: valid future tokens work

# Validate tests (fail-before/pass-after)
# ✅ Tests validated successfully

# Commit fix
git add src/auth/token.ts
/gh:commit
# AIGCODE-123: Fix token expiration validation off-by-one error

# Commit tests
git add src/auth/__tests__/token.test.ts
/gh:commit
# AIGCODE-123a: Add regression tests for token expiration bug

# Create PR
/mr
# PR created with investigation summary

# Archive session
# Session archived to .claude/debug-sessions/
```

## Example 2: Missing Validation

```bash
/debug 456

# Hypotheses generated
# - h1: Missing null check for email field (high)
# - h2: Regex validation too strict (medium)

# Research h1
# - Read src/validators/email.ts
# - Compare with other validators
# - Find: no null check before regex test
# - Confirm h1

# Fix approved
# Add: if (!email) return false;

# Tests created & validated
# Commit & PR
```

---

# Troubleshooting

## Script Not Found
```bash
# Make script executable
chmod +x .claude/skills/debug/scripts/hypothesis-tracker.py
```

## Python Not Found
```bash
# Check Python 3 installation
python3 --version

# Update shebang if needed
# Edit hypothesis-tracker.py line 1
```

## State File Corrupted
```bash
# Backup and reset
cp .claude/active-debug.json .claude/active-debug.json.bak
# Manually edit or delete to start fresh
```

## Tests Won't Fail Before Fix
- Review reproduction test logic
- Verify test triggers exact bug condition
- Check assertion tests CORRECT behavior (not buggy)
- Ensure test uses proper mocks/fixtures

## Can't Find Test Location
```bash
# Search for test patterns
find . -name "*.test.*" -o -name "*.spec.*"
grep -r "testMatch" jest.config.js
grep -r "test" package.json
```
