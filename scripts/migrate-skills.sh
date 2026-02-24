#!/bin/bash
set -euo pipefail

# Migration script: creates one PR per skill
# Uses git worktrees for clean isolation

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKTREE_BASE="/tmp/skill-migration"
LOG_FILE="$REPO_ROOT/scripts/migration-log.txt"

mkdir -p "$WORKTREE_BASE"
> "$LOG_FILE"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }

# Mapping: "old_dir|new_dir|branch_suffix|pr_title"
SKILLS=(
  "_templates|_templates|templates|Migrate _templates to .claude/skills/"
  "add-content-image|add-content-image|add-content-image|Migrate add-content-image to .claude/skills/"
  "fitness-function-architect|arch:fitness-function|arch-fitness-function|Migrate fitness-function-architect to arch:fitness-function"
  "aws-architect|aws:architect|aws-architect|Migrate aws-architect to aws:architect"
  "cdk-scripting|aws:cdk|aws-cdk|Migrate cdk-scripting to aws:cdk"
  "bug-fix|bug-fix|bug-fix|Migrate bug-fix to .claude/skills/"
  "hooks|claude:hooks|claude-hooks|Migrate hooks to claude:hooks"
  "refactor-skill|claude:refactor-skill|claude-refactor-skill|Migrate refactor-skill to claude:refactor-skill"
  "skill-creator|claude:skill-creator|claude-skill-creator|Migrate skill-creator to claude:skill-creator"
  "sync-skills|claude:sync-skills|claude-sync-skills|Migrate sync-skills to claude:sync-skills"
  "claude:validate-skills|claude:validate-skills|claude-validate-skills|Migrate claude:validate-skills to .claude/skills/"
  "create-adr|create-adr|create-adr|Migrate create-adr to .claude/skills/"
  "creative-writing|creative-writing|creative-writing|Migrate creative-writing to .claude/skills/"
  "css-architecture|css-architecture|css-architecture|Migrate css-architecture to .claude/skills/"
  "cuda-remote-manager|cuda-remote-manager|cuda-remote-manager|Migrate cuda-remote-manager to .claude/skills/"
  "editor-in-chief|editor-in-chief|editor-in-chief|Migrate editor-in-chief to .claude/skills/"
  "gather-context|gather-context|gather-context|Migrate gather-context to .claude/skills/"
  "gather-nfr|gather-nfr|gather-nfr|Migrate gather-nfr to .claude/skills/"
  "commit|git:commit|git-commit|Migrate commit to git:commit"
  "gh-actions|github:actions|github-actions|Migrate gh-actions to github:actions"
  "gh-create-issue|github:create-issue|github-create-issue|Migrate gh-create-issue to github:create-issue"
  "pr|github:pull-request|github-pull-request|Migrate pr to github:pull-request"
  "github-runner-setup,gh:runner-setup|github:runner-setup|github-runner-setup|Consolidate runner-setup into github:runner-setup"
  "create-story|github:story-create|github-story-create|Migrate create-story to github:story-create"
  "fetch-story|github:story-fetch|github-story-fetch|Migrate fetch-story to github:story-fetch"
  "play-story|github:story-play|github-story-play|Migrate play-story to github:story-play"
  "check-story-quality|github:story-quality|github-story-quality|Migrate check-story-quality to github:story-quality"
  "mermaid-diagram|mermaid-diagram|mermaid-diagram|Migrate mermaid-diagram to .claude/skills/"
  "regenerate-course-content|regenerate-course-content|regenerate-course-content|Migrate regenerate-course-content to .claude/skills/"
  "overall-review|review:overall|review-overall|Migrate overall-review to review:overall"
  "performance-review|review:performance|review-performance|Migrate performance-review to review:performance"
  "security-review|review:security|review-security|Migrate security-review to review:security"
  "agile-dev-team|team:agile-dev|team-agile-dev|Migrate agile-dev-team to team:agile-dev"
  "ux-professional|ux-professional|ux-professional|Migrate ux-professional to .claude/skills/"
)

CREATED=0
FAILED=0

for entry in "${SKILLS[@]}"; do
  IFS='|' read -r old_dirs new_dir branch_suffix pr_title <<< "$entry"
  branch="migrate/$branch_suffix"
  worktree="$WORKTREE_BASE/$branch_suffix"

  log "--- Processing: $new_dir (branch: $branch)"

  # Clean up any leftover worktree
  if [ -d "$worktree" ]; then
    git -C "$REPO_ROOT" worktree remove "$worktree" --force 2>/dev/null || rm -rf "$worktree"
  fi
  git -C "$REPO_ROOT" branch -D "$branch" 2>/dev/null || true

  # Create worktree
  if ! git -C "$REPO_ROOT" worktree add "$worktree" -b "$branch" main 2>&1; then
    log "FAIL: Could not create worktree for $branch"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Create target directory in worktree
  mkdir -p "$worktree/.claude/skills/"

  # Copy new skill files from main repo working tree
  if [ -d "$REPO_ROOT/.claude/skills/$new_dir" ]; then
    cp -r "$REPO_ROOT/.claude/skills/$new_dir" "$worktree/.claude/skills/$new_dir"
  else
    log "FAIL: Source .claude/skills/$new_dir not found"
    git -C "$REPO_ROOT" worktree remove "$worktree" --force 2>/dev/null || true
    git -C "$REPO_ROOT" branch -D "$branch" 2>/dev/null || true
    FAILED=$((FAILED + 1))
    continue
  fi

  # Delete old skill directories in worktree
  IFS=',' read -ra OLD_DIRS <<< "$old_dirs"
  for old_dir in "${OLD_DIRS[@]}"; do
    if [ -d "$worktree/skills/$old_dir" ]; then
      rm -rf "$worktree/skills/$old_dir"
    fi
  done

  # Stage, commit
  cd "$worktree"
  git add ".claude/skills/$new_dir/"
  for old_dir in "${OLD_DIRS[@]}"; do
    git add "skills/$old_dir/" 2>/dev/null || true
  done

  git commit -m "$pr_title

Move skill from skills/$old_dirs to .claude/skills/$new_dir as part of
the marketplace skill prefixing migration.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>" 2>&1

  # Push
  if ! git push -u origin "$branch" 2>&1; then
    log "FAIL: Could not push $branch"
    cd "$REPO_ROOT"
    git worktree remove "$worktree" --force 2>/dev/null || true
    git branch -D "$branch" 2>/dev/null || true
    FAILED=$((FAILED + 1))
    continue
  fi

  # Create PR
  PR_URL=$(gh pr create \
    --title "$pr_title" \
    --body "$(cat <<EOF
## Summary
- Move \`skills/$old_dirs/\` to \`.claude/skills/$new_dir/\`
- Part of the skill prefixing migration to \`.claude/skills/\` standard location

## Test plan
- [ ] Verify skill loads correctly from new location
- [ ] Confirm old location is removed

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
    --head "$branch" \
    --base main 2>&1) || true

  log "OK: $pr_title -> $PR_URL"
  CREATED=$((CREATED + 1))

  cd "$REPO_ROOT"
  git worktree remove "$worktree" --force 2>/dev/null || true
done

# Handle mr deletion separately
log "--- Processing: Delete mr skill"
branch="migrate/delete-mr"
worktree="$WORKTREE_BASE/delete-mr"

if [ -d "$worktree" ]; then
  git -C "$REPO_ROOT" worktree remove "$worktree" --force 2>/dev/null || rm -rf "$worktree"
fi
git -C "$REPO_ROOT" branch -D "$branch" 2>/dev/null || true

git -C "$REPO_ROOT" worktree add "$worktree" -b "$branch" main 2>&1
cd "$worktree"
rm -rf skills/mr/
git add skills/mr/
git commit -m "Remove deprecated mr skill

The mr (merge request) skill is GitLab-specific and has been superseded
by github:pull-request.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>" 2>&1
git push -u origin "$branch" 2>&1
MR_PR_URL=$(gh pr create \
  --title "Remove deprecated mr skill" \
  --body "$(cat <<EOF
## Summary
- Remove \`skills/mr/\` (GitLab merge request skill)
- Superseded by \`github:pull-request\`

## Test plan
- [ ] Confirm no references to mr skill remain

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
  --head "$branch" \
  --base main 2>&1) || true

log "OK: Delete mr -> $MR_PR_URL"
CREATED=$((CREATED + 1))

cd "$REPO_ROOT"
git worktree remove "$worktree" --force 2>/dev/null || true

# Handle docs update
log "--- Processing: Update migration docs"
branch="migrate/update-docs"
worktree="$WORKTREE_BASE/update-docs"

if [ -d "$worktree" ]; then
  git -C "$REPO_ROOT" worktree remove "$worktree" --force 2>/dev/null || rm -rf "$worktree"
fi
git -C "$REPO_ROOT" branch -D "$branch" 2>/dev/null || true

git -C "$REPO_ROOT" worktree add "$worktree" -b "$branch" main 2>&1
cd "$worktree"

# Copy modified docs from main working tree
for doc in MIGRATION_STATUS.md README.md SKILL_CATALOG.md USAGE_GUIDE.md docs/abstraction-guide.md docs/configuration-reference.md; do
  if [ -f "$REPO_ROOT/$doc" ]; then
    cp "$REPO_ROOT/$doc" "$worktree/$doc"
  fi
done

git add MIGRATION_STATUS.md README.md SKILL_CATALOG.md USAGE_GUIDE.md docs/abstraction-guide.md docs/configuration-reference.md 2>/dev/null || true
git commit -m "Update documentation for skill migration

Update catalog, usage guide, and migration status to reflect new
.claude/skills/ directory structure and skill prefixing conventions.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>" 2>&1
git push -u origin "$branch" 2>&1
DOCS_PR_URL=$(gh pr create \
  --title "Update documentation for skill migration" \
  --body "$(cat <<EOF
## Summary
- Update MIGRATION_STATUS.md, README.md, SKILL_CATALOG.md, USAGE_GUIDE.md
- Update docs/abstraction-guide.md, docs/configuration-reference.md
- Reflects new \`.claude/skills/\` directory structure

## Test plan
- [ ] Review documentation accuracy

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
  --head "$branch" \
  --base main 2>&1) || true

log "OK: Update docs -> $DOCS_PR_URL"
CREATED=$((CREATED + 1))

cd "$REPO_ROOT"
git worktree remove "$worktree" --force 2>/dev/null || true

# Summary
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Migration Summary"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Created: $CREATED PRs"
log "Failed:  $FAILED"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
