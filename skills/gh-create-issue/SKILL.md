---
description: Create high-quality, comprehensive GitHub issues with templates, validation, and best practices. For detailed, well-structured issues requiring planning and documentation. Use /create-story for minimal issues during commits.
invocation: gh:create-issue
---

# GitHub Issue Creation Skill

> **Create comprehensive, well-structured GitHub issues**
> Template-driven workflow with validation and quality checks

## Overview

This skill guides you through creating **high-quality GitHub issues** that follow best practices for structure, clarity, and actionability. It provides:

1. **Issue type selection** - Bug, Feature, Task, Investigation, Test Failure
2. **Template-based structure** - Consistent, scannable format
3. **Quality validation** - Checks for clarity and completeness
4. **Validated creation** - Uses gh CLI with error handling

**Different from `/create-story`**: This skill creates detailed, comprehensive issues for planning and tracking. Use `/create-story` for minimal issues during the commit workflow.

## When to Use This Skill

**Use `/gh:create-issue` when:**
- Creating planned work items for sprints
- Documenting complex bugs requiring investigation
- Proposing new features with detailed requirements
- Creating investigation tasks
- Documenting test failures comprehensively

**Use `/create-story` when:**
- Making ad-hoc commits without an active story
- Need minimal issue quickly during development

## How It Works

### Step 1: Determine Issue Type

Ask the user to select the issue type using AskUserQuestion:

```
What type of issue are you creating?
- Bug Report
- Feature Request
- Task/Chore
- Investigation
- Test Failure
```

Based on selection, load the appropriate template from @references/issue-templates.md.

### Step 2: Gather Information

Use AskUserQuestion to collect key details based on issue type:

**For Bug Reports:**
- What is the problem?
- What is the current behavior?
- What is the expected behavior?
- How to reproduce?
- Any error messages or logs?

**For Feature Requests:**
- What problem does this solve?
- What is the proposed solution?
- What are the benefits?
- Any alternatives considered?

**For Tasks/Chores:**
- What needs to be done?
- Why is this needed (context)?
- What is the desired outcome?

**For Investigations:**
- What needs to be investigated?
- Why is this investigation needed?
- What is the scope?

**For Test Failures:**
- Which tests are failing?
- What is the error output?
- What is the expected behavior?
- Any known root cause?

### Step 3: Build Issue Content

Use the selected template and fill in with gathered information:

1. Load template from @references/issue-templates.md
2. Replace placeholders with user-provided content
3. Add tasks section with checkboxes
4. Add acceptance criteria
5. Include file paths if known
6. Format code blocks properly

**Quality checks** (based on @references/best-practices.md):
- Title is specific and actionable (10-100 chars)
- Body has sufficient context (>20 chars)
- Tasks are present and use checkbox format `- [ ]`
- Code blocks use language hints
- Sections use proper headers (##)
- No vague terms (it/this/that/stuff)

### Step 4: Preview and Confirm

Show the user a preview of the issue:

```markdown
Title: [Generated title]

Body:
[Generated body with formatting]

Labels: [If any]
Assignees: [If any]
```

Ask for confirmation or allow editing.

### Step 5: Create Issue

Use the @scripts/create_issue.sh script to create the issue:

```bash
cd .claude/skills/gh-create-issue
./scripts/create_issue.sh \
  "$TITLE" \
  "$BODY" \
  "${LABELS:-}" \
  "${ASSIGNEES:-}"
```

The script will:
- Validate authentication (`gh auth status`)
- Detect repository from git config or REPO_SLUG env var
- Validate title and body quality (warnings)
- Create issue via `gh issue create`
- Extract issue number from URL
- Return JSON with number, URL, and title

**Error Handling:**

Exit codes from create_issue.sh:
- `0`: Success
- `1`: Validation error (missing required fields)
- `2`: Authentication error (`gh auth login` needed)
- `3`: GitHub API error
- `4`: Configuration error (no repo found)

Handle each error appropriately:
- Exit 1: Show validation errors, ask user to provide missing info
- Exit 2: Tell user to run `gh auth login`
- Exit 3: Show API error message, check network/permissions
- Exit 4: Ask user to set REPO_SLUG or run from git repo

### Step 6: Report Results

Display the created issue details:

```
✅ Successfully created issue #123
   https://github.com/owner/repo/issues/123

Title: Fix Pa11y accessibility test failures
```

**Optional: Update Active Story**

Ask if this issue should become the active story:

```
Do you want to set this as your active story?
- Yes (update .claude/active-story.json)
- No (just create the issue)
```

If yes, write to `.claude/active-story.json`:

```json
{
  "issueNumber": 123,
  "title": "Issue title",
  "body": "Issue body",
  "url": "https://github.com/owner/repo/issues/123"
}
```

## Templates

**See:** @references/issue-templates.md for all templates

Available templates:
- Bug Report Template
- Feature Request Template
- Task/Chore Template
- Investigation Template
- Test Failure Template

Each template includes:
- Standard sections (Problem, Tasks, Acceptance Criteria)
- Proper markdown formatting
- Checkbox tasks
- Code block placeholders
- File path sections

## Best Practices

**See:** @references/best-practices.md for comprehensive guidelines

Key principles:
1. **Titles:** Specific, actionable, imperative mood (10-100 chars)
2. **Structure:** Headers, code blocks, checklists, bullet points
3. **Content:** Include "why", provide context, list acceptance criteria
4. **Format:** Use markdown effectively for scannability

**Quality checks:**
- ✅ Can someone pick this up without asking questions?
- ✅ Are tasks specific and testable?
- ✅ Is the problem clearly stated?
- ✅ Are code examples properly formatted?

## Examples

**See:** @references/examples.md for real issues from this repository

**Example 1: Simple Task (Issue #86)**
- Clear, actionable title
- Specific changes listed
- Files identified
- Concise and scannable

**Example 2: Complex Bug (Issue #88)**
- Comprehensive problem statement
- Current vs expected behavior
- Root cause analysis
- Detailed tasks and acceptance criteria

## Integration with Existing Workflows

### Relationship to `/create-story`

| Feature | `/gh:create-issue` | `/create-story` |
|---------|-------------------|-----------------|
| **Purpose** | Detailed planning | Quick commits |
| **Structure** | Comprehensive templates | Minimal fields |
| **Validation** | Quality checks | Basic only |
| **Time** | 2-3 min (interactive) | 30 sec (fast) |
| **When** | Sprint planning | Ad-hoc commits |

### Relationship to `/commit`

The `/commit` skill auto-creates issues via `/create-story` when no active story exists. This skill (`/gh:create-issue`) is for **deliberate, well-planned** issue creation, not automated commit workflow.

### Setting Active Story

After creating an issue with this skill, you can optionally set it as the active story. This updates `.claude/active-story.json` so `/commit` uses the new issue for commit messages.

## Configuration

**Repository Detection:**

The script auto-detects the repository from:
1. `REPO_SLUG` environment variable (e.g., `export REPO_SLUG="aigensa/website"`)
2. Git remote origin URL (if running from git repo)

**To override:**
```bash
REPO_SLUG="owner/repo" /gh:create-issue
```

## Workflow Summary

```
1. Ask: Issue type?
   ↓
2. Load: Template for type
   ↓
3. Gather: Type-specific details
   ↓
4. Build: Issue content with validation
   ↓
5. Preview: Show to user, confirm
   ↓
6. Create: Via create_issue.sh script
   ↓
7. Report: Issue URL and number
   ↓
8. Optional: Set as active story
```

## Error Handling

**Authentication Issues:**
```
❌ Error: GitHub CLI not authenticated
   Run: gh auth login
```

**Validation Issues:**
```
⚠️  Warning: Title is very short (8 chars). Consider adding more context.
⚠️  Warning: No task checkboxes found. Consider adding actionable tasks.
```

**Repository Issues:**
```
❌ Error: Could not determine repository
   Set REPO_SLUG environment variable or run from a git repository
```

**API Issues:**
```
❌ Failed to create GitHub issue
   [API error message]
```

## Tips for Best Results

1. **Be specific in titles** - "Fix Pa11y tests failing CI" not "Fix tests"
2. **Include context** - Explain why, not just what
3. **List files** - Help others find relevant code
4. **Add error output** - For bugs/test failures, paste actual errors
5. **Use tasks** - Break work into checkable items
6. **Define "done"** - Clear acceptance criteria

**Before submitting:**
- Can someone else pick this up without questions?
- Are tasks specific and testable?
- Is the problem clearly stated?
- Is markdown formatted correctly?

## Exit Codes

The create_issue.sh script returns:
- `0` - Success
- `1` - Validation error
- `2` - Authentication error
- `3` - GitHub API error
- `4` - Configuration error

Use these to handle errors appropriately in the workflow.

## Quick Reference

**Invoke:** `/gh:create-issue`

**Files:**
- `SKILL.md` - This file (workflow)
- `references/issue-templates.md` - All issue templates
- `references/best-practices.md` - Quality guidelines
- `references/examples.md` - Real issue examples
- `scripts/create_issue.sh` - Validated creation script

**Related:**
- `/create-story` - Minimal issue creation for commits
- `/commit` - Commit workflow (auto-creates via create-story)
- `/fetch-story` - Fetch planned work from GitHub Projects
