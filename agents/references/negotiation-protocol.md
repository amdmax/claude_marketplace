# Negotiation Protocol

## When a Developer Disputes a Test Contract

1. Evaluate the developer's reasoning — is the test contract genuinely wrong?
2. If valid: update the test and re-confirm RED (re-run tests to verify still failing)
3. If disagreement persists after 1 round: escalate to PM

## Escalation Format (to PM)

```
Test contract dispute: [function/file]
Test-architect position: [1 line]
Developer position: [1 line]
Recommendation: [1 line]
```

## Principle

Tests define the contract. Only change a test if the architect's brief itself was wrong or ambiguous — not because the implementation is hard.
