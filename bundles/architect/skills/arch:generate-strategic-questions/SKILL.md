---
name: arch:generate-strategic-questions
description: >
  Generates enterprise/org-level questions that must be answered before an implementation
  brief can be safely produced. Covers cloud infrastructure, security & compliance,
  architecture governance, team ownership, and cost/budget constraints. Skips questions
  already answered in existing ADRs or the NFR registry. Writes to
  agent-docs/stories/{issueNumber}/strategic-questions.yaml (created if absent).
argument-hint: "[issue_number]"
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Write
write-paths:
  - agent-docs/
---

# arch:generate-strategic-questions

Surfaces unknown enterprise and organisational constraints before the architect commits
to a design direction. Every question that remains unanswered is a risk that could
invalidate the implementation brief.

---

## Workflow

### Step 1 — Load story context

```bash
STORY_FILE=".agile-dev-team/active-story.yaml"
if [ ! -f "$STORY_FILE" ]; then
  echo "ERROR  No active story. Run /github:story-fetch first."
  exit 1
fi
ISSUE_NUMBER=$(grep 'issueNumber:' "$STORY_FILE" | awk '{print $2}')
OUTPUT_DIR="agent-docs/stories/${ISSUE_NUMBER}"
OUTPUT_PATH="${OUTPUT_DIR}/strategic-questions.yaml"
mkdir -p "$OUTPUT_DIR"
```

Read:
- `.agile-dev-team/active-story.yaml` — story title, issueNumber, ACs, NFRs
- `$ADR_DIR` — all existing ADRs (to avoid re-asking decided questions)
- `.agile-dev-team/nfr-registry.json` — existing NFRs (to avoid duplication)

### Step 2 — Analyse story scope

For each acceptance criterion and NFR, identify which strategic domains are touched:

| Domain touched | Category to generate questions for |
|---|---|
| New compute / storage / network resource | `cloud_infrastructure` |
| Handles PII, payments, auth, or regulated data | `security_compliance` |
| Introduces new service, pattern, or technology | `architecture_governance` |
| Creates a new component with runtime responsibilities | `org_ownership` |
| Adds always-on resources or increases data volume | `cost_budget` |

If a domain is not touched by any AC, skip it entirely.

### Step 3 — Generate questions

For each relevant category, generate targeted questions drawn from the catalogue below.
Include only questions whose answers are NOT already captured in existing ADRs or NFR registry.
Add `context` to each question explaining *which AC or NFR* prompted it.

#### Category: `cloud_infrastructure`

- What cloud provider is approved for this workload?
- Are there whitelisted or blacklisted services for this workload type?
- Which regions are approved for deployment?
- Is a multi-cloud or cloud-agnostic requirement in force?
- What IaC toolchain is mandated (CDK, Terraform, Pulumi)?
- Are there approved compute tiers or instance families?

#### Category: `security_compliance`

- What data classification applies to the data this story handles?
- Are there data residency or sovereignty requirements?
- Is encryption at rest mandatory? Which key management service?
- Is encryption in transit sufficient with TLS, or is mTLS required?
- Which compliance standards apply (GDPR, SOC 2, HIPAA, PCI-DSS)?
- Is a security review or penetration test required before go-live?
- Are there approved secret/credential management tools?

#### Category: `architecture_governance`

- Are there reference architectures or enterprise blueprints this story must follow?
- Is there an approved technology stack or whitelist for this domain?
- Are there banned libraries, frameworks, or patterns?
- Is there an API gateway or service mesh that all new services must integrate with?
- Are there event bus or messaging standards in place?

#### Category: `org_ownership`

- Which team or squad will own this component in production?
- Are there on-call or SLA requirements that constrain the design?
- Who is the escalation path for incidents involving this component?
- Is there a change management or release approval process to follow?

#### Category: `cost_budget`

- What is the monthly budget envelope for this component?
- Are there cost tagging or chargeback requirements?
- Is a FinOps or cost review gate required before deployment?
- Are reserved instances or savings plans available that should be preferred?

### Step 4 — Deduplicate against existing knowledge

Before writing, check each question:

```bash
# Check if topic is covered in any ADR
grep -r "QUESTION_TOPIC" "${ADR_DIR:-docs/adr}" 2>/dev/null
# Check if NFR already captures this constraint
grep "QUESTION_TOPIC" .agile-dev-team/nfr-registry.json 2>/dev/null
```

If an existing ADR or NFR fully answers a question, set `answer:` to the reference
(e.g. `"Covered by ADR-0003"`) rather than `null`.

### Step 5 — Write output

Write `agent-docs/stories/{issueNumber}/strategic-questions.yaml`:

```yaml
generated_at: "YYYY-MM-DD"
story: "{issueNumber} — {title}"
questions:
  - id: SQ-001
    category: cloud_infrastructure
    question: "What cloud provider is approved for this workload?"
    context: "AC-3 requires deploying a new Lambda function"
    answer: null

  - id: SQ-002
    category: security_compliance
    question: "What data classification applies to the payment data handled here?"
    context: "AC-1 introduces storage of payment method tokens"
    answer: null
```

IDs are sequential: `SQ-001`, `SQ-002`, …

If the file already exists, merge: preserve existing `answer:` values, append new questions,
re-sequence IDs.

### Step 6 — Report

```
arch:generate-strategic-questions: {N} questions written

  cloud_infrastructure  {n} questions
  security_compliance   {n} questions
  architecture_governance {n} questions
  org_ownership         {n} questions
  cost_budget           {n} questions

  {m} already answered (from ADRs / NFR registry)

Output: agent-docs/stories/{issueNumber}/strategic-questions.yaml
Next:   run /arch:generate-tactical-questions, then send scout to answer both files.
```

---

## Output

| File | Content |
|------|---------|
| `agent-docs/stories/{issueNumber}/strategic-questions.yaml` | Structured question list; `answer: null` for unanswered |

---

## Error Handling

| Condition | Behaviour |
|-----------|-----------|
| No active story | Error: run `/github:story-fetch` first |
| No ACs in story | Warn and generate only top-level governance questions |
| File already exists | Merge: preserve answers, append new questions |
