---
name: claude:sync-skills
description: Push local skills to https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}} for reuse across projects. Discovers skills, syncs to remote repository, generates index, and reports results. Use when you want to share skills across projects or when user says "sync skills", "push skills to GitHub", or "share skills".
---

# Skill Sync Tool

## Overview

This skill syncs local skills from `.claude/skills/` to a central GitHub repository for reuse across projects. It:

1. **Discovers local skills** - Scans .claude/skills/ directory
2. **Selects skills to sync** - Interactive selection with filtering
3. **Syncs to GitHub** - Clones/pulls {{SKILLS_REPO_NAME}} repo, copies skills
4. **Generates index** - Creates README.md with skill catalog
5. **Commits and pushes** - Atomic commit with descriptive message
6. **Reports results** - Shows sync status and GitHub URLs

**When to use:**
- Share skills across multiple projects
- Backup skills to version control
- Collaborate on skill development
- Distribute skills to team members

## Prerequisites

- **GitHub CLI** installed and authenticated:
  ```bash
  gh auth status
  ```

- **Write access** to target repository (https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}})

- **Git** configured with user name and email:
  ```bash
  git config --global user.name
  git config --global user.email
  ```

## Workflow

### Step 1: Verify Prerequisites

**Check GitHub CLI authentication:**
```bash
gh auth status
```

**Expected output:**
```
✓ Logged in to github.com as {{SKILLS_REPO_OWNER}} (keyring)
✓ Git operations for github.com configured to use https protocol.
✓ Token: *******************
```

**If not authenticated:**
```bash
gh auth login
# Follow interactive prompts
```

**Check git configuration:**
```bash
git config user.name
git config user.email
```

**If not configured:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Step 2: Discover Local Skills

**Scan for skills:**
```bash
find .claude/skills -mindepth 1 -maxdepth 1 -type d | sort
```

**Example output:**
```
.claude/skills/add-content-image
.claude/skills/cdk-scripting
.claude/skills/commit
.claude/skills/create-adr
.claude/skills/editor-in-chief
.claude/skills/fetch-story
.claude/skills/gather-context
.claude/skills/gather-nfr
.claude/skills/lsp-diagnostics
.claude/skills/lsp-find-references
.claude/skills/lsp-goto-definition
.claude/skills/lsp-hover
.claude/skills/mermaid-diagram
.claude/skills/mr
.claude/skills/overall-review
.claude/skills/performance-review
.claude/skills/refactor-skill
.claude/skills/regenerate-course-content
.claude/skills/security-review
.claude/skills/play-story
.claude/skills/sync-skills
.claude/skills/ux-professional
.claude/skills/write-cdk
.claude/skills/write-typescript
```

**Analyze each skill:**

For each skill directory:
```bash
SKILL_NAME=$(basename $SKILL_DIR)

# Check for SKILL.md
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  # Extract description from frontmatter
  DESCRIPTION=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | grep "^description:" | sed 's/description: *//')

  # Check for config.yaml (indicates parametrization)
  HAS_CONFIG=$([ -f "$SKILL_DIR/config.yaml" ] && echo "✓" || echo "")

  # Check for references/ (indicates modular structure)
  HAS_REFS=$([ -d "$SKILL_DIR/references" ] && echo "✓" || echo "")

  # Get file count
  FILE_COUNT=$(find "$SKILL_DIR" -type f | wc -l | tr -d ' ')

  echo "$SKILL_NAME|$DESCRIPTION|$HAS_CONFIG|$HAS_REFS|$FILE_COUNT"
fi
```

**Present skills to user:**

```
Found 24 skills in .claude/skills/:

Skill Name                  | Params | Modular | Files | Description
--------------------------- | ------ | ------- | ----- | -----------
add-content-image           |        |         | 1     | Add screenshots to course materials
cdk-scripting               |        |         | 1     | AWS CDK best practices guide
commit                      |        |         | 1     | Create AIGCODE-numbered commits
create-adr                  |        |         | 1     | Generate Architecture Decision Records
fetch-story                 |        |         | 1     | Fetch next Ready story from GitHub
mr                          | ✓      | ✓       | 8     | Create theme-based pull requests
refactor-skill              |        | ✓       | 3     | Convert monolithic skills to modular structure
sync-skills                 |        |         | 1     | Push skills to {{SKILLS_REPO_NAME}} repo
...
```

### Step 3: Select Skills to Sync

**Prompt user with options:**

Use AskUserQuestion for interactive selection:

```
Which skills should I sync to {{SKILLS_REPO_NAME}} repo?

Options:
[A] All skills (24 total)
[M] Modular skills only (skills with references/ directory) - 5 skills
[P] Parametrized skills only (skills with config.yaml) - 3 skills
[C] Custom selection (choose specific skills)
[N] None (cancel sync)
```

**If Custom selection:**

Present multi-select for specific skills:
```
Select skills to sync (multiple selection):

[ ] add-content-image
[ ] cdk-scripting
[x] commit (selected)
[ ] create-adr
[ ] fetch-story
[x] mr (selected)
[x] refactor-skill (selected)
[x] sync-skills (selected)
...

Selected: 4 skills
```

**Store selection:**
```bash
# Create array of selected skills
SELECTED_SKILLS=(
  "commit"
  "mr"
  "refactor-skill"
  "sync-skills"
)
```

### Step 4: Prepare Sync Directory

**Create temporary working directory:**
```bash
SYNC_DIR=$(mktemp -d -t skill-sync-XXXXXX)
echo "Working directory: $SYNC_DIR"

cd "$SYNC_DIR"
```

**Clone {{SKILLS_REPO_NAME}} repository:**
```bash
# Clone using gh CLI (uses existing auth)
gh repo clone {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}

cd {{SKILLS_REPO_NAME}}
```

**If repository doesn't exist:**
```bash
# Create new repository
gh repo create {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}} --public --description "Shared Claude Code skills for cross-project reuse"

# Initialize with README
cat > README.md <<'EOF'
# Agent Skills Repository

Shared Claude Code skills for reuse across projects.

## Skills

See individual skill directories for documentation.
EOF

git add README.md
git commit -m "Initial commit"
git push origin main
```

**Pull latest changes:**
```bash
git pull origin main --rebase
```

### Step 5: Copy Selected Skills

**For each selected skill:**

```bash
for SKILL_NAME in "${SELECTED_SKILLS[@]}"; do
  echo "Copying $SKILL_NAME..."

  # Create skill directory in {{SKILLS_REPO_NAME}} repo
  mkdir -p "$SYNC_DIR/{{SKILLS_REPO_NAME}}/$SKILL_NAME"

  # Copy entire skill directory structure
  rsync -av --exclude='*.tmp' --exclude='.DS_Store' \
    "$PROJECT_ROOT/.claude/skills/$SKILL_NAME/" \
    "$SYNC_DIR/{{SKILLS_REPO_NAME}}/$SKILL_NAME/"

  # Verify copy
  if [ -f "$SYNC_DIR/{{SKILLS_REPO_NAME}}/$SKILL_NAME/SKILL.md" ]; then
    echo "✓ $SKILL_NAME copied successfully"
  else
    echo "✗ $SKILL_NAME copy failed - SKILL.md missing"
  fi
done
```

**Handle project-specific paths:**

Some skills may reference project-specific paths. Warn user:
```bash
# Check for project-specific path references
grep -r "vibe-coding-course\|aigensa\|\.claude\|_bmad" \
  "$SYNC_DIR/{{SKILLS_REPO_NAME}}/" | \
  grep -v "config.yaml" | \
  grep -v ".git/"

# If found, warn user
if [ $? -eq 0 ]; then
  echo "⚠️  Warning: Found project-specific references in synced skills."
  echo "    These may need adjustment for cross-project use."
  echo "    Consider using config.yaml for project-specific values."
fi
```

### Step 6: Generate README Index

**Create comprehensive index:**

```bash
cd "$SYNC_DIR/{{SKILLS_REPO_NAME}}"

cat > README.md <<'EOF'
# Agent Skills Repository

Shared Claude Code skills for reuse across projects.

## Overview

This repository contains reusable skills for Claude Code. Each skill is a self-contained package with:
- `SKILL.md` - Main skill documentation and instructions
- `config.yaml` (optional) - Parametrized project-specific settings
- `hooks.json` (optional) - Success criteria and validation hooks
- `references/` (optional) - Detailed documentation loaded as needed
- `scripts/` (optional) - Executable helper scripts
- `assets/` (optional) - Static files used by the skill

## Skills Catalog

EOF

# Generate skill table
echo "| Skill | Description | Params | Modular | Last Updated |" >> README.md
echo "|-------|-------------|--------|---------|--------------|" >> README.md

for SKILL_DIR in */; do
  SKILL_NAME=$(basename "$SKILL_DIR")

  # Skip .git directory
  [ "$SKILL_NAME" = ".git" ] && continue

  # Extract description from SKILL.md frontmatter
  if [ -f "$SKILL_DIR/SKILL.md" ]; then
    DESCRIPTION=$(sed -n '/^---$/,/^---$/p' "$SKILL_DIR/SKILL.md" | \
                  grep "^description:" | \
                  sed 's/description: *//' | \
                  sed 's/"//g' | \
                  cut -c1-80)

    # Check for config.yaml
    HAS_CONFIG=$([ -f "$SKILL_DIR/config.yaml" ] && echo "✓" || echo "")

    # Check for references/
    HAS_REFS=$([ -d "$SKILL_DIR/references" ] && echo "✓" || echo "")

    # Get last updated date
    LAST_UPDATE=$(git log -1 --format="%cd" --date=short -- "$SKILL_DIR" 2>/dev/null || date +%Y-%m-%d)

    # Add row to table
    echo "| [$SKILL_NAME]($SKILL_NAME/) | $DESCRIPTION | $HAS_CONFIG | $HAS_REFS | $LAST_UPDATE |" >> README.md
  fi
done

# Add usage instructions
cat >> README.md <<'EOF'

## Installation

### Option 1: Copy Individual Skills

```bash
# Copy a specific skill to your project
cp -r <skill-name> /path/to/your/project/.claude/skills/
```

### Option 2: Clone Entire Repository

```bash
# Clone as a git submodule (recommended for teams)
git submodule add https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}.git .claude/{{SKILLS_REPO_NAME}}

# Symlink skills you want to use
ln -s .claude/{{SKILLS_REPO_NAME}}/commit .claude/skills/commit
ln -s .claude/{{SKILLS_REPO_NAME}}/mr .claude/skills/mr
```

### Option 3: Use sync-skills Skill

```bash
# If you have the sync-skills skill installed
/sync-skills --pull <skill-name>
```

## Configuration

Many skills support parametrization via `config.yaml`. After copying a skill:

1. Check if `config.yaml` exists in the skill directory
2. Customize values for your project (repository names, branch conventions, etc.)
3. The skill will automatically load settings from config.yaml

## Contributing

To add or update skills:

1. Fork this repository
2. Add/modify skills in their respective directories
3. Ensure each skill has a valid `SKILL.md` with frontmatter
4. Run validation: `npm run validate-skills` (if available)
5. Submit a pull request

Or use the `/sync-skills` skill from your project to push changes directly.

## Skill Structure Guidelines

### Minimal Skill
```
skill-name/
└── SKILL.md          (required: frontmatter + instructions)
```

### Modular Skill
```
skill-name/
├── SKILL.md          (main documentation, <500 lines)
├── config.yaml       (optional: project-specific parameters)
├── hooks.json        (optional: success criteria validation)
└── references/       (optional: detailed docs loaded as needed)
    ├── algorithm.md
    ├── examples.md
    └── error-handling.md
```

### Complete Skill
```
skill-name/
├── SKILL.md
├── config.yaml
├── hooks.json
├── references/
│   └── *.md
├── scripts/
│   └── *.py
└── assets/
    └── *.*
```

## License

Skills in this repository are provided as-is for use with Claude Code.
Check individual skill directories for specific licenses.

## Maintenance

This repository is maintained by the aigensa development team.

**Last sync:** $(date +"%Y-%m-%d %H:%M:%S")
**Skills count:** $(find . -mindepth 1 -maxdepth 1 -type d ! -name ".git" | wc -l | tr -d ' ')

EOF
```

### Step 7: Commit and Push

**Check for changes:**
```bash
cd "$SYNC_DIR/{{SKILLS_REPO_NAME}}"

git add .
git status --short
```

**If no changes:**
```
No changes detected. All skills are already up-to-date in {{SKILLS_REPO_NAME}} repo.
```

**If changes exist:**

**Show diff summary:**
```bash
# Show what changed
git diff --cached --stat

# Show new skills
git status --short | grep "^A.*SKILL.md$"

# Show modified skills
git status --short | grep "^M.*SKILL.md$"
```

**Create descriptive commit message:**
```bash
# Generate commit message
COMMIT_MSG="Sync skills: $(echo ${SELECTED_SKILLS[@]} | tr ' ' ', ')

Updated: $(date +"%Y-%m-%d")
Source: $(basename $PROJECT_ROOT)

Changes:
$(git status --short | head -10)
"

# Commit with message
git commit -m "$COMMIT_MSG"
```

**Push to remote:**
```bash
git push origin main
```

**If push fails (authentication or permissions):**
```
Error: Push failed. Possible causes:
1. Not authenticated with gh CLI
2. No write access to {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}
3. Branch protection rules require PR

Solutions:
- Run: gh auth refresh
- Check: gh repo view {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}
- Create PR instead: gh pr create
```

### Step 8: Report Results

**Success report:**
```
✓ Skill sync completed successfully!

Synced Skills:
✓ commit      → https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}/tree/main/commit
✓ mr          → https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}/tree/main/mr
✓ refactor-skill → https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}/tree/main/refactor-skill
✓ sync-skills → https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}/tree/main/sync-skills

Repository: https://github.com/{{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}
Commit: abc1234
README updated with 24 skills

To use these skills in another project:
1. Clone: gh repo clone {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}
2. Copy: cp -r {{SKILLS_REPO_NAME}}/<skill-name> .claude/skills/
3. Configure: Edit config.yaml if present

Temp directory retained at: $SYNC_DIR
(Will be cleaned up on next sync or manually: rm -rf $SYNC_DIR)
```

**Failure report:**
```
✗ Skill sync failed

Error: [specific error message]

Attempted to sync:
- commit
- mr
- refactor-skill
- sync-skills

Troubleshooting:
1. Verify GitHub CLI auth: gh auth status
2. Check repository access: gh repo view {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}
3. Review git config: git config --list
4. Check network connection

Temp directory retained for debugging: $SYNC_DIR
Review logs: cat $SYNC_DIR/sync.log
```

### Step 9: Cleanup (Optional)

**Ask user:**
```
Sync complete. Clean up temporary directory?

[Y] Yes, delete $SYNC_DIR
[N] No, keep for review

Keeping the directory allows you to:
- Review exactly what was synced
- Make manual adjustments
- Debug any issues
```

**If yes:**
```bash
rm -rf "$SYNC_DIR"
echo "✓ Temporary directory cleaned up"
```

## Pull Mode: Sync Skills FROM Repository

**Usage:**
```bash
/sync-skills --pull <skill-name>
```

**Workflow:**

1. **Clone {{SKILLS_REPO_NAME}} repo:**
```bash
SYNC_DIR=$(mktemp -d)
cd "$SYNC_DIR"
gh repo clone {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}
```

2. **Check if skill exists:**
```bash
if [ ! -d "{{SKILLS_REPO_NAME}}/$SKILL_NAME" ]; then
  echo "✗ Skill '$SKILL_NAME' not found in {{SKILLS_REPO_NAME}} repo"
  echo "Available skills:"
  ls -1 {{SKILLS_REPO_NAME}}/
  exit 1
fi
```

3. **Copy to local .claude/skills/:**
```bash
rsync -av "{{SKILLS_REPO_NAME}}/$SKILL_NAME/" ".claude/skills/$SKILL_NAME/"
```

4. **Check for config.yaml:**
```bash
if [ -f ".claude/skills/$SKILL_NAME/config.yaml" ]; then
  echo "⚠️  This skill uses config.yaml for project-specific settings."
  echo "   Please review and customize:"
  echo "   .claude/skills/$SKILL_NAME/config.yaml"
fi
```

5. **Report:**
```
✓ Skill '$SKILL_NAME' installed successfully

Location: .claude/skills/$SKILL_NAME/
Files copied: $(find .claude/skills/$SKILL_NAME -type f | wc -l)

Next steps:
1. Review SKILL.md: cat .claude/skills/$SKILL_NAME/SKILL.md
2. Configure (if needed): vim .claude/skills/$SKILL_NAME/config.yaml
3. Test: /$SKILL_NAME
```

## Configuration

### sync-skills Config

Create `.claude/skills/sync-skills/config.yaml` to customize:

```yaml
# Sync configuration
repository:
  owner: {{SKILLS_REPO_OWNER}}
  name: {{SKILLS_REPO_NAME}}
  branch: main

# Sync behavior
sync:
  include_backups: false      # Don't sync *.backup files
  include_temp: false          # Don't sync *.tmp files
  dry_run: false               # Set true to preview without pushing

# Filters
filters:
  exclude_patterns:
    - "*.backup.*"
    - "*.tmp"
    - ".DS_Store"
    - "node_modules/"

  min_file_size: 0             # Minimum file size to sync (bytes)
  max_file_size: 10485760      # Maximum file size to sync (10MB)

# Commit messages
commit:
  prefix: "Sync skills:"       # Commit message prefix
  include_source: true         # Include source project in commit
  include_timestamp: true      # Include timestamp in commit
```

## Error Handling

### Error: "gh: command not found"
**Solution:** Install GitHub CLI
```bash
# macOS
brew install gh

# Linux
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

### Error: "Authentication required"
**Solution:** Authenticate with GitHub CLI
```bash
gh auth login
# Follow interactive prompts
# Choose: HTTPS, Login with web browser
```

### Error: "Permission denied (publickey)"
**Solution:** Check SSH keys or switch to HTTPS
```bash
# Configure git to use HTTPS instead of SSH
gh config set git_protocol https

# Or add SSH key
ssh-keygen -t ed25519 -C "your@email.com"
gh ssh-key add ~/.ssh/id_ed25519.pub
```

### Error: "Repository not found"
**Solution:** Verify repository exists and you have access
```bash
# Check repository
gh repo view {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}

# If doesn't exist, create it
gh repo create {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}} --public

# Check your access
gh repo list {{SKILLS_REPO_OWNER}}
```

### Error: "Merge conflict"
**Solution:** Pull latest changes and retry
```bash
cd "$SYNC_DIR/{{SKILLS_REPO_NAME}}"
git pull origin main --rebase
# Resolve conflicts if any
git push origin main
```

## Advanced Usage

### Sync Specific Files Only

```bash
# Sync only SKILL.md files (no references, scripts, etc.)
rsync -av --include="*/" --include="SKILL.md" --exclude="*" \
  .claude/skills/ {{SKILLS_REPO_NAME}}/
```

### Sync to Different Repository

```bash
# Override repository in command
REPO_OWNER=myorg REPO_NAME=my-skills /sync-skills
```

### Dry Run (Preview Changes)

```bash
# Show what would be synced without pushing
cd {{SKILLS_REPO_NAME}}
git add .
git diff --cached --stat
git status --short

# Don't commit or push
```

### Batch Sync Multiple Projects

```bash
# From a script
for PROJECT in project1 project2 project3; do
  cd "$PROJECT"
  /sync-skills --auto --skills=all
done
```

## Best Practices

1. **Sync regularly** - Keep {{SKILLS_REPO_NAME}} repo up-to-date with improvements
2. **Use config.yaml** - Parametrize project-specific values before syncing
3. **Test before syncing** - Ensure skills work in current project
4. **Review README** - Check generated index before pushing
5. **Clean up temp dirs** - Remove temp directories after successful sync
6. **Version control** - Use git tags for skill versions if needed

## Security Considerations

- **Sensitive data:** Never sync skills containing API keys, passwords, or credentials
- **Project-specific paths:** Use config.yaml to parametrize local paths
- **Private repositories:** Ensure {{SKILLS_REPO_NAME}} repo is private if syncing proprietary skills
- **Access control:** Verify who has write access to {{SKILLS_REPO_NAME}} repository

## Troubleshooting Checklist

- [ ] GitHub CLI installed: `gh --version`
- [ ] GitHub CLI authenticated: `gh auth status`
- [ ] Git configured: `git config --list`
- [ ] Repository exists: `gh repo view {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}}`
- [ ] Write access: `gh repo view {{SKILLS_REPO_OWNER}}/{{SKILLS_REPO_NAME}} --json permissions`
- [ ] Network connectivity: `ping github.com`
- [ ] Disk space: `df -h`
- [ ] SKILL.md files valid: Check frontmatter YAML syntax

