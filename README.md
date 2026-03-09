# Claude Code Skills Marketplace

A centralized repository of reusable Claude Code skills that can be integrated into any project. These skills extend Claude's capabilities with specialized workflows, from commit automation to architecture reviews.

## What is This?

This marketplace contains 30+ production-ready skills abstracted from multiple projects and designed to work anywhere. Each skill is:

- **Fully abstracted** - No hardcoded project-specific values
- **Configurable** - Per-skill configuration files you customize
- **Battle-tested** - Migrated from real-world production projects
- **Well-documented** - Complete usage examples and configuration references

## Quick Start

### Option 1: Install from Marketplace (Recommended)

Install all bundles or choose specific ones:

```bash
# Add the marketplace
/plugin marketplace add aigensa/claude_marketplace

# Install all bundles
/plugin install core-workflow@claude-skills-marketplace
/plugin install development-tools@claude-skills-marketplace
/plugin install architecture-quality@claude-skills-marketplace
/plugin install content-specialized@claude-skills-marketplace

# Or install just what you need
/plugin install core-workflow@claude-skills-marketplace
```

**Available Bundles:**
- **core-workflow** (5 skills) - git:commit, github:pull-request, github:story-create, github:story-fetch, github:story-play
- **development-tools** (5 skills) - bug-fix, claude:skill-creator, claude:refactor-skill, claude:sync-skills, gather-context
- **architecture-quality** (6 skills) - aws:architect, aws:cdk, review:security, review:performance, review:overall, arch:fitness-function
- **content-specialized** (12 skills) - css-architecture, ux-professional, creative-writing, editor-in-chief, mermaid-diagram, and more

### Option 2: Manual Copy (For Customization)

#### 1. Browse the Catalog

See [SKILL_CATALOG.md](SKILL_CATALOG.md) for the complete list of available skills.

#### 2. Copy a Skill to Your Project

```bash
# Example: Copy the commit skill to your project
cp -r .claude/skills/git:commit/ /path/to/your/project/.claude/skills/
```

#### 3. Configure the Skill

```bash
cd /path/to/your/project/.claude/skills/git:commit/

# Copy the example config and customize it
cp config.example.yaml config.yaml

# Edit config.yaml with your project-specific values
vim config.yaml
```

#### 4. Use the Skill

The skill is now available in your project. Invoke it via Claude Code:

```
/commit
```

## Structure

```
claude_marketplace/
├── .claude/
│   └── skills/                # All marketplace skills (auto-discovered)
│       ├── _templates/        # Skill creation templates
│       ├── git:commit/        # Git commit automation
│       ├── github:pull-request/ # Pull request creation
│       ├── github:story-create/ # Issue creation
│       └── [30+ more skills...]
├── docs/                      # Detailed guides
│   ├── abstraction-guide.md
│   ├── configuration-reference.md
│   └── migration-notes.md
├── SKILL_CATALOG.md           # Complete skill index
└── USAGE_GUIDE.md             # Detailed usage instructions
```

## Skill Categories

### Core Workflow
- **git:commit** - Automated commit creation with issue numbering
- **github:pull-request** - Pull request creation
- **github:story-create** - GitHub issue creation
- **github:story-fetch** - Issue fetching and management
- **github:story-play** - Story workflow activation

### Development
- **bug-fix** - Bug fix workflow
- **claude:skill-creator** - Create new skills
- **claude:refactor-skill** - Refactor existing skills
- **claude:sync-skills** - Synchronize skills across projects
- **gather-context** - Code exploration and context gathering

### Architecture & Quality
- **aws:architect** - AWS architecture guidance
- **aws:cdk** - CDK infrastructure as code
- **review:security** - Security code reviews
- **review:performance** - Performance analysis
- **review:overall** - General code reviews
- **arch:fitness-function** - Architecture validation

### Team Orchestration
- **team:agile-dev** - 5-agent TDD team with story-driven workflow

### Content & Specialized
- **css-architecture** - CSS architecture patterns
- **ux-professional** - UX guidance
- **creative-writing** - Content creation
- **editor-in-chief** - Editorial review
- **mermaid-diagram** - Diagram generation
- **create-adr** - Architecture decision records
- **gather-nfr** - Non-functional requirements
- **claude:hooks** - Claude Code hooks configuration

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
- **[docs/statusline-guide.md](docs/statusline-guide.md)** - Claude Code statusline features and configuration
- **[docs/abstraction-guide.md](docs/abstraction-guide.md)** - Understanding template variables
- **[docs/configuration-reference.md](docs/configuration-reference.md)** - Config options reference
- **[docs/migration-notes.md](docs/migration-notes.md)** - Source project analysis

## Creating New Skills

See [.claude/skills/_templates/](.claude/skills/_templates/) for:
- **SKILL_TEMPLATE.md** - Template for new skills
- **config-schema.md** - Configuration file documentation

## Aigensa Academy Assets

Synced directly from [aigensa/academy](https://github.com/amdmax/academy) `.claude/` directory. These are production-ready assets used in a real-world TypeScript/AWS CDK course project.

### Skills (`skills/`)

| Skill | Description |
|-------|-------------|
| `add-content-image` | Add Content Image |
| `arch:create-adr` | Create Architecture Decision Record |
| `arch:gather-nfrs` | Gather Non-Functional Requirements |
| `arch:maintain-registries` | Maintain Registries |
| `bug-fix` | Bug Fix Automation |
| `cdk-scripting` | CDK Scripting Assistant |
| `cdk-validate` | CDK Infrastructure Validator |
| `code-review` | Code Review Orchestrator |
| `compliance` | Compliance Validation |
| `create-story` | Quick GitHub issue creation for commit workflow |
| `creative-writing` | Creative Writing Skill |
| `css-architecture` | CSS Architecture Skill |
| `debug` | Hypothesis-Driven Bug Investigation |
| `editor-in-chief` | Editorial review for educational materials |
| `fetch-story` | Fetch next Ready story from GitHub Projects |
| `finalize-story` | Wrap up completed story with GitHub hygiene |
| `gather-context` | Gather Technical Context |
| `gh-actions` | GitHub Actions Composite Actions |
| `gh-edit-workflow` | GitHub Actions Workflow Editor |
| `gh:commit` | AIGCODE Commit Automation with issue numbering |
| `gh:pr` | Pull Request Creation with Story Integration |
| `mermaid-diagram` | Mermaid Diagram Generator |
| `overall-review` | Overall Code Review |
| `performance-review` | Performance Review |
| `play-story` | Play Story Workflow |
| `refactor-skill` | Skill Refactoring Tool |
| `regenerate-course-content` | Rebuild course HTML from markdown sources |
| `security-review` | OWASP Top 10 + API Security Scanner |
| `skill-creator` | Skill Creator |
| `sync-skills` | Skill Sync Tool |
| `ux-professional` | UX Professional |

### Commands (`commands/`)

Slash commands for Claude Code:

| Command | Description |
|---------|-------------|
| `agile-dev-team` | 5-agent TDD agile team orchestration |
| `architect` | Morgan — Solution Architect (Standalone) |
| `backend-dev` | Alex — Backend Dev (Standalone) |
| `create-claude-hook` | Interactive hook configuration |
| `frontend-dev` | Casey — Frontend Dev (Standalone) |
| `pm` | Riley — PM (Standalone) |
| `test-architect` | Jordan — Test Architect (Standalone) |
| `write-cdk` | CDK Infrastructure Code Review |
| `write-typescript` | TypeScript Code Review |
| `speckit.analyze` | Cross-artifact consistency analysis |
| `speckit.checklist` | Feature checklist generation |
| `speckit.clarify` | Spec clarification Q&A |
| `speckit.constitution` | Project constitution management |
| `speckit.implement` | Implementation plan execution |
| `speckit.plan` | Implementation planning workflow |
| `speckit.specify` | Feature specification creation |
| `speckit.tasks` | Task generation from design artifacts |
| `speckit.taskstoissues` | Convert tasks to GitHub issues |

### Agents (`agents/`)

Role-based agent definitions for team orchestration:

| Agent | Role |
|-------|------|
| `architect` | Solution Architect — maps requirements to implementation |
| `backend-dev` | Backend Developer — handlers, infrastructure, config |
| `devops` | DevOps — deployment pipeline, S3/CloudFront, verification |
| `frontend-dev` | Frontend Developer — TypeScript builders, templates, CSS |
| `pm` | PM / Team Lead — story lifecycle, PRs |
| `scope-guard` | Independent reviewer — compares diff against scope |
| `test-architect` | Test Architect — TDD red phase, failing tests first |

### Hooks (`hooks/`)

Git and tool hooks for code quality automation:

| Hook | Purpose |
|------|---------|
| `block-master-push.sh` | Block direct pushes to master |
| `block-pr-merge.sh` | Block PR merges that fail checks |
| `cdk-validate.sh` | Validate CDK synth before commit |
| `edit.sh` | Pre-edit hook |
| `format.sh` | Auto-format on save |
| `lint-check.sh` | Lint gate |
| `pre-push.sh` | Pre-push validation |
| `pre-tool-use.ts` | TypeScript pre-tool hook |
| `session-start.sh` | Session initialization hook |
| `validate-workflows.sh` | GitHub Actions workflow validation |

### Usage

Copy any asset into your project's `.claude/` directory:

```bash
# Copy a skill
cp -r skills/gh:commit/ /path/to/your/project/.claude/skills/

# Copy an agent definition
cp agents/architect.md /path/to/your/project/.claude/agents/

# Copy a command
cp commands/speckit.plan.md /path/to/your/project/.claude/commands/

# Copy a hook
cp hooks/block-master-push.sh /path/to/your/project/.claude/hooks/
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
