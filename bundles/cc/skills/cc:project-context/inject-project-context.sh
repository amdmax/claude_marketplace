#!/bin/bash
# PreToolUse hook: inject project context before skill invocations.
# Reads .claude/config.yaml for agent_docs_dir, derives standard paths,
# and surfaces active-story key values if active-story.yaml exists.
# Output goes to stdout — Claude Code injects it into context before the skill runs.

INPUT=$(cat)
CWD=$(echo "$INPUT" | grep -o '"cwd":"[^"]*"' | sed 's/"cwd":"//;s/"//')
CWD="${CWD:-$PWD}"

CONFIG_FILE="$CWD/.claude/config.yaml"
DEFAULT_DIR="docs"

AGENT_DOCS_DIR=""
if [ -f "$CONFIG_FILE" ]; then
    AGENT_DOCS_DIR=$(grep -m1 'agent_docs_dir' "$CONFIG_FILE" 2>/dev/null \
        | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')
fi
AGENT_DOCS_DIR="${AGENT_DOCS_DIR:-$DEFAULT_DIR}"
AGENT_DOCS_PATH="$CWD/$AGENT_DOCS_DIR"

ADR_DIR="$AGENT_DOCS_DIR/adr"
STORIES_DIR="$AGENT_DOCS_DIR/stories"
ACTIVE_STORY="$AGENT_DOCS_DIR/active-story.yaml"

printf '[project-context]\n'
printf 'AGENT_DOCS_DIR=%s\n' "$AGENT_DOCS_DIR"
printf 'ADR_DIR=%s\n' "$ADR_DIR"
printf 'STORIES_DIR=%s\n' "$STORIES_DIR"
printf 'ACTIVE_STORY=%s\n' "$ACTIVE_STORY"

ACTIVE_STORY_FILE="$AGENT_DOCS_PATH/active-story.yaml"
if [ -f "$ACTIVE_STORY_FILE" ]; then
    ISSUE_NUMBER=$(grep -m1 'issueNumber:' "$ACTIVE_STORY_FILE" 2>/dev/null \
        | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')
    TITLE=$(grep -m1 'title:' "$ACTIVE_STORY_FILE" 2>/dev/null \
        | sed 's/.*title:[[:space:]]*//' | sed 's/^["'"'"']//' | sed 's/["'"'"']$//')
    URL=$(grep -m1 'url:' "$ACTIVE_STORY_FILE" 2>/dev/null \
        | sed 's/.*url:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')

    [ -n "$ISSUE_NUMBER" ] && printf 'ACTIVE_STORY_NUMBER=%s\n' "$ISSUE_NUMBER"
    [ -n "$TITLE" ]        && printf 'ACTIVE_STORY_TITLE=%s\n'  "$TITLE"
    [ -n "$URL" ]          && printf 'ACTIVE_STORY_URL=%s\n'    "$URL"
fi

exit 0
