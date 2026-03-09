---
name: refactor-skill
description: Convert monolithic SKILL.md files to modular structure with references/, config.yaml for parameters, and optional validation hooks in frontmatter. Use when skills exceed 500 lines, contain hardcoded project-specific values, or would benefit from progressive disclosure patterns.
---

# Skill Refactoring Tool

## Overview

This skill refactors existing monolithic SKILL.md files into a modular, maintainable structure following Anthropic's progressive disclosure patterns. It:

1. **Analyzes structure** - Detects logical sections and breakpoints
2. **Extracts references** - Moves detailed content to `references/` directory
3. **Parameterizes values** - Generates `config.yaml` for project-specific settings
4. **Adds validation** - Optionally adds hooks to frontmatter for self-validation
5. **Preserves functionality** - Ensures all content is retained and accessible

**When to use:**
- Skill files exceed 500 lines
- Repeated context loading slows execution
- Multiple skills share common patterns
- Project-specific values are hardcoded
- Skills would benefit from clearer organization

## Workflow

### Step 1: Select Skill to Refactor

**Ask user:**
"Which skill should I refactor? Provide the skill name or path to SKILL.md."

**Load and analyze the skill:**
```bash
# List available skills
find .claude/skills -name "SKILL.md" -type f

# Read the target skill
cat .claude/skills/{skill-name}/SKILL.md
```

**Analyze metrics:**
- Line count: `wc -l .claude/skills/{skill-name}/SKILL.md`
- Section count: `grep "^## " .claude/skills/{skill-name}/SKILL.md | wc -l`
- File size: `du -h .claude/skills/{skill-name}/SKILL.md`

**Report to user:**
```
Current skill metrics:
- Lines: 1,242
- Sections: 12
- Size: 45KB

Recommendation: [Strong candidate for refactoring | Moderate benefit | Marginal benefit]
```

### Step 2: Analyze Structure

**Parse the SKILL.md:**

```bash
# Extract all section headers
grep -n "^## " .claude/skills/{skill-name}/SKILL.md
```

**Example output:**
```
42:## Overview
58:## Workflow
75:## Step 1: Verify Staged Changes
120:## Step 2: Find Next AIGCODE Number
185:## Step 2b: Detect Related Recent Commits
310:## Step 3: Analyze Changes
425:## Step 4: Generate Commit Message
580:## Step 5: Create Commit
680:## Error Handling
750:## Examples
850:## Advanced Usage
```

**Identify refactoring opportunities:**

1. **Logical groupings:**
   - Configuration/setup sections
   - Core workflow steps
   - Advanced features
   - Error handling
   - Examples

2. **Size thresholds:**
   - Sections >100 lines → Strong candidate for extraction
   - Sections 50-100 lines → Consider extraction if self-contained
   - Sections <50 lines → Keep in main SKILL.md unless part of larger group

3. **Reference patterns:**
   - Detailed algorithms → `references/algorithm-{name}.md`
   - Error catalogs → `references/error-handling.md`
   - Examples → `references/examples.md`
   - API documentation → `references/api-reference.md`
   - Advanced features → `references/advanced-usage.md`

**Propose structure to user:**
```
Proposed refactoring:

Main SKILL.md (reduced to ~200 lines):
- Overview and quick start
- High-level workflow steps
- References to detailed sections

New references/:
- references/aigcode-numbering.md (lines 120-309)
- references/grouping-detection.md (lines 185-309)
- references/commit-analysis.md (lines 310-424)
- references/message-generation.md (lines 425-579)
- references/error-handling.md (lines 680-749)
- references/examples.md (lines 750-849)

Estimated token reduction: 60% (main file only loaded initially)
```

### Step 3: Scan for Hardcoded Values

**Detection patterns:**

```bash
# Repository identifiers
grep -nE "github\.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+" SKILL.md
grep -nE "(origin|upstream|remote)" SKILL.md

# Branch names
grep -nE "(master|main|develop|staging)" SKILL.md

# Project-specific prefixes/patterns
grep -nE "[A-Z]{2,10}-[0-9]+" SKILL.md  # Like AIGCODE-###

# Threshold values
grep -nE "0\.[0-9]{2}" SKILL.md  # Like 0.40 threshold

# File paths
grep -nE "/_[a-z]+/" SKILL.md
grep -nE "\\.claude/" SKILL.md
```

**Categorize findings:**

1. **Repository settings:**
   - `origin` (git remote)
   - `master` (base branch)
   - `github.com/aigensa/vibe-coding-course` (repo path)

2. **Naming conventions:**
   - `AIGCODE` (commit prefix)
   - `feature/`, `fix/` (branch prefixes)

3. **Thresholds:**
   - `0.40` (theme similarity threshold)
   - `4 hours ago` (recent commit window)

4. **Paths:**
   - `.claude/skills/`
   - `_bmad/`

**Present findings:**
```
Found 15 hardcoded values:

Repository settings:
- remote: "origin" (3 occurrences)
- base_branch: "master" (5 occurrences)
- repo_owner: "aigensa" (2 occurrences)

Conventions:
- commit_prefix: "AIGCODE" (8 occurrences)
- theme_threshold: 0.40 (1 occurrence)

Should I:
[A] Parameterize all (max portability)
[B] Parameterize repository settings only
[C] Custom selection
[S] Skip parametrization
```

### Step 4: Create config.yaml (If Approved)

**Generate configuration file:**

```yaml
# Skill: {skill-name}
# Generated by refactor-skill

# Repository settings
repository:
  remote: origin
  base_branch: master
  repo_owner: aigensa
  repo_name: vibe-coding-course

# Naming conventions
conventions:
  commit_prefix: AIGCODE
  branch_prefix_feature: feature/
  branch_prefix_fix: fix/
  branch_max_length: 25

# Thresholds and tuning
tuning:
  theme_similarity_threshold: 0.40
  recent_commit_window: "4 hours ago"
  max_commits_check: 10

# Paths (relative to project root)
paths:
  skills_dir: .claude/skills
  bmad_dir: _bmad
```

**Write to file:**
```bash
cat > .claude/skills/{skill-name}/config.yaml <<'EOF'
[config content]
EOF
```

**Update SKILL.md to load config:**

Add to SKILL.md:
```markdown
## Configuration

This skill uses `config.yaml` for project-specific settings. Customize these values for your project:

**Repository settings:**
- `repository.remote`: Git remote name (default: origin)
- `repository.base_branch`: Base branch for PRs (default: master)

**Conventions:**
- `conventions.commit_prefix`: Commit number prefix (default: AIGCODE)

Load configuration:
```bash
# Using yq (YAML processor)
REMOTE=$(yq e '.repository.remote' config.yaml)
BASE_BRANCH=$(yq e '.repository.base_branch' config.yaml)

# Or using Python
python3 -c "import yaml; c=yaml.safe_load(open('config.yaml')); print(c['repository']['remote'])"
```

See [CONFIG.md](references/config-reference.md) for all options.
```

### Step 5: Extract Sections to References

**For each section marked for extraction:**

1. **Create reference file:**
```bash
mkdir -p .claude/skills/{skill-name}/references

# Extract lines 120-309 to aigcode-numbering.md
sed -n '120,309p' .claude/skills/{skill-name}/SKILL.md > \
  .claude/skills/{skill-name}/references/aigcode-numbering.md
```

2. **Add section header to reference file:**
```markdown
# AIGCODE Numbering System

> **Reference for:** {skill-name}
> **Context:** This document is loaded when detailed AIGCODE numbering logic is needed.

[extracted content]
```

3. **Update main SKILL.md:**

Replace extracted section with reference:
```markdown
## Step 2: Find Next AIGCODE Number

The skill uses sequential numbering across all branches.

**Quick usage:**
```bash
git log --oneline --all --grep="AIGCODE-" | grep -o "AIGCODE-[0-9]*" | sort -u | tail -1
```

**For detailed algorithm and edge cases:** See [AIGCODE Numbering](references/aigcode-numbering.md)
```

### Step 6: Define Validation Hooks (Optional)

**Ask user:**
```
Would you like to add validation hooks for this skill?

Hooks enable automatic validation when the skill executes:
- Stop: Validate after skill completes
- PostToolUse: Check after file changes
- PreToolUse: Security checks before operations

[Y] Yes, add validation hooks
[N] No, skip validation
```

**If yes, ask about validation needs:**

```
What should be validated?

Common patterns:
[1] Compilation (tsc, cargo check, go build)
[2] Linting (eslint, prettier)
[3] Tests (npm test, pytest)
[4] Git operations (PR created, commit format)
[5] API verification (endpoints respond)
[6] Custom validation
[C] Custom (describe what to validate)
```

**Map validation to hook events:**

| Validation Type | Hook Event | Example |
|-----------------|------------|---------|
| Compilation, Tests, Final checks | Stop | `tsc --noEmit` |
| Linting, Formatting | PostToolUse | `eslint --fix` |
| Security checks | PreToolUse | `./scripts/security-check.sh` |

**Example interaction:**
```
Selected: [1] Compilation, [2] Linting

For Compilation:
  Event: Stop (runs after skill completes)
  Command: tsc --noEmit
  Timeout: 30 seconds
  Blocking: Yes (exit code 2 stops execution)

For Linting:
  Event: PostToolUse
  Matcher: Write|Edit (runs after file changes)
  Command: eslint --fix
  Timeout: 10 seconds
  Blocking: No (warnings only)
```

**Generate hooks in frontmatter format:**

```yaml
hooks:
  Stop:
    - hooks:
        - type: command
          command: "tsc --noEmit"
          timeout: 30
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "eslint --fix"
          timeout: 10
```

**Optional: Create hooks.json for documentation**

If user wants to document recommended global hooks:

```json
{
  "skill": "{skill-name}",
  "description": "Recommended hooks for enhanced validation",
  "note": "These are optional. Skill has its own validation in frontmatter.",
  "global_hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write",
            "description": "Auto-format all files after changes"
          }
        ]
      }
    ]
  }
}
```

### Step 7: Create Refactored SKILL.md

**Generate new main SKILL.md with hooks:**

```markdown
---
name: {skill-name}
description: {original description}
hooks:
  Stop:
    - hooks:
        - type: command
          command: "validation-command"
---

# {Skill Title}

## Overview

{Concise 2-3 paragraph overview - keep the essence}

## Quick Start

{Most common usage pattern - 10-20 lines}

## Configuration

Load settings from `config.yaml`:
```bash
[config loading example]
```

See [Configuration Reference](references/config-reference.md) for all options.

## Workflow

### Step 1: {First Step}
{High-level description}
See [detailed algorithm](references/{step-1}.md) for implementation.

### Step 2: {Second Step}
{High-level description}
See [detailed algorithm](references/{step-2}.md) for implementation.

[... continue for all steps]

## Error Handling

Common issues and solutions:
- **Error X**: Brief description → See [Error Handling Guide](references/error-handling.md)
- **Error Y**: Brief description → See [Error Handling Guide](references/error-handling.md)

## Examples

**Example 1: {Common case}**
```bash
[quick example]
```

**More examples:** See [Examples Reference](references/examples.md)

## Advanced Usage

For advanced features:
- **Feature A**: See [Advanced Usage](references/advanced-usage.md)
- **Feature B**: See [Advanced Usage](references/advanced-usage.md)
```

### Step 8: Backup and Swap

**Create backup:**
```bash
cp .claude/skills/{skill-name}/SKILL.md \
   .claude/skills/{skill-name}/SKILL.md.backup.$(date +%Y%m%d_%H%M%S)
```

**Write new SKILL.md:**
```bash
cat > .claude/skills/{skill-name}/SKILL.md <<'EOF'
[refactored content]
EOF
```

**Verify structure:**
```bash
ls -lah .claude/skills/{skill-name}/
# Should show:
# - SKILL.md (new, smaller, with hooks in frontmatter)
# - SKILL.md.backup.YYYYMMDD_HHMMSS (original)
# - config.yaml (if created)
# - hooks.json (optional, if documenting global hooks)
# - references/ (directory with extracted sections)
```

### Step 9: Validate Refactoring

**Check integrity:**

1. **No content loss:**
```bash
# Compare word counts
wc -w .claude/skills/{skill-name}/SKILL.md.backup.*
wc -w .claude/skills/{skill-name}/SKILL.md
wc -w .claude/skills/{skill-name}/references/*.md

# Total words in new structure should equal or exceed original
```

2. **References resolve:**
```bash
# Check all referenced files exist
grep -oE 'references/[a-z-]+\.md' .claude/skills/{skill-name}/SKILL.md | \
  while read ref; do
    if [ ! -f ".claude/skills/{skill-name}/$ref" ]; then
      echo "MISSING: $ref"
    fi
  done
```

3. **Valid YAML frontmatter:**
```bash
# Validate SKILL.md frontmatter (including hooks)
yq e '.' .claude/skills/{skill-name}/SKILL.md | head -20 && \
  echo "✓ SKILL.md frontmatter valid"

# Validate config.yaml if exists
if [ -f ".claude/skills/{skill-name}/config.yaml" ]; then
  yq e '.' .claude/skills/{skill-name}/config.yaml > /dev/null && \
    echo "✓ config.yaml valid" || echo "✗ config.yaml invalid"
fi

# Validate hooks.json if exists (optional documentation)
if [ -f ".claude/skills/{skill-name}/hooks.json" ]; then
  jq '.' .claude/skills/{skill-name}/hooks.json > /dev/null && \
    echo "✓ hooks.json valid" || echo "✗ hooks.json invalid"
fi
```

**Report results:**
```
Refactoring complete! ✓

Original: 1,242 lines, 45KB
New structure:
  - SKILL.md: 187 lines, 7KB (85% reduction)
  - references/: 6 files, 38KB
  - config.yaml: 42 lines
  - hooks.json: 28 lines

Backup created: SKILL.md.backup.20260123_143022

Next steps:
1. Test the skill: /{skill-name}
2. Verify all references load correctly
3. Validate hooks (if created): .claude/lib/validate-skill-success.js {skill-name}
4. Delete backup after confirming functionality
```

## Refactoring Patterns

### Pattern 1: Sequential Workflow Skills

**Structure:**
```
SKILL.md (main)
- Overview
- Quick start
- High-level workflow

references/
- step-01-{name}.md
- step-02-{name}.md
- step-03-{name}.md
- error-handling.md
- examples.md
```

### Pattern 2: Conditional/Branching Skills

**Structure:**
```
SKILL.md (main)
- Overview
- Decision tree/routing logic

references/
- path-a-{scenario}.md
- path-b-{scenario}.md
- common-operations.md
- error-handling.md
```

### Pattern 3: Analysis/Review Skills

**Structure:**
```
SKILL.md (main)
- Overview
- Analysis framework

references/
- checklist-{category}.md
- best-practices.md
- examples.md
- scoring-rubrics.md
```

## Best Practices

### Keep Main SKILL.md Concise
- Target: <300 lines
- Focus: Overview, routing, quick reference
- Defer: Details, edge cases, examples to references/

### Reference Organization
- One topic per file
- Clear, descriptive filenames
- Include context header in each reference
- Keep references one level deep (avoid nested directories)

### Parameterization Guidelines
- **Always parameterize:** Repository URLs, branch names, remote names
- **Consider parameterizing:** Thresholds, time windows, limits
- **Don't parameterize:** Fundamental algorithms, skill logic

### Success Criteria Quality
- **Specific:** Clear, unambiguous outcomes
- **Measurable:** Executable commands with expected outputs
- **Achievable:** Can be validated with available tools
- **Relevant:** Directly related to skill purpose
- **Testable:** Automated validation possible

## Error Handling

### Common Issues

**Issue: Reference file not found**
- Cause: Incorrect path in SKILL.md reference
- Solution: Verify all `[text](references/file.md)` paths exist
- Command: `find .claude/skills/{skill-name}/references -name "*.md"`

**Issue: Config values not loading**
- Cause: Invalid YAML syntax or missing keys
- Solution: Validate config.yaml syntax
- Command: `yq e '.' config.yaml`

**Issue: Hooks not executing**
- Cause: Invalid YAML in frontmatter hooks section
- Solution: Validate SKILL.md frontmatter syntax
- Command: `yq e '.hooks' .claude/skills/{skill-name}/SKILL.md`
- See: [Skill Hooks Guide](.claude/lib/skill-hooks-guide.md)

**Issue: Content appears duplicated**
- Cause: Section extracted but not removed from main SKILL.md
- Solution: Ensure main SKILL.md only contains references, not full content

## Rollback Procedure

If refactoring causes issues:

```bash
# Restore original SKILL.md
cp .claude/skills/{skill-name}/SKILL.md.backup.* \
   .claude/skills/{skill-name}/SKILL.md

# Remove generated files
rm -rf .claude/skills/{skill-name}/references/
rm -f .claude/skills/{skill-name}/config.yaml
rm -f .claude/skills/{skill-name}/hooks.json  # if exists

# Verify restoration
git diff .claude/skills/{skill-name}/SKILL.md
```

## Resources

- [Skill Hooks Guide](.claude/lib/skill-hooks-guide.md) - Complete guide to skill-specific hooks
- [Claude Code Hooks Documentation](https://code.claude.com/docs/en/hooks) - Official hooks reference
- [Anthropic Skills Repository](https://github.com/anthropics/skills) - Example skills with progressive disclosure
