# Abstraction Guide

Deep dive into the Skills Marketplace template variable system and abstraction patterns.

## Table of Contents

1. [Overview](#overview)
2. [Template Variable System](#template-variable-system)
3. [Abstraction Patterns](#abstraction-patterns)
4. [Common Variables](#common-variables)
5. [Creating Abstracted Skills](#creating-abstracted-skills)
6. [Migration Examples](#migration-examples)

## Overview

The Skills Marketplace uses **template variables** to make skills portable across any project. Instead of hardcoding project-specific values like repository names or commit prefixes, skills reference configurable variables.

### Why Abstraction?

**Before (Project-Specific):**
```bash
# Hardcoded in SKILL.md
git commit -m "AIGWS-123: Add feature"
gh pr create --repo aigensa/landing_page
```

**After (Marketplace-Ready):**
```bash
# References config.yaml
git commit -m "{{PROJECT_PREFIX}}-123: Add feature"
gh pr create --repo {{REPO_SLUG}}
```

**Benefits:**
- ✅ Skills work in any project
- ✅ No code changes when moving skills
- ✅ Central configuration management
- ✅ Easy to share and distribute

## Template Variable System

### Syntax

Template variables use double curly braces: `{{VARIABLE_NAME}}`

**In config.yaml (Template):**
```yaml
repository:
  slug: "{{REPO_SLUG}}"
```

**In user's project (Actual Values):**
```yaml
repository:
  slug: "myorg/myrepo"  # No curly braces - real value
```

**In SKILL.md (Documentation):**
```markdown
Creates PR to {{REPO_SLUG}} repository.
```

### Variable Naming Conventions

**Uppercase with underscores:**
```
{{PROJECT_PREFIX}}      ✓ Good
{{REPO_SLUG}}          ✓ Good
{{Active_Story_File}}   ✗ Bad - use snake_case
{{repoSlug}}           ✗ Bad - use SCREAMING_SNAKE_CASE
```

**Descriptive names:**
```
{{PREFIX}}             ✗ Too vague
{{PROJECT_PREFIX}}     ✓ Clear and specific
{{FILE}}               ✗ Too generic
{{ACTIVE_STORY_FILE}}  ✓ Descriptive
```

## Abstraction Patterns

### Pattern 1: Repository References

**Hardcoded:**
```yaml
repository: "aigensa/landing_page"
url: "https://github.com/aigensa/landing_page"
```

**Abstracted:**
```yaml
repository:
  slug: "{{REPO_SLUG}}"
  owner: "{{REPO_OWNER}}"
  name: "{{REPO_NAME}}"
  url: "https://github.com/{{REPO_SLUG}}"
```

**User Configuration:**
```yaml
repository:
  slug: "acme/webapp"
  owner: "acme"
  name: "webapp"
  url: "https://github.com/acme/webapp"
```

### Pattern 2: File Paths

**Hardcoded:**
```yaml
active_story: ".claude/active-story.json"
infrastructure: "infrastructure/"
```

**Abstracted:**
```yaml
paths:
  active_story: "{{ACTIVE_STORY_FILE}}"
  infrastructure: "{{INFRA_DIR}}"
```

**Flexibility:** Users can use different directory structures:
```yaml
paths:
  active_story: ".project/current-task.json"
  infrastructure: "infra/"
```

### Pattern 3: Naming Prefixes

**Hardcoded:**
```bash
COMMIT_PREFIX="AIGWS"
echo "$COMMIT_PREFIX-123: Add feature"
```

**Abstracted:**
```bash
COMMIT_PREFIX=$(yq e '.numbering.prefix' config.yaml)
echo "$COMMIT_PREFIX-123: Add feature"
```

**Configuration:**
```yaml
numbering:
  prefix: {{PROJECT_PREFIX}}  # Template
  # User sets to: "MYAPP"
```

### Pattern 4: Branch Names

**Hardcoded:**
```bash
git checkout -b "story-157-add-auth"
```

**Abstracted:**
```bash
STORY_PREFIX=$(yq e '.branch_naming.story_prefix' config.yaml)
git checkout -b "${STORY_PREFIX}-157-add-auth"
```

**Configuration:**
```yaml
branch_naming:
  story_prefix: {{STORY_PREFIX}}  # Template
  # User sets to: "feature" or "story" or "task"
```

### Pattern 5: GitHub Project IDs

**Hardcoded:**
```json
{
  "projectId": "PVT_kwDODvZ3Zc4BM9rk",
  "fieldIds": {
    "status": "PVTSSF_lADODvZ3Zc4BM9rkzg8GG4A"
  }
}
```

**Abstracted:**
```json
{
  "projectId": "{{GITHUB_PROJECT_ID}}",
  "fieldIds": {
    "status": "{{FIELD_ID_STATUS}}"
  }
}
```

**Discovery:** Users must query GitHub API to get their project's IDs.

### Pattern 6: Tool Commands

**Hardcoded:**
```yaml
commands:
  test: "npm test"
  type_check: "tsc --noEmit"
```

**Abstracted:**
```yaml
commands:
  test: "{{TEST_CMD}}"
  type_check: "{{TYPE_CHECK_CMD}}"
```

**Flexibility:** Works with any stack:
```yaml
# JavaScript
commands:
  test: "jest"

# Python
commands:
  test: "pytest"

# Rust
commands:
  test: "cargo test"
```

## Common Variables

### Project Identity

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{PROJECT_PREFIX}}` | Commit/branch prefix | MYAPP | Yes |
| `{{PROJECT_NAME}}` | Full project name | My Application | No |

### Repository

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{REPO_SLUG}}` | GitHub repository | owner/repo | Yes |
| `{{REPO_OWNER}}` | Repository owner | owner | Yes |
| `{{REPO_NAME}}` | Repository name | repo | Yes |
| `{{DEFAULT_BRANCH}}` | Target branch | main | Yes |
| `{{DEFAULT_REMOTE}}` | Git remote name | origin | No |

### File Paths

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{ACTIVE_STORY_FILE}}` | Active story JSON | .claude/active-story.json | Conditional |
| `{{SKILLS_DIR}}` | Skills directory | .claude/skills/ | No |
| `{{INFRA_DIR}}` | Infrastructure directory | infrastructure/ | No |
| `{{ADR_DIR}}` | ADR directory | docs/adr/ | No |

### GitHub Projects

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{GITHUB_PROJECT_ID}}` | Project node ID | PVT_kwDO... | Conditional |
| `{{FIELD_ID_STATUS}}` | Status field ID | PVTSSF_lADO... | Conditional |
| `{{OPTION_ID_STATUS_READY}}` | Ready option ID | 61e4505c | Conditional |

### Workflow Settings

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{STORY_PREFIX}}` | Story branch prefix | story | No |
| `{{MAX_BRANCH_LENGTH}}` | Max branch name length | 25 | No |
| `{{SIMILARITY_THRESHOLD}}` | Theme similarity | 0.40 | No |

### Commands

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{TEST_CMD}}` | Test command | npm test | No |
| `{{TYPE_CHECK_CMD}}` | Type check command | tsc --noEmit | No |
| `{{LINT_CMD}}` | Lint command | eslint . | No |
| `{{BUILD_CMD}}` | Build command | npm run build | No |

### Messages

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| `{{PR_FOOTER}}` | PR footer text | 🤖 Generated with Claude Code | No |

## Creating Abstracted Skills

### Step 1: Identify Hardcoded Values

Search for project-specific patterns:

```bash
# In your skill directory
grep -r "AIGWS\|AIGCODE\|AIGNEWS" .
grep -r "aigensa/" .
grep -r "landing_page\|vibe-coding" .
grep -r "PVT_kwDO" .
```

### Step 2: Extract to Config

Create `config.yaml` with template variables:

```yaml
# Don't include actual values - use template vars
repository:
  slug: "{{REPO_SLUG}}"  # NOT: "aigensa/landing_page"

numbering:
  prefix: {{PROJECT_PREFIX}}  # NOT: AIGWS
```

### Step 3: Replace in SKILL.md

Replace hardcoded values with template variable references:

```markdown
<!-- Before -->
Creates commits with AIGWS prefix to aigensa/landing_page.

<!-- After -->
Creates commits with {{PROJECT_PREFIX}} prefix to {{REPO_SLUG}}.
```

### Step 4: Create Example Config

Provide `config.example.yaml` with realistic sample values:

```yaml
repository:
  slug: "myorg/myrepo"  # Example value, not template

numbering:
  prefix: MYAPP  # Example value
```

### Step 5: Document Variables

Add "Template Variables Reference" section to SKILL.md:

```markdown
## Template Variables Reference

| Variable | Purpose | Example | Required |
|----------|---------|---------|----------|
| {{REPO_SLUG}} | GitHub repository | owner/repo | Yes |
| {{PROJECT_PREFIX}} | Commit prefix | MYAPP | Yes |
```

### Step 6: Validate

```bash
# Should find nothing
grep -r "AIGWS\|AIGCODE\|AIGNEWS" .
grep -r "aigensa/" . --exclude="*.example.*"
```

## Migration Examples

### Example 1: Simple Skill (create-story)

**Original config.yaml:**
```yaml
repository:
  slug: "aigensa/landing_page"

active_story:
  path: ".claude/active-story.json"
```

**Abstracted config.yaml:**
```yaml
repository:
  slug: "{{REPO_SLUG}}"

active_story:
  path: "{{ACTIVE_STORY_FILE}}"
```

**Changes in SKILL.md:**
```diff
- Creates GitHub issues in aigensa/landing_page repository.
+ Creates GitHub issues in {{REPO_SLUG}} repository.

- Saves to `.claude/active-story.json`
+ Saves to {{ACTIVE_STORY_FILE}}
```

### Example 2: Complex Skill (commit)

**Original config.yaml:**
```yaml
numbering:
  prefix: AIGCODE

issue:
  source: ".claude/active-story.json"

commands:
  type_check: "npm run type-check"
```

**Abstracted config.yaml:**
```yaml
numbering:
  prefix: {{PROJECT_PREFIX}}

issue:
  source: "{{ACTIVE_STORY_FILE}}"

commands:
  type_check: "{{TYPE_CHECK_CMD}}"
```

**Changes in bash snippets:**
```diff
- COMMIT_PREFIX="AIGCODE-${ISSUE_NUMBER}"
+ PREFIX=$(yq e '.numbering.prefix' config.yaml)
+ COMMIT_PREFIX="${PREFIX}-${ISSUE_NUMBER}"

- STORY_FILE=".claude/active-story.json"
+ STORY_FILE=$(yq e '.issue.source' config.yaml)
```

### Example 3: Deeply Embedded Values (sync-skills)

**Original SKILL.md (50+ references):**
```markdown
Syncs to https://github.com/amdmax/agent_skills.
Repository owner: amdmax
Clone from: git@github.com:amdmax/agent_skills.git
```

**Abstracted approach:**

1. **Create config.yaml:**
```yaml
repository:
  owner: "{{SKILLS_REPO_OWNER}}"
  name: "{{SKILLS_REPO_NAME}}"
  url: "https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}"
```

2. **Use sed for bulk replacement:**
```bash
sed 's/amdmax/{{SKILLS_REPO_OWNER}}/g' SKILL.md
sed 's/agent_skills/{{SKILLS_REPO_NAME}}/g' SKILL.md
```

3. **Validate:**
```bash
grep -c "amdmax\|agent_skills" SKILL.md
# Should return: 0
```

## Best Practices

### DO:
✅ Use descriptive variable names (`{{ACTIVE_STORY_FILE}}` not `{{FILE}}`)
✅ Group related variables in config.yaml (`repository:`, `paths:`)
✅ Provide config.example.yaml with realistic examples
✅ Document all variables in SKILL.md
✅ Use SCREAMING_SNAKE_CASE for variable names
✅ Keep config.yaml as template (no real values)

### DON'T:
❌ Hardcode any project-specific values
❌ Use vague variable names (`{{PREFIX}}` vs `{{PROJECT_PREFIX}}`)
❌ Mix template vars with real values in config.yaml
❌ Forget to abstract hook configurations
❌ Skip config.example.yaml
❌ Leave undocumented variables

## Troubleshooting

### Issue: Variables Not Replaced

**Problem:** Skill shows `{{REPO_SLUG}}` literally instead of value.

**Solution:** Check user's config.yaml has actual value (no curlies):
```yaml
# Wrong
repository:
  slug: "{{REPO_SLUG}}"

# Right
repository:
  slug: "acme/webapp"
```

### Issue: Partial Abstraction

**Problem:** Some values abstracted, others hardcoded.

**Solution:** Search systematically:
```bash
# Find all potential hardcoded values
grep -r "aigensa\|AIGWS\|AIGCODE" .
grep -r "github\.com/[a-z]" .
grep -r "PVT_kwDO" .
```

### Issue: Config Variable Not Found

**Problem:** `yq: command not found` or jq errors.

**Solution:** Skills assume yq/jq available. Document in prerequisites:
```markdown
## Prerequisites

- yq v4+ for YAML parsing
- jq for JSON parsing
```

## See Also

- [Configuration Reference](configuration-reference.md) - Complete config options
- [USAGE_GUIDE.md](../USAGE_GUIDE.md) - How to use marketplace skills
- [config-schema.md](../skills/_templates/config-schema.md) - Config file structure
