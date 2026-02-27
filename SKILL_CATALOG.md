# Skills Catalog

Complete index of all skills available in the Claude Code Skills Marketplace.

## Quick Reference

| Skill | Category | Description | Priority |
|-------|----------|-------------|----------|
| [git:commit](#gitcommit) | Core Workflow | Automated commit creation with issue numbering | Tier 1 |
| [github:story-create](#githubstory-create) | Core Workflow | GitHub issue creation | Tier 1 |
| [github:story-fetch](#githubstory-fetch) | Core Workflow | Issue fetching and management | Tier 1 |
| [github:story-play](#githubstory-play) | Core Workflow | Story workflow activation | Tier 1 |
| [github:pull-request](#githubpull-request) | Core Workflow | Pull request creation | Tier 1 |
| [team:agile-dev](#teamagile-dev) | Team Orchestration | 5-agent TDD team with story-driven workflow | Tier 1 |
| [bug-fix](#bug-fix) | Development | Bug fix workflow | Tier 2 |
| [claude:skill-creator](#claudeskill-creator) | Development | Create new skills | Tier 2 |
| [claude:refactor-skill](#clauderefactor-skill) | Development | Refactor existing skills | Tier 2 |
| [claude:sync-skills](#claudesync-skills) | Development | Synchronize skills across projects | Tier 2 |
| [gather-context](#gather-context) | Development | Code exploration and context gathering | Tier 2 |
| [github:story-quality](#githubstory-quality) | Quality | SMART AC and NFR validation for stories | Tier 2 |
| [aws:architect](#awsarchitect) | Architecture | AWS architecture guidance | Tier 3 |
| [aws:cdk](#awscdk) | Architecture | CDK infrastructure as code | Tier 3 |
| [review:security](#reviewsecurity) | Quality | Security code reviews | Tier 3 |
| [review:performance](#reviewperformance) | Quality | Performance analysis | Tier 3 |
| [review:overall](#reviewoverall) | Quality | General code reviews | Tier 3 |
| [arch:fitness-function](#archfitness-function) | Architecture | Architecture validation | Tier 3 |
| [jupyter-remote](#jupyter-remote) | Specialized | Run Python code/notebooks on Jupyter kernel (remote SSH or local) | Tier 4 |
| [remote-execution](#remote-execution) | Specialized | Routing pattern for SSH-dispatched compute (reference skill) | Tier 4 |
| [css-architecture](#css-architecture) | Specialized | CSS architecture patterns | Tier 4 |
| [ux-professional](#ux-professional) | Specialized | UX guidance | Tier 4 |
| [creative-writing](#creative-writing) | Content | Content creation | Tier 4 |
| [editor-in-chief](#editor-in-chief) | Content | Editorial review | Tier 4 |
| [mermaid-diagram](#mermaid-diagram) | Content | Diagram generation | Tier 4 |
| [add-content-image](#add-content-image) | Content | Image handling | Tier 4 |
| [regenerate-course-content](#regenerate-course-content) | Content | Course content generation | Tier 4 |
| [create-adr](#create-adr) | Documentation | Architecture decision records | Tier 4 |
| [gather-nfr](#gather-nfr) | Documentation | Non-functional requirements | Tier 4 |
| [claude:hooks](#claudehooks) | Configuration | Claude Code hooks configuration | Tier 4 |

---

## Team Orchestration Skills

### team:agile-dev

**Category:** Team Orchestration
**Priority:** Tier 1

**Purpose:**
Spin up a coordinated 5-agent TDD team that fetches stories, designs implementation, writes failing tests, and implements both backend and frontend code.

**Key Features:**
- 5-agent team: PM, Architect, Test Architect, Backend Dev, Frontend Dev
- TDD-first workflow (red-green cycle)
- Automatic story enrichment with NFRs
- Parallel backend + frontend implementation
- Automatic PR creation after verification
- Built-in negotiation and conflict resolution protocol

**Configuration Required:**
- Project prefix (for branch naming)
- File paths (active story, NFR registry, test dir)
- Test commands (unit, integration, e2e)
- File boundary definitions per agent role
- Agent definition files in `.claude/agents/`

**Dependencies:**
- `/fetch-story`, `/check-story-quality`, `/gather-context`, `/create-adr`, `/commit`, `/pr` (or `/github:pull-request`)

**Use Cases:**
- Fully automated story implementation
- TDD-driven feature development
- Multi-agent parallel implementation

**Invoke:** `/team:agile-dev`

---

## Core Workflow Skills

### git:commit

**Category:** Core Workflow
**Priority:** Tier 1 (Most Critical)

**Purpose:**
Automated commit creation with intelligent issue numbering, theme detection, and hook validation.

**Key Features:**
- Issue-based commit numbering (e.g., `PROJ-123: Add feature`)
- Theme detection and grouping
- Auto-creation of missing GitHub issues
- Sequential fallback numbering
- Pre-commit hook validation
- Type checking and testing integration

**Configuration Required:**
- Project prefix
- Repository slug
- GitHub settings
- Tool commands (type-check, test, lint)

**Use Cases:**
- Automated commit workflow
- Issue tracking integration
- Code quality validation before commit

**Invoke:** `/commit`

---

### github:story-create

**Category:** Core Workflow
**Priority:** Tier 1

**Purpose:**
Create GitHub issues with standardized formatting and optional templates.

**Key Features:**
- Issue template support
- Label management
- Milestone assignment
- Story point estimation
- Acceptance criteria formatting

**Configuration Required:**
- Repository slug
- Issue templates path
- Default labels

**Use Cases:**
- Create user stories
- Track feature requests
- Document bugs

**Invoke:** `/create-story`

---

### github:story-fetch

**Category:** Core Workflow
**Priority:** Tier 1

**Purpose:**
Fetch and display GitHub issues with filtering and sorting capabilities.

**Key Features:**
- Issue filtering by label, milestone, assignee
- Sorting options
- Active story tracking
- Issue metadata display

**Configuration Required:**
- Repository slug
- Active story file path

**Use Cases:**
- Browse available issues
- Select next task
- Track current work

**Invoke:** `/fetch-story`

---

### github:story-play

**Category:** Core Workflow
**Priority:** Tier 1

**Purpose:**
Activate a GitHub issue as the current story, creating branch and tracking file.

**Key Features:**
- Branch creation from issue
- Active story file management
- Issue metadata extraction
- Workflow state tracking

**Configuration Required:**
- Repository slug
- Active story file path
- Branch naming convention

**Use Cases:**
- Start work on an issue
- Track current task
- Maintain workflow context

**Invoke:** `/play-story`

---

## Development Skills

### bug-fix

**Category:** Development
**Priority:** Tier 2

**Purpose:**
Structured bug fix workflow with root cause analysis and verification.

**Key Features:**
- Bug reproduction steps
- Root cause analysis
- Fix verification
- Test case creation
- Regression prevention

**Configuration Required:**
- Test commands
- Active bug file path

**Use Cases:**
- Systematic bug resolution
- Create bug fix documentation
- Ensure comprehensive testing

**Invoke:** `/bug-fix`

---

### claude:skill-creator

**Category:** Development
**Priority:** Tier 2

**Purpose:**
Create new Claude Code skills with proper structure and documentation.

**Key Features:**
- Skill template generation
- SKILL.md scaffolding
- Configuration file creation
- References directory setup
- Best practices enforcement

**Configuration Required:**
- Skills directory path
- Template preferences

**Use Cases:**
- Create custom project skills
- Extend Claude capabilities
- Standardize skill structure

**Invoke:** `/claude:skill-creator`

---

### claude:refactor-skill

**Category:** Development
**Priority:** Tier 2

**Purpose:**
Refactor existing skills with abstraction and improvement suggestions.

**Key Features:**
- Skill analysis
- Abstraction recommendations
- Configuration extraction
- Documentation updates
- Version migration

**Configuration Required:**
- Skills directory path

**Use Cases:**
- Improve existing skills
- Abstract project-specific logic
- Update skill documentation

**Invoke:** `/claude:refactor-skill`

---

### claude:sync-skills

**Category:** Development
**Priority:** Tier 2

**Purpose:**
Synchronize skills across multiple projects with conflict resolution.

**Key Features:**
- Multi-project sync
- Conflict detection
- Version tracking
- Selective sync
- Backup creation

**Configuration Required:**
- Source/target project paths
- Sync rules

**Use Cases:**
- Share skills across projects
- Maintain skill consistency
- Update multiple projects

**Invoke:** `/claude:sync-skills`

---

### gather-context

**Category:** Development
**Priority:** Tier 2

**Purpose:**
Explore codebase and gather contextual information for tasks.

**Key Features:**
- Dependency analysis
- Code structure exploration
- Pattern detection
- Impact analysis
- Documentation extraction

**Configuration Required:**
- Project paths
- Exclusion patterns

**Use Cases:**
- Understand unfamiliar code
- Plan refactoring
- Analyze dependencies

**Invoke:** `/gather-context`

---

## Architecture & Quality Skills

### aws:architect

**Category:** Architecture
**Priority:** Tier 3

**Purpose:**
AWS architecture guidance and best practices.

**Key Features:**
- Service selection guidance
- Architecture pattern recommendations
- Cost optimization
- Security best practices
- Scalability planning

**Configuration Required:**
- AWS region preferences
- Service constraints

**Use Cases:**
- Design cloud architecture
- Review AWS implementations
- Optimize cloud costs

**Invoke:** `/aws-architect`

---

### aws:cdk

**Category:** Architecture
**Priority:** Tier 3

**Purpose:**
AWS CDK infrastructure as code development.

**Key Features:**
- CDK stack generation
- Best practices enforcement
- Resource naming conventions
- Tag management
- Cross-stack references

**Configuration Required:**
- CDK version
- Infrastructure directory
- Stack naming convention

**Use Cases:**
- Create CDK stacks
- Manage infrastructure as code
- Implement cloud resources

**Invoke:** `/cdk-scripting`

---

### review:security

**Category:** Quality
**Priority:** Tier 3

**Purpose:**
Security-focused code review with vulnerability detection.

**Key Features:**
- OWASP Top 10 checking
- Authentication/authorization review
- Input validation analysis
- Secret detection
- Dependency vulnerability scanning

**Configuration Required:**
- Security scanning tools
- Review criteria

**Use Cases:**
- Pre-deployment security checks
- Code review for security
- Compliance validation

**Invoke:** `/security-review`

---

### review:performance

**Category:** Quality
**Priority:** Tier 3

**Purpose:**
Performance analysis and optimization recommendations.

**Key Features:**
- Performance profiling
- Bottleneck identification
- Query optimization
- Caching strategies
- Resource utilization analysis

**Configuration Required:**
- Performance thresholds
- Profiling tools

**Use Cases:**
- Optimize slow code
- Review performance-critical paths
- Capacity planning

**Invoke:** `/performance-review`

---

### review:overall

**Category:** Quality
**Priority:** Tier 3

**Purpose:**
Comprehensive code review covering quality, maintainability, and best practices.

**Key Features:**
- Code quality metrics
- Best practices checking
- Documentation review
- Test coverage analysis
- Technical debt identification

**Configuration Required:**
- Review criteria
- Quality standards

**Use Cases:**
- General code review
- Quality gate checking
- Team code standards

**Invoke:** `/overall-review`

---

### arch:fitness-function

**Category:** Architecture
**Priority:** Tier 3

**Purpose:**
Define and implement architecture fitness functions for governance.

**Key Features:**
- Fitness function definition
- Automated architecture validation
- Governance rule creation
- Compliance checking
- Evolutionary architecture support

**Configuration Required:**
- Architecture rules
- Validation tools

**Use Cases:**
- Enforce architecture standards
- Automated governance
- Continuous architecture validation

**Invoke:** `/arch:fitness-function`

---

## Content & Specialized Skills

### jupyter-remote

**Category:** Specialized
**Priority:** Tier 4

**Purpose:**
Run Python code and notebooks on a Jupyter kernel, routing automatically to a remote box via SSH tunnel or to a local server.

**Key Features:**
- Local/remote routing via `JUPYTER_SSH_HOST` env var
- SSH tunnel opened automatically when remote mode is active
- Run inline code, stdin, or full `.ipynb` notebooks cell by cell
- Kernel reuse (attaches to existing idle/busy kernel)
- Configurable timeout, start/stop cell for partial notebook runs

**Configuration Required:**
- `JUPYTER_SSH_HOST` (for remote mode, e.g. `cuda-dev`)
- `JUPYTER_TOKEN` (default: `aigensa`)

**Dependencies:**
- `remote-execution` skill (routing pattern)
- `websocket-client` Python package

**Use Cases:**
- Run GPU-intensive training or eval on a remote machine
- Execute notebook cells on a remote Jupyter kernel
- Run local Jupyter experiments from Claude

**Invoke:** `/jupyter-remote`

---

### remote-execution

**Category:** Specialized
**Priority:** Tier 4

**Purpose:**
Behavioral reference skill documenting the `*_SSH_HOST` routing pattern for skills that dispatch compute to a remote host or fall back to local.

**Key Features:**
- Defines the `*_SSH_HOST` env var convention
- Remote mode: opens SSH tunnel via `scripts/ssh_tunnel.py`
- Local mode: probes once, exits immediately if unreachable
- Implementation reference code snippet included

**Configuration Required:**
- None (pattern/reference skill — not directly invocable)

**Use Cases:**
- Reference when building new remote-capable skills
- Ensure consistent routing behavior across tools

**Invoke:** N/A (behavioral reference skill, not user-invocable)

---

### css-architecture

**Category:** Specialized
**Priority:** Tier 4

**Purpose:**
CSS architecture patterns and best practices guidance.

**Key Features:**
- CSS methodology recommendations (BEM, SMACSS, etc.)
- Component styling patterns
- Performance optimization
- Maintainability review
- Design system integration

**Configuration Required:**
- CSS methodology preference
- Design system path

**Use Cases:**
- Structure CSS codebase
- Review styling patterns
- Implement design systems

**Invoke:** `/css-architecture`

---

### ux-professional

**Category:** Specialized
**Priority:** Tier 4

**Purpose:**
UX guidance and usability review.

**Key Features:**
- Usability heuristics evaluation
- Accessibility checking (WCAG)
- User flow analysis
- Component UX patterns
- Mobile responsiveness

**Configuration Required:**
- Accessibility standards
- Target devices

**Use Cases:**
- Review UX implementation
- Accessibility compliance
- User experience optimization

**Invoke:** `/ux-professional`

---

### creative-writing

**Category:** Content
**Priority:** Tier 4

**Purpose:**
Content creation assistance for documentation, marketing, and communication.

**Key Features:**
- Tone and voice consistency
- Content structure templates
- SEO optimization
- Readability analysis
- Multi-format support

**Configuration Required:**
- Brand voice guidelines
- Content templates

**Use Cases:**
- Write documentation
- Create marketing content
- Draft communications

**Invoke:** `/creative-writing`

---

### editor-in-chief

**Category:** Content
**Priority:** Tier 4

**Purpose:**
Editorial review and content quality assurance.

**Key Features:**
- Grammar and style checking
- Content structure review
- Consistency validation
- Fact checking
- Publishing workflow

**Configuration Required:**
- Style guide reference
- Publishing criteria

**Use Cases:**
- Review documentation
- Quality assurance for content
- Pre-publication review

**Invoke:** `/editor-in-chief`

---

### mermaid-diagram

**Category:** Content
**Priority:** Tier 4

**Purpose:**
Generate Mermaid diagrams for documentation and architecture.

**Key Features:**
- Multiple diagram types (flowchart, sequence, class, etc.)
- Syntax validation
- Style customization
- Documentation integration
- Export options

**Configuration Required:**
- Diagram output directory
- Style preferences

**Use Cases:**
- Create architecture diagrams
- Document workflows
- Visualize systems

**Invoke:** `/mermaid-diagram`

---

### add-content-image

**Category:** Content
**Priority:** Tier 4

**Purpose:**
Image handling and optimization for content.

**Key Features:**
- Image optimization
- Alt text generation
- Responsive image variants
- Asset organization
- Format conversion

**Configuration Required:**
- Image directory
- Optimization settings

**Use Cases:**
- Add images to documentation
- Optimize media assets
- Manage content images

**Invoke:** `/add-content-image`

---

### regenerate-course-content

**Category:** Content
**Priority:** Tier 4

**Purpose:**
Generate and update course or educational content.

**Key Features:**
- Course structure generation
- Learning objective alignment
- Content templating
- Assessment creation
- Progress tracking

**Configuration Required:**
- Course structure path
- Content templates

**Use Cases:**
- Create course materials
- Update educational content
- Generate learning resources

**Invoke:** `/regenerate-course-content`

---

### create-adr

**Category:** Documentation
**Priority:** Tier 4

**Purpose:**
Create Architecture Decision Records (ADR) for documenting technical decisions.

**Key Features:**
- ADR template usage
- Decision context capture
- Alternative analysis
- Consequence documentation
- Decision linking

**Configuration Required:**
- ADR directory
- Template format

**Use Cases:**
- Document architecture decisions
- Track technical choices
- Maintain decision history

**Invoke:** `/create-adr`

---

### gather-nfr

**Category:** Documentation
**Priority:** Tier 4

**Purpose:**
Gather and document non-functional requirements.

**Key Features:**
- NFR categories (performance, security, etc.)
- Requirement templates
- Acceptance criteria
- Testability analysis
- Priority ranking

**Configuration Required:**
- NFR templates path
- Requirement categories

**Use Cases:**
- Define system requirements
- Quality attribute specification
- Architecture constraints

**Invoke:** `/gather-nfr`

---

### claude:hooks

**Category:** Configuration
**Priority:** Tier 4

**Purpose:**
Configure and manage Claude Code hooks for workflow automation.

**Key Features:**
- Hook template generation
- Pre-commit validation
- Post-commit automation
- Hook testing
- Team hook distribution

**Configuration Required:**
- Hooks directory
- Validation rules

**Use Cases:**
- Enforce commit standards
- Automate pre-commit checks
- Standardize team workflow

**Invoke:** `/hooks`

---

### github:story-quality

**Category:** Quality
**Priority:** Tier 2

**Purpose:**
Analyze GitHub Project stories for SMART acceptance criteria and NFR coverage. Applies labels and posts structured feedback comments.

**Key Features:**
- SMART analysis (Specific, Measurable, Achievable, Relevant, Time-bound)
- NFR cross-referencing against registry
- Automated label management (needs-acs, needs-nfrs, needs-refinement, ready-for-development)
- Structured feedback comments with actionable gaps
- Scheduled and manual execution modes
- NFR registry auto-update from detected patterns

**Configuration Required:**
- Repository slug
- Active story file path
- NFR registry file path
- GitHub Project owner and number

**Use Cases:**
- Validate story readiness before development
- Enforce acceptance criteria quality standards
- Ensure NFR coverage across stories
- Automated story refinement feedback

**Invoke:** `/github:story-quality`

---

## Using Skills

To use any skill:

1. **Copy to your project:**
   ```bash
   cp -r .claude/skills/<skill-name>/ /path/to/your/project/.claude/skills/
   ```

2. **Configure:**
   ```bash
   cd .claude/skills/<skill-name>/
   cp config.example.yaml config.yaml
   # Edit config.yaml with your values
   ```

3. **Invoke:**
   ```
   /<skill-name>
   ```

For detailed usage, see [USAGE_GUIDE.md](USAGE_GUIDE.md).

For configuration details, see each skill's `SKILL.md` and [docs/configuration-reference.md](docs/configuration-reference.md).
