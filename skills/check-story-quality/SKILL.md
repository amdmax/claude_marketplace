---
name: check-story-quality
description: Analyze GitHub Project stories for SMART acceptance criteria and NFR coverage. Applies labels and posts structured feedback comments. Can run as a scheduled background assistant or manually via /check-story-quality.
---

# Check Story Quality

## Overview

This skill evaluates stories in GitHub Projects against SMART acceptance criteria and system-wide NFR coverage. It operates asynchronously — no developer interaction required when run by the scheduled workflow.

**Entry points:**
- Scheduled: `story-quality-monitor.yml` (hourly, Mon-Fri)
- Manual: `/check-story-quality` (analyzes the active story or a specified issue)

---

## Workflow

### Step 1: Resolve Parameters

**When invoked by the scheduled workflow**, parameters are passed in the prompt:
```
GitHub Project owner: <owner>
GitHub Project number: <number>
```

**When invoked manually** (no parameters in prompt), fall back to `{{ACTIVE_STORY_FILE}}`:
```bash
cat {{ACTIVE_STORY_FILE}}
# Use issueNumber and derive repo owner/name from the url field
```

If neither source provides a project owner/number, and there is no active story, output a clear error and exit.

---

### Step 2: Fetch Ready Stories Without `ready-for-development` Label

**For scheduled runs** — query GitHub Projects via GraphQL:

```bash
gh api graphql -f query='
  query($owner: String!, $number: Int!) {
    user(login: $owner) {
      projectV2(number: $number) {
        items(first: 50) {
          nodes {
            id
            content {
              ... on Issue {
                number
                title
                body
                url
                labels(first: 20) {
                  nodes { name }
                }
              }
            }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                  field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
        }
      }
    }
  }
' -f owner="$PROJECT_OWNER" -F number="$PROJECT_NUMBER"
```

Filter results to items where:
- The `Status` field equals `Ready`
- The issue does **not** have the `ready-for-development` label

**For manual runs** — fetch the single issue from `{{ACTIVE_STORY_FILE}}`:
```bash
gh issue view <issueNumber> --json number,title,body,url,labels
```

---

### Step 3: Analyze Each Story

For each story, run the following checks in sequence.

#### 3a. Locate Acceptance Criteria Section

Search the issue body for an `## Acceptance Criteria` or `## ACs` section (case-insensitive). Extract all bullet/numbered points under it.

If no AC section is found → mark `has_ac_section = false`.

#### 3b. SMART Analysis

Apply each heuristic to the extracted ACs:

| Dimension | Flag condition |
|-----------|----------------|
| **Specific** | Body < 3 sentences OR contains "should", "might", "could", "maybe" |
| **Measurable** | No numeric threshold or unit found in AC text (e.g. `ms`, `%`, `s`, `px`, a number) |
| **Achievable** | Story has size label `L` or `XL` and no technical feasibility note |
| **Relevant** | No reference to user benefit or story goal in the ACs |
| **Time-bound** | No version, milestone, sprint, or due-date reference in body |

Collect all failing dimensions. If `has_ac_section = false`, mark all SMART dimensions as failing.

#### 3c. NFR Cross-Reference

Read `{{NFR_REGISTRY_FILE}}`. For each NFR entry, check whether the story matches **any** of its `appliesTo` keywords against:
- Issue labels
- Story title (case-insensitive)
- Body text (case-insensitive)

If the story matches an NFR's keywords, that NFR **applies to** this story.

Search the issue body for an `## NFR` or `## Non-Functional Requirements` section. If it exists, parse it for references to matching NFR IDs or their names.

`nfrs_covered` = list of applicable NFR IDs that are explicitly referenced in the body.
`nfrs_missing` = applicable NFR IDs not referenced.

#### 3d. Determine Labels to Apply

| Condition | Label |
|-----------|-------|
| No AC section OR any SMART dimension fails | `needs-acs` |
| `nfrs_missing` is non-empty | `needs-nfrs` |
| Either `needs-acs` OR `needs-nfrs` | `needs-refinement` |
| No gaps found | `ready-for-development` |

Remove any of the four managed labels that conflict with the new state before applying.

Apply labels:
```bash
gh issue edit <number> --repo {{REPO_SLUG}} --add-label "<label>"
gh issue edit <number> --repo {{REPO_SLUG}} --remove-label "<label>"
```

Ensure the four labels exist before applying (create if missing — see Label Setup below).

#### 3e. Post Comment (only if gaps found)

**Only post a comment if `needs-acs` or `needs-nfrs` was applied.** Do not comment on clean stories.

Before posting, check if a prior quality-check comment exists (search for `<!-- story-quality-check -->` in existing comments). If one exists, **edit** it rather than posting a new one.

```bash
gh issue comment <number> --repo {{REPO_SLUG}} --body "..."
# or for edit:
gh api repos/{{REPO_SLUG}}/issues/comments/<comment_id> -X PATCH -f body="..."
```

**Comment format:**

```markdown
<!-- story-quality-check -->
## Story Quality Check

**Status**: Requires refinement before development

### Acceptance Criteria Gaps
<!-- Only include this section if needs-acs was applied -->
- [ ] _[specific SMART gap — e.g. "No measurable threshold found in ACs"]_
- [ ] _[e.g. "Vague language detected: 'should work correctly'"]_

### NFR Check
<!-- Only include this section if needs-nfrs was applied -->
The following system-wide NFRs apply to this story and are not yet referenced:

| NFR | Description | Threshold |
|-----|-------------|-----------|
| **NFR-001** | API Response Time | p95 <= 200ms |

Please add an `## NFR` section to the issue body confirming whether each threshold applies or providing a justified exception.

### Questions
1. _[Specific question derived from SMART gap]_
2. _[Specific question about missing NFR coverage]_

---
_To dismiss this check, apply the `ready-for-development` label manually or address the gaps above._
_Automated check by [Story Quality Monitor](../../actions/workflows/story-quality-monitor.yml)_
```

---

### Step 4: NFR Registry Update (Scheduled Runs Only)

Track new threshold patterns observed across stories in this session. A pattern qualifies if:
- The same constraint (e.g. `<500ms`, `99.95%`) appears in 2 or more stories
- It is not already represented in `{{NFR_REGISTRY_FILE}}`

If qualifying patterns exist:
1. Propose a new NFR entry with a generated ID (next in sequence)
2. Create a branch: `chore/nfr-registry-update-<YYYYMMDD>`
3. Write the updated `{{NFR_REGISTRY_FILE}}`
4. Commit and open a PR:

```bash
git checkout -b chore/nfr-registry-update-$(date +%Y%m%d)
# Edit NFR registry file to add new entries and update lastUpdated
git add {{NFR_REGISTRY_FILE}}
git commit -m "chore: add NFR patterns detected in story quality scan $(date +%Y-%m-%d)"
gh pr create \
  --title "chore: NFR registry update $(date +%Y-%m-%d)" \
  --body "Automated PR: new NFR patterns detected across stories during quality scan. Please review and merge." \
  --base {{DEFAULT_BRANCH}}
```

---

## Label Setup

Run once to create the required labels (safe to re-run; `--force` updates existing):

```bash
gh label create "needs-acs"             --color "E4A11B" --description "Missing or non-SMART acceptance criteria" --force
gh label create "needs-nfrs"            --color "E4A11B" --description "Missing non-functional requirements" --force
gh label create "needs-refinement"      --color "D93F0B" --description "Story requires refinement before development" --force
gh label create "ready-for-development" --color "0E8A16" --description "Story fully refined, ready to pick up" --force
```

This skill creates missing labels automatically before applying them.

---

## Error Handling

| Error | Behaviour |
|-------|-----------|
| No project owner/number and no active story | Print clear error, exit without modifying anything |
| No Ready stories found | Print summary "0 stories to review", exit cleanly |
| `gh` auth not available | Print auth instructions, exit |
| Label apply fails | Log warning, continue processing remaining stories |
| Comment post fails | Log warning, continue |
| NFR PR creation fails | Log warning — do not block the main quality check |

---

## Manual Usage

```
/check-story-quality
```

When run manually:
- Uses `{{ACTIVE_STORY_FILE}}` for the target issue
- Outputs the quality analysis to the terminal in addition to applying labels/comments
- Does **not** create NFR registry PRs (scheduled-only feature)

Example terminal output:

```
Story Quality Check: #123 - Implement payment checkout

SMART Analysis:
  + Specific
  x Measurable — no numeric threshold found in ACs
  + Achievable
  + Relevant
  x Time-bound — no milestone or sprint reference

NFR Coverage:
  x NFR-001 (API Response Time) — applies via label 'api', not referenced
  + NFR-003 (Authentication Required) — referenced in body

Result: needs-acs, needs-nfrs, needs-refinement labels applied
Comment posted: https://github.com/.../issues/123#issuecomment-...
```

---

## Integration with /play-story

When `/play-story` fetches a story, it checks for the `needs-refinement` label:
- If present: display a warning block with the quality-check comment thread link
- Developer can continue or exit to refine the story first
