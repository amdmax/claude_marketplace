---
name: "ai-adoption:learn"
description: "Discover skills in this marketplace that match your workflow. Accepts a workload or task description, scans all released skills, and recommends the best matches with install commands. Use when users ask 'what skills are available', 'find a skill for X', 'which skill helps me with Y', 'what can I install', or 'recommend skills for my workflow'."
tools:
  - Bash
  - Read
---

# ai-adoption:learn

Helps users discover and adopt skills from this marketplace by matching their workflow to the right skills.

## Purpose

Scan all skills in the marketplace, reason about the user's workload, and surface the best-fit skills with ready-to-run install commands.

## Workflow

### Step 1 — Capture workload

If the user provided a description in the invocation args, use it directly.
If not, ask: **"Describe the workflow or task you want help with."**

### Step 2 — Discover all skills

Run this to extract name, description, and bundle from every skill in the marketplace:

```bash
MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces/thesolutionarchitect_marketplace/bundles"
find "$MARKETPLACE_DIR" -name "SKILL.md" | while read f; do
  bundle=$(echo "$f" | sed "s|$MARKETPLACE_DIR/\([^/]*\)/.*|\1|")
  skill=$(grep '^name:' "$f" | head -1 | sed 's/name: *//' | tr -d '"')
  desc=$(grep '^description:' "$f" | head -1 | sed 's/description: *//' | tr -d '"')
  echo "BUNDLE=$bundle | SKILL=$skill | DESC=$desc"
done
```

If the marketplace directory doesn't exist at that path, fall back to the current repo:

```bash
REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null)/bundles"
find "$REPO_DIR" -name "SKILL.md" | while read f; do
  bundle=$(echo "$f" | sed "s|$REPO_DIR/\([^/]*\)/.*|\1|")
  skill=$(grep '^name:' "$f" | head -1 | sed 's/name: *//' | tr -d '"')
  desc=$(grep '^description:' "$f" | head -1 | sed 's/description: *//' | tr -d '"')
  echo "BUNDLE=$bundle | SKILL=$skill | DESC=$desc"
done
```

### Step 3 — Match skills to workload

Reason over the discovered skill list and the user's workload description. Select the **top 3–5 best-fit skills**. Consider:

- Semantic overlap between the workload and the skill description
- Skills that complement each other for the same workflow
- Prefer specific skills over broad ones when the workload is specific

### Step 4 — Present results

For each matched skill, output:

```
**<skill-name>**
<one-sentence description of what it does>
Bundle: `<bundle-name>`
Install: `/plugin install <bundle-name>@thesolutionarchitect_marketplace`
```

List matches ranked by relevance (best first). After the list, ask:
> "Want me to install any of these? Just say which one."

### Step 5 — Install on confirmation (optional)

If the user confirms installation, output the install command for them to run. Do NOT run `/plugin install` yourself — it is a Claude Code CLI command, not a shell command.

Tell the user: **"Run this in your Claude Code prompt: `/plugin install <bundle>@thesolutionarchitect_marketplace`"**

## Validation

- At least one skill must be returned from Step 2; if the find command returns nothing, report the error and the path checked.
- Present a minimum of 1 match even if confidence is low — state the confidence.
- Never invent skills that aren't in the discovered list.

## Exceptions

- If the marketplace directory is missing and there is no git repo, inform the user and suggest they add the marketplace first: `/plugin marketplace add amdmax/claude_marketplace`
- If the user's workload is too vague, ask one clarifying question before matching.
