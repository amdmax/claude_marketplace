# NFR → Fitness Function Mapping

Complete reference for mapping Non-Functional Requirements to testable fitness functions with appropriate test frameworks and CI/CD integration strategies.

---

## Mapping Framework

Each NFR category maps to:
1. **Measurement Type**: What we're measuring
2. **Test Type**: How we verify it
3. **Framework**: Tool to use
4. **Automation Level**: Automated vs manual
5. **CI/CD Integration**: Blocking vs non-blocking
6. **Implementation Files**: Where tests live

---

## Performance NFRs

### Latency (API Response Time)

**NFR Example**: "99th percentile API latency must be ≤ 100ms"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Request-response time (p99, p95, p50) |
| **Test Type** | Load testing + Infrastructure monitoring |
| **Framework** | k6 (load test) + CloudWatch (production alarm) |
| **Automation** | Fully automated |
| **CI/CD Gate** | Blocking in pre-production |
| **Files** | `tests/performance/{service}-load.js` (k6)<br>`infrastructure/lib/*-stack.ts` (CloudWatch alarm) |
| **Workflow** | `.github/workflows/performance-test.yml` |

**k6 Test Template**:
```javascript
import http from 'k6/http';
import { Trend } from 'k6/metrics';

const latency = new Trend('api_latency');

export const options = {
  stages: [
    { duration: '2m', target: 10 },
    { duration: '5m', target: 50 },
  ],
  thresholds: {
    'api_latency': ['p(99)<100'], // FITNESS FUNCTION
  },
};

export default function () {
  const res = http.get('https://api.example.com/endpoint');
  latency.add(res.timings.duration);
}
```

**CloudWatch Alarm Template**:
```typescript
const p99Latency = lambdaFunction.metricDuration({
  statistic: 'p99',
  period: cdk.Duration.minutes(5),
});

new cloudwatch.Alarm(this, 'HighP99LatencyAlarm', {
  metric: p99Latency,
  threshold: 100, // milliseconds
  evaluationPeriods: 2,
  alarmDescription: 'Fitness Function: API p99 latency > 100ms',
}).addAlarmAction(new cloudwatch_actions.SnsAction(alarmTopic));
```

---

### Page Load Time

**NFR Example**: "75th percentile page load time must be ≤ 2s"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Full page load (DOMContentLoaded, load events) |
| **Test Type** | Browser-based performance testing |
| **Framework** | Lighthouse CI + WebPageTest |
| **Automation** | Fully automated |
| **CI/CD Gate** | Non-blocking (report only) initially |
| **Files** | `.lighthouserc.json` (config)<br>`tests/performance/page-load.spec.js` (Lighthouse) |
| **Workflow** | `.github/workflows/lighthouse-ci.yml` |

**Lighthouse Config Template**:
```json
{
  "ci": {
    "collect": {
      "url": ["https://example.com", "https://example.com/contact"],
      "numberOfRuns": 3
    },
    "assert": {
      "assertions": {
        "first-contentful-paint": ["error", {"maxNumericValue": 2000}],
        "speed-index": ["error", {"maxNumericValue": 3000}],
        "interactive": ["error", {"maxNumericValue": 3500}]
      }
    }
  }
}
```

---

### Throughput (Requests Per Second)

**NFR Example**: "System must handle 1000 RPS at p95 latency ≤ 200ms"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Sustained load capacity |
| **Test Type** | Load testing + Stress testing |
| **Framework** | k6 (load) + CloudWatch (production metrics) |
| **Automation** | Fully automated |
| **CI/CD Gate** | Blocking for major changes |
| **Files** | `tests/performance/{service}-stress-test.js` |
| **Workflow** | `.github/workflows/stress-test.yml` (scheduled) |

---

### Cold Start Time (Serverless)

**NFR Example**: "Lambda cold start p90 ≤ 1s"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Init duration for cold starts |
| **Test Type** | CloudWatch metrics + Synthetic testing |
| **Framework** | CloudWatch Insights + k6 |
| **Automation** | Fully automated |
| **CI/CD Gate** | Non-blocking (monitoring only) |
| **Files** | `infrastructure/lib/*-stack.ts` (alarm)<br>CloudWatch Logs Insights queries |
| **Workflow** | Production monitoring |

---

## User Experience NFRs

### Click Journey Efficiency

**NFR Example**: "95% of user journeys must complete in ≤ 5 clicks"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Click count for task completion |
| **Test Type** | E2E testing with click tracking |
| **Framework** | Playwright (automated) + Manual testing |
| **Automation** | Semi-automated (E2E + manual validation) |
| **CI/CD Gate** | Non-blocking (report only) |
| **Files** | `tests/e2e/{journey}-clicks.spec.ts` (Playwright)<br>`tests/manual/{journey}-procedure.md` (manual) |
| **Workflow** | `.github/workflows/e2e-test.yml` |

**Playwright Test Template**:
```typescript
import { test, expect } from '@playwright/test';

test('Contact form journey ≤5 clicks', async ({ page }) => {
  let clickCount = 0;
  page.on('click', () => clickCount++);

  await page.goto('https://example.com');
  await page.click('a[href="/contact"]');  // Click 1
  await page.fill('input[name="name"]', 'Test User');
  await page.fill('input[name="email"]', 'test@example.com');
  await page.fill('textarea[name="message"]', 'Message');
  await page.click('button[type="submit"]');  // Click 5

  expect(clickCount).toBeLessThanOrEqual(5);  // FITNESS FUNCTION
});
```

---

### Task Completion Rate

**NFR Example**: "90% of users complete onboarding successfully"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Funnel completion percentage |
| **Test Type** | Analytics + E2E testing |
| **Framework** | Google Analytics + Playwright |
| **Automation** | Semi-automated (E2E) + Production analytics |
| **CI/CD Gate** | Non-blocking (dashboard monitoring) |
| **Files** | `tests/e2e/onboarding-funnel.spec.ts`<br>Analytics dashboard |
| **Workflow** | Production monitoring |

---

### Error Rate (User-Visible Errors)

**NFR Example**: "User-visible error rate ≤ 0.1%"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | HTTP 5xx errors / total requests |
| **Test Type** | CloudWatch metrics + Application monitoring |
| **Framework** | CloudWatch + Sentry/Datadog |
| **Automation** | Fully automated |
| **CI/CD Gate** | Blocking (production alarm) |
| **Files** | `infrastructure/lib/*-stack.ts` (alarm)<br>Application error tracking |
| **Workflow** | Production monitoring |

---

## Security NFRs

### Vulnerability Scanning

**NFR Example**: "Zero CRITICAL or HIGH severity vulnerabilities in dependencies"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Vulnerability count by severity |
| **Test Type** | Dependency scanning + SAST |
| **Framework** | npm audit + Semgrep + existing code review |
| **Automation** | Fully automated |
| **CI/CD Gate** | Blocking for CRITICAL/HIGH |
| **Files** | `.github/code-review/prompts/01-security-review.md` (ALREADY EXISTS!)<br>`package.json` (npm audit) |
| **Workflow** | `.github/workflows/claude-code-review.yml` (ALREADY EXISTS!) |

**npm Audit Integration**:
```bash
# In CI/CD workflow
npm audit --audit-level=moderate
if [ $? -ne 0 ]; then
  echo "❌ FAILED: Found moderate or higher vulnerabilities"
  exit 1
fi
```

---

### Secret Detection

**NFR Example**: "Zero secrets (API keys, passwords) in source code or logs"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Secret pattern matches |
| **Test Type** | Static analysis + Log scanning |
| **Framework** | Existing code review + git-secrets |
| **Automation** | Fully automated |
| **CI/CD Gate** | Blocking |
| **Files** | `.github/code-review/prompts/01-security-review.md` (ALREADY EXISTS!)<br>Pre-commit hooks |
| **Workflow** | `.github/workflows/claude-code-review.yml` (ALREADY EXISTS!) |

---

### OWASP Top 10 Compliance

**NFR Example**: "No instances of OWASP Top 10:2025 vulnerabilities"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | OWASP category violations |
| **Test Type** | Code review + SAST + Penetration testing (manual) |
| **Framework** | Existing code review (15 OWASP categories!) |
| **Automation** | Automated (code review) + Manual (pentest) |
| **CI/CD Gate** | Blocking for automated checks |
| **Files** | `.github/code-review/prompts/01-security-review.md` (ALREADY EXISTS!) |
| **Workflow** | `.github/workflows/claude-code-review.yml` (ALREADY EXISTS!) |

**Note**: Your project already has comprehensive OWASP security review! Reference:
- `.github/CODE_REVIEW_PROCESS.md`
- `.github/code-review/prompts/01-security-review.md`

---

## Reliability NFRs

### Uptime / Availability

**NFR Example**: "99.9% uptime SLA (≤ 43 minutes downtime/month)"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Service availability percentage |
| **Test Type** | Health checks + Synthetic monitoring |
| **Framework** | CloudWatch + Route53 Health Checks + External monitoring (Pingdom) |
| **Automation** | Fully automated |
| **CI/CD Gate** | Production monitoring (alarms) |
| **Files** | `infrastructure/lib/*-stack.ts` (health checks)<br>Monitoring dashboard |
| **Workflow** | Production monitoring |

---

### Error Rate (Backend)

**NFR Example**: "Backend error rate ≤ 1% of requests"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Errors / total invocations |
| **Test Type** | CloudWatch metrics |
| **Framework** | CloudWatch alarms (ALREADY EXISTS!) |
| **Automation** | Fully automated |
| **CI/CD Gate** | Production monitoring (blocking alarm) |
| **Files** | `infrastructure/lib/aigensa-stack.ts` (ALREADY EXISTS!)<br>HighErrorRateAlarm already configured! |
| **Workflow** | Production monitoring |

**Note**: Your project already has error rate monitoring! Current threshold: 10% error rate over 5 minutes.

---

### Recovery Time Objective (RTO)

**NFR Example**: "System recovery within 1 hour of failure"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Time from failure detection to service restoration |
| **Test Type** | Disaster recovery drills (manual) |
| **Framework** | Runbooks + Chaos engineering |
| **Automation** | Manual execution with documented procedures |
| **CI/CD Gate** | Quarterly validation |
| **Files** | `docs/runbooks/disaster-recovery.md`<br>`docs/runbooks/incident-response.md` |
| **Workflow** | Manual + Scheduled drills |

---

## Accessibility NFRs

### WCAG 2.0 Level AA Compliance

**NFR Example**: "100% of pages pass WCAG 2.0 Level AA"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | WCAG violation count |
| **Test Type** | Automated accessibility testing |
| **Framework** | Pa11y-CI with axe + htmlcs runners (ALREADY EXISTS!) |
| **Automation** | Fully automated |
| **CI/CD Gate** | Non-blocking (currently) |
| **Files** | `.pa11yci.json` (ALREADY EXISTS!)<br>Tests 6 pages currently |
| **Workflow** | `.github/workflows/accessibility-check.yml` (ALREADY EXISTS!) |

**Note**: Your project already has comprehensive accessibility testing! Currently tests:
- index.html, contact.html, learning.html, products.html, blog.html, eval-arena.html

**To make blocking**:
```yaml
# Modify .github/workflows/accessibility-check.yml
- name: Run Pa11y-CI
  run: npm run a11y:check
  # Remove continue-on-error to make blocking
```

---

### Keyboard Navigation

**NFR Example**: "All interactive elements accessible via keyboard only"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Keyboard navigation completeness |
| **Test Type** | Manual testing + Automated checks |
| **Framework** | Pa11y-CI (automated) + Manual validation |
| **Automation** | Semi-automated |
| **CI/CD Gate** | Non-blocking |
| **Files** | `.pa11yci.json` (ALREADY EXISTS!)<br>`tests/manual/keyboard-navigation.md` |
| **Workflow** | `.github/workflows/accessibility-check.yml` (ALREADY EXISTS!) |

---

## Compliance NFRs

### HIPAA Compliance

**NFR Example**: "Zero PHI (Protected Health Information) in logs or unencrypted storage"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | PHI pattern detection |
| **Test Type** | Log scanning + Code review + Audit |
| **Framework** | Custom regex scanning + Manual audit |
| **Automation** | Semi-automated |
| **CI/CD Gate** | Blocking for automated checks |
| **Files** | `tests/compliance/phi-detection.js`<br>`docs/compliance/hipaa-controls.md` |
| **Workflow** | `.github/workflows/compliance-check.yml` |

---

### SOC 2 Controls

**NFR Example**: "All SOC 2 Type II controls implemented and verified"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Control implementation status |
| **Test Type** | Automated checks + Manual audit |
| **Framework** | Custom scripts + Third-party audit |
| **Automation** | Semi-automated (technical controls) |
| **CI/CD Gate** | Quarterly validation |
| **Files** | `docs/compliance/soc2-controls.md`<br>`tests/compliance/soc2-validation.sh` |
| **Workflow** | Scheduled validation + Annual audit |

---

## Cost Optimization NFRs

### Infrastructure Cost Ceiling

**NFR Example**: "Monthly AWS cost ≤ $500 for non-production environments"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | AWS billing metrics |
| **Test Type** | AWS Budgets + Cost Explorer |
| **Framework** | AWS Budgets (alarms) + CloudWatch |
| **Automation** | Fully automated |
| **CI/CD Gate** | Alert-based (non-blocking) |
| **Files** | `infrastructure/lib/*-stack.ts` (budget alarms)<br>Cost allocation tags |
| **Workflow** | Production monitoring |

**Budget Alarm Template**:
```typescript
import * as budgets from 'aws-cdk-lib/aws-budgets';

new budgets.CfnBudget(this, 'MonthlyBudget', {
  budget: {
    budgetName: 'dev-environment-budget',
    budgetLimit: {
      amount: 500,
      unit: 'USD',
    },
    budgetType: 'COST',
    timeUnit: 'MONTHLY',
  },
  notificationsWithSubscribers: [{
    notification: {
      notificationType: 'ACTUAL',
      comparisonOperator: 'GREATER_THAN',
      threshold: 80, // Alert at 80% of budget
    },
    subscribers: [{
      subscriptionType: 'EMAIL',
      address: 'team@example.com',
    }],
  }],
});
```

---

### Bundle Size

**NFR Example**: "JavaScript bundle size ≤ 200KB (gzipped)"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Compressed bundle size (gzip) |
| **Test Type** | Build-time analysis |
| **Framework** | size-limit + webpack-bundle-analyzer |
| **Automation** | Fully automated |
| **CI/CD Gate** | Blocking |
| **Files** | `.size-limit.json` (config)<br>Build pipeline |
| **Workflow** | `.github/workflows/bundle-size-check.yml` |

**size-limit Config Template**:
```json
[
  {
    "path": "dist/bundle.js",
    "limit": "200 KB",
    "gzip": true
  }
]
```

---

## Operability NFRs

### Deployment Frequency

**NFR Example**: "Deploy to production at least weekly"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Deployments per week |
| **Test Type** | CI/CD metrics |
| **Framework** | GitHub Actions + DORA metrics |
| **Automation** | Automated tracking |
| **CI/CD Gate** | Dashboard monitoring |
| **Files** | Deployment logs<br>Metrics dashboard |
| **Workflow** | Production tracking |

---

### Mean Time To Recovery (MTTR)

**NFR Example**: "MTTR ≤ 30 minutes for production incidents"

| Aspect | Details |
|--------|---------|
| **Measurement Type** | Time from incident detection to resolution |
| **Test Type** | Incident tracking + Runbook validation |
| **Framework** | PagerDuty/Opsgenie + Runbooks |
| **Automation** | Manual (incident response) |
| **CI/CD Gate** | Monthly review |
| **Files** | `docs/runbooks/incident-response.md`<br>Incident retrospectives |
| **Workflow** | Incident tracking system |

---

## Summary Matrix

| NFR Category | Recommended Framework | Automation | CI/CD Gate | Already Exists? |
|--------------|----------------------|------------|------------|-----------------|
| **Performance - Latency** | k6 + CloudWatch | Automated | Blocking | Partial (CloudWatch alarms exist) |
| **Performance - Page Load** | Lighthouse CI | Automated | Non-blocking | ❌ No |
| **UX - Clicks** | Playwright | Semi-automated | Non-blocking | ❌ No |
| **UX - Task Completion** | Playwright + Analytics | Semi-automated | Non-blocking | ❌ No |
| **Security - Vulnerabilities** | npm audit + Code Review | Automated | Blocking | ✅ **Yes** (code review) |
| **Security - OWASP Top 10** | Code Review | Automated | Blocking | ✅ **Yes** (15 categories!) |
| **Reliability - Error Rate** | CloudWatch | Automated | Blocking | ✅ **Yes** (HighErrorRateAlarm) |
| **Reliability - Uptime** | CloudWatch + Route53 | Automated | Monitoring | Partial |
| **Accessibility - WCAG** | Pa11y-CI | Automated | Non-blocking | ✅ **Yes** (6 pages) |
| **Compliance - HIPAA** | Custom + Manual Audit | Semi-automated | Blocking | ❌ No |
| **Compliance - SOC 2** | Custom + Manual Audit | Semi-automated | Quarterly | ❌ No |
| **Cost - Budget** | AWS Budgets | Automated | Alert-based | ❌ No |
| **Cost - Bundle Size** | size-limit | Automated | Blocking | ❌ No |

---

## Decision Tree: Which Framework to Use?

```
What are you measuring?
├─ API/Backend Performance → k6 + CloudWatch
├─ Frontend Performance → Lighthouse CI + WebPageTest
├─ User Journeys → Playwright E2E
├─ Security Vulnerabilities → npm audit + Code Review (already exists!)
├─ Accessibility → Pa11y-CI (already exists!)
├─ Infrastructure Health → CloudWatch alarms (already exists!)
├─ Compliance → Custom scripts + Manual audit
└─ Cost → AWS Budgets + Cost Explorer
```

---

## Next Steps

1. Review existing fitness functions (security, accessibility, error rate)
2. Identify gaps based on business priorities
3. Generate test scaffolding for new fitness functions
4. Integrate with CI/CD pipeline
5. Document remediation procedures for each fitness function
