---
name: bug-fix
description: Automate investigation and fixing of reported bugs from GitHub backlog. Use when user requests bug fixing, wants to pick up issues from backlog, or says phrases like "fix this bug", "investigate bug report", "work on reported issue". REQUIRED: Always create regression tests before committing any fix.
---

# Bug Fix Automation

> **Critical Requirement:** Regression tests are MANDATORY for every bug fix. No fix may be committed without tests that validate the fix and prevent recurrence.

## Quick Start

```bash
# Invoke the skill
/bug-fix

# Skill workflow:
# 1. Fetch bugs from GitHub (label: "bug")
# 2. Select bug to work on
# 3. Investigate root cause
# 4. Implement fix
# 5. Create regression tests (REQUIRED)
# 6. Commit fix + tests
# 7. Create PR linked to bug issue
```

## Workflow

### Step 1: Fetch Bugs from GitHub Backlog

```bash
# List open bugs
gh issue list \
  --label "bug" \
  --state open \
  --json number,title,body,labels,createdAt \
  --limit 20
```

**Present bugs to user** via AskUserQuestion:
- Show bug number, title, and age
- Include severity labels if present (critical, high, medium, low)
- Allow user to select which bug to work on

**Store selected bug:**
```bash
# Save to .claude/active-bug.json
{
  "issueNumber": 123,
  "title": "Authentication fails with expired tokens",
  "body": "...",
  "url": "https://github.com/owner/repo/issues/123",
  "labels": ["bug", "authentication", "high-priority"]
}
```

### Step 2: Investigation Phase

**Read the bug report thoroughly:**
- Extract reproduction steps
- Identify error messages and stack traces
- Note affected components/files
- Check for related issues or PRs

**Locate relevant code** using Task tool with Explore agent:
```bash
# Example investigation
# If bug mentions "authentication fails", search for:
# - authentication logic
# - token validation code
# - error handling paths
```

**Analyze git history** if helpful:
```bash
# Find recent changes to relevant files
git log --since="1 month ago" --oneline -- path/to/file.ts

# Check when bug might have been introduced
git blame path/to/file.ts
```

**Document findings:**
- Which file(s) contain the bug
- What code is responsible
- When the bug was likely introduced
- Why the code behaves incorrectly

### Step 3: Root Cause Analysis

Identify the **specific cause**:
- Logic error (wrong condition, off-by-one, etc.)
- Missing validation or error handling
- Race condition or timing issue
- Incorrect assumptions about data
- Dependency or configuration issue

Understand **why it wasn't caught**:
- Missing test coverage
- Edge case not considered
- Integration gap between components

Determine **scope of impact**:
- How many users affected
- Which features/paths trigger the bug
- Data integrity concerns
- Security implications

### Step 4: Generate Fix

**Create minimal, focused fix:**
- Change only what's necessary
- Preserve existing behavior for non-bug cases
- Add validation if missing
- Improve error messages if unclear

**Explain the fix clearly:**
- What changed and why
- Why this approach was chosen
- What edge cases are now handled
- Any performance or compatibility considerations

**Example fix explanation:**
```
The bug occurs because token expiration is checked using > instead of >=,
causing tokens to be accepted for one extra second after expiration.

Fix: Change condition from `exp > now` to `exp >= now`

This ensures tokens are rejected at or after their expiration time,
matching RFC 7519 JWT specification.
```

### Step 5: Create Regression Tests (REQUIRED)

**This step is MANDATORY.** No fix may be committed without regression tests.

#### Test Requirements

**Must include:**
1. **Test that reproduces the bug** - Fails before fix, passes after fix
2. **Edge case tests** - Cover boundary conditions related to the bug
3. **Integration tests** - Verify fix works end-to-end if applicable

**Test structure:**
```typescript
describe('Bug #123: Authentication with expired tokens', () => {
  it('should reject tokens at exact expiration time', () => {
    // This test would fail before the fix
    const token = createToken({ exp: now });
    expect(validateToken(token)).toBe(false);
  });

  it('should reject tokens after expiration time', () => {
    const token = createToken({ exp: now - 1 });
    expect(validateToken(token)).toBe(false);
  });

  it('should accept tokens before expiration time', () => {
    const token = createToken({ exp: now + 3600 });
    expect(validateToken(token)).toBe(true);
  });

  it('should handle edge case: expiration at epoch 0', () => {
    const token = createToken({ exp: 0 });
    expect(validateToken(token)).toBe(false);
  });
});
```

#### Test Location

**Add tests to existing test files** when possible:
- Keep tests near the code they validate
- Follow project's test structure conventions
- Example: Fix in `src/auth.ts` → Tests in `src/__tests__/auth.test.ts`

**Create new test file** if needed:
- Use project's naming convention (`.test.ts`, `.spec.ts`, `_test.py`, etc.)
- Place in appropriate test directory
- Include descriptive name: `bug-123-token-expiration.test.ts`

#### Test Validation

**Before committing:**
1. Run tests to confirm they fail without the fix
2. Apply the fix
3. Run tests to confirm they now pass
4. Run full test suite to ensure no regressions

```bash
# Run specific test
npm test -- path/to/test.test.ts

# Run full suite
npm test
```

**Test coverage:**
- Aim for 100% coverage of the bug scenario
- Cover all code paths affected by the fix
- Include edge cases discovered during investigation

### Step 6: Commit Fix and Tests

**Use /gh:commit skill** with active bug issue:

```bash
# Commit the fix
git add <fixed-files>
/gh:commit
# → AIGCODE-123: Fix token expiration validation off-by-one error

# Commit the tests (separate commit)
git add <test-files>
/gh:commit
# → AIGCODE-123a: Add regression tests for token expiration bug
```

**Commit message format:**
```
AIGCODE-123: Fix token expiration validation off-by-one error

Tokens were incorrectly accepted for one second after expiration due
to > instead of >= comparison. Changed to >= to match RFC 7519 spec.

Fixes #123

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Link to bug issue:**
- Use `Fixes #123` in commit message
- GitHub will auto-close issue when PR merges

### Step 7: Create Pull Request

**Use /mr skill:**

```bash
/mr
```

**PR description should include:**
```markdown
## Bug Fix: Authentication fails with expired tokens

Fixes #123

## Problem
Tokens were incorrectly accepted for 1 second after expiration due to
off-by-one error in comparison operator.

## Solution
Changed token expiration check from `>` to `>=` to properly reject
tokens at exact expiration time per RFC 7519.

## Testing
- ✅ Added regression tests for exact expiration, past expiration, future expiration
- ✅ Added edge case test for epoch 0 expiration
- ✅ All tests pass
- ✅ Full test suite passes without regressions

## Impact
- Security: Tokens now properly expire at specified time
- Users: No impact on valid tokens
- Breaking: None
```

## Configuration

Create `config.yaml` in skill directory:

```yaml
bug_selection:
  label: "bug"
  auto_assign_to_self: true
  max_bugs_to_show: 20

investigation:
  explore_depth: "thorough"  # quick, medium, thorough
  include_git_history: true
  analyze_stack_traces: true

fix:
  require_explanation: true
  require_edge_case_analysis: true

tests:
  required: true  # CANNOT be false
  separate_commit: true
  test_before_and_after: true
  require_edge_cases: true

commit:
  link_to_issue: true  # Add "Fixes #123" to commit
  use_aigcode_prefix: true

pr:
  auto_create: true
  request_review: false  # Set to true to auto-request reviews
```

## Error Handling

**No bugs found:**
```
❌ No open bugs found in backlog with label "bug"

Try:
- Check if bugs use different labels
- Verify GitHub CLI authentication
- Look for closed bugs that need reopening
```

**Investigation fails:**
```
⚠️  Unable to locate bug in codebase

Options:
1. Provide more details about where to search
2. Share reproduction steps
3. Link to related files or error logs
```

**Tests cannot be created:**
```
🛑 BLOCKED: Cannot commit without regression tests

Regression tests are REQUIRED for all bug fixes. Please:
1. Identify test framework (Jest, pytest, etc.)
2. Locate existing test files for reference
3. Write tests that reproduce the bug
4. Verify tests fail before fix, pass after fix
```

**Tests fail after fix:**
```
❌ Tests still failing after applying fix

This suggests:
- Fix is incomplete
- Fix introduced new bugs
- Tests need adjustment

Review and iterate before committing.
```

## Best Practices

### Investigation

1. **Read the full bug report** - Don't skip reproduction steps
2. **Search for related issues** - May provide additional context
3. **Test locally if possible** - Reproduce before fixing
4. **Check git blame** - Understand why code was written that way

### Fixing

1. **Minimal changes** - Fix only the bug, don't refactor
2. **Preserve behavior** - Ensure non-buggy paths still work
3. **Consider edge cases** - Think beyond the reported scenario
4. **Add validation** - Prevent similar bugs in future

### Testing

1. **Test-driven** - Write failing test first
2. **Cover edge cases** - Not just the happy path
3. **Integration tests** - Verify fix works end-to-end
4. **Run full suite** - Catch unintended regressions

### Committing

1. **Separate commits** - Fix in one, tests in another
2. **Link to issue** - Use "Fixes #123" syntax
3. **Clear messages** - Explain what and why
4. **Verify CI passes** - Don't break the build

## Examples

### Example 1: Logic Error Bug

**Bug report:** "Search returns 11 results when limit=10"

**Investigation:**
- Located: `src/api/search.ts:45`
- Root cause: Loop condition `i <= limit` instead of `i < limit`

**Fix:**
```typescript
// Before
for (let i = 0; i <= limit; i++) {

// After
for (let i = 0; i < limit; i++) {
```

**Regression tests:**
```typescript
describe('Bug #156: Search limit off-by-one', () => {
  it('should return exactly 10 results when limit=10', () => {
    const results = search('query', { limit: 10 });
    expect(results).toHaveLength(10);
  });

  it('should return exactly 1 result when limit=1', () => {
    const results = search('query', { limit: 1 });
    expect(results).toHaveLength(1);
  });

  it('should handle limit=0', () => {
    const results = search('query', { limit: 0 });
    expect(results).toHaveLength(0);
  });
});
```

### Example 2: Missing Validation Bug

**Bug report:** "App crashes when uploading 0-byte file"

**Investigation:**
- Located: `src/upload/handler.ts:78`
- Root cause: No validation for empty files

**Fix:**
```typescript
async function handleUpload(file: File) {
  // Add validation
  if (file.size === 0) {
    throw new Error('Cannot upload empty file');
  }

  // Existing upload logic
  await processFile(file);
}
```

**Regression tests:**
```typescript
describe('Bug #201: Empty file upload crash', () => {
  it('should reject empty file with clear error', async () => {
    const emptyFile = new File([], 'empty.txt');

    await expect(handleUpload(emptyFile))
      .rejects.toThrow('Cannot upload empty file');
  });

  it('should accept file with content', async () => {
    const validFile = new File(['content'], 'valid.txt');

    await expect(handleUpload(validFile))
      .resolves.not.toThrow();
  });

  it('should accept 1-byte file (edge case)', async () => {
    const tinyFile = new File(['a'], 'tiny.txt');

    await expect(handleUpload(tinyFile))
      .resolves.not.toThrow();
  });
});
```

### Example 3: Race Condition Bug

**Bug report:** "Occasionally get duplicate entries in database"

**Investigation:**
- Located: `src/db/insert.ts:92`
- Root cause: No locking or uniqueness check before insert

**Fix:**
```typescript
async function insertUser(data: UserData) {
  // Add unique constraint check
  const existing = await db.user.findUnique({
    where: { email: data.email }
  });

  if (existing) {
    throw new Error(`User with email ${data.email} already exists`);
  }

  return db.user.create({ data });
}
```

**Regression tests:**
```typescript
describe('Bug #178: Duplicate user entries race condition', () => {
  it('should prevent duplicate users with same email', async () => {
    const userData = { email: 'test@example.com', name: 'Test' };

    await insertUser(userData);

    await expect(insertUser(userData))
      .rejects.toThrow('already exists');
  });

  it('should allow multiple users with different emails', async () => {
    await insertUser({ email: 'user1@example.com', name: 'User 1' });
    await insertUser({ email: 'user2@example.com', name: 'User 2' });

    const users = await db.user.findMany();
    expect(users).toHaveLength(2);
  });

  it('should handle concurrent insert attempts', async () => {
    const userData = { email: 'concurrent@example.com', name: 'Test' };

    const promises = Array(5).fill(null).map(() =>
      insertUser(userData).catch(e => e)
    );

    const results = await Promise.all(promises);
    const successes = results.filter(r => !(r instanceof Error));

    expect(successes).toHaveLength(1);
  });
});
```

## Troubleshooting

**Issue: Can't find the bug in codebase**
- Try broader search terms
- Search error messages in logs
- Check recently modified files
- Ask user for more context

**Issue: Fix seems too complex**
- Reassess root cause - might be misunderstood
- Consider if refactoring is truly needed
- Ask user if simpler approach acceptable

**Issue: Tests are flaky**
- Add proper setup/teardown
- Mock external dependencies
- Use deterministic test data
- Add delays for async operations if needed

**Issue: Fix breaks other tests**
- Review what broke - might reveal larger issue
- Consider if original code had hidden dependencies
- May need to update other tests

## Integration with Other Skills

- **Uses `/gh:commit` skill** for creating commits
- **Uses `/mr` skill** for creating pull requests
- **Uses Task tool** with Explore agent for investigation
- **Compatible with `/play-story`** workflow

## References

- See @references/testing-best-practices.md for test patterns
- See @references/bug-investigation.md for debugging techniques
- See @references/examples.md for more bug fix examples
