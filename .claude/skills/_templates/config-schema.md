# Configuration File Schema

This document describes the structure and options for skill `config.yaml` files.

## Overview

Each skill in the marketplace has its own `config.yaml` file that users customize for their project. This file uses template variable syntax to abstract project-specific values.

## File Structure

```yaml
# Project Identity
project:
  prefix: "{{PROJECT_PREFIX}}"
  name: "{{PROJECT_NAME}}"

# Repository Configuration
repository:
  slug: "{{REPO_SLUG}}"
  owner: "{{REPO_OWNER}}"
  name: "{{REPO_NAME}}"
  default_branch: "{{DEFAULT_BRANCH}}"

# File Paths (relative to project root)
paths:
  active_story: "{{ACTIVE_STORY_FILE}}"
  active_bug: "{{ACTIVE_BUG_FILE}}"
  infrastructure: "{{INFRA_DIR}}"

# Tool Commands
commands:
  type_check: "{{TYPE_CHECK_CMD}}"
  test: "{{TEST_CMD}}"
  lint: "{{LINT_CMD}}"
  build: "{{BUILD_CMD}}"

# Feature Flags
features:
  issue_based_numbering: {{ISSUE_MODE}}
  theme_detection: {{THEME_DETECT}}
  auto_create_issues: {{AUTO_CREATE}}

# Skill-Specific Configuration
{{skill_specific_section}}:
  {{option}}: {{value}}
```

## Standard Sections

### Project Identity

Defines project identification and naming.

```yaml
project:
  prefix: "MYAPP"              # Used in commits, branches (e.g., MYAPP-123)
  name: "My Application"       # Full project name for documentation
```

**Fields:**
- `prefix` (string, required) - Short uppercase identifier (3-10 chars)
- `name` (string, optional) - Full descriptive project name

**Template Variables:**
- `{{PROJECT_PREFIX}}` - Project prefix
- `{{PROJECT_NAME}}` - Project name

### Repository Configuration

GitHub repository settings.

```yaml
repository:
  slug: "myorg/myapp"          # Full repository path
  owner: "myorg"               # Organization or user
  name: "myapp"                # Repository name
  default_branch: "main"       # Default branch for PRs
```

**Fields:**
- `slug` (string, required) - Format: `owner/repo`
- `owner` (string, required) - Repository owner
- `name` (string, required) - Repository name
- `default_branch` (string, optional) - Default: `main`

**Template Variables:**
- `{{REPO_SLUG}}` - Repository slug
- `{{REPO_OWNER}}` - Repository owner
- `{{REPO_NAME}}` - Repository name
- `{{DEFAULT_BRANCH}}` - Default branch

### File Paths

Project file and directory paths (relative to project root).

```yaml
paths:
  active_story: ".claude/active-story.json"
  active_bug: ".claude/active-bug.json"
  infrastructure: "infrastructure/"
  skills: ".claude/skills/"
```

**Common Paths:**
- `active_story` - Current story/issue tracking file
- `active_bug` - Current bug tracking file
- `infrastructure` - Infrastructure code directory
- `skills` - Skills directory
- `docs` - Documentation directory
- `tests` - Test directory

**Template Variables:**
- `{{ACTIVE_STORY_FILE}}` - Active story file path
- `{{ACTIVE_BUG_FILE}}` - Active bug file path
- `{{INFRA_DIR}}` - Infrastructure directory
- `{{SKILLS_DIR}}` - Skills directory
- Custom variables: `{{YOUR_PATH}}`

**Best Practices:**
- Always use relative paths from project root
- Include trailing slash for directories
- Use forward slashes (/) even on Windows

### Tool Commands

Commands for running project tools.

```yaml
commands:
  type_check: "npm run type-check"
  test: "npm test"
  lint: "npm run lint"
  build: "npm run build"
  format: "npm run format"
```

**Common Commands:**
- `type_check` - Type checking command
- `test` - Test runner command
- `lint` - Linter command
- `build` - Build command
- `format` - Code formatter command

**Template Variables:**
- `{{TYPE_CHECK_CMD}}` - Type check command
- `{{TEST_CMD}}` - Test command
- `{{LINT_CMD}}` - Lint command
- `{{BUILD_CMD}}` - Build command
- `{{FORMAT_CMD}}` - Format command

**Examples by Stack:**

JavaScript/TypeScript:
```yaml
commands:
  type_check: "tsc --noEmit"
  test: "jest"
  lint: "eslint ."
```

Python:
```yaml
commands:
  type_check: "mypy ."
  test: "pytest"
  lint: "ruff check ."
```

Rust:
```yaml
commands:
  type_check: "cargo check"
  test: "cargo test"
  lint: "cargo clippy"
```

### Feature Flags

Boolean flags to enable/disable skill features.

```yaml
features:
  issue_based_numbering: true      # Use GitHub issues for numbering
  theme_detection: true            # Detect and group by theme
  auto_create_issues: false        # Auto-create missing issues
  sequential_fallback: false       # Fallback to sequential numbering
```

**Common Flags:**
- `issue_based_numbering` - Use GitHub issues for commit numbering
- `theme_detection` - Detect commit themes
- `auto_create_issues` - Auto-create issues when missing
- `sequential_fallback` - Use sequential numbering as fallback
- `strict_validation` - Enable strict validation
- `dry_run` - Simulate actions without executing

**Values:**
- `true` - Feature enabled
- `false` - Feature disabled

**Template Variables:**
- Use descriptive names: `{{FEATURE_NAME_ENABLED}}`

## Skill-Specific Sections

Skills may define custom configuration sections:

```yaml
# Example: commit skill
commit:
  message_format: "{{PREFIX}}-{{NUMBER}}: {{DESCRIPTION}}"
  require_issue: true
  max_length: 72

# Example: aws-architect skill
aws:
  region: "us-east-1"
  profile: "default"
  preferred_services:
    - Lambda
    - DynamoDB
    - S3
```

Document these in the skill's `SKILL.md` file.

## Template Variable Syntax

### In config.yaml (Template)

Templates use `{{VARIABLE_NAME}}` syntax:

```yaml
# This is a TEMPLATE - no actual values
project:
  prefix: "{{PROJECT_PREFIX}}"
```

### In config.yaml (User's Project)

Users replace with actual values:

```yaml
# User's actual config
project:
  prefix: "MYAPP"              # NO {{}} - just the value
```

### In Skill Code

Skills reference variables using the template syntax:

```
commit -m "{{PROJECT_PREFIX}}-{{ISSUE_NUMBER}}: {{COMMIT_MESSAGE}}"
```

At runtime, these are replaced with config values:

```
commit -m "MYAPP-123: Add new feature"
```

## Validation Rules

### Required Fields

At minimum, configs should define:
```yaml
project:
  prefix: "{{PROJECT_PREFIX}}"

repository:
  slug: "{{REPO_SLUG}}"
```

### Naming Conventions

- **Project prefix:** UPPERCASE, 3-10 characters, alphanumeric
- **Repository slug:** lowercase, format `owner/repo`
- **Paths:** relative, forward slashes, trailing slash for directories
- **Commands:** valid shell commands

### Best Practices

1. **No Hardcoded Values in Templates**
   ```yaml
   # BAD - hardcoded in template
   project:
     prefix: "MYAPP"

   # GOOD - template variable
   project:
     prefix: "{{PROJECT_PREFIX}}"
   ```

2. **Use Descriptive Variable Names**
   ```yaml
   # BAD - unclear
   paths:
     file1: "{{F1}}"

   # GOOD - descriptive
   paths:
     active_story: "{{ACTIVE_STORY_FILE}}"
   ```

3. **Provide Defaults Where Appropriate**
   ```yaml
   repository:
     default_branch: "main"     # Common default

   features:
     strict_validation: false   # Conservative default
   ```

4. **Document All Variables**
   - In SKILL.md, create a "Template Variables Reference" section
   - Include purpose, example value, and whether required

## Example Configurations

### Minimal Config

```yaml
project:
  prefix: "MYAPP"

repository:
  slug: "myorg/myapp"
```

### Standard Config

```yaml
project:
  prefix: "MYAPP"
  name: "My Application"

repository:
  slug: "myorg/myapp"
  owner: "myorg"
  name: "myapp"
  default_branch: "main"

paths:
  active_story: ".claude/active-story.json"

commands:
  type_check: "npm run type-check"
  test: "npm test"

features:
  issue_based_numbering: true
```

### Comprehensive Config

```yaml
project:
  prefix: "MYAPP"
  name: "My Application"
  version: "1.0.0"

repository:
  slug: "myorg/myapp"
  owner: "myorg"
  name: "myapp"
  default_branch: "main"
  remote: "origin"

paths:
  active_story: ".claude/active-story.json"
  active_bug: ".claude/active-bug.json"
  infrastructure: "infrastructure/"
  skills: ".claude/skills/"
  docs: "docs/"
  tests: "tests/"

commands:
  type_check: "npm run type-check"
  test: "npm test"
  lint: "npm run lint"
  build: "npm run build"
  format: "prettier --write ."

features:
  issue_based_numbering: true
  theme_detection: true
  auto_create_issues: false
  sequential_fallback: true
  strict_validation: true
  dry_run: false

# Skill-specific configuration
commit:
  message_format: "{{PREFIX}}-{{NUMBER}}: {{DESCRIPTION}}"
  require_issue: true
  max_length: 72

hooks:
  pre_commit:
    - type-check
    - lint
    - test
```

## config.example.yaml

Each skill should provide `config.example.yaml` with realistic sample values:

```yaml
# config.example.yaml - Example configuration
# Copy this to config.yaml and customize

project:
  prefix: "MYAPP"              # Example: Your project prefix
  name: "My Application"       # Example: Full project name

repository:
  slug: "myorg/myapp"          # Example: Your GitHub org/repo
  owner: "myorg"               # Example: Your GitHub org
  name: "myapp"                # Example: Repository name
  default_branch: "main"       # Usually: main or master

paths:
  active_story: ".claude/active-story.json"  # Default location

commands:
  type_check: "npm run type-check"  # Example: For Node.js projects
  test: "npm test"                  # Example: npm test command

features:
  issue_based_numbering: true   # Recommended: Use GitHub issues
  theme_detection: true         # Recommended: Group by theme
```

## Migration from Project-Specific to Marketplace

When migrating a skill to marketplace:

1. **Identify Hardcoded Values**
   ```bash
   # Search for project-specific values
   grep -r "AIGWS\|AIGCODE\|AIGNEWS" skill/
   grep -r "aigensa/landing_page" skill/
   ```

2. **Extract to config.yaml**
   ```yaml
   # Before (hardcoded in SKILL.md)
   commit -m "AIGWS-123: Add feature"

   # After (template variable)
   commit -m "{{PROJECT_PREFIX}}-123: Add feature"

   # In config.yaml
   project:
     prefix: "{{PROJECT_PREFIX}}"
   ```

3. **Create Template Variables**
   - Replace each hardcoded value with `{{DESCRIPTIVE_NAME}}`
   - Add to config.yaml template
   - Document in SKILL.md

4. **Validate Abstraction**
   ```bash
   # Should find nothing
   grep -r "AIGWS\|AIGCODE\|AIGNEWS" skill/
   ```

## See Also

- [Abstraction Guide](../../docs/abstraction-guide.md) - Deep dive on template variables
- [Configuration Reference](../../docs/configuration-reference.md) - Complete config options
- [SKILL_TEMPLATE.md](SKILL_TEMPLATE.md) - Template for creating new skills
