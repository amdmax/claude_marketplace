# Feature Flags

## `numbering.mode`

**Default:** `"issue-based"`

**Description:** Determines how commit numbers are assigned.

**Options:**
- `"issue-based"` - Use GitHub issue numbers from active story
- `"sequential"` - Use auto-incrementing counter

**When to use issue-based:**
- Direct traceability to GitHub issues
- Working on specific issues/stories
- Integrates with `/fetch-story` and `/play-story` workflows

**When to use sequential:**
- No GitHub issue integration needed
- Simpler, faster workflow
- Fallback when issue creation fails

**Example:**
```yaml
numbering:
  mode: "issue-based"  # or "sequential"
  prefix: MYAPP
```

## `issue.create_if_missing`

**Default:** `true`

**Description:** Auto-create GitHub issue if no active story exists (issue-based mode only).

**When to enable:**
- Want automated issue creation
- Prefer every commit tied to an issue
- Trust Claude to create good issues

**When to disable:**
- Manual issue creation preferred
- Want to fail fast if no active story
- Use sequential mode as fallback

**Example:**
```yaml
numbering:
  mode: "issue-based"
  issue:
    create_if_missing: true
```

## `grouping.enabled`

**Default:** `true`

**Description:** Detect related commits and suggest grouping with suffixes (a, b, c).

**When to enable:**
- Make multiple related commits
- Want clear progression (157, 157a, 157b)
- Appreciate intelligent suggestions

**When to disable:**
- Prefer independent commits always
- Don't want grouping prompts
- Simpler commit history

**Example:**
```yaml
grouping:
  enabled: true
  time_window: "4 hours ago"
  confidence_threshold: 60
```

## `validation.enabled`

**Default:** `true`

**Description:** Enable post-commit validation hook to ensure format compliance.

**When to enable:**
- Enforce commit message standards
- Catch format errors immediately
- Team standardization

**When to disable:**
- Testing/development
- Non-standard commit needs
- Hook conflicts

**Example:**
```yaml
validation:
  enabled: true
  skip_merge_commits: true
```
