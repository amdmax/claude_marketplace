# Plugin File Templates

Substitute `{plugin-name}`, `{description}`, `{author-name}`, `{author-email}` throughout.

---

## `.claude-plugin/plugin.json` (always required)

```json
{
  "name": "{plugin-name}",
  "description": "{description}",
  "author": {
    "name": "{author-name}",
    "email": "{author-email}"
  }
}
```

---

## `commands/{command-name}.md`

```markdown
---
description: {Short description shown in /help}
argument-hint: <required-arg> [optional-arg]
allowed-tools: [Read, Glob, Grep, Bash]
---

# {Command Name}

## Arguments

The user invoked this command with: $ARGUMENTS

## Instructions

1. Parse the arguments
2. Perform the action
3. Report results
```

**Frontmatter options:**
| Field | Required | Notes |
|---|---|---|
| `description` | yes | Shown in `/help` |
| `argument-hint` | no | Hint shown to user |
| `allowed-tools` | no | Pre-approved tools (reduces permission prompts) |
| `model` | no | Override model: `haiku`, `sonnet`, `opus` |

---

## `skills/{skill-name}/SKILL.md`

```markdown
---
name: {skill-name}
description: Use this skill when the user asks to "{trigger phrase}" or mentions "{keyword}". {One sentence on what it does.}
version: 1.0.0
---

# {Skill Name}

## What this skill does

{Brief description}

## When this skill applies

{List trigger conditions}

## Instructions

{Step-by-step guidance for Claude}
```

**Frontmatter options:**
| Field | Required | Notes |
|---|---|---|
| `name` | yes | Skill identifier |
| `description` | yes | Trigger conditions — be specific about phrases/keywords |
| `version` | no | Semantic version |
| `license` | no | e.g. `MIT` |

---

## `.mcp.json`

```json
{
  "{server-name}": {
    "type": "http",
    "url": "https://mcp.example.com/api"
  }
}
```

For stdio-based servers:
```json
{
  "{server-name}": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@my-org/mcp-server"]
  }
}
```

---

## `README.md`

```markdown
# {Plugin Name}

{description}

## Installation

```
/plugin install {plugin-name}@claude-plugin-directory
```

## Features

- `/command-name` — {what the command does}
- Skill: {skill-name} — {what the skill does}

## Structure

```
{plugin-name}/
├── .claude-plugin/plugin.json
├── commands/
├── skills/
└── README.md
```

## License

MIT
```

---

## `LICENSE` (MIT)

```
MIT License

Copyright (c) {year} {author-name}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
