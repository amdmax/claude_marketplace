---
name: pm:pull-request
description: >
  Issue-tracker-agnostic PR router. Reads .agile-dev-team/project-config.yaml to
  determine issueTracker (github or gitlab) and delegates to /github:pull-request
  or /gitlab:pull-request. Defaults to github when config is absent or issueTracker
  is unset.
argument-hint: "[args passed through to the provider skill]"
disable-model-invocation: true
allowed-tools:
  - Skill
---

# PM: Pull Request — Issue Tracker Router

## Purpose

Thin router. Delegates PR creation to the correct provider skill based on `issueTracker` from project config. No PR logic here.

## Project config

!`bash "${CLAUDE_SKILL_DIR}/preamble.sh"`

## Routing

Read `issueTracker` from the injected project config above, then:

| `issueTracker` | Delegate to | Notes |
|----------------|-------------|-------|
| `github` | `/github:pull-request` | Default |
| `gitlab` | `/gitlab:pull-request` | Requires gitlab bundle |
| _(other)_ | Abort with error | Print supported values |

### github (default)

Invoke `/github:pull-request` passing `$ARGUMENTS` unchanged.

### gitlab

Invoke `/gitlab:pull-request` passing `$ARGUMENTS` unchanged.

### Unrecognised tracker

```
❌ Unsupported issueTracker: "<value>"
Supported values: github, gitlab
Fix .agile-dev-team/project-config.yaml and retry.
```

## project-config.yaml schema

```yaml
# .agile-dev-team/project-config.yaml
issueTracker: github   # "github" | "gitlab"  (omit → defaults to "github")
```

**Behaviour when absent:** preamble outputs `issueTracker: github`, skill routes to GitHub.

## Error handling

| Condition | Behaviour |
|-----------|-----------|
| Config file missing | Preamble defaults to `github` |
| `issueTracker` missing/empty | Default to `github` |
| Unrecognised value | Abort with message listing valid values |
| GitLab bundle not installed | `/gitlab:pull-request` fails at resolution time |
