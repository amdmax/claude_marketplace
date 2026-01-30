---
name: mr
description: Push the current branch to remote and create a pull request to default branch. Intelligently handles merged/closed PRs by creating new branches based on actual changes. Detects and groups commits by theme to create focused PRs.

# Claude Code Extensions
disable-model-invocation: true

# Allowed Tools
allowed-tools:
  - "Bash(git*)"
  - "Bash(gh*)"
  - "Bash(jq*)"
  - "Bash(yq*)"
  - "Bash(test*)"
  - "Bash([*)"
  - "Bash(wc*)"
  - "Bash(tr*)"
  - "Bash(echo*)"
  - "Bash(timeout*)"
  - "AskUserQuestion"
  - "Read(.claude/active-story.json)"

# Hooks
hooks:
  Stop:
    - type: command
      command: |
        #!/bin/bash
        # Verify PR was created or branch was pushed
        if [ -n "$PR_URL" ]; then
          echo "✓ PR created: $PR_URL"
          exit 0
        elif [ -n "$BRANCH_PUSHED" ]; then
          echo "✓ Branch pushed: $BRANCH_PUSHED"
          exit 0
        else
          echo "❌ No PR created or branch pushed"
          exit 2
        fi
      timeout: 5
---

# /mr - Merge Request Creation Skill

**Category:** Core Workflow
**Priority:** Tier 1 (Critical)

## Purpose

Automates pull request creation with intelligent branch management, theme-based commit grouping, and comprehensive PR descriptions. Handles complex scenarios like merged/closed PRs and multi-theme branches.

## Key Features

- **Smart branch management** - Handles merged/closed PRs by creating new branches
- **Theme detection** - Groups commits by similarity for focused PRs
- **Story integration** - Integrates with active story/issue workflow
- **Cherry-pick workflow** - Split multi-theme branches into separate PRs
- **Auto-generated descriptions** - Creates comprehensive PR bodies with test plans
- **Conflict resolution** - Intelligent conflict handling during cherry-picks

## Configuration

This skill requires the following configuration in `config.yaml`:

### Required Variables

```yaml
# Repository Settings
repository:
  slug: "{{REPO_SLUG}}"                # GitHub repository (owner/repo)
  default_branch: "{{DEFAULT_BRANCH}}" # Target branch (main/master)
  default_remote: "{{DEFAULT_REMOTE}}" # Git remote name (origin)

# Story Integration
story_integration:
  active_story_file: "{{ACTIVE_STORY_FILE}}"
  branch_format: "{{STORY_PREFIX}}-{issue_number}-{slug}"

# Branch Naming
branch_naming:
  story_prefix: "{{STORY_PREFIX}}"     # Prefix for story branches (story)
  max_length: {{MAX_BRANCH_LENGTH}}    # Max branch name length (25)
```

### Optional Configuration

```yaml
# Theme Detection
theme_detection:
  enabled: {{THEME_DETECTION_ENABLED}} # Enable theme grouping
  similarity_threshold: {{SIMILARITY_THRESHOLD}} # 0.40 = 40% similarity

# PR Creation
pr_creation:
  footer: "{{PR_FOOTER}}"              # PR footer text
  include_test_plan: true              # Include test plan section
```

### Template Variables Reference

| Variable | Purpose | Example Value | Required |
|----------|---------|---------------|----------|
| `{{REPO_SLUG}}` | GitHub repository | owner/repo | Yes |
| `{{DEFAULT_BRANCH}}` | Target branch | main | Yes |
| `{{DEFAULT_REMOTE}}` | Git remote name | origin | Yes |
| `{{STORY_PREFIX}}` | Story branch prefix | story | Yes |
| `{{ACTIVE_STORY_FILE}}` | Active story file path | .claude/active-story.json | Yes |
| `{{MAX_BRANCH_LENGTH}}` | Max branch name length | 25 | No |
| `{{THEME_DETECTION_ENABLED}}` | Enable theme detection | true | No |
| `{{SIMILARITY_THRESHOLD}}` | Theme similarity threshold | 0.40 | No |
| `{{PR_FOOTER}}` | PR footer text | 🤖 Generated with Claude Code | No |

## Usage

### Basic Usage

```bash
# Simple workflow
/mr  # Creates or updates PR automatically
```

Or in natural language:
```
Create a pull request for this branch
Make a PR for these changes
Open a merge request
```

The skill will:
1. Check for uncommitted changes
2. Detect PR status (merged/closed/open)
3. Analyze commits for themes
4. Create focused PR(s) with generated descriptions

### Advanced Usage

#### Example 1: Story-Based PR

```yaml
# config.yaml
story_integration:
  active_story_file: ".claude/active-story.json"
  include_story_in_title: true
  branch_format: "story-{issue_number}-{slug}"
```

**Workflow:**
```bash
/play-story  # Select story #157
# ... make changes ...
/commit
/mr  # Creates story-157-* branch with story context in PR
```

#### Example 2: Multi-Theme Branch Splitting

When your branch has unrelated commits:

```bash
# Branch has 5 commits:
# - 3 commits about feature X
# - 2 commits about dependency updates

/mr

# Skill detects themes:
# Theme 1: "Feature implementation" (3 commits, 60% similarity)
# Theme 2: "Dependency updates" (2 commits, 85% similarity)

# You select which themes to create PRs for:
# [x] Feature implementation
# [x] Dependency updates

# Result:
# - PR #1: feature-implementation branch (3 commits)
# - PR #2: dependency-updates branch (2 commits)
```

#### Example 3: Handling Merged PR

```bash
# Current branch already has merged PR
/mr

# Skill detects merged PR
# Analyzes uncommitted changes
# Creates new branch: "add-validation-logic"
# Creates fresh PR with new changes only
```

## Feature Flags

### `theme_detection.enabled`

**Default:** `true`

**Description:** Automatically detect and group commits by theme for focused PRs.

**When to enable:**
- Branch has multiple unrelated commits
- Want separate PRs for different concerns
- Improve code review quality

**When to disable:**
- All commits are related
- Prefer single PR for all changes
- Simpler workflow

**Example:**
```yaml
theme_detection:
  enabled: true
  min_commits: 2
  similarity_threshold: 0.40
```

### `pr_creation.include_test_plan`

**Default:** `true`

**Description:** Include test plan section in PR body.

**Example:**
```yaml
pr_creation:
  include_test_plan: true
  include_impact: true
  include_categories: true
```

### `story_integration.include_story_in_title`

**Default:** `true`

**Description:** Include story number in PR title when active story exists.

**Example:**
```yaml
story_integration:
  include_story_in_title: true
  include_story_progress: true
```

## Workflows

### Workflow 1: Simple PR Creation

**Configuration:**
```yaml
repository:
  slug: "myorg/myrepo"
  default_branch: "main"
```

**Steps:**
1. Make changes and commit
2. `/mr`
3. PR created to main branch

### Workflow 2: Story-Based PR

**Configuration:**
```yaml
repository:
  slug: "myorg/myrepo"
story_integration:
  include_story_in_title: true
  branch_format: "story-{issue_number}-{slug}"
```

**Steps:**
1. `/play-story` - Activate issue #42
2. Make changes and `/commit`
3. `/mr` - Creates PR with "Story #42: Feature Name" title

### Workflow 3: Theme-Based PR Splitting

**Configuration:**
```yaml
theme_detection:
  enabled: true
  similarity_threshold: 0.40
```

**Steps:**
1. Branch has 6 unrelated commits
2. `/mr`
3. Skill detects 2 themes
4. Select themes to split
5. Creates 2 focused PRs via cherry-picking

## Examples

### Example 1: First PR from Feature Branch

**Scenario:** Creating PR from feature branch.

**Configuration:**
```yaml
repository:
  slug: "acme/webapp"
  default_branch: "main"
  default_remote: "origin"
```

**Usage:**
```bash
git checkout -b add-authentication
# ... make changes ...
git add .
/commit
/mr
```

**Result:**
- Branch pushed to origin
- PR created: "Add authentication system"
- PR body includes commits, test plan, impact analysis

### Example 2: Handling Merged PR with New Changes

**Scenario:** Branch's PR was merged, but you have new uncommitted changes.

**Usage:**
```bash
# On branch "add-auth" (PR already merged)
# Make new changes
vim src/auth.ts

/mr
# Skill detects merged PR
# Analyzes changes: "Add token validation"
# Creates new branch: "add-token-validation"
# Creates new PR
```

**Result:**
- New branch created from changes
- Fresh PR without merged commits

### Example 3: Multi-Theme PR Splitting

**Scenario:** Branch has feature work + dependency updates.

**Configuration:**
```yaml
theme_detection:
  enabled: true
  similarity_threshold: 0.40
```

**Branch commits:**
```
{{PROJECT_PREFIX}}-042: Add user authentication
{{PROJECT_PREFIX}}-042a: Add login form
{{PROJECT_PREFIX}}-042b: Add password validation
{{PROJECT_PREFIX}}-043: Update React to v18
{{PROJECT_PREFIX}}-044: Update TypeScript to v5
```

**Usage:**
```bash
/mr

# Skill output:
# Detected 2 themes:
#
# Theme 1: "Authentication feature" (70% similarity)
#   - {{PROJECT_PREFIX}}-042: Add user authentication
#   - {{PROJECT_PREFIX}}-042a: Add login form
#   - {{PROJECT_PREFIX}}-042b: Add password validation
#
# Theme 2: "Dependency updates" (90% similarity)
#   - {{PROJECT_PREFIX}}-043: Update React to v18
#   - {{PROJECT_PREFIX}}-044: Update TypeScript to v5
#
# Create separate PRs? [Y/n]
```

**Result:**
- PR #1: "Add authentication feature" (3 commits)
- PR #2: "Update dependencies" (2 commits)
- Original branch preserved

## Integration

### With Other Skills

This skill integrates with:

- **commit** - Creates commits that mr organizes into PRs
- **play-story** - Activates story for story-based branches
- **fetch-story** - Browse issues before creating PRs
- **create-story** - Create issue before PR

**Typical workflow:**
```bash
/fetch-story          # Browse available issues
/play-story           # Activate issue #157
# Make changes
/commit              # Create commits
/mr                  # Create PR with story context
```

### With GitHub

Uses GitHub CLI (`gh`) for:
- `gh pr list` - Check existing PRs
- `gh pr create` - Create new PRs
- `gh pr view` - View PR details
- `gh issue close` - Close issues after merge

## Troubleshooting

### Issue: "No commits to push"

**Symptoms:**
- Error when running `/mr`
- Branch has no commits ahead of default branch

**Solution:**
```bash
# Verify commits exist
git log {{DEFAULT_BRANCH}}..HEAD

# If no commits, make changes and commit
git add .
/commit
```

---

### Issue: "PR already exists"

**Symptoms:**
- Error: PR already exists for this branch
- Existing PR is open

**Solutions:**

1. **Update existing PR:**
```bash
git push --force-with-lease
# Existing PR automatically updates
```

2. **Create new branch:**
```bash
# Let skill create new branch from changes
/mr
# Select option to create new branch
```

---

### Issue: Theme detection not working

**Symptoms:**
- No theme suggestions despite unrelated commits
- All commits grouped as one theme

**Solutions:**

1. **Check minimum commits:**
```yaml
theme_detection:
  min_commits: 2  # Need at least 2 commits
```

2. **Lower similarity threshold:**
```yaml
theme_detection:
  similarity_threshold: 0.30  # Lower from 0.40
```

3. **Verify commits are different:**
```bash
git log --oneline -10
# Check if commits touch different files/areas
```

---

### Issue: Cherry-pick conflicts

**Symptoms:**
- Conflicts during theme splitting
- Cherry-pick fails

**Solutions:**

1. **Use auto-resolve strategy:**
```yaml
conflicts:
  default_strategy: "auto_resolve_simple"
```

2. **Manual resolution:**
```yaml
conflicts:
  default_strategy: "always_ask"
```

3. **Abort on conflict:**
```yaml
conflicts:
  default_strategy: "abort_on_conflict"
```

---

### Issue: Branch name too long

**Symptoms:**
- Error: branch name exceeds limit
- Branch name gets truncated oddly

**Solution:**
```yaml
branch_naming:
  max_length: 30  # Increase from 25
  story_slug_length: 35  # Increase slug length

  # Add abbreviations
  abbreviations:
    authentication: "auth"
    configuration: "config"
    implementation: "impl"
```

## Implementation Details

### How It Works

**High-level process:**

1. **Pre-flight checks:**
   - Check for uncommitted changes
   - Verify git remote exists
   - Check GitHub CLI authentication

2. **PR detection:**
   - Query existing PRs for branch
   - Check if merged/closed/open
   - Decide: update, create new, or split

3. **Theme detection** (if enabled):
   - Analyze commit messages and file changes
   - Calculate similarity scores
   - Group commits by theme (>threshold)
   - Present themes to user

4. **Branch creation:**
   - Generate descriptive branch name
   - Create branch from default branch
   - Cherry-pick themed commits

5. **PR creation:**
   - Generate PR title and body
   - Include test plan, impact, categories
   - Add story context if available
   - Create PR via `gh pr create`

### Dependencies

This skill requires:
- **Git** - Version control
- **GitHub CLI (gh)** - PR creation
- **jq** - JSON parsing (active story)
- **yq** - YAML parsing (config file)

### Files Created/Modified

This skill may create or modify:
- New git branches (theme-based or story-based)
- `.claude/active-story.json` - Update PR info
- Git commits (during cherry-pick)

## Customization

### Custom PR Body Format

Modify PR creation settings:

```yaml
pr_creation:
  include_test_plan: true
  include_impact: true
  include_categories: true
  include_story_context: true
  footer: "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

### Custom Theme Detection

Adjust theme detection algorithm:

```yaml
theme_detection:
  similarity_threshold: 0.40
  weights:
    title_keywords: 0.5  # Keywords from titles
    directories: 0.3     # File paths
    categories: 0.2      # Commit categories

  stopwords:
    - "add"
    - "update"
    - "fix"
    # Add your own stopwords
```

### Custom Branch Naming

Customize branch name generation:

```yaml
branch_naming:
  max_length: 25
  story_prefix: "feature"  # Use "feature" instead of "story"

  abbreviations:
    dependencies: "deps"
    infrastructure: "infra"
    # Add your abbreviations
```

## Migration Notes

**Source Projects:**
- Landing page (aigensa/landing_page) - Jan 30, 2026
- Vibe coding course (aigensa/vibe-coding-course) - Jan 29, 2026
- News bot (aigensa/news-bot) - Jan 20, 2026

**Abstraction Changes:**
- Hardcoded repository (aigensa/*) → `{{REPO_SLUG}}`
- Hardcoded branch (master) → `{{DEFAULT_BRANCH}}`
- Hardcoded prefix (AIGCODE) → `{{PROJECT_PREFIX}}`
- Project-specific branch naming → Configurable via `branch_naming`

**Variations Merged:**
- All three versions used similar structure
- Vibe-coding-course version was most recent
- Config-based approach unified across projects

## See Also

- [commit](../commit/SKILL.md) - Create commits
- [play-story](../play-story/SKILL.md) - Activate issues
- [fetch-story](../fetch-story/SKILL.md) - Browse issues
- [Configuration Reference](../../docs/configuration-reference.md)
- [Abstraction Guide](../../docs/abstraction-guide.md)

## Notes

**Best Practices:**
- Commit changes before running `/mr`
- Enable theme detection for multi-concern branches
- Use story workflow for traceability
- Review generated PR descriptions before creating

**Common Patterns:**
```bash
# Standard workflow
/commit
/mr

# Story-based workflow
/play-story
/commit
/mr

# Theme splitting workflow
# (Make unrelated commits)
/mr
# Select themes to split
# Review and create focused PRs
```

---

**Invoke:** `/mr`

**Configuration File:** [config.yaml](config.yaml)

**Example Configuration:** [config.example.yaml](config.example.yaml)
