---
name: marketplace:list
description: List all skills across every bundle in this marketplace, formatted as plugin | namespace | skill.
---

## Execution

1. Use the Glob tool with pattern `bundles/*/skills/*/SKILL.md` to find all skills.
2. For each result, extract:
   - **plugin**: the second path segment (e.g. `bundles/github/...` → `github`)
   - **skill dir**: the fourth path segment (e.g. `github:story-fetch`)
   - **namespace**: everything before the first `:` in the skill dir, or `-` if no `:`
   - **skill**: everything after the first `:`, or the full skill dir if no `:`
3. Sort by plugin, then skill dir.
4. Output as a markdown table:

```
| plugin | namespace | skill |
|--------|-----------|-------|
| ...    | ...       | ...   |
```

No additional commentary — table only.
