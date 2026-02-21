---
name: gather-nfr
description: Collect non-functional requirements through interactive Q&A. Asks targeted questions about performance, scalability, security, reliability, and cost constraints. Invokable with /gather-nfr.
---

# Gather Non-Functional Requirements

## Overview

This skill collects Non-Functional Requirements (NFRs) through an interactive questionnaire. It:

1. **Reads active story** from `.claude/active-story.json`
2. **Analyzes story context** (title, labels, body) to tailor questions
3. **Asks targeted questions** across 6 NFR categories
4. **Collects responses** using AskUserQuestion tool
5. **Appends NFRs** to `.claude/active-story.json` for later use

NFRs inform architectural decisions, implementation choices, and ADR content.

## NFR Categories

### 1. Performance

**Questions:**

| Question | Response Type | Default/Skip |
|----------|---------------|--------------|
| Expected daily active users? | Multiple choice: [<100, 100-1000, 1000-10000, 10000+] | 100-1000 |
| Maximum acceptable response time? | Multiple choice: [<500ms, <1s, <2s, <5s, No constraint] | <2s |
| Concurrent user load estimate? | Multiple choice: [<10, 10-100, 100-1000, 1000+] | 10-100 |

**When to ask:**
- Always ask for user-facing features
- Skip for backend batch jobs (no user interaction)

**Example responses:**
```json
{
  "dailyActiveUsers": "1000-10000",
  "maxResponseTime": "<2s",
  "concurrentUsers": "100-1000"
}
```

### 2. Scalability

**Questions:**

| Question | Response Type | Default/Skip |
|----------|---------------|--------------|
| User growth projection (6 months)? | Multiple choice: [No growth, 2x, 5x, 10x+] | 2x |
| Geographic distribution? | Multiple choice: [Single region (US), Multi-region, Global] | Single region |
| Peak usage patterns? | Text input | "Standard business hours" |

**When to ask:**
- For features expected to have significant growth
- Skip for internal tools or proof-of-concepts

**Example responses:**
```json
{
  "growthProjection": "2x in 6 months",
  "geographic": "US-only",
  "peakPatterns": "9am-5pm weekdays, spikes during month-end"
}
```

### 3. Data & Storage

**Questions:**

| Question | Response Type | Default/Skip |
|----------|---------------|--------------|
| Data retention requirements? | Multiple choice: [7 days, 30 days, 1 year, 7 years, Indefinite] | 1 year |
| Estimated data volume per user? | Multiple choice: [<1MB, 1-10MB, 10-100MB, >100MB] | 1-10MB |
| Backup/recovery SLAs? | Multiple choice: [No backup, Daily backup, Real-time replication] | Daily backup |

**When to ask:**
- For features that create or modify data
- Skip for read-only or stateless features

**Example responses:**
```json
{
  "dataRetention": "1 year",
  "dataVolumePerUser": "1-10MB",
  "backupSLA": "Daily backup with 7-day retention"
}
```

### 4. Security

**Questions:**

| Question | Response Type | Default/Skip |
|----------|---------------|--------------|
| Sensitive data types? | Multiple select: [None, PII, Payment, Health, Credentials] | None |
| Authentication requirements? | Multiple choice: [Public, Authenticated, Role-based] | Authenticated |
| Compliance needs? | Multiple select: [None, GDPR, PCI-DSS, HIPAA, SOC 2] | None |

**When to ask:**
- Always ask (security is critical)
- Tailor questions based on labels (e.g., skip payment questions if label != "payment")

**Example responses:**
```json
{
  "sensitiveData": ["PII", "payment"],
  "authentication": "authenticated-only",
  "compliance": ["PCI-DSS", "GDPR"]
}
```

### 5. Reliability

**Questions:**

| Question | Response Type | Default/Skip |
|----------|---------------|--------------|
| Acceptable downtime? | Multiple choice: [4 hours/year (99.95%), 8 hours/year (99.9%), 1 day/year, Best effort] | 8 hours/year |
| Error rate tolerance? | Multiple choice: [<0.1%, <1%, <5%, No constraint] | <1% |
| Monitoring/alerting needs? | Multiple choice: [None, Basic (errors only), Comprehensive (errors + metrics)] | Basic |

**When to ask:**
- For production features
- Skip for development/testing features

**Example responses:**
```json
{
  "acceptableDowntime": "8 hours/year (99.9%)",
  "errorRate": "<1%",
  "monitoring": "Comprehensive (errors + metrics + dashboards)"
}
```

### 6. Cost

**Questions:**

| Question | Response Type | Default/Skip |
|----------|---------------|--------------|
| Budget constraints? | Multiple choice: [Minimize cost, Standard/balanced, Premium (performance priority)] | Standard |
| Preferred AWS services? | Multiple select: [Lambda, ECS, DynamoDB, RDS, S3, CloudFront] | Lambda, DynamoDB |

**When to ask:**
- For features with significant infrastructure
- Skip if using existing infrastructure

**Example responses:**
```json
{
  "budget": "standard",
  "preferredServices": ["Lambda", "DynamoDB", "S3"]
}
```

## Workflow

### Step 1: Verify Active Story Exists

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.claude/active-story.json"
if [ ! -f "$STORY_FILE" ]; then
  echo "❌ No active story found"
  echo "   Expected: $CLAUDE_PROJECT_DIR/.claude/active-story.json"
  echo "   Run /fetch-story first to select a story"
  exit 1
fi
```

### Step 2: Load and Analyze Story Context

**Read story data:**
```javascript
const story = JSON.parse(fs.readFileSync('.claude/active-story.json', 'utf-8'));

// Extract context for question tailoring
const title = story.title.toLowerCase();
const labels = story.labels.map(l => l.toLowerCase());
const body = story.body.toLowerCase();
```

**Determine applicable categories:**

| Category | Ask if... | Skip if... |
|----------|-----------|-----------|
| Performance | Always (user-facing) | Label contains "internal-tool" |
| Scalability | Expected growth | Label contains "poc" or "prototype" |
| Data & Storage | Creates/modifies data | Label contains "read-only" |
| Security | Always | Never skip |
| Reliability | Production feature | Label contains "experimental" |
| Cost | New infrastructure | Uses existing services |

### Step 3: Ask Performance Questions

**Use AskUserQuestion tool:**

```
Question 1: "How many daily active users do you expect for this feature?"
Options:
  • <100 users (small internal tool)
  • 100-1,000 users (team/department tool)
  • 1,000-10,000 users (company-wide tool) [Recommended]
  • 10,000+ users (public-facing product)

Question 2: "What is the maximum acceptable response time?"
Options:
  • <500ms (real-time, interactive)
  • <1 second (snappy, user-friendly)
  • <2 seconds (acceptable for most users) [Recommended]
  • <5 seconds (background operations)
  • No specific constraint

Question 3: "What concurrent user load should the system handle?"
Options:
  • <10 concurrent users
  • 10-100 concurrent users [Recommended]
  • 100-1,000 concurrent users
  • 1,000+ concurrent users
```

**Tailor recommendations:**
- For label="public": Recommend higher thresholds
- For label="internal": Recommend lower thresholds
- For label="admin": Recommend "No constraint"

### Step 4: Ask Scalability Questions

**Conditional logic:**

```javascript
// Skip scalability if POC or prototype
if (labels.includes('poc') || labels.includes('prototype')) {
  console.log('ℹ️  Skipping scalability (POC/prototype detected)');
  nfrs.scalability = { skipped: true, reason: 'POC/prototype' };
  // Continue to next category
}
```

**Otherwise ask:**

```
Question 1: "What user growth do you project in the next 6 months?"
Options:
  • No significant growth (stable user base)
  • 2x growth (moderate expansion) [Recommended]
  • 5x growth (rapid expansion)
  • 10x+ growth (viral/explosive growth)

Question 2: "What geographic distribution is required?"
Options:
  • Single region (US only) [Recommended]
  • Multi-region (US + EU)
  • Global (worldwide)

Question 3: "Describe peak usage patterns (time of day, events, etc.)"
Type: Text input
Default: "Standard business hours (9am-5pm)"
```

### Step 5: Ask Data & Storage Questions

**Conditional logic:**

```javascript
// Skip if read-only feature
if (labels.includes('read-only') || title.includes('view') || title.includes('display')) {
  console.log('ℹ️  Skipping data/storage (read-only feature detected)');
  nfrs.data = { skipped: true, reason: 'Read-only feature' };
}
```

**Otherwise ask:**

```
Question 1: "How long should data be retained?"
Options:
  • 7 days (short-term, temporary data)
  • 30 days (monthly reports)
  • 1 year (standard retention) [Recommended]
  • 7 years (compliance, financial records)
  • Indefinite (permanent storage)

Question 2: "What is the estimated data volume per user?"
Options:
  • <1MB (minimal data)
  • 1-10MB (standard) [Recommended]
  • 10-100MB (media, documents)
  • >100MB (large files, videos)

Question 3: "What backup and recovery SLAs are required?"
Options:
  • No backup (ephemeral data)
  • Daily backup with 7-day retention [Recommended]
  • Real-time replication (high availability)
```

### Step 6: Ask Security Questions

**Always ask (never skip):**

```
Question 1: "What types of sensitive data will this feature handle?"
Multi-select:
  □ None (public data only)
  □ PII (names, emails, addresses)
  □ Payment information (credit cards, bank accounts)
  □ Health information (PHI, medical records)
  □ Credentials (passwords, API keys)

Question 2: "What authentication level is required?"
Options:
  • Public (no authentication required)
  • Authenticated (logged-in users only) [Recommended]
  • Role-based (specific permissions required)

Question 3: "What compliance standards apply?"
Multi-select:
  □ None
  □ GDPR (EU data protection)
  □ PCI-DSS (payment card industry)
  □ HIPAA (healthcare)
  □ SOC 2 (security controls)
```

**Smart recommendations based on Question 1:**
- If "Payment" selected → Recommend PCI-DSS
- If "Health" selected → Recommend HIPAA
- If "PII" selected → Recommend GDPR (if applicable)

### Step 7: Ask Reliability Questions

**Conditional logic:**

```javascript
// Skip if experimental feature
if (labels.includes('experimental') || labels.includes('test')) {
  console.log('ℹ️  Skipping reliability (experimental feature)');
  nfrs.reliability = { skipped: true, reason: 'Experimental feature' };
}
```

**Otherwise ask:**

```
Question 1: "What is the acceptable downtime per year?"
Options:
  • 4 hours/year - 99.95% uptime (mission-critical)
  • 8 hours/year - 99.9% uptime (production) [Recommended]
  • 1 day/year - 99.7% uptime (standard)
  • Best effort (no SLA)

Question 2: "What error rate is acceptable?"
Options:
  • <0.1% (near-perfect)
  • <1% (production-quality) [Recommended]
  • <5% (acceptable)
  • No specific constraint

Question 3: "What monitoring and alerting is needed?"
Options:
  • None (no monitoring)
  • Basic (error alerts only)
  • Comprehensive (errors + metrics + dashboards) [Recommended]
```

### Step 8: Ask Cost Questions

**Conditional logic:**

```javascript
// Skip if using existing infrastructure
if (body.includes('existing infrastructure') || body.includes('no new services')) {
  console.log('ℹ️  Skipping cost (using existing infrastructure)');
  nfrs.cost = { skipped: true, reason: 'Existing infrastructure' };
}
```

**Otherwise ask:**

```
Question 1: "What are the budget constraints for this feature?"
Options:
  • Minimize cost (prioritize cheapest solution)
  • Standard/balanced (cost-performance balance) [Recommended]
  • Premium (prioritize performance over cost)

Question 2: "Which AWS services are preferred for this feature?"
Multi-select:
  □ Lambda (serverless compute)
  □ ECS/Fargate (container compute)
  □ DynamoDB (NoSQL database)
  □ RDS (SQL database)
  □ S3 (object storage)
  □ CloudFront (CDN)
  □ API Gateway
  □ No preference

Default: Lambda, DynamoDB, S3
```

### Step 9: Append NFRs to Active Story

**Read existing story:**
```javascript
const story = JSON.parse(fs.readFileSync('.claude/active-story.json', 'utf-8'));
```

**Merge NFR data:**
```javascript
story.nfrs = {
  performance: {
    dailyActiveUsers: "1000-10000",
    maxResponseTime: "<2s",
    concurrentUsers: "100-1000"
  },
  scalability: {
    growthProjection: "2x in 6 months",
    geographic: "US-only",
    peakPatterns: "9am-5pm weekdays, month-end spikes"
  },
  data: {
    dataRetention: "1 year",
    dataVolumePerUser: "1-10MB",
    backupSLA: "Daily backup with 7-day retention"
  },
  security: {
    sensitiveData: ["PII", "payment"],
    authentication: "authenticated-only",
    compliance: ["PCI-DSS", "GDPR"]
  },
  reliability: {
    acceptableDowntime: "8 hours/year (99.9%)",
    errorRate: "<1%",
    monitoring: "Comprehensive"
  },
  cost: {
    budget: "standard",
    preferredServices: ["Lambda", "DynamoDB", "S3"]
  }
};
```

**Write updated story:**
```javascript
fs.writeFileSync('.claude/active-story.json', JSON.stringify(story, null, 2));
```

### Step 10: Report Summary

**Output:**

```
✓ Non-Functional Requirements Collected

Performance:
  • Daily Active Users: 1,000-10,000
  • Max Response Time: <2s
  • Concurrent Users: 100-1,000

Scalability:
  • Growth Projection: 2x in 6 months
  • Geographic: US-only
  • Peak Patterns: 9am-5pm weekdays, month-end spikes

Data & Storage:
  • Data Retention: 1 year
  • Data Volume per User: 1-10MB
  • Backup SLA: Daily backup with 7-day retention

Security:
  • Sensitive Data: PII, Payment
  • Authentication: Authenticated-only
  • Compliance: PCI-DSS, GDPR

Reliability:
  • Acceptable Downtime: 8 hours/year (99.9%)
  • Error Rate: <1%
  • Monitoring: Comprehensive

Cost:
  • Budget: Standard/balanced
  • Preferred Services: Lambda, DynamoDB, S3

✓ NFRs saved to .claude/active-story.json

Next steps:
  Run /gather-context to collect technical context
  Or run /play-story to continue the full workflow
```

## Error Handling

### No Active Story

**Detection:**
```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.claude/active-story.json"
if [ ! -f "$STORY_FILE" ]; then
  # No active story file
fi
```

**Error message:**
```
❌ No active story found

Please run /fetch-story first to select a story.

Or run /play-story to execute the full workflow.
```

### Active Story Already Has NFRs

**Detection:**
```javascript
const story = JSON.parse(fs.readFileSync('.claude/active-story.json', 'utf-8'));
if (story.nfrs && Object.keys(story.nfrs).length > 0) {
  // NFRs already exist
}
```

**Warning:**
```
⚠️  NFRs already exist for this story

Current NFRs:
  • Performance: 1000-10000 daily users, <2s response
  • Security: PII + Payment, Authenticated-only
  • ... (abbreviated summary)

Options:
  [1] Keep existing NFRs (cancel)
  [2] Re-collect NFRs (overwrite existing)
  [3] View full existing NFRs

Choice:
```

### File Write Failed

**Detection:**
```javascript
try {
  fs.writeFileSync('.claude/active-story.json', ...);
} catch (error) {
  // Write failed
}
```

**Error message:**
```
❌ Failed to save NFRs to .claude/active-story.json

Error: [error message]

Possible causes:
- File permissions issue
- Disk full
- File locked by another process

Please check file permissions and try again.
```

## Question Strategy

### Recommendation Logic

**For public-facing features:**
```javascript
if (labels.includes('public') || labels.includes('external')) {
  // Recommend higher thresholds
  recommendDailyUsers = "10,000+";
  recommendResponseTime = "<500ms";
  recommendConcurrentUsers = "1,000+";
}
```

**For internal tools:**
```javascript
if (labels.includes('internal') || labels.includes('admin')) {
  // Recommend lower thresholds
  recommendDailyUsers = "100-1,000";
  recommendResponseTime = "<2s";
  recommendConcurrentUsers = "10-100";
}
```

**For payment features:**
```javascript
if (labels.includes('payment') || title.includes('payment') || title.includes('checkout')) {
  // Recommend security compliance
  recommendCompliance = ["PCI-DSS", "GDPR"];
  recommendMonitoring = "Comprehensive";
  recommendErrorRate = "<0.1%";
}
```

### Smart Skipping

**Skip entire categories when:**

| Category | Skip Condition | Message |
|----------|----------------|---------|
| Performance | label="batch-job" | "Batch job detected - performance constraints not applicable" |
| Scalability | label="poc" or "prototype" | "POC/prototype - scalability not needed yet" |
| Data & Storage | label="read-only" | "Read-only feature - data storage not applicable" |
| Security | Never skip | Always ask |
| Reliability | label="experimental" | "Experimental feature - reliability SLAs not needed" |
| Cost | body contains "existing infrastructure" | "Using existing infrastructure - no new cost considerations" |

**Still collect minimal data for skipped categories:**
```json
{
  "performance": {
    "skipped": true,
    "reason": "Batch job - no user interaction"
  }
}
```

### Multi-Select vs Single-Select

**Use multi-select for:**
- Sensitive data types (user may handle multiple types)
- Compliance standards (multiple may apply)
- Preferred AWS services (hybrid architectures common)

**Use single-select for:**
- Daily active users (single answer)
- Response time (single threshold)
- Authentication level (single requirement)
- Budget constraints (single priority)

### Text Input Questions

**Use sparingly:**
- Peak usage patterns (free-form description useful)
- Any other truly open-ended requirement

**Provide good defaults:**
- "Standard business hours (9am-5pm)"
- "No specific patterns"

## Integration with Other Skills

### Called by /play-story

```
/play-story
  ↓
1. /fetch-story → Get story
2. /gather-nfr → Collect NFRs (this skill)
3. /gather-context → Collect technical context
4. /create-adr → Generate ADR
```

### Output Used by Other Skills

**By /create-adr:**
- NFRs become "Decision Drivers" in ADR
- Security compliance informs technology choices
- Performance/scalability constraints guide architecture decisions

**By /gather-context:**
- Security requirements guide context search (look for auth patterns)
- Preferred services guide code analysis (find Lambda examples)

## Best Practices

### Question Design

**✅ Good questions:**
- Clear, unambiguous options
- Reasonable defaults/recommendations
- Contextual (tailored to story)
- Multiple choice when possible

**❌ Bad questions:**
- Vague or open-ended without guidance
- Too many options (analysis paralysis)
- Generic (not story-specific)

### Response Handling

**✅ Good practices:**
- Store responses in structured format
- Include context (why was this chosen?)
- Allow "N/A" or "No constraint" options

**❌ Bad practices:**
- Free-form text without validation
- No default/skip options
- Forcing answers when not applicable

### Category Balance

**Ask just enough:**
- 2-3 questions per category
- Skip irrelevant categories
- Total ~10-15 questions (not 30+)

**Respect user time:**
- Pre-select sensible defaults
- Allow bulk "Standard" responses
- Explain why each question matters

## Example Session

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
  • <5 seconds
  • No specific constraint

Your answer: <500ms

Q3: What concurrent user load should the system handle?
  • <10
  • 10-100
  • 100-1,000 [Recommended]
  • 1,000+

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

Your answers: Payment information, PII

Q2: What authentication level is required?
  • Public
  • Authenticated [Recommended]
  • Role-based

Your answer: Authenticated

Q3: What compliance standards apply?
  [Multi-select]
  ☑ PCI-DSS [Recommended for payment data]
  ☑ GDPR [Recommended for PII]
  ☐ HIPAA
  ☐ SOC 2

Your answers: PCI-DSS, GDPR

✓ Non-Functional Requirements Collected

[Summary output...]

✓ NFRs saved to .claude/active-story.json

Next steps:
  Run /gather-context to collect technical context
```

## Summary

The `/gather-nfr` skill streamlines NFR collection by:

✅ **Intelligent questioning** - Tailors questions to story context
✅ **Smart defaults** - Recommends sensible values based on labels
✅ **Category skipping** - Avoids irrelevant questions
✅ **Structured storage** - Saves NFRs in reusable format
✅ **ADR-ready** - Output directly feeds into decision records

Use `/gather-nfr` to capture requirements that guide architectural decisions!
