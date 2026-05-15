#!/bin/bash
# UserPromptSubmit hook: inject AGENT_DOCS_DIR and derived paths into Claude's context.
# Register in .claude/settings.json:
#   "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash hooks/inject-agent-docs-path.sh"}]}]
#
# Project config (.claude/config.yaml):
#   agent_docs_dir: "docs"   # optional, defaults to "docs"

CONFIG_FILE=".claude/config.yaml"
DEFAULT_DIR="docs"

AGENT_DOCS_DIR=""
if [ -f "$CONFIG_FILE" ]; then
    AGENT_DOCS_DIR=$(grep -m1 'agent_docs_dir' "$CONFIG_FILE" 2>/dev/null \
        | sed 's/.*:[[:space:]]*//' | tr -d '"' | tr -d "'" | tr -d ' ')
fi
AGENT_DOCS_DIR="${AGENT_DOCS_DIR:-$DEFAULT_DIR}"

cat <<EOF
[project-paths] AGENT_DOCS_DIR=$AGENT_DOCS_DIR | ADR_DIR=$AGENT_DOCS_DIR/adr | STORIES_DIR=$AGENT_DOCS_DIR/stories
EOF

exit 0
