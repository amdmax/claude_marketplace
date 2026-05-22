# Workflows

## Workflow 1: Issue-Based with Auto-Creation

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: MYAPP
  issue:
    create_if_missing: true
```

**Steps:**
1. Make code changes
2. `git add .`
3. `/commit`
4. If no active story:
   - Skill calls `/create-story`
   - User describes issue
   - Issue created automatically
5. Commit created: `MYAPP-{issueNumber}: description`

## Workflow 2: Sequential Only

**Configuration:**
```yaml
numbering:
  mode: "sequential"
  prefix: MYAPP
```

**Steps:**
1. Make code changes
2. `git add .`
3. `/commit`
4. Skill finds highest MYAPP-### commit
5. Increments number
6. Commit created: `MYAPP-042: description`

## Workflow 3: Issue-Based with Manual Issues

**Configuration:**
```yaml
numbering:
  mode: "issue-based"
  prefix: MYAPP
  issue:
    create_if_missing: false
```

**Steps:**
1. `/fetch-story` - Browse available issues
2. `/play-story` - Activate an issue
3. Make code changes
4. `git add .`
5. `/commit` - Uses active issue number
