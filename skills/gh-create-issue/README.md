# GitHub Issue Creation Skill (`/gh:create-issue`)

A comprehensive skill for creating high-quality, well-structured GitHub issues with templates, validation, and best practices.

## Quick Start

Invoke the skill with:
```
/gh:create-issue
```

The skill will guide you through:
1. Selecting issue type (Bug, Feature, Task, Investigation, Test Failure)
2. Gathering relevant information
3. Building structured issue content
4. Validating quality
5. Creating the issue in GitHub

## What's Included

### Templates (`references/issue-templates.md`)
- Bug Report Template
- Feature Request Template
- Task/Chore Template
- Investigation Template
- Test Failure Template

### Best Practices (`references/best-practices.md`)
Guidelines for:
- Writing clear, actionable titles
- Structuring issues with markdown
- Including proper context
- Creating testable acceptance criteria
- Common mistakes to avoid

### Examples (`references/examples.md`)
Real issues from this repository:
- Issue #86: Simple task/update
- Issue #88: Complex bug report with investigation

### Validation Script (`scripts/create_issue.sh`)
Robust bash script that:
- Validates authentication
- Checks title and body quality
- Creates issue via gh CLI
- Handles errors gracefully
- Returns JSON with issue details

## Features

✅ Template-driven workflow
✅ Quality validation and warnings
✅ Error handling for auth, API, config issues
✅ Auto-detects repository from git config
✅ Optional active story integration
✅ Real examples from this repository

## When to Use

**Use `/gh:create-issue` for:**
- Planned work items for sprints
- Complex bugs requiring investigation
- Feature requests with detailed requirements
- Investigation tasks
- Comprehensive test failure documentation

**Use `/create-story` for:**
- Quick issues during ad-hoc commits
- Minimal issue creation in commit workflow

## File Structure

```
gh-create-issue/
├── SKILL.md                      # Main skill workflow (357 lines)
├── README.md                     # This file
├── references/
│   ├── issue-templates.md        # All issue templates (184 lines)
│   ├── best-practices.md         # Quality guidelines (277 lines)
│   └── examples.md               # Real issue examples (264 lines)
└── scripts/
    └── create_issue.sh           # Validated creation script (286 lines)
```

## Requirements

- GitHub CLI (`gh`) installed and authenticated
- Running from a git repository with remote origin, OR
- `REPO_SLUG` environment variable set (e.g., `owner/repo`)

## Examples

### Simple Task
```
Title: Update booking notice to show fully booked until mid-March
Type: Task/Chore
```

### Complex Bug
```
Title: Fix Pa11y accessibility test failures not failing CI pipeline
Type: Bug Report
Includes: Error output, root cause analysis, detailed tasks
```

## Comparison with `/create-story`

| Feature                | `/gh:create-issue`     | `/create-story`       |
|------------------------|------------------------|-----------------------|
| **Purpose**            | Detailed planning      | Quick commits         |
| **Structure**          | Comprehensive          | Minimal (4 fields)    |
| **Validation**         | Quality checks         | Basic only            |
| **Templates**          | 5 types                | None                  |
| **Time**               | 2-3 min (interactive)  | 30 sec (fast)         |
| **Best for**           | Sprint planning        | Ad-hoc development    |

## Installation

The skill is automatically available if the directory exists in `.claude/skills/`.

For distribution, use the packaged version:
```
.claude/skills/gh-create-issue.skill
```

Extract with:
```bash
tar -xzf gh-create-issue.skill -C /path/to/skills/
```

## Testing

Test the creation script directly:
```bash
cd .claude/skills/gh-create-issue
./scripts/create_issue.sh \
  "Test issue title" \
  "Test issue body with details" \
  "bug,test" \
  "username"
```

## Exit Codes

- `0` - Success
- `1` - Validation error (missing required fields)
- `2` - Authentication error (run `gh auth login`)
- `3` - GitHub API error
- `4` - Configuration error (no repo found)

## Contributing

This skill follows the modular structure:
- Keep SKILL.md under 500 lines (currently 357)
- Move detailed content to `references/`
- Keep scripts in `scripts/`
- Use `@references/` and `@scripts/` syntax in SKILL.md

## License

Part of the aigensa/website project skills collection.
