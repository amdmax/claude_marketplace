# Story Scope Validation

## Purpose

Ensure PR changes align with the active story's stated scope to prevent:
- Scope creep (unrelated features sneaking in)
- Context switching (mixing unrelated concerns)
- Review complexity (harder to review mixed changes)

## Story Focus Detection

Extract focus from story title + labels:

### Authentication/Authorization
**Patterns:** auth, authentication, login, signup, cognito, user pool, jwt, oauth
**Expected files:** lambda/auth-edge/, infrastructure/*cognito*, lambda/custom-message/

### Testing
**Patterns:** test, testing, coverage, guard, validation, CI/CD
**Expected files:** scripts/*test*, .github/workflows/*test*, *test.ts, vitest.config.ts

### Infrastructure
**Patterns:** infrastructure, cdk, stack, deploy, aws, cloudformation
**Expected files:** infrastructure/*, cdk.json, tsconfig infrastructure files

### Content
**Patterns:** content, course, week, material, lesson, module
**Expected files:** content/week_*/, src/build-html.ts, src/templates/

### Dependencies
**Patterns:** deps, dependencies, upgrade, update, npm, package
**Expected files:** package.json, */package-lock.json, */package.json

### Skills/Automation
**Patterns:** skill, automation, workflow, hook, claude code
**Expected files:** .claude/skills/*, .claude/hooks/*, .github/workflows/

## Validation Process

1. **Extract story focus** from title + labels
2. **Get changed files** from PR diff
3. **Match files to focus** using patterns above
4. **Flag unrelated files** - files that don't match focus
5. **Report scope creep** if >20% of files unrelated

## Example Validations

### ✅ Good: Aligned Changes
```
Story: "Fix test guard timeout detection" (focus: testing)
Changed files:
- scripts/test-guard.ts
- .github/workflows/test.yml
- README.md (test documentation)

Result: All files related to testing ✅
```

### ⚠️ Scope Creep Detected
```
Story: "Add user authentication with Cognito" (focus: auth)
Changed files:
- lambda/auth-edge/index.ts ✅
- infrastructure/lib/auth-stack.ts ✅
- lambda/referral/index.ts ⚠️ (unrelated)
- package.json (dependencies for auth) ✅

Result: lambda/referral/index.ts is unrelated to auth story
Flag: "Scope creep: referral Lambda changes not mentioned in auth story"
```

### ❌ Unrelated Changes
```
Story: "Update course content for Week 5" (focus: content)
Changed files:
- infrastructure/lib/website-stack.ts ❌
- lambda/admin/index.ts ❌
- content/week_5/ai-code-review.md ✅

Result: 67% of files unrelated to content story
Flag: "Major scope creep: infrastructure and Lambda changes in content-focused story"
```

## Output Format

When scope issues detected:

```markdown
### 🟡 MINOR: Scope Creep Detected

**Story Context:**
- Story #153: Fix test guard timeout detection
- Focus: Testing
- Labels: testing, bug

**Unrelated Changes:**
- `lambda/referral/index.ts:15-42` - Referral logic unrelated to test guard
- `infrastructure/lib/auth-stack.ts:89` - Auth stack update not in story scope

**Impact:** Mixing concerns makes PR harder to review and increases risk of unintended side effects.

**Recommendation:** Split into separate PRs:
1. This PR: Test guard fixes only
2. New PR: Referral Lambda changes
3. New PR: Auth stack updates

**Agent Prompt:**
```
Review the changed files in this PR and compare against story #153 scope (test guard timeout detection). Identify any files that are unrelated to testing or test guard functionality. Suggest splitting those changes into separate PRs focused on their respective concerns.
```

**References:**
- [Story Scope Validation Guide](.claude/commands/references/story-scope-validation.md)
```
