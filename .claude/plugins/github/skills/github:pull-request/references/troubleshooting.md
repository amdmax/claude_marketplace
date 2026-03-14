# Troubleshooting Guide

> **Reference for:** pr skill
> **Context:** Common issues and solutions

## No Commits Ahead of Master

### Symptom
```
❌ No commits to create PR for
Branch is up to date with master.
```

### Causes
1. Branch just created without changes
2. All commits already merged to master
3. Working on master branch directly
4. Remote master ahead of local branch

### Solutions

**Solution 1: Verify you're on a feature branch**
```bash
# Check current branch
git branch --show-current

# If on master, create feature branch
git checkout -b feature/my-work
```

**Solution 2: Ensure you have commits**
```bash
# Check commit history
git log --oneline origin/master..HEAD

# If empty, make changes and commit
git add .
/commit
```

**Solution 3: Update remote references**
```bash
# Fetch latest from origin
git fetch origin

# Check commits again
git log --oneline origin/master..HEAD
```

**Solution 4: Verify remote tracking**
```bash
# Check remote branches
git remote -v

# Ensure origin/master exists
git branch -r | grep origin/master
```

---

## GitHub Authentication Failed

### Symptom
```
❌ Failed to create pull request
gh: authentication required
```

### Causes
1. GitHub CLI not authenticated
2. Authentication token expired
3. Insufficient permissions

### Solutions

**Solution 1: Authenticate with GitHub CLI**
```bash
# Login to GitHub
gh auth login

# Follow prompts:
# - Choose GitHub.com
# - Select HTTPS or SSH
# - Authenticate via browser or token
# - Grant necessary permissions
```

**Solution 2: Verify authentication**
```bash
# Check current auth status
gh auth status

# Should show:
# ✓ Logged in to github.com as <username>
```

**Solution 3: Refresh token**
```bash
# Logout and login again
gh auth logout
gh auth login
```

**Solution 4: Check repository permissions**
```bash
# Verify you have write access
gh repo view

# Check your role in the repository
```

---

## /commit Invoked but Changes Not Committed

### Symptom
PR creation stops after invoking `/commit` but no commit appears in git history.

### Causes
1. Pre-commit hooks failed
2. Commit message validation failed
3. `/commit` skill encountered error
4. Merge conflict during commit

### Solutions

**Solution 1: Check git status**
```bash
# Verify current status
git status

# Check if files are staged
git diff --cached --name-only
```

**Solution 2: Manually run /commit to see error**
```bash
# Run commit skill directly
/commit

# Read error message carefully
# Common errors:
# - "AIGCODE format invalid"
# - "Pre-commit hook failed"
# - "No staged changes"
```

**Solution 3: Check pre-commit hooks**
```bash
# View hook output
cat .git/hooks/pre-commit

# Check if hooks are executable
ls -la .git/hooks/

# Temporarily bypass hooks if needed
git commit --no-verify -m "AIGCODE-123: Fix"
```

**Solution 4: Review commit history**
```bash
# Check last commit
git log -1

# If commit exists, continue
/pr
```

**Solution 5: Check for merge conflicts**
```bash
# Look for conflict markers
git status | grep "both modified"

# Resolve conflicts
git add <resolved-files>
/commit
```

---

## PR Created but Story Link Missing

### Symptom
PR created successfully but "Closes #..." link is missing or shows wrong issue number.

### Causes
1. `.claude/active-story.json` is malformed
2. Issue creation failed silently
3. GitHub API returned unexpected format
4. Issue number extraction regex failed

### Solutions

**Solution 1: Verify active-story.json**
```bash
# Check file exists and is valid JSON
cat .claude/active-story.json | jq

# Expected format:
# {
#   "issueNumber": 157,
#   "title": "...",
#   "url": "https://github.com/.../issues/157"
# }
```

**Solution 2: Fetch or create story**
```bash
# Fetch existing story from GitHub Projects
/fetch-story

# Or create new issue
/create-story --title "My work"

# Verify active-story.json updated
cat .claude/active-story.json | jq '.issueNumber'
```

**Solution 3: Manually update PR description**
```bash
# Get current PR number
gh pr list --head $(git branch --show-current)

# Edit PR body
gh pr edit <PR_NUMBER> --body "$(cat <<EOF
## Summary

My changes

## Related Issue

Closes #<ISSUE_NUMBER>

https://github.com/aigensa/vibe-coding-course/issues/<ISSUE_NUMBER>
EOF
)"
```

**Solution 4: Check GitHub issue exists**
```bash
# List recent issues
gh issue list --limit 10

# Verify issue number exists
gh issue view <ISSUE_NUMBER>
```

---

## Branch Already Exists

### Symptom
```
fatal: A branch named 'fix/aigcode-157-1738675200' already exists.
```

### Causes
1. Previous PR creation partially failed
2. Branch name collision (rare due to timestamp)
3. Local branch not deleted after PR merge

### Solutions

**Solution 1: Delete local branch**
```bash
# Force delete the branch
git branch -D fix/aigcode-157-1738675200

# Retry PR creation
/pr
```

**Solution 2: Delete remote branch if exists**
```bash
# Check if branch exists on remote
git ls-remote --heads origin fix/aigcode-157-1738675200

# Delete from remote
git push origin --delete fix/aigcode-157-1738675200

# Delete local
git branch -D fix/aigcode-157-1738675200

# Retry
/pr
```

**Solution 3: Use different branch name**
```bash
# Manually create branch with custom name
git checkout -b feature/my-fix

# Create PR
/pr
```

**Solution 4: Clean up old branches**
```bash
# List merged branches
git branch --merged master

# Delete all merged feature branches
git branch --merged master | grep -v "master" | xargs -n 1 git branch -d
```

---

## Wrong Base Branch

### Symptom
PR created against wrong branch (not master).

### Causes
1. Local git config has different default branch
2. Repository uses `main` instead of `master`
3. Previous PR targeted different base

### Solutions

**Solution 1: Check repository default branch**
```bash
# Get remote HEAD branch
git remote show origin | grep "HEAD branch"

# Common outputs:
# - HEAD branch: master
# - HEAD branch: main
```

**Solution 2: Update skill to use correct base**

Edit `.claude/skills/pr/SKILL.md`, find Step 7:

```bash
# Change from:
gh pr create --base master

# To:
gh pr create --base main
```

Also update all references to `origin/master`:

```bash
# Change all occurrences:
# origin/master → origin/main
# master → main
```

**Solution 3: Manually specify base when creating**
```bash
# Close incorrect PR
gh pr close <PR_NUMBER>

# Create PR with correct base
gh pr create --base main
```

**Solution 4: Change PR base after creation**
```bash
# Edit PR to target different base
gh pr edit <PR_NUMBER> --base main
```

---

## Test Plan Items Not Relevant

### Symptom
PR body includes test checklist items that don't apply to changes.

### Causes
1. Auto-generated test plan too broad
2. File changes in multiple areas trigger irrelevant tests
3. Documentation-only changes include code test items

### Solutions

**Solution 1: Edit PR description manually**
```bash
# Edit PR interactively
gh pr edit <PR_NUMBER>

# Or update body directly
gh pr edit <PR_NUMBER> --body "$(cat <<EOF
## Test Plan

- [ ] Verify documentation renders
- [ ] Check internal links
- [ ] Pre-commit hooks passed
EOF
)"
```

**Solution 2: Customize template for specific changes**

Edit `.claude/skills/pr/references/pr-body-template.md`:

```markdown
## Test Plan

{CUSTOM_TESTS}

{AUTO_GENERATED_TESTS}
```

Then modify Step 6 in SKILL.md to add custom logic:

```bash
# Docs-only changes
if echo "$CHANGED_FILES" | grep -qv -E '\.md$|^docs/'; then
  TEST_PLAN="- [ ] Documentation renders correctly\n"
else
  # Use auto-generated plan
fi
```

**Solution 3: Create PR with custom body**

Skip `/pr` skill and use `gh` directly:

```bash
# Write custom body
cat > pr-body.md <<EOF
## Summary

Documentation updates

## Changes

- Updated troubleshooting guide
- Fixed typos

## Test Plan

- [ ] All links work
- [ ] Markdown renders correctly
EOF

# Create PR with custom body
gh pr create --title "Update docs" --body "$(cat pr-body.md)"
```

---

## Impact Section Inaccurate

### Symptom
PR body shows impact areas that don't match actual changes.

### Causes
1. Pattern matching too broad
2. Test files trigger production impact
3. Renamed/moved files show up incorrectly

### Solutions

**Solution 1: Edit PR description**
```bash
# Update impact section
gh pr edit <PR_NUMBER> --body "$(cat <<EOF
## Impact

- Documentation only
- No production changes
EOF
)"
```

**Solution 2: Refine pattern matching**

Edit Step 6 in `.claude/skills/pr/SKILL.md`:

```bash
# More specific patterns
if echo "$CHANGED_FILES" | grep -q '^infrastructure/.*\.ts$' && \
   echo "$CHANGED_FILES" | grep -qv '\.test\.ts$'; then
  IMPACT="${IMPACT}- Infrastructure (CDK stacks)\n"
fi

# Exclude test files
if echo "$CHANGED_FILES" | grep -q '^src/.*\.ts$' && \
   echo "$CHANGED_FILES" | grep -qv '\.test\.ts$'; then
  IMPACT="${IMPACT}- Static site builder\n"
fi
```

**Solution 3: Add impact exclusions**

```bash
# Exclude patterns
EXCLUDE_PATTERNS="\.test\.ts$|\.spec\.ts$|__tests__/"

FILTERED_FILES=$(echo "$CHANGED_FILES" | grep -Ev "$EXCLUDE_PATTERNS")

# Run impact detection on filtered files
if echo "$FILTERED_FILES" | grep -q '^infrastructure/'; then
  IMPACT="${IMPACT}- Infrastructure (CDK stacks)\n"
fi
```

---

## Uncommitted Changes Not Detected

### Symptom
`/pr` proceeds without committing changes, but `git status` shows uncommitted files.

### Causes
1. Files not staged (`git add` not run)
2. Gitignored files present
3. `/commit` skill silently failed

### Solutions

**Solution 1: Stage files explicitly**
```bash
# Stage all changes
git add .

# Or stage specific files
git add file1.ts file2.ts

# Verify staged
git status

# Retry
/pr
```

**Solution 2: Check gitignore**
```bash
# Check if files are ignored
git status --ignored

# If important files ignored, update .gitignore
```

**Solution 3: Manually commit before /pr**
```bash
# Commit changes first
/commit

# Verify commit exists
git log -1

# Then create PR
/pr
```

---

## PR Creation Timeout

### Symptom
`/pr` hangs or times out during `gh pr create`.

### Causes
1. Network issues
2. Large PR body (rare)
3. GitHub API rate limiting

### Solutions

**Solution 1: Check network connection**
```bash
# Test GitHub connectivity
gh api user

# Should return your user info
```

**Solution 2: Retry with smaller body**
```bash
# Create PR with minimal body
gh pr create --title "Quick fix" --body "See commits"

# Add details later
gh pr edit <PR_NUMBER> --body "$(cat detailed-body.md)"
```

**Solution 3: Check rate limits**
```bash
# Check GitHub API rate limit
gh api rate_limit

# Wait if exceeded, or use different auth token
```

**Solution 4: Create PR via web UI**
```bash
# Push branch
git push -u origin $(git branch --show-current)

# Open browser to create PR
gh browse
```

---

## Multiple PRs Created

### Symptom
Running `/pr` multiple times creates duplicate PRs.

### Causes
1. PR detection logic failed
2. Branch name changed between runs
3. GitHub API delay

### Solutions

**Solution 1: Close duplicate PRs**
```bash
# List all PRs
gh pr list

# Close duplicates
gh pr close <PR_NUMBER> --comment "Duplicate PR"
```

**Solution 2: Verify detection logic**
```bash
# Check for existing PRs manually
CURRENT_BRANCH=$(git branch --show-current)
gh pr list --head "$CURRENT_BRANCH"

# Should return existing PR if any
```

**Solution 3: Add rate limiting**

Wait between `/pr` invocations:
```bash
/pr
# Wait 5 seconds before retrying
```

---

## Related Resources

- **Main Skill:** [../SKILL.md](../SKILL.md)
- **PR Body Template:** [pr-body-template.md](pr-body-template.md)
- **Commit Skill:** `/.claude/skills/commit/`
- **GitHub CLI Docs:** https://cli.github.com/manual/
