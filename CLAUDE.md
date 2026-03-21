# Claude Code Skills Marketplace

This repo is a **custom Claude Code plugin marketplace** — a centralized collection of reusable skills installable via the Claude Code `/plugin` system.

## What Is This Repo?

`amdmax/claude_marketplace` is registered as a marketplace source in Claude Code. Users add it once and install individual skill bundles:

```bash
/plugin marketplace add amdmax/claude_marketplace
/plugin install core-workflow@thesolutionarchitect_marketplace
```

## Repo Structure

| Path | Purpose |
|------|---------|
| `.claude-plugin/marketplace.json` | Marketplace manifest — lists all bundles and their `./bundles/<name>` paths |
| `bundles/<bundle-name>/` | Each installable plugin: has `.claude-plugin/plugin.json` + `skills/` |
| `bundles/<bundle-name>/skills/<skill-name>` | Real copy of the skill content. Canonical source is `skills/<name>/` |
| `.claude/skills/<name>/` | Canonical skill source — `SKILL.md` and supporting files |
| `skills/<name>/` | Published copy of each skill (all bundles draw from here) |
| `agents/` | Agent definition markdown files |
| `commands/` | Claude Code slash commands |
| `hooks/` | Claude Code hook scripts |

## Bundles

| Bundle | Skills | Description |
|--------|--------|-------------|
| `core-workflow` | commit, create-story, fetch-story, mr, play-story | Git + GitHub workflow automation |
| `development-tools` | bug-fix, gather-context, refactor-skill, skill-creator, sync-skills | Dev utilities |
| `architecture-quality` | aws-architect, cdk-scripting, fitness-function-architect, overall-review, performance-review, security-review | Architecture + code quality |
| `content-specialized` | add-content-image, arch:create-adr, creative-writing, css-architecture, cuda-remote-manager, editor-in-chief, gather-nfr, github-runner-setup, hooks, mermaid-diagram, regenerate-course-content, reveal-pdf-export, ux-professional | Content + specialized tools |

## How Skill Resolution Works

1. Claude Code reads `.claude-plugin/marketplace.json` → finds bundle sources at `./bundles/<name>`
2. On install, it copies `bundles/<bundle>/` to the plugin cache (`~/.claude/plugins/cache/`)
3. Each `bundles/<bundle>/skills/<name>` is a **real directory copy** of the skill content
4. Canonical skill source lives in `.claude/skills/<name>/` and `skills/<name>/` (published copy)

## Adding a New Skill

1. Create `.claude/skills/<namespace>:<name>/SKILL.md`
2. Copy the skill dir into the appropriate `bundles/<bundle>/skills/<name>` (no symlinks)
3. Also copy it to `skills/<name>/` so it is published
4. Update the bundle's `plugin.json` description if needed
5. Commit and push — marketplace auto-updates for users with `autoUpdate: true`

## Local Development

The marketplace install location symlinks here:
```
~/.claude/plugins/marketplaces/thesolutionarchitect_marketplace → <this repo>
```

To test changes locally, edit skills in `.claude/skills/` then copy updated content to `bundles/` and `skills/`.
