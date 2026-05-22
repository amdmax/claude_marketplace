# Fix Implementation (Phase 4)

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

- **"yes" / "approved" / "go ahead"** → Proceed with fix implementation
- **"no" / "reject"** → Ask for clarification, generate alternative approaches, re-evaluate hypothesis
- **"revise" / "modify"** → Ask what changes are needed, adjust, re-present

## Implementing the Fix

After approval:
1. Make code changes using Edit tool — keep changes minimal
2. Preserve existing functionality
3. Record fix:

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

Records fix in state and transitions phase to `test_generation`.
