# NFR Output Schema

## Target file

`.agile-dev-team/technical-context.json` — merged under the `nfrs` key (existing keys preserved).

## JSON Structure

```json
{
  "nfrs": {
    "performance": {
      "dailyActiveUsers": "1,000–10,000",
      "maxResponseTime": "<2s",
      "concurrentUsers": "100–1,000"
    },
    "scalability": {
      "growthProjection": "2x in 6 months",
      "geographic": "US-only",
      "peakPatterns": "9am–5pm weekdays, month-end spikes"
    },
    "data": {
      "dataRetention": "1 year",
      "dataVolumePerUser": "1–10MB",
      "backupSLA": "Daily backup with 7-day retention"
    },
    "security": {
      "sensitiveData": ["PII", "payment"],
      "authentication": "authenticated-only",
      "compliance": ["PCI-DSS", "GDPR"]
    },
    "reliability": {
      "acceptableDowntime": "8 hours/year (99.9%)",
      "errorRate": "<1%",
      "monitoring": "Comprehensive"
    },
    "cost": {
      "budget": "standard",
      "preferredServices": ["Lambda", "DynamoDB", "S3"]
    }
  }
}
```

## Skipped category shape

```json
{
  "scalability": {
    "skipped": true,
    "reason": "POC/prototype — scalability not needed yet"
  }
}
```

## Merge logic

```javascript
let techContext = {};
try { techContext = JSON.parse(fs.readFileSync('.agile-dev-team/technical-context.json', 'utf-8')); } catch {}
techContext.nfrs = collectedNfrs;
fs.writeFileSync('.agile-dev-team/technical-context.json', JSON.stringify(techContext, null, 2));
```
