---
description: Create a Claude Code hook with interactive configuration
---

Create a new Claude Code hook by asking the user about:

1. **Hook Event** - Which event should trigger this hook:
   - PreToolUse - Before a tool executes (can block with exit 2)
   - PermissionRequest - When permission dialog shows
   - PostToolUse - After a tool completes successfully
   - Notification - When Claude sends notifications
   - UserPromptSubmit - When user submits a prompt (stdout added to context)
   - Stop - When main agent finishes responding
   - SubagentStop - When subagent finishes responding
   - PreCompact - Before compact operation
   - SessionStart - When session starts (stdout added to context, use for env vars)
   - SessionEnd - When session ends

2. **Tool Matcher** - Which tools should trigger this hook:
   - Specific tool name (e.g., "Edit", "Bash", "Write")
   - Multiple tools with regex (e.g., "Edit|Write")
   - All tools with "*" or ""

3. **Hook Purpose** - What should this hook do?

4. **Exit Code Behavior**:
   - Exit 0: Success (stdout shown in verbose mode, or added to context for UserPromptSubmit/SessionStart)
   - Exit 2: Blocking error (blocks tool execution, stderr shown to Claude)
   - Other non-zero: Non-blocking error (execution continues, stderr in verbose mode)

After gathering requirements, create the hook configuration in `.claude/settings.json`.

## Available Hook Input (JSON via stdin)

All hooks receive:
- `session_id` - Unique session identifier
- `transcript_path` - Path to conversation JSON
- `cwd` - Current working directory
- `permission_mode` - Current mode (default/plan/acceptEdits/bypassPermissions)
- `hook_event_name` - Triggering event name

Event-specific fields:
- `tool_name` - Name of tool being used
- `tool_input` - Tool parameters
- `tool_response` - Tool output (PostToolUse only)
- `message` - Notification content
- `prompt` - User's submitted prompt
- `env_file` - Path to persist env vars (SessionStart only)

## Environment Variables Available

- `CLAUDE_PROJECT_DIR` - Absolute path to project root
- `CLAUDE_ENV_FILE` - File to persist env vars (SessionStart only)
- `CLAUDE_CODE_REMOTE` - "true" if remote, otherwise local

## Examples

**Block unsafe file paths:**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "input=$(cat); path=$(echo \"$input\" | jq -r '.tool_input.file_path // .tool_input.path'); if echo \"$path\" | grep -q '\\.\\./'; then echo 'Path traversal detected!' >&2; exit 2; fi"
      }]
    }]
  }
}
```

**Add context on every prompt:**
```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "echo 'Skip acknowledgments - focus on the solution'"
      }]
    }]
  }
}
```

After creating the hook, run `/hooks` to verify it was registered correctly.
