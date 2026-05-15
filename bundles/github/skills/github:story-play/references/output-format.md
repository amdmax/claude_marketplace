# Story Ready Output Format

```
═══════════════════════════════════════════════════════════════
  Story Ready for Implementation
═══════════════════════════════════════════════════════════════

Story: #123 - Implement payment checkout
Priority: P0
Size: M (estimated 4-6 hours)
URL: https://github.com/{{REPO_SLUG}}/issues/123

───────────────────────────────────────────────────────────────
Non-Functional Requirements
───────────────────────────────────────────────────────────────

Performance:
  • 1,000-10,000 daily active users
  • <2s maximum response time
  • 100-1,000 concurrent users

Security:
  • PII + Payment data
  • Authenticated-only access
  • PCI-DSS + GDPR compliance

Reliability:
  • 8 hours/year (99.9%) acceptable downtime
  • <1% error rate tolerance

Cost:
  • Standard/balanced budget
  • Preferred services: Lambda, DynamoDB, S3

───────────────────────────────────────────────────────────────
Technical Context
───────────────────────────────────────────────────────────────

Documentation:
  • docs/DEVELOPMENT_WORKFLOW.md - Payment testing requirements
  • docs/API_GUIDELINES.md - Error handling patterns

Related Code:
  • lambda/payment-handler/index.ts - Stripe integration
  • infrastructure/payment-stack.ts - CDK stack

Existing ADRs:
  • ADR-0001: Stripe payment processor (accepted)
  • ADR-0005: Lambda@Edge auth (accepted)

Dependencies:
  • Authentication system (Cognito)
  • User profile service

Constraints:
  • AWS Lambda timeout (30s max)

───────────────────────────────────────────────────────────────
Architecture Decision Record
───────────────────────────────────────────────────────────────

ADR-0012: stripe-payment-integration
Status: Proposed
Location: $ADR_DIR/0012-stripe-payment-integration.md

Decision: Stripe Checkout (hosted page)

───────────────────────────────────────────────────────────────
Next Steps
───────────────────────────────────────────────────────────────

1. Review ADR and update status to "accepted" if approved
2. Create feature branch: git checkout -b feature/payment-checkout-[timestamp]
3. Implement according to ADR implementation notes
4. Reference story #123 and ADR-0012 in commits
5. Create PR when ready: /github:pull-request

Story data: .agile-dev-team/active-story.yaml
ADR: $ADR_DIR/0012-stripe-payment-integration.md

═══════════════════════════════════════════════════════════════
```
