---
name: code-review
description: Comprehensive code review orchestrator - runs deterministic checks before LLM reviews
---

# Code Review Orchestrator

## Overview

Comprehensive code review workflow that **runs non-probabilistic checks first** (type-check, linters, tests) before expensive LLM-based reviews. This approach saves tokens and ensures basic quality gates pass before deep analysis.

**Workflow:**

1. **Phase 1: Deterministic Checks** (fast, no LLM tokens)
   - TypeScript type-check
   - ESLint validation
   - Stylelint validation
   - Unit tests
2. **Phase 2: LLM-Based Reviews** (only after Phase 1 passes)
   - Security review (OWASP Top 10)
   - Performance review (algorithmic complexity)
   - Overall quality review (maintainability)

## When to Use

- Before committing code
- Before creating a pull request
- After completing a feature
- When you want comprehensive quality validation

## Usage

```bash
/code-review
```

## Workflow

### Phase 1: Non-Probabilistic Checks

Run these checks sequentially. Stop on first failure to fail fast.

#### 1. TypeScript Type Check

```bash
npm run type-check
```

**What it checks:**

- Type errors
- Missing type declarations
- Type mismatches
- TypeScript configuration compliance

**Exit on failure:** ✅ Block if errors found

---

#### 2. ESLint

```bash
npm run lint
```

**What it checks:**

- Code style violations
- Common bug patterns
- Import/export issues
- JSDoc problems
- Security issues (via eslint-plugin-security)

**Exit on failure:** ✅ Block if errors found (warnings allowed)

---

#### 3. Stylelint

```bash
npm run lint:css
```

**What it checks:**

- CSS style violations
- Invalid CSS properties
- CSS best practices

**Exit on failure:** ✅ Block if errors found

---

#### 4. Unit Tests

```bash
npm test
```

**What it checks:**

- Test failures
- Test coverage
- Regression detection

**Exit on failure:** ✅ Block if tests fail

---

#### 5. CDK Infrastructure Validation (if infrastructure/ files changed)

```bash
/cdk-validate
```

**What it checks:**

- cdk-nag best practices (AWS Solutions rules)
- cfn-lint CloudFormation syntax
- IAM least privilege violations
- Security misconfigurations

**Exit on failure:** ✅ Block if errors found (warnings allowed)

**Conditional:** Only runs if staged changes include `infrastructure/` files

---

### Phase 1 Summary

After running all Phase 1 checks, provide:

```
✅ Phase 1: Deterministic Checks PASSED
-------------------------------------------
✅ TypeScript: No type errors
✅ ESLint: No errors (X warnings)
✅ Stylelint: No errors
✅ Tests: All tests passed (X tests, Y ms)
✅ CDK Infrastructure: Validation passed (if applicable)

Proceeding to Phase 2: LLM-Based Reviews...
```

**OR if failures:**

```
❌ Phase 1: Deterministic Checks FAILED
-------------------------------------------
✅ TypeScript: No type errors
❌ ESLint: 3 errors found
✅ Stylelint: No errors
❌ Tests: 2 tests failed
❌ CDK Infrastructure: Validation failed (if applicable)

⚠️ Fix Phase 1 issues before running LLM-based reviews.

Phase 1 must pass to proceed to Phase 2 (saves LLM tokens).
```

**IMPORTANT:** If Phase 1 fails, STOP here. Do NOT proceed to Phase 2. Ask user to fix issues and re-run.

---

### Phase 2: LLM-Based Reviews

**Only run if Phase 1 passes.**

These reviews use LLM tokens, so we defer them until basic quality gates pass.

#### 1. Security Review

Run the `security-review` skill to check for:

- OWASP Top 10 2025 vulnerabilities
- OWASP API Security Top 10 2023
- Injection attacks (SQL, XSS, Command)
- Authentication/authorization issues
- Cryptographic failures
- Supply chain vulnerabilities

**Output format:**

```
🔴 CRITICAL | 🟠 MAJOR | 🟡 MINOR

File: path/to/file.ts
Line(s): 42-45
Problem: [Brief explanation]
Fix: [Specific code example]
```

**Token estimate:** ~500-2000 tokens depending on file size

---

#### 2. Performance Review

Run the `performance-review` skill to check for:

- O(n²) algorithmic complexity
- N+1 query problems
- Memory leaks
- Unnecessary re-renders
- Bundle size issues

**Output format:**

```
🔴 CRITICAL | 🟠 MAJOR | 🟡 MINOR

File: path/to/file.ts
Line(s): 42-45
Problem: [Performance issue with impact]
Fix: [Optimized code with expected improvement]
```

**Token estimate:** ~500-2000 tokens depending on file size

---

#### 3. Overall Quality Review

Run the `overall-review` skill to check for:

- Logic bugs
- Null/undefined handling
- Code maintainability
- Test coverage
- TypeScript best practices

**Output format:**

```
🔴 CRITICAL | 🟠 MAJOR | 🟡 MINOR

File: path/to/file.ts
Line(s): 42-45
Problem: [Issue description]
Fix: [Refactored code example]
```

**Token estimate:** ~500-2000 tokens depending on file size

---

### Phase 2 Summary

After running all Phase 2 reviews, provide:

```
✅ Phase 2: LLM-Based Reviews COMPLETE
-------------------------------------------
Security Review:
  - 🔴 CRITICAL: 0
  - 🟠 MAJOR: 2
  - 🟡 MINOR: 3

Performance Review:
  - 🔴 CRITICAL: 0
  - 🟠 MAJOR: 1
  - 🟡 MINOR: 2

Overall Quality Review:
  - 🔴 CRITICAL: 0
  - 🟠 MAJOR: 3
  - 🟡 MINOR: 5

Total Issues: 16 (0 critical, 6 major, 10 minor)
Token Usage: ~2500 tokens

⚠️ Fix CRITICAL and MAJOR issues before committing.
```

---

## Configuration

Create `.claude/skills/code-review/config.yaml` to customize behavior:

```yaml
# Phase 1: Deterministic Checks
phase1:
  type_check:
    enabled: true
    command: "npm run type-check"
    block_on_failure: true

  eslint:
    enabled: true
    command: "npm run lint"
    block_on_failure: true
    allow_warnings: true

  stylelint:
    enabled: true
    command: "npm run lint:css"
    block_on_failure: true

  tests:
    enabled: true
    command: "npm test"
    block_on_failure: true

# Phase 2: LLM-Based Reviews
phase2:
  security_review:
    enabled: true
    skip_on_phase1_failure: true # Skip if Phase 1 fails

  performance_review:
    enabled: true
    skip_on_phase1_failure: true

  overall_review:
    enabled: true
    skip_on_phase1_failure: true

# Reporting
reporting:
  verbose: false # Set true for detailed output
  save_report: true # Save to .claude/reviews/
  report_format: "markdown" # markdown or json
```

---

## Examples

### Example 1: All Checks Pass

```bash
$ /code-review

Phase 1: Deterministic Checks
==============================
✅ TypeScript type-check... PASSED (0 errors)
✅ ESLint... PASSED (0 errors, 2 warnings)
✅ Stylelint... PASSED (0 errors)
✅ Tests... PASSED (42 tests, 1.2s)

Phase 2: LLM-Based Reviews
===========================
Running security review...
  ✅ No critical or major issues found
  🟡 3 minor recommendations

Running performance review...
  ✅ No critical or major issues found
  🟡 2 minor optimizations suggested

Running overall quality review...
  🟠 2 major maintainability issues
  🟡 5 minor style improvements

Final Summary
=============
Total Issues: 12 (0 critical, 2 major, 10 minor)
All deterministic checks passed ✅
Ready to commit after addressing major issues.
```

---

### Example 2: Phase 1 Failure (No Phase 2)

```bash
$ /code-review

Phase 1: Deterministic Checks
==============================
✅ TypeScript type-check... PASSED
❌ ESLint... FAILED
  - src/api/users.ts:42: Unexpected 'any' type
  - src/utils/helper.ts:15: Missing return type
  ✅ Stylelint... SKIPPED (Phase 1 failed)
  ✅ Tests... SKIPPED (Phase 1 failed)

Phase 1 Failed
==============
⚠️ Fix ESLint errors before proceeding.

Phase 2 reviews skipped to save LLM tokens.
Run /code-review again after fixes.
```

---

## Integration with Git Hooks

Add to `.claude/skills/hooks/hooks/pre-commit/`:

```bash
#!/bin/bash
# Run code review before commit

echo "Running code review..."
claude-code /code-review

if [ $? -ne 0 ]; then
  echo "❌ Code review failed. Commit blocked."
  exit 1
fi

echo "✅ Code review passed. Proceeding with commit."
exit 0
```

---

## Token Optimization Strategy

**Problem:** Running LLM-based reviews on failing code wastes tokens.

**Solution:** Two-phase approach.

**Example:**

- Phase 1 finds type error → STOP (0 LLM tokens used)
- Fix type error → Re-run
- Phase 1 passes → Phase 2 runs (~2500 tokens)

**Savings:** If Phase 1 catches 50% of issues, you save ~1250 tokens per failed review.

---

## Troubleshooting

### "npm run type-check not found"

Add to `package.json`:

```json
"scripts": {
  "type-check": "tsc --noEmit"
}
```

### "npm run lint not found"

Add to `package.json`:

```json
"scripts": {
  "lint": "eslint . --cache"
}
```

### Phase 1 passes but Phase 2 skipped

Check config.yaml - ensure `skip_on_phase1_failure: false` for Phase 2 reviews you want to run.

### Too many false positives

Adjust ESLint/Stylelint configs to reduce noise:

- Disable specific rules in `.eslintrc`
- Adjust severity (error → warn)
- Use inline disable comments for exceptions

---

## References

- **Phase 1 Tools:**
  - TypeScript: https://www.typescriptlang.org/docs/handbook/compiler-options.html
  - ESLint: https://eslint.org/docs/rules/
  - Stylelint: https://stylelint.io/user-guide/rules/

- **Phase 2 Skills:**
  - `/security-review` - OWASP Top 10 scanner
  - `/performance-review` - Algorithmic complexity analyzer
  - `/overall-review` - Code quality reviewer

---

## Notes

- **Always run Phase 1 first** - catches 60-80% of issues without LLM tokens
- **Phase 2 is optional** - can skip if time/token-constrained
- **Incremental approach** - fix Phase 1 → re-run → Phase 2
- **Pre-commit integration** - automate with git hooks
- **CI/CD friendly** - exit codes indicate pass/fail
