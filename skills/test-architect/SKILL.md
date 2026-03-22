---
name: test-architect
description: TDD test planning and implementation for agile dev teams. Generates a structured per-story YAML test plan from an implementation brief, then writes failing tests (red phase) following codebase conventions. Escalates if no test plan exists before writing any code. Sub-commands: test-plan, implement-tests.
---

# test-architect Skill Package

This package contains sub-commands for the test-architect agent.

## Available Sub-Commands

| Command | File | Description |
|---------|------|-------------|
| `test-plan` | `test-plan.md` | Generate `.agile-dev-team/testing/{story_id}/test-plan.yaml` from the active story's implementation brief |
| `implement-tests` | `implement-tests.md` | Read the story's test plan and write all failing tests following codebase conventions |

## Invocation

```
/test-architect:test-plan
/test-architect:implement-tests
```

Or referenced from an agent definition:

```
invoke .claude/skills/test-architect/test-plan.md
invoke .claude/skills/test-architect/implement-tests.md
```
