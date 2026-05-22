---
name: arch:gather-nfr
description: Collect non-functional requirements through interactive Q&A. Asks targeted questions about performance, scalability, security, reliability, and cost constraints. Invokable with /gather-nfr.
---

# Gather Non-Functional Requirements

## Overview

This skill collects Non-Functional Requirements (NFRs) through an interactive questionnaire. It:

1. **Reads active story** from `.agile-dev-team/active-story.yaml`
2. **Analyzes story context** (title, labels, body) to tailor questions
3. **Asks targeted questions** across 6 NFR categories
4. **Collects responses** using AskUserQuestion tool
5. **Appends NFRs** to `.agile-dev-team/active-story.yaml` for later use

NFRs inform architectural decisions, implementation choices, and ADR content.

## NFR Categories

| Category | Always Ask? | Key Questions |
|----------|-------------|---------------|
| Performance | User-facing features | DAU, response time, concurrency |
| Scalability | Growth expected | Growth projection, geography, peaks |
| Data & Storage | Creates/modifies data | Retention, volume, backup SLA |
| Security | **Always** | Sensitive data, auth, compliance |
| Reliability | Production features | Downtime SLA, error rate, monitoring |
| Cost | New infrastructure | Budget, preferred AWS services |

See `@references/nfr-categories.md` for detailed question tables and example responses.

## Workflow

### Step 1: Verify Active Story Exists

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.yaml"
if [ ! -f "$STORY_FILE" ]; then
  echo "❌ No active story found. Run /fetch-story first."
  exit 1
fi
```

### Step 2: Load and Analyze Story Context

```javascript
const story = yaml.load(fs.readFileSync('.agile-dev-team/active-story.yaml', 'utf-8'));
const title = story.title.toLowerCase();
const labels = story.labels.map(l => l.toLowerCase());
const body = story.body.toLowerCase();
```

**Determine applicable categories:**

| Category | Skip if label contains... |
|----------|--------------------------|
| Performance | "internal-tool" |
| Scalability | "poc" or "prototype" |
| Data & Storage | "read-only" |
| Security | Never skip |
| Reliability | "experimental" |
| Cost | Body mentions "existing infrastructure" |

### Steps 3–8: Ask Category Questions

See `@references/workflow-questions.md` for the exact question text, options, defaults, and skip conditions for each category (Performance, Scalability, Data & Storage, Security, Reliability, Cost).

### Step 9: Append NFRs to Active Story

```javascript
story.nfrs = {
  performance: { dailyActiveUsers: "...", maxResponseTime: "...", concurrentUsers: "..." },
  scalability: { growthProjection: "...", geographic: "...", peakPatterns: "..." },
  data:        { dataRetention: "...", dataVolumePerUser: "...", backupSLA: "..." },
  security:    { sensitiveData: [...], authentication: "...", compliance: [...] },
  reliability: { acceptableDowntime: "...", errorRate: "...", monitoring: "..." },
  cost:        { budget: "...", preferredServices: [...] }
};
fs.writeFileSync('.agile-dev-team/active-story.yaml', yaml.dump(story));
```

### Step 10: Report Summary

```
✓ Non-Functional Requirements Collected

Performance:  <DAU> DAU, <response time>, <concurrency>
Scalability:  <growth>, <geography>, <peak patterns>
Data:         <retention>, <volume/user>, <backup SLA>
Security:     <sensitive data>, <auth>, <compliance>
Reliability:  <downtime SLA>, <error rate>, <monitoring>
Cost:         <budget>, <preferred services>

✓ NFRs saved to .agile-dev-team/active-story.yaml

Next steps:
  Run /gather-context to collect technical context
  Or run /play-story to continue the full workflow
```

## Error Handling

See `@references/error-handling.md` for: no active story, NFRs already exist (overwrite prompt), and file write failures.

## Question Strategy

See `@references/question-strategy.md` for recommendation logic per label, smart skipping rules, multi-select vs single-select guidance, and question count targets.

## Integration with Other Skills

### Called by /play-story

```
/play-story → /fetch-story → /gather-nfr (this) → /gather-context → /arch:create-adr
```

### Output Used by Other Skills

- **`/arch:create-adr`** — NFRs become Decision Drivers; security/compliance guides technology choices
- **`/gather-context`** — security requirements and preferred services guide code search

## Best Practices

- 2-3 questions per category; skip irrelevant ones (target ~10-15 total)
- Pre-select sensible defaults — respect user time
- Use multiple choice whenever possible; text input sparingly
- Include "N/A" or "No constraint" options
- Store skipped categories as `{ skipped: true, reason: "..." }`

## Example Session

See `@references/example-session.md` for a complete walkthrough of `/gather-nfr` on a payment checkout story.

## Summary

The `/gather-nfr` skill streamlines NFR collection by:

- **Intelligent questioning** — tailors questions to story context and labels
- **Smart defaults** — recommends sensible values based on feature type
- **Category skipping** — avoids irrelevant questions
- **Structured storage** — saves NFRs in reusable YAML format
- **ADR-ready** — output directly feeds into decision records
