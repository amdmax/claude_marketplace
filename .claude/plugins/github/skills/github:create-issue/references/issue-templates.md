# GitHub Issue Templates

This file contains templates for different types of GitHub issues. Each template provides a structured format optimized for clarity and actionability.

## Bug Report Template

```markdown
## Problem
[Clear, one-sentence description of the issue]

## Current Behavior
[What happens now - be specific]

## Expected Behavior
[What should happen instead]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [Third step]

## Additional Context
- **Environment**: [OS, browser, versions, etc.]
- **Related files**: [`path/to/file.ts`]
- **Error messages**:
  ```
  [Paste error output here]
  ```

## Tasks
- [ ] Investigate root cause
- [ ] Implement fix
- [ ] Add test coverage
- [ ] Update documentation if needed

## Acceptance Criteria
- [ ] Issue no longer reproduces following steps above
- [ ] All tests pass
- [ ] No regression in related functionality
```

## Feature Request Template

```markdown
## Problem Statement
[What problem does this solve? Why is it needed?]

## Proposed Solution
[Describe the feature/enhancement]

## Benefits
- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

## Implementation Approach
[High-level approach if known, otherwise leave blank]

## Alternatives Considered
- **Option 1**: [Description and why not chosen]
- **Option 2**: [Description and why not chosen]

## Tasks
- [ ] Design/plan implementation approach
- [ ] Implement feature
- [ ] Add test coverage
- [ ] Update documentation

## Acceptance Criteria
- [ ] Feature works as described in proposed solution
- [ ] All tests pass
- [ ] Documentation updated with usage examples
```

## Task/Chore Template

```markdown
## What Needs to Be Done
[Clear description of the task]

## Why
[Context or motivation - what problem does this solve or improve?]

## Current State
[Describe the current situation if applicable]

## Desired Outcome
[What the end state should look like]

## Tasks
- [ ] [Specific task 1]
- [ ] [Specific task 2]
- [ ] [Specific task 3]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
```

## Investigation Template

```markdown
## Question/Problem
[What needs to be investigated?]

## Context
[Why is this investigation needed? What's the broader context?]

## Scope
[What should be investigated? What's out of scope?]

## Research Tasks
- [ ] [Investigation task 1]
- [ ] [Investigation task 2]
- [ ] [Investigation task 3]

## Success Criteria
- [ ] Clear recommendation or conclusion documented
- [ ] Findings shared with team
- [ ] Next steps identified (if any)

## Notes
[Space for ongoing findings and observations]
```

## Test Failure Template

```markdown
## Test Issue
[Specific test(s) failing]

## Current Behavior
[What the test shows now]

**Test output:**
```
[Paste test failure output]
```

## Expected Behavior
[What should happen]

## Root Cause
[If known, describe the root cause. Otherwise leave for investigation]

## Tasks
- [ ] Investigate why test is failing
- [ ] Fix underlying issue or update test if expectations changed
- [ ] Verify all related tests pass
- [ ] Prevent regression

## Acceptance Criteria
- [ ] All tests pass
- [ ] Test coverage maintained or improved
- [ ] CI pipeline green
```

## Template Selection Guide

**Use Bug Report when:**
- Something that worked is now broken
- Functionality doesn't match expected behavior
- There are errors or exceptions

**Use Feature Request when:**
- Adding new capability
- Enhancing existing functionality
- User-facing improvements

**Use Task/Chore when:**
- Technical debt cleanup
- Refactoring
- Build/deployment improvements
- Documentation updates

**Use Investigation when:**
- Need to research options
- Root cause analysis required
- Architecture decisions needed

**Use Test Failure when:**
- Specific tests failing in CI/CD
- Test suite issues
- Coverage problems
