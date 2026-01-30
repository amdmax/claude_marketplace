# Claude Code Skills Marketplace

A centralized repository of reusable Claude Code skills that can be integrated into any project. These skills extend Claude's capabilities with specialized workflows, from commit automation to architecture reviews.

## What is This?

This marketplace contains 30+ production-ready skills abstracted from multiple projects and designed to work anywhere. Each skill is:

- **Fully abstracted** - No hardcoded project-specific values
- **Configurable** - Per-skill configuration files you customize
- **Battle-tested** - Migrated from real-world production projects
- **Well-documented** - Complete usage examples and configuration references

## Quick Start

### 1. Browse the Catalog

See [SKILL_CATALOG.md](SKILL_CATALOG.md) for the complete list of available skills.

### 2. Copy a Skill to Your Project

```bash
# Example: Copy the commit skill to your project
cp -r skills/commit/ /path/to/your/project/.claude/skills/
```

### 3. Configure the Skill

```bash
cd /path/to/your/project/.claude/skills/commit/

# Copy the example config and customize it
cp config.example.yaml config.yaml

# Edit config.yaml with your project-specific values
vim config.yaml
```

### 4. Use the Skill

The skill is now available in your project. Invoke it via Claude Code:

```
/commit
```

## Structure

```
claude_marketplace/
├── skills/                    # All marketplace skills
│   ├── commit/               # Git commit automation
│   ├── mr/                   # Pull request creation
│   ├── create-story/         # Issue creation
│   └── [30+ more skills...]
├── docs/                      # Detailed guides
│   ├── abstraction-guide.md
│   ├── configuration-reference.md
│   └── migration-notes.md
├── SKILL_CATALOG.md          # Complete skill index
└── USAGE_GUIDE.md            # Detailed usage instructions
```

## Skill Categories

### Core Workflow
- **commit** - Automated commit creation with issue numbering
- **mr** - Pull request creation with intelligent grouping
- **create-story** - GitHub issue creation
- **fetch-story** - Issue fetching and management
- **play-story** - Story workflow activation

### Development
- **bug-fix** - Bug fix workflow
- **skill-creator** - Create new skills
- **refactor-skill** - Refactor existing skills
- **sync-skills** - Synchronize skills across projects
- **gather-context** - Code exploration and context gathering

### Architecture & Quality
- **aws-architect** - AWS architecture guidance
- **cdk-scripting** - CDK infrastructure as code
- **security-review** - Security code reviews
- **performance-review** - Performance analysis
- **overall-review** - General code reviews
- **fitness-function-architect** - Architecture validation

### Content & Specialized
- **css-architecture** - CSS architecture patterns
- **ux-professional** - UX guidance
- **creative-writing** - Content creation
- **editor-in-chief** - Editorial review
- **mermaid-diagram** - Diagram generation
- **create-adr** - Architecture decision records
- **gather-nfr** - Non-functional requirements
- **hooks** - Git hooks configuration

## How It Works

### Template Variables

Skills use template variable syntax to remain project-agnostic:

```yaml
# In config.yaml
project:
  prefix: "MYPROJ"              # Your project prefix
  name: "My Cool Project"

repository:
  slug: "myorg/my-repo"
  default_branch: "main"

paths:
  active_story: ".claude/active-story.json"

commands:
  type_check: "npm run type-check"
  test: "npm test"
```

Skills reference these as `{{PROJECT_PREFIX}}`, `{{REPO_SLUG}}`, etc.

### Feature Flags

When skills have variations, they use feature flags:

```yaml
# In config.yaml
features:
  issue_based_numbering: true
  theme_detection: true
  sequential_fallback: false
```

This allows one skill to support multiple workflows.

## Documentation

- **[USAGE_GUIDE.md](USAGE_GUIDE.md)** - Comprehensive usage instructions
- **[SKILL_CATALOG.md](SKILL_CATALOG.md)** - Complete skill index
- **[docs/abstraction-guide.md](docs/abstraction-guide.md)** - Understanding template variables
- **[docs/configuration-reference.md](docs/configuration-reference.md)** - Config options reference
- **[docs/migration-notes.md](docs/migration-notes.md)** - Source project analysis

## Creating New Skills

See [skills/_templates/](skills/_templates/) for:
- **SKILL_TEMPLATE.md** - Template for new skills
- **config-schema.md** - Configuration file documentation

## Contributing

Skills are migrated from production projects:
- Landing page project (AIGWS prefix)
- Vibe coding course project (AIGCODE prefix)
- News bot project (AIGNEWS prefix)

When adding skills, ensure:
1. All project-specific values are abstracted
2. Complete config.yaml template with NO hardcoded values
3. Realistic config.example.yaml
4. Feature flags for variations
5. Complete documentation

## License

Skills are provided as-is for use in Claude Code projects.
