# Hypothesis Tracking Reference

Complete reference for debug session state management, hypothesis lifecycle, and script operations.

## State File Schema

The `.claude/active-debug.json` file maintains the complete state of a debug session.

### Root Structure

```json
{
  "issueNumber": 123,
  "title": "Authentication fails with expired tokens",
  "url": "https://github.com/owner/repo/issues/123",
  "sessionId": "debug-123-20260202-143022",
  "status": "investigating" | "fixed" | "blocked",
  "currentPhase": "hypothesis_generation" | "research" | "fix_implementation" | "test_generation" | "commit_and_pr",
  "hypotheses": [...],
  "fix": {...},
  "tests": {...},
  "createdAt": "2026-02-02T14:30:22.000Z",
  "updatedAt": "2026-02-02T15:45:10.000Z"
}
```

### Hypothesis Object

```json
{
  "id": "h1",
  "description": "Token expiration check uses > instead of >=",
  "type": "logic_error",
  "confidence": "high" | "medium" | "low",
  "status": "pending" | "investigating" | "confirmed" | "rejected" | "needs_info",
  "evidence": [
    {
      "file": "src/auth/token.ts",
      "line": 45,
      "note": "Found comparison: if (exp > now) return true",
      "timestamp": "2026-02-02T14:35:00.000Z"
    }
  ],
  "researchNotes": "Additional context or observations",
  "createdAt": "2026-02-02T14:30:22.000Z",
  "updatedAt": "2026-02-02T14:35:00.000Z",
  "confirmedAt": "2026-02-02T14:40:00.000Z"
}
```

### Fix Object

```json
{
  "files": "src/auth/token.ts",
  "description": "Change comparison from > to >= on line 45",
  "implementedAt": "2026-02-02T14:45:00.000Z"
}
```

### Tests Object

```json
{
  "files": "src/auth/__tests__/token.test.ts",
  "description": "Added 4 test cases covering expiration scenarios",
  "count": 4,
  "validated": true,
  "createdAt": "2026-02-02T14:50:00.000Z",
  "validatedAt": "2026-02-02T14:55:00.000Z"
}
```

## Hypothesis Types

### logic_error
**Description:** Wrong condition, off-by-one error, incorrect operator, flawed algorithm

**Research Strategy:**
- Grep for function/method names from error messages
- Read code with context (±20 lines)
- Check git blame for recent changes
- Look for similar patterns in codebase
- Verify against specifications/documentation

**Evidence Examples:**
- Incorrect comparison operator (>, <, >=, <=)
- Off-by-one in loop bounds or array access
- Wrong boolean logic (AND vs OR)
- Incorrect calculation or formula

### missing_validation
**Description:** No input checks, missing error handling, unhandled edge cases

**Research Strategy:**
- Search for validation patterns in similar functions
- Check error handling paths
- Compare with other input processing code
- Examine test coverage gaps
- Look for TODOs or FIXMEs

**Evidence Examples:**
- Missing null/undefined checks
- No bounds checking
- Unhandled exception paths
- Missing type validation

### race_condition
**Description:** Concurrent access issues, timing problems, async bugs

**Research Strategy:**
- Identify shared state/resources
- Look for async/await usage
- Check for proper locking/synchronization
- Examine event ordering assumptions
- Review concurrent test failures

**Evidence Examples:**
- Unprotected shared state
- Missing await keywords
- Callback ordering issues
- Race between initialization and usage

### configuration
**Description:** Wrong defaults, missing environment variables, config mismatches

**Research Strategy:**
- Check configuration files and defaults
- Examine environment variable usage
- Compare dev vs prod settings
- Review configuration documentation
- Check for environment-specific code

**Evidence Examples:**
- Missing .env variables
- Wrong default values
- Config not loaded in certain environments
- Hardcoded values that should be configurable

### dependency
**Description:** Version mismatch, breaking changes, API incompatibilities

**Research Strategy:**
- Check package.json and lock files
- Review recent dependency updates
- Examine CHANGELOG of dependencies
- Look for deprecated API usage
- Check for version-specific behavior

**Evidence Examples:**
- Breaking change in minor/patch version
- API removed or changed signature
- Peer dependency conflicts
- Incompatible version ranges

## Hypothesis Lifecycle

```
┌─────────┐
│ pending │ ← Initial state when hypothesis created
└────┬────┘
     │
     ↓ (Research begins)
┌──────────────┐
│investigating │ ← Actively collecting evidence
└──────┬───────┘
       │
       ├─→ CONFIRMED ──→ ┌───────────┐
       │                 │ confirmed │ → Proceed to fix
       │                 └───────────┘
       │
       ├─→ REJECTED ───→ ┌──────────┐
       │                 │ rejected │ → Try next hypothesis
       │                 └──────────┘
       │
       └─→ NEEDS INFO → ┌────────────┐
                        │ needs_info │ → Generate sub-hypotheses or ask user
                        └────────────┘
```

## Phase Transitions

```
hypothesis_generation
  ↓ (Hypotheses created)
research
  ↓ (Hypothesis confirmed)
fix_implementation
  ↓ (Fix recorded)
test_generation
  ↓ (Tests validated)
commit_and_pr
  ↓ (PR created)
COMPLETE → Archive session
```

## Script Commands Reference

### Session Management

#### Initialize Session
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py init <issue-number> "<title>" [<url>]
```
- Creates `.claude/active-debug.json`
- Fails if session already exists
- Generates unique session ID

#### Check Status
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py status
```
- Displays current session state
- Shows all hypotheses with status icons
- Indicates fix and test status

#### Archive Session
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py archive
```
- Moves state to `.claude/debug-sessions/`
- Removes `.claude/active-debug.json`
- Adds `archivedAt` timestamp

### Hypothesis Operations

#### Add Hypothesis
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-hypothesis \
  "<description>" \
  "<type>" \
  "<confidence>"
```
- `type`: logic_error | missing_validation | race_condition | configuration | dependency
- `confidence`: high | medium | low
- Auto-generates hypothesis ID (h1, h2, h3...)

#### Update Status
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py update-status <h-id> <status>
```
- `status`: pending | investigating | confirmed | rejected | needs_info
- Updates timestamp

#### Add Evidence
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-evidence \
  <h-id> \
  "<file-path>" \
  <line-number> \
  "<note>"
```
- Appends to evidence array
- Records timestamp
- Line number must be integer

#### Mark Confirmed
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py mark-confirmed <h-id>
```
- Sets hypothesis to "confirmed"
- Auto-rejects all other non-confirmed hypotheses
- Transitions phase to "fix_implementation"

#### Get Next Hypothesis
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py get-next-hypothesis
```
- Returns highest-confidence pending hypothesis
- Output: JSON object with id, description, type, confidence
- Exit code 1 if no pending hypotheses

#### List Hypotheses
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py list-hypotheses [<status>]
```
- Lists all hypotheses (or filtered by status)
- Output: JSON array
- Includes evidence count

### Fix and Test Tracking

#### Record Fix
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py set-fix \
  "<file-paths>" \
  "<description>"
```
- Records fix implementation details
- Transitions phase to "test_generation"
- Sets `implementedAt` timestamp

#### Record Tests
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py set-tests \
  "<file-paths>" \
  "<description>" \
  <test-count>
```
- Records test creation
- Sets `validated: false` initially
- Test count must be integer

#### Mark Tests Validated
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py mark-tests-validated
```
- Sets `validated: true`
- Adds `validatedAt` timestamp
- Transitions phase to "commit_and_pr"
- Changes status to "fixed"

## State Transition Rules

1. **Session Creation**
   - Must not have existing active session
   - Issue number must be valid integer
   - Creates with phase "hypothesis_generation"

2. **Hypothesis Confirmation**
   - Only one hypothesis can be confirmed
   - Confirming auto-rejects others
   - Transitions to "fix_implementation" phase

3. **Fix Recording**
   - Can only record fix after hypothesis confirmed
   - Transitions to "test_generation" phase

4. **Test Validation**
   - Cannot validate without tests recorded
   - Validation is mandatory before commit
   - Transitions to "commit_and_pr" phase

5. **Session Completion**
   - Archive only when ready
   - Preserves all state in archive
   - Clears active session

## Error Handling

### Exit Codes
- `0`: Success
- `1`: Error (see stderr for details)

### Common Errors
- "No active debug session" → Run `init` first
- "Active debug session already exists" → Run `archive` first
- "Invalid hypothesis type" → Use valid type from list
- "Hypothesis not found" → Check hypothesis ID
- "Invalid line number" → Must be integer

## Integration with /commit Skill

The debug skill creates `.agile-dev-team/active-story.json` for `/commit` integration:

```json
{
  "issueNumber": 123,
  "title": "Authentication fails with expired tokens",
  "url": "https://github.com/owner/repo/issues/123"
}
```

This enables:
- AIGCODE-123 numbering for fix commit
- AIGCODE-123a numbering for test commit
- "Fixes #123" reference in commit message
