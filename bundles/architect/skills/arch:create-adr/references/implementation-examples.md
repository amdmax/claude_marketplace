# Implementation Examples

## Decision Logic

```javascript
function shouldCreateADR(story, nfrs, context) {
  if (story.labels.includes('bug') && !story.labels.includes('security')) return false;
  if (story.labels.includes('docs-only')) return false;
  if (detectNewTechnology(story.title, story.body, context)) return true;
  if (nfrs.security?.sensitiveData?.length > 0 || nfrs.security?.compliance?.length > 0) return true;
  if (context.relatedADRs.some(adr => adr.status === 'superseded')) return true;
  if (context.preferredApproach && context.preferredApproach !== "No preference") return true;
  return askUser("This story may benefit from an ADR. Create one?");
}
```

## NFR Mapping

```javascript
const decisionDrivers = [];
if (nfrs.performance) {
  decisionDrivers.push(
    `Performance: ${nfrs.performance.dailyActiveUsers} daily users, ` +
    `${nfrs.performance.maxResponseTime} max response time`
  );
}
if (nfrs.scalability && !nfrs.scalability.skipped) {
  decisionDrivers.push(`Scalability: ${nfrs.scalability.growthProjection}`);
}
if (nfrs.security) {
  decisionDrivers.push(
    `Security: ${nfrs.security.sensitiveData.join(', ')}, ` +
    `${nfrs.security.compliance.join(', ')} compliance required`
  );
}
if (nfrs.reliability && !nfrs.reliability.skipped) {
  decisionDrivers.push(
    `Reliability: ${nfrs.reliability.acceptableDowntime} downtime SLA, ` +
    `${nfrs.reliability.errorRate} error rate`
  );
}
if (nfrs.cost) {
  decisionDrivers.push(`Cost: ${nfrs.cost.budget}, prefer ${nfrs.cost.preferredServices.join(', ')}`);
}
context.constraints?.forEach(c => decisionDrivers.push(`Constraint: ${c}`));
```

## Alternatives Generation

```javascript
function generateAlternatives(preferredApproach) {
  if (preferredApproach.includes('Stripe')) {
    return [
      { name: 'Stripe Elements (custom UI)' },
      { name: 'PayPal Commerce Platform' },
      { name: 'Square Payment Form' }
    ];
  }
  if (preferredApproach.includes('DynamoDB')) {
    return [
      { name: 'RDS PostgreSQL' },
      { name: 'Aurora Serverless' }
    ];
  }
  return [
    { name: 'Alternative approach (specify)' },
    { name: 'Do nothing (defer decision)' }
  ];
}
```

## Pros/Cons Example (Stripe Checkout)

```markdown
### Stripe Checkout (Hosted Page)

Stripe's hosted payment page that handles the entire checkout flow.

* Good, because PCI-DSS compliance is handled by Stripe
* Good, because fast implementation (< 1 day)
* Good, because battle-tested at scale
* Bad, because limited UI customization
* Bad, because redirect may increase cart abandonment 10–15%
* Cost: $0.029 + 2.9% per transaction
* Complexity: Low
```

## Decision Outcome Example

```markdown
## Decision Outcome

Chosen option: "Stripe Checkout (hosted page)", because it satisfies PCI-DSS compliance
with minimal effort, aligns with standard budget, and meets performance requirements.

### Consequences

* Good, because Stripe handles PCI compliance, reducing audit scope
* Good, because fast implementation (1–2 days vs 1–2 weeks)
* Bad, because users redirect away from site (estimated 10–15% abandonment increase)

### Confirmation

* Payment completion rate > 85%
* Payment latency < 2s end-to-end
* Cart abandonment during redirect < 20%
```

## File Write

```javascript
const adrContent = `---
status: "proposed"
date: ${new Date().toISOString().split('T')[0]}
decision-makers: [User Name]
consulted: []
informed: []
---

# ADR-${adrNumber}: ${titleSlug}
...
`;
fs.writeFileSync(`${process.env.ADR_DIR || 'docs/adr'}/${adrNumber}-${titleSlug}.md`, adrContent);

story.adr = {
  number: adrNumber,
  filePath: `${process.env.ADR_DIR || 'docs/adr'}/${adrNumber}-${titleSlug}.md`,
  title: titleSlug,
  status: 'proposed',
  createdAt: new Date().toISOString()
};
fs.writeFileSync('.agile-dev-team/active-story.yaml', yaml.dump(story));
```
