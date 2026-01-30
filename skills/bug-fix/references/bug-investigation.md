# Bug Investigation Techniques

## Reading Bug Reports Effectively

### Extract Key Information

1. **Reproduction steps** - Exact sequence to trigger bug
2. **Expected behavior** - What should happen
3. **Actual behavior** - What actually happens
4. **Environment** - OS, browser, version, configuration
5. **Error messages** - Exact text of errors or stack traces
6. **Frequency** - Always, intermittent, specific conditions

### Example Bug Report Analysis

**Bug Report:**
```
Title: App crashes when uploading large files

Steps to reproduce:
1. Navigate to /upload
2. Select a file larger than 50MB
3. Click "Upload"
4. Page becomes unresponsive

Expected: File uploads with progress indicator
Actual: Page freezes, console shows "out of memory" error

Environment: Chrome 120, Windows 11, 8GB RAM
```

**Extracted information:**
- Trigger: Files > 50MB
- Location: /upload page
- Error: "out of memory"
- Likely cause: Memory constraint, no chunking
- Search terms: "upload", "memory", "large files", "chunking"

## Search Strategies

### Keyword Search

```bash
# Search for error messages
grep -r "out of memory" .

# Search for function names
grep -r "uploadFile\|handleUpload" .

# Search for related concepts
grep -r "file.*upload\|upload.*file" .
```

### File Pattern Search

```bash
# Find relevant files
find . -name "*upload*"
find . -name "*file*handler*"

# Search specific file types
find . -name "*.ts" -exec grep -l "upload" {} \;
```

### Git History Search

```bash
# Find commits mentioning upload
git log --all --grep="upload" --oneline

# Find changes to upload functionality
git log --all -- "*upload*"

# See what changed in specific time range
git log --since="2024-01-01" --until="2024-01-15" --oneline
```

## Stack Trace Analysis

### JavaScript Stack Trace

```
Error: Cannot read property 'data' of undefined
    at processFile (src/upload.ts:45:18)
    at handleUpload (src/handlers.ts:92:5)
    at onClick (src/components/Upload.tsx:34:7)
```

**Analysis:**
1. Start at top: `processFile` at line 45
2. Undefined property access: `something.data`
3. Check what could be undefined at that line
4. Trace back through call stack

### Reading Stack Traces

```typescript
// src/upload.ts:45
function processFile(file) {
  const size = file.data.length; // ← Line 45: crashes here
  // ...
}
```

**Diagnosis:** `file` or `file.data` is undefined. Check caller:

```typescript
// src/handlers.ts:92
async function handleUpload(event) {
  const file = await readFile(event); // ← Could return undefined
  processFile(file); // ← Passes undefined
}
```

**Root cause:** `readFile` can return `undefined` but no validation before `processFile`.

## Git Blame for Context

### When Bug Was Introduced

```bash
# See when line was last changed
git blame src/upload.ts -L 45,45

# Output shows commit and author
abc123def Author Name 2024-01-10 | const size = file.data.length;
```

### View That Commit

```bash
git show abc123def
```

**What to look for:**
- Was validation removed?
- Was error handling deleted?
- Did refactoring introduce the bug?
- Was there a merge conflict resolution?

## Binary Search for Regression

### When Did It Break?

```bash
# Start bisect
git bisect start

# Mark current as bad
git bisect bad

# Mark last known good version
git bisect good v1.2.0

# Git will checkout middle commit
# Test if bug exists, then mark:
git bisect bad  # or git bisect good

# Repeat until found
```

### Automated Bisect

```bash
# With test script
git bisect start HEAD v1.2.0
git bisect run npm test -- bug-test.test.ts
```

## Debugging Techniques

### Add Logging

```typescript
function processFile(file) {
  console.log('processFile called with:', file);
  console.log('file type:', typeof file);
  console.log('file.data exists:', 'data' in file);

  const size = file.data.length;
  // ...
}
```

### Assertions

```typescript
function processFile(file) {
  if (!file) {
    throw new Error('processFile: file is null or undefined');
  }
  if (!file.data) {
    throw new Error('processFile: file.data is missing');
  }

  const size = file.data.length;
  // ...
}
```

### Reproduce Locally

```typescript
// Create minimal test case
const mockFile = {
  name: 'test.txt',
  // Missing 'data' field - triggers bug
};

processFile(mockFile); // Should crash
```

## Common Bug Patterns

### Off-by-One Errors

```typescript
// Wrong: includes boundary
for (let i = 0; i <= arr.length; i++) {
  arr[i]; // Crashes at i === arr.length
}

// Right: excludes boundary
for (let i = 0; i < arr.length; i++) {
  arr[i]; // Safe
}
```

### Null/Undefined Checks

```typescript
// Wrong: doesn't check for undefined
if (obj.property) { ... }

// Right: explicit checks
if (obj && obj.property !== undefined) { ... }
```

### Async Race Conditions

```typescript
// Wrong: not awaited
async function loadData() {
  fetchData(); // Fire and forget
  useData(); // Might run before fetchData completes
}

// Right: awaited
async function loadData() {
  await fetchData();
  useData(); // Runs after fetchData completes
}
```

### Type Coercion Bugs

```typescript
// Wrong: string comparison
if (response.status == 200) { ... } // true for "200"

// Right: strict comparison
if (response.status === 200) { ... } // only true for number 200
```

### Memory Leaks

```typescript
// Wrong: event listeners not cleaned up
componentDidMount() {
  window.addEventListener('resize', this.handleResize);
}

// Right: cleanup
componentWillUnmount() {
  window.removeEventListener('resize', this.handleResize);
}
```

## Investigation Checklist

### Initial Assessment

- [ ] Read full bug report
- [ ] Extract reproduction steps
- [ ] Note error messages/stack traces
- [ ] Identify affected components
- [ ] Check if bug is reproducible

### Code Location

- [ ] Search for error messages in code
- [ ] Find relevant files/functions
- [ ] Check git history for recent changes
- [ ] Look for related issues/PRs

### Root Cause

- [ ] Identify exact line causing crash
- [ ] Understand why it fails
- [ ] Trace through call stack
- [ ] Check for missing validation
- [ ] Look for timing/race issues

### Impact Analysis

- [ ] Determine severity
- [ ] Identify affected users
- [ ] Check for data corruption risk
- [ ] Assess security implications
- [ ] Look for similar bugs

### Fix Planning

- [ ] Confirm minimal fix approach
- [ ] Consider edge cases
- [ ] Plan regression tests
- [ ] Check for breaking changes

## Example Investigation Flow

### Bug: "Login fails for users with + in email"

**Step 1: Reproduce**
```bash
# Test with email containing +
curl -X POST /api/login \
  -d '{"email":"user+test@example.com","password":"pwd"}'

# Returns 401 Unauthorized
```

**Step 2: Search code**
```bash
grep -r "login\|authenticate" src/
# Find: src/auth/login.ts
```

**Step 3: Examine login logic**
```typescript
// src/auth/login.ts:23
function validateEmail(email: string) {
  return /^[a-zA-Z0-9@.]$/.test(email); // ← Missing + in regex!
}
```

**Step 4: Confirm root cause**
- Regex doesn't allow `+` character
- Valid email format includes `+`
- RFC 5322 allows `+` in local part

**Step 5: Plan fix**
- Update regex to include `+`
- Add test for `+` in email
- Test other special chars (`,`, `-`, `_`)

**Step 6: Implement**
```typescript
function validateEmail(email: string) {
  // RFC 5322 simplified regex
  return /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$/.test(email);
}
```

**Step 7: Test**
```typescript
describe('Bug #145: Email validation with + character', () => {
  it('should accept email with + character', () => {
    expect(validateEmail('user+test@example.com')).toBe(true);
  });

  it('should accept email with other special chars', () => {
    expect(validateEmail('user.name_123@example.com')).toBe(true);
  });

  it('should reject invalid formats', () => {
    expect(validateEmail('notanemail')).toBe(false);
    expect(validateEmail('@example.com')).toBe(false);
  });
});
```

## Tools and Resources

### Browser DevTools

- **Console**: Error messages, logging
- **Network**: API calls, response codes
- **Sources**: Breakpoints, step debugging
- **Performance**: Memory leaks, slow operations

### Command Line Tools

```bash
# Find files
find . -name "pattern"

# Search content
grep -r "pattern" .
rg "pattern"  # faster alternative

# Git investigation
git log
git blame
git bisect
git show

# Debugging
node --inspect
npm test -- --debug
```

### IDE Features

- **Go to definition**: Find where function is defined
- **Find references**: See where function is called
- **Breakpoints**: Pause execution at specific line
- **Watch expressions**: Monitor variable values

## When to Escalate

### Ask for Help When:

- Bug can't be reproduced locally
- Root cause unclear after thorough investigation
- Fix requires architectural changes
- Multiple components involved
- Security implications uncertain
- Breaking changes necessary

### Provide When Asking:

1. Investigation summary
2. Attempted solutions
3. Why they didn't work
4. Specific question or guidance needed
