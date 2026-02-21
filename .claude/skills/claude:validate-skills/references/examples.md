# Valid Skill Examples

## Minimal Valid Skill

```markdown
---
name: example-skill
description: Example skill demonstrating minimal valid frontmatter
---

# Example Skill

Your skill content here.
```

## Complete Skill with All Options

```markdown
---
name: complete-example
description: Complete example with all valid frontmatter options
version: 1.0.0
author: Claude
tags: [example, validation, complete]
hooks:
  Start:
    command: bash "$SKILL_DIR/scripts/init.sh"
    description: Initialize skill resources
    timeout: 10000
  Stop:
    command: bash "$SKILL_DIR/scripts/cleanup.sh"
    description: Clean up temporary files
    timeout: 5000
  PreToolUse:
    command: bash "$SKILL_DIR/scripts/pre-check.sh"
    description: Validate before tool execution
    timeout: 3000
parameters:
  max_retries:
    type: integer
    default: 3
    description: Maximum number of retry attempts
  debug_mode:
    type: boolean
    default: false
    description: Enable debug logging
dependencies:
  - yq
  - jq
  - gh
---

# Complete Example Skill

Full skill documentation here.
```

## Skill with Multiple Hooks

```markdown
---
name: multi-hook-example
description: Example with multiple hook configurations
hooks:
  SessionStart:
    command: bash "$SKILL_DIR/scripts/load-context.sh"
    description: Load development context
    timeout: 15000
  Stop:
    command: bash "$SKILL_DIR/scripts/validate.sh"
    description: Validate before stopping
    timeout: 30000
  PostToolUse:
    command: bash "$SKILL_DIR/scripts/format.sh"
    description: Format files after editing
    timeout: 10000
---

# Multi-Hook Example

Shows multiple hook types.
```

## GitHub Workflow Skill

```markdown
---
name: gh:workflow-manager
description: Manage GitHub Actions workflows
version: 2.1.0
author: GitHub Team
tags: [github, ci-cd, workflows, automation]
hooks:
  Stop:
    command: bash "$SKILL_DIR/scripts/validate-workflows.sh"
    description: Validate workflow YAML syntax
    timeout: 20000
parameters:
  workflow_dir:
    type: string
    default: ".github/workflows"
    description: Path to workflows directory
dependencies:
  - gh
  - yq
  - actionlint
---

# GitHub Workflow Manager

Manages GitHub Actions workflows with validation and deployment.
```

## Invalid Examples (What NOT to Do)

### Missing Frontmatter Delimiters

```markdown
name: broken-skill
description: Missing frontmatter delimiters

# Broken Skill
```

**Error:** Missing frontmatter delimiters (---)

### Missing Required Fields

```markdown
---
name: incomplete-skill
---

# Incomplete Skill
```

**Error:** Required field 'description' not found

### Invalid Hook Event Type

```markdown
---
name: bad-hooks
description: Uses invalid hook event
hooks:
  BeforeExecution:  # INVALID - should be PreToolUse
    command: bash script.sh
    description: Run before execution
---
```

**Error:** Invalid hook event type: 'BeforeExecution'

### Invalid Timeout Format

```markdown
---
name: bad-timeout
description: Invalid timeout value
hooks:
  Stop:
    command: bash cleanup.sh
    description: Cleanup
    timeout: "very-long"  # INVALID - must be number
---
```

**Error:** Hook 'Stop' timeout must be a number (milliseconds)

### Invalid Skill Name Format

```markdown
---
name: skill with spaces!  # INVALID
description: Has spaces and special characters in name
---
```

**Error:** Invalid skill name format (use alphanumeric, hyphens, colons, underscores)

## Best Practices

1. **Always include frontmatter** - Use `---` delimiters
2. **Provide description** - Clear, concise skill description
3. **Add version** - Semantic versioning (1.0.0)
4. **Tag appropriately** - Use relevant tags for discovery
5. **Document hooks** - Add descriptions explaining what hooks do
6. **Set reasonable timeouts** - Prevent hanging (default: 30000ms)
7. **Use $SKILL_DIR** - Reference skill directory in commands
8. **List dependencies** - Document required external tools
