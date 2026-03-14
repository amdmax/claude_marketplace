# github plugin

GitHub workflow skills for Claude Code.

## Skills

| Skill | Description |
|---|---|
| `github:actions` | Create and manage GitHub Actions composite actions |
| `github:create-issue` | Create high-quality, comprehensive GitHub issues |
| `github:pull-request` | Create pull requests with automatic commit handling |
| `github:runner-setup` | Configure GitHub Actions self-hosted runners on macOS |
| `github:story-create` | Quick GitHub issue creation for commit workflow |
| `github:story-fetch` | Fetch the next Ready story from GitHub Projects |
| `github:story-play` | Put a story "in play" by fetching from GitHub Projects |
| `github:story-quality` | Analyze GitHub Project stories for SMART acceptance criteria |
| `github:tidy-board` | Triage and organize GitHub Project boards |

## Installation

```bash
# Symlink individual skills into your project
cd /path/to/your/project/.claude/skills
ln -s ~/claude-marketplace/.claude/plugins/github/skills/github:pull-request github:pull-request
```
