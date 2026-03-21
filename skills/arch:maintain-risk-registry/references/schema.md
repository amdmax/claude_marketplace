# Risk Registry Schema

## YAML Structure

```yaml
# Project Risk Registry
# scope: project = persistent, applies across all stories
#        story   = scoped to one issue (storyRef required)
# status: open | mitigated

risks:
  - id: RISK-001
    scope: project
    storyRef: null
    type: business          # business | implementation | security
    description: "Single sentence describing the risk"
    status: open
    mitigation: null

  - id: RISK-002
    scope: story
    storyRef: ISSUE-157
    type: implementation
    description: "Lambda@Edge bundle size may exceed 1MB if all dependencies are bundled"
    status: mitigated
    mitigation: "Switched to local.tryBundle() with tree-shaking; final bundle 340KB"
```

## Field Reference

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `id` | string | yes | `RISK-NNN` (3-digit zero-padded) |
| `scope` | enum | yes | `project` \| `story` |
| `storyRef` | string\|null | yes | Issue ref if story-scoped; `null` otherwise |
| `type` | enum | yes | `business` \| `implementation` \| `security` |
| `description` | string | yes | One line, plain English |
| `status` | enum | yes | `open` \| `mitigated` |
| `mitigation` | string\|null | yes | Free text when mitigated; `null` when open |

## Scope Distinction

**Project-level risks** (`scope: project`, `storyRef: null`):
- Persistent architectural or business risks
- Reviewed at the start of every story design
- Examples: "No automated rollback for deployments", "Third-party API rate limits"

**Story-level risks** (`scope: story`, `storyRef: ISSUE-NNN`):
- Risks specific to one story's implementation
- Written by architect during design
- Archived but not deleted after story closes

## Auto-Incrementing IDs

To find the next ID:
```bash
grep '  - id: RISK-' {{REGISTRY_DIR}}/risks.yaml | tail -1 | grep -o '[0-9]*$'
# Increment that number by 1 and zero-pad to 3 digits
```

## Bootstrap Template

If `{{REGISTRY_DIR}}/risks.yaml` does not exist, create it with:

```yaml
# Project Risk Registry
# Maintained by: architect agent + human review
# Updated: on each story design

risks: []
```
