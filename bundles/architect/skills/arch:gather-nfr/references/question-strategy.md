# Question Strategy

## Recommendation Logic

**Public-facing features** (`public`/`external` label):
```javascript
recommendDailyUsers = "10,000+";
recommendResponseTime = "<500ms";
recommendConcurrentUsers = "1,000+";
```

**Internal tools** (`internal`/`admin` label):
```javascript
recommendDailyUsers = "100-1,000";
recommendResponseTime = "<2s";
recommendConcurrentUsers = "10-100";
```

**Payment features** (`payment` label or title):
```javascript
recommendCompliance = ["PCI-DSS", "GDPR"];
recommendMonitoring = "Comprehensive";
recommendErrorRate = "<0.1%";
```

## Smart Skipping

| Category | Skip Condition |
|----------|----------------|
| Performance | label="batch-job" |
| Scalability | label="poc" or "prototype" |
| Data & Storage | label="read-only" |
| Security | **Never skip** |
| Reliability | label="experimental" |
| Cost | body contains "existing infrastructure" |

Skipped categories store: `{ "skipped": true, "reason": "..." }`

## Multi-Select vs Single-Select

**Multi-select:** sensitive data types, compliance standards, preferred AWS services (multiple may apply).

**Single-select:** daily active users, response time, authentication level, budget constraints (single threshold/priority).

**Text input:** peak usage patterns (truly open-ended). Provide sensible defaults.

## Question Count

- 2-3 questions per category
- Skip irrelevant categories
- Target ~10-15 total questions (not 30+)
- Pre-select sensible defaults to respect user time
