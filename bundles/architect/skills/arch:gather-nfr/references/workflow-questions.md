# Workflow Question Steps (3–8)

## Step 3: Performance Questions

```
Q1: "How many daily active users do you expect for this feature?"
  • <100 users (small internal tool)
  • 100-1,000 users (team/department tool)
  • 1,000-10,000 users (company-wide tool) [Recommended]
  • 10,000+ users (public-facing product)

Q2: "What is the maximum acceptable response time?"
  • <500ms (real-time, interactive)
  • <1 second (snappy, user-friendly)
  • <2 seconds (acceptable for most users) [Recommended]
  • <5 seconds (background operations)
  • No specific constraint

Q3: "What concurrent user load should the system handle?"
  • <10 / 10-100 [Recommended] / 100-1,000 / 1,000+
```

**Tailor recommendations:**
- `public` label → recommend higher thresholds
- `internal`/`admin` label → recommend lower thresholds

## Step 4: Scalability Questions

**Skip if POC/prototype:**
```javascript
if (labels.includes('poc') || labels.includes('prototype')) {
  nfrs.scalability = { skipped: true, reason: 'POC/prototype' };
}
```

**Otherwise ask:**
```
Q1: "What user growth do you project in the next 6 months?"
  • No significant growth / 2x [Recommended] / 5x / 10x+

Q2: "What geographic distribution is required?"
  • Single region (US only) [Recommended] / Multi-region (US + EU) / Global

Q3: "Describe peak usage patterns"
  Type: Text input  Default: "Standard business hours (9am-5pm)"
```

## Step 5: Data & Storage Questions

**Skip if read-only:**
```javascript
if (labels.includes('read-only') || title.includes('view') || title.includes('display')) {
  nfrs.data = { skipped: true, reason: 'Read-only feature' };
}
```

**Otherwise ask:**
```
Q1: "How long should data be retained?"
  • 7 days / 30 days / 1 year [Recommended] / 7 years / Indefinite

Q2: "What is the estimated data volume per user?"
  • <1MB / 1-10MB [Recommended] / 10-100MB / >100MB

Q3: "What backup and recovery SLAs are required?"
  • No backup / Daily backup with 7-day retention [Recommended] / Real-time replication
```

## Step 6: Security Questions (never skip)

```
Q1: "What types of sensitive data will this feature handle?"
  [Multi-select]: None / PII / Payment / Health / Credentials

Q2: "What authentication level is required?"
  • Public / Authenticated [Recommended] / Role-based

Q3: "What compliance standards apply?"
  [Multi-select]: None / GDPR / PCI-DSS / HIPAA / SOC 2
```

**Smart recommendations:**
- Payment selected → recommend PCI-DSS
- Health selected → recommend HIPAA
- PII selected → recommend GDPR

## Step 7: Reliability Questions

**Skip if experimental:**
```javascript
if (labels.includes('experimental') || labels.includes('test')) {
  nfrs.reliability = { skipped: true, reason: 'Experimental feature' };
}
```

**Otherwise ask:**
```
Q1: "What is the acceptable downtime per year?"
  • 4 hours/year (99.95%) / 8 hours/year (99.9%) [Recommended] / 1 day/year / Best effort

Q2: "What error rate is acceptable?"
  • <0.1% / <1% [Recommended] / <5% / No constraint

Q3: "What monitoring and alerting is needed?"
  • None / Basic (error alerts only) / Comprehensive (errors + metrics + dashboards) [Recommended]
```

## Step 8: Cost Questions

**Skip if using existing infrastructure:**
```javascript
if (body.includes('existing infrastructure') || body.includes('no new services')) {
  nfrs.cost = { skipped: true, reason: 'Existing infrastructure' };
}
```

**Otherwise ask:**
```
Q1: "What are the budget constraints for this feature?"
  • Minimize cost / Standard/balanced [Recommended] / Premium

Q2: "Which AWS services are preferred for this feature?"
  [Multi-select]: Lambda / ECS/Fargate / DynamoDB / RDS / S3 / CloudFront / API Gateway / No preference
  Default: Lambda, DynamoDB, S3
```
