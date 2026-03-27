---
name: cc:output-style
description: Install JSON or YAML output styles for Claude Code — changes how Claude formats all responses to structured, machine-readable output. Use when the user wants to respond in JSON, output as YAML, build automation pipelines, pipe Claude output to scripts or tools, or switch to structured response mode. Trigger on phrases like "respond in JSON", "output as YAML", "structured output", "machine readable responses", "install output style", "json mode", "yaml mode".
tools:
  - Read
  - Write
  - Bash
---

# Output Style Installer

Installs pre-built output styles that change how Claude formats every response.

## Available Styles

| Style | File | Best For |
|-------|------|----------|
| `JSON` | `$SKILL_DIR/assets/json.md` | Automation, piping to jq/scripts, CI systems |
| `YAML` | `$SKILL_DIR/assets/yaml.md` | Human-readable structured output, config pipelines, docs |

## Workflow

1. Ask which style(s) to install: JSON, YAML, or both
2. Ask scope:
   - **User-level** (`~/.claude/output-styles/`) — available in all projects
   - **Project-level** (`.claude/output-styles/`) — this project only
3. Create the target directory if it doesn't exist, then copy the style file from `$SKILL_DIR/assets/`
4. Ask if they want to activate it now

## Installing

```bash
# User-level
mkdir -p ~/.claude/output-styles
cp "$SKILL_DIR/assets/json.md" ~/.claude/output-styles/json.md

# Project-level
mkdir -p .claude/output-styles
cp "$SKILL_DIR/assets/yaml.md" .claude/output-styles/yaml.md
```

## Activating a Style

To activate without the menu, set `outputStyle` in the appropriate `settings.local.json`:

```json
{
  "outputStyle": "JSON"
}
```

Locations:
- User-level: `~/.claude/settings.local.json`
- Project-level: `.claude/settings.local.json`

Alternatively, run `/config` → select **Output style** from the menu.

> Output style changes take effect on the **next session start** — not mid-conversation.

## After Installing

Tell the user:
- Where the file was installed
- The style name to use in `outputStyle` (matches the `name` field in the file's frontmatter)
- That it takes effect next session (start a new Claude Code session or restart)
