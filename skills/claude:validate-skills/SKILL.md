---
name: claude:validate-skills
description: Validate skill files for proper YAML frontmatter format and valid Claude Code skill options
version: 1.0.0
author: Claude
tags:
  - validation
  - skills
  - quality
  - frontmatter
hooks:
  Stop:
    command: bash "$SKILL_DIR/scripts/validate-all-skills.sh"
    description: Validate all skills before stopping
    timeout: 30000
---

# Claude Skills Validator

Validates that skill files follow proper formatting and use valid Claude Code skill options.

## What This Skill Does

Validates skills against:
1. **YAML Frontmatter Format** - Ensures proper `---` delimiters and valid YAML syntax
2. **Required Fields** - Checks for `name`, `description`
3. **Valid Options** - Validates against official Claude Code skill schema
4. **Hook Configuration** - Ensures hooks use valid event types and parameters

## Usage

### Automatic Validation (via Stop Hook)

The skill automatically validates all skills when Claude stops:
```
Validating skills...
✓ commit/SKILL.md - Valid
✓ fetch-story/SKILL.md - Valid
✗ custom-skill/SKILL.md - Missing required field: description
```

### Manual Validation

Run validation script directly:
```bash
bash .claude/skills/claude:validate-skills/scripts/validate-all-skills.sh
```

Validate single skill:
```bash
bash .claude/skills/claude:validate-skills/scripts/validate-skill.sh path/to/SKILL.md
```

## Validation Rules

### Frontmatter Format

**Valid:**
```yaml
---
name: skill-name
description: Brief description
version: 1.0.0
tags: [tag1, tag2]
---
```

**Invalid:**
```yaml
# Missing delimiters
name: skill-name
description: Brief description
```

### Required Fields

- `name` - Skill identifier (alphanumeric, hyphens, colons)
- `description` - Brief description of what skill does

### Optional Fields

- `version` - Semantic version (e.g., 1.0.0)
- `author` - Author name
- `tags` - Array of tags for categorization
- `hooks` - Hook configurations (Start, Stop, PreToolUse, PostToolUse, etc.)
- `parameters` - Skill parameters with validation
- `dependencies` - External tool dependencies

### Hook Events

Valid hook event types:
- `Start` - Skill initialization
- `Stop` - Skill cleanup/validation
- `PreToolUse` - Before tool execution
- `PostToolUse` - After tool execution
- `Notification` - User notifications
- `SessionStart` - Session initialization

### Hook Configuration

Each hook must specify:
- `command` - Shell command to execute
- `description` - What the hook does
- `timeout` - Timeout in milliseconds (optional, default 30000)

**Example:**
```yaml
hooks:
  Stop:
    command: bash "$SKILL_DIR/scripts/cleanup.sh"
    description: Clean up temporary files
    timeout: 10000
```

## Validation Output

### Success
```
✓ All skills valid (25/25)
```

### Errors
```
✗ Validation failed (2 errors)

gh-actions/SKILL.md:
  - Missing frontmatter delimiters
  - Required field 'description' not found

custom-skill/SKILL.md:
  - Invalid hook event type: 'PreExecute' (use 'PreToolUse')
  - Invalid timeout: 'very-long' (must be number)
```

## Error Types

### Critical Errors (Block)
- Missing frontmatter
- Invalid YAML syntax
- Missing required fields
- Invalid hook event types

### Warnings (Non-blocking)
- Missing optional fields (version, author)
- Deprecated options
- Unconventional naming

## Files

### Scripts
- `validate-all-skills.sh` - Validate all skills in .claude/skills/
- `validate-skill.sh` - Validate single skill file
- `check-frontmatter.sh` - Check YAML frontmatter format

### References
- `skill-schema.yaml` - Valid skill options schema
- `hook-events.md` - Valid hook event types
- `examples.md` - Example valid skill files

## Integration

Works with:
- **/refactor-skill** - Validates after refactoring
- **/skill-creator** - Validates newly created skills
- **Stop hook** - Auto-validates before session ends

## Configuration

Create `config.yaml` to customize:
```yaml
validation:
  strict_mode: false          # Treat warnings as errors
  require_version: false      # Require version field
  require_author: false       # Require author field
  check_hooks: true          # Validate hook configurations
  allowed_hook_events:
    - Start
    - Stop
    - PreToolUse
    - PostToolUse
    - Notification
    - SessionStart
```

## Exit Codes

- `0` - All validations passed
- `1` - Validation errors found
- `2` - Critical error (e.g., script failure)

## Best Practices

1. **Use frontmatter** - Always include YAML frontmatter with name and description
2. **Valid hooks** - Only use documented hook event types
3. **Add descriptions** - Document what hooks do
4. **Set timeouts** - Prevent hanging with reasonable timeouts
5. **Test validation** - Run validator after creating/modifying skills

## Examples

See [examples.md](references/examples.md) for valid skill examples.

## Troubleshooting

**Issue:** "Missing frontmatter delimiters"
- **Fix:** Add `---` before and after frontmatter

**Issue:** "Invalid YAML syntax"
- **Fix:** Check indentation and special characters
- **Tool:** Use `yq` to validate YAML

**Issue:** "Invalid hook event"
- **Fix:** Use valid event types (see [hook-events.md](references/hook-events.md))

**Issue:** "Command not found: yq"
- **Fix:** Install yq: `brew install yq`
