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
| `bundles/<bundle-name>/skills/<skill-name>` | Symlink → `../../.claude/skills/<actual-name>` (real content lives in `.claude/skills/`) |
| `.claude/skills/<name>/` | Canonical skill source — `SKILL.md` and supporting files |
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
3. Each `bundles/<bundle>/skills/<name>` is a **symlink** to the real skill in `.claude/skills/`
4. This means editing `.claude/skills/<name>/SKILL.md` updates all bundles referencing it

## Adding a New Skill

1. Create `.claude/skills/<namespace>:<name>/SKILL.md`
2. Add an empty dir (then symlink) in the appropriate `bundles/<bundle>/skills/<name>`
3. Update the bundle's `plugin.json` description if needed
4. Commit and push — marketplace auto-updates for users with `autoUpdate: true`

## Local Development

The marketplace install location symlinks here:
```
~/.claude/plugins/marketplaces/thesolutionarchitect_marketplace → <this repo>
```

To test changes locally, edit skills in `.claude/skills/` — they resolve immediately via symlinks.
