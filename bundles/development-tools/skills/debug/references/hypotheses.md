# Hypothesis Generation

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
**Indicators:** Wrong operators, off-by-one errors, incorrect boolean logic, flawed calculations.
**Example:** "Token expiration check uses > instead of >="

### 2. missing_validation
**Indicators:** Null/undefined errors, missing input checks, unhandled edge cases, no error handling.
**Example:** "Missing null check for token expiration field"

### 3. race_condition
**Indicators:** Timing-dependent failures, concurrent access, async/await problems, intermittent bugs.
**Example:** "Session Map accessed without synchronization"

### 4. configuration
**Indicators:** Environment-specific failures, missing env variables, wrong defaults, config not loaded.
**Example:** "TOKEN_EXPIRY not set in production environment"

### 5. dependency
**Indicators:** Recent dependency updates, deprecated API, version mismatches, breaking changes.
**Example:** "jwt-decode 4.0 changed decode() signature"

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
hypothesis-tracker.py add-hypothesis \
  "Token expiration check uses > instead of >=" \
  "logic_error" \
  "high"

hypothesis-tracker.py add-hypothesis \
  "Missing null check for exp field" \
  "missing_validation" \
  "medium"

hypothesis-tracker.py add-hypothesis \
  "Race condition during token refresh" \
  "race_condition" \
  "low"
```

## Confidence Ranking

**High:** Strong evidence from error messages, matches known patterns, clear code location.
**Medium:** Plausible based on symptoms, similar to past bugs, indirect evidence.
**Low:** Speculative, would explain symptoms but less likely, fallback hypothesis.
