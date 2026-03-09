# Error Handling

## No active story

**Detection:** `.agile-dev-team/active-story.json` does not exist.

**Message:**
```
❌ No active story found
   Run /fetch-story first to select a story.
   Or run /play-story to execute the full workflow.
```

Exit without asking any questions.

## NFRs already exist

**Detection:** `technical-context.json` already has a non-empty `nfrs` key.

**Prompt:**
```
⚠️  NFRs already exist for this story

[abbreviated summary of existing values]

Options:
  [1] Keep existing NFRs (cancel)
  [2] Re-collect NFRs (overwrite)
```

## File write failed

**Detection:** `writeFileSync` throws on `.agile-dev-team/technical-context.json`.

**Message:**
```
❌ Failed to save NFRs to .agile-dev-team/technical-context.json
Error: [message]
Possible causes: permissions, disk full, file locked
```
