# Performance Fitness Function Example: 99th Percentile Latency

Complete implementation example for the NFR: **"Contact form submission must have 99th percentile latency ≤ 100ms"**

---

## Business Context

- **Business Type**: B2B SaaS
- **User Base**: Enterprise customers
- **Risk Profile**: System downtime
- **Critical Journey**: "Homepage → Contact → Submit → Confirmation"
- **NFR Priority**: Performance (HIGH)

---

## Fitness Function Definition

**File**: `.claude/fitness-functions/fitness-functions/performance/latency-99p.yml`

```yaml
fitness_function:
  id: "perf-001"
  name: "contact_form_latency_p99"
  category: "performance"
  nfr_description: "Contact form Lambda p99 latency ≤ 100ms"

  business_context:
    priority: "HIGH"
    rationale: "Enterprise customers expect fast responses; slow forms reduce conversion"
    stakeholder: "VP of Engineering"

  measurement:
    type: "latency"
    source: "CloudWatch Metrics (production) + k6 (pre-production)"
    metric: "Lambda.Duration"
    aggregation: "p99"
    period: "5 minutes"

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
        trigger: "PR to master"
        environment: "Staging"
      - type: "cloudwatch_alarm"
        file: "infrastructure/lib/aigensa-stack.ts"
        trigger: "Production runtime"
        environment: "Production"
    manual:
      - file: "tests/manual/performance-verification.md"
        frequency: "Pre-release"

  ci_cd_gate:
    stage: "pre-merge"
    blocking: true
    failure_action: "Block PR merge, comment with results and remediation guidance"
    success_criteria: "p99 latency < 100ms for 5-minute test duration"

  remediation:
    guidance: |
      If this fitness function fails (p99 > 100ms):

      1. **Profile Lambda execution** with AWS X-Ray
         - Identify slowest operations
         - Check for external API calls

      2. **Check for common issues**:
         - N+1 database queries
         - Cold start overhead (provision concurrency?)
         - Inefficient algorithms (O(n²) or worse)
         - Synchronous external API calls

      3. **Optimization strategies**:
         - Add caching (ElastiCache, DynamoDB DAX)
         - Use connection pooling for database
         - Parallelize independent operations (Promise.all)
         - Increase Lambda memory (improves CPU allocation)
         - Consider provisioned concurrency for critical Lambdas

      4. **If still failing**:
         - Review threshold with stakeholders (is 100ms realistic?)
         - Consider architectural changes (async processing, queues)
```

---

## Implementation: k6 Load Test

**File**: `tests/performance/contact-form-load.js`

```javascript
import http from 'k6/http';
import { check } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';

// Custom metrics
const contactFormLatency = new Trend('contact_form_latency');
const contactFormErrors = new Rate('contact_form_errors');
const totalRequests = new Counter('total_requests');

// Test configuration
export const options = {
  stages: [
    { duration: '1m', target: 5 },   // Warm-up: ramp to 5 users
    { duration: '3m', target: 10 },  // Steady state: 10 users
    { duration: '2m', target: 20 },  // Peak load: 20 users
    { duration: '1m', target: 0 },   // Cool down
  ],

  thresholds: {
    // FITNESS FUNCTION: p99 latency < 100ms
    'contact_form_latency': [
      'p(99)<100',   // 99th percentile < 100ms (CRITICAL)
      'p(95)<80',    // 95th percentile < 80ms (target)
      'p(50)<50',    // 50th percentile < 50ms (target)
    ],

    // Additional quality metrics
    'contact_form_errors': ['rate<0.01'], // Error rate < 1%
    'http_req_duration': ['p(99)<200'],   // Overall request < 200ms
  },
};

// Test data
const testPayload = JSON.stringify({
  name: 'Load Test User',
  email: 'loadtest@example.com',
  subject: 'Performance Test',
  message: 'This is an automated performance test message.',
  'g-recaptcha-response': 'test_token', // Mock reCAPTCHA for testing
});

export default function () {
  const url = __ENV.CONTACT_FORM_URL || 'https://staging-lambda-url.execute-api.us-east-1.amazonaws.com';

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
    tags: {
      name: 'ContactFormSubmission',
    },
  };

  // Execute request
  const startTime = Date.now();
  const response = http.post(url, testPayload, params);
  const duration = Date.now() - startTime;

  // Record metrics
  contactFormLatency.add(duration);
  totalRequests.add(1);

  // Validate response
  const success = check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 200ms': (r) => r.timings.duration < 200,
    'body contains success': (r) => r.body && r.body.includes('success'),
  });

  if (!success) {
    contactFormErrors.add(1);
    console.error(`Request failed: ${response.status} - ${response.body}`);
  }
}

// Summary handler
export function handleSummary(data) {
  const p99 = data.metrics.contact_form_latency.values['p(99)'];
  const p95 = data.metrics.contact_form_latency.values['p(95)'];
  const p50 = data.metrics.contact_form_latency.values['p(50)'];
  const errorRate = data.metrics.contact_form_errors.values.rate;

  console.log('\n========================================');
  console.log('FITNESS FUNCTION RESULTS');
  console.log('========================================');
  console.log(`P99 Latency: ${p99.toFixed(2)}ms ${p99 <= 100 ? '✅ PASS' : '❌ FAIL'}`);
  console.log(`P95 Latency: ${p95.toFixed(2)}ms ${p95 <= 80 ? '✅' : '⚠️'}`);
  console.log(`P50 Latency: ${p50.toFixed(2)}ms`);
  console.log(`Error Rate: ${(errorRate * 100).toFixed(2)}% ${errorRate <= 0.01 ? '✅' : '❌'}`);
  console.log('========================================\n');

  return {
    'summary.json': JSON.stringify(data),
    stdout: textSummary(data, { indent: ' ', enableColors: true }),
  };
}
```

**To run locally**:
```bash
export CONTACT_FORM_URL="https://your-staging-url.com"
k6 run tests/performance/contact-form-load.js
```

---

## Implementation: CloudWatch Alarm

**File**: `infrastructure/lib/aigensa-stack.ts` (modify existing)

```typescript
import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatch_actions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as sns from 'aws-cdk-lib/aws-sns';

// ... existing code ...

export class AigensaStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ... existing Lambda function code ...

    // Existing SNS topic for alarms
    const alarmTopic = new sns.Topic(this, 'AlarmTopic', {
      displayName: 'CloudWatch Alarms for AIGENSA',
    });

    // NEW: Fitness Function - P99 Latency Alarm
    const p99Latency = contactFormFunction.metricDuration({
      statistic: 'p99',
      period: cdk.Duration.minutes(5),
    });

    new cloudwatch.Alarm(this, 'HighP99LatencyAlarm', {
      metric: p99Latency,
      threshold: 100, // 100 milliseconds
      evaluationPeriods: 2,
      datapointsToAlarm: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      alarmName: 'AIGENSA-ContactForm-HighP99Latency',
      alarmDescription: 'Fitness Function: Contact form Lambda p99 latency > 100ms',
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(alarmTopic));

    // Optional: P95 latency for early warning
    const p95Latency = contactFormFunction.metricDuration({
      statistic: 'p95',
      period: cdk.Duration.minutes(5),
    });

    new cloudwatch.Alarm(this, 'HighP95LatencyWarning', {
      metric: p95Latency,
      threshold: 80, // 80 milliseconds
      evaluationPeriods: 3,
      datapointsToAlarm: 2,
      comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
      alarmName: 'AIGENSA-ContactForm-HighP95Latency',
      alarmDescription: 'Warning: Contact form Lambda p95 latency > 80ms',
      treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
    }).addAlarmAction(new cloudwatch_actions.SnsAction(alarmTopic));
  }
}
```

**Deploy changes**:
```bash
cd infrastructure
npm run synth     # Validate CloudFormation template
npm run diff      # Review changes
npm run deploy    # Deploy to AWS
```

---

## CI/CD Integration

**File**: `.github/workflows/performance-test.yml`

```yaml
name: Performance Testing (Fitness Functions)

on:
  pull_request:
    branches: [master]
    paths:
      - 'infrastructure/**'
      - '.github/workflows/performance-test.yml'
  workflow_dispatch:
    inputs:
      target_url:
        description: 'Target URL for performance testing'
        required: true
        default: 'https://staging-url.com'

jobs:
  performance-test:
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup k6
        uses: grafana/setup-k6-action@v1

      - name: Run performance tests
        env:
          CONTACT_FORM_URL: ${{ github.event.inputs.target_url || secrets.STAGING_CONTACT_FORM_URL }}
        run: |
          k6 run tests/performance/contact-form-load.js --out json=summary.json

      - name: Parse results
        id: results
        run: |
          P99_LATENCY=$(jq -r '.metrics.contact_form_latency.values."p(99)"' summary.json)
          ERROR_RATE=$(jq -r '.metrics.contact_form_errors.values.rate' summary.json)

          echo "p99_latency=$P99_LATENCY" >> $GITHUB_OUTPUT
          echo "error_rate=$ERROR_RATE" >> $GITHUB_OUTPUT

          echo "### Performance Test Results" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Metric | Value | Threshold | Status |" >> $GITHUB_STEP_SUMMARY
          echo "|--------|-------|-----------|--------|" >> $GITHUB_STEP_SUMMARY
          echo "| P99 Latency | ${P99_LATENCY}ms | ≤100ms | $([ $(echo "$P99_LATENCY <= 100" | bc -l) -eq 1 ] && echo "✅ PASS" || echo "❌ FAIL") |" >> $GITHUB_STEP_SUMMARY
          echo "| Error Rate | $(echo "$ERROR_RATE * 100" | bc)% | ≤1% | $([ $(echo "$ERROR_RATE <= 0.01" | bc -l) -eq 1 ] && echo "✅ PASS" || echo "❌ FAIL") |" >> $GITHUB_STEP_SUMMARY

      - name: Check fitness function (BLOCKING)
        run: |
          P99_LATENCY=${{ steps.results.outputs.p99_latency }}

          if (( $(echo "$P99_LATENCY > 100" | bc -l) )); then
            echo "❌ FAILED: P99 latency (${P99_LATENCY}ms) exceeds 100ms threshold"
            echo ""
            echo "Remediation steps:"
            echo "1. Profile Lambda with X-Ray"
            echo "2. Check for N+1 queries, cold starts"
            echo "3. Consider caching, async optimization"
            echo "4. Increase Lambda memory"
            exit 1
          else
            echo "✅ PASSED: P99 latency (${P99_LATENCY}ms) within 100ms threshold"
          fi

      - name: Comment on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const p99 = '${{ steps.results.outputs.p99_latency }}';
            const errorRate = '${{ steps.results.outputs.error_rate }}';
            const passed = parseFloat(p99) <= 100;

            const body = `## Performance Fitness Function Results

            | Metric | Value | Threshold | Status |
            |--------|-------|-----------|--------|
            | P99 Latency | ${p99}ms | ≤100ms | ${passed ? '✅ PASS' : '❌ FAIL'} |
            | Error Rate | ${(parseFloat(errorRate) * 100).toFixed(2)}% | ≤1% | ${parseFloat(errorRate) <= 0.01 ? '✅ PASS' : '❌ FAIL'} |

            ${passed ? '✅ All fitness functions passed!' : '❌ Fitness function failed - PR blocked'}`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });
```

---

## Manual Testing Procedure

**File**: `tests/manual/performance-verification.md`

```markdown
# Manual Performance Verification

**NFR ID**: perf-001
**Fitness Function**: Contact form p99 latency ≤ 100ms
**Frequency**: Pre-release (before production deployment)

## Prerequisites

- Access to staging environment
- Browser with DevTools
- Access to CloudWatch (production verification)

## Test Procedure

### 1. Browser-Based Testing

1. Open browser DevTools (F12)
2. Navigate to Network tab
3. Go to staging contact form: https://staging.aigensa.com/contact.html
4. Fill out form with test data:
   - Name: "Manual Test User"
   - Email: "test@example.com"
   - Subject: "Performance Verification"
   - Message: "Manual performance test"
5. Click Submit
6. In Network tab, find the POST request to Lambda
7. Record the "Time" value
8. Repeat 20 times, recording each time

### 2. Calculate P99

1. Sort all times ascending
2. P99 = value at index 19 (20 * 0.99 = 19.8, round up to 20)
3. Compare to threshold: P99 ≤ 100ms

### 3. CloudWatch Verification (Production)

1. Log into AWS Console → CloudWatch
2. Navigate to Metrics → Lambda → By Function Name
3. Select contact form Lambda
4. Choose "Duration" metric
5. Set statistic to "p99"
6. Set period to "5 minutes"
7. Verify p99 latency over last 24 hours
8. Check "HighP99LatencyAlarm" status

## Pass/Fail Criteria

✅ **PASS**: P99 latency ≤ 100ms in both manual and CloudWatch checks
❌ **FAIL**: P99 latency > 100ms in either check

## If Test Fails

Follow remediation guidance in fitness function definition:
1. Profile with X-Ray
2. Check for N+1 queries, cold starts
3. Consider caching, async optimization
4. Increase Lambda memory

## Sign-off

- Tester: _______________
- Date: _______________
- Result: ☐ PASS  ☐ FAIL
- Notes: _______________
```

---

## Verification Checklist

Before marking this fitness function as complete:

- [ ] Fitness function definition created (`.claude/fitness-functions/fitness-functions/performance/latency-99p.yml`)
- [ ] k6 load test created (`tests/performance/contact-form-load.js`)
- [ ] k6 test runs successfully locally
- [ ] CloudWatch alarm added to CDK stack (`infrastructure/lib/aigensa-stack.ts`)
- [ ] CDK changes deployed to staging
- [ ] CloudWatch alarm visible in AWS Console
- [ ] CI/CD workflow created (`.github/workflows/performance-test.yml`)
- [ ] Workflow runs successfully on PR
- [ ] Manual test procedure documented (`tests/manual/performance-verification.md`)
- [ ] Manual test executed successfully
- [ ] Remediation guidance documented
- [ ] Stakeholder approval received

---

## Success Metrics

After implementation:
- ✅ 100% of PRs run performance fitness function
- ✅ P99 latency maintained < 100ms in production
- ✅ Zero production incidents related to slow contact form
- ✅ Stakeholder confidence in performance quality
