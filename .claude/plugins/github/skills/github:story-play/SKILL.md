---
name: play-story
description: Put a story "in play" by fetching it from GitHub Projects, gathering NFRs, collecting context, and creating ADRs as needed. Invokable with /play-story.
---

# Play Story Workflow

## Overview

This skill orchestrates the complete story preparation workflow, coordinating all helper skills to prepare a story for implementation. It:

1. **Checks for active story** - Handles existing work gracefully
2. **Fetches next Ready story** - Calls `/fetch-story` to get highest-priority story
3. **Gathers non-functional requirements** - Calls `/gather-nfr` for NFR collection
4. **Collects technical context** - Calls `/gather-context` for comprehensive context
5. **Creates ADR if needed** - Calls `/create-adr` for architectural decisions
6. **Provides summary** - Shows complete story preparation and suggests next steps

This is the **primary entry point** for developers starting work on a new story.

## Workflow

### Step 1: Pull Latest Changes from Master

**CRITICAL: Always pull latest changes before starting new work**

```bash
# Fetch and pull latest from master
echo "🔄 Pulling latest changes from master..."

# Fetch latest
git fetch origin master

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Stash uncommitted changes if any
if ! git diff-index --quiet HEAD --; then
  echo "  Stashing uncommitted changes..."
  git stash push -u -m "Auto-stash before pulling master (play-story)"
  STASHED=true
else
  STASHED=false
fi

# Switch to master and pull
git checkout master
git pull origin master

# Return to previous branch
if [ "$CURRENT_BRANCH" != "master" ]; then
  git checkout "$CURRENT_BRANCH"

  # Offer to rebase/merge if branch exists
  echo "  Current branch: $CURRENT_BRANCH"
  echo "  Master updated. Consider rebasing your branch."
fi

# Restore stashed changes
if [ "$STASHED" = "true" ]; then
  echo "  Restoring stashed changes..."
  git stash pop
fi

echo "✓ Master branch updated"
```

**Why this is critical:**
- PR #207 merged while working on another feature
- Master may contain dependency updates affecting your work
- Prevents merge conflicts and duplicate work
- Ensures you're working with latest code patterns

**When to skip:**
- You just cloned the repository
- You're certain master hasn't changed (check `git fetch origin master && git log master..origin/master`)

### Step 2: Check for Active Story

**Read active story file:**

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.claude/active-story.json"
if [ -f "$STORY_FILE" ]; then
  # Active story exists
  ACTIVE_STORY_EXISTS=true
else
  ACTIVE_STORY_EXISTS=false
fi
```

**If active story exists, prompt user:**

```
⚠️  Active story in progress

Current story: #123 - Implement payment checkout
Status: NFRs collected, context gathered, ADR created
Fetched: 2 hours ago

What would you like to do?
  [1] Continue with current story
  [2] Switch to a different story (fetch new story)
  [3] View current story details
  [4] Cancel

Choice:
```

**Handle user choice:**

| Choice | Action |
|--------|--------|
| 1 - Continue | Skip to summary, show current story status |
| 2 - Switch | Archive current story, fetch new one |
| 3 - View details | Display full `.claude/active-story.json`, then re-prompt |
| 4 - Cancel | Exit workflow |

**Archive current story (if switching):**

```bash
# Move active story to archive
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mv "$CLAUDE_PROJECT_DIR/.claude/active-story.json" \
   "$CLAUDE_PROJECT_DIR/.claude/active-story-${TIMESTAMP}.json"

echo "✓ Previous story archived to .claude/active-story-${TIMESTAMP}.json"
```

### Step 3: Fetch Next Ready Story

**Call `/fetch-story` skill:**

```
→ Step 2/5: Fetching next Ready story from GitHub Projects

Calling /fetch-story...
```

**Skill tool invocation:**

```javascript
Skill: "fetch-story"
```

**Expected output:**
- `.claude/active-story.json` created with story data
- GitHub status updated to "In Progress"
- Story summary displayed

**Error handling:**

If `/fetch-story` fails:

```
❌ Failed to fetch story

Error: [error from fetch-story skill]

Common causes:
- No Ready stories in project
- GitHub authentication failed
- Configuration missing

Please resolve the issue and run /play-story again.
```

Exit workflow if fetch fails.

**Success confirmation:**

```
✓ Story Fetched: #123 - Implement payment checkout
  Priority: P0
  Size: M
  Labels: story, feature, payment
```

### Step 4: Gather Non-Functional Requirements

**Call `/gather-nfr` skill:**

```
→ Step 3/5: Collecting non-functional requirements

Calling /gather-nfr...
```

**Skill tool invocation:**

```javascript
Skill: "gather-nfr"
```

**Expected output:**
- Interactive Q&A session with user
- NFRs appended to `.claude/active-story.json`
- NFR summary displayed

**Error handling:**

If `/gather-nfr` fails or user cancels:

```
⚠️  NFR collection incomplete

You can continue without NFRs, but architectural decisions may be less informed.

Options:
  [1] Continue without NFRs (skip to context gathering)
  [2] Retry NFR collection
  [3] Cancel workflow

Choice:
```

**Success confirmation:**

```
✓ NFRs Collected
  • Performance: 1000-10000 daily users, <2s response
  • Security: PII + Payment, PCI-DSS + GDPR
  • Reliability: 99.9% uptime
  • Cost: Standard budget
```

### Step 5: Gather Technical Context

**Call `/gather-context` skill:**

```
→ Step 4/5: Gathering technical context

Calling /gather-context...
```

**Skill tool invocation:**

```javascript
Skill: "gather-context"
```

**Expected output:**
- Documentation search results
- Codebase analysis (via Explore agent)
- Architecture doc review
- User clarification questions
- Context appended to `.claude/active-story.json`

**Error handling:**

If `/gather-context` fails:

```
⚠️  Context gathering incomplete

Partial context available:
  • 2 related docs
  • 1 code file

Options:
  [1] Continue with partial context
  [2] Retry context gathering
  [3] Cancel workflow

Choice:
```

**Success confirmation:**

```
✓ Context Collected
  • 2 documentation files
  • 3 related code files
  • 1 architecture document
  • 2 existing ADRs
  • 3 dependencies identified
  • 2 constraints noted
```

### Step 6: Create ADR (Conditional)

**Determine if ADR is needed:**

```javascript
// Read story data
const story = JSON.parse(fs.readFileSync('.claude/active-story.json', 'utf-8'));

// Check if ADR is recommended
const needsADR = shouldCreateADR(story);

if (needsADR) {
  console.log('→ Step 5/5: Creating Architecture Decision Record');
  console.log('  ADR recommended: [Reason]');
  console.log('');
  console.log('Calling /create-adr...');
} else {
  console.log('ℹ️  Step 5/5: ADR not needed');
  console.log('  Reason: [Simple bug fix | Following established pattern]');
  console.log('');
  console.log('Skipping ADR creation.');
}
```

**If ADR needed, call `/create-adr`:**

```javascript
Skill: "create-adr"
```

**Expected output:**
- ADR file created in `docs/adr/`
- ADR reference added to `.claude/active-story.json`
- ADR summary displayed

**Error handling:**

If `/create-adr` fails:

```
⚠️  ADR creation failed

Error: [error from create-adr skill]

You can proceed without an ADR, but architectural decisions won't be documented.

Options:
  [1] Continue without ADR
  [2] Retry ADR creation
  [3] Cancel workflow

Choice:
```

**Success confirmation:**

```
✓ ADR Created: ADR-0012: stripe-payment-integration
  Decision: Stripe Checkout (hosted page)
  Status: Proposed
  Location: docs/adr/0012-stripe-payment-integration.md
```

### Step 7: Final Summary

**Display complete story preparation:**

```
═══════════════════════════════════════════════════════════════
  Story Ready for Implementation
═══════════════════════════════════════════════════════════════

Story: #123 - Implement payment checkout
Priority: P0
Size: M (estimated 4-6 hours)
URL: https://github.com/{{REPO_SLUG}}/issues/123

───────────────────────────────────────────────────────────────
Non-Functional Requirements
───────────────────────────────────────────────────────────────

Performance:
  • 1,000-10,000 daily active users
  • <2s maximum response time
  • 100-1,000 concurrent users

Security:
  • PII + Payment data
  • Authenticated-only access
  • PCI-DSS + GDPR compliance

Reliability:
  • 8 hours/year (99.9%) acceptable downtime
  • <1% error rate tolerance
  • Comprehensive monitoring

Cost:
  • Standard/balanced budget
  • Preferred services: Lambda, DynamoDB, S3

───────────────────────────────────────────────────────────────
Technical Context
───────────────────────────────────────────────────────────────

Documentation:
  • docs/DEVELOPMENT_WORKFLOW.md - Payment testing requirements
  • docs/API_GUIDELINES.md - Error handling patterns

Related Code:
  • lambda/payment-handler/index.ts - Stripe integration with retries
  • infrastructure/payment-stack.ts - CDK stack for payment Lambda

Architecture:
  • _bmad-output/payment-referral-architecture.md

Existing ADRs:
  • ADR-0001: Stripe payment processor (accepted)
  • ADR-0005: Lambda@Edge auth (accepted)

Dependencies:
  • Authentication system (Cognito)
  • User profile service
  • Notification system (SNS)

Constraints:
  • AWS Lambda timeout (30s max)
  • Cost constraints (standard budget)

Established Patterns:
  • API Gateway + Lambda pattern
  • DynamoDB single-table design
  • Exponential backoff for retries
  • Lambda@Edge authentication

───────────────────────────────────────────────────────────────
Architecture Decision Record
───────────────────────────────────────────────────────────────

ADR-0012: stripe-payment-integration
Status: Proposed
Location: docs/adr/0012-stripe-payment-integration.md

Decision: Stripe Checkout (hosted page)

Rationale:
  • Satisfies PCI-DSS compliance with minimal effort
  • Fast implementation (1-2 days)
  • Meets performance (<2s) and reliability (99.9%) requirements

Trade-offs:
  ✓ Stripe handles PCI compliance (reduces audit scope)
  ✓ Battle-tested infrastructure (99.99% uptime)
  ✗ Limited UI customization (Stripe branding)
  ✗ User redirect may increase abandonment by 10-15%

───────────────────────────────────────────────────────────────
Next Steps
───────────────────────────────────────────────────────────────

1. Review ADR and update status to "accepted" if approved
2. Create feature branch: git checkout -b feature/payment-checkout-[timestamp]
3. Implement according to ADR implementation notes
4. Reference story #123 and ADR-0012 in commits
5. Create PR when ready: /mr

Story data saved to: .claude/active-story.json
ADR location: docs/adr/0012-stripe-payment-integration.md

═══════════════════════════════════════════════════════════════
```

### Step 8: Offer Quick Actions

**Prompt user for next action:**

```
What would you like to do next?

  [1] Start implementation (opens ADR + story in editor)
  [2] Review ADR before starting
  [3] View story details in browser
  [4] Create feature branch
  [5] Nothing (I'll start manually)

Choice:
```

**Handle quick actions:**

| Choice | Action |
|--------|--------|
| 1 - Start implementation | Open ADR file and GitHub issue URL |
| 2 - Review ADR | Read and display ADR file |
| 3 - View story | Open story URL in browser using `open` command |
| 4 - Create branch | Run `git checkout -b feature/[story-slug]-[timestamp]` |
| 5 - Nothing | Exit workflow |

## Error Handling

### Configuration Missing

```
❌ Configuration not found

This workflow requires configuration in .claude/story-workflow-config.json

Please add the following section:

{
  "storyWorkflow": {
    "projectId": "{{GITHUB_PROJECT_ID}}",
    "fieldIds": { ... },
    "optionIds": { ... }
  }
}

See /fetch-story skill documentation for complete configuration schema.
```

### GitHub Authentication Failed

```
❌ GitHub authentication required

Please authenticate with GitHub CLI:
  gh auth login

Then run /play-story again.
```

### No Ready Stories

```
ℹ️  No Ready stories found

There are no stories with Status='Ready' in the GitHub Project.

Suggestions:
1. Create new stories in GitHub Issues
2. Add them to the project: https://github.com/orgs/aigensa/projects/...
3. Set their Status to 'Ready'
4. Run /play-story again

Alternatively, you can manually select a story from:
  gh issue list --label story
```

### Workflow Interrupted

**If user cancels at any step:**

```
⚠️  Workflow cancelled by user

Partial progress saved to .claude/active-story.json

Completed:
  ✓ Story fetched
  ✓ NFRs collected
  ✗ Context gathering (not started)
  ✗ ADR creation (not started)

To resume, run:
  /gather-context  (continue from where you left off)
  /play-story     (restart full workflow)
```

### Skill Execution Failed

**If any helper skill fails:**

```
❌ Workflow failed at step [X/5]: [Step name]

Error: [error message from skill]

Troubleshooting:
- Check error details above
- Verify prerequisites (GitHub auth, configuration)
- Try running /[skill-name] directly to diagnose
- Report issue if error persists

Partial progress saved to .claude/active-story.json
```

## Configuration

### Required Settings

**File:** `.claude/story-workflow-config.json`

```json
{
  "storyWorkflow": {
    "projectId": "{{GITHUB_PROJECT_ID}}",
    "fieldIds": {
      "status": "PVTSSF_lADODvZ3Zc4BM9rkzg8GG4A",
      "priority": "PVTSSF_lADODvZ3Zc4BM9rkzg8GHB4",
      "size": "PVTSSF_lADODvZ3Zc4BM9rkzg8GHB8",
      "itemType": "PVTSSF_lADODvZ3Zc4BM9rkzg8GOqE",
      "techSpecStatus": "PVTSSF_lADODvZ3Zc4BM9rkzg8GOtI"
    },
    "optionIds": {
      "status": {
        "ready": "61e4505c",
        "inProgress": "47fc9ee4",
        "backlog": "f75ad846"
      },
      "priority": {
        "p0": "79628723",
        "p1": "0a877460",
        "p2": "da944a9c"
      }
    }
  }
}
```

### Optional Settings

```json
{
  "storyWorkflow": {
    ...
    "defaultNFRs": {
      "performance": {
        "dailyActiveUsers": "100-1000",
        "maxResponseTime": "<2s"
      }
    },
    "skipADRForLabels": ["bug", "chore", "docs"],
    "autoCreateBranch": true,
    "branchPrefix": "feature/"
  }
}
```

## Integration with Other Skills

### Calls Helper Skills

```
/play-story (this skill)
  ↓
  ├── /fetch-story
  ├── /gather-nfr
  ├── /gather-context
  └── /create-adr (conditional)
```

### Called Before Implementation

**Typical workflow:**

```
Developer workflow:
1. /play-story          (prepare story)
2. [Implement code]      (write code following ADR)
3. /commit               (create commits with AIGCODE-###)
4. /mr                   (create pull request)
```

### Alternative: Run Skills Individually

Users can also run helper skills individually:

```bash
# Manual workflow
/fetch-story         # Just fetch story
/gather-nfr          # Just collect NFRs
/gather-context      # Just gather context
/create-adr          # Just create ADR
```

## Best Practices

### When to Use /play-story

**✅ Use when:**
- Starting work on a new story
- Beginning a development session
- Switching to a different story
- Need complete story context

**❌ Don't use when:**
- Already have active story prepared
- Continuing work on current story
- Just need one piece (use specific skill instead)

### Workflow Customization

**Skip steps if not needed:**

```javascript
// If you know you don't need ADRs for this story
/play-story --skip-adr

// If you want to quickly fetch without full workflow
/fetch-story

// If you already have story but need context
/gather-context
```

*Note: Command-line flags are illustrative; actual implementation uses Skill tool which doesn't support flags. Users would run individual skills instead.*

### Archive Management

**Periodically clean up archives:**

```bash
# List archived stories
ls "$CLAUDE_PROJECT_DIR/.claude/active-story-"*.json

# Remove old archives (keep last 5)
ls -t "$CLAUDE_PROJECT_DIR/.claude/active-story-"*.json | tail -n +6 | xargs rm
```

## Troubleshooting

### Issue: "Active story is stale"

**Cause:** Story was fetched days ago, may be outdated

**Solution:**

```
⚠️  Active story is stale

Story was fetched 3 days ago. It may be outdated.

Recommended: Fetch fresh story

Options:
  [1] Continue with current story
  [2] Fetch fresh story (recommended)

Choice:
```

### Issue: "Skills are taking too long"

**Cause:** Explore agent or searches are slow

**Solution:**
- Use thoroughness="quick" for faster results
- Skip optional steps (e.g., ADR creation)
- Run skills individually to diagnose

### Issue: "Story already has status='In Progress'"

**Cause:** Multiple team members may be working on same story

**Solution:**

```
⚠️  Story #123 already has status 'In Progress'

Another developer may be working on this story.

Options:
  [1] Continue anyway (coordinate with team)
  [2] Fetch different story
  [3] Cancel

Choice:
```

## Advanced Usage

### Running Skills in Parallel

For maximum efficiency, independent steps could be parallelized (future enhancement):

```javascript
// Future: Run NFR and context gathering in parallel
await Promise.all([
  Skill("gather-nfr"),
  Skill("gather-context")
]);
```

*Note: Current implementation runs sequentially for simplicity.*

### Custom Workflows

Create custom orchestrations:

```javascript
// Custom: Skip NFRs for simple bug fixes
if (story.labels.includes('bug') && story.size === 'XS') {
  // Skip NFRs and context, just create branch
  runSkill('fetch-story');
  createBranch();
}
```

### Integration with BMAD

**Bridge to BMAD's `/dev-story` skill:**

```
/play-story         (this skill - preparation)
  → Story ready
/dev-story           (BMAD skill - implementation)
  → Code written, tests pass
/commit              (this project - commit)
/mr                  (this project - PR)
```

## Example Session

```bash
$ /play-story

═══════════════════════════════════════════════════════════════
  Story Workflow Orchestrator
═══════════════════════════════════════════════════════════════

Checking for active story...
  No active story found

→ Step 2/5: Fetching next Ready story from GitHub Projects

🔍 Querying project {{GITHUB_PROJECT_ID}}...
  ✓ Found 3 Ready stories

Filtering and sorting by priority...
  • P0: Implement payment checkout (M)
  • P1: Add user profile editing (S)
  • P2: Improve error messages (XS)

Selected: #123 - Implement payment checkout

✓ Story data saved to .claude/active-story.json
✓ GitHub status updated to "In Progress"

───────────────────────────────────────────────────────────────

→ Step 3/5: Collecting non-functional requirements

📋 Analyzing story context...
  Labels: story, feature, payment

Q1: How many daily active users do you expect?
  [User selects: 1,000-10,000]

Q2: What is the maximum acceptable response time?
  [User selects: <2s]

[... more questions ...]

✓ NFRs collected and saved

───────────────────────────────────────────────────────────────

→ Step 4/5: Gathering technical context

🔍 Searching documentation...
  ✓ Found 2 related docs

🔍 Analyzing codebase...
  ✓ Found 3 related code files

🔍 Reviewing architecture...
  ✓ Found 1 architecture document

🔍 Checking existing ADRs...
  ✓ Found 2 related ADRs

Q: Does this feature depend on any existing systems?
  [User selects: Authentication, User profile, Notifications]

[... more questions ...]

✓ Context collected and saved

───────────────────────────────────────────────────────────────

→ Step 5/5: Creating Architecture Decision Record

Analysis: ADR recommended (new payment integration, security-sensitive)

🔍 Generating ADR...
  Next ADR number: 0012
  Title slug: stripe-payment-integration

✓ ADR created: docs/adr/0012-stripe-payment-integration.md
✓ ADR reference saved to active story

───────────────────────────────────────────────────────────────

[... Final Summary displayed ...]

What would you like to do next?
  [1] Start implementation
  [2] Review ADR before starting
  [3] View story in browser
  [4] Create feature branch
  [5] Nothing

Choice: 1

Opening ADR in editor...
Opening story in browser...

✓ Ready to implement! Good luck! 🚀
```

## Summary

The `/play-story` skill orchestrates the complete story preparation workflow by:

✅ **Coordinating helper skills** - Calls fetch-story, gather-nfr, gather-context, create-adr
✅ **Handling errors gracefully** - Allows recovery and retry at each step
✅ **Managing state** - Checks for active stories, archives old ones
✅ **Providing clear guidance** - Shows progress, summarizes results, suggests next steps
✅ **Saving time** - Automates tedious preparation work in one command

Use `/play-story` as your primary entry point when beginning work on a new story!
