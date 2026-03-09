# NFR Questions by Category

Six categories, 2–3 questions each. Skip entire category when condition met (see SKILL.md Step 2).

---

## 1. Performance

| # | Question | Options | Default |
|---|----------|---------|---------|
| 1 | Daily active users? | `<100` / `100–1,000` / `1,000–10,000` / `10,000+` | `1,000–10,000` |
| 2 | Max acceptable response time? | `<500ms` / `<1s` / `<2s` / `<5s` / No constraint | `<2s` |
| 3 | Concurrent user load? | `<10` / `10–100` / `100–1,000` / `1,000+` | `10–100` |

Skip message: `"Batch job detected — performance constraints not applicable"`

---

## 2. Scalability

| # | Question | Options | Default |
|---|----------|---------|---------|
| 1 | User growth (6 months)? | No growth / `2x` / `5x` / `10x+` | `2x` |
| 2 | Geographic distribution? | Single region (US) / Multi-region / Global | Single region |
| 3 | Peak usage patterns? | *(text input)* | `"Standard business hours (9am–5pm)"` |

Skip message: `"POC/prototype — scalability not needed yet"`

---

## 3. Data & Storage

| # | Question | Options | Default |
|---|----------|---------|---------|
| 1 | Data retention? | `7 days` / `30 days` / `1 year` / `7 years` / Indefinite | `1 year` |
| 2 | Data volume per user? | `<1MB` / `1–10MB` / `10–100MB` / `>100MB` | `1–10MB` |
| 3 | Backup/recovery SLA? | No backup / Daily backup (7-day retention) / Real-time replication | Daily backup |

Skip message: `"Read-only feature — data storage not applicable"`

---

## 4. Security

**Never skip.**

| # | Question | Type | Options | Default |
|---|----------|------|---------|---------|
| 1 | Sensitive data types? | Multi-select | None / PII / Payment / Health / Credentials | None |
| 2 | Authentication level? | Single-select | Public / Authenticated / Role-based | Authenticated |
| 3 | Compliance standards? | Multi-select | None / GDPR / PCI-DSS / HIPAA / SOC 2 | None |

Auto-recommendations based on Q1:
- Payment selected → recommend PCI-DSS
- Health selected → recommend HIPAA
- PII selected → recommend GDPR

---

## 5. Reliability

| # | Question | Options | Default |
|---|----------|---------|---------|
| 1 | Acceptable downtime/year? | `4h (99.95%)` / `8h (99.9%)` / `1 day (99.7%)` / Best effort | `8h (99.9%)` |
| 2 | Error rate tolerance? | `<0.1%` / `<1%` / `<5%` / No constraint | `<1%` |
| 3 | Monitoring/alerting? | None / Basic (errors only) / Comprehensive (errors + metrics) | Basic |

Skip message: `"Experimental feature — reliability SLAs not needed"`

---

## 6. Cost

| # | Question | Type | Options | Default |
|---|----------|------|---------|---------|
| 1 | Budget priority? | Single-select | Minimize cost / Standard/balanced / Premium | Standard |
| 2 | Preferred AWS services? | Multi-select | Lambda / ECS / DynamoDB / RDS / S3 / CloudFront / API Gateway / No preference | Lambda, DynamoDB, S3 |

Skip message: `"Using existing infrastructure — no new cost considerations"`
