# Research Loop (Phase 3)

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

See `@references/research-strategies.md` for strategy details per hypothesis type.

## Research Strategy (logic_error example)

```bash
# 1. Get next hypothesis
NEXT=$(hypothesis-tracker.py get-next-hypothesis)
H_ID=$(echo $NEXT | jq -r '.id')

# 2. Mark as investigating
hypothesis-tracker.py update-status "$H_ID" "investigating"

# 3. Execute research (grep, read, git blame, compare)

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

Record **every significant finding** with file path, line number, and observation.

```bash
hypothesis-tracker.py add-evidence \
  <h-id> \
  "<file-path>" \
  <line-number> \
  "<note>"
```

**Good evidence notes:**
- ✅ "Found comparison: if (exp > now). RFC 7519 requires >= for expiration"
- ✅ "No null check before accessing token.exp (line 42)"
- ✅ "git blame shows line changed 3 days ago by commit abc123"

**Bad evidence notes:**
- ❌ "Looks wrong" / "Check this file" / "Might be the issue"

## Hypothesis Outcomes

### CONFIRMED
**Criteria:** Strong evidence, can explain bug mechanism, can design a fix, 2+ supporting pieces.
```bash
hypothesis-tracker.py mark-confirmed <h-id>
# Auto-rejects all other hypotheses → transitions to "fix_implementation"
```

### REJECTED
**Criteria:** Evidence contradicts hypothesis, code is correct, root cause is elsewhere.
```bash
hypothesis-tracker.py update-status <h-id> "rejected"
# Move to next hypothesis
```

### NEEDS_INFO
**Criteria:** Insufficient information, requires user input, need to run code/tests.
```bash
hypothesis-tracker.py update-status <h-id> "needs_info"
# Generate sub-hypotheses OR ask user specific questions
```

## Research Depth & Max Iterations

**Depth** (`@config.yaml` → `research.depth`):
- `"thorough"` (default): multiple strategies per hypothesis, read related files, check git history, compare similar code (20-30 min per hypothesis)

**Max Iterations** (`@config.yaml` → `research.max_rounds`, default: 3):
- If all hypotheses rejected in a round → generate new ones from findings
- After 3 rounds with no confirmation → ask user for guidance
