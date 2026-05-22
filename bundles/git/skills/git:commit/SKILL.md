---
name: git:commit
description: Create git commits with configurable numbering (issue-based or sequential). Analyzes staged changes and generates commit messages following project conventions. Optionally creates GitHub issues if no active story exists.
scope: project
author: "@thesolutionarchitect"
email: maksym.diabin@gmail.com
hooks:
  Stop:
    command: |
      #!/bin/bash
      CONFIG_FILE="$(dirname "$0")/config.yaml"
      VALIDATION_ENABLED=$(yq e '.validation.enabled' "$CONFIG_FILE" 2>/dev/null || echo "false")
      if [ "$VALIDATION_ENABLED" != "true" ]; then
        echo "Validation disabled - skipping"
        exit 0
      fi
      if git log -1 --pretty=%B | grep -q "^Merge"; then
        echo "Merge commit - skipping validation"
        exit 0
      fi
      PREFIX=$(yq e '.numbering.prefix' "$CONFIG_FILE" 2>/dev/null || echo "PROJ")
      if ! git log -1 --pretty=%B | grep -E "^${PREFIX}-[0-9]+[a-z]?:"; then
        echo "Error: Commit must follow '${PREFIX}-###:' format" >&2
        exit 2
      fi
      echo "Commit format validated (${PREFIX})"
    description: Validate commit format follows project conventions
    timeout: 10000
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
  source: "{{ACTIVE_STORY_FILE}}"     # Path to active story YAML file
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
| `{{ACTIVE_STORY_FILE}}` | Active story file path | .agile-dev-team/active-story.yaml | Yes (issue mode) |
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
1. `/play-story` - Activate an issue (creates `.agile-dev-team/active-story.yaml`)
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

See @references/feature-flags.md.

## Workflows

See @references/workflows.md.

## Examples

See @references/examples.md.

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

See @references/implementation.md for internals, customization, and migration notes.

## See Also

- [create-story](../create-story/SKILL.md) - Create GitHub issues
- [fetch-story](../fetch-story/SKILL.md) - Browse available issues
- [play-story](../play-story/SKILL.md) - Activate issue for work
- [mr](../mr/SKILL.md) - Create pull requests
- [Configuration Reference](../../docs/configuration-reference.md) - Complete config options
- [Abstraction Guide](../../docs/abstraction-guide.md) - Template variable system

---

**Invoke:** `/commit`

**Configuration File:** [config.yaml](config.yaml)

**Example Configuration:** [config.example.yaml](config.example.yaml)

**References:** [references/](references/)
