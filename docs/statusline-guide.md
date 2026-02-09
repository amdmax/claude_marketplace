# Claude Code Statusline Guide

## Overview

The Claude Code statusline provides real-time information about your current workspace, git status, and session context. It displays as a compact, single-line status bar with six key components separated by dimmed pipe characters.

## Features

### 1. Directory Name

**Display:** Current working directory basename

**Example:** `claude_marketplace`

**Purpose:** Quickly identify which project you're working in, especially useful when switching between multiple projects.

**Implementation:** Extracted from `workspace.current_dir` JSON field using `basename` command.

### 2. Git Branch

**Display:** Active git branch name

**Example:** `main` or `feature/add-statusline`

**Purpose:** Show which branch you're currently working on without running `git status`.

**Implementation:** Retrieved using `git rev-parse --abbrev-ref HEAD` with `GIT_OPTIONAL_LOCKS=0` to avoid lock contention.

**Behavior:**
- Only displayed when current directory is a git repository
- Gracefully omitted if not in a git repo

### 3. Lines Changed

**Display:** Format `+X/-Y` showing added/removed lines

**Example:** `+42/-18` (42 lines added, 18 lines removed)

**Purpose:** Track your current work progress since the last commit.

**Implementation:** Calculated using `git diff --numstat` and aggregating added/removed lines across all modified files.

**Behavior:**
- Shows `+0/-0` when no changes exist
- Only displayed when in a git repository
- Includes staged and unstaged changes

### 4. Story/Task ID

**Display:** First 30 characters of story/task identifier

**Example:** `AIGMRKT-001: Add marketplace.j` or `Fix statusline rendering bug`

**Purpose:** Keep track of which story or task you're implementing, useful for commit messages and context switching.

**Implementation:** Extracted from `start_here.md` file in the project root using pattern matching:
1. First attempts to find format: `Story: PROJ-123` or `Task: PROJ-123`
2. Falls back to first markdown heading if no story ID found
3. Truncated to 30 characters maximum

**Behavior:**
- Only displayed when `start_here.md` exists
- Gracefully omitted if file not found

### 5. Context Usage

**Display:** Format `ctx:XX%` showing Claude Code context window usage

**Example:** `ctx:45%` (45% of context window used)

**Purpose:** Monitor how much of Claude's context window is consumed, helping you understand when summarization might occur.

**Implementation:** Retrieved from `context_window.used_percentage` JSON field, rounded to nearest integer.

**Behavior:**
- Shows `ctx:0%` if percentage not available
- Always displayed

### 6. Model Name

**Display:** Current Claude model display name

**Example:** `Sonnet 4.5` or `Opus 4.5`

**Purpose:** Identify which Claude model you're currently using, useful when switching between models or understanding response characteristics.

**Implementation:** Retrieved from `model.display_name` JSON field.

**Behavior:**
- Always displayed
- Shows the human-friendly model name (not the API model ID)

## Configuration

### Installation

The statusline script is located at:

```bash
~/.claude/statusline-command.sh
```

### Settings

Configure the statusline in `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /Users/YOUR_USERNAME/.claude/statusline-command.sh"
  }
}
```

**Note:** Replace `YOUR_USERNAME` with your actual username, or use the `~` shorthand if supported.

## Technical Details

### Input Format

The script receives JSON via stdin with the following structure:

```json
{
  "model": {
    "display_name": "Sonnet 4.5"
  },
  "workspace": {
    "current_dir": "/path/to/project"
  },
  "context_window": {
    "used_percentage": 45.2
  }
}
```

### Output Format

The script outputs a single line to stdout with ANSI escape codes for formatting:

```
claude_marketplace | main | +42/-18 | AIGMRKT-001: Add marketplace.j | ctx:45% | Sonnet 4.5
```

**Visual appearance:** All text is dimmed using ANSI escape code `\033[2m`, with pipe separators also dimmed.

### Formatting

- **Separator:** Dimmed pipe character ` | ` between components
- **Text styling:** All components use ANSI escape code `\033[2m` for dimmed appearance
- **Reset code:** `\033[0m` to reset formatting after each component

### Dependencies

- **jq:** JSON parsing
- **git:** Branch and diff statistics (optional, gracefully degraded if not available)
- **bash:** Shell interpreter

## Verification Test

Test the statusline script manually:

```bash
echo '{"model":{"display_name":"Test"},"workspace":{"current_dir":"'$(pwd)'"},"context_window":{"used_percentage":25}}' | bash ~/.claude/statusline-command.sh
```

**Expected output:** Properly formatted (dimmed) text, not raw escape codes like `\033[2m`.

**Example output:**
```
claude_marketplace | main | +5/-2 | ctx:25% | Test
```

## Recent Fixes

### Fix: ANSI Escape Codes Not Rendering (2026-01-31)

**Issue:** The statusline displayed raw escape codes (`\033[2m`) instead of dimmed text.

**Root cause:** Line 73 used `printf "$output"` which didn't interpret escape sequences.

**Solution:** Changed to `echo -e -n "$output"`:
- `-e` flag enables interpretation of backslash escape sequences
- `-n` flag suppresses trailing newline

**File:** `~/.claude/statusline-command.sh:73`

**Change:**
```bash
# Before
printf "$output"

# After
echo -e -n "$output"
```

## Troubleshooting

### Issue: Statusline not appearing

**Causes:**
1. `statusLine.command` not configured in settings.json
2. Script file doesn't exist or isn't executable

**Solution:**
```bash
# Check if script exists
ls -la ~/.claude/statusline-command.sh

# Make executable if needed
chmod +x ~/.claude/statusline-command.sh

# Verify settings.json configuration
cat ~/.claude/settings.json | jq '.statusLine'
```

### Issue: Raw escape codes shown instead of dimmed text

**Cause:** Using old version of script with `printf` instead of `echo -e -n`.

**Solution:** Update line 73 to use `echo -e -n "$output"` (see Recent Fixes above).

### Issue: Git branch not showing

**Causes:**
1. Not in a git repository
2. Git not installed or not in PATH

**Solution:**
```bash
# Verify git is available
which git

# Check if current directory is a git repo
git rev-parse --abbrev-ref HEAD
```

### Issue: Story/Task ID not showing

**Cause:** `start_here.md` file doesn't exist in project root.

**Solution:** Create a `start_here.md` file with your story ID:

```markdown
# Story: PROJ-123 - Implement feature X

Description of what you're working on...
```

## Implementation Notes

### Performance Optimization

The script uses `GIT_OPTIONAL_LOCKS=0` when running git commands to avoid lock contention:

```bash
GIT_OPTIONAL_LOCKS=0 git rev-parse --abbrev-ref HEAD
```

This prevents the script from creating unnecessary lock files that could interfere with other git operations.

### Graceful Degradation

Components are only added if they have values:

```bash
if [ -n "$git_branch" ]; then
    components+=("$git_branch")
fi
```

This ensures the statusline works correctly even when:
- Not in a git repository
- `start_here.md` doesn't exist
- Context percentage is unavailable

### Cross-Platform Compatibility

The script uses POSIX-compliant bash features and should work on:
- macOS (tested)
- Linux distributions
- WSL (Windows Subsystem for Linux)

## Customization

### Adding Custom Components

To add a new component to the statusline:

1. Extract data from JSON input or run commands
2. Add to `components` array
3. The existing loop will automatically format it

Example - adding current time:

```bash
# After line 62, before components array building
current_time=$(date +%H:%M)

# Add to components array
components+=("$current_time")
```

### Changing Separator

To use a different separator, modify line 68:

```bash
# Current: dimmed pipe
output="$output \033[2m|\033[0m "

# Example: dimmed dot
output="$output \033[2m•\033[0m "

# Example: arrow
output="$output \033[2m→\033[0m "
```

### Changing Text Style

To use different ANSI formatting:

```bash
# Current: dimmed (2m)
output="$output\033[2m${components[$i]}\033[0m"

# Bold (1m)
output="$output\033[1m${components[$i]}\033[0m"

# Italic (3m)
output="$output\033[3m${components[$i]}\033[0m"

# Colored (e.g., cyan = 36m)
output="$output\033[36m${components[$i]}\033[0m"
```

## See Also

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [ANSI Escape Codes Reference](https://en.wikipedia.org/wiki/ANSI_escape_code)
- [jq Manual](https://stedolan.github.io/jq/manual/)
