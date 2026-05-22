# Examples

## Example 1: Logic Error (Token Validation)

```bash
/debug 123

# Hypotheses: h1 (logic_error, high), h2 (missing_validation, medium), h3 (race_condition, low)

# Research h1 (autonomous):
# - Grep validateToken → read src/auth/token.ts
# - Find: if (exp > now) return true (line 45)
# - Check RFC 7519: requires >=
# → h1 CONFIRMED

# Fix proposal:
🔧 Root Cause: Token expiration uses > instead of >=
Location: src/auth/token.ts:45
Fix: if (exp > now) → if (exp >= now)
Approve? yes

# Implement fix (Edit tool)

# Generate tests (mandatory):
# src/auth/__tests__/token.test.ts
# - Reproduction: reject at exact expiration
# - Edge: 1ms before/after
# - Regression: valid future tokens work

# Validate (fail-before/pass-after) ✅

# Commit fix + tests
git add src/auth/token.ts && /gh:commit
# → AIGCODE-123: Fix token expiration validation off-by-one error
git add src/auth/__tests__/token.test.ts && /gh:commit
# → AIGCODE-123a: Add regression tests for token expiration bug

/mr   # PR with investigation summary
# → hypothesis-tracker.py archive
```

## Example 2: Missing Validation

```bash
/debug 456

# Hypotheses: h1 (missing_validation, high), h2 (logic_error, medium)

# Research h1:
# - Read src/validators/email.ts
# - Find: regex test without null check
# → h1 CONFIRMED

# Fix: add if (!email) return false;
# Tests: null input, empty string, valid email
# Validate, commit, PR, archive
```
