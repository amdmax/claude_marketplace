# MADR Template

```markdown
---
status: "{proposed | rejected | accepted | deprecated | superseded by ADR-0123}"
date: YYYY-MM-DD
decision-makers: [list of names]
consulted: [list of names]
informed: [list of names]
---

# ADR-NNNN: [Short Title of Decision]

## Context and Problem Statement

[Describe the context and problem. What is the architectural challenge we're addressing?]

[Include background from story description, business requirements, and technical constraints.]

## Decision Drivers

* [NFR or constraint, e.g., "Performance: 1000 daily users, <2s response time"]
* [NFR or constraint, e.g., "Security: PCI-DSS compliance required"]
* [NFR or constraint, e.g., "Cost: Standard budget, prefer serverless"]
* [Technical constraint, e.g., "Must integrate with existing Cognito auth"]

## Considered Options

* [Option 1: Short name]
* [Option 2: Short name]
* [Option 3: Short name]

## Decision Outcome

Chosen option: "[Option 1]", because [justification considering decision drivers].

### Consequences

* Good, because [positive consequence]
* Bad, because [negative consequence, with mitigation if possible]

### Confirmation

[How will we know if this decision is successful? Metrics, tests, validation criteria.]

## Pros and Cons of the Options

### [Option 1]

[Brief description]

* Good, because [argument for]
* Neutral, because [neither good nor bad]
* Bad, because [argument against]
* Cost: [e.g., "$50/month estimated"]
* Complexity: [Low | Medium | High]

### [Option 2]

[Brief description]

* Good, because [argument for]
* Bad, because [argument against]
* Cost: [cost implications]
* Complexity: [complexity level]

## More Information

* [Story Issue #XXX](https://github.com/owner/repo/issues/XXX)
* [Related ADR-YYYY](./YYYY-related-decision.md)
* [External Documentation](https://example.com/docs)

### Implementation Notes

[Technical details, code patterns, migration steps, rollback plan]
```

## Status Values

| Status | Meaning |
|--------|---------|
| `proposed` | Drafted, not yet approved |
| `accepted` | Approved and active |
| `superseded` | Replaced by a newer ADR |
| `deprecated` | No longer recommended |
| `rejected` | Considered but not chosen |

## YAML Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `status` | ✅ | Current decision status |
| `date` | ✅ | Decision date (YYYY-MM-DD) |
| `decision-makers` | optional | Who made the decision |
| `consulted` | optional | Who was consulted |
| `informed` | optional | Who was informed |
