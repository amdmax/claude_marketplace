---
name: create-adr
description: Generate Architecture Decision Records in MADR format with auto-numbering. Analyzes story context, NFRs, and technical context to create comprehensive ADRs. Invokable with /create-adr.
---

# Create Architecture Decision Record

## Overview

This skill generates Architecture Decision Records (ADRs) in MADR (Markdown Any Decision Records) format. It:

1. **Analyzes story context** to determine if ADR is needed
2. **Auto-numbers ADRs** by scanning existing `docs/adr/` directory
3. **Extracts decision drivers** from NFRs and technical context
4. **Identifies options** from context and industry best practices
5. **Generates MADR-format file** with comprehensive decision documentation
6. **Updates active story** with ADR reference

ADRs document **why** architectural decisions were made, helping future developers understand trade-offs and rationale.

## When to Create an ADR

### ✅ Create ADR When Decision Involves:

| Category | Examples |
|----------|----------|
| **New AWS service integration** | Adding S3, DynamoDB, SQS, etc. for the first time |
| **Authentication/authorization changes** | New auth flow, permission model, SSO integration |
| **Database schema changes** | New tables, major schema migrations, indexing strategy |
| **Breaking API changes** | Endpoint deprecation, version upgrades, contract changes |
| **Security-sensitive logic** | Payment processing, PII handling, encryption choices |
| **Technology/library selection** | Choosing React vs Vue, Stripe vs PayPal, etc. |
| **Significant performance trade-offs** | Caching strategy, pre-computation, denormalization |
| **Architecture pattern changes** | Monolith → microservices, sync → async, etc. |

### ❌ Do NOT Create ADR When:

| Scenario | Why Skip |
|----------|----------|
| **Simple bug fixes** | No architectural impact |
| **UI-only changes** | No backend or infrastructure changes |
| **Documentation updates** | No code changes |
| **Following established patterns** | Precedent already set (reference existing ADR) |
| **Small refactorings** | No significant structural changes |
| **Routine maintenance** | Dependency updates, log cleanup, etc. |

### Decision Logic

```javascript
function shouldCreateADR(story, nfrs, context) {
  // Check story labels
  if (story.labels.includes('bug') && !story.labels.includes('security')) {
    return false; // Bug fix, not security-related
  }

  if (story.labels.includes('docs-only')) {
    return false; // Documentation only
  }

  // Check for new technology/service
  const newTech = detectNewTechnology(story.title, story.body, context);
  if (newTech) {
    return true; // New technology integration
  }

  // Check for security/compliance
  if (nfrs.security?.sensitiveData?.length > 0 || nfrs.security?.compliance?.length > 0) {
    return true; // Security-sensitive
  }

  // Check for architectural change
  if (context.relatedADRs.some(adr => adr.status === 'superseded')) {
    return true; // Superseding existing decision
  }

  // Check for multiple implementation approaches
  if (context.preferredApproach && context.preferredApproach !== "No preference") {
    return true; // Explicit choice among alternatives
  }

  // Default: consult user
  return askUser("This story may benefit from an ADR. Create one?");
}
```

## MADR Format

### Template Structure

```markdown
---
status: proposed | accepted | superseded | deprecated | rejected
date: YYYY-MM-DD
decision-makers: [Name(s)]
consulted: [Name(s)] (optional)
informed: [Name(s)] (optional)
---

# ADR-NNNN: [Short Title of Decision]

**Story:** GitHub Issue #XXX
**Date:** YYYY-MM-DD

## Context and Problem Statement

[Describe the context and problem. What is the architectural challenge we're addressing?]

[Include background from story description, business requirements, and technical constraints.]

## Decision Drivers

* [NFR or constraint that influences the decision, e.g., "Performance: 1000 daily users, <2s response time"]
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
* Good, because [positive consequence]
* Bad, because [negative consequence, with mitigation if possible]

### Confirmation

[Optional: How will we know if this decision is successful? Metrics, tests, validation criteria.]

## Pros and Cons of the Options

### [Option 1]

[Brief description of option 1]

* Good, because [argument for]
* Good, because [argument for]
* Neutral, because [neither good nor bad]
* Bad, because [argument against]
* Cost: [AWS cost implications, e.g., "$50/month estimated"]
* Complexity: [Implementation complexity: Low | Medium | High]

### [Option 2]

[Brief description of option 2]

* Good, because [argument for]
* Bad, because [argument against]
* Cost: [cost implications]
* Complexity: [complexity level]

### [Option 3]

[Brief description of option 3]

* Good, because [argument for]
* Bad, because [argument against]
* Cost: [cost implications]
* Complexity: [complexity level]

## Implementation Notes

[Technical details for implementing the chosen option]

[Code patterns, configuration examples, migration steps, testing strategy]

## Links

* [Story Issue #XXX](https://github.com/owner/repo/issues/XXX)
* [Related ADR-YYYY](./YYYY-related-decision.md) (if superseding or related)
* [External Documentation](https://example.com/docs)
* [Technology Homepage](https://example.com)
```

### MADR YAML Frontmatter

**Required fields:**
- `status`: Current decision status
- `date`: Decision date (YYYY-MM-DD)

**Optional fields:**
- `decision-makers`: Who made the decision
- `consulted`: Who was consulted
- `informed`: Who was informed

**Status values:**

| Status | Meaning |
|--------|---------|
| `proposed` | Decision drafted but not yet approved |
| `accepted` | Decision approved and active |
| `superseded` | Replaced by a newer ADR |
| `deprecated` | No longer recommended but not replaced |
| `rejected` | Considered but not chosen |

## Workflow

### Step 1: Verify Prerequisites

```bash
# Check active story exists
STORY_FILE="$CLAUDE_PROJECT_DIR/.claude/active-story.json"
if [ ! -f "$STORY_FILE" ]; then
  echo "❌ No active story found"
  echo "   Expected: $CLAUDE_PROJECT_DIR/.claude/active-story.json"
  exit 1
fi

# Check NFRs and context exist
# Warn if missing but continue
```

### Step 2: Load Story Data

```javascript
const story = JSON.parse(fs.readFileSync('.claude/active-story.json', 'utf-8'));

// Extract data
const { issueNumber, title, body, nfrs, context, labels } = story;
```

### Step 3: Determine if ADR is Needed

**Apply decision logic:**

```javascript
if (!shouldCreateADR(story, nfrs, context)) {
  console.log('ℹ️  ADR not required for this story');
  console.log('   Reason: [Simple bug fix | Following established pattern | UI-only change]');
  console.log('');
  console.log('   Skipping ADR creation.');
  exit(0);
}

console.log('✓ ADR creation recommended');
console.log('  Reason: [New technology | Security-sensitive | Multiple options]');
```

### Step 4: Auto-Number the ADR

**Scan existing ADRs:**

```bash
# Create directory if it doesn't exist
mkdir -p docs/adr

# Find highest ADR number
HIGHEST=$(ls docs/adr/ 2>/dev/null | grep -o "^[0-9]*" | sort -n | tail -1)

# If no ADRs exist, start at 0001
if [ -z "$HIGHEST" ]; then
  NEXT="0001"
else
  # Increment and zero-pad to 4 digits
  NEXT=$(printf "%04d" $((10#$HIGHEST + 1)))
fi

echo "Next ADR number: $NEXT"
```

**Numbering format:**
- Four digits: `0001`, `0002`, ..., `9999`
- Zero-padded for proper sorting
- Sequential across all ADRs

### Step 5: Generate Title Slug

**Extract key technical terms:**

```javascript
function generateTitleSlug(storyTitle, context) {
  // Extract technical terms
  const techs = extractTechTerms(storyTitle, context);
  // Example: ["stripe", "payment", "integration"]

  // Remove stop words
  const stopWords = ['implement', 'add', 'create', 'update', 'fix', 'improve'];
  const filtered = techs.filter(t => !stopWords.includes(t.toLowerCase()));

  // Limit to 5 words max
  const slug = filtered.slice(0, 5).join('-').toLowerCase();

  return slug;
}

// Example: "Implement Payment Checkout with Stripe"
// → "stripe-payment-checkout"
```

**File naming:**
```
docs/adr/{NNNN}-{slug}.md

Example: docs/adr/0012-stripe-payment-integration.md
```

### Step 6: Extract Decision Drivers from NFRs

**Map NFRs to decision drivers:**

```javascript
const decisionDrivers = [];

// Performance
if (nfrs.performance) {
  decisionDrivers.push(
    `Performance: ${nfrs.performance.dailyActiveUsers} daily users, ` +
    `${nfrs.performance.maxResponseTime} max response time, ` +
    `${nfrs.performance.concurrentUsers} concurrent users`
  );
}

// Scalability
if (nfrs.scalability && !nfrs.scalability.skipped) {
  decisionDrivers.push(
    `Scalability: ${nfrs.scalability.growthProjection}, ` +
    `${nfrs.scalability.geographic} distribution`
  );
}

// Security
if (nfrs.security) {
  decisionDrivers.push(
    `Security: ${nfrs.security.sensitiveData.join(', ')} data, ` +
    `${nfrs.security.compliance.join(', ')} compliance required`
  );
}

// Reliability
if (nfrs.reliability && !nfrs.reliability.skipped) {
  decisionDrivers.push(
    `Reliability: ${nfrs.reliability.acceptableDowntime} downtime SLA, ` +
    `${nfrs.reliability.errorRate} error rate tolerance`
  );
}

// Cost
if (nfrs.cost) {
  decisionDrivers.push(
    `Cost: ${nfrs.cost.budget} budget, ` +
    `prefer ${nfrs.cost.preferredServices.join(', ')}`
  );
}

// Technical constraints
if (context.constraints) {
  context.constraints.forEach(c => {
    decisionDrivers.push(`Constraint: ${c}`);
  });
}
```

**Example output:**
```markdown
## Decision Drivers

* Performance: 1000-10000 daily users, <2s max response time, 100-1000 concurrent users
* Security: PII, Payment data, PCI-DSS and GDPR compliance required
* Reliability: 8 hours/year (99.9%) downtime SLA, <1% error rate tolerance
* Cost: Standard budget, prefer Lambda, DynamoDB, S3
* Constraint: AWS Lambda timeout (30s max)
* Constraint: Must integrate with existing Cognito auth
```

### Step 7: Identify Options from Context

**Extract options from preferred approach:**

```javascript
// If user specified preferred approach, that's Option 1
const options = [];

if (context.preferredApproach && context.preferredApproach !== "No preference") {
  options.push({
    name: context.preferredApproach,
    chosen: true
  });
}

// Add alternatives from related ADRs or industry knowledge
// Example: If preferred is "Stripe Checkout", alternatives might be:
// - Stripe Elements
// - PayPal
// - Square
// - Custom payment form

options.push(...generateAlternatives(context.preferredApproach, context.relatedADRs));
```

**Generate alternatives:**

```javascript
function generateAlternatives(preferredApproach, relatedADRs) {
  // Use domain knowledge and related ADRs to suggest alternatives

  // Example: Payment processing
  if (preferredApproach.includes('Stripe')) {
    return [
      { name: 'Stripe Elements (custom UI)', chosen: false },
      { name: 'PayPal Commerce Platform', chosen: false },
      { name: 'Square Payment Form', chosen: false }
    ];
  }

  // Example: Database choice
  if (preferredApproach.includes('DynamoDB')) {
    return [
      { name: 'RDS PostgreSQL', chosen: false },
      { name: 'Aurora Serverless', chosen: false }
    ];
  }

  // Fallback: At least include "Do nothing" or "Alternative approach"
  return [
    { name: 'Alternative approach (specify)', chosen: false },
    { name: 'Do nothing (defer decision)', chosen: false }
  ];
}
```

### Step 8: Generate Pros/Cons for Each Option

**For each option, analyze:**

```javascript
function generateProsConsFor(option, decisionDrivers, context) {
  const proscons = { good: [], neutral: [], bad: [], cost: '', complexity: '' };

  // Example for "Stripe Checkout"
  if (option.name.includes('Stripe Checkout')) {
    proscons.good = [
      'PCI-DSS compliance handled by Stripe',
      'Fast implementation (< 1 day)',
      'Hosted UI reduces frontend complexity',
      'Battle-tested at scale (millions of merchants)'
    ];

    proscons.bad = [
      'Limited UI customization (Stripe branding visible)',
      'Redirects user away from site (potential abandonment)',
      'Vendor lock-in to Stripe ecosystem'
    ];

    proscons.cost = '$0.029 + 2.9% per transaction (standard Stripe pricing)';
    proscons.complexity = 'Low (minimal backend code, no frontend UI)';
  }

  // Consider decision drivers
  decisionDrivers.forEach(driver => {
    if (driver.includes('PCI-DSS')) {
      // Stripe Checkout satisfies PCI-DSS → good
      proscons.good.push('Satisfies PCI-DSS compliance requirement (driver)');
    }
    if (driver.includes('<2s max response time')) {
      // Redirects may impact perceived performance → neutral
      proscons.neutral.push('Redirect may feel slower but payment API is fast (<500ms)');
    }
  });

  return proscons;
}
```

**Format pros/cons:**

```markdown
### Stripe Checkout (Hosted Page)

Stripe's hosted payment page that handles the entire checkout flow on Stripe's domain.

* Good, because PCI-DSS compliance is handled by Stripe
* Good, because fast implementation (< 1 day)
* Good, because hosted UI reduces frontend complexity
* Good, because battle-tested at scale (millions of merchants)
* Good, because satisfies PCI-DSS compliance requirement (driver)
* Neutral, because redirect may feel slower but payment API is fast (<500ms)
* Bad, because limited UI customization (Stripe branding visible)
* Bad, because redirects user away from site (potential abandonment)
* Bad, because vendor lock-in to Stripe ecosystem
* Cost: $0.029 + 2.9% per transaction (standard Stripe pricing)
* Complexity: Low (minimal backend code, no frontend UI)
```

### Step 9: Write Decision Outcome

**Format decision:**

```markdown
## Decision Outcome

Chosen option: "Stripe Checkout (hosted page)", because it satisfies our PCI-DSS compliance requirement with minimal implementation effort, aligns with our standard budget (no upfront costs), and meets performance requirements (<2s) despite the redirect. The trade-off of limited UI customization is acceptable given the security and speed benefits.

### Consequences

* Good, because we can launch payment functionality quickly (estimated 1-2 days vs 1-2 weeks for custom UI)
* Good, because Stripe handles PCI compliance, reducing our security audit scope and ongoing maintenance
* Good, because Stripe's infrastructure reliability (99.99% uptime) exceeds our 99.9% SLA requirement
* Bad, because users are redirected away from our site, which may reduce trust and increase cart abandonment by ~10-15% (industry average)
* Bad, because we have limited control over the UI, making brand consistency challenging

### Confirmation

We will validate this decision by:
* Tracking payment completion rate (target: >85%)
* Monitoring payment latency (target: <2s end-to-end)
* Measuring cart abandonment during redirect (target: <20%)
* Conducting user feedback sessions within first month of launch

If payment completion rate falls below 80% or abandonment exceeds 25%, we will re-evaluate the custom UI option (Stripe Elements).
```

### Step 10: Add Implementation Notes

**Include technical details:**

```markdown
## Implementation Notes

### Backend (Lambda Function)

```typescript
// lambda/payment-checkout/index.ts
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function createCheckoutSession(event) {
  const { priceId, customerId } = JSON.parse(event.body);

  const session = await stripe.checkout.sessions.create({
    customer: customerId,
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    mode: 'payment',
    success_url: `${process.env.APP_URL}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${process.env.APP_URL}/cancel`,
  });

  return {
    statusCode: 200,
    body: JSON.stringify({ sessionId: session.id })
  };
}
```

### Infrastructure (CDK)

```typescript
// infrastructure/lib/payment-stack.ts
const checkoutLambda = new lambda.Function(this, 'CheckoutLambda', {
  runtime: lambda.Runtime.NODEJS_18_X,
  handler: 'index.createCheckoutSession',
  code: lambda.Code.fromAsset('lambda/payment-checkout'),
  environment: {
    STRIPE_SECRET_KEY: ssm.StringParameter.valueForStringParameter(
      this, '/payment/stripe/secret-key'
    ),
    APP_URL: 'https://example.com'
  },
  timeout: Duration.seconds(10)
});
```

### Testing Strategy

1. **Unit tests:** Mock Stripe SDK, test error handling
2. **Integration tests:** Use Stripe test mode with test cards
3. **E2E tests:** Playwright with Stripe checkout flow

### Migration Steps

1. Deploy Lambda function and API Gateway endpoint
2. Store Stripe secret key in SSM Parameter Store
3. Add checkout button to UI pointing to new endpoint
4. Run smoke tests in staging
5. Deploy to production
6. Monitor payment completion rates

### Rollback Plan

If critical issues arise:
1. Remove checkout button from UI (immediate)
2. Redirect users to support page with manual payment instructions
3. Expected downtime: <15 minutes
```

### Step 11: Add Links Section

**Include relevant links:**

```markdown
## Links

* [Story Issue #123](https://github.com/aigensa/vibe-coding-course/issues/123)
* [Related ADR-0005: Lambda@Edge Authentication](./0005-lambda-edge-auth.md) - Payment endpoints use this auth
* [Stripe Checkout Documentation](https://stripe.com/docs/payments/checkout)
* [PCI-DSS Compliance Guide](https://stripe.com/docs/security/guide)
* [Payment Testing Guide (internal)](../DEVELOPMENT_WORKFLOW.md#payment-testing)
```

**Link to related ADRs:**

```javascript
// From context.relatedADRs
context.relatedADRs.forEach(adr => {
  links.push(`[Related ${adr.path}](./${adr.fileName}) - ${adr.relevance}`);
});
```

### Step 12: Write ADR File

**Combine all sections:**

```javascript
const adrContent = `---
status: proposed
date: ${new Date().toISOString().split('T')[0]}
decision-makers: [User Name]
---

# ADR-${adrNumber}: ${titleSlug}

**Story:** GitHub Issue #${issueNumber}
**Date:** ${new Date().toISOString().split('T')[0]}

${contextSection}

${decisionDriversSection}

${consideredOptionsSection}

${decisionOutcomeSection}

${prosAndConsSection}

${implementationNotesSection}

${linksSection}
`;

// Write file
fs.writeFileSync(`docs/adr/${adrNumber}-${titleSlug}.md`, adrContent);
```

### Step 13: Update Active Story with ADR Reference

```javascript
story.adr = {
  number: adrNumber,
  filePath: `docs/adr/${adrNumber}-${titleSlug}.md`,
  title: titleSlug,
  status: 'proposed',
  createdAt: new Date().toISOString()
};

fs.writeFileSync('.claude/active-story.json', JSON.stringify(story, null, 2));
```

### Step 14: Report Success

```
✓ Architecture Decision Record Created

ADR-0012: stripe-payment-integration
Location: docs/adr/0012-stripe-payment-integration.md

Decision: Stripe Checkout (hosted page)

Rationale:
  • Satisfies PCI-DSS compliance with minimal effort
  • Fast implementation (1-2 days)
  • Meets performance and reliability requirements

Decision Drivers:
  • Security: PCI-DSS compliance required
  • Performance: <2s response time, 1000-10000 daily users
  • Cost: Standard budget

Considered Options:
  1. Stripe Checkout (hosted page) [CHOSEN]
  2. Stripe Elements (custom UI)
  3. PayPal Commerce Platform

Next Steps:
  1. Review ADR for accuracy and completeness
  2. Update status to "accepted" when approved
  3. Reference ADR in implementation PR
  4. Run /dev-story to begin implementation

✓ ADR reference saved to .claude/active-story.json
```

## Error Handling

### No Active Story

```
❌ No active story found

Please run /fetch-story first to select a story.
```

### NFRs or Context Missing

```
⚠️  NFRs or context not collected

Creating ADR without complete context may result in incomplete decision documentation.

Options:
  [1] Continue anyway (use available data)
  [2] Cancel (run /gather-nfr and /gather-context first)
  [3] Run /play-story (full workflow)

Choice:
```

### ADR Directory Creation Failed

```
❌ Failed to create docs/adr/ directory

Error: [error message]

Please check file permissions and try again.
```

### ADR File Write Failed

```
❌ Failed to write ADR file

Error: [error message]

Possible causes:
- File permissions issue
- Disk full
- File already exists (check docs/adr/)

Please resolve and try again.
```

### ADR Not Needed

```
ℹ️  ADR not required for this story

Reason: Simple bug fix with no architectural impact

Skipping ADR creation. The story can proceed to implementation without an ADR.

Next steps:
  Run /dev-story to begin implementation
```

## Best Practices

### When to Create ADRs

**✅ Create ADR when:**
- Introducing new technology or AWS service
- Making security-sensitive decisions
- Choosing between multiple valid approaches
- Changing established patterns
- Making decisions with long-term impact

**❌ Skip ADR when:**
- Following existing patterns (reference existing ADR)
- Making obvious/trivial decisions
- Implementing bug fixes
- Making UI-only changes

### ADR Quality

**✅ Good ADRs:**
- Clear problem statement
- Concrete options with pros/cons
- Explicit trade-offs
- Measurable confirmation criteria
- Implementation guidance

**❌ Bad ADRs:**
- Vague problem description
- Only one option considered
- No downsides mentioned
- No validation plan
- Missing implementation details

### Updating ADRs

**When decision changes:**
1. Update status to `superseded`
2. Create new ADR with link to old one
3. Explain why decision changed

**When decision fails:**
1. Update status to `rejected` or `deprecated`
2. Document lessons learned
3. Create new ADR with corrected approach

## Integration with Other Skills

### Called by /play-story

```
/play-story
  ↓
1. /fetch-story
2. /gather-nfr
3. /gather-context
4. /create-adr (this skill, if needed)
5. Summary and next steps
```

### Output Used by Implementation

**During implementation:**
- Reference ADR in PR description
- Follow implementation notes
- Validate against confirmation criteria

**After implementation:**
- Update ADR status to `accepted`
- Add actual metrics/results
- Link to implementation PR

## Summary

The `/create-adr` skill generates comprehensive ADRs by:

✅ **Auto-numbering** - Sequential ADR numbering with zero-padding
✅ **Context-aware** - Uses NFRs and context to inform decisions
✅ **MADR format** - Industry-standard format for ADRs
✅ **Comprehensive** - Includes options, pros/cons, implementation notes
✅ **Linked** - References story, related ADRs, and documentation

Use `/create-adr` to document architectural decisions and preserve decision rationale!
