# Claude Code Hooks

This directory contains automation hooks that run at various points in the Claude Code workflow.

## Active Hooks

### Session Lifecycle

#### `session-start.sh` (SessionStart)
Runs when a new Claude Code session starts. Displays project context and guidelines.

#### `pre-push.sh` (Stop)
Runs when the Claude Code session ends (`/stop` or exit). Validates all builds to catch errors before pushing to GitHub CI/CD.

**What it validates:**
1. **Content quality** - `npm run test:content` checks for em dashes in markdown files
2. **CSS linting** - `npm run lint:css` validates all CSS modules
3. **Main site build** - `npm run build` in project root (includes CSS concatenation & minification)
4. **Lambda builds** - `npm run build` in each `lambda/*/` directory
5. **Test count & coverage** - Ensures no test regressions via `npm run test:guard`
6. **CDK infrastructure** - `npx cdk synth` in `infrastructure/`

**Timeout:** 120 seconds (2 minutes)

### Code Modification

#### `format.sh` (PostToolUse: Edit|Write)
Auto-formats code after Edit/Write operations using Prettier (if configured).

#### `block-master-push.sh` (PreToolUse: Bash)
Blocks direct `git push` commands when on master/main branches. Enforces the "all changes via PR" policy with no exceptions.

**What it blocks:**
- Any `git push` command on master branch
- Any `git push` command on main branch

**Required workflow:**
1. Create feature branch: `git checkout -b feature/my-change`
2. Make changes and commit
3. Push feature branch: `git push -u origin feature/my-change`
4. Create PR: `/mr`

**No bypasses allowed.** This ensures consistent code review and CI validation for all changes.

#### `block-pr-merge.sh` (PreToolUse: Bash)
Blocks PR merge operations. Enforces human-only PR merging to ensure proper review and approval.

**What it blocks:**
- Any `gh pr merge` command
- Direct PR merge attempts via automation

**Why blocked:**
- PR merges require human judgment on timing and readiness
- Ensures all CI checks are verified by humans
- Requires explicit code review approval
- Prevents accidental premature merges

**Required workflow:**
1. Review PR on GitHub
2. Verify all CI checks pass
3. Get approvals from reviewers
4. Merge manually via GitHub UI or run `gh pr merge` yourself (not via Claude)

## Running Validations Manually

### Full pre-push validation

Run all build validations locally (same as Stop hook):

```bash
./.claude/hooks/pre-push.sh
```

**Output example:**
```
🚀 Pre-push validation (mirrors CI/CD pipeline)

🎨 Step 1/5: Linting CSS...
  ✅ Passed

📦 Step 2/5: Building main site...
  ✅ Passed

🔧 Step 3/5: Building Lambdas...
  → auth-edge...
    ✅ Passed
  → custom-message...
    ✅ Passed
  → referral...
    ✅ Passed

🧪 Step 3/4: Checking test count and coverage...
  ✅ Passed

☁️  Step 4/4: Validating CDK infrastructure...
  ✅ Passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ All validation steps PASSED

Safe to push to remote! 🎉
```

**Error logs:**
If a validation step fails, check the corresponding log file:
- Main site: `/tmp/site-build.log`
- Lambda: `/tmp/lambda-<name>-build.log`
- Test guard: `/tmp/test-guard.log` (or run `npm run test:guard` directly)
- CDK: `/tmp/cdk-synth.log`

### Individual validations

#### Main site build
```bash
npm run build
```

#### Lambda builds
```bash
# Specific Lambda
cd lambda/auth-edge
npm run build

# All Lambdas
for dir in lambda/*/; do (cd "$dir" && npm run build); done
```

#### Test guard validation
```bash
npm run test:guard
```

**Update baseline (after adding tests):**
```bash
npm run update-test-baseline
git add .test-metrics.json
git commit -m "Update test baseline"
```

**Note on unit tests:**

Unit tests for `scripts/test-guard.ts` are not included due to Jest's incompatibility with TypeScript ESM and `import.meta`. This is a known tooling limitation with ts-jest. The test guard functionality is comprehensively validated through:
- **Integration tests**: `npm run test:guard` (validates full workflow)
- **Pre-push hook**: `.claude/hooks/pre-push.sh` (validates before push)
- **Manual testing**: Baseline corruption, invalid metrics, edge cases

#### Infrastructure validation
```bash
cd infrastructure
npx cdk synth
```

### Manual pre-push hook validation

To ensure the pre-push hook works correctly after changes, verify:

**Integration checklist:**
- [ ] Hook script exists and is executable: `ls -la .claude/hooks/pre-push.sh`
- [ ] Script is registered in `.claude/settings.json` under `"Stop"` hooks
- [ ] All npm scripts exist: `npm run build`, `npm run test:guard`
- [ ] Script paths are correct: `scripts/test-guard.ts`, `scripts/update-test-baseline.ts`
- [ ] Log files are writable: `/tmp/site-build.log`, `/tmp/test-guard.log`, etc.
- [ ] Exit codes propagate correctly: Hook exits 1 on failure, 0 on success

**Functional test:**
```bash
# Test hook directly
./.claude/hooks/pre-push.sh

# Verify exit code
echo $?  # Should be 0 if all validations pass
```

**Test individual steps:**
```bash
# Step 1: Main site build
npm run build

# Step 2: Lambda builds
for LAMBDA_DIR in lambda/*/; do
  if [ -f "${LAMBDA_DIR}package.json" ]; then
    (cd "$LAMBDA_DIR" && npm run build)
  fi
done

# Step 3: Test guard
npm run test:guard

# Step 4: CDK synth
cd infrastructure && npx cdk synth
```

## Debugging Hook Issues

### View hook execution
Claude Code shows hook output in the terminal. Look for:
- `✅` - Hook passed
- `❌` - Hook failed (blocks operation)
- `⚠️` - Warning (non-blocking)

### Skip hooks temporarily
Set environment variable:
```bash
export CLAUDE_SKIP_HOOKS=1
```

### Hook environment variables
Hooks have access to:
- `CLAUDE_PROJECT_DIR` - Project root directory
- Standard shell variables (`PATH`, `HOME`, etc.)

## Hook Types

### Available hook types
- **SessionStart** - Runs when session begins
- **SessionEnd** - Runs when session ends (not used - Stop is preferred)
- **Stop** - Runs when user explicitly stops (`/stop`)
- **UserPromptSubmit** - Runs after user submits a prompt
- **PreToolUse** - Runs before a tool is executed
- **PostToolUse** - Runs after a tool is executed

### Matcher syntax
Hooks can match specific tools or patterns:
- `""` - Matches all (empty matcher)
- `"Edit|Write"` - Matches Edit OR Write tools
- `"Bash"` - Matches only Bash tool

## Maintenance

### Adding a new hook

1. Create script in `.claude/hooks/`:
   ```bash
   touch .claude/hooks/my-hook.sh
   chmod +x .claude/hooks/my-hook.sh
   ```

2. Add to `.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PostToolUse": [
         {
           "matcher": "Edit",
           "hooks": [
             {
               "type": "command",
               "command": ".claude/hooks/my-hook.sh"
             }
           ]
         }
       ]
     }
   }
   ```

3. Test the hook:
   ```bash
   echo '{"tool_input":{"file_path":"test.ts"}}' | .claude/hooks/my-hook.sh
   ```

### Hook best practices

1. **Exit codes:**
   - `0` - Success (continue)
   - `1` - Failure (block operation)
   - `2` - Warning (log but continue)

2. **Output:**
   - Write to stderr: `echo "message" >&2`
   - stdout is reserved for structured data

3. **Performance:**
   - Keep hooks fast (<5 seconds)
   - Use `timeout` setting for long-running hooks

4. **Error handling:**
   - Use `set -e` for fail-fast behavior
   - Provide clear error messages
   - Include troubleshooting hints

## Legacy Hooks

The following hooks are deprecated and no longer active:

- `lint-check.sh` - Replaced by `pre-push.sh` (comprehensive validation)
- `cdk-validate.sh` - Replaced by `pre-push.sh` (included in step 3)

These files remain for reference but are not called by Claude Code.
