# Implementation Details

## How It Works

**High-level process:**

1. **Verification** - Checks for staged changes (`git diff --cached`)
2. **Number determination:**
   - Issue-based: Read `$AGENT_DOCS_DIR/active-story.yaml` → `/create-story` if missing → extract issueNumber
   - Sequential: Query git log → find highest {{PREFIX}}-### → increment
3. **Grouping detection** (optional):
   - Get recent commits (last N hours)
   - Calculate file overlap with staged changes
   - Compute confidence score
   - Suggest suffix if high confidence
4. **Message generation:**
   - Analyze staged changes (`git diff --cached`)
   - Generate descriptive commit message
   - Format: `{{PREFIX}}-###[suffix]: description`
5. **Commit creation:**
   - Execute `git commit` with generated message
   - Add co-author line if enabled
6. **Validation** (optional):
   - Post-commit hook verifies format
   - Regex check: `^{{PREFIX}}-[0-9]+[a-z]?:`

## Dependencies

- **Git** - Version control system
- **GitHub CLI (gh)** - For issue creation (issue-based mode only)
- **jq** - JSON parsing (active story file)
- **yq** - YAML parsing (config file)
- **create-story skill** - For auto-issue creation (optional)

## Files Created/Modified

- `$AGENT_DOCS_DIR/active-story.yaml` - Active issue tracking (issue-based mode)
- Git commit history - New commits with standardized format

## Customization

**Custom commit message format:**
```yaml
# In config.yaml
message:
  format: "{{prefix}}-{{number}}: {{type}}: {{description}}"
  # Example: MYAPP-123: feat: Add new feature
```

**Custom grouping algorithm:**
```yaml
grouping:
  min_overlap_high: 70      # Stricter HIGH confidence (default: 50)
  min_overlap_medium: 40    # Stricter MEDIUM confidence (default: 30)
  time_threshold_high: 0.5  # Tighter time window (default: 1 hour)
```

**Creating variants:**
```bash
cp -r .claude/skills/commit .claude/skills/commit-experimental
vim .claude/skills/commit-experimental/config.yaml
vim .claude/skills/commit-experimental/SKILL.md
```

## Migration Notes

**Source Projects:**
- Landing page (AIGWS prefix) - Jan 30, 2026
- Vibe coding course (AIGCODE prefix) - Jan 28, 2026
- News bot (AIGNEWS prefix) - Jan 19, 2026

**Abstraction Changes:**
- Hardcoded prefixes → `{{PROJECT_PREFIX}}`
- Hardcoded validation regex → Dynamic prefix from config
- Project-specific hooks → Generic template with config-driven validation
- Separate configurations merged into single configurable skill

**Variations Merged:**
- Issue-based numbering (AIGWS, AIGCODE)
- Sequential numbering (AIGNEWS)
- Grouping detection (AIGWS, AIGCODE)
- All three approaches now available via `numbering.mode` config flag
