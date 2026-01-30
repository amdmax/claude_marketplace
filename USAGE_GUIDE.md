# Skills Marketplace Usage Guide

Complete guide to using skills from the Claude Code Skills Marketplace in your projects.

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Using Skills](#using-skills)
4. [Customization](#customization)
5. [Troubleshooting](#troubleshooting)
6. [Advanced Topics](#advanced-topics)

## Installation

### Method 1: Copy Individual Skills

Copy specific skills you need to your project:

```bash
# Navigate to your project
cd /path/to/your/project

# Create skills directory if it doesn't exist
mkdir -p .claude/skills

# Copy a skill from the marketplace
cp -r /path/to/claude_marketplace/skills/commit/ .claude/skills/
```

### Method 2: Clone Entire Marketplace

Clone the marketplace and symlink skills:

```bash
# Clone marketplace to a central location
git clone <marketplace-repo> ~/claude-marketplace

# Symlink skills you want to use
cd /path/to/your/project/.claude/skills
ln -s ~/claude-marketplace/skills/commit commit
ln -s ~/claude-marketplace/skills/mr mr
```

Benefits: Easy updates when marketplace skills improve.

### Method 3: Git Submodule

Add marketplace as a submodule (advanced):

```bash
cd /path/to/your/project
git submodule add <marketplace-repo> .claude/marketplace

# Symlink individual skills
ln -s .claude/marketplace/skills/commit .claude/skills/commit
```

## Configuration

### Step 1: Copy Config Template

Each skill has a `config.yaml` template and a `config.example.yaml`:

```bash
cd .claude/skills/commit

# Copy the example to start
cp config.example.yaml config.yaml
```

### Step 2: Customize Your Config

Edit `config.yaml` with your project-specific values:

```yaml
# config.yaml for commit skill

# Project Identity
project:
  prefix: "MYAPP"                    # Your commit prefix
  name: "My Application"

# Repository
repository:
  slug: "myorg/myapp"                # GitHub org/repo
  owner: "myorg"
  name: "myapp"
  default_branch: "main"

# File Paths (relative to project root)
paths:
  active_story: ".claude/active-story.json"
  active_bug: ".claude/active-bug.json"
  infrastructure: "infrastructure/"

# Tool Commands
commands:
  type_check: "npm run type-check"
  test: "npm test"
  lint: "npm run lint"

# Feature Flags
features:
  issue_based_numbering: true       # Use GitHub issues for numbering
  create_missing_issues: true       # Auto-create issues if missing
  theme_detection: true             # Group commits by theme
  sequential_fallback: false        # Use sequential numbering if issues fail
```

### Step 3: Verify Configuration

Check that template variables are properly replaced:

```bash
# Search for unreplaced variables
grep -r "{{" .claude/skills/commit/

# Should return nothing if config is complete
```

### Understanding Template Variables

Skills use `{{VARIABLE_NAME}}` syntax for abstraction. These are replaced at runtime using your `config.yaml`:

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| `{{PROJECT_PREFIX}}` | Commit/branch prefix | MYAPP |
| `{{REPO_SLUG}}` | GitHub repository | myorg/myapp |
| `{{DEFAULT_BRANCH}}` | Main branch name | main |
| `{{ACTIVE_STORY_FILE}}` | Story tracking file | .claude/active-story.json |
| `{{TYPE_CHECK_CMD}}` | Type checking command | npm run type-check |
| `{{TEST_CMD}}` | Test command | npm test |

See [docs/configuration-reference.md](docs/configuration-reference.md) for complete variable reference.

## Using Skills

### Invoking Skills

Once configured, invoke skills in Claude Code:

```
/commit
```

Or reference them in natural language:

```
Create a commit for these changes
```

Claude will use the configured skill automatically.

### Skill-Specific Usage

Each skill's `SKILL.md` contains:
- **Purpose** - What the skill does
- **Configuration** - Required config variables
- **Usage Examples** - How to invoke it
- **Template Variables** - Variables it uses
- **Feature Flags** - Optional features

Example from `skills/commit/SKILL.md`:

```markdown
## Usage

Invoke with `/commit` or ask Claude to create a commit.

## Configuration

Required variables:
- PROJECT_PREFIX - Your commit prefix (e.g., MYAPP)
- REPO_SLUG - GitHub repository (e.g., myorg/myapp)

Optional features:
- issue_based_numbering: true - Use GitHub issues
- theme_detection: true - Group by theme
```

## Customization

### Enabling/Disabling Features

Many skills support feature flags:

```yaml
# In config.yaml
features:
  # Core feature
  issue_based_numbering: true

  # Additional options
  create_missing_issues: true      # Auto-create missing issues
  theme_detection: true            # Detect commit themes
  sequential_fallback: false       # Fallback to sequential numbers
```

Set to `true`/`false` to enable/disable.

### Customizing Workflows

Skills may have workflow variations. Check the skill's `SKILL.md` for available workflows:

```yaml
# Example: commit skill workflows
features:
  workflow: "issue-based"          # Options: issue-based, sequential, manual
```

### Overriding Commands

Customize tool commands for your stack:

```yaml
commands:
  # JavaScript project
  type_check: "npm run type-check"
  test: "npm test"
  lint: "npm run lint"

  # Python project
  # type_check: "mypy ."
  # test: "pytest"
  # lint: "ruff check ."
```

### Custom Paths

Adjust paths for your project structure:

```yaml
paths:
  # Default structure
  active_story: ".claude/active-story.json"
  infrastructure: "infrastructure/"

  # Alternative structure
  # active_story: ".project/current-task.json"
  # infrastructure: "infra/"
```

## Troubleshooting

### Skill Not Found

**Issue:** Claude says skill doesn't exist.

**Solution:**
```bash
# Verify skill is in correct location
ls .claude/skills/

# Should show: commit/, mr/, etc.

# Restart Claude Code to reload skills
```

### Configuration Errors

**Issue:** Skill fails with "variable not defined" error.

**Solution:**
```bash
# Check config.yaml exists
ls .claude/skills/commit/config.yaml

# Verify all required variables are set
cat .claude/skills/commit/config.yaml

# Compare with config.example.yaml
diff .claude/skills/commit/config.yaml .claude/skills/commit/config.example.yaml
```

### Template Variables Not Replaced

**Issue:** Commits show `{{PROJECT_PREFIX}}` instead of actual value.

**Solution:**
```yaml
# In config.yaml, ensure values are NOT quoted with {{}}
project:
  prefix: "MYAPP"              # Correct
  # prefix: "{{MYAPP}}"        # Wrong - remove {{}}
```

### Feature Not Working

**Issue:** Feature flag set to `true` but feature doesn't activate.

**Solution:**
```bash
# Check skill's SKILL.md for exact feature flag name
cat .claude/skills/commit/SKILL.md | grep -A 10 "Feature Flags"

# Ensure feature is supported in this skill version
cat .claude/skills/commit/SKILL.md | grep "issue_based_numbering"
```

### Path Issues

**Issue:** Skill can't find files or directories.

**Solution:**
```yaml
# Ensure paths are relative to project root
paths:
  active_story: ".claude/active-story.json"    # Relative to project root
  # NOT: "/Users/you/project/.claude/..."      # Avoid absolute paths

# Create directories if they don't exist
```

```bash
mkdir -p .claude
touch .claude/active-story.json
```

## Advanced Topics

### Multiple Configurations

Use different configs for different environments:

```bash
.claude/skills/commit/
├── config.yaml              # Active config (gitignored)
├── config.example.yaml      # Template
├── config.dev.yaml          # Development config
└── config.prod.yaml         # Production config
```

Switch configs:
```bash
cp config.dev.yaml config.yaml
```

### Sharing Skills Across Projects

Create a shared config template:

```bash
# In marketplace
skills/commit/config.shared.yaml

# In each project, extend it
# .claude/skills/commit/config.yaml
<<: *shared    # YAML merge
project:
  prefix: "THISPROJECT"
```

### Creating Skill Variants

Fork a skill to create project-specific variants:

```bash
# Copy and rename
cp -r .claude/skills/commit .claude/skills/commit-experimental

# Customize for specific use case
vim .claude/skills/commit-experimental/SKILL.md
```

### Version Locking

Lock skills to specific marketplace versions:

```bash
# If using git submodule
cd .claude/marketplace
git checkout v1.2.3

# Or copy specific version
cp -r ~/claude-marketplace@v1.2.3/skills/commit .claude/skills/
```

### Integration with CI/CD

Use skills in CI pipelines:

```yaml
# .github/workflows/auto-commit.yml
- name: Run commit skill
  run: |
    claude-code /commit
  env:
    CONFIG_PATH: .claude/skills/commit/config.ci.yaml
```

### Debugging Skills

Enable debug mode:

```yaml
# In config.yaml
debug:
  enabled: true
  verbose: true
  log_path: ".claude/skill-debug.log"
```

View skill execution:
```bash
tail -f .claude/skill-debug.log
```

## Next Steps

- Browse [SKILL_CATALOG.md](SKILL_CATALOG.md) for available skills
- Read [docs/abstraction-guide.md](docs/abstraction-guide.md) for deep dive on template system
- Check [docs/configuration-reference.md](docs/configuration-reference.md) for all config options
- See [skills/_templates/](skills/_templates/) to create your own skills

## Getting Help

If you encounter issues:

1. Check the skill's `SKILL.md` documentation
2. Review `config.example.yaml` for correct format
3. Search [docs/migration-notes.md](docs/migration-notes.md) for known issues
4. Verify Claude Code version compatibility
