# Valid Hook Event Types

Reference: https://code.claude.com/docs/en/skills

## Hook Events

### Start
Triggered when skill is initialized.

**Use cases:**
- Load configuration
- Initialize resources
- Validate dependencies

**Example:**
```yaml
hooks:
  Start:
    command: bash "$SKILL_DIR/scripts/init.sh"
    description: Initialize skill resources
    timeout: 10000
```

### Stop
Triggered before skill stops or session ends.

**Use cases:**
- Clean up temporary files
- Validate work
- Save state
- Run tests

**Example:**
```yaml
hooks:
  Stop:
    command: bash "$SKILL_DIR/scripts/validate.sh"
    description: Validate all changes before stopping
    timeout: 30000
```

### PreToolUse
Triggered before a tool is executed.

**Use cases:**
- Safety checks
- Input validation
- Pre-flight checks
- Block dangerous operations

**Example:**
```yaml
hooks:
  PreToolUse:
    command: bash "$SKILL_DIR/scripts/safety-check.sh"
    description: Validate command safety before execution
    timeout: 5000
```

### PostToolUse
Triggered after a tool completes execution.

**Use cases:**
- Auto-formatting
- File cleanup
- Update indexes
- Notifications

**Example:**
```yaml
hooks:
  PostToolUse:
    command: bash "$SKILL_DIR/scripts/format-files.sh"
    description: Auto-format edited files
    timeout: 10000
```

### Notification
Triggered for user notification events.

**Use cases:**
- Desktop notifications
- Alert on permission prompts
- Alert on idle prompts

**Example:**
```yaml
hooks:
  Notification:
    command: bash "$SKILL_DIR/scripts/desktop-notify.sh"
    description: Show desktop notification
    timeout: 5000
```

### SessionStart
Triggered at session initialization.

**Use cases:**
- Load development context
- Show git status
- Load active story
- Initialize environment

**Example:**
```yaml
hooks:
  SessionStart:
    command: bash "$SKILL_DIR/scripts/load-context.sh"
    description: Load development context at session start
    timeout: 10000
```

## Hook Configuration Fields

### Required Fields

**command** (required)
- Shell command to execute
- Can use environment variables: `$SKILL_DIR`, `$CLAUDE_PROJECT_DIR`
- Example: `bash "$SKILL_DIR/scripts/validate.sh"`

### Optional Fields

**description** (recommended)
- Human-readable description of what hook does
- Shown in logs and error messages
- Example: `Validate all files before stopping`

**timeout** (optional, default: 30000)
- Maximum execution time in milliseconds
- Prevents hanging
- Example: `10000` (10 seconds)

## Environment Variables

Hooks can access:
- `$SKILL_DIR` - Skill directory path
- `$CLAUDE_PROJECT_DIR` - Project root directory
- `$HOME` - User home directory
- All user environment variables

## Exit Codes

Hooks should use standard exit codes:
- `0` - Success, continue
- `1` - Warning, continue with notice
- `2` - Error, block operation
- `Other` - Unexpected error

## Best Practices

1. **Set reasonable timeouts** - Prevent hanging (5-30 seconds typical)
2. **Use $SKILL_DIR** - Portable path references
3. **Add descriptions** - Document what hooks do
4. **Handle errors gracefully** - Return appropriate exit codes
5. **Test hooks** - Verify they work before deploying
6. **Keep hooks fast** - Don't slow down user workflow
7. **Log output** - Help debugging when hooks fail

## Common Patterns

### Validation Hook (Stop)
```yaml
hooks:
  Stop:
    command: bash "$SKILL_DIR/scripts/run-tests.sh"
    description: Run tests before stopping
    timeout: 60000  # Longer for tests
```

### Safety Hook (PreToolUse)
```yaml
hooks:
  PreToolUse:
    command: bash "$SKILL_DIR/scripts/check-dangerous.sh"
    description: Block dangerous operations
    timeout: 3000   # Fast check
```

### Formatting Hook (PostToolUse)
```yaml
hooks:
  PostToolUse:
    command: bash "$SKILL_DIR/scripts/prettier-format.sh"
    description: Auto-format edited files
    timeout: 10000
```

### Context Hook (SessionStart)
```yaml
hooks:
  SessionStart:
    command: bash "$SKILL_DIR/scripts/show-git-status.sh"
    description: Display git status at session start
    timeout: 5000
```

## Invalid Hook Events

These will fail validation:

- `BeforeExecution` - Use `PreToolUse`
- `AfterExecution` - Use `PostToolUse`
- `Init` - Use `Start`
- `Cleanup` - Use `Stop`
- `OnStart` - Use `Start`
- `PreExecute` - Use `PreToolUse`
- `PostExecute` - Use `PostToolUse`

## Multiple Hooks

You can define multiple hook events in one skill:

```yaml
hooks:
  SessionStart:
    command: bash "$SKILL_DIR/scripts/init.sh"
    description: Initialize session
    timeout: 10000
  Stop:
    command: bash "$SKILL_DIR/scripts/validate.sh"
    description: Validate before stopping
    timeout: 30000
  PostToolUse:
    command: bash "$SKILL_DIR/scripts/format.sh"
    description: Format files
    timeout: 10000
```
