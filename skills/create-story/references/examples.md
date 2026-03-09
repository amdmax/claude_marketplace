# Examples

> **Reference for:** create-story skill
> **Context:** Usage patterns and workflows

## Example 1: Create Issue During Commit

**Scenario**: No active story exists, user wants to commit changes

```bash
# User stages changes
git add lambda/auth.ts

# User tries to commit
/gh:commit

# Commit skill detects no active story
# → 📋 No active story. Creating one...

# /create-story is invoked automatically
# → Analyzing staged changes...
# → Suggested title: Fix token expiration check in auth lambda
# → Enter issue title (or press Enter to accept): [user presses Enter]
# → Creating GitHub issue...
# → ✓ Issue #158 created: https://github.com/aigensa/vibe-coding-course/issues/158
# → ✓ Active story saved

# Commit continues with issue number
# → AIGCODE-158: Fix token expiration check in auth lambda
```

**Result**:
- GitHub issue #158 created
- `.agile-dev-team/active-story.json` contains minimal data (4 fields)
- Commit uses `AIGCODE-158:` format

---

## Example 2: Manual Issue Creation

**Scenario**: User wants to create an issue before starting work

```bash
# User invokes skill directly
/create-story

# → Enter issue title: Add Chart.js integration for course analytics
# → Creating GitHub issue...
# → ✓ Created issue #159: Add Chart.js integration for course analytics
# → ✓ Active story saved: .agile-dev-team/active-story.json

# User can now work on this story
git add src/chart-integration.ts
/gh:commit
# → ✓ Using issue #159: Add Chart.js integration for course analytics
# → AIGCODE-159: Add Chart.js wrapper with theme support
```

---

## Example 3: Auto-Generated Issue Body

**Scenario**: Skill generates description from staged changes

```bash
# User stages multiple related files
git add content/week_3/charts.md src/chart-helper.ts

# User invokes skill
/create-story
# → Analyzing staged changes...
# → Found 2 files: content/week_3/charts.md, src/chart-helper.ts
# → Suggested title: Add chart documentation and helper utilities
# → Enter issue title (or press Enter to accept): [user accepts]

# Skill analyzes git diff
# → Detected changes:
#   - Added new markdown content (charts.md)
#   - Added TypeScript helper module (chart-helper.ts)
#
# → Generated body:
#   Added Chart.js documentation to week 3 course content and created
#   helper utilities for chart initialization and theme integration.

# → Creating GitHub issue...
# → ✓ Created issue #160
```

**Active story JSON**:
```json
{
  "issueNumber": 160,
  "title": "Add chart documentation and helper utilities",
  "body": "Added Chart.js documentation to week 3 course content and created helper utilities for chart initialization and theme integration.",
  "url": "https://github.com/aigensa/vibe-coding-course/issues/160"
}
```

---

## Example 4: Error - No Authentication

**Scenario**: GitHub CLI not authenticated

```bash
# User invokes skill
/create-story

# → ❌ GitHub CLI not authenticated
# →
# → To create GitHub issues, authenticate with:
# →   gh auth login
# →
# → After authentication, try again:
# →   /create-story

# User authenticates
gh auth login
# → ✓ Logged in as user123

# Try again
/create-story
# → Enter issue title: Fix build script
# → Creating GitHub issue...
# → ✓ Created issue #161: Fix build script
```

---

## Example 5: Integration with Fetch Story

**Scenario**: Switch between ad-hoc and planned work

```bash
# User creates ad-hoc issue for quick fix
/create-story
# → Enter issue title: Fix typo in week 1
# → ✓ Created issue #162

# Work on quick fix
git add content/week_1/intro.md
/gh:commit
# → AIGCODE-162: Fix typo in introduction section

# Switch to planned work
/fetch-story
# → Fetching next Ready story from GitHub Projects...
# → ✓ Found story #157: Add LSP section to course content
# → ✓ Active story updated
# → ✓ GitHub status → In Progress

# Work on planned story
git add content/week_2/lsp.md
/gh:commit
# → ✓ Using issue #157: Add LSP section to course content
# → AIGCODE-157: Add LSP architecture overview
```

**Key difference**:
- `/create-story`: Creates **new** issue, minimal data
- `/fetch-story`: Fetches **existing** issue from Projects, full data + status update

---

## Example 6: Commit Workflow Fallback

**Scenario**: Issue creation fails, commit uses sequential numbering

```bash
# Network is down
/gh:commit

# → 📋 No active story. Creating one...
# → Enter issue title: Add tests
# → Creating GitHub issue...
# → ❌ Failed to create GitHub issue
# → Error: Could not resolve host: api.github.com
# →
# → ⚠️  Issue creation failed. Using sequential numbering...
# → AIGCODE-124: Add tests for authentication module

# Commit succeeds with sequential number
git log -1 --pretty=%s
# → AIGCODE-124: Add tests for authentication module
```

**Later** (network restored):
```bash
# User can create issue retroactively
/create-story --title "Add tests for authentication module"
# → ✓ Created issue #163
# → Note: Link commit AIGCODE-124 in PR description
```
