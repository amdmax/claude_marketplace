# Claude Code Skills Marketplace

This repo is a **custom Claude Code plugin marketplace** — a centralized collection of reusable skills installable via the Claude Code `/plugin` system.

## What Is This Repo?

`amdmax/claude_marketplace` is registered as a marketplace source in Claude Code. Users add it once and install individual skill bundles:

```bash
/plugin marketplace add amdmax/claude_marketplace
/plugin install github@thesolutionarchitect_marketplace
```

## Repo Structure

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace manifest — lists all bundles and their `./bundles/<name>` paths |
| `bundles/<bundle-name>/` | Each installable plugin: has `.claude-plugin/plugin.json` + `skills/` |
| `bundles/<bundle-name>/skills/<skill-name>` | **Single source of truth** for skill content — no other copies exist |
| `agents/` | Agent definition markdown files |
| `.claude/commands/` | Claude Code slash commands |
| `hooks/` | Claude Code hook scripts |

## Bundles

| Bundle | Skills | Description |
|--------|--------|-------------|
| `git` | `git:commit` | Local git operations — commit with configurable numbering and message conventions |
| `github` | `github:actions`, `github:issue-create`, `github:edit-workflow`, `github:merge-chores`, `github:mermaid-diagram`, `github:pull-request`, `github:runner-setup`, `github:story-create`, `github:story-fetch`, `github:story-finalize`, `github:story-play`, `github:story-quality`, `github:tidy-board`, `github:until-green` | GitHub-hosted workflow — issues, PRs, CI loops, story lifecycle, board management, runner setup, sequential chore merging, and Mermaid diagrams |
| `development-tools` | `bug-fix`, `debug`, `experimentator`, `jupyter-remote` | Developer utilities — debugging, experimentation, remote notebooks |
| `cc` | `cc:hooks`, `cc:output-style`, `cc:plugin-scaffold`, `cc:refactor-skill`, `cc:skill-creator`, `cc:sync-skills`, `cc:validate-skills` | Claude Code meta-skills — hooks, output styles, plugin scaffolding, skill creation, refactoring, syncing, and validation |
| `architect` | `arch:adr-render`, `arch:adr-yaml`, `arch:asyncapi-contract`, `arch:create-adr`, `arch:design-implementation`, `arch:design-review`, `arch:fitness-function`, `arch:gather-nfr`, `arch:implementation-plan`, `arch:maintain-constraints-registry`, `arch:maintain-nfr-registry`, `arch:maintain-risk-registry`, `arch:openapi-contract`, `review:code`, `review:compliance`, `review:overall`, `review:performance`, `review:security` | Architecture guidance and code quality — ADRs, story design lifecycle, API/event contracts, implementation planning, design review, NFR gathering, reviews, fitness functions, registries |
| `aws` | `aws:architect`, `aws:cdk`, `aws:cdk-validate` | AWS infrastructure — architect guidance, CDK, CDK validation |
| `content-specialized` | `creative-writing`, `cuda-remote-manager`, `editor-in-chief`, `regenerate-course-content`, `reveal-pdf-export` | Content creation and specialized tools — writing, documentation, CUDA |
| `design` | `add-content-image`, `css-architecture`, `design-system`, `ux-professional` | Design tools — CSS architecture, design systems, UX, content images |
| `mobile` | `mobile:android:test`, `mobile:ios:test` | Mobile testing — Android (Chromium) and iOS (WebKit) layout test automation |
| `agile-team` | `agent:architect`, `agent:backend-dev`, `agent:devops`, `agent:frontend-dev`, `agent:test-architect`, `pm`, `pm:build`, `pm:pull-request`, `scout:gather-context`, `scout:prepare-for-dev`, `team:agile-dev` | Agile dev team — full 5-agent TDD team or individual agents for controlled, single-agent delegation; `/pm build` orchestrates a fleet of specialist agents driven by the architect's implementation plan; `/pm:pull-request` routes PR creation to the active issue tracker |

## How Skill Resolution Works

1. Claude Code reads `.claude-plugin/marketplace.json` → finds bundle sources at `./bundles/<name>`
2. On install, it copies `bundles/<bundle>/` to the plugin cache (`~/.claude/plugins/cache/`)
3. Each `bundles/<bundle>/skills/<name>` is a **real directory copy** of the skill content
4. Canonical skill source lives in `.claude/skills/<name>/` and `skills/<name>/` (published copy)

## Skill Authoring Rules

**Least privilege is mandatory.** Every skill must declare its allowed tools explicitly in the SKILL.md frontmatter. Never use a wildcard or omit the tools list. Grant only the tools the skill actually needs.

`name` and `description` are required in every skill frontmatter.

```yaml
---
name: "namespace:skill-name"
description: "One-sentence description of what this skill does."
tools:
  - Read
  - Grep
  - Bash
---
```

If a skill requires broader access, justify it in a comment inside the frontmatter block.

## Adding a New Skill

1. Create `bundles/<bundle>/skills/<namespace>:<name>/SKILL.md` directly in the appropriate bundle
2. Declare allowed tools explicitly (least privilege — no wildcards)
3. Update the bundle's `plugin.json` description and skill count
4. Update `CLAUDE.md` bundles table
5. Commit and push — marketplace auto-updates for users with `autoUpdate: true`

## Local Development

The marketplace install location symlinks here:
```
~/.claude/plugins/marketplaces/thesolutionarchitect_marketplace → <this repo>
```

To test changes locally, edit skills directly in `bundles/<bundle>/skills/<name>/`. No sync step needed — bundles are the single source of truth.
