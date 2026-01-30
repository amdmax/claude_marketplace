---
name: commit
description: Create git commits with configurable numbering (issue-based or sequential). Analyzes staged changes and generates commit messages following project conventions. Optionally creates GitHub issues if no active story exists.
hooks:
  Stop:
    - hooks:
        - type: command
          command: |
            #!/bin/bash
            # Read configuration
            CONFIG_FILE="$(dirname "$0")/config.yaml"

            # Check if validation is enabled
            VALIDATION_ENABLED=$(yq e '.validation.enabled' "$CONFIG_FILE" 2>/dev/null || echo "false")

            if [ "$VALIDATION_ENABLED" != "true" ]; then
              echo "✓ Validation disabled - skipping"
              exit 0
            fi

            # Skip validation for merge commits
            if git log -1 --pretty=%B | grep -q "^Merge"; then
              echo "✓ Merge commit - skipping validation"
              exit 0
            fi

            # Read prefix from config
            PREFIX=$(yq e '.numbering.prefix' "$CONFIG_FILE" 2>/dev/null || echo "PROJ")

            # Verify commit format - accept both issue-based and sequential
            if ! git log -1 --pretty=%B | grep -E "^${PREFIX}-[0-9]+[a-z]?:"; then
              echo "Error: Commit must follow '${PREFIX}-###:' format" >&2
              echo "  Valid: ${PREFIX}-157: description (issue-based)" >&2
              echo "  Valid: ${PREFIX}-001: description (sequential)" >&2
              echo "  Valid: ${PREFIX}-157a: description (with suffix)" >&2
              exit 2
            fi
            echo "✓ Commit format validated (${PREFIX})"
          timeout: 10
---

# Commit Automation

**Category:** Core Workflow
**Priority:** Tier 1 (Critical)

## Purpose

Automates git commits with intelligent numbering, change analysis, and standardized commit message generation. Supports both issue-based (GitHub Issues) and sequential numbering modes.

## Key Features

- **Flexible numbering** - Issue-based ({{PROJECT_PREFIX}}-{issueNumber}) or sequential ({{PROJECT_PREFIX}}-001)
- **Auto-issue creation** - Creates GitHub issues via `/create-story` when no active story exists
- **Smart grouping** - Detects related commits and suggests suffixes (e.g., {{PROJECT_PREFIX}}-157a, 157b)
- **Change analysis** - Analyzes staged changes to generate descriptive commit messages
- **Convention enforcement** - Post-commit validation hook ensures format compliance
- **Co-author attribution** - Automatically adds Claude co-author line

## Configuration

This skill requires the following configuration in `config.yaml`:

### Required Variables

```yaml
# Project Identity
numbering:
  prefix: {{PROJECT_PREFIX}}          # Your project prefix (e.g., MYAPP)
  mode: {{NUMBERING_MODE}}            # "issue-based" or "sequential"

# Repository (for issue-based mode)
repository:
  slug: "{{REPO_SLUG}}"               # GitHub repository (e.g., owner/repo)

# Paths
issue:
  source: "{{ACTIVE_STORY_FILE}}"     # Path to active story JSON file
```

### Optional Configuration

```yaml
# Feature Flags
features:
  create_if_missing: {{true/false}}   # Auto-create issues if missing
  grouping_enabled: {{true/false}}    # Enable commit grouping detection
  validation_enabled: {{true/false}}  # Enable post-commit validation

# Grouping Settings
grouping:
  time_window: "4 hours ago"          # How far back to look for related commits
  confidence_threshold: 60            # Minimum % confidence to suggest grouping

# Message Format
message:
  max_summary_length: 72              # First line max length
  include_co_author: true             # Add Claude co-author line
```

### Template Variables Reference

| Variable | Purpose | Example Value | Required |
|----------|---------|---------------|----------|
| `{{PROJECT_PREFIX}}` | Commit prefix identifier | MYAPP | Yes |
| `{{NUMBERING_MODE}}` | Numbering strategy | issue-based | Yes |
| `{{REPO_SLUG}}` | GitHub repository | owner/repo | Yes (issue mode) |
| `{{ACTIVE_STORY_FILE}}` | Active story file path | .claude/active-story.json | Yes (issue mode) |
| `{{CREATE_MISSING_ISSUES}}` | Auto-create issues | true | No |
| `{{GROUPING_ENABLED}}` | Enable grouping | true | No |
| `{{VALIDATION_HOOK_ENABLED}}` | Enable validation | true | No |

## Usage

### Basic Usage

```bash
# Stage your changes
git add file1.ts file2.ts

# Invoke the skill
/commit
```

Or in natural language:
```
Create a commit for these changes
Commit the staged files
Make a commit with these updates
```

The skill will:
1. Verify staged changes exist
2. Determine commit number (issue-based or sequential)
3. Analyze your changes
4. Generate descriptive message
5. Create commit with co-author attribution

### Advanced Usage

#### Example 1: Issue-Based Workflow

```yaml
# config.yaml
numbering:
  mode: "issue-based"
  prefix: MYAPP
  issue:
    create_if_missing: true
```

**Workflow:**
1. `/play-story` - Activate an issue (creates `.claude/active-story.json`)
2. Make code changes
3. `git add .`
4. `/commit` - Creates commit as `MYAPP-157: description`

If no active story exists and `create_if_missing: true`:
1. `/commit` automatically calls `/create-story`
2. User describes the issue
3. Issue is created and activated
4. Commit proceeds with new issue number

#### Example 2: Sequential Workflow

```yaml
# config.yaml
numbering:
  mode: "sequential"
  prefix: MYAPP
```

**Workflow:**
1. Make code changes
2. `git add .`
3. `/commit` - Finds highest MYAPP-### and increments (e.g., MYAPP-042)

#### Example 3: Grouped Commits

When working on the same files recently:

```bash
# First commit
git add feature.ts
/commit
# → MYAPP-157: Add initial feature structure

# Continue working on same files (within 4 hours)
git add feature.ts tests.ts
/commit

# Skill detects HIGH confidence (same files, <1 hour)
# Offers options:
#   [1] MYAPP-157a (grouped) - RECOMMENDED (HIGH confidence)
#   [2] MYAPP-157 (new independent commit)

# If you choose [1]:
# → MYAPP-157a: Add feature tests and validation
```

## Feature Flags

### `numbering.mode`

**Default:** `"issue-based"`

**Description:** Determines how commit numbers are assigned.

**Options:**
- `"issue-based"` - Use GitHub issue numbers from active story
- `"sequential"` - Use auto-incrementing counter

**When to use issue-based:**
- Direct traceability to GitHub issues
- Working on specific issues/stories
- Integrates with `/fetch-story` and `/play-story` workflows

**When to use sequential:**
- No GitHub issue integration needed
- Simpler, faster workflow
- Fallback when issue creation fails

**Example:**
```yaml
numbering:
  mode: "issue-based"  # or "sequential"
  prefix: MYAPP
```

### `issue.create_if_missing`

**Default:** `true`

**Description:** Auto-create GitHub issue if no active story exists (issue-based mode only).

**When to enable:**
- Want automated issue creation
- Prefer every commit tied to an issue
- Trust Claude to create good issues

**When to disable:**
- Manual issue creation preferred
- Want to fail fast if no active story
- Use sequential mode as fallback

**Example:**
```yaml
numbering:
  mode: "issue-based"
  issue:
    create_if_missing: true
```

### `grouping.enabled`

**Default:** `true`

**Description:** Detect related commits and suggest grouping with suffixes (a, b, c).

**When to enable:**
- Make multiple related commits
- Want clear progression (157, 157a, 157b)
- Appreciate intelligent suggestions

**When to disable:**
- Prefer independent commits always
- Don't want grouping prompts
- Simpler commit history

**Example:**
```yaml
grouping:
  enabled: true
  time_window: "4 hours ago"
  confidence_threshold: 60
```

### `validation.enabled`

**Default:** `true`

**Description:** Enable post-commit validation hook to ensure format compliance.

**When to enable:**
- Enforce commit message standards
- Catch format errors immediately
- Team standardization

**When to disable:**
- Testing/development
- Non-standard commit needs
- Hook conflicts

**Example:**
```yaml
validation:
  enabled: true
  skip_merge_commits: true
```

## Workflows

### Workflow 1: Issue-Based with Auto-Creation

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: MYAPP
  issue:
    create_if_missing: true
```

**Steps:**
1. Make code changes
2. `git add .`
3. `/commit`
4. If no active story:
   - Skill calls `/create-story`
   - User describes issue
   - Issue created automatically
5. Commit created: `MYAPP-{issueNumber}: description`

### Workflow 2: Sequential Only

**Configuration:**
```yaml
numbering:
  mode: "sequential"
  prefix: MYAPP
```

**Steps:**
1. Make code changes
2. `git add .`
3. `/commit`
4. Skill finds highest MYAPP-### commit
5. Increments number
6. Commit created: `MYAPP-042: description`

### Workflow 3: Issue-Based with Manual Issues

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: MYAPP
  issue:
    create_if_missing: false
```

**Steps:**
1. `/fetch-story` - Browse available issues
2. `/play-story` - Activate an issue
3. Make code changes
4. `git add .`
5. `/commit` - Uses active issue number

## Examples

### Example 1: First-Time Setup

**Scenario:** Setting up commit skill in a new project.

**Configuration:**
```yaml
# config.yaml
numbering:
  mode: "issue-based"
  prefix: ACME
  issue:
    source: ".claude/active-story.json"
    create_if_missing: true

repository:
  slug: "acme/web-app"

grouping:
  enabled: true

validation:
  enabled: true
```

**Usage:**
```bash
# Make changes
echo "console.log('hello')" > index.js
git add index.js

# First commit - no active story
/commit

# Skill response:
# "📋 No active story. Creating one..."
# [User describes issue: "Add initial application structure"]
# "✓ Created issue #1"
# "Creating commit: ACME-1: Add initial application structure"
```

**Result:**
- GitHub issue #1 created
- Commit: `ACME-1: Add initial application structure`
- `.claude/active-story.json` created

### Example 2: Grouped Commits

**Scenario:** Making multiple related commits on same feature.

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: WEBAPP
grouping:
  enabled: true
  time_window: "4 hours ago"
  confidence_threshold: 60
```

**Usage:**
```bash
# First commit
git add auth.ts
/commit
# → WEBAPP-42: Add authentication service

# 30 minutes later, continue on same feature
git add auth.ts auth.test.ts
/commit

# Skill detects HIGH confidence:
# "Detected recent commit on same files:
#  WEBAPP-42: Add authentication service (30 minutes ago)
#  File overlap: 100% (1/1 files)
#
#  [1] WEBAPP-42a (grouped) - RECOMMENDED (HIGH confidence)
#  [2] WEBAPP-42 (new independent commit)"

# User selects [1]
# → WEBAPP-42a: Add authentication tests and validation
```

### Example 3: Sequential Fallback

**Scenario:** Issue creation fails (network down, auth issues).

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: APP
  issue:
    create_if_missing: true

numbering:
  sequential:
    digits: 3
    format: "%s-%03d"
```

**Usage:**
```bash
git add feature.ts
/commit

# Skill tries to create issue, fails:
# "⚠️ Issue creation failed (network error)"
# "Using sequential numbering as fallback..."
# "Found highest commit: APP-024"
# "Creating commit: APP-025: Add new feature"
```

**Result:**
- Graceful fallback to sequential mode
- Commit still created: `APP-025: Add new feature`
- Work continues despite network issues

## Integration

### With Other Skills

This skill integrates with:

- **create-story** - Auto-creates GitHub issues when missing
- **fetch-story** - Browse and select issues to work on
- **play-story** - Activate issue before committing
- **mr** - Pull requests reference commit numbers

**Typical workflow:**
```bash
/fetch-story          # Browse available issues
/play-story           # Activate issue #157
# Make changes
/commit              # Commits as PROJ-157: description
/commit              # Additional work as PROJ-157a: description
/mr                  # Create PR referencing PROJ-157 commits
```

### With Hooks

This skill provides a post-commit validation hook. Configure in your project:

```yaml
# .claude/hooks.yaml
hooks:
  post_commit:
    - name: "validate-commit-format"
      command: |
        # Validation logic from SKILL.md hooks section
      enabled: true
```

The hook automatically validates commit format based on your `config.yaml` prefix.

## Troubleshooting

### Issue: "No staged changes to commit"

**Symptoms:**
- Error message when running `/commit`
- No files in `git diff --cached`

**Solution:**
Stage your files first:
```bash
git add file1.ts file2.ts
# or
git add .
```

---

### Issue: "Failed to create GitHub issue"

**Symptoms:**
- Error during issue creation
- Falls back to sequential numbering

**Solutions:**

1. Check GitHub CLI authentication:
```bash
gh auth status
gh auth login
```

2. Verify repository slug in config:
```yaml
repository:
  slug: "correct-owner/correct-repo"
```

3. Disable auto-creation and use manual issues:
```yaml
numbering:
  issue:
    create_if_missing: false
```

---

### Issue: Validation hook rejects commit

**Symptoms:**
- Commit created but validation fails
- Error: "Commit must follow '{{PREFIX}}-###:' format"

**Solutions:**

1. Check config.yaml prefix matches commit:
```yaml
numbering:
  prefix: MYAPP  # Must match commit prefix
```

2. Verify commit message format:
```
✓ Correct: MYAPP-123: Add new feature
✗ Wrong: MYAPP123: Add new feature
✗ Wrong: myapp-123: Add new feature
✗ Wrong: Add new feature
```

3. Temporarily disable validation:
```yaml
validation:
  enabled: false
```

---

### Issue: Grouping not suggesting suffixes

**Symptoms:**
- Making related commits
- No grouping suggestions appear

**Solutions:**

1. Check grouping is enabled:
```yaml
grouping:
  enabled: true
```

2. Verify time window:
```yaml
grouping:
  time_window: "4 hours ago"  # Expand if needed: "8 hours ago"
```

3. Check confidence threshold:
```yaml
grouping:
  confidence_threshold: 60  # Lower to 40 for more suggestions
```

4. Ensure file overlap exists:
```bash
# Current changes
git diff --cached --name-only

# Recent commits
git log --since="4 hours ago" --name-only
```

## Implementation Details

### How It Works

**High-level process:**

1. **Verification** - Checks for staged changes (`git diff --cached`)
2. **Number determination:**
   - Issue-based: Read `.claude/active-story.json` → `/create-story` if missing → extract issueNumber
   - Sequential: Query git log → find highest {{PREFIX}}-### → increment
3. **Grouping detection** (optional):
   - Get recent commits (last N hours)
   - Calculate file overlap with staged changes
   - Compute confidence score
   - Suggest suffix if high confidence
4. **Message generation:**
   - Analyze staged changes (`git diff --cached`)
   - Generate descriptive commit message
   - Format: `{{PREFIX}}-###[suffix]: description`
5. **Commit creation:**
   - Execute `git commit` with generated message
   - Add co-author line if enabled
6. **Validation** (optional):
   - Post-commit hook verifies format
   - Regex check: `^{{PREFIX}}-[0-9]+[a-z]?:`

### Dependencies

This skill requires:
- **Git** - Version control system
- **GitHub CLI (gh)** - For issue creation (issue-based mode only)
- **jq** - JSON parsing (active story file)
- **yq** - YAML parsing (config file)
- **create-story skill** - For auto-issue creation (optional)

### Files Created/Modified

This skill may create or modify:
- `.claude/active-story.json` - Active issue tracking (issue-based mode)
- Git commit history - New commits with standardized format

## Customization

### Extending This Skill

**Custom commit message format:**

Modify the message generation logic in SKILL.md to use your preferred format:

```yaml
# In config.yaml
message:
  format: "{{prefix}}-{{number}}: {{type}}: {{description}}"
  # Example: MYAPP-123: feat: Add new feature
```

**Custom grouping algorithm:**

Adjust confidence scoring:

```yaml
grouping:
  min_overlap_high: 70      # Stricter HIGH confidence (default: 50)
  min_overlap_medium: 40    # Stricter MEDIUM confidence (default: 30)
  time_threshold_high: 0.5  # Tighter time window (default: 1 hour)
```

### Creating Variants

To create a project-specific variant:

```bash
# Copy and rename
cp -r .claude/skills/commit .claude/skills/commit-experimental

# Customize config
vim .claude/skills/commit-experimental/config.yaml

# Modify SKILL.md for specific use case
vim .claude/skills/commit-experimental/SKILL.md
```

## Migration Notes

**Source Projects:**
- Landing page (AIGWS prefix) - Jan 30, 2026
- Vibe coding course (AIGCODE prefix) - Jan 28, 2026
- News bot (AIGNEWS prefix) - Jan 19, 2026

**Abstraction Changes:**
- Hardcoded prefixes (AIGWS, AIGCODE, AIGNEWS) → `{{PROJECT_PREFIX}}`
- Hardcoded validation regex → Dynamic prefix from config
- Project-specific hooks → Generic template with config-driven validation
- Separate configurations merged into single configurable skill

**Variations Merged:**
- Issue-based numbering (AIGWS, AIGCODE)
- Sequential numbering (AIGNEWS)
- Grouping detection (AIGWS, AIGCODE)
- All three approaches now available via `numbering.mode` config flag

## See Also

- [create-story](../create-story/SKILL.md) - Create GitHub issues
- [fetch-story](../fetch-story/SKILL.md) - Browse available issues
- [play-story](../play-story/SKILL.md) - Activate issue for work
- [mr](../mr/SKILL.md) - Create pull requests
- [Configuration Reference](../../docs/configuration-reference.md) - Complete config options
- [Abstraction Guide](../../docs/abstraction-guide.md) - Template variable system

## Notes

**Best Practices:**
- Always stage changes before running `/commit`
- Use issue-based mode for traceability
- Enable grouping for related commits
- Keep commit messages under 72 characters

**Common Patterns:**
```bash
# Standard workflow
git add .
/commit

# With explicit issue
/play-story    # Select issue first
git add .
/commit        # Uses active issue

# Quick sequential
# config: mode: "sequential"
git add .
/commit        # Auto-increments

# Multiple related commits
git add feature.ts
/commit        # PROJ-42: Initial feature
git add tests.ts
/commit        # PROJ-42a: Add tests (grouped)
git add docs.md
/commit        # PROJ-42b: Add documentation (grouped)
```

---

**Invoke:** `/commit`

**Configuration File:** [config.yaml](config.yaml)

**Example Configuration:** [config.example.yaml](config.example.yaml)

**References:** [references/](references/)
