---
name: fitness-function-architect
description: Define testable fitness functions from business priorities and NFRs. Use when defining non-functional requirements, SLAs, SLOs, quality metrics, performance targets, or when asked "how do we ensure quality" or "what are the acceptance criteria". Automatically engaged during /feature command Phase 3.5.
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Fitness Function Architect

## Purpose

Transform business priorities into testable fitness functions that measure a system's alignment to architectural goals. Fitness functions are automated tests that provide continuous feedback for architectural conformance during development.

**Core Principle**: "Measure alignment to architectural goals through automated tests"

## When to Use

This skill is automatically engaged when:
- Defining non-functional requirements (NFRs)
- Setting SLAs, SLOs, or quality metrics
- Planning system architecture
- Setting up CI/CD quality gates
- During `/feature` command (Phase 3.5)

## Stakeholder Interview

Conduct this 8-question interview to understand business context:

### 1. Business Type
"What type of business or system is this?"
- E-commerce, Fintech, Healthcare, B2B SaaS, B2C SaaS, Consulting, Media, Government, Education, Other

### 2. User Base
"Who are your primary users?"
- General consumers (B2C), Enterprise customers (B2B), Internal employees, Partners, Mixed

### 3. Risk Profile
"What's your biggest concern?"
- Security breaches, System downtime, Slow performance, Compliance violations, High costs, Scalability, Technical debt

### 4. Compliance Requirements
"Which compliance standards apply?"
- HIPAA, SOC 2, GDPR, PCI-DSS, WCAG 2.0 AA, FedRAMP, ISO 27001, None

### 5. Critical User Journeys
"What are the top 3 workflows that MUST work flawlessly?"
- Example: "Login → Dashboard → Submit Form"

### 6. Performance Expectations
"What are your performance targets?"
- API response time (e.g., p99 < 100ms)
- Page load time (e.g., p75 < 2s)
- TTFB, concurrent users, throughput

### 7. Current Pain Points
"What needs improvement?"
- Slow performance, Bugs/errors, Security vulnerabilities, Poor accessibility, Hard to maintain, High costs, Lack of monitoring, Nothing (new system)

### 8. Testing Budget
"What's your testing preference?"
- Fully automated, Mostly automated, Balanced, Mostly manual, Cost-conscious

## Priority Matrix Synthesis

After gathering responses, generate priority order:

**Example: Fintech (consumer-facing, regulated)**
1. Security & Compliance (CRITICAL - regulatory)
2. Reliability (HIGH - financial transactions)
3. Performance (HIGH - user experience)
4. Accessibility (MEDIUM - consumer-facing)
5. Cost Optimization (MEDIUM)

**Validation**: Present to stakeholder and ask: "Does this priority order align with your goals?"

## NFR → Fitness Function Mapping

For each high-priority NFR, define:

1. **Measurement Type**: What we measure (latency, clicks, error rate)
2. **Threshold**: Quantitative target (e.g., p99 < 100ms, ≤5 clicks)
3. **Test Type**: How we measure (load test, E2E, security scan, alarm)
4. **Test Framework**: Tool to use (k6, Playwright, npm audit, Pa11y-CI, CloudWatch)
5. **Automation Level**: Automated vs manual
6. **CI/CD Integration**: Blocking vs non-blocking gate

**For complete mapping templates**, see [nfr-to-fitness-mapping.md](nfr-to-fitness-mapping.md).

**For business type priority patterns**, see [business-priority-templates.md](business-priority-templates.md).

## Fitness Function Definition Format

Create YAML definitions in `.claude/fitness-functions/fitness-functions/{category}/`:

```yaml
fitness_function:
  id: "perf-001"
  name: "contact_form_latency_p99"
  category: "performance"
  nfr_description: "Contact form p99 latency ≤ 100ms"

  measurement:
    type: "latency"
    source: "CloudWatch + k6"
    metric: "Lambda.Duration"
    aggregation: "p99"

  threshold:
    value: 100
    unit: "milliseconds"
    operator: "less_than_or_equal"
    percentile: 99

  test_implementation:
    automated:
      - type: "load_test"
        framework: "k6"
        file: "tests/performance/contact-form-load.js"
      - type: "cloudwatch_alarm"
        file: "infrastructure/lib/aigensa-stack.ts"
    manual:
      - file: "tests/manual/performance-verification.md"

  ci_cd_gate:
    stage: "pre-merge"
    blocking: true

  remediation:
    guidance: |
      If this fails:
      1. Profile with X-Ray
      2. Check for N+1 queries, cold starts
      3. Consider caching, async optimization
      4. Increase Lambda memory
```

## Test Generation by NFR Category

### Performance (Latency, Throughput)
- **Framework**: k6 (load testing) + CloudWatch alarms
- **Generated**: `tests/performance/{service}-load.js`
- **Infrastructure**: Add alarm to `infrastructure/lib/*-stack.ts`
- **CI/CD**: `.github/workflows/performance-test.yml`
- **Example**: See [examples/performance-latency-example.md](examples/performance-latency-example.md)

### User Experience (Clicks, Task Completion)
- **Framework**: Playwright (E2E testing)
- **Generated**: `tests/e2e/{journey}.spec.ts`
- **Manual**: `tests/manual/{journey}-procedure.md`
- **CI/CD**: `.github/workflows/e2e-test.yml`
- **Example**: See [examples/ux-clicks-example.md](examples/ux-clicks-example.md)

### Security (OWASP, Vulnerabilities)
- **Framework**: npm audit + existing code review
- **Reference**: `.github/code-review/prompts/01-security-review.md` (already exists!)
- **CI/CD**: `.github/workflows/claude-code-review.yml` (already exists!)
- **Example**: See [examples/security-compliance-example.md](examples/security-compliance-example.md)

### Accessibility (WCAG 2.0)
- **Framework**: Pa11y-CI (already implemented!)
- **Reference**: `.pa11yci.json`
- **CI/CD**: `.github/workflows/accessibility-check.yml` (already exists!)
- **Example**: See [examples/accessibility-wcag-example.md](examples/accessibility-wcag-example.md)

## Workflow Integration

This skill integrates with `/feature` command at Phase 3.5:

```
Phase 1: Requirements Gathering
Phase 2: Technical Analysis
Phase 3: Implementation Planning
Phase 3.5: NFR Definition & Fitness Functions ← THIS SKILL
Phase 4: PRD Creation
Phase 5: Branch Setup
Phase 6: Development Guidance
```

**Steps**:
1. Prompt: "Would you like to define fitness functions? (Recommended for production features)"
2. If yes, run stakeholder interview
3. Generate business priority matrix
4. Define NFRs with thresholds
5. Create fitness function definitions
6. Generate test scaffolding
7. Document in PRD's "Non-Functional Requirements" section

## Output Deliverables

After interview and synthesis, generate:

1. **Business Context**: `.claude/fitness-functions/business-context.yml`
2. **NFR Definitions**: `.claude/fitness-functions/nfr-definitions.yml`
3. **Fitness Functions**: `.claude/fitness-functions/fitness-functions/{category}/{function}.yml`
4. **Test Scaffolding**: `tests/{framework}/{test-name}.*`
5. **Infrastructure Changes**: Modify CDK stacks with CloudWatch alarms
6. **CI/CD Workflows**: `.github/workflows/{test-type}.yml`
7. **Manual Procedures**: `tests/manual/{procedure}.md`
8. **PRD Section**: Include in feature PRD document

## Example Workflow

**Scenario**: Building contact form with email delivery

**Stakeholder Responses**:
- Business: B2B SaaS
- Users: Enterprise customers
- Risk: System downtime
- Compliance: SOC 2
- Journey: "Homepage → Contact → Submit → Confirmation"
- Performance: p99 < 100ms
- Pain Point: Slow API responses
- Testing: Fully automated

**Generated Priority**:
1. Reliability (HIGH)
2. Performance (HIGH)
3. Security & Compliance (MEDIUM)

**Fitness Functions Created**:
- `perf-001`: Contact form latency p99 ≤ 100ms (k6 + CloudWatch)
- `rel-001`: Email delivery success rate ≥ 99% (CloudWatch alarm)
- `ux-001`: Contact journey ≤ 5 clicks for 95% (Playwright)

**Tests Generated**:
- `tests/performance/contact-form-load.js` (k6 load test)
- `tests/e2e/contact-form-journey.spec.ts` (Playwright E2E)
- Infrastructure: P99 latency alarm in CDK

**CI/CD**:
- Performance test runs on PR (blocking if p99 > 100ms)
- E2E test runs on PR (non-blocking, report only)
- CloudWatch alarm monitors production

## Best Practices

1. **Start with Business Context** - Understand business before defining metrics
2. **Prioritize Ruthlessly** - Focus on top 3-5 NFRs
3. **Use Quantitative Thresholds** - "p99 < 100ms" beats "fast enough"
4. **Automate Critical Paths** - Block PRs for critical fitness functions
5. **Report Non-Critical** - Non-blocking gates for lower-priority NFRs
6. **Document Manual Procedures** - Some fitness functions need human judgment
7. **Iterate** - Start with essential fitness functions, expand over time
8. **Monitor Production** - CloudWatch alarms for runtime fitness functions
9. **Review Quarterly** - Business priorities change, update fitness functions
10. **Balance Rigor with Velocity** - Don't block PRs unnecessarily

## Anti-Patterns to Avoid

- ❌ Defining NFRs without business context
- ❌ Creating fitness functions for every possible metric
- ❌ Blocking PRs for non-critical fitness functions
- ❌ Setting unrealistic thresholds that always fail
- ❌ Ignoring manual testing for subjective measures
- ❌ "One size fits all" approach (fintech ≠ blog)
- ❌ Forgetting remediation steps for failures
- ❌ Over-automating (some things need human judgment)

## Reference Documentation

- [business-priority-templates.md](business-priority-templates.md) - Pre-defined priority matrices by business type
- [nfr-to-fitness-mapping.md](nfr-to-fitness-mapping.md) - Complete NFR → test framework mappings
- [examples/performance-latency-example.md](examples/performance-latency-example.md) - Full example: latency fitness function
- [examples/ux-clicks-example.md](examples/ux-clicks-example.md) - Full example: UX journey fitness function
- [examples/security-compliance-example.md](examples/security-compliance-example.md) - Reference to existing security reviews
- [examples/accessibility-wcag-example.md](examples/accessibility-wcag-example.md) - Reference to existing Pa11y-CI setup
