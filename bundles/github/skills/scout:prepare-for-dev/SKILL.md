---
name: scout:prepare-for-dev
author: "@amdmax"
description: Pre-implementation scout agent. Analyzes a "Ready for Dev" GitHub story in read-only mode — blast radius, architecture review, ADR check, task list, infra question resolution. Writes YAML report to docs/stories/{id}/. Invokable with /scout:prepare-for-dev [issue_number].
---

# Ready for Dev Scout

Runs read-only reconnaissance on a story before implementation starts. Produces a structured report answering: what files change, what architecture governs the work, what tasks need doing and in what order, and what open questions can be resolved now.

**Invocation:**
```bash
/scout:prepare-for-dev 460    # Scout a specific issue
/scout:prepare-for-dev        # Uses active-story.json issue number
```

## Constraints

- **Read-only** for all source code, tests, infrastructure, and config
- Write only under `docs/stories/{id}/` and `docs/adr/`
- Do not change issue status to In Progress
- Do not create implementation branches
- If a bug is found during recon, record it in Open Questions — do not fix it

## Workflow (11 Steps)

### Step 1 — Resolve issue number

```bash
# From argument
ISSUE_NUMBER=460

# Or from active story
ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json)
REPOSITORY=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
OUTPUT_DIR="docs/stories/${ISSUE_NUMBER}"
mkdir -p "$OUTPUT_DIR"
```

Then fetch:
```bash
gh issue view $ISSUE_NUMBER --repo $REPOSITORY --json title,body,labels,comments,url
```

**Guard — verify "ready for dev" label before proceeding:**
```bash
LABELS=$(gh issue view $ISSUE_NUMBER --repo $REPOSITORY --json labels --jq '[.labels[].name]')
if ! echo "$LABELS" | grep -q "ready for dev"; then
  echo "⛔ Scout aborted: issue #$ISSUE_NUMBER does not have the 'ready for dev' label."
  echo "Run the story-review workflow first. Current labels: $LABELS"
  exit 1
fi
```

If the label is missing, stop here and tell the user to run story-review first.

### Step 2 — Extract from the issue

- Business objective
- Acceptance criteria
- Named modules, services, APIs, data stores
- Constraints mentioned

### Step 3 — Repository reconnaissance

Search for domain terms extracted in Step 2 across `src/`, `lambda/`, `infrastructure/`, `content/`:

```bash
rg "<term>" --type ts -l
rg "<term>" --type md -l
```

Use multiple terms. Look for existing components, handlers, tests, and templates with similar behavior.

### Step 4 — Read context files

- `CLAUDE.md` files in any directories that appeared in Step 3
- Registry files via `/arch:maintain-constraints-registry`, `/arch:maintain-nfr-registry`, `/arch:maintain-risk-registry`
- `ls docs/adr/` — then read ADRs relevant to this story's domain

### Step 5 — Build blast radius (three tiers)

- **Directly affected** — files that must change to implement the story
- **Likely affected** — callers, tests, config that may need updates
- **Validate only** — infra or adjacent modules to verify nothing is broken

### Step 6 — Architecture review

- List ADRs from Step 4 that govern patterns relevant to this story
- Assess whether they are sufficient for implementation
- Apply ADR creation decision rules (see `/create-adr`):

  **Create** a new ADR draft only if ONE OR MORE of these is true:
  - A new service or technology is being introduced
  - Multiple valid architectural approaches exist with meaningful trade-offs
  - An existing architectural decision may be changed or superseded
  - The change creates a lasting cross-cutting constraint

  **Skip** a new ADR when:
  - The story is a straightforward application of an existing pattern
  - The decision is local and short-lived
  - The change is UI-only or implementation-detail level

### Step 7 — ADR creation (conditional)

If a new ADR is warranted, use `/create-adr` for MADR format and auto-numbering:

```bash
# Find next ADR number
ls docs/adr/ 2>/dev/null | grep -o "^[0-9]*" | sort -n | tail -1
# Increment and zero-pad to 4 digits (start at 0001 if empty)
```

File: `docs/adr/{NNNN}-{slug}.md` with `status: proposed`.

If no ADR is needed, record the governing document reference instead.

### Step 8 — Resolve infrastructure open questions

After collecting open questions from Steps 2–7, identify any that relate to infrastructure or cloud resources.

**Detect infra stack:**
```bash
# AWS
aws sts get-caller-identity 2>/dev/null && INFRA=aws
# GCP
gcloud config get-value project 2>/dev/null && INFRA=gcp
# Check IaC files
ls infrastructure/ cdk.json terraform/ 2>/dev/null
```

**For each infra open question**, attempt to answer it using the detected CLI:

| Stack | Example resolution commands |
|---|---|
| AWS | `aws lambda list-functions`, `aws s3 ls`, `aws cloudformation describe-stacks`, `aws ssm get-parameter`, `aws iam get-role` |
| GCP | `gcloud functions list`, `gcloud run services list`, `gcloud projects describe` |
| Generic | Read `infrastructure/` CDK/Terraform files for resource definitions |

For each question:
- Run the relevant CLI command(s) read-only
- If answered: record the answer inline and mark resolved
- If unanswerable (permissions, missing resource): keep in Open Questions with the attempted command and error

### Step 9 — Write scout report

Write `docs/stories/<N>/scout.yaml` in YAML format (compact, token-efficient):

```yaml
scout:
  issue: <N>
  title: "<issue title>"
  scouted: "<YYYY-MM-DD>"

  change_list:
    - file: path/to/file.ts
      tier: directly_affected   # directly_affected | likely_affected | validate_only
      reason: "why it must change"

  dependencies:
    - name: "SymbolOrService"
      path: path/to/file.ts
      reached_via: "brief description"
      confidence: high   # high | medium | low

  architecture:
    governing_adrs:
      - docs/adr/0001-slug.md
    sufficient: true
    new_adr: null   # or: docs/adr/NNNN-slug.md

  tasks:
    - id: 1
      task: "description"
      status: pending   # pending | done | blocked
      depends_on: []
    - id: 2
      task: "description"
      status: blocked
      depends_on: [1]

  open_questions:
    - id: 1
      question: "question text"
      owner: product   # product | architecture | implementer
      infra_resolution: null
    - id: 2
      question: "infra question"
      owner: implementer
      infra_resolution:
        command: "aws lambda list-functions"
        result: "resolved answer or permission denied"
        resolved: true

  next_actions:
    - "First step for the implementer"
    - "Second step"
```

### Step 10 — Post GitHub comment

Check for existing `<!-- scout-report -->` comment; update if found, create if not:

```bash
gh issue view $ISSUE_NUMBER --json comments
# edit last if found, else:
gh issue comment $ISSUE_NUMBER --body "<!-- scout-report -->
## Scout Report Summary

**Directly affected:** N files | **Likely affected:** N files | **Tasks:** N | **Open questions:** N

Full report: docs/stories/<N>/scout.yaml
[**ADR draft:** docs/adr/NNNN-slug.md]          # include if proposed
[**Architecture review needed** before coding.]   # include if applicable"
```

### Step 11 — Apply labels

**Labels to apply:**

```bash
gh issue edit $ISSUE_NUMBER --add-label "scouted"
# Conditional:
gh issue edit $ISSUE_NUMBER --add-label "architecture-review-needed"  # if true
gh issue edit $ISSUE_NUMBER --add-label "adr-proposed"                # if true
```

## Output Files

| File | Description |
|------|-------------|
| `docs/stories/<N>/scout.yaml` | Full scout report (YAML, token-efficient) |
| `docs/adr/{NNNN}-{slug}.md` | ADR draft (only if warranted) |

## Scout Blocked Conditions

Set `scout_blocked: true` and populate `blocked_reason` when:

- Story is too vague to map to code
- Multiple plausible implementation paths exist with no governing decision
- Required architecture context is missing
- Dependency traversal is inconclusive

Still write the partial report. Post a comment explaining what blocked the scout and what follow-up is needed before implementation can start.

## Related Skills

- `/create-adr` — MADR format, ADR auto-numbering, create-vs-skip rules
- `/arch:maintain-constraints-registry` — read/update project constraints
- `/arch:maintain-nfr-registry` — read/update NFR registry
- `/arch:maintain-risk-registry` — read/update risk registry
- `/github:story-fetch` — populate `.agile-dev-team/active-story.json` from GitHub Projects

## Label State Transitions

```
Ready for Dev  →  scout-pending  (optional manual staging)
              ↓
         scouting               (workflow picks it up)
              ↓
           scouted              (report complete)
              + architecture-review-needed  (if arch decision required)
              + adr-proposed               (if ADR drafted)
```
