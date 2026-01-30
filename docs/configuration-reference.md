# Configuration Reference

Complete reference for all configuration options across Skills Marketplace skills.

## Table of Contents

1. [Overview](#overview)
2. [Global Patterns](#global-patterns)
3. [Skill-Specific Configs](#skill-specific-configs)
4. [Common Sections](#common-sections)
5. [Variable Reference](#variable-reference)

## Overview

Each skill has its own `config.yaml` file that users customize for their project. This reference documents all available configuration options.

### Configuration Philosophy

- **Per-skill configuration** - Each skill has its own config.yaml
- **Template-based** - Marketplace provides templates with `{{VARIABLES}}`
- **Example-driven** - Each skill includes config.example.yaml with realistic values
- **No defaults in marketplace** - Users must provide values (prevents accidental hardcoding)

### File Locations

```
your-project/
└── .claude/
    └── skills/
        ├── commit/
        │   └── config.yaml          # User's values
        ├── mr/
        │   └── config.yaml
        └── story-workflow-config.json  # Shared by fetch-story/play-story
```

## Global Patterns

### Standard Sections

Most skills use these standard sections:

```yaml
# Project Identity
project:
  prefix: "MYAPP"
  name: "My Application"

# Repository Settings
repository:
  slug: "myorg/myrepo"
  owner: "myorg"
  name: "myrepo"
  default_branch: "main"
  default_remote: "origin"

# File Paths (relative to project root)
paths:
  active_story: ".claude/active-story.json"
  skills_dir: ".claude/skills/"

# Tool Commands
commands:
  type_check: "npm run type-check"
  test: "npm test"
  lint: "npm run lint"

# Feature Flags
features:
  enabled: true
  option: value
```

## Skill-Specific Configs

### commit

**File:** `skills/commit/config.yaml`

```yaml
# Commit numbering convention
numbering:
  mode: "issue-based"  # Options: "issue-based" | "sequential"
  prefix: MYAPP

  issue:
    source: ".claude/active-story.json"
    field: "issueNumber"
    format: "%s-%d"
    create_if_missing: true

  sequential:
    digits: 3
    format: "%s-%03d"

# Grouping detection
grouping:
  enabled: true
  time_window: "4 hours ago"
  max_recent_commits: 10
  min_overlap_high: 50
  min_overlap_medium: 30
  time_threshold_high: 1
  time_threshold_medium: 4
  confidence_threshold: 60

# Message format
message:
  max_summary_length: 72
  max_line_length: 100
  include_co_author: true
  co_author: "Claude Sonnet 4.5 <noreply@anthropic.com>"

# Git settings
git:
  check_all_branches: true
  verify_staged: true

# Behavior
behavior:
  auto_stage: false
  prompt_before_commit: false
  show_diff_summary: true

# Validation
validation:
  enabled: true
  skip_merge_commits: true
  timeout: 10
```

**Key Options:**
- `numbering.mode` - Issue-based uses GitHub issues, sequential uses counter
- `grouping.enabled` - Detect related commits and suggest suffixes (a, b, c)
- `create_if_missing` - Auto-create issue if none active
- `validation.enabled` - Post-commit format validation

---

### mr

**File:** `skills/mr/config.yaml`

```yaml
# PR Detection
pr_detection:
  check_merged: true
  check_closed: true
  fallback_on_error: "create_new"

# Theme Detection
theme_detection:
  enabled: true
  min_commits: 2
  similarity_threshold: 0.40

  weights:
    title_keywords: 0.5
    directories: 0.3
    categories: 0.2

  stopwords:
    - "the"
    - "add"
    - "update"

# Theme Comparison
theme_comparison:
  high_match_threshold: 0.60
  low_match_threshold: 0.40

# Branch Naming
branch_naming:
  max_length: 25
  story_prefix: "story"
  story_slug_length: 30

  abbreviations:
    dependencies: "deps"
    infrastructure: "infra"

# Conflict Resolution
conflicts:
  default_strategy: "auto_resolve_simple"
  strategies:
    - "auto_resolve_simple"
    - "always_ask"
    - "abort_on_conflict"

# Repository
repository:
  default_remote: "origin"
  default_branch: "main"
  slug: "myorg/myrepo"

# PR Creation
pr_creation:
  auto_generate_body: true
  include_story_context: true
  include_test_plan: true
  include_impact: true
  include_categories: true
  footer: "🤖 Generated with [Claude Code](https://claude.com/claude-code)"

# Story Integration
story_integration:
  active_story_file: ".claude/active-story.json"
  include_story_in_title: true
  include_story_progress: true
  branch_format: "story-{issue_number}-{slug}"

# Issue Management
issue_management:
  auto_prompt_closure: true
  closure_comment: "Completed in PR #{pr_number}"
  closure_reason: "completed"
  check_multiple_prs: true
  cleanup_story_file: false

# Cherry-Pick
cherry_pick:
  checkout_master_first: true
  pull_master_before_branch: true
  sort_by_prefix: true
  track_skipped: true
  prompt_cleanup_original: true

# Advanced
advanced:
  verbose: false
  dry_run: false
  skip_theme_for_single_commit: true
  skip_theme_for_similar_commits: true
  similar_commits_threshold: 0.70
```

**Key Options:**
- `theme_detection.enabled` - Group commits by theme for focused PRs
- `similarity_threshold` - How similar commits must be to group (0.0-1.0)
- `conflicts.default_strategy` - How to handle cherry-pick conflicts
- `branch_format` - Template for story branch names

---

### create-story

**File:** `skills/create-story/config.yaml`

```yaml
# Repository
repository:
  slug: "myorg/myrepo"
  default_labels: []

# Issue creation
issue:
  auto_generate_body: true
  diff_analysis_lines: 50
  default_body: "Auto-created during commit workflow"

# Active story
active_story:
  path: ".claude/active-story.json"

  minimal_fields:
    - "issueNumber"
    - "title"
    - "body"
    - "url"

# Error handling
errors:
  no_auth: "prompt"
  network_failure: "fail"
```

**Key Options:**
- `auto_generate_body` - Generate issue body from git diff
- `minimal_fields` - Fields stored in active-story.json (fast path)
- `errors.no_auth` - How to handle missing GitHub auth

---

### fetch-story

**File:** `skills/fetch-story/story-workflow-config.json`

```json
{
  "projectId": "PVT_kwDO...",

  "fieldIds": {
    "status": "PVTSSF_lADO...",
    "priority": "PVTSSF_lADO...",
    "size": "PVTSSF_lADO...",
    "itemType": "PVTSSF_lADO...",
    "techSpecStatus": "PVTSSF_lADO..."
  },

  "optionIds": {
    "status": {
      "ready": "61e4505c",
      "inProgress": "47fc9ee4",
      "backlog": "f75ad846"
    },
    "priority": {
      "p0": "79628723",
      "p1": "0a877460",
      "p2": "da944a9c"
    }
  }
}
```

**Key Options:**
- `projectId` - GitHub Project V2 node ID
- `fieldIds` - Custom field IDs from your project
- `optionIds` - Option values for each field

**Discovery:** Use GraphQL to find your project's IDs:
```bash
# Get project ID
gh api graphql -f query='...'

# Get field IDs
gh api graphql -f query='...'
```

See `story-workflow-config.example.json` for discovery instructions.

---

### bug-fix

**File:** `skills/bug-fix/config.yaml`

```yaml
# Investigation
investigation:
  depth: "thorough"  # Options: "quick" | "standard" | "thorough"
  include_related_code: true
  max_context_files: 10

# Testing
testing:
  require_reproduction: true
  require_regression_test: true
  test_commands:
    - "npm test"
    - "npm run integration-test"

# Commit behavior
commit:
  auto_commit_fix: false
  commit_message_template: "Fix: {description}"
  include_root_cause: true

# Labels
labels:
  bug_label: "bug"
  fixed_label: "fixed"
```

**Key Options:**
- `investigation.depth` - How thoroughly to investigate
- `require_regression_test` - Enforce regression test creation
- `auto_commit_fix` - Commit automatically or prompt user

---

### sync-skills

**File:** `skills/sync-skills/config.yaml`

```yaml
# Target repository
repository:
  owner: "myuser"
  name: "my-claude-skills"
  branch: "main"
  url: "https://github.com/myuser/my-claude-skills"

# Local paths
paths:
  skills_dir: ".claude/skills/"
  temp_dir: "/tmp/skill-sync"

# Sync behavior
sync:
  generate_index: true
  commit_message: "Sync {skill_count} skill(s): {skill_names}"
  author_name: ""
  author_email: ""

# Filtering
filters:
  exclude:
    - "_templates"
    - "example-*"
  include: []

# Advanced
advanced:
  verbose: false
  dry_run: false
```

**Key Options:**
- `repository.owner` - Your GitHub username for skill repo
- `filters.exclude` - Skills to skip during sync
- `dry_run` - Test without actually pushing

---

### gather-context

**File:** `skills/gather-context/config.yaml`

```yaml
# Project paths
paths:
  architecture_docs: "_bmad-output/"
  active_story: ".claude/active-story.json"
  skills_dir: ".claude/skills/"
  adr_dir: "docs/adr/"
  nfr_dir: "docs/nfr/"

# Context sources
sources:
  include_architecture: true
  include_story: true
  include_adrs: true
  include_nfrs: true
  include_code: true

# Output
output:
  format: "markdown"
  save_to: ""
  verbose: false
```

**Key Options:**
- `paths.*` - Directories for different documentation types
- `sources.include_*` - Which sources to gather
- `output.format` - Output format (markdown or json)

## Common Sections

### Project Identity

```yaml
project:
  prefix: "MYAPP"        # Commit/branch prefix (3-10 chars, UPPERCASE)
  name: "My Application" # Full project name (optional)
```

Used by: commit, bug-fix

### Repository

```yaml
repository:
  slug: "myorg/myrepo"     # GitHub repository (owner/repo)
  owner: "myorg"            # Repository owner
  name: "myrepo"            # Repository name
  default_branch: "main"    # Target branch for PRs
  default_remote: "origin"  # Git remote name
```

Used by: commit, mr, create-story, sync-skills

### Paths

```yaml
paths:
  active_story: ".claude/active-story.json"
  skills_dir: ".claude/skills/"
  infrastructure: "infrastructure/"
  adr_dir: "docs/adr/"
  nfr_dir: "docs/nfr/"
```

Used by: Most skills

### Commands

```yaml
commands:
  type_check: "npm run type-check"
  test: "npm test"
  lint: "npm run lint"
  build: "npm run build"
  format: "prettier --write ."
```

Used by: commit, bug-fix

## Variable Reference

### Required Variables

These must be set for skills to work:

| Variable | Skills | Purpose | Example |
|----------|--------|---------|---------|
| `PROJECT_PREFIX` | commit, bug-fix | Commit prefix | MYAPP |
| `REPO_SLUG` | Most | GitHub repository | owner/repo |
| `DEFAULT_BRANCH` | mr, commit | Target branch | main |

### Optional Variables

These have sensible defaults or are feature-specific:

| Variable | Skills | Purpose | Default |
|----------|--------|---------|---------|
| `STORY_PREFIX` | mr, play-story | Story branch prefix | story |
| `MAX_BRANCH_LENGTH` | mr | Branch name limit | 25 |
| `SIMILARITY_THRESHOLD` | mr | Theme grouping | 0.40 |
| `TEST_CMD` | commit, bug-fix | Test command | npm test |

### Conditional Variables

Required only when using specific features:

| Variable | When Required | Purpose |
|----------|--------------|---------|
| `GITHUB_PROJECT_ID` | Using fetch-story | GitHub Project V2 ID |
| `FIELD_ID_*` | Using fetch-story | Project field IDs |
| `ACTIVE_STORY_FILE` | Issue-based mode | Story tracking file |

## Examples by Stack

### JavaScript/TypeScript

```yaml
commands:
  type_check: "tsc --noEmit"
  test: "jest"
  lint: "eslint ."
  build: "npm run build"
  format: "prettier --write ."
```

### Python

```yaml
commands:
  type_check: "mypy ."
  test: "pytest"
  lint: "ruff check ."
  build: "python setup.py build"
  format: "black ."
```

### Rust

```yaml
commands:
  type_check: "cargo check"
  test: "cargo test"
  lint: "cargo clippy"
  build: "cargo build"
  format: "cargo fmt"
```

### Go

```yaml
commands:
  type_check: "go vet ./..."
  test: "go test ./..."
  lint: "golangci-lint run"
  build: "go build"
  format: "gofmt -w ."
```

## Validation

### Required Fields Check

Verify required fields are set:

```bash
# Check PROJECT_PREFIX exists
yq e '.project.prefix' config.yaml

# Check REPO_SLUG exists
yq e '.repository.slug' config.yaml
```

### Format Validation

Ensure correct formats:

```yaml
# Prefix: UPPERCASE, 3-10 chars
project:
  prefix: "MYAPP"  # ✓ Valid
  # prefix: "my-app"  # ✗ Invalid - lowercase
  # prefix: "AB"      # ✗ Invalid - too short

# Repo slug: owner/name
repository:
  slug: "myorg/myrepo"  # ✓ Valid
  # slug: "myrepo"        # ✗ Invalid - missing owner
  # slug: "myorg"         # ✗ Invalid - missing repo
```

## See Also

- [Abstraction Guide](abstraction-guide.md) - Template variable system
- [USAGE_GUIDE.md](../USAGE_GUIDE.md) - Using marketplace skills
- [config-schema.md](../skills/_templates/config-schema.md) - Config structure
