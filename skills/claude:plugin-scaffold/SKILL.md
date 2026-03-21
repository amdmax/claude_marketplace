---
name: claude:plugin-scaffold
description: Scaffold a new Claude Code plugin following the official Anthropic plugin structure (anthropics/claude-plugins-official). Use when the user wants to create a Claude Code plugin, scaffold a plugin project, or asks about the official plugin structure, plugin.json, slash commands, or how to submit a plugin to the marketplace.
---

# Claude Code Plugin Scaffolder

Scaffold a new Claude Code plugin following the official structure from [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official).

## Step 1 — Gather inputs

Ask the user for:
1. **Plugin name** (kebab-case, e.g. `my-plugin`)
2. **Description** (one sentence)
3. **Author name and email**
4. **Extension types** to include (any combination):
   - Commands (slash commands)
   - Skills (model-invoked capabilities)
   - MCP servers
   - Agents

If the user has already provided some of these, skip those questions.

## Step 2 — Scaffold the directory structure

Create the following layout (include only the subdirs matching selected extension types):

```
{plugin-name}/
├── .claude-plugin/
│   └── plugin.json          ← always required
├── .mcp.json                ← if MCP selected
├── commands/
│   └── {command-name}.md    ← if Commands selected
├── skills/
│   └── {skill-name}/
│       └── SKILL.md         ← if Skills selected
├── agents/                  ← if Agents selected (empty dir with .gitkeep)
├── LICENSE                  ← MIT by default
└── README.md
```

For exact file contents and templates, see [references/file-templates.md](references/file-templates.md).

## Step 3 — Fill in each file

Use the templates in `references/file-templates.md`, substituting `{plugin-name}`, `{author-name}`, `{author-email}`, and `{description}` with the user's inputs.

Key rules:
- `plugin.json` is always created (required)
- Only create `commands/`, `skills/`, `agents/`, `.mcp.json` for the selected extension types
- Each command file becomes `/command-name` when installed
- Each skill subdirectory name becomes the skill's identifier

## Step 4 — Explain next steps

After scaffolding, tell the user:

1. **Test locally** — copy the plugin directory into a project's `.claude/` or install via:
   ```
   /plugin install ./{plugin-name}
   ```
2. **Iterate** — add real logic to commands/skills, wire up MCP endpoints
3. **Submit to marketplace** — fill out the [plugin directory submission form](https://clau.de/plugin-directory-submission); external plugins go in `external_plugins/` of the official repo
4. **Reference** — `plugins/example-plugin/` in the official repo is the canonical reference implementation
