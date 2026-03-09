# Research Strategies Reference

Investigation techniques for each hypothesis type, including step-by-step processes, search patterns, and when to stop.

## General Research Principles

1. **Start with High-Confidence Hypotheses**
   - Process hypotheses in order: high → medium → low confidence
   - Confirming a high-confidence hypothesis saves time

2. **Collect Evidence Systematically**
   - Record every finding with file path and line number
   - Note both supporting and contradicting evidence
   - Use the hypothesis tracker to maintain state

3. **Know When to Stop**
   - CONFIRMED: Strong evidence supports hypothesis (proceed to fix)
   - REJECTED: Evidence contradicts hypothesis (move to next)
   - NEEDS_INFO: Insufficient data (generate sub-hypotheses or ask user)

4. **Avoid Rabbit Holes**
   - Set time limits for each hypothesis investigation
   - If stuck after 3-4 search attempts, mark as needs_info
   - Don't over-investigate low-confidence hypotheses

## Research Strategies by Type

### logic_error

**Characteristics:**
- Wrong comparison operators (>, <, >=, <=)
- Off-by-one errors in loops or array access
- Incorrect boolean logic (AND vs OR)
- Flawed calculations or algorithms

**Step-by-Step Investigation:**

1. **Locate the Suspicious Code**
   ```bash
   # Extract function/method names from error messages
   # Example error: "validateToken failed at line 45"

   # Search for the function
   grep -rn "validateToken" --include="*.ts" --include="*.js"
   ```

2. **Read with Context**
   ```bash
   # Read the file with surrounding lines
   # Use Read tool with the file path
   # Focus on ±20 lines around suspicious code
   ```

3. **Check Recent Changes**
   ```bash
   # See who last modified this code
   git blame <file-path>

   # Check recent commits touching this file
   git log -p --follow -n 5 -- <file-path>
   ```

4. **Look for Similar Patterns**
   ```bash
   # Find similar comparison patterns
   grep -rn "if.*>.*now" --include="*.ts"
   grep -rn "if.*exp.*>" --include="*.ts"
   ```

5. **Verify Against Specs**
   - Check documentation (README, API docs, comments)
   - Look for related test cases
   - Compare with similar functions in codebase

**Evidence to Collect:**
- Exact code location (file:line)
- The suspicious operator/logic
- Expected behavior from docs/specs
- Similar correct implementations
- Recent commits that modified this code

**Example Evidence Recording:**
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-evidence \
  "h1" \
  "src/auth/token.ts" \
  45 \
  "Found: if (exp > now) return true; RFC 7519 requires rejection AT expiration (>=)"
```

**Confirmation Criteria:**
- ✅ Found the exact logical error
- ✅ Verified expected behavior from documentation
- ✅ Can explain why current logic fails

**Rejection Criteria:**
- ❌ Logic is correct as written
- ❌ Error occurs elsewhere
- ❌ No logical flaws found after thorough review

---

### missing_validation

**Characteristics:**
- Missing null/undefined checks
- No input bounds checking
- Unhandled error paths
- Missing type validation
- No sanitization of user input

**Step-by-Step Investigation:**

1. **Identify Input Points**
   ```bash
   # Find function parameters and their usage
   grep -rn "function.*<function-name>" --include="*.ts"

   # Look for input validation patterns
   grep -rn "if.*null" <file-path>
   grep -rn "throw new Error" <file-path>
   ```

2. **Compare with Similar Functions**
   ```bash
   # Find similar functions that DO validate
   grep -rn "function validate" --include="*.ts"

   # Check how other functions handle same input type
   grep -A 10 "function.*Token" --include="*.ts"
   ```

3. **Check Error Handling**
   ```bash
   # Look for try-catch blocks
   grep -B 5 -A 10 "try.*{" <file-path>

   # Check for error throwing
   grep -rn "throw" <file-path>
   ```

4. **Examine Test Coverage**
   ```bash
   # Find related tests
   find . -name "*.test.ts" -o -name "*.spec.ts"

   # Search for edge case tests
   grep -rn "null.*undefined.*empty" --include="*.test.ts"
   ```

5. **Look for TODOs**
   ```bash
   # Find validation-related TODOs
   grep -rn "TODO.*validat" --include="*.ts"
   grep -rn "FIXME.*check" --include="*.ts"
   ```

**Evidence to Collect:**
- Missing validation points (file:line)
- Similar functions with proper validation
- Test gaps (missing edge case tests)
- TODO comments about validation
- Error paths that aren't handled

**Example Evidence Recording:**
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-evidence \
  "h2" \
  "src/auth/token.ts" \
  42 \
  "No null check for token.exp field. Function validateEmail() at line 120 shows proper pattern"
```

**Confirmation Criteria:**
- ✅ Found missing validation/error handling
- ✅ Identified specific unchecked input
- ✅ Can point to correct validation pattern

**Rejection Criteria:**
- ❌ All inputs properly validated
- ❌ Error handling is sufficient
- ❌ Edge cases properly covered

---

### race_condition

**Characteristics:**
- Concurrent access to shared state
- Missing synchronization/locks
- Async/await issues
- Event ordering problems
- Timing-dependent behavior

**Step-by-Step Investigation:**

1. **Identify Shared State**
   ```bash
   # Find class/module variables
   grep -rn "this\." <file-path>
   grep -rn "let.*=.*\[\]" <file-path>
   grep -rn "const.*Map\|Set\|Array" <file-path>
   ```

2. **Check Async Patterns**
   ```bash
   # Find async functions
   grep -rn "async function" --include="*.ts"

   # Look for missing await
   grep -B 3 -A 3 "async.*{" <file-path> | grep -v "await"

   # Check Promise usage
   grep -rn "Promise\|.then(" <file-path>
   ```

3. **Examine Event Ordering**
   ```bash
   # Find event listeners
   grep -rn "addEventListener\|on(" --include="*.ts"

   # Check for race-prone patterns
   grep -rn "setTimeout\|setInterval" <file-path>
   ```

4. **Review Concurrent Tests**
   ```bash
   # Find tests that might expose races
   grep -rn "concurrent\|parallel\|Promise.all" --include="*.test.ts"
   ```

5. **Check for Locks/Synchronization**
   ```bash
   # Look for synchronization primitives
   grep -rn "mutex\|lock\|semaphore" --include="*.ts"
   ```

**Evidence to Collect:**
- Unprotected shared state access (file:line)
- Missing await keywords
- Concurrent operations without synchronization
- Event ordering assumptions
- Timing-dependent code

**Example Evidence Recording:**
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-evidence \
  "h3" \
  "src/auth/session.ts" \
  67 \
  "sessions Map accessed without lock. Line 45 writes, line 67 reads - potential race"
```

**Confirmation Criteria:**
- ✅ Found concurrent access to shared resource
- ✅ No synchronization mechanism present
- ✅ Can reproduce timing-dependent failure

**Rejection Criteria:**
- ❌ No shared state involved
- ❌ Proper synchronization already in place
- ❌ Operations are sequential, not concurrent

---

### configuration

**Characteristics:**
- Wrong default values
- Missing environment variables
- Configuration not loaded
- Environment-specific bugs
- Hardcoded values

**Step-by-Step Investigation:**

1. **Check Environment Variables**
   ```bash
   # Find env var usage
   grep -rn "process.env" --include="*.ts"
   grep -rn "process.env" --include="*.js"

   # Look for .env files
   find . -name ".env*" -o -name "*.env"
   ```

2. **Examine Configuration Files**
   ```bash
   # Find config files
   find . -name "config.*" -o -name "*.config.*"

   # Read configuration
   # Use Read tool for: config.ts, .env.example, etc.
   ```

3. **Compare Environments**
   ```bash
   # Look for environment-specific code
   grep -rn "NODE_ENV\|ENVIRONMENT" --include="*.ts"
   grep -rn "if.*production\|development" --include="*.ts"
   ```

4. **Check Defaults**
   ```bash
   # Find default value assignments
   grep -rn "||.*default\|??.*default" <file-path>
   grep -rn "= config.get" --include="*.ts"
   ```

5. **Review Config Documentation**
   - Check README for required env vars
   - Look for .env.example
   - Read config schema or validation

**Evidence to Collect:**
- Missing config values (file:line)
- Wrong default values
- Environment-specific failures
- Hardcoded values that should be configurable
- Config loading issues

**Example Evidence Recording:**
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-evidence \
  "h4" \
  "src/config/auth.ts" \
  23 \
  "TOKEN_EXPIRY defaults to 3600, but .env.example shows 7200. Production may use different value"
```

**Confirmation Criteria:**
- ✅ Found missing or incorrect configuration
- ✅ Can verify expected vs actual config
- ✅ Configuration explains the bug

**Rejection Criteria:**
- ❌ All config values present and correct
- ❌ Defaults are appropriate
- ❌ Environment settings not involved in bug

---

### dependency

**Characteristics:**
- Breaking changes in dependencies
- Version mismatches
- Deprecated API usage
- Peer dependency conflicts
- Incompatible version ranges

**Step-by-Step Investigation:**

1. **Check Package Files**
   ```bash
   # Read package.json
   # Use Read tool for package.json

   # Check lock file for actual versions
   # Use Read tool for package-lock.json or yarn.lock
   ```

2. **Review Recent Updates**
   ```bash
   # Find recent dependency changes
   git log -p --follow -n 10 -- package.json

   # Check when dependency was updated
   git blame package.json | grep "<package-name>"
   ```

3. **Examine CHANGELOGs**
   ```bash
   # Look for breaking changes
   # Check node_modules/<package>/CHANGELOG.md

   # Or search online for changelog
   # Use WebSearch for "<package> <version> changelog breaking changes"
   ```

4. **Search for Deprecated Usage**
   ```bash
   # Find usage of deprecated APIs
   grep -rn "<deprecated-method>" --include="*.ts"

   # Check for compatibility notes
   grep -rn "@deprecated" node_modules/<package>/
   ```

5. **Check Version Compatibility**
   ```bash
   # Look for version-specific imports
   grep -rn "import.*from.*<package>" --include="*.ts"

   # Check peer dependency warnings
   npm list <package>
   ```

**Evidence to Collect:**
- Dependency version changes (git log)
- Breaking change documentation
- Deprecated API usage (file:line)
- Version incompatibilities
- Peer dependency conflicts

**Example Evidence Recording:**
```bash
.claude/skills/debug/scripts/hypothesis-tracker.py add-evidence \
  "h5" \
  "package.json" \
  42 \
  "jwt-decode updated from 3.1.2 to 4.0.0. v4 CHANGELOG shows decode() signature changed"
```

**Confirmation Criteria:**
- ✅ Found breaking change in dependency
- ✅ Code uses old/deprecated API
- ✅ Version update timeline matches bug appearance

**Rejection Criteria:**
- ❌ Dependencies haven't changed recently
- ❌ No breaking changes in versions used
- ❌ Code uses current API correctly

---

## Research Depth Configuration

Based on `config.yaml` settings:

### "quick" Depth
- Single search per hypothesis
- Check only primary file
- Skip git history
- 10 minutes max per hypothesis

### "thorough" Depth (Default)
- Multiple search strategies
- Read related files
- Check git blame/log
- Compare with similar code
- 20-30 minutes per hypothesis

### "exhaustive" Depth
- Deep codebase analysis
- Full git history review
- Check all similar patterns
- Review all related tests
- Read documentation
- 45+ minutes per hypothesis

## When to Stop Investigating

### Hypothesis CONFIRMED
Stop when you have:
- Clear evidence of root cause
- Can explain bug mechanism
- Can design a fix
- 2+ pieces of supporting evidence

### Hypothesis REJECTED
Stop when:
- Evidence contradicts hypothesis
- Root cause must be elsewhere
- Cannot find supporting evidence after thorough search
- 3-4 search strategies yield nothing

### Hypothesis NEEDS_INFO
Stop when:
- Need more context from user
- Require access to external systems
- Need to run code/tests first
- Require domain knowledge

Mark as `needs_info` and:
- Generate sub-hypotheses if possible
- Ask user specific questions
- Note what information is needed
