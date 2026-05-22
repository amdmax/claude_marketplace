# NFR Categories - Detailed Reference

## 1. Performance

| Question | Response Type | Default |
|----------|---------------|---------|
| Expected daily active users? | Choice: [<100, 100-1000, 1000-10000, 10000+] | 100-1000 |
| Maximum acceptable response time? | Choice: [<500ms, <1s, <2s, <5s, No constraint] | <2s |
| Concurrent user load estimate? | Choice: [<10, 10-100, 100-1000, 1000+] | 10-100 |

**When to ask:** Always for user-facing features. Skip for backend batch jobs.

**Example responses:**
```json
{ "dailyActiveUsers": "1000-10000", "maxResponseTime": "<2s", "concurrentUsers": "100-1000" }
```

## 2. Scalability

| Question | Response Type | Default |
|----------|---------------|---------|
| User growth projection (6 months)? | Choice: [No growth, 2x, 5x, 10x+] | 2x |
| Geographic distribution? | Choice: [Single region (US), Multi-region, Global] | Single region |
| Peak usage patterns? | Text input | "Standard business hours" |

**When to ask:** For features with significant growth. Skip for internal tools or POCs.

**Example responses:**
```json
{ "growthProjection": "2x in 6 months", "geographic": "US-only", "peakPatterns": "9am-5pm weekdays, spikes during month-end" }
```

## 3. Data & Storage

| Question | Response Type | Default |
|----------|---------------|---------|
| Data retention requirements? | Choice: [7 days, 30 days, 1 year, 7 years, Indefinite] | 1 year |
| Estimated data volume per user? | Choice: [<1MB, 1-10MB, 10-100MB, >100MB] | 1-10MB |
| Backup/recovery SLAs? | Choice: [No backup, Daily backup, Real-time replication] | Daily backup |

**When to ask:** For features that create or modify data. Skip for read-only/stateless.

**Example responses:**
```json
{ "dataRetention": "1 year", "dataVolumePerUser": "1-10MB", "backupSLA": "Daily backup with 7-day retention" }
```

## 4. Security

| Question | Response Type | Default |
|----------|---------------|---------|
| Sensitive data types? | Multi-select: [None, PII, Payment, Health, Credentials] | None |
| Authentication requirements? | Choice: [Public, Authenticated, Role-based] | Authenticated |
| Compliance needs? | Multi-select: [None, GDPR, PCI-DSS, HIPAA, SOC 2] | None |

**When to ask:** Always — never skip.

**Example responses:**
```json
{ "sensitiveData": ["PII", "payment"], "authentication": "authenticated-only", "compliance": ["PCI-DSS", "GDPR"] }
```

## 5. Reliability

| Question | Response Type | Default |
|----------|---------------|---------|
| Acceptable downtime? | Choice: [4h/yr (99.95%), 8h/yr (99.9%), 1d/yr, Best effort] | 8h/yr |
| Error rate tolerance? | Choice: [<0.1%, <1%, <5%, No constraint] | <1% |
| Monitoring/alerting needs? | Choice: [None, Basic (errors only), Comprehensive] | Basic |

**When to ask:** For production features. Skip for dev/testing features.

**Example responses:**
```json
{ "acceptableDowntime": "8 hours/year (99.9%)", "errorRate": "<1%", "monitoring": "Comprehensive" }
```

## 6. Cost

| Question | Response Type | Default |
|----------|---------------|---------|
| Budget constraints? | Choice: [Minimize cost, Standard/balanced, Premium] | Standard |
| Preferred AWS services? | Multi-select: [Lambda, ECS, DynamoDB, RDS, S3, CloudFront] | Lambda, DynamoDB |

**When to ask:** For features with significant new infrastructure. Skip if using existing.

**Example responses:**
```json
{ "budget": "standard", "preferredServices": ["Lambda", "DynamoDB", "S3"] }
```
