# GitHub Issue Best Practices

Guidelines for creating high-quality, actionable GitHub issues based on successful patterns in this repository.

## Title Guidelines

### Good Titles
✅ **Specific and actionable**
- "Fix Pa11y tests not failing CI when accessibility issues found"
- "Update booking notice to show fully booked until mid-March"
- "Migrate JavaScript to TypeScript"

✅ **Include key context**
- Mention the component: "Fix Pa11y tests...", "Update booking notice..."
- Use action verbs: Fix, Add, Update, Remove, Migrate

✅ **Use imperative mood**
- "Fix the bug" not "Fixes bug" or "Fixed bug"
- "Add feature" not "Adding feature"

### Avoid
❌ **Vague titles**
- "Bug in tests" → What bug? Which tests?
- "Need feature" → What feature?
- "Problem" → What problem?

❌ **Too generic**
- "Update code" → What code? Why?
- "Fix issue" → Which issue?

❌ **Missing context**
- "Not working" → What's not working?
- "Error" → What error? Where?

## Structure Guidelines

### Use Markdown Effectively

**Headers for sections:**
```markdown
## Problem
[Content]

## Tasks
[Content]
```

**Code blocks with language hints:**
```markdown
```typescript
const example = "code";
```
````

**Checklists for actionable items:**
```markdown
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3
```

**Bold key terms:**
```markdown
**Environment**: Production
**Files affected**: `src/test.ts`, `src/utils.ts`
```

**Link to related issues/PRs:**
```markdown
Related to #123
Blocks #456
```

### Recommended Sections

**For all issues:**
1. **Problem/Context** - What and why
2. **Tasks** - Specific, checkable actions
3. **Acceptance Criteria** - How to verify it's done

**For bugs (add):**
- Current Behavior
- Expected Behavior
- Steps to Reproduce
- Error messages/output

**For features (add):**
- Proposed Solution
- Benefits
- Alternatives Considered

**For investigations (add):**
- Research Questions
- Scope (what to investigate)
- Success Criteria (what answer looks like)

## Content Guidelines

### Include the "Why"

**Good:**
> ## Problem
> Pa11y tests are detecting accessibility issues but the CI pipeline continues to pass, allowing violations to reach production. This undermines our accessibility compliance efforts.

**Poor:**
> ## Problem
> Tests not failing CI

### Provide Context

**Good:**
> The booking notice banner currently says "fully booked until mid-February" but all February sessions are now full. We need to update it to reflect March bookings.
>
> **Files**: `src/components/BookingNotice.tsx`

**Poor:**
> Update booking notice

### List Acceptance Criteria

**Good:**
```markdown
## Acceptance Criteria
- [ ] When Pa11y detects issues, CI pipeline fails with exit code 1
- [ ] Test output clearly shows which accessibility rules failed
- [ ] Documentation updated with how to run Pa11y locally
```

**Poor:**
```markdown
## Acceptance Criteria
- [ ] Fixed
```

### Include File Paths

**Good:**
> **Files affected:**
> - `src/test/pa11y.config.ts` - Update to fail on warnings
> - `.github/workflows/ci.yml` - Check Pa11y exit code

**Poor:**
> Update the config and workflow

### Add Error Messages

**Good:**
````markdown
**Error output:**
```
FAIL src/components/BookingForm.test.ts
  ● BookingForm › validates required fields

    expect(received).toBe(expected)

    Expected: true
    Received: false
```
````

**Poor:**
> Test is failing

## Quality Checks

Before creating an issue, verify:

### ✅ Clarity Check
- Can someone else pick this up without asking questions?
- Is the problem clearly stated?
- Are the success criteria clear?

### ✅ Actionability Check
- Are tasks specific and testable?
- Can each task be checked off independently?
- Is it clear what "done" looks like?

### ✅ Context Check
- Is there enough background information?
- Are related files/issues mentioned?
- Is the "why" explained?

### ✅ Format Check
- Are code examples in code blocks?
- Are tasks in checkbox format?
- Are sections properly structured with headers?
- Is markdown rendering correctly?

## Anti-Patterns

### ❌ Wall of Text
Break up long paragraphs into:
- Bulleted lists
- Sections with headers
- Code blocks
- Short paragraphs (2-3 sentences max)

### ❌ Missing Tasks
Every issue should have actionable tasks:
```markdown
## Tasks
- [ ] Specific task 1
- [ ] Specific task 2
```

Not just a description without next steps.

### ❌ Ambiguous Acceptance Criteria
**Poor:**
- [ ] Works correctly
- [ ] No bugs

**Good:**
- [ ] Form submits successfully with valid data
- [ ] Form shows error message when email is invalid
- [ ] All Pa11y tests pass

### ❌ No Error Details
When reporting bugs/test failures, always include:
- Actual error message
- Stack trace (if applicable)
- Test output
- Environment details

## Examples from This Repository

### Excellent: Issue #86
✅ Clear title: "Update booking notice to show fully booked until mid-March"
✅ Problem statement with context
✅ Specific files mentioned
✅ Clear tasks
✅ Testable acceptance criteria

### Excellent: Issue #88
✅ Comprehensive structure
✅ Root cause analysis
✅ Detailed implementation approach
✅ Clear acceptance criteria
✅ Related issues linked

## Common Mistakes

### 1. Too Minimal
Creating an issue with just a title and one-line description.

**Fix**: Use templates, add context, list tasks.

### 2. Too Verbose
Multi-paragraph walls of text without structure.

**Fix**: Use sections, bullets, and code blocks.

### 3. Missing the "Why"
Describing what to do without explaining why it matters.

**Fix**: Add Problem/Context section explaining motivation.

### 4. Vague Tasks
```markdown
- [ ] Fix the issue
- [ ] Make it work
```

**Fix**: Be specific:
```markdown
- [ ] Update Pa11y config to fail on warnings
- [ ] Add test to verify CI fails when issues detected
```

## Summary

**Great issues are:**
- Scannable (headers, bullets, code blocks)
- Specific (exact files, error messages, steps)
- Actionable (clear tasks and acceptance criteria)
- Contextual (explain the "why", not just "what")
- Complete (all necessary information included)
