# Error Handling

> **Reference for:** create-story skill
> **Context:** Graceful degradation and user guidance

## Error Scenarios

### 1. GitHub CLI Not Authenticated

**Detection**:
```bash
gh auth status &>/dev/null
if [ $? -ne 0 ]; then
  # Not authenticated
fi
```

**Response** (config: `errors.no_auth: "prompt"`):
```
❌ GitHub CLI not authenticated

To create GitHub issues, authenticate with:
  gh auth login

After authentication, try again:
  /create-story
```

**Alternative Response** (config: `errors.no_auth: "fail"`):
```
❌ GitHub CLI not authenticated. Run: gh auth login
```

---

### 2. Network/API Failure

**Detection**:
```bash
ISSUE_JSON=$(gh issue create ... 2>&1)
if [ $? -ne 0 ]; then
  # API call failed
fi
```

**Response** (config: `errors.network_failure: "fail"`):
```
❌ Failed to create GitHub issue

Error details:
  $ISSUE_JSON

Possible causes:
  - Network connectivity issue
  - GitHub API rate limit exceeded
  - Repository permissions issue

The commit skill will fall back to sequential numbering.
```

---

### 3. Empty Issue Title

**Detection**:
```bash
if [ -z "$ISSUE_TITLE" ]; then
  # User provided empty title
fi
```

**Response**:
```
❌ Issue title cannot be empty

Please provide a descriptive title for the GitHub issue.
This will be visible in commit messages.
```

**Prompt again** with better suggestion from staged changes.

---

### 4. Invalid Repository Configuration

**Detection**:
```bash
REPO_SLUG=$(yq e '.repository.slug' config.yaml)
if [ -z "$REPO_SLUG" ] || [ "$REPO_SLUG" = "null" ]; then
  # Missing repository configuration
fi
```

**Response**:
```
❌ Repository not configured

Edit .claude/skills/create-story/config.yaml:

repository:
  slug: "owner/repo-name"
```

---

### 5. Active Story File Write Failure

**Detection**:
```bash
cat > .agile-dev-team/active-story.json <<EOF
...
EOF

if [ $? -ne 0 ]; then
  # File write failed
fi
```

**Response**:
```
❌ Failed to save active story

Created GitHub issue #${ISSUE_NUMBER}:
  ${ISSUE_URL}

But could not write .agile-dev-team/active-story.json

Check directory permissions and try:
  mkdir -p .claude
```

**Recovery**: Issue exists in GitHub, user can manually create file or re-run skill.

---

## Exit Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 0 | Success | Issue created, story file written |
| 1 | Configuration error | Missing config, invalid settings |
| 2 | Authentication error | GitHub CLI not authenticated |
| 3 | API error | GitHub API call failed |
| 4 | User cancellation | User aborted during prompts |

## Graceful Degradation

When `/create-story` fails, the `/commit` skill should:

1. **Catch exit code**: Check if skill exited non-zero
2. **Show error**: Display `/create-story` error message
3. **Fall back**: Use sequential AIGCODE numbering
4. **Continue**: Don't block commit workflow

```bash
# In /commit skill
if ! /create-story; then
  echo "⚠️  Issue creation failed. Using sequential numbering..."
  # Fall back to AIGCODE-### logic
fi
```
