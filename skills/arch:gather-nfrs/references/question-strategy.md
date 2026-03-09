# Question Strategy

## Label-Based Recommendation Overrides

Applied in Step 3 (Performance) to shift defaults before presenting options:

| Label/context | Override |
|---------------|---------|
| `public`, `external` | dailyUsers → `10,000+`, responseTime → `<500ms`, concurrent → `1,000+` |
| `internal`, `admin` | dailyUsers → `100–1,000`, responseTime → `<2s`, concurrent → `10–100` |
| `payment`, title contains "payment"/"checkout" | compliance → PCI-DSS + GDPR, monitoring → Comprehensive, errorRate → `<0.1%` |

## Multi-Select vs Single-Select

**Multi-select** (user may choose several):
- Sensitive data types
- Compliance standards
- Preferred AWS services

**Single-select** (one answer required):
- Daily active users
- Max response time
- Concurrent users
- Geographic distribution
- Authentication level
- Budget priority
- Acceptable downtime
- Error rate
- Monitoring level

## Text Input

Use only for peak usage patterns — free-form is genuinely useful here. Provide default: `"Standard business hours (9am–5pm)"`. For all other questions prefer structured options to avoid open-ended noise.

## Question Count Target

2–3 questions per category. Skip irrelevant categories entirely. Total should be 10–15 questions per session, not 30+. Pre-select sensible defaults so users can confirm quickly rather than deliberating.
