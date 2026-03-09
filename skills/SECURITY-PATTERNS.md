# Security Patterns for Claude Code Skills

## Why Path Security Matters

Skills execute bash commands that may run from any working directory. Using relative paths creates:

1. **Path Traversal Risks:** Commands could affect unintended files if executed from wrong directory
2. **Injection Vulnerabilities:** Unquoted paths with spaces or special characters can break commands
3. **Reliability Issues:** Skills fail silently when files aren't found at expected locations

## Required Pattern

**Always use `$CLAUDE_PROJECT_DIR` with quoted paths:**

```bash
# ❌ WRONG - Relative path, unquoted
if [ -f .agile-dev-team/active-story.json ]; then
  STORY=$(jq -r '.title' .agile-dev-team/active-story.json)
fi

# ✅ CORRECT - Absolute path with quoted variable
if [ -f "$CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.json" ]; then
  STORY=$(jq -r '.title' "$CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.json")
fi
```

---

## Pattern 1: File Existence Checks

### Before
```bash
if [ ! -f .claude/story-workflow-config.json ]; then
  echo "❌ Configuration missing"
  exit 1
fi
```

### After
```bash
if [ ! -f "$CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json" ]; then
  echo "❌ Configuration missing"
  echo "   Expected: $CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json"
  exit 1
fi
```

**Key Changes:**
- Add `"$CLAUDE_PROJECT_DIR/` prefix to path
- Quote the entire path expression
- Include full path in error messages for debugging

---

## Pattern 2: Multiple Operations on Same File

### Before
```bash
if [ -f .agile-dev-team/active-story.json ]; then
  STORY_ISSUE_NUMBER=$(jq -r '.issueNumber' .agile-dev-team/active-story.json)
  STORY_TITLE=$(jq -r '.title' .agile-dev-team/active-story.json)
  STORY_URL=$(jq -r '.url' .agile-dev-team/active-story.json)
fi
```

### After
```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.json"
if [ -f "$STORY_FILE" ]; then
  STORY_ISSUE_NUMBER=$(jq -r '.issueNumber' "$STORY_FILE")
  STORY_TITLE=$(jq -r '.title' "$STORY_FILE")
  STORY_URL=$(jq -r '.url' "$STORY_FILE")
fi
```

**Benefits:**
- Define the path once in a variable
- Easier to maintain and read
- Quote the variable in all uses

---

## Pattern 3: File Move Operations

### Before
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mv .agile-dev-team/active-story.json .claude/active-story-${TIMESTAMP}.json
```

### After
```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
mv "$CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.json" \
   "$CLAUDE_PROJECT_DIR/.claude/active-story-${TIMESTAMP}.json"
```

**Key Changes:**
- Prefix both source and destination with `$CLAUDE_PROJECT_DIR`
- Quote both paths
- Use line continuation (`\`) for readability

---

## Pattern 4: Directory Changes (cd)

### Before
```bash
cd infrastructure
npm run cdk synth
```

### After
```bash
cd "$CLAUDE_PROJECT_DIR/infrastructure" || {
  echo "❌ Failed to change to infrastructure directory"
  exit 1
}
npm run cdk synth
```

**Key Changes:**
- Use absolute path with `$CLAUDE_PROJECT_DIR`
- Quote the path
- Add error handling with `||` operator
- Exit if cd fails (prevents running commands in wrong directory)

---

## Pattern 5: Variable Definitions

### Before
```bash
CONFIG_FILE=".claude/story-workflow-config.json"
```

### After
```bash
CONFIG_FILE="$CLAUDE_PROJECT_DIR/.claude/story-workflow-config.json"
```

**Key Changes:**
- Add `$CLAUDE_PROJECT_DIR/` prefix inside the quotes
- Keep entire value quoted as single string

---

## Special Cases

### Narrative Text (No Change Needed)

```markdown
This skill stores story data in `.agile-dev-team/active-story.json` for use by other skills.
```

**Rule:** Only fix bash code blocks. Narrative markdown text explaining file locations should remain user-friendly with relative paths.

---

### Error vs Success Messages

```bash
# Success messages: Keep user-friendly short paths
echo "✓ Story saved to .agile-dev-team/active-story.json"

# Error messages: Use full paths for debugging
echo "❌ Cannot read: $CLAUDE_PROJECT_DIR/.agile-dev-team/active-story.json"
```

**Rationale:** Success messages are for users; error messages are for debugging.

---

### Claude Code Tool Invocations (No Change Needed)

```markdown
**Example Tool Use:**
Read: file_path=".agile-dev-team/active-story.json"
```

**Rule:** Claude Code's Read, Write, Edit tools automatically resolve paths from project root. These examples don't need `$CLAUDE_PROJECT_DIR`.

---

## Skill Author Checklist

When writing or reviewing skills with bash code:

- [ ] All `.claude/` paths include `$CLAUDE_PROJECT_DIR` prefix
- [ ] All file paths are quoted: `"$VARIABLE"` or `"$VAR/path"`
- [ ] All `cd` commands use absolute paths with error handling
- [ ] File existence checks (`-f`, `-d`) use quoted absolute paths
- [ ] `jq` operations use variables for repeated file access
- [ ] Error messages include full paths for debugging
- [ ] Move/copy operations quote both source and destination

---

## Common Pitfalls

### 1. Forgetting Quotes Around Variables
```bash
# ❌ WRONG - Will break with spaces in $CLAUDE_PROJECT_DIR
if [ -f $CLAUDE_PROJECT_DIR/.claude/config.json ]; then

# ✅ CORRECT
if [ -f "$CLAUDE_PROJECT_DIR/.claude/config.json" ]; then
```

### 2. Partial Quoting
```bash
# ❌ WRONG - Variable not included in quotes
if [ -f "$CLAUDE_PROJECT_DIR"/.claude/config.json ]; then

# ✅ CORRECT - Entire path quoted
if [ -f "$CLAUDE_PROJECT_DIR/.claude/config.json" ]; then
```

### 3. Missing Error Handling on cd
```bash
# ❌ WRONG - Continues on failure
cd "$CLAUDE_PROJECT_DIR/infrastructure"
npm run cdk synth  # Could run in wrong directory!

# ✅ CORRECT - Exits on failure
cd "$CLAUDE_PROJECT_DIR/infrastructure" || {
  echo "❌ Failed to change directory"
  exit 1
}
npm run cdk synth
```

### 4. Inconsistent Path Usage
```bash
# ❌ WRONG - Mix of relative and absolute
CONFIG="$CLAUDE_PROJECT_DIR/.claude/config.json"
if [ -f "$CONFIG" ]; then
  jq -r '.value' .claude/config.json  # Inconsistent!
fi

# ✅ CORRECT - Use variable consistently
CONFIG="$CLAUDE_PROJECT_DIR/.claude/config.json"
if [ -f "$CONFIG" ]; then
  jq -r '.value' "$CONFIG"
fi
```

---

## Testing Your Skills

### 1. Test from Different Directories
```bash
# Skill should work from any directory
cd /tmp
# Execute your skill - paths should still resolve correctly
```

### 2. Search for Unsafe Patterns
```bash
# Find unquoted .claude/ paths in your skill
grep -n '\.claude/' your-skill/SKILL.md | \
  grep -v '\$CLAUDE_PROJECT_DIR' | \
  grep -v '^\s*#'

# Find unsafe cd commands
grep -n '^cd [^"]' your-skill/SKILL.md
```

### 3. Visual Code Review
- Open skill in editor
- Verify all bash code blocks updated
- Verify narrative text unchanged
- Verify error messages helpful

---

## Environment Variables

### Always Available

- **`$CLAUDE_PROJECT_DIR`**: Absolute path to project root (always set by Claude Code)

### Usage
```bash
# Reference project files
CONFIG="$CLAUDE_PROJECT_DIR/.claude/config.json"

# Navigate to project subdirectories
cd "$CLAUDE_PROJECT_DIR/infrastructure" || exit 1

# Create project-relative paths
OUTPUT="$CLAUDE_PROJECT_DIR/output/report.txt"
```

---

## Summary

**Golden Rule:** Every file path in bash code must be:
1. Prefixed with `"$CLAUDE_PROJECT_DIR/`
2. Fully quoted as `"$VAR/path"`
3. Checked for existence before use
4. Accompanied by clear error messages

Following these patterns ensures skills are secure, reliable, and maintainable.
