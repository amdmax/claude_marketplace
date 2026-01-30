# Skills Catalog

Complete index of all skills available in the Claude Code Skills Marketplace.

## Quick Reference

| Skill | Category | Description | Priority |
|-------|----------|-------------|----------|
| [commit](#commit) | Core Workflow | Automated commit creation with issue numbering | Tier 1 |
| [mr](#mr) | Core Workflow | Pull request creation with theme grouping | Tier 1 |
| [create-story](#create-story) | Core Workflow | GitHub issue creation | Tier 1 |
| [fetch-story](#fetch-story) | Core Workflow | Issue fetching and management | Tier 1 |
| [play-story](#play-story) | Core Workflow | Story workflow activation | Tier 1 |
| [bug-fix](#bug-fix) | Development | Bug fix workflow | Tier 2 |
| [skill-creator](#skill-creator) | Development | Create new skills | Tier 2 |
| [refactor-skill](#refactor-skill) | Development | Refactor existing skills | Tier 2 |
| [sync-skills](#sync-skills) | Development | Synchronize skills across projects | Tier 2 |
| [gather-context](#gather-context) | Development | Code exploration and context gathering | Tier 2 |
| [aws-architect](#aws-architect) | Architecture | AWS architecture guidance | Tier 3 |
| [cdk-scripting](#cdk-scripting) | Architecture | CDK infrastructure as code | Tier 3 |
| [security-review](#security-review) | Quality | Security code reviews | Tier 3 |
| [performance-review](#performance-review) | Quality | Performance analysis | Tier 3 |
| [overall-review](#overall-review) | Quality | General code reviews | Tier 3 |
| [fitness-function-architect](#fitness-function-architect) | Architecture | Architecture validation | Tier 3 |
| [css-architecture](#css-architecture) | Specialized | CSS architecture patterns | Tier 4 |
| [ux-professional](#ux-professional) | Specialized | UX guidance | Tier 4 |
| [creative-writing](#creative-writing) | Content | Content creation | Tier 4 |
| [editor-in-chief](#editor-in-chief) | Content | Editorial review | Tier 4 |
| [mermaid-diagram](#mermaid-diagram) | Content | Diagram generation | Tier 4 |
| [add-content-image](#add-content-image) | Content | Image handling | Tier 4 |
| [regenerate-course-content](#regenerate-course-content) | Content | Course content generation | Tier 4 |
| [create-adr](#create-adr) | Documentation | Architecture decision records | Tier 4 |
| [gather-nfr](#gather-nfr) | Documentation | Non-functional requirements | Tier 4 |
| [hooks](#hooks) | Configuration | Git hooks configuration | Tier 4 |

---

## Core Workflow Skills

### commit

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

### mr

**Category:** Core Workflow
**Priority:** Tier 1

**Purpose:**
Create pull requests with intelligent commit grouping by theme and comprehensive PR descriptions.

**Key Features:**
- Automatic commit theme detection
- Multi-theme PR grouping
- Branch management
- Merged/closed PR detection
- PR description generation
- Test plan creation

**Configuration Required:**
- Repository settings
- Default branch
- GitHub CLI configuration

**Use Cases:**
- Create focused, thematic PRs
- Handle complex multi-commit branches
- Generate comprehensive PR documentation

**Invoke:** `/mr`

---

### create-story

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

### fetch-story

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

### play-story

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

### skill-creator

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

**Invoke:** `/skill-creator`

---

### refactor-skill

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

**Invoke:** `/refactor-skill`

---

### sync-skills

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

**Invoke:** `/sync-skills`

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

### aws-architect

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

### cdk-scripting

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

### security-review

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

### performance-review

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

### overall-review

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

### fitness-function-architect

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

**Invoke:** `/fitness-function-architect`

---

## Content & Specialized Skills

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

### hooks

**Category:** Configuration
**Priority:** Tier 4

**Purpose:**
Configure and manage Git hooks for workflow automation.

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

## Using Skills

To use any skill:

1. **Copy to your project:**
   ```bash
   cp -r skills/<skill-name>/ /path/to/your/project/.claude/skills/
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
