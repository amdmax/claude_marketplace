#!/usr/bin/env bash
# PostToolUse hook: validate YAML frontmatter after writing/editing a SKILL.md
# Receives tool data as JSON on stdin: { tool_input: { file_path, ... } }

FILE=$(python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)

[[ "$FILE" == *SKILL.md ]] || exit 0
[[ -f "$FILE" ]] || exit 0

FM=$(awk 'NR==1 && /^---$/{flag=1; next} flag && /^---$/{exit} flag' "$FILE" 2>/dev/null)

if [[ -z "$FM" ]]; then
  echo "✗ $FILE: missing YAML frontmatter" >&2
  exit 1
fi

if echo "$FM" | yq eval '.' - >/dev/null 2>&1; then
  echo "✓ Frontmatter valid: $FILE"
else
  echo "✗ Invalid YAML frontmatter: $FILE" >&2
  echo "$FM" | yq eval '.' - 2>&1 | head -5 >&2
  exit 1
fi
