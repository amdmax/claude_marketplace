---
name: claude:hooks
description: Comprehensive Claude Code hooks configuration for notifications, validation, auto-formatting, safety checks, and context loading.
author: "@thesolutionarchitect"
email: maksym.diabin@gmail.com
---

# Hooks Management Skill

Comprehensive Claude Code hooks configuration for notifications, validation, auto-formatting, safety checks, and context loading.

## Quick Start

```bash
# Run setup to configure all hooks
bash .claude/skills/hooks/scripts/setup-hooks.sh

# Or invoke via skill
/hooks
```

After setup, restart Claude Code for hooks to take effect.

## Features

### 1. **Desktop Notifications** 🔔
Get native desktop notifications when Claude needs your attention:
- Permission prompts
- Idle prompts
- Works on macOS and Linux

### 2. **Stop Hook Validation** ✅
Run tests and validation before Claude stops:
- Runs `npm test` (configurable)
- Runs `npm run validate:all` (configurable)
- Can block stop if validation fails
- Configurable fail behavior

### 3. **Auto-Formatting** ✨
Automatically format files after Claude edits them:
- **Prettier**: JavaScript, TypeScript, CSS, HTML, JSON, Markdown
- **Black**: Python files
- **PostCSS**: styles.css minification
- Non-blocking (warns if formatter missing)

### 4. **Safety Checks** 🛡️
Block dangerous operations before they execute:
- **Bash commands**: Blocks `rm -rf /`, `dd`, `mkfs`, fork bombs, etc.
- **File writes**: Blocks writing to `.env`, `*.key`, `*.pem`, `secrets.json`, etc.
- Exit code 2 (blocks) on dangerous operations

### 5. **Session Context Loading** 📋
Load development context at session start:
- Git status (last 10 files)
- Recent commits (last 24 hours)
- Active story from `.claude/active-story.json`
- Injected into Claude's context automatically

## Configuration

Edit `.claude/skills/hooks/config.yaml` to customize behavior:

```yaml
# Enable/disable features
notification:
  enabled: true

stop_hooks:
  enabled: true
  run_tests: true
  fail_on_test_error: false

post_tool_use:
  enabled: true
  formatters:
    prettier:
      enabled: true
    black:
      enabled: true

pre_tool_use:
  enabled: true
  safety_checks:
    bash_safety:
      enabled: true

session_start:
  enabled: true
```

After changing config, re-run setup:
```bash
bash .claude/skills/hooks/scripts/setup-hooks.sh
```

## Installation

### Prerequisites

**Already installed:**
- Node.js & npm
- Python 3
- Git
- jq (for JSON parsing)

**Will be installed by setup:**
- Prettier (npm install --save-dev prettier)
- Black (pip3 install black)

### Setup Steps

1. **Run setup script:**
   ```bash
   bash .claude/skills/hooks/scripts/setup-hooks.sh
   ```

2. **Restart Claude Code:**
   ```bash
   # Exit current session and restart
   claude code
   ```

3. **Verify installation:**
   - Edit a file → should auto-format
   - Try `rm -rf /` → should block
   - Stop session → tests should run
   - Check verbose output (ctrl+o) for hook execution

## Hook Details

### Notification Hook
- **Trigger**: Permission prompts, idle prompts
- **Behavior**: Shows desktop notification
- **macOS**: Uses `osascript`
- **Linux**: Uses `notify-send` (install via `sudo apt-get install libnotify-bin`)
- **Timeout**: 5 seconds

### Stop Hook
- **Trigger**: Before Claude stops
- **Behavior**: Runs tests and validation
- **Exit code 0**: Pass (non-blocking)
- **Exit code 1**: Fail (non-blocking warning)
- **Exit code 2**: Critical fail (blocks stop)
- **Timeout**: 120 seconds

### PostToolUse Hook (Formatting)
- **Trigger**: After Edit or Write tool
- **Behavior**: Formats file based on extension
- **Exit code 0**: Success
- **Exit code 1**: Formatter missing (warning)
- **Timeout**: 30 seconds

### PreToolUse Hook (Safety)
- **Trigger**: Before Bash, Edit, or Write tool
- **Behavior**: Checks for dangerous patterns
- **Exit code 0**: Safe (allow)
- **Exit code 2**: Dangerous (block)
- **Timeout**: 5 seconds

### SessionStart Hook
- **Trigger**: At session start
- **Behavior**: Loads git status, commits, active story
- **Output**: Injected into Claude's context
- **Timeout**: 10 seconds

## Integration with Existing Hooks

This skill preserves your existing `.claude/hooks/validate-changes.sh` hook. Both hooks will run in parallel:

1. **Existing hook**: Validates CDK TypeScript and Python syntax
2. **New formatting hook**: Auto-formats files after edits

No conflicts expected - hooks are merged automatically.

## Troubleshooting

### Hooks not running
- Check `.claude/settings.json` has hooks configured
- Verify hook scripts are executable: `chmod +x .claude/skills/hooks/hooks/*/*.sh`
- Restart Claude Code
- Enable debug mode: `claude --debug`
- Check verbose output: ctrl+o

### Formatter not found
- Install Prettier: `npm install --save-dev prettier`
- Install Black: `pip3 install black`
- Re-run setup: `bash .claude/skills/hooks/scripts/setup-hooks.sh`

### Notification not showing
- **macOS**: Should work out of the box
- **Linux**: Install `notify-send`: `sudo apt-get install libnotify-bin`
- Check permissions for desktop notifications

### Permission denied errors
- Make scripts executable: `chmod +x .claude/skills/hooks/**/*.sh`
- Check file permissions in `.claude/skills/hooks/`

### Hooks blocking too much
- Edit `config.yaml` to disable specific checks
- Adjust `blocked_patterns` to be less strict
- Re-run setup to apply changes

## Advanced Usage

### Custom Safety Rules
Add custom patterns to `config.yaml`:

```yaml
pre_tool_use:
  safety_checks:
    bash_safety:
      blocked_patterns:
        - "my-dangerous-command"
```

### Custom Formatters
Add custom formatter to `post_tool_use/format-files.sh`:

```bash
case "$extension" in
  myext)
    my-formatter "$file_path"
    ;;
esac
```

### Disable Specific Hooks
Edit `config.yaml`:

```yaml
notification:
  enabled: false  # Disable notifications
```

Re-run setup to apply.

## Reference Documentation

- **Hook Types**: `.claude/skills/hooks/references/hook-types.md`
- **Formatter Config**: `.claude/skills/hooks/references/formatter-config.md`
- **Safety Rules**: `.claude/skills/hooks/references/safety-rules.md`
- **Troubleshooting**: `.claude/skills/hooks/references/troubleshooting.md`

## Uninstall

To remove all hooks:

```bash
# Clear hooks section from settings.json
# Or manually remove:
# - .claude/skills/hooks/
# - Hooks section from .claude/settings.json
```

Then restart Claude Code.

## Support

- Report issues: [GitHub Issues](https://github.com/anthropics/claude-code/issues)
- Hook documentation: [Claude Code Docs](https://docs.anthropic.com/claude-code)

## License

MIT
