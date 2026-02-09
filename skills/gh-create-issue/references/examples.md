# Real Issue Examples

These are actual issues from the `aigensa/website` repository that demonstrate best practices.

## Example 1: Simple Task/Update (Issue #86)

**Title:** Update booking notice to show fully booked until mid-March

**Type:** Task/Content Update

**What makes it good:**
✅ Specific, actionable title
✅ Clear context (why the change is needed)
✅ Exact files mentioned
✅ Language-specific changes listed
✅ Concise and scannable

**Full Issue:**

```markdown
Update the enrollment notice on the learning page to inform visitors we're fully booked until mid-March, with messaging that the next run is coming soon.

**Changes:**
- Update English notice: 'We're fully booked until mid-March. The next run is coming soon!'
- Update Spanish notice: 'Estamos completamente reservados hasta mediados de marzo. ¡La próxima edición está por venir!'

**Files modified:**
- src/i18n/en.json
- src/i18n/es.json
```

**Key Takeaways:**
1. Title describes the outcome, not the action ("Update booking notice" vs "Change JSON files")
2. Context explains why (enrollment status changed)
3. Specific text changes listed
4. Files clearly identified
5. Simple and to-the-point for straightforward tasks

---

## Example 2: Comprehensive Bug Report (Issue #88)

**Title:** Fix Pa11y accessibility test failures not failing CI pipeline

**Type:** Bug/Test Failure

**What makes it good:**
✅ Detailed problem statement with root cause analysis
✅ Current vs expected behavior clearly articulated
✅ Code blocks showing actual error output
✅ Multiple task sections (investigation + fixes)
✅ Files to check listed
✅ Comprehensive acceptance criteria

**Full Issue:**

```markdown
## Problem

Pa11y accessibility tests are currently failing but the CI pipeline shows green (passing), which means build failures are not being detected properly.

### Current Failure Output

```
Running Pa11y on 12 URLs:
 > chrome-error://chromewebdata/ - 3 errors
 > chrome-error://chromewebdata/ - 3 errors
 [... repeated for all 12 URLs]

Errors in chrome-error://chromewebdata/:
 • Zooming and scaling must not be disabled
   (html > head > meta:nth-child(4))
   <meta name="viewport" content="width=device-width, initial-scale=1.0,
   maximum-scale=1.0, user-scalable=no">

 • Img element missing an alt attribute
   (#offline-resources-1x)

 • Img element missing an alt attribute
   (#offline-resources-2x)

✘ 0/12 URLs passed
```

### Expected Behavior

When Pa11y tests fail (0/12 URLs passed), the CI pipeline should:
1. Mark the build as **failed** (red status)
2. Block PR merging if configured
3. Provide clear failure indication in GitHub checks

### Root Causes

1. **Chrome error URLs**: All tests showing `chrome-error://chromewebdata/` instead of actual URLs suggests Pa11y can't access the test URLs
2. **Exit code not propagating**: The `npm run a11y:check` command may be returning exit code 0 even when tests fail
3. **CI configuration**: The workflow may not be properly checking the exit code

### Tasks

- [ ] Investigate why Pa11y is accessing `chrome-error://chromewebdata/` instead of actual URLs
- [ ] Check `.pa11yci.json` configuration for URL serving issues
- [ ] Verify pa11y-ci exits with non-zero code on failure
- [ ] Review CI workflow to ensure it fails on test failures
- [ ] Fix accessibility violations once tests are running correctly:
  - [ ] Remove `maximum-scale=1.0, user-scalable=no` from viewport meta tag
  - [ ] Add alt attributes to offline resource images (if applicable)

### Files to Check

- `.pa11yci.json` - Pa11y configuration
- `.github/workflows/*.yml` - CI workflow configuration
- `package.json` - npm script configuration for `a11y:check`
- HTML templates with viewport meta tags

### Acceptance Criteria

- [ ] Pa11y tests access actual URLs (not chrome-error pages)
- [ ] CI pipeline fails (red) when Pa11y tests fail
- [ ] CI pipeline passes (green) when Pa11y tests pass
- [ ] Accessibility violations are fixed or documented
```

**Key Takeaways:**
1. **Problem section** includes context, current behavior, and expected behavior
2. **Error output** shown in code block with formatting
3. **Root cause analysis** demonstrates investigation thinking
4. **Tasks** broken into investigation and fixes
5. **Files to check** gives clear starting points
6. **Acceptance criteria** are testable and specific
7. Headers make it scannable (##, ###)
8. Bold used for key terms

---

## Comparison: Minimal vs Comprehensive

### When to use Issue #86 style (Simple):
- Straightforward content updates
- Single-file or few-file changes
- Clear requirements, no investigation needed
- Low complexity

**Structure:**
- Context paragraph
- Changes list
- Files list

### When to use Issue #88 style (Comprehensive):
- Complex bugs requiring investigation
- Test failures with unclear causes
- Multiple related tasks
- Root cause analysis needed

**Structure:**
- Problem statement
- Current/Expected behavior
- Root cause analysis
- Tasks (investigation + fixes)
- Files to check
- Acceptance criteria

---

## Anti-Example: What NOT to Do

**Bad Title:** "Fix tests"

**Bad Body:**
```markdown
Tests are failing. Please fix.
```

**Problems:**
❌ Vague title (which tests?)
❌ No context (why failing? when did it start?)
❌ No error output
❌ No acceptance criteria
❌ Not actionable

**Better Version:**
```markdown
## Problem
Pa11y accessibility tests failing in CI but showing green status

## Current Behavior
[Error output here]

## Expected Behavior
CI should fail when tests fail

## Tasks
- [ ] Investigation task
- [ ] Fix task

## Acceptance Criteria
- [ ] Specific criterion
```

---

## Template Selection Based on Examples

**For updates like #86:**
Use the **Task/Chore Template**

**For bugs like #88:**
Use the **Bug Report Template** or **Test Failure Template**

**For new features:**
Use the **Feature Request Template**

**For investigations:**
Use the **Investigation Template**

---

## Style Guide from Examples

### Formatting Patterns

**Use code blocks for:**
- Error messages
- Test output
- Configuration snippets
- File paths in lists

**Use bold for:**
- Key terms (e.g., **failed**, **passed**)
- File types (e.g., **Files modified:**)
- Section labels (e.g., **Changes:**)

**Use checkboxes for:**
- All actionable tasks
- Acceptance criteria
- Subtasks

**Use numbered lists for:**
- Sequential steps
- Expected behaviors
- Procedures

**Use bullet points for:**
- File lists
- Changes lists
- Root causes
- Benefits

### Language Patterns

**Be specific:**
- ✅ "Update English notice to 'We're fully booked until mid-March'"
- ❌ "Update the notice"

**Include context:**
- ✅ "Pa11y tests are failing but CI shows green, allowing violations to reach production"
- ❌ "Tests are broken"

**Use imperative mood:**
- ✅ "Fix Pa11y accessibility test failures"
- ❌ "Fixing Pa11y tests" or "Pa11y tests should be fixed"

**Be actionable:**
- ✅ "Investigate why Pa11y is accessing chrome-error URLs"
- ❌ "Figure out what's wrong"
