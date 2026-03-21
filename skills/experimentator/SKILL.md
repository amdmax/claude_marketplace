---
name: experimentator
description: Orchestrates safe experiments and code changes in isolated git worktrees with background processing. Use when the user wants to try changes, experiment with code, test alternatives, or explore modifications without affecting main codebase. Triggers on phrases like "experiment with", "try out", "test in isolation", "worktree experiment".
allowed-tools: Bash(git:*), Task, AskUserQuestion, Read, Grep, Glob
---

# Experimentator Agent

Safely orchestrate experiments in isolated git worktrees with autonomous background processing.

## Core Workflow

### 1. Clarify & Validate (REQUIRED FIRST)
Before ANY work, use AskUserQuestion to resolve:
- Exact changes requested
- Scope and boundaries
- Expected outcomes
- Success criteria
- Any ambiguous requirements

**Never proceed with assumptions - always clarify first.**

### 2. Create Worktree (MANDATORY)
**CRITICAL: NEVER modify files without creating worktree first.**

```bash
# Check current state
git status
git worktree list

# Create isolated worktree
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
WORKTREE_PATH="../${PWD##*/}_experiment_${TIMESTAMP}"
git worktree add "$WORKTREE_PATH" -b "experiment/<descriptive-name>"

# Verify isolation
cd "$WORKTREE_PATH" && pwd
```

Default location: `../<project>_experiment_<timestamp>`
Default branch: `experiment/<descriptive-name>`

### 3. Execute in Background
Launch Task agents with `run_in_background: true` for:
- File modifications
- Code generation
- Testing
- Build processes
- Long-running tasks

**Run independent tasks in parallel** - use multiple background agents simultaneously.

### 4. Monitor & Report
- Track background agent completion using TaskOutput
- Collect all results
- Verify builds/tests
- Generate comprehensive summary

## Usage Patterns

**Color scheme experiment:**
```
User: "Try a dark blue theme"
→ Clarify: Which blue? Navy, royal, sky?
→ Create: ../project_experiment_20260106_143022
→ Background: Modify styles.css
→ Return: Preview ready with cleanup instructions
```

**Feature development:**
```
User: "Experiment with adding search functionality"
→ Clarify: Full-text? Filters? Which pages?
→ Create: ../project_experiment_20260106_143545
→ Background: Multiple agents for backend, frontend, tests
→ Return: Complete implementation with test results
```

**Architecture changes:**
```
User: "Try refactoring to TypeScript"
→ Clarify: All files or specific modules? Strict mode?
→ Create: ../project_experiment_20260106_144012
→ Background: Parallel conversion of independent files
→ Return: Migration report with issues identified
```

## Safety Rules

1. **MANDATORY: Worktree before changes** - No exceptions
2. **NEVER auto-commit** - Always ask user first
3. **Background preferred** - Minimize user interruption
4. **Clarify ambiguities** - Don't assume, ask
5. **Preserve isolation** - Don't touch main worktree
6. **Clean on failure** - Provide removal instructions

## Output Format

**After Clarification:**
```
Starting experiment in isolated worktree...

📁 Worktree: <PATH>
🌿 Branch: experiment/<NAME>
🎯 Tasks: <LIST>
⏱️  Running in background...
```

**Upon Completion:**
```
✅ Experiment complete!

📍 Location: <WORKTREE_PATH>
🌿 Branch: <BRANCH_NAME>

📝 Changes:
- <Change 1>
- <Change 2>

📊 Results:
- ✅ Build: Success
- ✅ Tests: 15/15 passed
- ⚠️ Warnings: 2 (see details)

🔍 Preview:
cd <WORKTREE_PATH>
python3 -m http.server 8000

📋 Next Steps:

Keep changes:
  cd <WORKTREE_PATH>
  git add .
  git commit -m "AIGWS-XXX <Description>"
  git push -u origin <BRANCH>

Discard:
  git worktree remove <WORKTREE_PATH>
  git branch -D <BRANCH>
```

## Worktree Naming

**Path format:** `../<project>_experiment_<timestamp>`
- Example: `../landing_page_experiment_20260106_143022`

**Branch format:** `experiment/<descriptive-name>`
- Example: `experiment/dark-theme`
- Example: `experiment/search-feature`
- Example: `experiment/typescript-migration`

## Error Handling

**Worktree creation fails:**
- Check for stale worktrees: `git worktree list`
- Suggest cleanup: `git worktree prune`

**Background agent fails:**
- Include error in final report
- Provide debugging context
- Suggest resolution steps

**Build/test failures:**
- Report specific failures
- Include logs
- Suggest fixes

## Key Reminders

- ⚠️ **WORKTREE FIRST** - Never skip this step
- 🚀 **BACKGROUND PROCESSING** - Default to background agents
- 💬 **CLARIFY UPFRONT** - Resolve ambiguities before starting
- 📦 **AUTONOMOUS** - Minimize interruptions during execution
- ✅ **SAFE** - Provide cleanup options, never auto-commit
- 🔄 **PARALLEL** - Run independent tasks concurrently

## Dependencies

Install in worktree if needed:
```bash
cd "$WORKTREE_PATH"
npm ci || npm install
```

Run builds:
```bash
npm run build
npm run test
```

## Example Invocations

Users can trigger this with:
- "Experiment with [change]"
- "Try [modification] in isolation"
- "Test out [feature] without affecting main code"
- "Create worktree to [task]"
- "Run experiment for [goal]"

The skill automatically activates based on semantic matching.
