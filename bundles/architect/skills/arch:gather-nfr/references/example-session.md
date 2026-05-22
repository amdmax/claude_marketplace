# Example Session

```
$ /gather-nfr

📋 Collecting Non-Functional Requirements

→ Loading active story: #123 - Implement payment checkout
  Labels: story, feature, payment
  Analyzing context...

→ Performance Requirements (3 questions)

Q1: How many daily active users do you expect for this feature?
  • <100 users
  • 100-1,000 users
  • 1,000-10,000 users [Recommended for payment features]
  • 10,000+ users

Your answer: 1,000-10,000 users

Q2: What is the maximum acceptable response time?
  • <500ms [Recommended for checkout flow]
  • <1 second
  • <2 seconds
  • No specific constraint

Your answer: <500ms

Q3: What concurrent user load should the system handle?
  • 10-100 / 100-1,000 [Recommended] / 1,000+

Your answer: 100-1,000

→ Scalability Requirements (2 questions)
...

→ Security Requirements (3 questions)

Q1: What types of sensitive data will this feature handle?
  [Multi-select]
  ☑ Payment information [Auto-selected based on labels]
  ☑ PII
  ☐ Health information
  ☐ Credentials

Q2: What authentication level is required?
  • Authenticated [Recommended]

Q3: What compliance standards apply?
  ☑ PCI-DSS [Recommended for payment data]
  ☑ GDPR [Recommended for PII]

✓ Non-Functional Requirements Collected

Performance: 1,000-10,000 DAU, <500ms, 100-1,000 concurrent
Security: PII + Payment, Authenticated-only, PCI-DSS + GDPR
[...remaining categories...]

✓ NFRs saved to $AGENT_DOCS_DIR/active-story.yaml

Next steps:
  Run /gather-context to collect technical context
```
