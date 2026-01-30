# Sequential Counter Logic

> **Reference for:** commit skill
> **Context:** Detailed algorithm for finding and incrementing commit numbers

## Why Check All Branches?

The project uses a **global sequential counter** across all branches. This prevents:

- **Duplicate numbers** when multiple branches are active
- **Merge conflicts** from overlapping {{PROJECT_PREFIX}} numbers
- **Confusion** in git history and PR discussions

## Finding the Highest Number

**Command:**
```bash
# Replace {{PROJECT_PREFIX}} with your actual prefix from config.yaml
git log --oneline --all --grep="{{PROJECT_PREFIX}}-"
```

**Output example:**
```
a1b2c3d {{PROJECT_PREFIX}}-018: Consolidate build and lint jobs to eliminate duplication
b2c3d4e {{PROJECT_PREFIX}}-017: Add logo assets to HTML build pipeline
c3d4e5f {{PROJECT_PREFIX}}-016: Fix remaining major issues from PR feedback
d4e5f6a {{PROJECT_PREFIX}}-015: Add comprehensive test coverage for Lambda function
e5f6a7b {{PROJECT_PREFIX}}-014: Add HTML escaping to prevent XSS vulnerabilities
```

**Extraction:**
```bash
# Get unique numbers (prefix comes from config.yaml)
PREFIX=$(yq e '.numbering.prefix' config.yaml)
git log --oneline --all --grep="${PREFIX}-" | grep -o "${PREFIX}-[0-9]*" | sort -u

# Sort numerically by the number part (after the dash)
sort -t- -k2 -n

# Get the last (highest) one
tail -1
```

**Result:** `{{PROJECT_PREFIX}}-018`

## Incrementing Algorithm

```bash
# Extract the number part
HIGHEST=$(git log --oneline --all --grep="{{PROJECT_PREFIX}}-" | \
  grep -o "{{PROJECT_PREFIX}}-[0-9]*" | \
  sort -u | \
  sort -t- -k2 -n | \
  tail -1 | \
  grep -o "[0-9]*")

# If no {{PROJECT_PREFIX}} commits exist, start at 001
if [ -z "$HIGHEST" ]; then
  NEXT="001"
else
  # Increment (strips leading zeros automatically in bash arithmetic)
  NEXT_NUM=$((10#$HIGHEST + 1))

  # Zero-pad to 3 digits (configurable in config.yaml)
  NEXT=$(printf "%03d" $NEXT_NUM)
fi

# Result: {{PROJECT_PREFIX}}-019
echo "{{PROJECT_PREFIX}}-$NEXT"
```

## Edge Cases

### No {{PROJECT_PREFIX}} Commits Exist
- **Behavior:** Start with `{{PROJECT_PREFIX}}-001`
- **When:** New projects or first use of skill
- **Command check:** `git log --all --grep="{{PROJECT_PREFIX}}-" | wc -l` returns 0

### Number Exceeds 999
- **Behavior:** Use 4 digits: `{{PROJECT_PREFIX}}-1000`
- **Config:** Update `config.yaml`:
  ```yaml
  numbering:
    digits: 4
    format: "%s-%04d"
  ```
- **Format command:** `printf "%04d"` instead of `"%03d"`

### Gaps in Sequence
- **Behavior:** Acceptable and expected
- **Causes:**
  - Rebasing (old numbers removed)
  - Amending commits (number changes)
  - Cherry-picking (skips numbers)
  - Manual commit deletions
- **Rule:** Always increment from highest, regardless of gaps
- **Example:** If highest is 018, next is 019 even if 010-017 are missing

### Multiple Commits at Same Time
- **Scenario:** Team member commits {{PROJECT_PREFIX}}-020 while you're working
- **Behavior:** You pull, see 020, use 021
- **Prevention:** Always run `git pull --all` before `/commit`
- **Detection:** If collision detected during push:
  ```bash
  git pull --rebase
  git commit --amend  # Update to next available number
  ```

### Cross-Branch Numbering
- **Scenario:** Working on feature branch while main has new commits
- **Behavior:** Checks both branches, uses global highest + 1
- **Example:**
  ```
  main:    {{PROJECT_PREFIX}}-018
  feature: {{PROJECT_PREFIX}}-015

  Next commit on feature uses: {{PROJECT_PREFIX}}-019 (not 016)
  ```

## Parametrization

Configure numbering via `config.yaml`:

```yaml
numbering:
  prefix: {{PROJECT_PREFIX}}        # Change to PROJ, TICKET, etc.
  digits: 3              # Number of zero-padded digits
  format: "%s-%03d"      # sprintf format string
```

**Examples:**

```yaml
# Use PROJ prefix with 4 digits
numbering:
  prefix: PROJ
  digits: 4
  format: "%s-%04d"
# Result: PROJ-0001, PROJ-0002, ...

# Use TICKET prefix with 5 digits
numbering:
  prefix: TICKET
  digits: 5
  format: "%s-%05d"
# Result: TICKET-00001, TICKET-00002, ...

# Simple sequential (no prefix)
numbering:
  prefix: ""
  digits: 3
  format: "%03d"
# Result: 001, 002, ...
```

## Troubleshooting

### Issue: Incorrect Number Used

**Symptom:** Commit has {{PROJECT_PREFIX}}-015 but {{PROJECT_PREFIX}}-020 already exists

**Diagnosis:**
```bash
# Check all branches
git log --all --oneline --grep="{{PROJECT_PREFIX}}-015"
git log --all --oneline --grep="{{PROJECT_PREFIX}}-020"

# Check which branch has 020
git branch --contains <commit-hash-of-020>
```

**Fix:**
```bash
# If not pushed yet
git commit --amend

# If already pushed
git revert <commit>  # Then create new commit with correct number
```

### Issue: Duplicate Numbers Detected

**Symptom:** Two commits with same {{PROJECT_PREFIX}} number

**Cause:** Concurrent work without pulling latest

**Fix:**
```bash
# Find duplicates
git log --all --oneline --grep="{{PROJECT_PREFIX}}-###"

# Renumber the newer one
git rebase -i <parent-commit>
# Mark commit as 'edit'
# Update commit message with new number
git commit --amend
git rebase --continue
```

### Issue: Counter Starts at Wrong Number

**Symptom:** First commit is {{PROJECT_PREFIX}}-050 instead of {{PROJECT_PREFIX}}-001

**Cause:** Old commits with {{PROJECT_PREFIX}} exist (maybe rebased away)

**Diagnosis:**
```bash
# Check what's the highest
git log --all --oneline --grep="{{PROJECT_PREFIX}}-" | \
  grep -o "{{PROJECT_PREFIX}}-[0-9]*" | \
  sort -u | \
  sort -t- -k2 -n | \
  tail -1
```

**Fix:**
```bash
# If you want to restart numbering
# Warning: This is disruptive, coordinate with team
git filter-branch --msg-filter 'sed "s/{{PROJECT_PREFIX}}-[0-9]*/TEMP-\\1/g"' HEAD

# Or accept current numbering and continue
# No fix needed - gaps are acceptable
```

## Performance Optimization

For repos with many commits:

```bash
# Limit search depth (faster but less safe)
git log --oneline --all --grep="{{PROJECT_PREFIX}}-" -n 100 | \
  grep -o "{{PROJECT_PREFIX}}-[0-9]*" | \
  sort -u | \
  sort -t- -k2 -n | \
  tail -1

# Or use git rev-list (faster for large repos)
git rev-list --all --grep="{{PROJECT_PREFIX}}-" --format="%s" | \
  grep -o "{{PROJECT_PREFIX}}-[0-9]*" | \
  sort -u | \
  sort -t- -k2 -n | \
  tail -1
```

## Alternative Implementations

### Using awk (more efficient)

```bash
git log --all --oneline --grep="{{PROJECT_PREFIX}}-" | \
  awk -F'{{PROJECT_PREFIX}}-' '{print $2}' | \
  awk '{print $1}' | \
  sort -n | \
  tail -1
```

### Using Python (complex logic)

```python
#!/usr/bin/env python3
import subprocess
import re

def get_next_aigcode():
    # Get all {{PROJECT_PREFIX}} commits
    result = subprocess.run(
        ['git', 'log', '--all', '--oneline', '--grep={{PROJECT_PREFIX}}-'],
        capture_output=True,
        text=True
    )

    # Extract numbers
    numbers = [int(m.group(1)) for m in re.finditer(r'{{PROJECT_PREFIX}}-(\d+)', result.stdout)]

    # Get highest
    highest = max(numbers) if numbers else 0

    # Return next
    return f"{{PROJECT_PREFIX}}-{highest + 1:03d}"

print(get_next_aigcode())
```

## Integration with Other Tools

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# Only auto-number if not amending or merging
if [ -z "$COMMIT_SOURCE" ]; then
  NEXT_{{PROJECT_PREFIX}}=$(git log --all --oneline --grep="{{PROJECT_PREFIX}}-" | \
    grep -o "{{PROJECT_PREFIX}}-[0-9]*" | \
    sort -u | \
    sort -t- -k2 -n | \
    tail -1 | \
    awk -F'-' '{printf "{{PROJECT_PREFIX}}-%03d", $2+1}')

  # Prepend to commit message if not already present
  if ! grep -q "^{{PROJECT_PREFIX}}-" "$COMMIT_MSG_FILE"; then
    echo "$NEXT_{{PROJECT_PREFIX}}: $(cat $COMMIT_MSG_FILE)" > "$COMMIT_MSG_FILE"
  fi
fi
```

### GitHub Actions

```yaml
name: Validate {{PROJECT_PREFIX}} Sequence
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - name: Check {{PROJECT_PREFIX}} numbering
        run: |
          # Get all {{PROJECT_PREFIX}} numbers in this PR
          PR_COMMITS=$(git log origin/main..HEAD --oneline --grep="{{PROJECT_PREFIX}}-")

          # Verify no duplicates
          DUPLICATES=$(echo "$PR_COMMITS" | \
            grep -o "{{PROJECT_PREFIX}}-[0-9]*" | \
            sort | \
            uniq -d)

          if [ -n "$DUPLICATES" ]; then
            echo "Error: Duplicate {{PROJECT_PREFIX}} numbers found: $DUPLICATES"
            exit 1
          fi
```

## References

- [Commit Message Examples](examples.md)
- [Grouping Detection Algorithm](grouping-detection.md)
- [Best Practices](best-practices.md)
