# Migration Notes

Documentation of source projects, migration decisions, and abstraction changes made during the Skills Marketplace creation.

## Table of Contents

1. [Source Projects](#source-projects)
2. [Migration Methodology](#migration-methodology)
3. [Per-Skill Migration Notes](#per-skill-migration-notes)
4. [Abstraction Changes](#abstraction-changes)
5. [Variations Merged](#variations-merged)
6. [Known Issues](#known-issues)

## Source Projects

Skills were migrated from three production AIGENSA projects:

### Landing Page (AIGWS)
- **Path:** `/Users/thesolutionarchitect/Documents/source/aigensa/landing_page/.claude/skills/`
- **Prefix:** AIGWS
- **Repository:** aigensa/landing_page
- **Last Updated:** January 30, 2026
- **Characteristics:** Full skill set with references, most recently updated

### Vibe Coding Course (AIGCODE)
- **Path:** `/Users/thesolutionarchitect/Documents/source/aigensa/vibe-coding-course/.claude/skills/`
- **Prefix:** AIGCODE
- **Repository:** aigensa/vibe-coding-course
- **Last Updated:** January 29, 2026
- **Characteristics:** Identical to landing_page for most skills, includes some unique references

### News Bot (AIGNEWS)
- **Path:** `/Users/thesolutionarchitect/Documents/source/aigensa/news-bot/.claude/skills/`
- **Prefix:** AIGNEWS
- **Repository:** aigensa/news-bot
- **Last Updated:** January 20, 2026
- **Characteristics:** Simpler implementations, some skills use different approaches

## Migration Methodology

### Version Selection Criteria

For each skill, we selected the source version based on:

1. **Recency** - Most recently updated (later modification date preferred)
2. **Completeness** - Most comprehensive documentation and references
3. **Modularity** - Best separation of concerns (config.yaml vs SKILL.md)
4. **Correctness** - No hardcoded references to wrong projects

### Abstraction Process

1. **Discovery** - Identify all hardcoded values (grep for patterns)
2. **Extraction** - Move values to config.yaml with template variables
3. **Replacement** - Replace hardcoded values in SKILL.md with variables
4. **Documentation** - Add "Template Variables Reference" section
5. **Validation** - Verify no hardcoded values remain

### Tooling Used

- **sed** - Bulk find/replace for common patterns
- **grep** - Find hardcoded values
- **yq** - Config file parsing
- **jq** - JSON config parsing

## Per-Skill Migration Notes

### Tier 1: Core Workflow Skills

#### commit

**Source:** Vibe Coding Course (AIGCODE)
**Rationale:** Most recent (Jan 28), complete references, correct config

**Hardcoded Values Removed:**
- AIGCODE prefix → `{{PROJECT_PREFIX}}`
- aigensa/vibe-coding-course → `{{REPO_SLUG}}`
- .claude/active-story.json → `{{ACTIVE_STORY_FILE}}`
- Validation hook regex patterns

**Variations Merged:**
- **Issue-based mode** (AIGWS, AIGCODE) - Uses GitHub issues for numbering
- **Sequential mode** (AIGNEWS) - Uses auto-incrementing counter
- Combined via `numbering.mode` config flag

**Key Changes:**
- Validation hook now reads prefix from config dynamically
- References (aigcode-counter.md, issue-numbering.md) fully abstracted
- All three modes available via single skill

**Lines:** 779 (SKILL.md)

---

#### mr

**Source:** Vibe Coding Course
**Rationale:** Most recent (Jan 29), no config errors, complete documentation

**Hardcoded Values Removed:**
- aigensa/vibe-coding-course → `{{REPO_SLUG}}`
- master → `{{DEFAULT_BRANCH}}`
- AIGCODE → `{{PROJECT_PREFIX}}`
- story- prefix → `{{STORY_PREFIX}}`

**Variations:** All three projects had identical implementations

**Key Changes:**
- Theme detection fully parameterized
- Cherry-pick workflow abstracted
- Branch naming configurable

**Lines:** 686 (SKILL.md)

---

#### create-story

**Source:** Landing Page
**Rationale:** Has references directory, complete implementation

**Hardcoded Values Removed:**
- aigensa/landing_page → `{{REPO_SLUG}}`
- AIGCODE → `{{PROJECT_PREFIX}}`
- .claude/active-story.json → `{{ACTIVE_STORY_FILE}}`

**Variations:** Identical across all projects

**Key Changes:**
- Repository slug templated
- File paths configurable
- References (error-handling.md, examples.md, github-api.md) abstracted

**Lines:** 234 (SKILL.md)

---

#### fetch-story

**Source:** Vibe Coding Course
**Rationale:** Complete implementation, correct project IDs

**Hardcoded Values Removed:**
- PVT_kwDODvZ3Zc4BM9rk → `{{GITHUB_PROJECT_ID}}`
- All field IDs → `{{FIELD_ID_*}}`
- All option IDs → `{{OPTION_ID_*}}`
- aigensa/vibe-coding-course → `{{REPO_SLUG}}`

**Special Handling:**
- Created `story-workflow-config.json` template
- Created `story-workflow-config.example.json` with discovery instructions
- GitHub Projects v2 IDs must be discovered per project via GraphQL

**Key Changes:**
- Completely abstracted GitHub Project IDs
- Documented discovery process in example file
- Template ready for any GitHub Project

**Lines:** 812 (SKILL.md)

---

#### play-story

**Source:** Vibe Coding Course
**Rationale:** Most comprehensive (900 lines), complete workflow

**Hardcoded Values Removed:**
- aigensa/vibe-coding-course → `{{REPO_SLUG}}`
- PVT_kwDODvZ3Zc4BM9rk → `{{GITHUB_PROJECT_ID}}`
- vibe-coding-course → `{{REPO_NAME}}`
- URL references

**Variations:** Identical across projects

**Key Changes:**
- Repository references abstracted
- Project URLs templated
- Integration with other skills preserved

**Lines:** 900 (SKILL.md)

---

### Tier 2: Development Skills

#### bug-fix

**Source:** Landing Page
**Rationale:** Has references directory, complete workflow

**Hardcoded Values Removed:**
- AIGCODE → `{{PROJECT_PREFIX}}`
- aigensa/landing_page → `{{REPO_SLUG}}`

**Variations:** Identical across projects

**Key Changes:**
- Config.yaml already existed (minimal abstraction needed)
- References (bug-investigation.md, testing-best-practices.md) included

**Lines:** 558 (SKILL.md)

---

#### skill-creator

**Source:** Landing Page
**Rationale:** Complete references, modular structure

**Hardcoded Values Removed:**
- AIGCODE → `{{PROJECT_PREFIX}}`
- aigensa → `{{REPO_OWNER}}`

**Variations:** Identical across projects

**Key Changes:**
- Minimal hardcoding (already generic)
- References (output-patterns.md, workflows.md) included
- Self-contained and reusable

**Lines:** 357 (SKILL.md)

---

#### refactor-skill

**Source:** Landing Page
**Rationale:** Complete, self-contained

**Hardcoded Values Removed:**
- AIGCODE → `{{PROJECT_PREFIX}}`

**Variations:** Identical across projects

**Key Changes:**
- Already very generic
- No config.yaml needed (pattern-based guidance)
- Fully self-contained

**Lines:** 668 (SKILL.md)

---

#### sync-skills

**Source:** Landing Page
**Rationale:** Most recent

**Hardcoded Values Removed (50+ instances):**
- amdmax → `{{SKILLS_REPO_OWNER}}`
- agent_skills → `{{SKILLS_REPO_NAME}}`
- github.com/amdmax/agent_skills → templated URL

**Variations:** Identical across projects, all hardcoded to amdmax/agent_skills

**Critical Issue:**
- Originally tightly coupled to amdmax's personal repository
- Created config.yaml to make it work for any user's skills repo

**Key Changes:**
- Created comprehensive config.yaml for repository settings
- Bulk replacement of 50+ hardcoded references
- Now works for any user's skill repository

**Lines:** 785 (SKILL.md)

---

#### gather-context

**Source:** Landing Page
**Rationale:** Complete implementation

**Hardcoded Values Removed:**
- _bmad-output/ → `{{ARCHITECTURE_DOCS_DIR}}`
- .claude/active-story.json → `{{ACTIVE_STORY_FILE}}`
- .claude/skills/ → `{{SKILLS_DIR}}`
- docs/adr/ → `{{ADR_DIR}}`

**Variations:** Identical across projects

**Key Changes:**
- Created config.yaml for flexible directory structure
- Path abstraction allows different project layouts
- Multi-source context gathering preserved

**Lines:** 884 (SKILL.md)

---

## Abstraction Changes

### Pattern 1: Prefix Abstraction

**Before:**
```yaml
numbering:
  prefix: AIGCODE
```

**After:**
```yaml
numbering:
  prefix: {{PROJECT_PREFIX}}
```

**Impact:** Skills work with any project prefix (MYAPP, PROJ, etc.)

---

### Pattern 2: Repository Abstraction

**Before:**
```yaml
repository: "aigensa/landing_page"
```

**After:**
```yaml
repository:
  slug: "{{REPO_SLUG}}"
  owner: "{{REPO_OWNER}}"
  name: "{{REPO_NAME}}"
```

**Impact:** Skills work with any GitHub repository

---

### Pattern 3: Path Abstraction

**Before:**
```bash
STORY_FILE=".claude/active-story.json"
```

**After:**
```bash
STORY_FILE=$(yq e '.paths.active_story' config.yaml)
```

**Impact:** Flexible directory structures supported

---

### Pattern 4: GitHub Project IDs

**Before:**
```json
{
  "projectId": "PVT_kwDODvZ3Zc4BM9rk"
}
```

**After:**
```json
{
  "projectId": "{{GITHUB_PROJECT_ID}}"
}
```

**Impact:** Works with any GitHub Project V2 (user must discover IDs)

---

### Pattern 5: External Repository References

**Before:**
```yaml
repository: "amdmax/agent_skills"
```

**After:**
```yaml
repository:
  owner: "{{SKILLS_REPO_OWNER}}"
  name: "{{SKILLS_REPO_NAME}}"
```

**Impact:** sync-skills works for any user's repository

---

## Variations Merged

### commit: Issue-Based vs Sequential

**Source Variations:**
- **AIGWS, AIGCODE:** Issue-based numbering with GitHub Issues
- **AIGNEWS:** Sequential numbering only

**Merge Strategy:**
```yaml
numbering:
  mode: "issue-based"  # or "sequential"
```

**Result:** Single skill supports both modes via config flag

---

### No Other Significant Variations

Most skills were identical across projects with only prefix/repository differences.

## Known Issues

### Issue 1: GitHub Project ID Discovery

**Problem:** Users must manually discover GitHub Project IDs via GraphQL

**Impact:** fetch-story, play-story require setup

**Mitigation:**
- Provided discovery instructions in story-workflow-config.example.json
- Documented GraphQL queries
- Added step-by-step guide

**Future:** Could create setup wizard to automate discovery

---

### Issue 2: Reference Files May Contain Examples

**Problem:** Some reference files contain example commits with old prefixes

**Impact:** Minimal - examples are clearly marked

**Mitigation:**
- Most examples abstracted
- Remaining examples documented as "example only"

**Status:** 2 minor references remain in documentation (intentional)

---

### Issue 3: Stack-Specific Commands

**Problem:** Commands like `npm test` assume Node.js stack

**Impact:** Users must configure for their stack

**Mitigation:**
- config.example.yaml shows examples for multiple stacks
- Documentation includes Python, Rust, Go examples

**Status:** By design - user configurable

---

## Migration Statistics

### Skills Migrated

- **Tier 1:** 5 skills (commit, mr, create-story, fetch-story, play-story)
- **Tier 2:** 5 skills (bug-fix, skill-creator, refactor-skill, sync-skills, gather-context)
- **Total:** 10 skills

### Abstraction Metrics

- **Hardcoded values removed:** 200+
- **Template variables created:** 50+
- **Config files created:** 16 (8 .yaml, 8 .example.yaml)
- **Lines of documentation:** 11,000+

### Validation Results

- ✅ Zero AIGWS/AIGCODE/AIGNEWS in marketplace code
- ✅ Zero aigensa/* repository references
- ✅ Zero amdmax/agent_skills references
- ✅ All skills tested with template configs
- ✅ All reference docs abstracted

## Lessons Learned

### What Worked Well

1. **sed for bulk replacement** - Efficient for patterns like AIGCODE → {{PROJECT_PREFIX}}
2. **Per-skill configs** - Better than global config (isolation, clarity)
3. **Example files** - config.example.yaml helps users understand format
4. **Template variable naming** - SCREAMING_SNAKE_CASE is clear and consistent

### Challenges

1. **GitHub Project IDs** - No automated way to discover, required manual documentation
2. **Deep nesting** - sync-skills had 50+ references to abstract
3. **Path assumptions** - Some skills assumed specific directory structures
4. **Validation hooks** - Needed dynamic regex patterns (solved with config reads)

### Best Practices Established

1. Always create config.example.yaml with realistic values
2. Document all template variables in SKILL.md
3. Use grep extensively to find hardcoded values
4. Test abstraction with fresh config (no old values cached)
5. Include "Migration Notes" section in each SKILL.md

## Future Enhancements

### Possible Improvements

1. **Setup Wizard** - Interactive script to create config.yaml
2. **Project ID Discovery** - Automated GraphQL queries for GitHub Projects
3. **Validation Tool** - Check config.yaml completeness
4. **Migration Tool** - Automated abstraction for new skills
5. **Multi-project Sync** - Sync skill improvements back to source projects

### Backwards Compatibility

These marketplace skills are compatible with original projects if:
- User sets config values to match original (e.g., PROJECT_PREFIX=AIGCODE)
- User keeps same file paths

No breaking changes for existing users who adopt marketplace versions.

## See Also

- [Abstraction Guide](abstraction-guide.md) - Template variable system
- [Configuration Reference](configuration-reference.md) - All config options
- [SKILL_CATALOG.md](../SKILL_CATALOG.md) - Complete skill list
