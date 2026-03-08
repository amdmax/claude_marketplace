# NFR Registry Schema

## YAML Structure

```yaml
# Non-Functional Requirements Registry
# scope: project = permanent, applies to all stories
#        story   = scoped to one issue (storyRef required)
# Project-level NFRs drive architect decisions on every story.
# Story-level NFRs refine or override project defaults for one story.

nfrs:
  - id: NFR-001
    scope: project
    storyRef: null
    category: security
    requirement: "All authenticated routes must validate tokens before serving content"
    rationale: "Prevents unauthorized access before content reaches the origin"

  - id: NFR-002
    scope: story
    storyRef: ISSUE-157
    category: performance
    requirement: "Catalog page must achieve Lighthouse performance score ≥ 90 on mobile"
    rationale: "Story AC-3 specifically targets mobile load time improvement"
```

## Field Reference

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `id` | string | yes | `NFR-NNN` (3-digit zero-padded) |
| `scope` | enum | yes | `project` \| `story` |
| `storyRef` | string\|null | yes | Issue ref if story-scoped; `null` otherwise |
| `category` | enum | yes | See categories below |
| `requirement` | string | yes | Testable, unambiguous statement |
| `rationale` | string | yes | Why this requirement exists |

## Categories

| Category | Examples |
|----------|---------|
| `performance` | Page load time, Lighthouse score, cold start latency |
| `security` | Auth, input validation, data encryption, IAM scope |
| `reliability` | Uptime, error rate, retry behaviour |
| `cost` | Max monthly cloud spend, API invocation budget |
| `scalability` | Concurrent users, throughput, burst handling |
| `maintainability` | Code complexity, test coverage thresholds |
| `accessibility` | WCAG level, screen reader support |

## Scope Distinction

**Project-level NFRs** (`scope: project`):
- Apply to every story by default
- Architect checks these when gathering context and maps applicable ones to the implementation brief
- Never deleted — only updated

**Story-level NFRs** (`scope: story`):
- Override or extend project NFRs for one specific story
- Added by architect during design when a story has exceptional requirements
- Reference the issue number in `storyRef`

## Auto-Incrementing IDs

```bash
grep '  - id: NFR-' {{REGISTRY_DIR}}/nfr-registry.yaml | tail -1 | grep -o '[0-9]*$'
# Increment by 1, zero-pad to 3 digits
```

## Bootstrap Template

If `{{REGISTRY_DIR}}/nfr-registry.yaml` does not exist, create it with:

```yaml
# Non-Functional Requirements Registry
# Maintained by: architect agent + human review
# Project-level NFRs apply to every story by default.

nfrs: []
```
