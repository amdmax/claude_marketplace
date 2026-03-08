# Constraints Registry Schema

## YAML Structure

```yaml
# Project Constraints Registry
# enforcement: hard = blocking (must escalate to PM if a story would violate)
#              soft = advisory (can override with PM approval + ADR entry)
# Never delete entries — demote enforcement to soft with updated rationale if relaxed.

constraints:
  - id: CONST-001
    category: cloud
    rule: "Only use AWS services for all infrastructure and compute"
    rationale: "Existing infrastructure, team expertise, and tooling (CDK) are AWS-native"
    enforcement: hard

  - id: CONST-002
    category: licensing
    rule: "Do not introduce GPL or AGPL licensed dependencies"
    rationale: "GPL/AGPL copyleft may require open-sourcing proprietary source code"
    enforcement: hard

  - id: CONST-003
    category: architecture
    rule: "Prefer serverless functions for infrequent or short-lived compute over containers"
    rationale: "Cost and operational simplicity; no always-on resources for low-traffic workloads"
    enforcement: soft

  - id: CONST-004
    category: security
    rule: "No hardcoded secrets, API keys, or credentials in source code"
    rationale: "Secrets must be stored in a secrets manager or environment-specific config"
    enforcement: hard
```

## Field Reference

| Field | Type | Required | Values |
|-------|------|----------|--------|
| `id` | string | yes | `CONST-NNN` (3-digit zero-padded) |
| `category` | enum | yes | See categories below |
| `rule` | string | yes | One sentence, imperative form, plain English |
| `rationale` | string | yes | Why this constraint exists |
| `enforcement` | enum | yes | `hard` \| `soft` |

## Categories

| Category | Description |
|----------|-------------|
| `cloud` | Cloud provider, region, or service selection rules |
| `licensing` | Open source license and dependency restrictions |
| `security` | Security posture, secrets management, auth patterns |
| `architecture` | Structural and design pattern constraints |
| `process` | Development workflow, tooling, or team process rules |

## Enforcement Levels

**Hard (`enforcement: hard`)**:
- Non-negotiable — architect must escalate to PM if a story design would require violating one
- PM relays to human for a decision; do not proceed until resolved
- Example: "Only use AWS" — switching to GCP cannot happen silently

**Soft (`enforcement: soft`)**:
- Strong preference — can be overridden with PM approval
- Override must be documented in the story's ADR with rationale
- Example: "Prefer serverless over containers" — containers may be chosen if workload pattern justifies it

## Auto-Incrementing IDs

```bash
grep '  - id: CONST-' {{REGISTRY_DIR}}/constraints.yaml | tail -1 | grep -o '[0-9]*$'
# Increment by 1, zero-pad to 3 digits
```

## Bootstrap Template

If `{{REGISTRY_DIR}}/constraints.yaml` does not exist, create it with:

```yaml
# Project Constraints Registry
# Maintained by: architect agent + human review
# Hard constraints are blocking. Soft constraints require ADR entry to override.

constraints: []
```
