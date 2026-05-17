---
name: play-story
description: Put a story "in play" by fetching it from GitHub Projects, gathering NFRs, collecting context, and creating ADRs as needed. Invokable with /play-story.
---

# Play Story Workflow

## Overview

Orchestrates the complete story preparation workflow:

1. Checks for active story — handles existing work gracefully
2. Pulls latest master
3. Fetches next Ready story via `/github:story-fetch`
4. Gathers NFRs via `/arch:gather-nfr`
5. Collects technical context via `/scout:gather-context`
6. Creates ADR if needed via `/arch:create-adr`
7. Displays summary and suggests next steps

Primary entry point for developers starting work on a new story.

## Workflow

### Step 1: Pull Latest Changes from Master

```bash
git fetch origin master
CURRENT_BRANCH=$(git branch --show-current)
if ! git diff-index --quiet HEAD --; then
  git stash push -u -m "Auto-stash before pulling master (play-story)"
  STASHED=true
fi
git checkout master && git pull origin master
[ "$CURRENT_BRANCH" != "master" ] && git checkout "$CURRENT_BRANCH"
[ "$STASHED" = "true" ] && git stash pop
echo "✓ Master branch updated"
```

### Step 2: Check for Active Story

```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/${AGENT_DOCS_DIR:-docs}/active-story.yaml"
[ -f "$STORY_FILE" ] && ACTIVE_STORY_EXISTS=true || ACTIVE_STORY_EXISTS=false
```

If active story exists, prompt:
```
⚠️  Active story in progress: #123 - Implement payment checkout

  [1] Continue with current story
  [2] Switch to a different story
  [3] View current story details
  [4] Cancel
```

If switching, archive the current story:
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mv "$STORY_FILE" "${STORY_FILE%.yaml}-${TIMESTAMP}.yaml"
```

### Step 3: Fetch Next Ready Story

```
→ Step 2/5: Fetching next Ready story from GitHub Projects
```

Invoke skill: `github:story-fetch`

Expected: `$AGENT_DOCS_DIR/active-story.yaml` created, GitHub status → "In Progress".

If fetch fails, display error and exit. Configuration required — see [references/configuration.md](references/configuration.md).

### Step 4: Gather Non-Functional Requirements

```
→ Step 3/5: Collecting non-functional requirements
```

Invoke skill: `arch:gather-nfr`

Expected: interactive Q&A, NFRs saved to active-story.yaml.

If incomplete, offer: continue without NFRs / retry / cancel.

### Step 5: Gather Technical Context

```
→ Step 4/5: Gathering technical context
```

Invoke skill: `scout:gather-context`

Expected: docs, codebase, ADRs searched; context saved to active-story.yaml.

If incomplete, offer: continue with partial context / retry / cancel.

### Step 6: Create ADR (Conditional)

```
→ Step 5/5: Creating Architecture Decision Record
```

Determine if ADR is needed from story labels, NFRs, and context. If yes, invoke skill: `arch:create-adr`.

Expected: ADR file created in `$ADR_DIR`, reference saved to active-story.yaml.

If creation fails, offer: continue without ADR / retry / cancel.

### Step 7: Final Summary

Display complete story preparation. See [references/output-format.md](references/output-format.md) for full format.

### Step 8: Offer Quick Actions

```
What would you like to do next?

  [1] Start implementation (open ADR + story in editor)
  [2] Review ADR before starting
  [3] View story details in browser
  [4] Create feature branch
  [5] Nothing

Choice:
```

| Choice | Action |
|--------|--------|
| 1 | Open ADR file and GitHub issue URL |
| 2 | Read and display ADR file |
| 3 | `open <story URL>` |
| 4 | `git checkout -b feature/[story-slug]-[timestamp]` |
| 5 | Exit |

## Error Handling

| Error | Response |
|-------|----------|
| Configuration missing | `❌ Configuration not found. See references/configuration.md` |
| GitHub auth failed | `❌ Run: gh auth login` |
| No Ready stories | `ℹ️ No Ready stories in project. Add stories and set Status=Ready.` |
| Workflow interrupted | Save partial progress; show completed/pending steps; offer resume instructions |
| Skill execution failed | Show error, troubleshooting tips, and partial progress |

Full error details and troubleshooting: [references/troubleshooting.md](references/troubleshooting.md).

## Configuration

See [references/configuration.md](references/configuration.md) for required `.claude/story-workflow-config.json` schema.

## Integration

```
/play-story (this skill)
  ↓
  ├── /github:story-fetch
  ├── /arch:gather-nfr
  ├── /scout:gather-context
  └── /arch:create-adr (conditional)
```

Then: implement → `/git:commit` → `/github:pull-request`

Run skills individually when you only need one step:
```bash
/github:story-fetch   # just fetch
/arch:gather-nfr      # just NFRs
/scout:gather-context # just context
/arch:create-adr      # just ADR
```

## Best Practices

**Use /play-story when** starting work on a new story, beginning a development session, or switching stories.

**Skip /play-story when** you already have an active story prepared or only need one step — run that skill directly instead.

**Archive management:**
```bash
ls -t "$CLAUDE_PROJECT_DIR/${AGENT_DOCS_DIR:-docs}/active-story-"*.yaml | tail -n +6 | xargs rm
```

## Supporting Files

- [references/output-format.md](references/output-format.md) — full summary output format
- [references/configuration.md](references/configuration.md) — config schema
- [references/troubleshooting.md](references/troubleshooting.md) — troubleshooting and example session
