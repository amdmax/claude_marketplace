---
name: "cc:project-context"
description: "Injects project context (AGENT_DOCS_DIR, active story) before every skill invocation via PreToolUse hook."
tools:
  - Read
  - Bash
hooks:
  PreToolUse:
    matcher: "Skill"
    hooks:
      - type: command
        command: "bash $SKILL_DIR/inject-project-context.sh"
---

# Project Context Injector

Registers a PreToolUse hook that fires before every skill invocation and injects project-specific paths and active-story metadata into Claude's context.

## What Gets Injected

```
[project-context]
AGENT_DOCS_DIR=docs
ADR_DIR=docs/adr
STORIES_DIR=docs/stories
ACTIVE_STORY=docs/active-story.yaml
ACTIVE_STORY_NUMBER=42          # only if active-story.yaml exists
ACTIVE_STORY_TITLE=...          # only if active-story.yaml exists
ACTIVE_STORY_URL=...            # only if active-story.yaml exists
```

## Configuration

Override the default `docs` path in your project's `.claude/config.yaml`:

```yaml
agent_docs_dir: "agent-docs"
```

## Active Story

Skills that create or fetch stories write `$AGENT_DOCS_DIR/active-story.yaml` (e.g. `/github:story-create`, `/github:story-fetch`). Once present, all subsequent skill invocations automatically receive the active issue number, title, and URL.
