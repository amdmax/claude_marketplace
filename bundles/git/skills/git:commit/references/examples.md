# Examples

## Example 1: First-Time Setup

**Scenario:** Setting up commit skill in a new project.

**Configuration:**
```yaml
# config.yaml
numbering:
  mode: "issue-based"
  prefix: ACME
  issue:
    source: ".agile-dev-team/active-story.yaml"
    create_if_missing: true

repository:
  slug: "acme/web-app"

grouping:
  enabled: true

validation:
  enabled: true
```

**Usage:**
```bash
# Make changes
echo "console.log('hello')" > index.js
git add index.js

# First commit - no active story
/commit

# Skill response:
# "📋 No active story. Creating one..."
# [User describes issue: "Add initial application structure"]
# "✓ Created issue #1"
# "Creating commit: ACME-1: Add initial application structure"
```

**Result:**
- GitHub issue #1 created
- Commit: `ACME-1: Add initial application structure`
- `.agile-dev-team/active-story.yaml` created

## Example 2: Grouped Commits

**Scenario:** Making multiple related commits on same feature.

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: WEBAPP
grouping:
  enabled: true
  time_window: "4 hours ago"
  confidence_threshold: 60
```

**Usage:**
```bash
# First commit
git add auth.ts
/commit
# → WEBAPP-42: Add authentication service

# 30 minutes later, continue on same feature
git add auth.ts auth.test.ts
/commit

# Skill detects HIGH confidence:
# "Detected recent commit on same files:
#  WEBAPP-42: Add authentication service (30 minutes ago)
#  File overlap: 100% (1/1 files)
#
#  [1] WEBAPP-42a (grouped) - RECOMMENDED (HIGH confidence)
#  [2] WEBAPP-42 (new independent commit)"

# User selects [1]
# → WEBAPP-42a: Add authentication tests and validation
```

## Example 3: Sequential Fallback

**Scenario:** Issue creation fails (network down, auth issues).

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: APP
  issue:
    create_if_missing: true

numbering:
  sequential:
    digits: 3
    format: "%s-%03d"
```

**Usage:**
```bash
git add feature.ts
/commit

# Skill tries to create issue, fails:
# "⚠️ Issue creation failed (network error)"
# "Using sequential numbering as fallback..."
# "Found highest commit: APP-024"
# "Creating commit: APP-025: Add new feature"
```

**Result:**
- Graceful fallback to sequential mode
- Commit still created: `APP-025: Add new feature`
- Work continues despite network issues
