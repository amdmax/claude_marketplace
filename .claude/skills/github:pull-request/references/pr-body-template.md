# PR Body Template

> **Reference for:** pr skill
> **Context:** Pull request description format

## Standard Template

```markdown
## Summary

{ISSUE_TITLE or commit summary}

## Related Issue

Closes #{ISSUE_NUMBER}

{ISSUE_URL}

## Changes

{List of commits with AIGCODE numbers}

## Test Plan

- [ ] {Auto-generated test items based on changed files}
- [ ] Pre-commit hooks passed
- [ ] CI/CD validation will run on PR

## Impact

{Auto-generated impact areas: infrastructure, content, lambda, docs, etc.}

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Template Variables

### {ISSUE_TITLE}
**Source:** `.claude/active-story.json` → `title` field
**Fallback:** First commit summary (AIGCODE prefix removed)

**Example:**
```
Add LSP section to course content
```

### {ISSUE_NUMBER}
**Source:** `.claude/active-story.json` → `issueNumber` field
**Fallback:** Auto-created issue number

**Example:**
```
157
```

### {ISSUE_URL}
**Source:** `.claude/active-story.json` → `url` field
**Format:** `https://github.com/{owner}/{repo}/issues/{number}`

**Example:**
```
https://github.com/aigensa/vibe-coding-course/issues/157
```

### {COMMIT_LIST}
**Source:** `git log --format='- %s' origin/master..HEAD`
**Format:** Bullet list with AIGCODE numbers

**Example:**
```markdown
- AIGCODE-157: Add LSP section to course content
- AIGCODE-157a: Add architecture diagrams
- AIGCODE-157b: Fix typos in LSP section
```

### {TEST_PLAN}
**Source:** Auto-generated from changed files
**Logic:**

| Files Changed | Test Items |
|---------------|------------|
| `infrastructure/*.ts` | `- [ ] CDK synth passes` |
| `src/*.ts` | `- [ ] Site builds successfully` |
| `content/**/*.md` | `- [ ] Content renders correctly` |
| `lambda/**/*.ts` | `- [ ] Lambda tests pass` |
| Any changes | `- [ ] Pre-commit hooks passed`<br>`- [ ] CI/CD validation will run on PR` |

**Example:**
```markdown
- [ ] Site builds successfully
- [ ] Content renders correctly
- [ ] Pre-commit hooks passed
- [ ] CI/CD validation will run on PR
```

### {IMPACT}
**Source:** Auto-generated from changed file paths
**Categories:**

| Pattern | Impact Label |
|---------|--------------|
| `infrastructure/**` | `- Infrastructure (CDK stacks)` |
| `lambda/**` | `- Lambda functions` |
| `src/**` | `- Static site builder` |
| `content/**` | `- Course content` |
| `docs/**` | `- Documentation` |

**Example:**
```markdown
- Static site builder
- Course content
```

## Customization

### Adding New Impact Categories

Edit Step 6 in SKILL.md:

```bash
# Add new pattern detection
if echo "$CHANGED_FILES" | grep -q '^tests/'; then
  IMPACT="${IMPACT}- Test suite\n"
fi
```

### Adding Custom Test Plan Items

Edit Step 6 in SKILL.md:

```bash
# Add conditional test items
if echo "$IMPACT" | grep -q 'Lambda'; then
  TEST_PLAN="${TEST_PLAN}- [ ] Lambda tests pass\n"
  TEST_PLAN="${TEST_PLAN}- [ ] Lambda deployment simulated\n"
fi
```

### Changing Template Structure

Modify the `PR_BODY` heredoc in Step 6:

```bash
PR_BODY=$(cat <<EOF
## What Changed

$COMMIT_LIST

## Why This Matters

$ISSUE_TITLE

Closes #${ISSUE_NUMBER}

## Testing

$TEST_PLAN

## Deployment Impact

$IMPACT
EOF
)
```

## Complete Example

**Input:**
- Issue: #157 "Add LSP section to course content"
- Commits:
  - `AIGCODE-157: Add LSP section to course content`
  - `AIGCODE-157a: Add architecture diagrams`
- Changed files:
  - `content/week_2/lsp.md`
  - `content/week_2/images/lsp-arch.png`

**Generated PR Body:**
```markdown
## Summary

Add LSP section to course content

## Related Issue

Closes #157

https://github.com/aigensa/vibe-coding-course/issues/157

## Changes

- AIGCODE-157: Add LSP section to course content
- AIGCODE-157a: Add architecture diagrams

## Test Plan

- [ ] Content renders correctly
- [ ] Pre-commit hooks passed
- [ ] CI/CD validation will run on PR

## Impact

- Course content

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Best Practices

1. **Keep Summary concise** - One sentence describing the PR
2. **Always link issue** - Use "Closes #..." for auto-linking
3. **List all commits** - Provides complete change history
4. **Test plan completeness** - Add manual testing notes if needed
5. **Impact clarity** - Helps reviewers understand scope

## Related

- **Main Skill:** [../SKILL.md](../SKILL.md)
- **Troubleshooting:** [troubleshooting.md](troubleshooting.md)
- **Commit Skill:** `/.claude/skills/commit/`
